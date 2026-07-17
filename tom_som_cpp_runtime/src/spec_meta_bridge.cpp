/* spec_meta_bridge — implementation. See spec_meta_bridge.hpp; an idiomatic-C++
 * port of the C `spec_meta_bridge.c`. */
#include "spec_meta_bridge.hpp"

#include <algorithm>
#include <stdexcept>
#include <vector>

#include "som_util.hpp"

namespace som {

namespace {

/* Annotation names that have a dedicated SomMetaNode slot; everything else is
 * captured losslessly into SomMetaNode.extra. */
const char* const kSlottedAnnotations[] = {
    "SectionId",   "SectionIdPattern", "SerializationOrder",
    "Min",         "Unused",           "ContentType",
    "ContentHelp", "Headline",         "Comment",
    "Form",        "Document",         "MapsTo",
    "DetailedIn",  "SecondLevelSectionId",
};

bool isSlotted(const std::string& name) {
  for (const char* slotted : kSlottedAnnotations) {
    if (name == slotted) {
      return true;
    }
  }
  return false;
}

const SpecAnnotation* annNamed(const std::vector<SpecAnnotation>& list,
                               const std::string& name) {
  for (const auto& a : list) {
    if (a.name == name) {
      return &a;
    }
  }
  return nullptr;
}

/* Coerces an annotation argument value to its string form ("" for absent /
 * non-integral floats / other types, matching the other ports). */
std::string bridgeStr(const JsonRef& v) {
  if (!v) {
    return "";
  }
  switch (v->type) {
    case JsonType::Str:
      return v->str;
    case JsonType::Int:
      return formatI64(v->integer);
    case JsonType::Float:
      if (v->real == static_cast<double>(static_cast<long long>(v->real))) {
        return formatI64(static_cast<long long>(v->real));
      }
      return "";
    case JsonType::Bool:
      return v->boolean ? "true" : "false";
    default:
      return "";
  }
}

void bridgeSecondLevelIds(const std::vector<SpecAnnotation>& annotations,
                          SomMetaNode* node) {
  for (const auto& a : annotations) {
    if (a.name != "SecondLevelSectionId") {
      continue;
    }
    SomSecondLevelId entry;
    entry.documentClass = bridgeStr(a.argument("documentClass"));
    entry.id = bridgeStr(a.argument("id"));
    node->secondLevelIds.push_back(std::move(entry));
  }
}

void bridgeExtras(const std::vector<SpecAnnotation>& annotations,
                  SomMetaNode* node) {
  for (const auto& a : annotations) {
    if (isSlotted(a.name)) {
      continue;
    }
    SomMetaExtra extra;
    extra.annotation = a.name;
    extra.args = a.arguments;  // shared reference into the model source
    node->extra.push_back(std::move(extra));
  }
}

void bridgeBasedOn(const SpecClass* cls, SomDocMeta* doc) {
  if (cls == nullptr) {
    return;
  }
  const SpecAnnotation* ann = annNamed(cls->annotations, "Document");
  if (ann == nullptr) {
    return;
  }
  JsonRef raw = ann->argument("basedOn");
  if (!raw || raw->type != JsonType::Array) {
    return;
  }
  for (const auto& item : raw->array) {
    doc->basedOn.push_back(bridgeStr(item));
  }
}

std::unique_ptr<SomMetaNode> bridgeFieldNode(const SpecModel& model,
                                             const SpecClass& owner,
                                             const SpecField& field,
                                             std::vector<std::string>* stack);

/* Emits `cls`'s fields as child nodes onto `node`, ordered by
 * @SerializationOrder (annotated members first, then declaration order). */
void bridgeChildNodes(const SpecModel& model, const SpecClass& cls,
                      std::vector<std::string>* stack, SomMetaNode* node) {
  const long long fallback = 1LL << 30;
  size_t n = cls.fields.size();
  if (n == 0) {
    return;
  }
  std::vector<size_t> order(n);
  for (size_t i = 0; i < n; i++) {
    order[i] = i;
  }
  // Stable insertion sort on (serialization order, declaration index).
  for (size_t i = 1; i < n; i++) {
    size_t j = i;
    while (j > 0) {
      const SpecField& a = cls.fields[order[j - 1]];
      const SpecField& b = cls.fields[order[j]];
      long long oa = a.hasSerializationOrder ? a.serializationOrder : fallback;
      long long ob = b.hasSerializationOrder ? b.serializationOrder : fallback;
      if (oa > ob) {
        std::swap(order[j - 1], order[j]);
        j--;
      } else {
        break;
      }
    }
  }
  for (size_t i = 0; i < n; i++) {
    node->addChild(bridgeFieldNode(model, cls, cls.fields[order[i]], stack));
  }
}

std::unique_ptr<SomMetaNode> bridgeFieldNode(const SpecModel& model,
                                             const SpecClass& owner,
                                             const SpecField& field,
                                             std::vector<std::string>* stack) {
  auto node = std::make_unique<SomMetaNode>();
  // The kSpecFieldKind* values equal the kSomMetaKind* values; re-canonicalise
  // to point at the static literal.
  std::string kind = specParseFieldKind(field.kind);
  if (kind == kSpecFieldKindList) {
    node->kind = kSomMetaKindList;
  } else if (kind == kSpecFieldKindForm) {
    node->kind = kSomMetaKindForm;
  } else if (kind == kSpecFieldKindSection) {
    node->kind = kSomMetaKindSection;
  } else if (kind == kSpecFieldKindContent) {
    node->kind = kSomMetaKindContent;
  } else if (kind == kSpecFieldKindEnum) {
    node->kind = kSomMetaKindEnumValue;
  } else if (kind == kSpecFieldKindComplex) {
    node->kind = kSomMetaKindComplex;
  } else {
    node->kind = kSomMetaKindScalar;
  }

  const SpecClass* target = nullptr;
  if (field.kind == kSpecFieldKindComplex || field.kind == kSpecFieldKindSection) {
    target = model.classNamed(field.type);
    if (target != nullptr) {
      if (std::find(stack->begin(), stack->end(), target->name) !=
          stack->end()) {
        node->recursive = true;
      } else {
        stack->push_back(target->name);
        bridgeChildNodes(model, *target, stack, node.get());
        stack->pop_back();
      }
    }
  } else if (field.kind == kSpecFieldKindList && field.elementIsComplex) {
    const SpecClass* element = model.classNamed(field.elementType);
    if (element != nullptr) {
      auto elementNode = std::make_unique<SomMetaNode>();
      elementNode->kind = kSomMetaKindComplex;
      elementNode->className = element->name;
      elementNode->typeName = element->name;
      elementNode->headline = element->headline;
      elementNode->docComment = element->doc;
      elementNode->classDocComment = element->doc;
      elementNode->classSectionId = element->sectionId;
      elementNode->mapsTo = element->mapsTo;
      elementNode->detailedIn = element->detailedIn;
      if (std::find(stack->begin(), stack->end(), element->name) !=
          stack->end()) {
        elementNode->recursive = true;
      } else {
        stack->push_back(element->name);
        bridgeChildNodes(model, *element, stack, elementNode.get());
        stack->pop_back();
      }
      node->elementNode = std::move(elementNode);
    }
  }

  if (!field.contentType.empty()) {
    SomContentTypeMeta ct;
    ct.type = field.contentType;
    const SpecAnnotation* ctAnn = annNamed(field.annotations, "ContentType");
    ct.description =
        ctAnn != nullptr ? bridgeStr(ctAnn->argument("description")) : "";
    node->contentType = std::move(ct);
  }

  const SpecAnnotation* commentAnn = annNamed(field.annotations, "Comment");
  if (commentAnn != nullptr) {
    node->comment = bridgeStr(commentAnn->argument("text"));
  }

  if (field.kind == kSpecFieldKindForm) {
    SomFormMeta form;
    form.fields.reserve(field.formFields.size());
    for (size_t i = 0; i < field.formFields.size(); i++) {
      const FormFieldSpec& ff = field.formFields[i];
      SomFormFieldMeta out;
      out.name = ff.name;
      out.typeName = ff.type;
      out.description = ff.label;
      out.required = ff.required;
      out.hint = ff.hint;
      out.order = static_cast<long long>(i);
      form.fields.push_back(std::move(out));
    }
    node->form = std::move(form);
  }

  node->className = owner.name;
  node->docComment = field.doc;
  if (target != nullptr) {
    node->className = target->name;
    if (node->docComment.empty()) {
      node->docComment = target->doc;
    }
    node->classDocComment = target->doc;
    node->classSectionId = target->sectionId;
    node->mapsTo = target->mapsTo;
    node->detailedIn = target->detailedIn;
  }
  std::string typeName = field.type;
  if (typeName.empty()) {
    typeName = field.elementType;
  }
  if (typeName.empty()) {
    typeName = field.enumType;
  }
  if (typeName.empty()) {
    typeName = "String";
  }
  node->typeName = typeName;

  node->memberName = field.name;
  node->sectionId = field.sectionId;
  node->sectionIdPattern = field.sectionIdPattern;
  node->hasSerializationOrder = field.hasSerializationOrder;
  node->serializationOrder = field.serializationOrder;
  node->hasMin = field.hasMin;
  node->min = field.min;
  node->unused = annNamed(field.annotations, "Unused") != nullptr;
  node->contentHelp = field.help;
  // Field-level @Headline wins over the target class's (YRD4).
  node->headline = !field.headline.empty()
                       ? field.headline
                       : (target != nullptr ? target->headline : "");
  bridgeSecondLevelIds(field.annotations, node.get());
  bridgeExtras(field.annotations, node.get());
  return node;
}

}  // namespace

std::unique_ptr<SomMetaTree> somBuildMetaTree(const SpecModel& model,
                                              const std::string& rootType,
                                              std::string* err) {
  const SpecRoot* root = nullptr;
  if (rootType.empty()) {
    if (!model.roots.empty()) {
      root = &model.roots.front();
    } else {
      // No roots at all — rootByType throws with a descriptive message.
      try {
        root = &model.rootByType("");
      } catch (const std::exception& e) {
        if (err != nullptr) {
          *err = e.what();
        }
        return nullptr;
      }
    }
  } else {
    try {
      root = &model.rootByType(rootType);
    } catch (const std::exception& e) {
      if (err != nullptr) {
        *err = e.what();
      }
      return nullptr;
    }
  }

  const SpecClass* cls = model.classNamed(root->type);

  auto node = std::make_unique<SomMetaNode>();
  node->kind = kSomMetaKindSection;
  node->className = root->type;
  node->typeName = root->type;
  node->sectionId = root->sectionId;
  node->docComment = root->doc;

  SomDocMeta doc;
  doc.name = root->title;
  doc.description = root->description;
  bridgeBasedOn(cls, &doc);
  node->document = std::move(doc);

  if (cls != nullptr) {
    node->headline = cls->headline;
    if (node->sectionId.empty()) {
      node->sectionId = cls->sectionId;
    }
    if (node->docComment.empty()) {
      node->docComment = cls->doc;
    }
    node->classDocComment = cls->doc;
    node->classSectionId = cls->sectionId;
    node->mapsTo = cls->mapsTo;
    node->detailedIn = cls->detailedIn;
    bridgeSecondLevelIds(cls->annotations, node.get());
    bridgeExtras(cls->annotations, node.get());
    std::vector<std::string> stack;
    stack.push_back(root->type);
    bridgeChildNodes(model, *cls, &stack, node.get());
  }

  try {
    return SomMetaTree::create(std::move(node));
  } catch (const std::exception& e) {
    if (err != nullptr) {
      *err = e.what();
    }
    return nullptr;
  }
}

}  // namespace som
