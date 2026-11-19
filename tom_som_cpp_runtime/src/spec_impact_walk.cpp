/* spec_impact_walk — see include/spec_impact_walk.hpp. Port of the
 * TypeScript `spec_impact_walk.ts`. */
#include "spec_impact_walk.hpp"

#include <algorithm>
#include <regex>
#include <set>
#include <stdexcept>
#include <utility>

#include "som_json.hpp"
#include "spec_codespecs_extract.hpp"
#include "spec_paths.hpp"
#include "spec_reflection.hpp"

namespace som {

namespace {

std::string jsonStrArray(const std::vector<std::string>& v) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += jsonEncodeStr(v[i]);
  }
  return b + "]";
}

std::string jsonIntArray(const std::vector<int>& v) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += std::to_string(v[i]);
  }
  return b + "]";
}

const char* jsonBool(bool b) { return b ? "true" : "false"; }

std::string jsonFolders(const std::optional<std::vector<SpecImpactFolder>>& f) {
  if (!f.has_value()) return "null";
  std::string b = "[";
  for (std::size_t i = 0; i < f->size(); i++) {
    if (i > 0) b += ",";
    b += "{\"path\":" + jsonEncodeStr((*f)[i].path) +
         ",\"present\":" + jsonBool((*f)[i].present) + "}";
  }
  return b + "]";
}

/* Walks one root over one document. */
class ImpactWalker {
 public:
  ImpactWalker(const SpecModel& model, const SpecDocument& doc)
      : model_(model), doc_(doc) {
    for (const std::string& path : doc.contentPaths()) {
      if (doc.contentOpt(path) != nullptr) count(path);
    }
    for (const std::string& path : doc.formPaths()) {
      for (const std::string& field : doc.formFieldNames(path)) {
        if (doc.formFieldOpt(path, field) != nullptr) count(path);
      }
    }
  }

  std::vector<SpecImpactRow> walkRoot(const SpecRoot& root) {
    const SpecClass* cls = model_.classNamed(root.type);
    if (cls == nullptr) return std::move(rows_);
    const std::string segment = SpecReflection::rootSegment(root);
    classNode(kSpecImpactRowKindRoot, segment, segment, *cls, 0, {cls->name},
              std::nullopt);
    return std::move(rows_);
  }

 private:
  /* Adds one value at `path` to the path and each of its prefixes ending
   * before `/` or `-`. */
  void count(const std::string& path) {
    counts_[path]++;
    for (std::size_t i = path.size(); i-- > 1;) {
      if (path[i] == '/' || path[i] == '-') counts_[path.substr(0, i)]++;
    }
  }

  long long valuesAt(const std::string& path) const {
    auto it = counts_.find(path);
    return it != counts_.end() ? it->second : 0;
  }

  void push(const std::string& kind, const std::string& path,
            const std::string& chain, const std::string& className, int depth,
            std::optional<long long> items, const CodeSpecsRouting& routing) {
    const bool tmpl = path.find('*') != std::string::npos;
    SpecImpactRow row;
    row.path = path;
    row.chain = chain;
    row.kind = kind;
    row.className = className;
    row.depth = depth;
    row.filled = !tmpl && doc_.hasValuesUnder(path);
    row.values = tmpl ? 0 : valuesAt(path);
    row.items = items;
    row.routing = codeSpecsRoutingVerdictName(routing.verdict);
    row.routingValues = routing.values;
    row.routingDeclaredAt = routing.declaredAt;
    rows_.push_back(std::move(row));
  }

  void classNode(const std::string& kind, const std::string& path,
                 const std::string& chain, const SpecClass& cls, int depth,
                 const std::set<std::string>& ancestors,
                 const std::optional<CodeSpecsRouting>& process) {
    const CodeSpecsRouting routing =
        process.has_value() ? *process : codeSpecsClassRouting(cls, path);
    std::optional<CodeSpecsRouting> below;
    if (routing.verdict == CodeSpecsRoutingVerdict::FeedsProcess) {
      below = routing;
    }
    push(kind, path, chain, cls.name, depth, std::nullopt, routing);
    for (const SpecField& field : cls.fields) {
      const std::string segment = SpecReflection::fieldSegment(field);
      const std::string fieldPath = specPathJoin(path, segment);
      const std::string fieldChain = chain + " > " + segment;
      if (field.kind == kSpecFieldKindComplex ||
          field.kind == kSpecFieldKindSection) {
        const SpecClass* child = enter(field.type, ancestors);
        if (child != nullptr) {
          std::set<std::string> next = ancestors;
          next.insert(child->name);
          classNode(field.kind == kSpecFieldKindComplex
                        ? kSpecImpactRowKindComplex
                        : kSpecImpactRowKindSection,
                    fieldPath, fieldChain, *child, depth + 1, next, below);
        }
      } else if (field.kind == kSpecFieldKindList) {
        list(cls, field, fieldPath, fieldChain, depth + 1, ancestors, below);
      }
      // Any other kind is a value leaf: counted in this row.
    }
  }

