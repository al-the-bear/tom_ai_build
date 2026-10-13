/* spec_document_yaml — implementation. See spec_document_yaml.hpp; an
 * idiomatic-C++ port of the C `spec_document_yaml.c` (hierarchical format v2). */
#include "spec_document_yaml.hpp"

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <map>
#include <vector>

#include "som_json.hpp"
#include "som_util.hpp"
#include "spec_paths.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"

namespace som {

/* ---- small helpers ------------------------------------------------------- */

static void setErr(std::string* err, std::string msg) {
  if (err != nullptr) {
    *err = std::move(msg);
  }
}

/* Removes the first occurrence of `s` from `v`; true when it was present. */
static bool removeValue(std::vector<std::string>& v, const std::string& s) {
  for (auto it = v.begin(); it != v.end(); ++it) {
    if (*it == s) {
      v.erase(it);
      return true;
    }
  }
  return false;
}

static bool contains(const std::vector<std::string>& v, const std::string& s) {
  return std::find(v.begin(), v.end(), s) != v.end();
}

/* ---- shared scalar machinery --------------------------------------------- */

static std::string jsJsonString(const std::string& s) { return jsonEncodeStr(s); }

std::string specYamlNodeKey(const SomMetaNode& node) {
  const std::string& name =
      !node.memberName.empty() ? node.memberName : node.className;
  // Section/complex keys carry the full section id: the field-level @SectionId
  // when present, else the target class's own @SectionId (classSectionId, the
  // SOM §12.2 class fallback), mirroring the markdown codec's heading rule.
  // Content/scalar/enum/form/list-item keys keep only their field-level id; the
  // path segment is never affected (see SomMetaNode::segment).
  // Compare kinds by content, never by pointer: the constants are string
  // literals, and two translation units need not share one copy of a literal
  // (an AddressSanitizer build does not, and then every key lost its id).
  const std::string kind = node.kind;
  const std::string& id =
      (node.sectionId.empty() &&
       (kind == kSomMetaKindSection || kind == kSomMetaKindComplex))
          ? node.classSectionId
          : node.sectionId;
  if (id.empty()) {
    return name;
  }
  return id + " " + name;
}

/* plainKeyPattern: ^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$ */
static bool keyFirst(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9') || c == '_';
}
static bool keyLast(char c) { return keyFirst(c) || c == '.' || c == '-'; }
static bool keyMid(char c) { return keyLast(c) || c == ' '; }

std::string specYamlPlainKey(const std::string& key) {
  std::size_t n = key.size();
  bool plain = n > 0 && keyFirst(key[0]);
  if (plain && n > 1) {
    plain = keyLast(key[n - 1]);
    for (std::size_t i = 1; plain && i + 1 < n; i++) {
      plain = keyMid(key[i]);
    }
  }
  return plain ? key : jsJsonString(key);
}

std::string specYamlDedupEmptyLines(const std::string& value) {
  std::string b;
  std::size_t i = 0;
  while (i < value.size()) {
    if (value[i] == '\n') {
      std::size_t run = 0;
      while (i + run < value.size() && value[i + run] == '\n') {
        run++;
      }
      std::size_t emit = run >= 3 ? 2 : run;
      b.append(emit, '\n');
      i += run;
    } else {
      b.push_back(value[i]);
      i++;
    }
  }
  return b;
}

static std::size_t trailingNewlines(const std::string& value) {
  std::size_t n = value.size();
  std::size_t count = 0;
  while (count < n && value[n - 1 - count] == '\n') {
    count++;
  }
  return count;
}

/* Builds a `|2<chomp>` literal block with body at relative indent 2, or
 * std::nullopt when chomping can't reproduce two-or-more trailing newlines. */
static std::optional<std::string> literalBlock(const std::string& value) {
  std::size_t trailing = trailingNewlines(value);
  std::string chomp;
  std::size_t coreLen;
  std::size_t vlen = value.size();
  if (trailing == 0) {
    chomp = "-";
    coreLen = vlen;
  } else if (trailing == 1) {
    chomp = "";
    coreLen = vlen - 1;
  } else {
    return std::nullopt;
  }
  std::string b = "|2";
  b += chomp;
  std::size_t start = 0;
  for (std::size_t i = 0;; i++) {
    if (i == coreLen || value[i] == '\n') {
      b.push_back('\n');
      if (i > start) {
        b += "  ";
        b += value.substr(start, i - start);
      }
      if (i == coreLen) {
        break;
      }
      start = i + 1;
    }
  }
  return b;
}

/* Reports whether re-parsing `_v: <block>` yields exactly `value`. */
static bool roundTrips(const std::string& block, const std::string& value) {
  std::string probe = "_v: " + block + "\n";
  YamlPtr parsed = yamlParse(probe);
  YamlRef v = yamlGet(parsed, "_v");
  const std::string* s = yamlAsStr(v);
  return s != nullptr && *s == value;
}

/* Literal block at relative indent 2 when it round-trips, else JSON quoting. */
static std::string scalarRepr(const std::string& value) {
  auto block = literalBlock(value);
  if (block.has_value() && roundTrips(*block, value)) {
    return *block;
  }
  return jsJsonString(value);
}

/* Whether `value` is a YAML 1.1 boolean word that YAML 1.2 treats as a plain
 * string. */
static bool isYaml11Bool(const std::string& value) {
  static const char* const words[] = {
      "y",  "Y",  "yes", "Yes", "YES", "n",   "N",   "no",
      "No", "NO", "on",  "On",  "ON",  "off", "Off", "OFF"};
  for (const char* w : words) {
    if (value == w) {
      return true;
    }
  }
  return false;
}

/* Whether `value` is a YAML 1.1 sexagesimal literal — an int
 * (^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$) when isFloat is false, or a float
 * (^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$) when true. A dependency-free
 * stand-in for the other ports' regexes. */
static bool isYaml11Sexagesimal(const std::string& value, bool isFloat) {
  auto isDigit = [](char c) { return c >= '0' && c <= '9'; };
  std::size_t n = value.size();
  std::size_t i = 0;
  if (n == 0) {
    return false;
  }
  if (value[i] == '+' || value[i] == '-') {
    i++;
  }
  if (i >= n) {
    return false;
  }
  if (isFloat) {
    if (!isDigit(value[i])) {
      return false;
    }
  } else if (!(value[i] >= '1' && value[i] <= '9')) {
    return false;
  }
  i++;
  while (i < n && (isDigit(value[i]) || value[i] == '_')) {
    i++;
  }
  std::size_t groups = 0;
  while (i < n && value[i] == ':') {
    i++;
    if (i >= n || !isDigit(value[i])) {
      return false;
    }
    if (value[i] >= '0' && value[i] <= '5' && i + 1 < n && isDigit(value[i + 1])) {
      i += 2;
    } else {
      i++;
    }
    groups++;
  }
  if (groups == 0) {
    return false;
  }
  if (isFloat) {
    if (i >= n || value[i] != '.') {
      return false;
    }
    i++;
    while (i < n && (isDigit(value[i]) || value[i] == '_')) {
      i++;
    }
  }
  return i == n;
}

/* Whether `value`'s text is a YAML 1.1 special that a 1.1 parser would resolve
 * to a non-string, so it must never be emitted as a plain scalar (SOM §12.5).
 * Mirrors the Dart reference rule so every emitter agrees regardless of the
 * local YAML parser's schema. */
static bool isYaml11Special(const std::string& value) {
  return isYaml11Bool(value) || isYaml11Sexagesimal(value, false) ||
         isYaml11Sexagesimal(value, true);
}

/* A plain one-line scalar for a non-text value (SOM §12.5) when writing it plainly
 * re-parses to exactly `value`. Values whose text is a YAML 1.1 special are
 * forced to the quoted/block path so cross-language round-trips match. */
static bool plainScalarOk(const std::string& value) {
  if (value.empty() || value.find('\n') != std::string::npos) {
    return false;
  }
  if (isYaml11Special(value)) {
    return false;
  }
  std::string probe = "_v: " + value + "\n";
  YamlPtr parsed = yamlParse(probe);
  if (parsed == nullptr || parsed->type != YamlType::Map) {
    return false;
  }
  YamlRef v = yamlGet(parsed, "_v");
  if (v == nullptr || v->type == YamlType::Map || v->type == YamlType::Seq) {
    return false;
  }
  return yamlScalarString(v) == value;
}

/* `<pad><renderedKey>: <first line>` then the remaining repr lines re-indented
 * past keyIndent (empty lines stay empty). */
static void writeRendered(std::string& out, std::size_t keyIndent,
                          const std::string& renderedKey,
                          const std::string& repr) {
  out.append(keyIndent, ' ');
  out += renderedKey;
  out += ": ";
  std::size_t start = 0;
  bool first = true;
  std::size_t rlen = repr.size();
  for (std::size_t i = 0;; i++) {
    if (i == rlen || repr[i] == '\n') {
      std::size_t llen = i - start;
      if (first) {
        out += repr.substr(start, llen);
        out.push_back('\n');
        first = false;
      } else if (llen == 0) {
        out.push_back('\n');
      } else {
        out.append(keyIndent, ' ');
        out += repr.substr(start, llen);
        out.push_back('\n');
      }
      if (i == rlen) {
        break;
      }
      start = i + 1;
    }
  }
}

void specYamlWriteScalar(std::string& out, std::size_t keyIndent,
                         const std::string& key, const std::string& value) {
  writeRendered(out, keyIndent, jsJsonString(key), scalarRepr(value));
}

/* The file header comment + `version:` line, and the optional `modelVersion:`
 * stamp when non-empty. */
static void writeHeader(std::string& out, const std::string& modelVersion) {
  out += "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n";
  out += "version: ";
  out += formatI64(kSpecYamlFormatVersion);
  out.push_back('\n');
  if (!modelVersion.empty()) {
    out += "modelVersion: ";
    out += jsJsonString(modelVersion);
    out.push_back('\n');
  }
}

/* ---- encode -------------------------------------------------------------- */

static bool isNumericOrBool(const std::string& typeName) {
  return typeName == "int" || typeName == "double" || typeName == "num" ||
         typeName == "bool";
}

namespace {

/* One encode run: it walks the metadata tree, consuming values from snapshots
 * of the document's stores so anything left unconsumed at the end is a
 * structured error (nothing is silently dropped). */
class YamlEncoder {
 public:
  const SpecDocument* doc = nullptr;
  std::map<std::string, std::string> content;    // consumed as the walk places
  std::vector<std::string> formPaths;            // remaining unconsumed
  std::vector<std::string> listPaths;            // remaining unconsumed
  std::map<std::string, std::string> headlines;  // consumed as the walk places
  std::map<std::string, std::string> codeSpecs;  // consumed as the walk places

