/* Idiomatic-C++ port of the Dart `spec_node_creation` library. */
#include "spec_node_creation.hpp"

#include "spec_paths.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"

namespace som {
namespace {

/* The field of `cls` whose section segment (`@SectionId` ?? name) is `segment`,
 * or null when the class declares no such child. */
const SpecField* fieldForSegment(const SpecClass& cls,
                                 const std::string& segment) {
  for (const SpecField& f : cls.fields) {
    if (SpecReflection::fieldSegment(f) == segment) {
      return &f;
    }
  }
  return nullptr;
}

bool startsWith(const std::string& s, const std::string& prefix) {
  return s.size() >= prefix.size() &&
         s.compare(0, prefix.size(), prefix) == 0;
}

}  // namespace

const char* specCreationCodeName(SpecCreationCode code) {
  switch (code) {
    case SpecCreationCode::NotAContainer:
      return "notAContainer";
    case SpecCreationCode::UnknownChild:
      return "unknownChild";
    case SpecCreationCode::PatternMismatch:
      return "patternMismatch";
    case SpecCreationCode::DuplicateSectionId:
      return "duplicateSectionId";
    case SpecCreationCode::CardinalityExceeded:
      return "cardinalityExceeded";
  }
  return "";
}

SpecCreationError::SpecCreationError(std::string parentPath,
                                     std::string childSegment,
                                     SpecCreationCode code,
                                     std::string message)
    : parentPath_(std::move(parentPath)),
      childSegment_(std::move(childSegment)),
      code_(code),
      message_(std::move(message)),
      rendered_(std::string("SpecCreationError(") +
                specCreationCodeName(code) + ") under \"" + parentPath_ +
                "\" -> \"" + childSegment_ + "\": " + message_) {}

std::optional<SpecCreationError> checkAddNode(const SpecModel& model,
                                              const SpecDocument& document,
                                              const std::string& parentPath,
                                              const std::string& childSegment,
                                              const std::string& itemId) {
  const SpecReflection refl(model);

  auto err = [&](SpecCreationCode code,
                 const std::string& message) -> std::optional<SpecCreationError> {
    return SpecCreationError(parentPath, childSegment, code, message);
  };

  // 1. The parent must resolve to a class-bearing node (root / complex /
  //    section / complex list item). Leaves, lists and dangling paths cannot own
  //    named children.
  const std::optional<SpecResolution> parent = refl.resolve(parentPath);
  if (!parent.has_value() || parent->targetClass == nullptr) {
    const std::string what =
        !parent.has_value() ? "does not resolve" : "is a " + parent->kind;
    return err(SpecCreationCode::NotAContainer,
               "parent path " + what + " and cannot own child nodes");
  }
  const SpecClass& parentClass = *parent->targetClass;

  // 2. The child segment must name a declared field of the parent's class.
  const SpecField* field = fieldForSegment(parentClass, childSegment);
  if (field == nullptr) {
    return err(SpecCreationCode::UnknownChild,
               "\"" + childSegment + "\" is not a child of " +
                   parentClass.name);
  }

  const std::string childPath = specPathJoin(parentPath, childSegment);

  if (field->kind == kSpecFieldKindList) {
    // 3. List item: validate a caller-proposed id. Lists have no upper bound,
    //    so there is no cardinality check. A missing id is generated later
    //    (criterion 3); an explicit override must keep the pattern prefix
    //    (criterion 3) and stay unique within the list (criterion 5).
    const std::string& pattern = field->sectionIdPattern;
    if (!itemId.empty() && !pattern.empty()) {
      const std::string prefix = specSectionIdPatternPrefix(pattern);
      if (!startsWith(itemId, prefix)) {
        return err(SpecCreationCode::PatternMismatch,
                   "item id \"" + itemId +
                       "\" does not keep the pattern prefix \"" + prefix +
                       "\"");
      }
      for (const std::string& used : document.listItemSectionIds(childPath)) {
        if (used == itemId) {
          return err(SpecCreationCode::DuplicateSectionId,
                     "item id \"" + itemId + "\" is already used in list \"" +
                         childPath + "\"");
        }
      }
    }
    return std::nullopt;
  }

  // 4. Single-valued child (complex / section / form / content / enum /
  //    scalar): cardinality is exactly one, so reject if a value already exists
  //    at or beneath the child path.
  if (document.hasValuesUnder(childPath)) {
    return err(SpecCreationCode::CardinalityExceeded,
               "a " + field->kind + " child already exists at \"" + childPath +
                   "\"");
  }
  return std::nullopt;
}

std::string SpecNodeCreator::add(const std::string& parentPath,
                                 const std::string& childSegment,
                                 const std::string& itemId,
                                 std::optional<long long> month,
                                 std::optional<long long> day) {
  std::optional<SpecCreationError> error =
      checkAddNode(*model_, *document_, parentPath, childSegment, itemId);
  if (error.has_value()) {
    throw *error;
  }

  const std::string childPath = specPathJoin(parentPath, childSegment);
  const SpecReflection refl(*model_);
  const SpecField* field =
      fieldForSegment(*refl.resolve(parentPath)->targetClass, childSegment);
  if (field->kind == kSpecFieldKindList) {
    const std::string& pattern = field->sectionIdPattern;
    if (pattern.empty()) {
      return document_->addListItem(childPath);
    }
    std::string id = itemId;
    if (id.empty()) {
      std::pair<long long, long long> today = specTodayMonthDay();
      id = specGenerateListItemSectionId(
          pattern, month.value_or(today.first), day.value_or(today.second),
          document_->listItemSectionIds(childPath));
    }
    return document_->addListItemWithSectionId(childPath, id);
  }
  return childPath;
}

}  // namespace som
