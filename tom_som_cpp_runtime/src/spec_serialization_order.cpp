/* Idiomatic-C++ port of the C `spec_serialization_order` module. */
#include "spec_serialization_order.hpp"

#include <algorithm>

#include "spec_paths.hpp"
#include "spec_reflection.hpp"

namespace som {

namespace {

long long orderOf(const SpecField& field) {
  return field.hasSerializationOrder ? field.serializationOrder
                                     : kSpecSerializationUnorderedFallback;
}

/* Returns the field of `cls` whose section segment equals `segment`, or null. */
const SpecField* matchField(const SpecClass& cls, const std::string& segment) {
  for (const SpecField& f : cls.fields) {
    if (SpecReflection::fieldSegment(f) == segment) {
      return &f;
    }
  }
  return nullptr;
}

/* Computes the ordinal tuple for `path`: one entry per field crossed (its
 * `@SerializationOrder` or the fallback), plus a trailing entry for a list
 * item's numeric sequence. A path that does not resolve yields an empty tuple
 * (so it sorts by its string form only). */
std::vector<long long> orderKey(const SpecModel& model, const std::string& path) {
  std::vector<long long> key;

  std::vector<std::string> segs = specPathSegments(path);
  if (segs.empty() || segs[0].empty()) {
    return key;
  }

  SpecReflection refl(model);
  const SpecRoot* root = refl.rootForSegment(segs[0]);
  if (root == nullptr) {
    return key;
  }

  const SpecClass* curClass = model.classNamed(root->type);
  std::size_t i = 1;
  while (i < segs.size()) {
    if (curClass == nullptr) {
      break;
    }
    const std::string& seg = segs[i];

    const SpecField* field = matchField(*curClass, seg);
    if (field != nullptr) {
      key.push_back(orderOf(*field));
      if (field->kind == kSpecFieldKindComplex ||
          field->kind == kSpecFieldKindSection) {
        curClass = model.classNamed(field->type);
        i++;
        continue;
      }
      break;  // list container / leaf / form terminates the descent
    }

    /* A list item segment: `<base>-<seq>`. */
    std::string base;
    long long seq = 0;
    if (!specSplitListItemSegment(seg, &base, &seq)) {
      break;
    }
    const SpecField* listField = matchField(*curClass, base);
    if (listField == nullptr || listField->kind != kSpecFieldKindList) {
      break;
    }
    key.push_back(orderOf(*listField));
    key.push_back(seq);
    if (listField->elementIsComplex) {
      curClass = model.classNamed(listField->elementType);
      i++;
      continue;
    }
    break;  // scalar list item is a leaf
  }

  return key;
}

/* Reproduces the Rust `compare_order_keys` total order: element-wise on the
 * shared prefix, then by length, then ties break on the path string. */
struct PathKey {
  std::string path;
  std::vector<long long> key;
};

bool pathKeyLess(const PathKey& a, const PathKey& b) {
  std::size_t n = std::min(a.key.size(), b.key.size());
  for (std::size_t i = 0; i < n; i++) {
    if (a.key[i] != b.key[i]) {
      return a.key[i] < b.key[i];
    }
  }
  if (a.key.size() != b.key.size()) {
    return a.key.size() < b.key.size();
  }
  return a.path < b.path;
}

}  // namespace

std::vector<std::string> SpecSerializationOrder::orderPaths(
    const std::vector<std::string>& paths) const {
  std::vector<PathKey> items;
  items.reserve(paths.size());
  for (const std::string& p : paths) {
    items.push_back({p, orderKey(*model_, p)});
  }
  std::sort(items.begin(), items.end(), pathKeyLess);

  std::vector<std::string> out;
  out.reserve(items.size());
  for (const PathKey& pk : items) {
    out.push_back(pk.path);
  }
  return out;
}

std::vector<std::string> SpecSerializationOrder::orderFormFields(
    const std::string& formPath,
    const std::vector<std::string>& fieldNames) const {
  /* Resolve the form's declared field order (positions), if any. */
  const std::vector<FormFieldSpec>* formFields = nullptr;
  SpecReflection refl(*model_);
  std::optional<SpecResolution> res = refl.resolve(formPath);
  if (res.has_value() && res->field != nullptr) {
    formFields = &res->field->formFields;
  }

  struct FieldPos {
    std::string name;
    long long pos;
  };
  std::vector<FieldPos> items;
  items.reserve(fieldNames.size());
  for (const std::string& name : fieldNames) {
    long long pos = kSpecSerializationUnorderedFallback;
    if (formFields != nullptr) {
      for (std::size_t j = 0; j < formFields->size(); j++) {
        if ((*formFields)[j].name == name) {
          pos = static_cast<long long>(j);
          break;
        }
      }
    }
    items.push_back({name, pos});
  }
  std::sort(items.begin(), items.end(),
            [](const FieldPos& a, const FieldPos& b) {
              if (a.pos != b.pos) {
                return a.pos < b.pos;
              }
              return a.name < b.name;
            });

  std::vector<std::string> out;
  out.reserve(items.size());
  for (const FieldPos& fp : items) {
    out.push_back(fp.name);
  }
  return out;
}

}  // namespace som