  void init(const SpecDocument* d) {
    doc = d;
    for (const std::string& path : d->contentPaths()) {
      const std::string* v = d->contentOpt(path);
      content[path] = v != nullptr ? *v : "";
    }
    formPaths = d->formPaths();
    listPaths = d->listPaths();
    for (const std::string& path : d->headlinePaths()) {
      headlines[path] = d->headline(path);
    }
    for (const std::string& path : d->codeSpecPaths()) {
      codeSpecs[path] = d->codeSpec(path);
    }
  }

  /* Consumes the content snapshot entry at `path`; true when present. */
  bool takeContent(const std::string& path, std::string* out) {
    auto it = content.find(path);
    if (it == content.end()) {
      return false;
    }
    *out = it->second;
    content.erase(it);
    return true;
  }

  /* Consumes the headline snapshot entry at `path`; true when present. */
  bool takeHeadline(const std::string& path, std::string* out) {
    auto it = headlines.find(path);
    if (it == headlines.end()) {
      return false;
    }
    *out = it->second;
    headlines.erase(it);
    return true;
  }

  /* Consumes the codeSpec snapshot entry at `path`; true when present. */
  bool takeCodeSpec(const std::string& path, std::string* out) {
    auto it = codeSpecs.find(path);
    if (it == codeSpecs.end()) {
      return false;
    }
    *out = it->second;
    codeSpecs.erase(it);
    return true;
  }

  void writeText(std::string& b, std::size_t indent, const std::string& key,
                 const std::string& value) {
    std::string repr = scalarRepr(specYamlDedupEmptyLines(value));
    writeRendered(b, indent, specYamlPlainKey(key), repr);
  }

  void writeValue(std::string& b, std::size_t indent, const std::string& key,
                  const std::string& value) {
    if (plainScalarOk(value)) {
      b.append(indent, ' ');
      b += specYamlPlainKey(key);
      b += ": ";
      b += value;
      b.push_back('\n');
    } else {
      writeText(b, indent, key, value);
    }
  }

  /* Emits a scalar-valued node (content/scalar/enum leaf or scalar list item)
   * that carries a stored headline and/or a codeSpec mapping as a `{headline?:
   * …, codeSpec?: …, content?: …}` mapping (YRD3 + codespecs_mapping.md §9.2).
   * At least one of headline/codeSpec is present at every call site. The
   * content entry is
   * omitted when hasValue is false. */
  void writeScalarWithMeta(std::string& b, std::size_t indent,
                           const std::string& key, bool hasHeadline,
                           const std::string& headline, bool hasCodeSpec,
                           const std::string& codeSpec, const std::string& value,
                           bool hasValue, bool text) {
    b.append(indent, ' ');
    b += specYamlPlainKey(key);
    b += ":\n";
    if (hasHeadline) {
      writeText(b, indent + 2, "headline", headline);
    }
    if (hasCodeSpec) {
      writeText(b, indent + 2, "codeSpec", codeSpec);
    }
    if (hasValue) {
      if (text) {
        writeText(b, indent + 2, "content", value);
      } else {
        writeValue(b, indent + 2, "content", value);
      }
    }
  }

