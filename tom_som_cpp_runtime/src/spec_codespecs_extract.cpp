/* Idiomatic-C++ port of the Dart `spec_codespecs_extract` library. */
#include "spec_codespecs_extract.hpp"

#include <algorithm>

#include "spec_paths.hpp"

namespace som {
namespace {

/* ---- shared emission helpers -------------------------------------------- */

/* Appends `line` plus the newline the Dart original's StringBuffer.writeln
 * adds. */
void writeln(std::string& b, const std::string& line) {
  b += line;
  b += "\n";
}

std::vector<std::string> stringList(const JsonRef& raw) {
  std::vector<std::string> out;
  std::size_t n = jsonArrayLen(raw);
  for (std::size_t i = 0; i < n; i++) {
    const std::string* s = jsonAsStr(jsonArrayAt(raw, i));
    if (s != nullptr) {
      out.push_back(*s);
    }
  }
  return out;
}

std::vector<long long> intList(const JsonRef& raw) {
  std::vector<long long> out;
  std::size_t n = jsonArrayLen(raw);
  for (std::size_t i = 0; i < n; i++) {
    std::optional<long long> v = jsonAsI64(jsonArrayAt(raw, i));
    if (v.has_value()) {
      out.push_back(*v);
    }
  }
  return out;
}

/* A JSON string literal, which is also a valid YAML 1.2 double-quoted scalar.
 * Hand-written rather than delegated to a JSON encoder so the eight ports have
 * one rule to transcribe rather than nine encoders to hope agree.
 *
 * The Dart original walks Unicode code points (`value.runes`); here the string
 * holds UTF-8 bytes. The two agree byte for byte because every escaped case is
 * ASCII (`"`, `\`, and the C0 controls) and a UTF-8 continuation or lead byte is
 * always >= 0x80, so no byte of a multi-byte code point can match an escape or
 * fall into the `< 0x20` branch — every one of them is copied through
 * untouched, which is exactly what writeCharCode does for the whole code
 * point. */
std::string yamlString(const std::string& value) {
  std::string b = "\"";
  for (char raw : value) {
    unsigned char c = static_cast<unsigned char>(raw);
    switch (c) {
      case 0x22:
        b += "\\\"";
        break;
      case 0x5C:
        b += "\\\\";
        break;
      case 0x08:
        b += "\\b";
        break;
      case 0x0C:
        b += "\\f";
        break;
      case 0x0A:
        b += "\\n";
        break;
      case 0x0D:
        b += "\\r";
        break;
      case 0x09:
        b += "\\t";
        break;
      default:
        if (c < 0x20) {
          static const char kHex[] = "0123456789abcdef";
          b += "\\u00";
          b += kHex[(c >> 4) & 0xF];
          b += kHex[c & 0xF];
        } else {
          b += static_cast<char>(c);
        }
        break;
    }
  }
  b += "\"";
  return b;
}

std::string yamlNullableString(const std::optional<std::string>& value) {
  return value.has_value() ? yamlString(*value) : std::string("null");
}

std::string yamlStringList(const std::vector<std::string>& values) {
  std::string out = "[";
  for (std::size_t i = 0; i < values.size(); i++) {
    if (i > 0) {
      out += ", ";
    }
    out += yamlString(values[i]);
  }
  out += "]";
  return out;
}

std::string yamlIntList(const std::vector<long long>& values) {
  std::string out = "[";
  for (std::size_t i = 0; i < values.size(); i++) {
    if (i > 0) {
      out += ", ";
    }
    out += std::to_string(values[i]);
  }
  out += "]";
  return out;
}

/* A markdown table cell: newlines folded to a space (a cell cannot hold one) and
 * `|` escaped. Applied only to catalogue prose, never to a stored value — values
 * go into fenced blocks, where they stay verbatim. */
std::string mdCell(const std::string& value) {
  std::string out;
  out.reserve(value.size());
  for (char c : value) {
    if (c == '\n') {
      out += ' ';
    } else if (c == '|') {
      out += "\\|";
    } else {
      out += c;
    }
  }
  return out;
}

std::string mdCodeList(const std::vector<std::string>& values) {
  if (values.empty()) {
    return "—";
  }
  std::string out;
  for (std::size_t i = 0; i < values.size(); i++) {
    if (i > 0) {
      out += ", ";
    }
    out += "`" + values[i] + "`";
  }
  return out;
}

std::string mdIntList(const std::vector<long long>& values) {
  if (values.empty()) {
    return "—";
  }
  std::string out;
  for (std::size_t i = 0; i < values.size(); i++) {
    if (i > 0) {
      out += ", ";
    }
    out += std::to_string(values[i]);
  }
  return out;
}

/* The shortest backtick fence that cannot be closed by `value`'s own content. */
std::string fenceFor(const std::string& value) {
  std::size_t longest = 0;
  std::size_t run = 0;
  for (char c : value) {
    if (c == 0x60) {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 0;
    }
  }
  std::size_t width = longest >= 3 ? longest + 1 : 3;
  return std::string(width, '`');
}

}  // namespace

/* ---- routing ------------------------------------------------------------ */

const char* codeSpecsRoutingVerdictName(CodeSpecsRoutingVerdict verdict) {
  switch (verdict) {
    case CodeSpecsRoutingVerdict::FeedsCode:
      return "feedsCode";
    case CodeSpecsRoutingVerdict::FeedsProcess:
      return "feedsProcess";
    case CodeSpecsRoutingVerdict::FeedsNothing:
      return "feedsNothing";
    case CodeSpecsRoutingVerdict::DocumentRoot:
      return "documentRoot";
    case CodeSpecsRoutingVerdict::Unrouted:
      return "unrouted";
  }
  return "unrouted";
}

std::string CodeSpecsRouting::display() const {
  return "CodeSpecsRouting(" + path + ", " + className + ", " +
         codeSpecsRoutingVerdictName(verdict) + ")";
}

std::string CodeSpecsExtractEntry::display() const {
  return "CodeSpecsExtractEntry(" + areaCode + ", " + path + ")";
}

/* ---- the catalogue ------------------------------------------------------ */

CodeSpecsSlice CodeSpecsSlice::fromJson(const JsonRef& j) {
  CodeSpecsSlice out;
  out.number = jsonAsI64(jsonGet(j, "number")).value_or(0);
  out.title = jsonStrOr(j, "title");
  out.project = jsonStrOr(j, "project");
  out.cites = intList(jsonGet(j, "cites"));
  return out;
}

CodeSpecsArea CodeSpecsArea::fromJson(const JsonRef& j) {
  CodeSpecsArea out;
  out.code = jsonStrOr(j, "code");
  out.canonicalId = jsonStrOr(j, "canonicalId");
  out.part = jsonStrOr(j, "part");
  out.annotations = stringList(jsonGet(j, "annotations"));
  out.builtOn = jsonStrOr(j, "builtOn");
  out.attributeSurface = jsonStrOr(j, "attributeSurface");
  out.slices = intList(jsonGet(j, "slices"));
  out.authoringSteps = intList(jsonGet(j, "authoringSteps"));
  out.active = jsonAsBool(jsonGet(j, "active")).value_or(true);
  return out;
}

std::string CodeSpecsArea::kindValue() const { return "CodeSpecPart." + part; }

std::string CodeSpecsArea::display() const {
  return "CodeSpecsArea(" + code + ")";
}

CodeSpecsAreaCatalog CodeSpecsAreaCatalog::fromJson(const JsonRef& j) {
  CodeSpecsAreaCatalog out;
  out.source = jsonStrOr(j, "source");
  JsonRef slices = jsonGet(j, "slices");
  std::size_t sn = jsonArrayLen(slices);
  for (std::size_t i = 0; i < sn; i++) {
    out.slices.push_back(CodeSpecsSlice::fromJson(jsonArrayAt(slices, i)));
  }
  JsonRef areas = jsonGet(j, "areas");
  std::size_t an = jsonArrayLen(areas);
  for (std::size_t i = 0; i < an; i++) {
    out.areas.push_back(CodeSpecsArea::fromJson(jsonArrayAt(areas, i)));
  }
  return out;
}

std::vector<CodeSpecsArea> CodeSpecsAreaCatalog::activeAreas() const {
  std::vector<CodeSpecsArea> out;
  for (const CodeSpecsArea& a : areas) {
    if (a.active) {
      out.push_back(a);
    }
  }
  return out;
}

const CodeSpecsArea* CodeSpecsAreaCatalog::byCode(const std::string& code) const {
  for (const CodeSpecsArea& a : areas) {
    if (a.code == code) {
      return &a;
    }
  }
  return nullptr;
}

const CodeSpecsArea* CodeSpecsAreaCatalog::byPart(
    const std::string& value) const {
  static const std::string kPrefix = "CodeSpecPart.";
  std::string bare =
      (value.size() >= kPrefix.size() &&
       value.compare(0, kPrefix.size(), kPrefix) == 0)
          ? value.substr(kPrefix.size())
          : value;
  for (const CodeSpecsArea& a : areas) {
    if (a.part == bare) {
      return &a;
    }
  }
  return nullptr;
}

const CodeSpecsSlice* CodeSpecsAreaCatalog::sliceNumbered(
    long long number) const {
  for (const CodeSpecsSlice& s : slices) {
    if (s.number == number) {
      return &s;
    }
  }
  return nullptr;
}

std::vector<std::string> CodeSpecsAreaCatalog::projectsFor(
    const CodeSpecsArea& area) const {
  std::vector<std::string> out;
  for (long long n : area.slices) {
    const CodeSpecsSlice* slice = sliceNumbered(n);
    if (slice == nullptr || slice->project.empty() ||
        std::find(out.begin(), out.end(), slice->project) != out.end()) {
      continue;
    }
    out.push_back(slice->project);
  }
  return out;
}

std::vector<std::string> CodeSpecsAreaCatalog::citableAreaCodes(
    const CodeSpecsArea& area) const {
  std::set<long long> reachable;
  std::vector<long long> stack(area.slices);
  while (!stack.empty()) {
    long long n = stack.back();
    stack.pop_back();
    if (!reachable.insert(n).second) {
      continue;
    }
    const CodeSpecsSlice* slice = sliceNumbered(n);
    if (slice == nullptr) {
      continue;
    }
    stack.insert(stack.end(), slice->cites.begin(), slice->cites.end());
  }
  std::vector<std::string> out;
  for (const CodeSpecsArea& a : areas) {
    if (!a.active || a.code == area.code) {
      continue;
    }
    for (long long s : a.slices) {
      if (reachable.count(s) != 0) {
        out.push_back(a.code);
        break;
      }
    }
  }
  return out;
}

/* ---- the extract -------------------------------------------------------- */

std::string CodeSpecsExtract::fileStem() const {
  return area.code + ".extract";
}

std::string CodeSpecsExtract::toYaml() const {
  std::string b;
  writeln(b, "# " + area.code +
                 ".extract.yaml — generated by spec_codespecs_extract. Do not "
                 "edit.");
  writeln(b, "extract:");
  writeln(b, "  formatVersion: " + std::to_string(kCodeSpecsExtractFormat));
  writeln(b, "  catalogSource: " + yamlString(catalogSource));
  writeln(b, "  area:");
  writeln(b, "    code: " + yamlString(area.code));
  writeln(b, "    canonicalId: " + yamlString(area.canonicalId));
  writeln(b, "    part: " + yamlString(area.kindValue()));
  writeln(b, "    annotations: " + yamlStringList(area.annotations));
  writeln(b, "    builtOn: " + yamlString(area.builtOn));
  writeln(b, "    attributeSurface: " + yamlString(area.attributeSurface));
  writeln(b, "    slices: " + yamlIntList(area.slices));
  writeln(b, "    authoringSteps: " + yamlIntList(area.authoringSteps));
  writeln(b, "    projects: " + yamlStringList(projects));
  writeln(b, "    citableParts: " + yamlStringList(citableParts));
  writeln(b, "  document:");
  writeln(b, "    root: " + yamlString(documentRoot));
  writeln(b, "    entryCount: " + std::to_string(entries.size()));
  if (entries.empty()) {
    writeln(b, "  entries: []");
    return b;
  }
  writeln(b, "  entries:");
  for (const CodeSpecsExtractEntry& e : entries) {
    writeln(b, "    - sectionId: " + yamlString(e.sectionId));
    writeln(b, "      path: " + yamlString(e.path));
    writeln(b, "      className: " + yamlString(e.className));
    writeln(b, "      fieldName: " + yamlString(e.fieldName));
    writeln(b, "      formField: " + yamlNullableString(e.formField));
    writeln(b, "      routedBy: " + yamlString(e.routedBy));
    writeln(b, "      routedAt: " + yamlString(e.routedAt));
    writeln(b, "      routingNote: " + yamlNullableString(e.routingNote));
    writeln(b, "      value: " + yamlString(e.value));
  }
  return b;
}

std::string CodeSpecsExtract::toMarkdown() const {
  std::string b;
  writeln(b, "# " + area.code + " — " + area.canonicalId);
  writeln(b, "");
  writeln(b,
          "Generated by `spec_codespecs_extract` from the specification "
          "document rooted at `" +
              documentRoot + "`.");
  writeln(b, "`" + area.code +
                 ".extract.yaml` beside this file is the artifact of record; "
                 "this is a view of it.");
  writeln(b, "");
  writeln(b, "## Area");
  writeln(b, "");
  writeln(b, "| | |");
  writeln(b, "|---|---|");
  writeln(b, "| CE code | `" + area.code + "` |");
  writeln(b, "| Canonical id | `" + area.canonicalId + "` |");
  writeln(b, "| `@CodeSpecKind` value | `" + area.kindValue() + "` |");
  writeln(b, "| `Cs*` annotations | " + mdCodeList(area.annotations) + " |");
  writeln(b, "| Built on | " + mdCell(area.builtOn) + " |");
  writeln(b, "| Attribute surface | " + mdCell(area.attributeSurface) + " |");
  writeln(b, "| Slice(s) | " + mdIntList(area.slices) + " |");
  writeln(b, "| Authoring step(s) | " + mdIntList(area.authoringSteps) + " |");
  writeln(b, "| Project(s) | " + mdCodeList(projects) + " |");
  writeln(b, "| May cite | " + mdCodeList(citableParts) + " |");
  writeln(b, "| Catalogue source | " + mdCell(catalogSource) + " |");
  writeln(b, "");
  writeln(b, "## Entries (" + std::to_string(entries.size()) + ")");
  writeln(b, "");
  if (entries.empty()) {
    writeln(b, "_No section of this document is routed to `" +
                   area.kindValue() + "`._");
    return b;
  }
  long long n = 0;
  for (const CodeSpecsExtractEntry& e : entries) {
    n++;
    std::string member = !e.formField.has_value()
                             ? e.fieldName
                             : e.fieldName + "." + *e.formField;
    writeln(b, "### " + std::to_string(n) + ". `" + e.sectionId + "` — `" +
                   e.className + "." + member + "`");
    writeln(b, "");
    writeln(b, "- path: `" + e.path + "`");
    writeln(b, "- routed by: `" + e.routedBy + "` declared on `" + e.routedAt +
                   "`");
    if (e.routingNote.has_value()) {
      writeln(b, "- routing note: " + mdCell(*e.routingNote));
    }
    writeln(b, "");
    std::string fence = fenceFor(e.value);
    writeln(b, fence + " text");
    writeln(b, e.value);
    writeln(b, fence);
    writeln(b, "");
  }
  return b;
}

/* ---- the error ---------------------------------------------------------- */

CodeSpecsExtractError::CodeSpecsExtractError(std::string message,
                                             std::string path,
                                             std::string className)
    : message_(std::move(message)),
      path_(std::move(path)),
      className_(std::move(className)) {
  rendered_ = "CodeSpecsExtractError: " + message_ + " (" + path_ + ", " +
              className_ + ")";
}

/* ---- the extractor ------------------------------------------------------ */

namespace {

/* The document path segment a root's values live under. */
const std::string& codeSpecsRootSegment(const SpecRoot& r) {
  return r.sectionId.empty() ? r.type : r.sectionId;
}

std::string joinTypes(const std::vector<const SpecRoot*>& roots) {
  std::string out;
  for (const SpecRoot* r : roots) {
    if (!out.empty()) out += ", ";
    out += r->type;
  }
  return out;
}

/* Implements the constructor's root rule. */
const SpecRoot* resolveCodeSpecsRoot(const SpecModel& model,
                                     const SpecDocument& document,
                                     const std::string& rootType) {
  std::vector<const SpecRoot*> all;
  std::vector<const SpecRoot*> populated;
  for (const SpecRoot& r : model.roots) {
    all.push_back(&r);
    if (document.hasValuesUnder(codeSpecsRootSegment(r))) populated.push_back(&r);
  }
  if (!rootType.empty()) {
    for (const SpecRoot& r : model.roots) {
      if (r.type != rootType && codeSpecsRootSegment(r) != rootType) continue;
      bool isPopulated = false;
      for (const SpecRoot* p : populated) {
        if (p == &r) isPopulated = true;
      }
      if (!populated.empty() && !isPopulated) {
        throw CodeSpecsExtractError(
            "root \"" + rootType + "\" holds no value in this document, but " +
                joinTypes(populated) +
                " does — every extract would come out empty "
                "(codespecs_prompt.md §5)",
            codeSpecsRootSegment(r), r.type);
      }
      return &r;
    }
    throw CodeSpecsExtractError("no document root with type or section id \"" +
                                    rootType + "\" (have: " + joinTypes(all) +
                                    ")",
                                std::string(), rootType);
  }
  if (populated.size() == 1) return populated.front();
  if (populated.empty()) {
    if (model.roots.size() == 1) return &model.roots.front();
    throw CodeSpecsExtractError(
        "document has no populated root to extract from; pass rootType to "
        "choose one (have: " +
            joinTypes(all) + ")",
        std::string(), std::string());
  }
  throw CodeSpecsExtractError("document has " +
                                  std::to_string(populated.size()) +
                                  " populated roots (" + joinTypes(populated) +
                                  "); pass rootType to choose one",
                              std::string(), std::string());
}

}  // namespace

CodeSpecsExtractor::CodeSpecsExtractor(const SpecModel& model,
                                       const SpecDocument& document,
                                       CodeSpecsAreaCatalog catalog,
                                       const std::string& rootType)
    : model_(&model),
      document_(&document),
      catalog_(std::move(catalog)),
      root_(resolveCodeSpecsRoot(model, document, rootType)) {}

std::vector<CodeSpecsRouting> CodeSpecsExtractor::routings() const {
  std::vector<CodeSpecsRouting> out;
  walkAll(&out, nullptr, false);
  return out;
}

std::vector<CodeSpecsExtract> CodeSpecsExtractor::extractAll() const {
  std::vector<CodeSpecsExtractEntry> entries;
  walkAll(nullptr, &entries, true);
  std::string root = SpecReflection::rootSegment(*root_);
  std::vector<CodeSpecsExtract> out;
  for (const CodeSpecsArea& area : catalog_.activeAreas()) {
    CodeSpecsExtract x;
    x.area = area;
    x.catalogSource = catalog_.source;
    x.documentRoot = root;
    x.citableParts = catalog_.citableAreaCodes(area);
    x.projects = catalog_.projectsFor(area);
    for (const CodeSpecsExtractEntry& e : entries) {
      if (e.areaCode == area.code) {
        x.entries.push_back(e);
      }
    }
    out.push_back(std::move(x));
  }
  return out;
}

std::optional<CodeSpecsExtract> CodeSpecsExtractor::extractFor(
    const std::string& areaCode) const {
  for (CodeSpecsExtract& e : extractAll()) {
    if (e.area.code == areaCode) {
      return std::move(e);
    }
  }
  return std::nullopt;
}

// --- the walk --------------------------------------------------------------

void CodeSpecsExtractor::walkAll(std::vector<CodeSpecsRouting>* routings,
                                 std::vector<CodeSpecsExtractEntry>* entries,
                                 bool strict) const {
  walk(SpecReflection::rootSegment(*root_), model_->classNamed(root_->type),
       {root_->type}, routings, entries, strict);
}

void CodeSpecsExtractor::walk(const std::string& path, const SpecClass* cls,
                              const std::set<std::string>& ancestorTypes,
                              std::vector<CodeSpecsRouting>* routings,
                              std::vector<CodeSpecsExtractEntry>* entries,
                              bool strict) const {
  if (cls == nullptr) {
    return;
  }
  CodeSpecsRouting routing = verdictOf(*cls, path);
  if (routings != nullptr) {
    routings->push_back(routing);
  }

  switch (routing.verdict) {
    case CodeSpecsRoutingVerdict::FeedsProcess:
      return;  // the whole subtree is delivered by a non-generation process
    case CodeSpecsRoutingVerdict::Unrouted:
      if (strict) {
        throw CodeSpecsExtractError(
            "section carries none of the three routing verdicts "
            "(@CodeSpecKind / @FollowUpKind / @NoArtifact) — "
            "tom_specs_model_rules.md §10.2 ROUTE-TOTAL",
            path, cls->name);
      }
      break;
    case CodeSpecsRoutingVerdict::FeedsCode:
    case CodeSpecsRoutingVerdict::FeedsNothing:
    case CodeSpecsRoutingVerdict::DocumentRoot:
      break;
  }

  const CodeSpecsRouting* classRouting =
      routing.verdict == CodeSpecsRoutingVerdict::FeedsCode ? &routing
                                                            : nullptr;

  for (const SpecField& field : cls->fields) {
    std::string fieldPath =
        specPathJoin(path, SpecReflection::fieldSegment(field));
    std::optional<CodeSpecsRouting> fieldOverride = fieldRouting(*cls, field);
    const CodeSpecsRouting* fieldRouted =
        fieldOverride.has_value() ? &*fieldOverride : classRouting;

    if (field.kind == kSpecFieldKindContent ||
        field.kind == kSpecFieldKindEnum ||
        field.kind == kSpecFieldKindScalar) {
      emitValue(entries, fieldRouted, *cls, field, fieldPath, std::nullopt,
                document_->content(fieldPath));
    } else if (field.kind == kSpecFieldKindForm) {
      for (const FormFieldSpec& ff : field.formFields) {
        emitValue(entries, fieldRouted, *cls, field, fieldPath, ff.name,
                  document_->formField(fieldPath, ff.name));
      }
    } else if (field.kind == kSpecFieldKindList) {
      for (const std::string& itemPath : document_->listItems(fieldPath)) {
        if (field.elementIsComplex && !field.elementType.empty() &&
            ancestorTypes.count(field.elementType) == 0) {
          std::set<std::string> nested(ancestorTypes);
          nested.insert(field.elementType);
          walk(itemPath, model_->classNamed(field.elementType), nested,
               routings, entries, strict);
        } else {
          emitValue(entries, fieldRouted, *cls, field, itemPath, std::nullopt,
                    document_->content(itemPath));
        }
      }
    } else if (field.kind == kSpecFieldKindComplex ||
               field.kind == kSpecFieldKindSection) {
      if (!field.type.empty() && ancestorTypes.count(field.type) == 0) {
        std::set<std::string> nested(ancestorTypes);
        nested.insert(field.type);
        walk(fieldPath, model_->classNamed(field.type), nested, routings,
             entries, strict);
      }
    }
  }
}

void CodeSpecsExtractor::emitValue(
    std::vector<CodeSpecsExtractEntry>* entries, const CodeSpecsRouting* routing,
    const SpecClass& cls, const SpecField& field, const std::string& path,
    const std::optional<std::string>& formField,
    const std::string& value) const {
  if (entries == nullptr || routing == nullptr) {
    return;
  }
  // The generic document stores "unset" and "set to the empty string" alike as
  // "", which is the same pair the Dart original folds together (`value == null
  // || value.isEmpty`) — an empty leaf carries nothing to copy either way.
  if (value.empty()) {
    return;
  }
  for (const std::string& kind : routing->values) {
    const CodeSpecsArea* area = catalog_.byPart(kind);
    if (area == nullptr || !area->active) {
      continue;
    }
    CodeSpecsExtractEntry e;
    e.areaCode = area->code;
    e.sectionId = SpecReflection::fieldSegment(field);
    e.path = path;
    e.className = cls.name;
    e.fieldName = field.name;
    e.formField = formField;
    e.routedBy = area->kindValue();
    e.routedAt = routing->declaredAt;
    e.routingNote = routing->note;
    e.value = value;
    entries->push_back(std::move(e));
  }
}

// --- verdict resolution ----------------------------------------------------

/* The verdict `cls` carries. The three markers are mutually exclusive
 * (`KIND-EXCLUSIVE`), so the order they are tested in is a readability choice
 * rather than a precedence rule.
 *
 * Read through the model's own annotation accessors rather than off the raw
 * annotation bag: they already know that `@CodeSpecKind`'s list argument is
 * `kinds` while `@FollowUpKind`'s is `processes`, and they strip the enum
 * prefix, so the codes here are bare whatever spelling the meta chose. Two
 * readers of the same annotations would be two chances to disagree. */
CodeSpecsRouting CodeSpecsExtractor::verdictOf(const SpecClass& cls,
                                               const std::string& path) const {
  CodeSpecsRouting out;
  out.path = path;
  out.className = cls.name;

  std::optional<KindLink> code = specCodeSpecKind(cls.annotations);
  if (code.has_value()) {
    out.verdict = CodeSpecsRoutingVerdict::FeedsCode;
    out.values = code->kinds;
    out.note = code->note;
    out.declaredAt = cls.name;
    return out;
  }
  std::optional<KindLink> followUp = specFollowUpKind(cls.annotations);
  if (followUp.has_value()) {
    out.verdict = CodeSpecsRoutingVerdict::FeedsProcess;
    out.values = followUp->kinds;
    out.note = followUp->note;
    out.declaredAt = cls.name;
    return out;
  }
  std::optional<NoArtifactLink> none = specNoArtifact(cls.annotations);
  if (none.has_value()) {
    out.verdict = CodeSpecsRoutingVerdict::FeedsNothing;
    out.values = {none->reason};
    out.note = none->note;
    out.declaredAt = cls.name;
    return out;
  }
  out.verdict = specHasAnnotation(cls.annotations, "Document")
                    ? CodeSpecsRoutingVerdict::DocumentRoot
                    : CodeSpecsRoutingVerdict::Unrouted;
  return out;
}

/* A field-level `@CodeSpecKind`, which overrides its class's routing for that
 * field alone; std::nullopt when the field carries none. */
std::optional<CodeSpecsRouting> CodeSpecsExtractor::fieldRouting(
    const SpecClass& cls, const SpecField& field) const {
  std::optional<KindLink> code = specCodeSpecKind(field.annotations);
  if (!code.has_value()) {
    return std::nullopt;
  }
  CodeSpecsRouting out;
  out.className = cls.name;
  out.verdict = CodeSpecsRoutingVerdict::FeedsCode;
  out.values = code->kinds;
  out.note = code->note;
  out.declaredAt = cls.name + "." + field.name;
  return out;
}

}  // namespace som
