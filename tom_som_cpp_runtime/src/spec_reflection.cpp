/* Idiomatic-C++ port of the C `spec_reflection` module. */
#include "spec_reflection.hpp"

#include "spec_paths.hpp"

namespace som {

static bool kindIsValueLeaf(const std::string& kind) {
  return kind == kSpecNodeKindContent || kind == kSpecNodeKindEnumValue ||
         kind == kSpecNodeKindScalar || kind == kSpecNodeKindListItemScalar;
}

bool SpecResolution::isValueLeaf() const { return kindIsValueLeaf(kind); }

/* Maps a leaf field kind to its node kind, or empty for non-leaf kinds. */
static const char* leafKind(const std::string& fieldKind) {
  if (fieldKind == kSpecFieldKindForm) {
    return kSpecNodeKindForm;
  }
  if (fieldKind == kSpecFieldKindContent) {
    return kSpecNodeKindContent;
  }
  if (fieldKind == kSpecFieldKindEnum) {
    return kSpecNodeKindEnumValue;
  }
  if (fieldKind == kSpecFieldKindScalar) {
    return kSpecNodeKindScalar;
  }
  return nullptr;
}

std::string SpecReflection::rootSegment(const SpecRoot& root) {
  if (!root.sectionId.empty()) {
    return root.sectionId;
  }
  return root.type;
}

std::string SpecReflection::fieldSegment(const SpecField& field) {
  if (!field.sectionId.empty()) {
    return field.sectionId;
  }
  return field.name;
}

const SpecRoot* SpecReflection::rootForSegment(const std::string& segment) const {
  for (const SpecRoot& root : model_->roots) {
    if (rootSegment(root) == segment) {
      return &root;
    }
  }
  return nullptr;
}

std::set<std::string> SpecReflection::reachableClassNames(
    const std::string& typeName) const {
  std::set<std::string> seen;
  std::vector<std::string> stack{typeName};
  while (!stack.empty()) {
    std::string current = stack.back();
    stack.pop_back();
    if (seen.count(current) != 0) {
      continue;
    }
    const SpecClass* cls = model_->classNamed(current);
    if (cls == nullptr) {
      continue;
    }
    seen.insert(current);
    for (const SpecField& f : cls->fields) {
      const std::string* child = nullptr;
      if (f.kind == kSpecFieldKindComplex || f.kind == kSpecFieldKindSection) {
        child = &f.type;
      } else if (f.kind == kSpecFieldKindList && f.elementIsComplex) {
        child = &f.elementType;
      }
      if (child != nullptr && !child->empty()) {
        stack.push_back(*child);
      }
    }
  }
  return seen;
}

static const SpecField* matchField(const SpecClass& cls,
                                   const std::string& segment) {
  for (const SpecField& f : cls.fields) {
    if (SpecReflection::fieldSegment(f) == segment) {
      return &f;
    }
  }
  return nullptr;
}

std::optional<SpecResolution> SpecReflection::resolve(
    const std::string& path) const {
  std::vector<std::string> segs = specPathSegments(path);

  if (segs.empty() || segs[0].empty()) {
    return std::nullopt;
  }

  const SpecRoot* root = rootForSegment(segs[0]);
  if (root == nullptr) {
    return std::nullopt;
  }
  const SpecClass* curClass = model_->classNamed(root->type);

  auto make = [&](const char* kind, const SpecField* field,
                  const SpecClass* target) -> SpecResolution {
    SpecResolution out;
    out.path = path;
    out.kind = kind;
    out.root = root;
    out.field = field;
    out.targetClass = target;
    return out;
  };

  if (segs.size() == 1) {
    return make(kSpecNodeKindRoot, nullptr, curClass);
  }

  for (std::size_t i = 1; i < segs.size(); i++) {
    if (curClass == nullptr) {
      break;  // cannot descend into a non-class
    }
    const SpecClass* cls = curClass;
    const std::string& seg = segs[i];
    bool last = (i == segs.size() - 1);

    // Prefer an exact field-segment match; only then try a list-item suffix.
    const SpecField* field = matchField(*cls, seg);
    if (field != nullptr) {
      if (field->kind == kSpecFieldKindComplex ||
          field->kind == kSpecFieldKindSection) {
        curClass = model_->classNamed(field->type);
        if (last) {
          const char* kind = field->kind == kSpecFieldKindSection
                                 ? kSpecNodeKindSection
                                 : kSpecNodeKindComplex;
          return make(kind, field, curClass);
        }
        continue;  // descend into the collapsed class
      }
      if (field->kind == kSpecFieldKindList) {
        if (last) {
          return make(kSpecNodeKindList, field, nullptr);
        }
        break;  // a non-final list path needs a -<seq> item suffix
      }
      // form / content / enum / scalar leaves
      if (last) {
        const char* kind = leafKind(field->kind);
        if (kind != nullptr) {
          return make(kind, field, nullptr);
        }
      }
      break;  // a leaf cannot have further segments
    }

    std::string base;
    long long seq = 0;
    if (!specSplitListItemSegment(seg, &base, &seq)) {
      break;
    }
    const SpecField* listField = matchField(*cls, base);
    if (listField == nullptr || listField->kind != kSpecFieldKindList) {
      break;
    }
    if (listField->elementIsComplex) {
      curClass = model_->classNamed(listField->elementType);
      if (last) {
        return make(kSpecNodeKindListItemComplex, listField, curClass);
      }
      continue;
    }
    // Scalar list item: a value leaf, so it must be the final segment.
    if (last) {
      return make(kSpecNodeKindListItemScalar, listField, nullptr);
    }
    break;
  }

  return std::nullopt;
}

}  // namespace som