  bool writeForm(std::string& b, std::size_t indent, const std::string& key,
                 const SomMetaNode& node, const std::string& path,
                 std::string* err) {
    bool present = removeValue(formPaths, path);
    std::vector<std::string> names = doc->formFieldNames(path);
    std::string headline;
    bool hasHeadline = takeHeadline(path, &headline);
    std::string codeSpec;
    bool hasCodeSpec = takeCodeSpec(path, &codeSpec);
    /* The form's preamble — the free text before its first field (SOM §11.4
     * rule 7, the DocSpecs `${text[]}` region) — rides in the same mapping
     * under the literal `content` key, exactly as a section's body does. */
    std::string content;
    bool hasContent = takeContent(path, &content);
    if ((!present || names.empty()) && !hasHeadline && !hasCodeSpec &&
        !hasContent) {
      return true;
    }
    for (const std::string& name : names) {
      const SomFormFieldMeta* field =
          node.form.has_value() ? node.form->fieldNamed(name) : nullptr;
      if (field == nullptr) {
        setErr(err, "form `" + path + "` holds a field `" + name +
                        "` unknown to the model");
        return false;
      }
    }
    if (hasHeadline && node.form.has_value() &&
        node.form->fieldNamed("headline") != nullptr) {
      setErr(err, "cannot emit the stored headline at `" + path +
                      "`: the form declares a field literally named "
                      "`headline`");
      return false;
    }
    if (hasCodeSpec && node.form.has_value() &&
        node.form->fieldNamed("codeSpec") != nullptr) {
      setErr(err, "cannot emit the stored codeSpec at `" + path +
                      "`: the form declares a field literally named "
                      "`codeSpec`");
      return false;
    }
    if (hasContent && node.form.has_value() &&
        node.form->fieldNamed("content") != nullptr) {
      setErr(err, "cannot emit the preamble content at `" + path +
                      "`: the form declares a field literally named "
                      "`content`");
      return false;
    }
    b.append(indent, ' ');
    b += specYamlPlainKey(key);
    b += ":\n";
    if (hasHeadline) {
      writeText(b, indent + 2, "headline", headline);
    }
    if (hasCodeSpec) {
      writeText(b, indent + 2, "codeSpec", codeSpec);
    }
    if (hasContent) {
      writeText(b, indent + 2, "content", content);
    }
    if (node.form.has_value()) {
      for (const SomFormFieldMeta& f : node.form->fields) {
        const std::string* v = doc->formFieldOpt(path, f.name);
        if (v == nullptr) {
          continue;
        }
        if (isNumericOrBool(f.typeName)) {
          writeValue(b, indent + 2, f.name, *v);
        } else {
          writeText(b, indent + 2, f.name, *v);
        }
      }
    }
    return true;
  }

  bool writeList(std::string& b, std::size_t indent, const std::string& key,
                 const SomMetaNode& node, const std::string& path,
                 std::string* err) {
    removeValue(listPaths, path);
    std::string headline;
    bool hasHeadline = takeHeadline(path, &headline);
    std::string codeSpec;
    bool hasCodeSpec = takeCodeSpec(path, &codeSpec);
    const std::vector<std::string>* items = doc->listItemsPtr(path);
    if ((items == nullptr || items->empty()) && !hasHeadline && !hasCodeSpec) {
      return true;
    }
    b.append(indent, ' ');
    b += specYamlPlainKey(key);
    b += ":\n";
    if (hasHeadline) {
      writeText(b, indent + 2, "headline", headline);
    }
    if (hasCodeSpec) {
      writeText(b, indent + 2, "codeSpec", codeSpec);
    }
    std::vector<std::string> used;
    used.push_back("headline");
    used.push_back("codeSpec");
    long long pos = 0;
    static const std::vector<std::string> kNoItems;
    for (const std::string& itemPath : (items != nullptr ? *items : kNoItems)) {
      pos++;
      const std::string* storedId = doc->itemSectionIdOpt(itemPath);
      std::string itemKey;
      if (storedId != nullptr) {
        itemKey = *storedId;
        if (contains(used, itemKey)) {
          setErr(err, "duplicate list item key `" + itemKey + "` at `" + path +
                          "`");
          return false;
        }
        used.push_back(itemKey);
      } else {
        long long bump = pos;
        itemKey = node.memberName + "-" + formatI64(bump);
        while (contains(used, itemKey)) {
          bump++;
          itemKey = node.memberName + "-" + formatI64(bump);
        }
        used.push_back(itemKey);
      }
      if (!node.elementNode) {
        // Scalar list: the item is a direct value — unless it carries a stored
        // headline and/or codeSpec, in which case it becomes a `{headline?: …,
        // codeSpec?: …, content: …}` mapping (YRD3 + codespecs_mapping.md
        // §9.2).
        std::string v;
        bool hasV = takeContent(itemPath, &v);
        if (!hasV) {
          v = "";
        }
        std::string ih;
        bool hasIh = takeHeadline(itemPath, &ih);
        std::string ics;
        bool hasIcs = takeCodeSpec(itemPath, &ics);
        if (hasIh || hasIcs) {
          writeScalarWithMeta(b, indent + 2, itemKey, hasIh, ih, hasIcs, ics, v,
                              hasV, false);
        } else {
          writeValue(b, indent + 2, itemKey, v);
        }
      } else {
        std::string sub;
        if (!mappingBody(*node.elementNode, itemPath, indent + 4, sub, err)) {
          return false;
        }
        std::string ik = specYamlPlainKey(itemKey);
        if (sub.empty()) {
          b.append(indent + 2, ' ');
          b += ik;
          b += ": {}\n";
        } else {
          b.append(indent + 2, ' ');
          b += ik;
          b += ":\n";
          b += sub;
        }
      }
    }
    return true;
  }

