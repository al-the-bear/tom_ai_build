#include "spec_model.hpp"

namespace som {

std::string specParseFieldKind(const std::string& raw) {
  static const char* known[] = {
      kSpecFieldKindList,    kSpecFieldKindForm,   kSpecFieldKindSection,
      kSpecFieldKindContent, kSpecFieldKindEnum,   kSpecFieldKindComplex,
      kSpecFieldKindScalar};
  for (const char* k : known) {
    if (raw == k) {
      return k;
    }
  }
  return kSpecFieldKindScalar;
}

JsonRef SpecAnnotation::argument(const std::string& key) const {
  return jsonGet(arguments, key);
}

bool SpecField::isExpandable() const {
  return kind == kSpecFieldKindList || kind == kSpecFieldKindComplex;
}

const SpecField* SpecClass::fieldNamed(const std::string& name) const {
  for (const auto& f : fields) {
    if (f.name == name) {
      return &f;
    }
  }
  return nullptr;
}

const SpecClass* SpecModel::classNamed(const std::string& name) const {
  if (name.empty()) {
    return nullptr;
  }
  auto it = classesByName_.find(name);
  return it != classesByName_.end() ? &it->second : nullptr;
}

/* ---- decoding ----------------------------------------------------------- */

static std::vector<SpecAnnotation> annotationsFromJson(const JsonRef& v) {
  std::vector<SpecAnnotation> out;
  std::size_t n = jsonArrayLen(v);
  for (std::size_t i = 0; i < n; i++) {
    JsonRef a = jsonArrayAt(v, i);
    SpecAnnotation ann;
    ann.name = jsonStrOr(a, "name");
    JsonRef args = jsonGet(a, "arguments");
    ann.arguments =
        (args != nullptr && args->type == JsonType::Object) ? args : nullptr;
    out.push_back(std::move(ann));
  }
  return out;
}

static SpecField fieldFromJson(const JsonRef& f) {
  SpecField out;
  out.name = jsonStrOr(f, "name");
  out.kind = specParseFieldKind(jsonStrOr(f, "kind"));
  out.doc = jsonStrOr(f, "doc");
  out.help = jsonStrOr(f, "help");
  out.sectionId = jsonStrOr(f, "sectionId");
  out.sectionIdPattern = jsonStrOr(f, "sectionIdPattern");
  out.elementType = jsonStrOr(f, "elementType");
  out.elementIsComplex = jsonBoolOr(f, "elementIsComplex");

  auto min = jsonAsI64(jsonGet(f, "min"));
  if (min.has_value()) {
    out.hasMin = true;
    out.min = *min;
  }
  out.contentType = jsonStrOr(f, "contentType");
  out.sectionType = jsonStrOr(f, "sectionType");
  out.enumType = jsonStrOr(f, "enumType");

  JsonRef evs = jsonGet(f, "enumValues");
  std::size_t en = jsonArrayLen(evs);
  for (std::size_t i = 0; i < en; i++) {
    const std::string* s = jsonAsStr(jsonArrayAt(evs, i));
    if (s != nullptr) {
      out.enumValues.push_back(*s);
    }
  }

  out.type = jsonStrOr(f, "type");

  auto so = jsonAsI64(jsonGet(f, "serializationOrder"));
  if (so.has_value()) {
    out.hasSerializationOrder = true;
    out.serializationOrder = *so;
  }

  JsonRef ffs = jsonGet(f, "formFields");
  std::size_t fn = jsonArrayLen(ffs);
  for (std::size_t i = 0; i < fn; i++) {
    JsonRef ff = jsonArrayAt(ffs, i);
    FormFieldSpec ffs_out;
    std::string type = jsonStrOr(ff, "type");
    ffs_out.type = !type.empty() ? type : "String";
    std::string fname = jsonStrOr(ff, "name");
    std::string label = jsonStrOr(ff, "label");
    ffs_out.name = fname;
    ffs_out.label = !label.empty() ? label : fname;
    ffs_out.hint = jsonStrOr(ff, "hint");
    ffs_out.required = jsonBoolOr(ff, "required");
    out.formFields.push_back(std::move(ffs_out));
  }

  out.annotations = annotationsFromJson(jsonGet(f, "annotations"));
  return out;
}

static SpecClass classFromJson(const std::string& name, const JsonRef& cls) {
  SpecClass out;
  std::string cname = jsonStrOr(cls, "name");
  out.name = !cname.empty() ? cname : name;
  out.sectionId = jsonStrOr(cls, "sectionId");
  out.doc = jsonStrOr(cls, "doc");
  out.help = jsonStrOr(cls, "help");
  out.mapsTo = jsonStrOr(cls, "mapsTo");
  out.detailedIn = jsonStrOr(cls, "detailedIn");

  JsonRef fields = jsonGet(cls, "fields");
  std::size_t n = jsonArrayLen(fields);
  for (std::size_t i = 0; i < n; i++) {
    out.fields.push_back(fieldFromJson(jsonArrayAt(fields, i)));
  }
  out.annotations = annotationsFromJson(jsonGet(cls, "annotations"));
  return out;
}

std::unique_ptr<SpecModel> SpecModel::buildFromRoot(const JsonRef& root) {
  auto m = std::make_unique<SpecModel>();
  m->source_ = root;

  JsonRef roots = jsonGet(root, "roots");
  std::size_t rn = jsonArrayLen(roots);
  for (std::size_t i = 0; i < rn; i++) {
    JsonRef r = jsonArrayAt(roots, i);
    SpecRoot sr;
    sr.type = jsonStrOr(r, "type");
    sr.title = jsonStrOr(r, "title");
    sr.sectionId = jsonStrOr(r, "sectionId");
    sr.description = jsonStrOr(r, "description");
    sr.doc = jsonStrOr(r, "doc");
    m->roots.push_back(std::move(sr));
  }

  JsonRef classes = jsonGet(root, "classes");
  if (classes != nullptr && classes->type == JsonType::Object) {
    for (const auto& mem : classes->object) {
      // Re-create a const JsonRef view of the member value.
      JsonRef val = std::const_pointer_cast<const Json>(mem.second);
      SpecClass cls = classFromJson(mem.first, val);
      // key by the source member key (matches the C entry name).
      m->classesByName_[mem.first] = std::move(cls);
    }
  }

  auto mv = jsonAsI64(jsonGet(root, "modelVersion"));
  m->modelVersion = mv.value_or(0);
  m->modelVersionLabel = jsonStrOr(root, "modelVersionLabel");
  return m;
}

std::unique_ptr<SpecModel> SpecModel::fromJsonStr(const std::string& data,
                                                  std::string* err) {
  JsonPtr root = jsonParse(data, err);
  if (root == nullptr) {
    return nullptr;
  }
  return buildFromRoot(std::const_pointer_cast<const Json>(root));
}

std::unique_ptr<SpecModel> SpecModel::fromJson(const JsonRef& root) {
  if (root == nullptr) {
    return nullptr;
  }
  return buildFromRoot(root);
}

}  // namespace som
