/* spec_document_yaml — implementation. See spec_document_yaml.hpp; an
 * idiomatic-C++ port of the C `spec_document_yaml.c` (hierarchical format v2). */
#include "spec_document_yaml.hpp"

#include <algorithm>
#include <map>
#include <vector>

#include "som_json.hpp"
#include "som_util.hpp"
#include "spec_paths.hpp"
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
  if (node.sectionId.empty()) {
    return name;
  }
  return node.sectionId + " " + name;
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

/* A plain one-line scalar for a non-text value (§2.5) when writing it plainly
 * re-parses to exactly `value`. */
static bool plainScalarOk(const std::string& value) {
  if (value.empty() || value.find('\n') != std::string::npos) {
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
  std::map<std::string, std::string> content;  // consumed as the walk places
  std::vector<std::string> formPaths;          // remaining unconsumed
  std::vector<std::string> listPaths;          // remaining unconsumed

  void init(const SpecDocument* d) {
    doc = d;
    for (const std::string& path : d->contentPaths()) {
      const std::string* v = d->contentOpt(path);
      content[path] = v != nullptr ? *v : "";
    }
    formPaths = d->formPaths();
    listPaths = d->listPaths();
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

  bool writeForm(std::string& b, std::size_t indent, const std::string& key,
                 const SomMetaNode& node, const std::string& path,
                 std::string* err) {
    bool present = removeValue(formPaths, path);
    std::vector<std::string> names = doc->formFieldNames(path);
    if (!present || names.empty()) {
      return true;
    }
    for (const std::string& name : names) {
      if (!node.form.has_value() ||
          node.form->fieldNamed(name) == nullptr) {
        setErr(err, "form `" + path + "` holds a field `" + name +
                        "` unknown to the model");
        return false;
      }
    }
    b.append(indent, ' ');
    b += specYamlPlainKey(key);
    b += ":\n";
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
    const std::vector<std::string>* items = doc->listItemsPtr(path);
    if (items == nullptr || items->empty()) {
      return true;
    }
    b.append(indent, ' ');
    b += specYamlPlainKey(key);
    b += ":\n";
    std::vector<std::string> used;
    long long pos = 0;
    for (const std::string& itemPath : *items) {
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
        // Scalar list: the item is a direct value.
        std::string v;
        if (!takeContent(itemPath, &v)) {
          v = "";
        }
        writeValue(b, indent + 2, itemKey, v);
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

    // The node's own body text — the literal `content` key (DR1 §2.2).
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
        if (takeContent(childPath, &v)) {
          writeText(b, indent, key, v);
        }
      } else if (kind == kSomMetaKindScalar || kind == kSomMetaKindEnumValue) {
        std::string v;
        if (takeContent(childPath, &v)) {
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
                                      std::string* err) {
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
  if (body.empty()) {
    out += "document: {}\n";
  } else {
    out += "document:\n";
    out += "  ";
    out += specYamlPlainKey(specYamlNodeKey(*tree.root()));
    out += ":\n";
    out += body;
  }
  return out;
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
    joined += "`content`";
    return joined;
  }

  bool loadList(const SomMetaNode& node, const std::string& path,
                const YamlRef& items, std::string* err) {
    const std::string& member = node.memberName;
    for (const auto& kv : items->map) {
      const std::string& key = kv.first;
      YamlRef value = std::const_pointer_cast<const YamlValue>(kv.second);
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
        // Scalar list item: the value is the item itself.
        if (value != nullptr &&
            (value->type == YamlType::Seq ||
             (value->type == YamlType::Map && !value->map.empty()))) {
          setErr(err, "scalar list item `" + key + "` at `" + path +
                          "` must hold a scalar");
          return false;
        }
        if (value != nullptr && value->type != YamlType::Map) {
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
        if (!child.form.has_value() ||
            child.form->fieldNamed(name) == nullptr) {
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

  YamlRef rev = yamlGet(root, "review");
  YamlRef review = (rev != nullptr && rev->type == YamlType::Map)
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

}  // namespace som