  /* Renders the mapping body of `node` at `path`, one line per populated entry
   * at `indent`. Empty when nothing under the node is populated. */
  bool mappingBody(const SomMetaNode& node, const std::string& path,
                   std::size_t indent, std::string& out, std::string* err) {
    std::string b;

    // The node's own stored headline — the literal `headline` key (YRD3).
    std::string ownHeadline;
    if (takeHeadline(path, &ownHeadline)) {
      for (const auto& child : node.children) {
        if (specYamlNodeKey(*child) == "headline") {
          setErr(err, "cannot emit the stored headline at `" + path +
                          "`: a child of " + node.debugName() +
                          " also serializes as key `headline`");
          return false;
        }
      }
      writeText(b, indent, "headline", ownHeadline);
    }

    // The node's own codeSpec mapping — the literal `codeSpec` key
    // (codespecs_mapping.md §9.2).
    std::string ownCodeSpec;
    if (takeCodeSpec(path, &ownCodeSpec)) {
      for (const auto& child : node.children) {
        if (specYamlNodeKey(*child) == "codeSpec") {
          setErr(err, "cannot emit the stored codeSpec at `" + path +
                          "`: a child of " + node.debugName() +
                          " also serializes as key `codeSpec`");
          return false;
        }
      }
      writeText(b, indent, "codeSpec", ownCodeSpec);
    }

    // The node's own body text — the literal `content` key (SOM §12.2).
    std::string own;
    if (takeContent(path, &own)) {
      for (const auto& child : node.children) {
        if (specYamlNodeKey(*child) == "content") {
          setErr(err, "cannot emit body text at `" + path + "`: a child of " +
                          node.debugName() +
                          " also serializes as key `content`");
          return false;
        }
      }
      writeText(b, indent, "content", own);
    }

    for (const auto& childPtr : node.children) {
      const SomMetaNode& child = *childPtr;
      std::string childPath = specPathJoin(path, child.segment());
      std::string key = specYamlNodeKey(child);
      std::string kind = child.kind;
      bool ok = true;
      if (kind == kSomMetaKindContent) {
        std::string v;
        bool hasV = takeContent(childPath, &v);
        std::string h;
        bool hasH = takeHeadline(childPath, &h);
        std::string cs;
        bool hasCs = takeCodeSpec(childPath, &cs);
        if (hasH || hasCs) {
          writeScalarWithMeta(b, indent, key, hasH, h, hasCs, cs, v, hasV, true);
        } else if (hasV) {
          writeText(b, indent, key, v);
        }
      } else if (kind == kSomMetaKindScalar || kind == kSomMetaKindEnumValue) {
        std::string v;
        bool hasV = takeContent(childPath, &v);
        std::string h;
        bool hasH = takeHeadline(childPath, &h);
        std::string cs;
        bool hasCs = takeCodeSpec(childPath, &cs);
        if (hasH || hasCs) {
          writeScalarWithMeta(b, indent, key, hasH, h, hasCs, cs, v, hasV, false);
        } else if (hasV) {
          writeValue(b, indent, key, v);
        }
      } else if (kind == kSomMetaKindForm) {
        ok = writeForm(b, indent, key, child, childPath, err);
      } else if (kind == kSomMetaKindSection || kind == kSomMetaKindComplex) {
        std::string sub;
        ok = mappingBody(child, childPath, indent + 2, sub, err);
        if (ok && !sub.empty()) {
          b.append(indent, ' ');
          b += specYamlPlainKey(key);
          b += ":\n";
          b += sub;
        }
      } else if (kind == kSomMetaKindList) {
        ok = writeList(b, indent, key, child, childPath, err);
      }
      if (!ok) {
        return false;
      }
    }
    out = std::move(b);
    return true;
  }