  void list(const SpecClass& owner, const SpecField& field,
            const std::string& path, const std::string& chain, int depth,
            const std::set<std::string>& ancestors,
            const std::optional<CodeSpecsRouting>& process) {
    const bool tmpl = path.find('*') != std::string::npos;
    const std::vector<std::string> items =
        tmpl ? std::vector<std::string>() : doc_.listItems(path);
    const SpecClass* element =
        field.elementIsComplex ? model_.classNamed(field.elementType) : nullptr;
    CodeSpecsRouting routing;
    if (process.has_value()) {
      routing = *process;
    } else if (element != nullptr) {
      routing = codeSpecsClassRouting(*element, path);
    } else {
      std::optional<CodeSpecsRouting> own = codeSpecsFieldRouting(owner, field);
      routing = own.has_value() ? *own : codeSpecsClassRouting(owner, path);
    }
    push(kSpecImpactRowKindList, path, chain,
         element != nullptr ? element->name : std::string(), depth,
         static_cast<long long>(items.size()), routing);
    if (element == nullptr || ancestors.count(element->name) > 0) return;
    std::set<std::string> next = ancestors;
    next.insert(element->name);
    if (items.empty()) {
      classNode(kSpecImpactRowKindTemplate, path + "/*", chain + " > *",
                *element, depth + 1, next, process);
      return;
    }
    for (const std::string& itemPath : items) {
      const std::string* stored = doc_.itemSectionIdOpt(itemPath);
      const std::string id =
          stored != nullptr ? *stored
                            : itemPath.substr(itemPath.rfind('/') + 1);
      classNode(kSpecImpactRowKindItem, itemPath, chain + " > " + id, *element,
                depth + 1, next, process);
    }
  }

  const SpecClass* enter(const std::string& type,
                         const std::set<std::string>& ancestors) const {
    if (type.empty() || ancestors.count(type) > 0) return nullptr;
    return model_.classNamed(type);
  }

  const SpecModel& model_;
  const SpecDocument& doc_;
  std::vector<SpecImpactRow> rows_;
  /* Stored values per path prefix (a value counts at its own path and every
   * ancestor). */
  std::map<std::string, long long> counts_;
};

/* `\` to `/`, then one leading `./` dropped. */
std::vector<std::string> normalised(const std::vector<std::string>& listing) {
  std::vector<std::string> out;
  out.reserve(listing.size());
  for (std::string p : listing) {
    std::replace(p.begin(), p.end(), '\\', '/');
    if (p.compare(0, 2, "./") == 0) p.erase(0, 2);
    out.push_back(std::move(p));
  }
  return out;
}

bool matches(const std::string& s, const std::regex& re) {
  return std::regex_match(s, re);
}

std::string cell(const std::string& text) {
  std::string out;
  out.reserve(text.size());
  for (char ch : text) {
    if (ch == '|') out += '\\';
    out += ch;
  }
  return out;
}

std::string joinWith(const std::vector<std::string>& v, const std::string& sep) {
  std::string s;
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) s += sep;
    s += v[i];
  }
  return s;
}

std::string joinInts(const std::vector<int>& v) {
  std::vector<std::string> s;
  for (int i : v) s.push_back(std::to_string(i));
  return joinWith(s, ", ");
}

std::string orNone(const std::string& s) { return s.empty() ? "none" : s; }

std::string folders(const std::optional<std::vector<SpecImpactFolder>>& f) {
  if (!f.has_value()) return "not given";
  if (f->empty()) return "none";
  std::vector<std::string> parts;
  for (const SpecImpactFolder& x : *f) {
    parts.push_back("`" + x.path + "` (" +
                    (x.present ? "present" : "absent") + ")");
  }
  return joinWith(parts, ", ");
}

}  // namespace

std::string SpecImpactRow::toJson() const {
  return "{\"path\":" + jsonEncodeStr(path) +
         ",\"chain\":" + jsonEncodeStr(chain) +
         ",\"kind\":" + jsonEncodeStr(kind) +
         ",\"className\":" + jsonEncodeStr(className) +
         ",\"depth\":" + std::to_string(depth) +
         ",\"filled\":" + jsonBool(filled) +
         ",\"values\":" + std::to_string(values) + ",\"items\":" +
         (items.has_value() ? std::to_string(*items) : std::string("null")) +
         ",\"routing\":" + jsonEncodeStr(routing) +
         ",\"routingValues\":" + jsonStrArray(routingValues) +
         ",\"routingDeclaredAt\":" + jsonEncodeStr(routingDeclaredAt) + "}";
}

