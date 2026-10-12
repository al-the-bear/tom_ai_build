/* Idiomatic-C++ port of the Dart `spec_codespecs_records` library. */
#include "spec_codespecs_records.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <sstream>

#include "som_json.hpp"
#include "yaml.hpp"

namespace som {
namespace {

/* ---- YAML access --------------------------------------------------------- */

/* How a YAML node reads under the core schema the Dart reader uses. */
enum class NodeKind { Null, Str, Int, Map, Seq, Other };

/* A plain scalar YAML 1.2's core schema reads as a float (`2.5`, `1e3`,
 * `.inf`, `.nan`). Plain integers are already integers in the reader. */
bool plainIsFloat(const std::string& s) {
  static const char* const kSpecial[] = {".inf",  "+.inf", "-.inf", ".Inf",
                                         "+.Inf", "-.Inf", ".INF",  "+.INF",
                                         "-.INF", ".nan",  ".NaN",  ".NAN"};
  for (const char* sp : kSpecial) {
    if (s == sp) {
      return true;
    }
  }
  std::size_t p = 0;
  auto digit = [&](std::size_t i) { return i < s.size() && s[i] >= '0' && s[i] <= '9'; };
  if (p < s.size() && (s[p] == '+' || s[p] == '-')) {
    p++;
  }
  int digits = 0;
  while (digit(p)) {
    p++;
    digits++;
  }
  if (p < s.size() && s[p] == '.') {
    p++;
    while (digit(p)) {
      p++;
      digits++;
    }
  }
  if (digits == 0) {
    return false;
  }
  if (p < s.size() && (s[p] == 'e' || s[p] == 'E')) {
    p++;
    if (p < s.size() && (s[p] == '+' || s[p] == '-')) {
      p++;
    }
    if (!digit(p)) {
      return false;
    }
    while (digit(p)) {
      p++;
    }
  }
  return p == s.size();
}

/* The node's kind. An absent node, a plain `null` / `~`, and a key written with
 * no value (which the reader yields as an empty mapping) read as null. */
NodeKind nodeKind(const YamlRef& v) {
  if (v == nullptr) {
    return NodeKind::Null;
  }
  switch (v->type) {
    case YamlType::Map:
      return v->map.empty() ? NodeKind::Null : NodeKind::Map;
    case YamlType::Seq:
      return NodeKind::Seq;
    case YamlType::Int:
      return NodeKind::Int;
    case YamlType::Str:
      if (v->plain) {
        const std::string& s = v->str;
        if (s.empty() || s == "null" || s == "Null" || s == "NULL" || s == "~") {
          return NodeKind::Null;
        }
        if (s == "true" || s == "True" || s == "TRUE" || s == "false" ||
            s == "False" || s == "FALSE" || plainIsFloat(s)) {
          return NodeKind::Other;
        }
      }
      return NodeKind::Str;
  }
  return NodeKind::Other;
}

/* The value as Dart's string interpolation renders it, for messages. */
std::string nodeText(const YamlRef& v) {
  return nodeKind(v) == NodeKind::Null ? std::string("null")
                                       : yamlScalarString(v);
}

[[noreturn]] void fail(const std::string& message) {
  throw CodeSpecsRecordError(message);
}

/* `_str`: "" for null, the string for a string; otherwise an error. */
std::string readStr(const YamlRef& v, const std::string& name,
                    const std::string& key) {
  NodeKind k = nodeKind(v);
  if (k == NodeKind::Null) {
    return std::string();
  }
  if (k == NodeKind::Str) {
    return v->str;
  }
  fail(name + ": `" + key + "` must be a string");
}

/* `_optStr`: unset for null, the string for a string; otherwise an error. */
std::optional<std::string> readOptStr(const YamlRef& v, const std::string& name,
                                      const std::string& key) {
  NodeKind k = nodeKind(v);
  if (k == NodeKind::Null) {
    return std::nullopt;
  }
  if (k == NodeKind::Str) {
    return v->str;
  }
  fail(name + ": `" + key + "` must be a string or null");
}

/* A non-empty flow list (`["a", "b"]`, `[5]`) as the reader hands it over — a
 * plain scalar — decoded as the JSON the extract writer emits it as. Null when
 * `v` is not such a scalar or does not decode to a JSON array. */
JsonPtr flowList(const YamlRef& v) {
  if (v == nullptr || v->type != YamlType::Str || !v->plain || v->str.empty() ||
      v->str[0] != '[') {
    return nullptr;
  }
  std::string err;
  JsonPtr j = jsonParse(v->str, &err);
  if (j == nullptr || j->type != JsonType::Array) {
    return nullptr;
  }
  return j;
}

/* `_strList`: empty for null; each element through `_str`. */
std::vector<std::string> readStrList(const YamlRef& v, const std::string& name,
                                     const std::string& key) {
  std::vector<std::string> out;
  if (nodeKind(v) == NodeKind::Null) {
    return out;
  }
  if (v->type == YamlType::Seq) {
    for (const YamlPtr& e : v->seq) {
      out.push_back(readStr(e, name, key));
    }
    return out;
  }
  JsonPtr j = flowList(v);
  if (j == nullptr) {
    fail(name + ": `" + key + "` must be a list");
  }
  for (const JsonPtr& e : j->array) {
    if (e->type == JsonType::Null) {
      out.emplace_back();
    } else if (e->type == JsonType::Str) {
      out.push_back(e->str);
    } else {
      fail(name + ": `" + key + "` must be a string");
    }
  }
  return out;
}

/* `_intList`: empty for null; every element must be an integer. */
std::vector<long long> readIntList(const YamlRef& v, const std::string& name,
                                   const std::string& key) {
  std::vector<long long> out;
  if (nodeKind(v) == NodeKind::Null) {
    return out;
  }
  if (v->type == YamlType::Seq) {
    for (const YamlPtr& e : v->seq) {
      if (nodeKind(e) != NodeKind::Int) {
        fail(name + ": `" + key + "` must hold integers");
      }
      out.push_back(e->integer);
    }
    return out;
  }
  JsonPtr j = flowList(v);
  if (j == nullptr) {
    fail(name + ": `" + key + "` must be a list");
  }
  for (const JsonPtr& e : j->array) {
    if (e->type != JsonType::Int) {
      fail(name + ": `" + key + "` must hold integers");
    }
    out.push_back(e->integer);
  }
  return out;
}

/* Whether `text` holds no YAML content at all (blank and comment lines only) —
 * the reader's empty mapping there is Dart's null document. */
bool yamlTextIsEmpty(const std::string& text) {
  std::istringstream in(text);
  std::string line;
  while (std::getline(in, line)) {
    std::size_t p = line.find_first_not_of(" \t\r");
    if (p != std::string::npos && line[p] != '#') {
      return false;
    }
  }
  return true;
}

/* `_rootMapping`: parses `text` and returns the document and its `key:`
 * mapping. */
std::pair<YamlPtr, YamlRef> rootMapping(const std::string& text,
                                        const std::string& name,
                                        const std::string& key) {
  YamlPtr doc = yamlParse(text);
  if (doc == nullptr || doc->type != YamlType::Map || yamlTextIsEmpty(text)) {
    fail(name + " does not hold a YAML mapping");
  }
  YamlRef root = yamlGet(doc, key);
  if (nodeKind(root) != NodeKind::Map) {
    fail(name + " has no top-level `" + key + ":` mapping");
  }
  return {doc, root};
}

/* `^CE-[A-Z]+$`. */
bool isAreaCode(const std::string& s) {
  if (s.size() <= 3 || s.compare(0, 3, "CE-") != 0) {
    return false;
  }
  return std::all_of(s.begin() + 3, s.end(),
                     [](char ch) { return ch >= 'A' && ch <= 'Z'; });
}

std::string basenameOf(const std::string& name) {
  std::size_t slash = name.rfind('/');
  return slash == std::string::npos ? name : name.substr(slash + 1);
}

bool endsWith(const std::string& s, const std::string& suffix) {
  return s.size() >= suffix.size() &&
         s.compare(s.size() - suffix.size(), suffix.size(), suffix) == 0;
}

}  // namespace

/* ---- the error ----------------------------------------------------------- */

CodeSpecsRecordError::CodeSpecsRecordError(std::string message)
    : message_(std::move(message)),
      rendered_("CodeSpecsRecordError: " + message_) {}

/* ---- extract files ------------------------------------------------------- */

CodeSpecsExtract parseCodeSpecsExtractYaml(const std::string& text,
                                           const std::string& source) {
  const std::string name = source.empty() ? std::string("the extract") : source;
  auto [doc, root] = rootMapping(text, name, "extract");
  YamlRef version = yamlGet(root, "formatVersion");
  if (nodeKind(version) != NodeKind::Int ||
      version->integer != kCodeSpecsExtractFormat) {
    fail(name + " declares extract format " + nodeText(version) +
         "; this reader understands " +
         std::to_string(kCodeSpecsExtractFormat) +
         " only — reading it would silently drop entries");
  }
  YamlRef area = yamlGet(root, "area");
  if (nodeKind(area) != NodeKind::Map) {
    fail(name + " has no `area:` mapping");
  }
  CodeSpecsExtract x;
  x.area.code = readStr(yamlGet(area, "code"), name, "area.code");
  if (x.area.code.empty()) {
    fail(name + " names no area code");
  }
  std::string part = readStr(yamlGet(area, "part"), name, "area.part");
  static const std::string kPrefix = "CodeSpecPart.";
  if (part.compare(0, kPrefix.size(), kPrefix) == 0) {
    part = part.substr(kPrefix.size());
  }
  x.area.part = part;
  YamlRef document = yamlGet(root, "document");
  NodeKind dk = nodeKind(document);
  if (dk != NodeKind::Null && dk != NodeKind::Map) {
    fail(name + ": `document` must be a mapping");
  }
  YamlRef entries = yamlGet(root, "entries");
  NodeKind ek = nodeKind(entries);
  if (ek != NodeKind::Null && ek != NodeKind::Seq) {
    fail(name + ": `entries` must be a list");
  }
  if (ek == NodeKind::Seq) {
    for (const YamlPtr& raw : entries->seq) {
      if (nodeKind(raw) != NodeKind::Map) {
        fail(name + " has an entry that is not a mapping");
      }
      // In the Dart constructor's argument order, so the first bad key is the
      // one reported.
      auto req = [&](const char* key) {
        return readStr(yamlGet(raw, key), name, std::string("entries[].") + key);
      };
      auto opt = [&](const char* key) {
        return readOptStr(yamlGet(raw, key), name,
                          std::string("entries[].") + key);
      };
      CodeSpecsExtractEntry e;
      e.areaCode = x.area.code;
      e.sectionId = req("sectionId");
      e.headline = opt("headline");
      e.instanceId = opt("instanceId");
      e.path = req("path");
      e.className = req("className");
      e.fieldName = req("fieldName");
      e.formField = opt("formField");
      e.routedBy = req("routedBy");
      e.routedAt = req("routedAt");
      e.routingNote = opt("routingNote");
      e.value = req("value");
      x.entries.push_back(std::move(e));
    }
  }
  YamlRef declared = dk == NodeKind::Map ? yamlGet(document, "entryCount")
                                         : YamlRef();
  if (nodeKind(declared) != NodeKind::Null &&
      (nodeKind(declared) != NodeKind::Int ||
       declared->integer != static_cast<long long>(x.entries.size()))) {
    fail(name + " declares entryCount " + nodeText(declared) + " but carries " +
         std::to_string(x.entries.size()) +
         " entries — a truncated extract must not read as a complete one");
  }
  x.area.canonicalId =
      readStr(yamlGet(area, "canonicalId"), name, "area.canonicalId");
  x.area.annotations =
      readStrList(yamlGet(area, "annotations"), name, "area.annotations");
  x.area.builtOn = readStr(yamlGet(area, "builtOn"), name, "area.builtOn");
  x.area.attributeSurface = readStr(yamlGet(area, "attributeSurface"), name,
                                    "area.attributeSurface");
  x.area.slices = readIntList(yamlGet(area, "slices"), name, "area.slices");
  x.area.authoringSteps =
      readIntList(yamlGet(area, "authoringSteps"), name, "area.authoringSteps");
  x.area.active = true;
  x.documentRoot =
      readStr(dk == NodeKind::Map ? yamlGet(document, "root") : YamlRef(), name,
              "document.root");
  x.catalogSource =
      readStr(yamlGet(root, "catalogSource"), name, "catalogSource");
  x.projects = readStrList(yamlGet(area, "projects"), name, "area.projects");
  x.citableParts =
      readStrList(yamlGet(area, "citableParts"), name, "area.citableParts");
  return x;
}

CodeSpecsExtract CodeSpecsExtract::fromYaml(const std::string& text,
                                            const std::string& source) {
  return parseCodeSpecsExtractYaml(text, source);
}

/* ---- the gate record ----------------------------------------------------- */

const char* codeSpecsGateVerdictWord(CodeSpecsGateVerdict verdict) {
  switch (verdict) {
    case CodeSpecsGateVerdict::Sufficient:
      return "sufficient";
    case CodeSpecsGateVerdict::NotApplicable:
      return "not applicable";
    case CodeSpecsGateVerdict::Insufficient:
      return "insufficient";
  }
  return "";
}

std::optional<CodeSpecsGateVerdict> parseCodeSpecsGateVerdict(
    const std::string& word) {
  if (word == "sufficient") return CodeSpecsGateVerdict::Sufficient;
  if (word == "not applicable") return CodeSpecsGateVerdict::NotApplicable;
  if (word == "insufficient") return CodeSpecsGateVerdict::Insufficient;
  return std::nullopt;
}

CodeSpecsGateRecord::CodeSpecsGateRecord(
    std::vector<CodeSpecsGateEntry> verdicts, const std::string& source)
    : verdicts_(std::move(verdicts)) {
  check(source);
}

void CodeSpecsGateRecord::check(const std::string& source) const {
  for (std::size_t i = 0; i < verdicts_.size(); i++) {
    const CodeSpecsGateEntry& e = verdicts_[i];
    if (e.area.empty()) {
      fail(source + " has a verdict that names no area");
    }
    if (!isAreaCode(e.area)) {
      fail(source + " names the area `" + e.area +
           "`, which is not a CE-* code");
    }
    for (std::size_t k = 0; k < i; k++) {
      if (verdicts_[k].area == e.area) {
        fail(source + " carries two verdicts for " + e.area +
             " — a scope with two answers for one area is no scope");
      }
    }
    if (!e.resolution.has_value()) {
      continue;
    }
    if (e.verdict != CodeSpecsGateVerdict::Insufficient) {
      fail(source + " gives " + e.area + " a `resolution:` on verdict `" +
           codeSpecsGateVerdictWord(e.verdict) +
           "` — only an insufficient area has an L0 decision to resolve");
    }
    if (*e.resolution != kCodeSpecsGateDescoped) {
      fail(source + " gives " + e.area + " the resolution `" + *e.resolution +
           "` — `descoped` is the one resolution that admits a partial pass; "
           "any other resolution means the area was completed and its verdict "
           "re-taken");
    }
  }
}

CodeSpecsGateRecord CodeSpecsGateRecord::fromYaml(const std::string& text,
                                                  const std::string& source) {
  auto [doc, root] = rootMapping(text, source, "gate");
  for (const auto& kv : root->map) {
    if (kv.first != "formatVersion" && kv.first != "verdicts") {
      fail(source + " has an unknown key `gate." + kv.first +
           "` — the record knows `formatVersion` and `verdicts` only");
    }
  }
  YamlRef version = yamlGet(root, "formatVersion");
  if (nodeKind(version) != NodeKind::Int ||
      version->integer != kCodeSpecsGateRecordFormat) {
    fail(source + " declares gate record format " + nodeText(version) +
         "; this reader understands " +
         std::to_string(kCodeSpecsGateRecordFormat) +
         " only — reading it would silently change the scope");
  }
  YamlRef list = yamlGet(root, "verdicts");
  if (nodeKind(list) != NodeKind::Seq) {
    fail(source + " has no `verdicts:` list");
  }
  std::vector<CodeSpecsGateEntry> entries;
  for (const YamlPtr& raw : list->seq) {
    if (nodeKind(raw) != NodeKind::Map) {
      fail(source + " has a verdict that is not a mapping");
    }
    for (const auto& kv : raw->map) {
      if (kv.first != "area" && kv.first != "verdict" &&
          kv.first != "resolution" && kv.first != "note") {
        fail(source + " has an unknown key `" + kv.first +
             "` in a verdict — an entry knows `area`, `verdict`, "
             "`resolution` and `note` only");
      }
    }
    CodeSpecsGateEntry e;
    e.area = readStr(yamlGet(raw, "area"), source, "verdicts[].area");
    std::string word =
        readStr(yamlGet(raw, "verdict"), source, "verdicts[].verdict");
    std::optional<CodeSpecsGateVerdict> verdict =
        parseCodeSpecsGateVerdict(word);
    if (!verdict.has_value()) {
      fail(source + " gives " + e.area + " the verdict `" + word +
           "` — codespecs_prompt.md §6.2 knows `sufficient`, `not applicable` "
           "and `insufficient` only");
    }
    e.verdict = *verdict;
    e.resolution =
        readOptStr(yamlGet(raw, "resolution"), source, "verdicts[].resolution");
    e.note = readOptStr(yamlGet(raw, "note"), source, "verdicts[].note");
    entries.push_back(std::move(e));
  }
  return CodeSpecsGateRecord(std::move(entries), source);
}

const CodeSpecsGateEntry* CodeSpecsGateRecord::verdictFor(
    const std::string& area) const {
  for (const CodeSpecsGateEntry& e : verdicts_) {
    if (e.area == area) {
      return &e;
    }
  }
  return nullptr;
}

void CodeSpecsGateRecord::checkAgainst(const CodeSpecsAreaCatalog& catalog,
                                       const std::string& source) const {
  for (const CodeSpecsGateEntry& e : verdicts_) {
    const CodeSpecsArea* area = catalog.byCode(e.area);
    if (area == nullptr || !area->active) {
      fail(source + " gives a verdict for " + e.area +
           ", which is not an active area of the catalogue");
    }
  }
}

CodeSpecsGateRecord CodeSpecsGateRecord::withVerdict(
    const CodeSpecsGateEntry& entry) const {
  std::vector<CodeSpecsGateEntry> out;
  bool replaced = false;
  for (const CodeSpecsGateEntry& e : verdicts_) {
    if (e.area == entry.area) {
      out.push_back(entry);
      replaced = true;
    } else {
      out.push_back(e);
    }
  }
  if (!replaced) {
    out.push_back(entry);
  }
  return CodeSpecsGateRecord(std::move(out));
}

std::string CodeSpecsGateRecord::toYaml() const {
  std::string b = "gate:\n  formatVersion: " +
                  std::to_string(kCodeSpecsGateRecordFormat) + "\n";
  if (verdicts_.empty()) {
    b += "  verdicts: []\n";
    return b;
  }
  b += "  verdicts:\n";
  for (const CodeSpecsGateEntry& e : verdicts_) {
    b += "    - area: " + e.area + "\n";
    b += std::string("      verdict: ") + codeSpecsGateVerdictWord(e.verdict) +
         "\n";
    if (e.resolution.has_value()) {
      b += "      resolution: " + *e.resolution + "\n";
    }
    if (e.note.has_value()) {
      b += "      note: " + codeSpecsYamlString(*e.note) + "\n";
    }
  }
  return b;
}

/* ---- a tree of extracts, scoped by its gate record ----------------------- */

CodeSpecsExtractSet CodeSpecsExtractSet::fromFiles(
    const std::vector<std::pair<std::string, std::string>>& files) {
  std::optional<std::size_t> gateIndex;
  std::vector<CodeSpecsExtract> extracts;
  std::vector<std::string> sources;
  auto indexOf = [&](const std::string& area) -> long {
    for (std::size_t i = 0; i < extracts.size(); i++) {
      if (extracts[i].area.code == area) {
        return static_cast<long>(i);
      }
    }
    return -1;
  };
  for (std::size_t f = 0; f < files.size(); f++) {
    const std::string& name = files[f].first;
    if (basenameOf(name) == kCodeSpecsGateRecordFile) {
      if (gateIndex.has_value()) {
        fail("both " + files[*gateIndex].first + " and " + name +
             " are gate records — the scope must have one author");
      }
      gateIndex = f;
      continue;
    }
    CodeSpecsExtract x = parseCodeSpecsExtractYaml(files[f].second, name);
    long earlier = indexOf(x.area.code);
    if (earlier >= 0) {
      fail(sources[static_cast<std::size_t>(earlier)] + " and " + name +
           " are both extracts for " + x.area.code);
    }
    extracts.push_back(std::move(x));
    sources.push_back(name);
  }
  CodeSpecsExtractSet set;
  if (!gateIndex.has_value()) {
    set.extracts_ = std::move(extracts);
    set.sources_ = std::move(sources);
    return set;
  }
  const std::string& gateName = files[*gateIndex].first;
  CodeSpecsGateRecord gate =
      CodeSpecsGateRecord::fromYaml(files[*gateIndex].second, gateName);
  for (std::size_t i = 0; i < extracts.size(); i++) {
    if (gate.verdictFor(extracts[i].area.code) == nullptr) {
      fail(gateName + " carries no verdict for " + extracts[i].area.code +
           " (" + sources[i] +
           ") — the gate record must be total over the supplied extracts");
    }
  }
  for (const CodeSpecsGateEntry& v : gate.verdicts()) {
    long i = indexOf(v.area);
    const CodeSpecsExtract* x =
        i < 0 ? nullptr : &extracts[static_cast<std::size_t>(i)];
    std::string src = i < 0 ? std::string() : sources[static_cast<std::size_t>(i)];
    std::size_t count = x == nullptr ? 0 : x->entries.size();
    switch (v.verdict) {
      case CodeSpecsGateVerdict::Sufficient:
        if (x != nullptr) {
          set.extracts_.push_back(*x);
          set.sources_.push_back(src);
        }
        break;
      case CodeSpecsGateVerdict::NotApplicable:
        if (count > 0) {
          fail(gateName + " marks " + v.area + " `not applicable`, but " + src +
               " carries " + std::to_string(count) + " routed entr" +
               (count == 1 ? "y" : "ies") +
               " — a routed value is evidence the area applies "
               "(codespecs_prompt.md §6.4)");
        }
        set.excluded_.push_back({v.area, v.verdict, false, count, src});
        break;
      case CodeSpecsGateVerdict::Insufficient:
        if (!v.descoped()) {
          fail(gateName + " marks " + v.area +
               " `insufficient` without `resolution: descoped` — "
               "codespecs_prompt.md §6.2 says the run does not continue past "
               "an unresolved insufficient area; recording the descope is what "
               "legitimizes a partial pass");
        }
        set.excluded_.push_back({v.area, v.verdict, true, count, src});
        break;
    }
  }
  set.gate_ = std::move(gate);
  return set;
}

CodeSpecsExtractSet CodeSpecsExtractSet::fromDirectory(const std::string& path) {
  namespace fs = std::filesystem;
  std::error_code ec;
  if (!fs::is_directory(path, ec)) {
    fail("extract directory not found: " + path);
  }
  std::vector<std::string> names;
  for (const fs::directory_entry& entry : fs::directory_iterator(path, ec)) {
    // is_regular_file follows a symlink, as Dart's listing does.
    std::error_code fileEc;
    if (!entry.is_regular_file(fileEc)) {
      continue;
    }
    std::string n = entry.path().filename().string();
    if (endsWith(n, kCodeSpecsExtractFileSuffix) ||
        n == kCodeSpecsGateRecordFile) {
      names.push_back(n);
    }
  }
  if (ec) {
    fail("extract directory not found: " + path);
  }
  std::sort(names.begin(), names.end());
  std::vector<std::pair<std::string, std::string>> files;
  for (const std::string& n : names) {
    std::string full = path + "/" + n;
    std::ifstream in(full, std::ios::binary);
    if (!in) {
      fail("cannot read " + full);
    }
    std::ostringstream ss;
    ss << in.rdbuf();
    files.emplace_back(n, ss.str());
  }
  return fromFiles(files);
}

const CodeSpecsExtract* CodeSpecsExtractSet::byArea(
    const std::string& area) const {
  for (const CodeSpecsExtract& x : extracts_) {
    if (x.area.code == area) {
      return &x;
    }
  }
  return nullptr;
}

std::vector<const CodeSpecsExtractEntry*> CodeSpecsExtractSet::entriesForSection(
    const std::string& sectionId) const {
  std::vector<const CodeSpecsExtractEntry*> out;
  for (const CodeSpecsExtract& x : extracts_) {
    for (const CodeSpecsExtractEntry& e : x.entries) {
      if (e.sectionId == sectionId) {
        out.push_back(&e);
      }
    }
  }
  return out;
}

std::vector<const CodeSpecsExtractEntry*> CodeSpecsExtractSet::entriesAtPath(
    const std::string& path) const {
  std::vector<const CodeSpecsExtractEntry*> out;
  for (const CodeSpecsExtract& x : extracts_) {
    for (const CodeSpecsExtractEntry& e : x.entries) {
      if (e.path == path) {
        out.push_back(&e);
      }
    }
  }
  return out;
}

}  // namespace som