  bool assertNothingLeft(std::string* err) {
    std::vector<std::string> leftovers;
    for (const auto& kv : content) {
      leftovers.push_back("content at `" + kv.first + "`");
    }
    for (const std::string& p : formPaths) {
      leftovers.push_back("form values at `" + p + "`");
    }
    for (const std::string& p : listPaths) {
      leftovers.push_back("list items at `" + p + "`");
    }
    for (const auto& kv : headlines) {
      leftovers.push_back("headline at `" + kv.first + "`");
    }
    for (const auto& kv : codeSpecs) {
      leftovers.push_back("codeSpec at `" + kv.first + "`");
    }
    if (leftovers.empty()) {
      return true;
    }
    std::sort(leftovers.begin(), leftovers.end());
    std::string joined;
    for (std::size_t i = 0; i < leftovers.size(); i++) {
      if (i > 0) {
        joined += "; ";
      }
      joined += leftovers[i];
    }
    setErr(err, "document holds values the metadata tree cannot place: " +
                    joined);
    return false;
  }
};

}  // namespace

std::optional<std::string> encodeYaml(const SpecDocument& document,
                                      const SomMetaTree& tree,
                                      const std::string& modelVersion,
                                      std::string* err,
                                      const YamlValue* review) {
  std::string out;
  writeHeader(out, modelVersion);
  YamlEncoder e;
  e.init(&document);
  std::string body;
  if (!e.mappingBody(*tree.root(), tree.root()->segment(), 4, body, err)) {
    return std::nullopt;
  }
  if (!e.assertNothingLeft(err)) {
    return std::nullopt;
  }
  // The root key is the only record of which document root the file is, so
  // an empty document keeps it, with an empty body (SOM §12.3 rule 4).
  out += "document:\n";
  out += "  ";
  out += specYamlPlainKey(specYamlNodeKey(*tree.root()));
  if (body.empty()) {
    out += ": {}\n";
  } else {
    out += ":\n";
    out += body;
  }
  if (review != nullptr) {
    specYamlWriteReviewPass(out, *review);
  }
  return out;
}

/* ---- review pass --------------------------------------------------------- */

namespace {

/* `value` as Dart's double.toString prints it: the shortest digit string that
 * parses back to the same double (`%.{p}e` for growing p until strtod agrees),
 * laid out like JavaScript's Number.prototype.toString — fixed notation when
 * value == 0 or 1e-6 <= |value| < 1e21, with `.0` appended when there is no
 * fractional part (`3.0`, `-0.0`, `100000000000000000000.0`), exponent
 * notation otherwise with an explicit sign and no padding (`1e+21`,
 * `1.5e-300`, `1e-7`); `NaN` / `Infinity` / `-Infinity`. */
std::string dartDouble(double value) {
  if (std::isnan(value)) {
    return "NaN";
  }
  if (std::isinf(value)) {
    return value < 0 ? "-Infinity" : "Infinity";
  }
  std::string sign = std::signbit(value) ? "-" : "";
  double a = std::fabs(value);
  if (a == 0.0) {
    return sign + "0.0";
  }
  char buf[64];
  for (int prec = 0; prec <= 17; prec++) {
    std::snprintf(buf, sizeof buf, "%.*e", prec, a);
    if (std::strtod(buf, nullptr) == a) {
      break;
    }
  }
  std::string rep = buf;
  std::size_t e = rep.find('e');
  std::string digits;
  for (std::size_t i = 0; i < e; i++) {
    if (rep[i] != '.') {
      digits.push_back(rep[i]);
    }
  }
  while (digits.size() > 1 && digits.back() == '0') {
    digits.pop_back();
  }
  long n = std::strtol(rep.c_str() + e + 1, nullptr, 10) + 1;
  long k = static_cast<long>(digits.size());
  std::string out;
  if (k <= n && n <= 21) {
    out = digits + std::string(static_cast<std::size_t>(n - k), '0') + ".0";
  } else if (0 < n && n <= 21) {
    out = digits.substr(0, static_cast<std::size_t>(n)) + "." +
          digits.substr(static_cast<std::size_t>(n));
  } else if (-6 < n && n <= 0) {
    out = "0." + std::string(static_cast<std::size_t>(-n), '0') + digits;
  } else {
    long x = n - 1;
    std::string exp = (x < 0 ? "-" : "+") + formatI64(x < 0 ? -x : x);
    out = k == 1 ? digits + "e" + exp
                 : digits.substr(0, 1) + "." + digits.substr(1) + "e" + exp;
  }
  return sign + out;
}

JsonPtr jsonOf(JsonType t) { return std::make_shared<Json>(t); }

JsonPtr jsonStrValue(const std::string& s) {
  JsonPtr j = jsonOf(JsonType::Str);
  j->str = s;
  return j;
}

JsonPtr jsonFloat(double d) {
  JsonPtr j = jsonOf(JsonType::Float);
  j->real = d;
  return j;
}

/* Whether `t[from..]` is one or more characters of `set`. */
bool allOf(const std::string& t, std::size_t from, const char* set) {
  return from < t.size() && t.find_first_not_of(set, from) == std::string::npos;
}

/* Whether `t` matches the YAML 1.2 core-schema float spelling
 * [-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)? (a decimal integer
 * matches too; the caller tries the int forms first). */
bool isCoreFloat(const std::string& t) {
  auto digit = [&t](std::size_t i) { return i < t.size() && t[i] >= '0' && t[i] <= '9'; };
  std::size_t i = 0;
  if (i < t.size() && (t[i] == '-' || t[i] == '+')) {
    i++;
  }
  std::size_t intDigits = 0;
  while (digit(i)) {
    i++;
    intDigits++;
  }
  std::size_t fracDigits = 0;
  if (i < t.size() && t[i] == '.') {
    i++;
    while (digit(i)) {
      i++;
      fracDigits++;
    }
  }
  if (intDigits == 0 && fracDigits == 0) {
    return false;
  }
  if (i < t.size() && (t[i] == 'e' || t[i] == 'E')) {
    i++;
    if (i < t.size() && (t[i] == '-' || t[i] == '+')) {
      i++;
    }
    if (!digit(i)) {
      return false;
    }
    while (digit(i)) {
      i++;
    }
  }
  return i == t.size();
}

/* The value the YAML 1.2 core schema (package:yaml's, the Dart reference's
 * reader) gives the plain scalar `t` (SOM §12.5): `~` / `null` / `Null` /
 * `NULL` and an empty value → null; `true|True|TRUE|false|False|FALSE` →
 * bool; `[-+]?[0-9]+`, `0o[0-7]+`, `0x[0-9a-fA-F]+` → int, but a value
 * outside the signed 64-bit range → float (never saturated); the float
 * spelling, `[-+]?.inf` and `.nan` (each in its three case forms) → float;
 * a JSON flow collection (what the writer emits for a list) → its value;
 * anything else the string. Int and Float stay distinct, so `3.0` is written
 * back as `3.0` and `3` as `3`. */
JsonPtr typedPlain(const std::string& t) {
  if (t.empty() || t == "null" || t == "Null" || t == "NULL" || t == "~") {
    return jsonOf(JsonType::Null);
  }
  if (t == "true" || t == "True" || t == "TRUE" || t == "false" ||
      t == "False" || t == "FALSE") {
    JsonPtr j = jsonOf(JsonType::Bool);
    j->boolean = t[0] == 't' || t[0] == 'T';
    return j;
  }
  if (t[0] == '[' || t[0] == '{') {
    std::string err;
    JsonPtr j = jsonParse(t, &err);
    return j != nullptr ? j : jsonStrValue(t);
  }
  int base = 0;
  std::size_t from = 0;
  if (allOf(t, 2, "01234567") && t.compare(0, 2, "0o") == 0) {
    base = 8;
    from = 2;
  } else if (allOf(t, 2, "0123456789abcdefABCDEF") && t.compare(0, 2, "0x") == 0) {
    base = 16;
    from = 2;
  } else if (allOf(t, (t[0] == '-' || t[0] == '+') ? 1 : 0, "0123456789")) {
    base = 10;
  }
  if (base != 0) {
    errno = 0;
    char* end = nullptr;
    long long n = std::strtoll(t.c_str() + from, &end, base);
    if (errno != ERANGE) {
      JsonPtr j = jsonOf(JsonType::Int);
      j->integer = n;
      return j;
    }
    if (base == 10) {
      return jsonFloat(std::strtod(t.c_str(), nullptr));
    }
    double d = 0;
    for (std::size_t i = from; i < t.size(); i++) {
      char c = t[i];
      int digit = c <= '9' ? c - '0' : (c | 0x20) - 'a' + 10;
      d = d * base + digit;
    }
    return jsonFloat(d);
  }
  std::string unsignedT = (t[0] == '-' || t[0] == '+') ? t.substr(1) : t;
  if (unsignedT == ".inf" || unsignedT == ".Inf" || unsignedT == ".INF") {
    double inf = std::numeric_limits<double>::infinity();
    return jsonFloat(t[0] == '-' ? -inf : inf);
  }
  if (t == ".nan" || t == ".NaN" || t == ".NAN") {
    return jsonFloat(std::numeric_limits<double>::quiet_NaN());
  }
  if (isCoreFloat(t)) {
    return jsonFloat(std::strtod(t.c_str(), nullptr));
  }
  return jsonStrValue(t);
}

/* The review value `v` typed as YAML types it. */
JsonPtr reviewJson(const YamlValue& v) {
  switch (v.type) {
    case YamlType::Map: {
      if (v.plain && v.map.empty()) {
        return jsonOf(JsonType::Null);  // an empty value (`key:`)
      }
      JsonPtr j = jsonOf(JsonType::Object);
      for (const auto& kv : v.map) {
        j->object.emplace_back(kv.first, kv.second != nullptr
                                             ? reviewJson(*kv.second)
                                             : jsonOf(JsonType::Null));
      }
      return j;
    }
    case YamlType::Seq: {
      JsonPtr j = jsonOf(JsonType::Array);
      for (const auto& item : v.seq) {
        j->array.push_back(item != nullptr ? reviewJson(*item)
                                           : jsonOf(JsonType::Null));
      }
      return j;
    }
    case YamlType::Int: {
      JsonPtr j = jsonOf(JsonType::Int);
      j->integer = v.integer;
      return j;
    }
    case YamlType::Str:
      break;
  }
  return v.plain ? typedPlain(v.str) : jsonStrValue(v.str);
}

/* Compact JSON text of `v`, as Dart's jsonEncode writes it. */
void jsonFlow(std::string& out, const Json& v) {
  switch (v.type) {
    case JsonType::Null:
      out += "null";
      return;
    case JsonType::Bool:
      out += v.boolean ? "true" : "false";
      return;
    case JsonType::Int:
      out += formatI64(v.integer);
      return;
    case JsonType::Float:
      out += dartDouble(v.real);
      return;
    case JsonType::Str:
      out += jsJsonString(v.str);
      return;
    case JsonType::Array:
      out.push_back('[');
      for (std::size_t i = 0; i < v.array.size(); i++) {
        if (i > 0) {
          out.push_back(',');
        }
        jsonFlow(out, *v.array[i]);
      }
      out.push_back(']');
      return;
    case JsonType::Object:
      out.push_back('{');
      for (std::size_t i = 0; i < v.object.size(); i++) {
        if (i > 0) {
          out.push_back(',');
        }
        out += jsJsonString(v.object[i].first);
        out.push_back(':');
        jsonFlow(out, *v.object[i].second);
      }
      out.push_back('}');
      return;
  }
}

/* A review float in the canonical form that reads back as the same value
 * (SOM §12.5): `.nan`, `.inf`, `-.inf` for the non-finite values (`Infinity`
 * would read back as a string), else `dartDouble` — the shortest
 * round-tripping digits in JavaScript's Number toString layout, with `.0`
 * appended to a whole fixed-notation value (`3.0`, `1e+300`, `1e-7`). */
std::string reviewFloat(double d) {
  if (std::isnan(d)) {
    return ".nan";
  }
  if (std::isinf(d)) {
    return d > 0 ? ".inf" : "-.inf";
  }
  return dartDouble(d);
}

bool reviewToken(const std::string& s) {
  if (s.empty()) {
    return false;
  }
  auto first = [](char c) {
    return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '_';
  };
  if (!first(s[0])) {
    return false;
  }
  for (char c : s) {
    if (!first(c) && !(c >= '0' && c <= '9')) {
      return false;
    }
  }
  std::string lower = s;
  for (char& c : lower) {
    if (c >= 'A' && c <= 'Z') {
      c = static_cast<char>(c - 'A' + 'a');
    }
  }
  static const char* const kYamlWords[] = {"true", "false", "null", "yes", "no",
                                           "on",   "off",   "y",    "n"};
  for (const char* w : kYamlWords) {
    if (lower == w) {
      return false;
    }
  }
  return true;
}

/* Object members of `v` sorted by name (byte order). */
std::vector<std::pair<std::string, JsonPtr>> sortedMembers(const Json& v) {
  auto members = v.object;
  std::stable_sort(members.begin(), members.end(),
                   [](const std::pair<std::string, JsonPtr>& a,
                      const std::pair<std::string, JsonPtr>& b) {
                     return a.first < b.first;
                   });
  return members;
}

void writeReviewValue(std::string& out, std::size_t indent,
                      const std::string& renderedKey, const Json& value) {
  std::string pad(indent, ' ');
  switch (value.type) {
    case JsonType::Object:
      if (value.object.empty()) {
        out += pad + renderedKey + ": {}\n";
        return;
      }
      out += pad + renderedKey + ":\n";
      for (const auto& kv : sortedMembers(value)) {
        writeReviewValue(out, indent + 2, specYamlPlainKey(kv.first),
                         *kv.second);
      }
      return;
    case JsonType::Float:
      out += pad + renderedKey + ": " + reviewFloat(value.real) + "\n";
      return;
    case JsonType::Null:
    case JsonType::Bool:
    case JsonType::Int:
    case JsonType::Array: {
      std::string flow;
      jsonFlow(flow, value);
      out += pad + renderedKey + ": " + flow + "\n";
      return;
    }
    case JsonType::Str:
      if (reviewToken(value.str)) {
        out += pad + renderedKey + ": " + value.str + "\n";
      } else {
        writeRendered(out, indent, renderedKey, scalarRepr(value.str));
      }
      return;
  }
}

}  // namespace

void specYamlWriteReviewPass(std::string& out, const YamlValue& review) {
  JsonPtr r = reviewJson(review);
  if (r->type != JsonType::Object || r->object.empty()) {
    out += "review: {}\n";
    return;
  }
  out += "review:\n";
  for (const auto& kv : sortedMembers(*r)) {
    writeReviewValue(out, 2, jsJsonString(kv.first), *kv.second);
  }
}

std::vector<std::string> specYamlStaleReviewPaths(const SpecModel& model,
                                                  const SpecDocument& document,
                                                  const YamlValue& review) {
  SpecReflection refl(model);
  auto isStale = [&](const std::string& path) {
    std::vector<std::string> segments;
    std::size_t start = 0;
    for (;;) {
      std::size_t slash = path.find('/', start);
      segments.push_back(path.substr(start, slash - start));
      if (slash == std::string::npos) {
        break;
      }
      start = slash + 1;
    }
    std::string prefix;
    for (std::size_t i = 0; i < segments.size(); i++) {
      prefix += (i == 0 ? "" : "/") + segments[i];
      auto res = refl.resolve(prefix);
      if (!res.has_value()) {
        return true;
      }
      if (res->kind == kSpecNodeKindListItemComplex ||
          res->kind == kSpecNodeKindListItemScalar) {
        std::size_t dash = prefix.rfind('-');
        std::string listPath =
            dash == std::string::npos ? prefix : prefix.substr(0, dash);
        if (!contains(document.listItems(listPath), prefix)) {
          return true;
        }
      }
    }
    return false;
  };
  std::vector<std::string> stale;
  if (review.type == YamlType::Map) {
    for (const auto& kv : review.map) {
      if (isStale(kv.first)) {
        stale.push_back(kv.first);
      }
    }
  }
  std::sort(stale.begin(), stale.end());
  return stale;
}

/* ---- decode -------------------------------------------------------------- */

static YamlPtr newEmptyMap() {
  return std::make_shared<YamlValue>(YamlType::Map);
}

/* The raw parsed `version:` value for the unsupported-version error message (a
 * non-scalar mapping renders as "[object Object]", mirroring JS/TS string
 * interpolation). */
static std::string versionRepr(const YamlRef& v) {
  if (v != nullptr && v->type == YamlType::Map) {
    return "[object Object]";
  }
  return yamlScalarString(v);
}

/* Coerces a parsed leaf value to the document's string store. The hand-rolled
 * parser yields an empty mapping for a bare `key:`, so an *empty* mapping counts
 * as the empty string; a populated mapping or a sequence is a structural
 * error. */
static bool decoderScalarOf(const YamlRef& value, const std::string& where,
                            std::string* out, std::string* err) {
  if (value == nullptr) {
    *out = "";
    return true;
  }
  if (value->type == YamlType::Seq ||
      (value->type == YamlType::Map && !value->map.empty())) {
    setErr(err, "expected a scalar value at `" + where + "`");
    return false;
  }
  if (value->type == YamlType::Map) {
    *out = "";
    return true;
  }
  *out = yamlScalarString(value);
  return true;
}

namespace {

class YamlDecoder {
 public:
  SpecDocument* doc = nullptr;
  const SomMetaTree* tree = nullptr;