std::string SpecImpactRootWalk::toJson() const {
  std::string b = "{\"type\":" + jsonEncodeStr(type) +
                  ",\"sectionId\":" + jsonEncodeStr(sectionId) +
                  ",\"present\":" + jsonBool(present) + ",\"rows\":[";
  for (std::size_t i = 0; i < rows.size(); i++) {
    if (i > 0) b += ",";
    b += rows[i].toJson();
  }
  return b + "]}";
}

std::vector<SpecImpactRootWalk> specImpactWalk(
    const SpecModel& model,
    const std::map<std::string, SpecDocument>& documents) {
  for (const auto& kv : documents) {
    bool known = std::any_of(
        model.roots.begin(), model.roots.end(),
        [&](const SpecRoot& r) { return r.type == kv.first; });
    if (!known) {
      throw std::invalid_argument(
          "spec_impact_walk: the model has no document root " + kv.first);
    }
  }
  const SpecDocument empty;
  std::vector<SpecImpactRootWalk> out;
  for (const SpecRoot& root : model.roots) {
    auto it = documents.find(root.type);
    const bool present = it != documents.end();
    ImpactWalker walker(model, present ? it->second : empty);
    SpecImpactRootWalk w;
    w.type = root.type;
    w.sectionId = SpecReflection::rootSegment(root);
    w.present = present;
    w.rows = walker.walkRoot(root);
    out.push_back(std::move(w));
  }
  return out;
}

std::string SpecImpactLevel::toJson() const {
  std::string docs = "[";
  for (std::size_t i = 0; i < documents.size(); i++) {
    if (i > 0) docs += ",";
    docs += "{\"type\":" + jsonEncodeStr(documents[i].type) +
            ",\"sectionId\":" + jsonEncodeStr(documents[i].sectionId) +
            ",\"present\":" + jsonBool(documents[i].present) + "}";
  }
  docs += "]";
  return "{\"documents\":" + docs +
         ",\"projectIdea\":" + jsonBool(projectIdea) +
         ",\"extracts\":" + std::to_string(extracts) +
         ",\"gateRecord\":" + jsonBool(gateRecord) +
         ",\"ir\":" + std::to_string(ir) + ",\"gates\":" + jsonStrArray(gates) +
         ",\"tests\":" + jsonFolders(tests) + ",\"code\":" + jsonFolders(code) +
         ",\"phasesReached\":" + jsonIntArray(phasesReached) +
         ",\"phasesLeftOut\":" + jsonIntArray(phasesLeftOut) + "}";
}

SpecImpactLevel specImpactLevel(
    const SpecModel& model, const std::vector<SpecImpactRootWalk>& walk,
    const std::vector<std::string>& listing,
    const std::optional<std::vector<SpecImpactFolder>>& tests,
    const std::optional<std::vector<SpecImpactFolder>>& code) {
  static const std::regex kProjectIdea("phase1_[^/]*/[^/]+\\.md");
  static const std::regex kExtract(
      "generated-doc/codespecs_extracts/CE-[^/]+\\.extract\\.yaml");
  static const std::regex kIr("irspecs/[^/]+\\.ir\\.yaml");
  static const std::regex kGateChecklist("gates/G[^/]*\\.checklist\\.yaml");
  static const std::regex kGateReport("quality/evidence/gates/[^/]+\\.md");

  const std::vector<std::string> files = normalised(listing);
  SpecImpactLevel level;
  for (const SpecImpactRootWalk& w : walk) {
    level.documents.push_back({w.type, w.sectionId, w.present});
  }
  for (const std::string& f : files) {
    if (matches(f, kProjectIdea)) level.projectIdea = true;
    if (matches(f, kExtract)) level.extracts++;
    if (f == "generated-doc/codespecs_extracts/gate.verdicts.yaml") {
      level.gateRecord = true;
    }
    if (matches(f, kIr)) level.ir++;
    if (matches(f, kGateChecklist) || matches(f, kGateReport)) {
      level.gates.push_back(f);
    }
  }
  std::sort(level.gates.begin(), level.gates.end());
  level.tests = tests;
  level.code = code;

  auto present = [&](bool (*test)(const SpecModel&, const SpecRoot&)) {
    for (const SpecImpactRootWalk& w : walk) {
      if (!w.present) continue;
      for (const SpecRoot& r : model.roots) {
        if (r.type == w.type) {
          if (test(model, r)) return true;
          break;
        }
      }
    }
    return false;
  };
  auto anyPresent = [](const std::optional<std::vector<SpecImpactFolder>>& f) {
    return f.has_value() &&
           std::any_of(f->begin(), f->end(),
                       [](const SpecImpactFolder& x) { return x.present; });
  };
  std::vector<int>& reached = level.phasesReached;
  if (level.projectIdea) reached.push_back(1);
  if (present([](const SpecModel&, const SpecRoot& r) {
        return r.sectionId == "SBP";
      })) {
    reached.push_back(2);
  }
  if (present([](const SpecModel& m, const SpecRoot& r) {
        return r.sectionId != "SBP" && !m.isGenerationInput(r);
      })) {
    reached.push_back(3);
  }
  if (level.extracts > 0 || level.ir > 0) reached.push_back(4);
  if (anyPresent(tests)) reached.push_back(5);
  if (anyPresent(code)) reached.push_back(6);
  for (int p = 1; p <= 6; p++) {
    if (std::find(reached.begin(), reached.end(), p) == reached.end()) {
      level.phasesLeftOut.push_back(p);
    }
  }
  return level;
}