  const SomMetaNode* childByKey(const SomMetaNode& node,
                                const std::string& key) {
    for (const auto& child : node.children) {
      if (specYamlNodeKey(*child) == key) {
        return child.get();
      }
    }
    return nullptr;
  }

  std::string expectedKeys(const SomMetaNode& node) {
    std::string joined;
    for (const auto& child : node.children) {
      if (!joined.empty()) {
        joined += ", ";
      }
      joined += "`" + specYamlNodeKey(*child) + "`";
    }
    if (!joined.empty()) {
      joined += ", ";
    }
    joined += "`content`, `headline`, `codeSpec`";
    return joined;
  }

  /* Loads a headline-/codeSpec-extended scalar node (YRD3 + codespecs_mapping.md §9.2): a mapping
   * holding only the literal keys `headline`, `codeSpec`, and `content`. */
  bool loadScalarWithMeta(const std::string& path, const std::string& key,
                          const YamlRef& value, std::string* err) {
    for (const auto& kv : value->map) {
      const std::string& name = kv.first;
      YamlRef v = std::const_pointer_cast<const YamlValue>(kv.second);
      if (name == "headline") {
        std::string s;
        if (!decoderScalarOf(v, path + " (headline)", &s, err)) {
          return false;
        }
        doc->setHeadline(path, s);
      } else if (name == "codeSpec") {
        std::string s;
        if (!decoderScalarOf(v, path + " (codeSpec)", &s, err)) {
          return false;
        }
        doc->setCodeSpec(path, s);
      } else if (name == "content") {
        std::string s;
        if (!decoderScalarOf(v, path + "/content", &s, err)) {
          return false;
        }
        doc->setContent(path, s);
      } else {
        setErr(err, "scalar node `" + key + "` at `" + path +
                        "` may only hold `headline`/`codeSpec`/`content` keys "
                        "when written as a mapping, found `" + name + "`");
        return false;
      }
    }
    return true;
  }

  bool loadList(const SomMetaNode& node, const std::string& path,
                const YamlRef& items, std::string* err) {
    const std::string& member = node.memberName;
    for (const auto& kv : items->map) {
      const std::string& key = kv.first;
      YamlRef value = std::const_pointer_cast<const YamlValue>(kv.second);
      if (key == "headline") {
        // The list container's own stored headline (YRD3), not an item.
        std::string v;
        if (!decoderScalarOf(value, path + " (headline)", &v, err)) {
          return false;
        }
        doc->setHeadline(path, v);
        continue;
      }
      if (key == "codeSpec") {
        // The list container's own codeSpec mapping (codespecs_mapping.md
        // §9.2), not an item.
        std::string v;
        if (!decoderScalarOf(value, path + " (codeSpec)", &v, err)) {
          return false;
        }
        doc->setCodeSpec(path, v);
        continue;
      }
      // anonymous: ^<memberName>-[0-9]+$
      bool anonymous = key.size() > member.size() + 1 &&
                       key.compare(0, member.size(), member) == 0 &&
                       key[member.size()] == '-' &&
                       isAllDigits(key.substr(member.size() + 1));
      std::string itemPath;
      if (anonymous) {
        itemPath = doc->addListItem(path);
      } else {
        try {
          itemPath = doc->addListItemWithSectionId(path, key);
        } catch (const SomSectionIdError&) {
          setErr(err, "SpecSectionIdCollision: section id \"" + key +
                          "\" is already used in list \"" + path +
                          "\"; section ids within a list must be unique.");
          return false;
        }
      }
      if (!node.elementNode) {
        // Scalar list item: the value is the item itself — or a `{headline?: …,
        // codeSpec?: …, content: …}` mapping when it carries a stored headline
        // and/or codeSpec (YRD3 + codespecs_mapping.md §9.2). The hand-rolled
        // parser cannot distinguish a bare `key:` (null) from `key: {}`, so an
        // empty mapping counts as "no value" here.
        if (value != nullptr && value->type == YamlType::Seq) {
          setErr(err, "scalar list item `" + key + "` at `" + path +
                          "` must hold a scalar");
          return false;
        }
        if (value != nullptr && value->type == YamlType::Map) {
          if (!value->map.empty() &&
              !loadScalarWithMeta(itemPath, key, value, err)) {
            return false;
          }
          continue;
        }
        if (value != nullptr) {
          doc->setContent(itemPath, yamlScalarString(value));
        }
        continue;
      }
      if (value == nullptr || value->type != YamlType::Map) {
        setErr(err, "list item `" + key + "` at `" + path +
                        "` must hold a mapping (use `{}` for an empty item)");
        return false;
      }
      if (!loadMapping(*node.elementNode, itemPath, value, err)) {
        return false;
      }
    }
    return true;
  }