std::vector<std::string> specImpactDocumentFiles(
    const std::vector<std::string>& listing) {
  static const std::regex kDocument("phase[^/]*/[^/]+\\.docspecs\\.yaml");
  std::vector<std::string> out;
  for (const std::string& f : normalised(listing)) {
    if (matches(f, kDocument)) out.push_back(f);
  }
  std::sort(out.begin(), out.end());
  return out;
}

std::string specImpactWalkMarkdown(const std::vector<SpecImpactRootWalk>& walk,
                                   const SpecImpactLevel* level) {
  std::vector<std::string> out = {"# Impact walk", ""};
  out.push_back(
      "Every section of every document root, filled or not: the section-id "
      "chain, the model class, whether it holds values, and its CodeSpecs "
      "routing. A list counts its items; an empty list of sections shows what "
      "a new item holds at `<list>/*`.");
  out.push_back("");
  for (const SpecImpactRootWalk& root : walk) {
    std::size_t filled = 0;
    for (const SpecImpactRow& r : root.rows) {
      if (r.filled) filled++;
    }
    out.push_back("## " + root.sectionId + " — " + root.type +
                  (root.present ? "" : " (absent)"));
    out.push_back("");
    out.push_back(std::to_string(root.rows.size()) + " rows, " +
                  std::to_string(filled) + " holding values.");
    out.push_back("");
    out.push_back(
        "| Section-id chain | Path | Kind | Class | Values | Items | Routing |");
    out.push_back("| --- | --- | --- | --- | --- | --- | --- |");
    for (const SpecImpactRow& r : root.rows) {
      const std::string routing =
          r.routingValues.empty()
              ? r.routing
              : r.routing + ": " + joinWith(r.routingValues, ", ");
      out.push_back("| " + cell(r.chain) + " | `" + cell(r.path) + "` | " +
                    r.kind + " | " + cell(r.className) + " | " +
                    (r.filled ? std::to_string(r.values) : "—") + " | " +
                    (r.items.has_value() ? std::to_string(*r.items) : "") +
                    " | " + cell(routing) + " |");
    }
    out.push_back("");
  }
  if (level != nullptr) {
    auto yes = [](bool b) { return std::string(b ? "yes" : "no"); };
    std::vector<std::string> presentIds;
    std::vector<std::string> absentIds;
    for (const SpecImpactLevelDocument& d : level->documents) {
      (d.present ? presentIds : absentIds).push_back(d.sectionId);
    }
    std::vector<std::string> gates;
    for (const std::string& g : level->gates) gates.push_back("`" + g + "`");
    out.push_back("## Level");
    out.push_back("");
    out.push_back("- Documents present: " + orNone(joinWith(presentIds, ", ")));
    out.push_back("- Documents absent: " + orNone(joinWith(absentIds, ", ")));
    out.push_back("- Project Idea: " + yes(level->projectIdea));
    out.push_back("- CodeSpecs extracts: " + std::to_string(level->extracts) +
                  "; gate record: " + yes(level->gateRecord));
    out.push_back("- IR Specs: " + std::to_string(level->ir));
    out.push_back("- Gates: " + orNone(joinWith(gates, ", ")));
    out.push_back("- Tests: " + folders(level->tests));
    out.push_back("- Code: " + folders(level->code));
    out.push_back("- Phases reached: " + orNone(joinInts(level->phasesReached)) +
                  "; left out by a change: " +
                  orNone(joinInts(level->phasesLeftOut)) +
                  " (Phases 7–8 are not visible on disk)");
    out.push_back("");
  }
  return joinWith(out, "\n");
}

}  // namespace som