  bool loadChild(const SomMetaNode& child, const std::string& path,
                 const std::string& key, const YamlRef& value,
                 std::string* err) {
    const std::string& kind = child.kind;
    if (kind == kSomMetaKindContent || kind == kSomMetaKindScalar ||
        kind == kSomMetaKindEnumValue) {
      // A populated mapping is a headline-/codeSpec-extended scalar node (YRD3
      // + codespecs_mapping.md §9.2): `{headline?: …, codeSpec?: …, content:
      // …}`. An empty mapping is the hand-rolled parser's spelling of a bare
      // `key:` and stays the empty scalar.
      if (value != nullptr && value->type == YamlType::Map &&
          !value->map.empty()) {
        return loadScalarWithMeta(path, key, value, err);
      }
      std::string v;
      if (!decoderScalarOf(value, path, &v, err)) {
        return false;
      }
      doc->setContent(path, v);
      return true;
    }
    if (kind == kSomMetaKindForm) {
      if (value == nullptr || value->type != YamlType::Map) {
        setErr(err, "form `" + key + "` at `" + path +
                        "` must hold a field mapping");
        return false;
      }
      for (const auto& fv : value->map) {
        const std::string& name = fv.first;
        const SomFormFieldMeta* field =
            child.form.has_value() ? child.form->fieldNamed(name) : nullptr;
        if (field == nullptr) {
          if (name == "headline") {
            std::string v;
            if (!decoderScalarOf(
                    std::const_pointer_cast<const YamlValue>(fv.second),
                    path + " (headline)", &v, err)) {
              return false;
            }
            doc->setHeadline(path, v);
            continue;
          }
          if (name == "codeSpec") {
            std::string v;
            if (!decoderScalarOf(
                    std::const_pointer_cast<const YamlValue>(fv.second),
                    path + " (codeSpec)", &v, err)) {
              return false;
            }
            doc->setCodeSpec(path, v);
            continue;
          }
          if (name == "content") {
            /* The form's preamble (SOM §11.4 rule 7 / §12.2). */
            std::string v;
            if (!decoderScalarOf(
                    std::const_pointer_cast<const YamlValue>(fv.second),
                    path + "/content", &v, err)) {
              return false;
            }
            doc->setContent(path, v);
            continue;
          }
          setErr(err, "form `" + path + "` has no field `" + name +
                          "` in the model");
          return false;
        }
        std::string where = path + "." + name;
        std::string v;
        if (!decoderScalarOf(std::const_pointer_cast<const YamlValue>(fv.second),
                             where, &v, err)) {
          return false;
        }
        doc->setFormField(path, name, v);
      }
      return true;
    }
    if (kind == kSomMetaKindSection || kind == kSomMetaKindComplex) {
      if (value == nullptr || value->type != YamlType::Map) {
        setErr(err, "section `" + key + "` at `" + path +
                        "` must hold a mapping, not a scalar");
        return false;
      }
      return loadMapping(child, path, value, err);
    }
    if (kind == kSomMetaKindList) {
      if (value == nullptr || value->type != YamlType::Map) {
        setErr(err, "list `" + key + "` at `" + path +
                        "` must hold an item mapping");
        return false;
      }
      return loadList(child, path, value, err);
    }
    return true;
  }

  bool loadMapping(const SomMetaNode& node, const std::string& path,
                   const YamlRef& body, std::string* err) {
    for (const auto& kv : body->map) {
      const std::string& key = kv.first;
      YamlRef value = std::const_pointer_cast<const YamlValue>(kv.second);
      const SomMetaNode* child = childByKey(node, key);
      if (child != nullptr) {
        std::string childPath = specPathJoin(path, child->segment());
        if (!loadChild(*child, childPath, key, value, err)) {
          return false;
        }
        continue;
      }
      if (key == "content") {
        std::string where = path + "/content";
        std::string v;
        if (!decoderScalarOf(value, where, &v, err)) {
          return false;
        }
        doc->setContent(path, v);
        continue;
      }
      if (key == "headline") {
        std::string v;
        if (!decoderScalarOf(value, path + " (headline)", &v, err)) {
          return false;
        }
        doc->setHeadline(path, v);
        continue;
      }
      if (key == "codeSpec") {
        std::string v;
        if (!decoderScalarOf(value, path + " (codeSpec)", &v, err)) {
          return false;
        }
        doc->setCodeSpec(path, v);
        continue;
      }
      setErr(err, "key `" + key + "` under `" + path + "` matches no member of " +
                      node.debugName() + " (expected one of: " +
                      expectedKeys(node) + ")");
      return false;
    }
    return true;
  }
};

}  // namespace

bool decodeYaml(const std::string& yamlText, const SomMetaTree& tree,
                SpecYamlContents* out, std::string* err) {
  // Blank input is not a mapping.
  std::size_t p = 0;
  while (p < yamlText.size() && (yamlText[p] == ' ' || yamlText[p] == '\t' ||
                                 yamlText[p] == '\r' || yamlText[p] == '\n')) {
    p++;
  }
  YamlPtr root;
  if (p < yamlText.size()) {
    root = yamlParse(yamlText);
  }
  if (root == nullptr || root->type != YamlType::Map) {
    setErr(err,
           "not a *.docspecs.yaml mapping (expected version/document keys)");
    return false;
  }

  YamlRef version = yamlGet(root, "version");
  std::string vstr = yamlScalarString(version);
  if (version == nullptr || vstr != "2") {
    std::string msg;
    if (version == nullptr) {
      msg = "missing `version:` (expected version: 2)";
    } else if (vstr == "1") {
      msg =
          "format version 1 (flat path-map) is no longer supported; re-save "
          "the document in the hierarchical v2 format";
    } else {
      msg = "unsupported format version `" + versionRepr(version) +
            "` (expected 2)";
    }
    setErr(err, msg);
    return false;
  }

  std::string stamp = yamlScalarString(yamlGet(root, "modelVersion"));

  // An absent key stays null so encode writes no pass; a present one —
  // `review: {}`, or a bare `review:` — is a pass (an empty map), written back.
  YamlRef rev = yamlGet(root, "review");
  YamlRef review =
      rev == nullptr ? nullptr
      : (rev->type == YamlType::Map && !rev->map.empty())
          ? rev
          : std::const_pointer_cast<const YamlValue>(newEmptyMap());

  SpecDocument document;
  document.modelVersion = stamp;

  YamlRef docPass = yamlGet(root, "document");
  if (docPass != nullptr && docPass->type != YamlType::Map) {
    setErr(err, "`document:` must be a mapping");
    return false;
  }
  if (docPass != nullptr && !docPass->map.empty()) {
    std::string rootKey = specYamlNodeKey(*tree.root());
    if (docPass->map.size() != 1 || docPass->map[0].first != rootKey) {
      std::string joined;
      for (std::size_t i = 0; i < docPass->map.size(); i++) {
        if (i > 0) {
          joined += ", ";
        }
        joined += "`" + docPass->map[i].first + "`";
      }
      setErr(err, "expected the single document root key `" + rootKey +
                      "`, found: " + joined);
      return false;
    }
    YamlRef body =
        std::const_pointer_cast<const YamlValue>(docPass->map[0].second);
    if (body == nullptr || body->type != YamlType::Map) {
      setErr(err,
             "root `" + rootKey + "` must hold a mapping, not a scalar");
      return false;
    }
    YamlDecoder d;
    d.doc = &document;
    d.tree = &tree;
    if (!d.loadMapping(*tree.root(), tree.root()->segment(), body, err)) {
      return false;
    }
  }

  out->document = std::move(document);
  out->review = review;
  out->modelVersion = stamp;
  return true;
}

YamlPtr specYamlRekeyReview(const YamlValue& review,
                            const SpecPathPairs& renamed) {
  auto out = std::make_shared<YamlValue>(YamlType::Map);
  if (review.type != YamlType::Map) {
    return out;
  }
  for (const auto& kv : review.map) {
    out->mapSet(specRekeyPath(kv.first, renamed), kv.second);
  }
  return out;
}

}  // namespace som
