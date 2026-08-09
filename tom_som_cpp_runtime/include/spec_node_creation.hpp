/* spec_node_creation — meta-model-validated node creation for a live
 * SpecDocument (llm_and_d4rt_tools.md §5 "constrained node creation"), an
 * idiomatic-C++ port of the Dart `spec_node_creation` library.
 *
 * Every node a script or tool adds passes through this single gate, so the
 * document can only grow in ways the SpecModel permits for the parent. The rules
 * are the `tom_specs_model_rules.md` §10.2 *structural* rules — but read from the
 * model meta-data the runtime already carries (SpecField::kind,
 * SpecField::sectionIdPattern, SpecField::min), **not** from the analyzer-backed
 * authoring validator in `tom_specs_clitool`. The clitool validates the
 * *authored model graph*; this validates a *document mutation against that
 * model*. They are different layers.
 *
 * checkAddNode is the single, value-aware rule-check entry point (exported for
 * reuse by editors and the engine); SpecNodeCreator::add applies it and performs
 * the mutation only when it comes back clean, so an illegal add never touches
 * the tree.
 */
#ifndef SPEC_NODE_CREATION_HPP
#define SPEC_NODE_CREATION_HPP

#include <exception>
#include <optional>
#include <string>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* Why an attempted node creation is illegal against the model. */
enum class SpecCreationCode {
  /* The parent path does not resolve to a node that can own named children (it
   * is dangling, a leaf, or a list — lists grow through their own field, not by
   * adding children to the list node). */
  NotAContainer,
  /* The requested child segment names no field on the parent's class. */
  UnknownChild,
  /* A caller-proposed list-item id does not keep the prefix mandated by the
   * list's `@SectionIdPattern` (AA1 criterion 3/5: an override replaces the
   * suffix, the pattern prefix stays). */
  PatternMismatch,
  /* A caller-proposed list-item id collides with another item's section id in
   * the same list (AA1 criterion 5: section ids within a list must be
   * unique). */
  DuplicateSectionId,
  /* A single-valued (non-list) child already holds a value — only one is
   * allowed. */
  CardinalityExceeded,
};

/* The Dart enum's `.name`, which is what the shared corpus records. */
const char* specCreationCodeName(SpecCreationCode code);

/* Every code, in declaration order — lets a conformance replay assert that a
 * table exercises the whole set rather than a convenient subset. */
inline constexpr SpecCreationCode kSpecCreationCodeAll[] = {
    SpecCreationCode::NotAContainer,
    SpecCreationCode::UnknownChild,
    SpecCreationCode::PatternMismatch,
    SpecCreationCode::DuplicateSectionId,
    SpecCreationCode::CardinalityExceeded,
};

/* A rejected node-creation attempt. Thrown by SpecNodeCreator::add and returned
 * (rather than thrown) by checkAddNode. */
class SpecCreationError : public std::exception {
 public:
  SpecCreationError(std::string parentPath, std::string childSegment,
                    SpecCreationCode code, std::string message);

  /* The parent path the add was attempted under. */
  const std::string& parentPath() const { return parentPath_; }
  /* The child section segment that was requested. */
  const std::string& childSegment() const { return childSegment_; }
  /* Why the add is illegal. */
  SpecCreationCode code() const { return code_; }
  /* A human-readable explanation. */
  const std::string& message() const { return message_; }

  /* Renders as
   * `SpecCreationError(<code>) under "<parent>" -> "<child>": <message>`. */
  const char* what() const noexcept override { return rendered_.c_str(); }

 private:
  std::string parentPath_;
  std::string childSegment_;
  SpecCreationCode code_;
  std::string message_;
  std::string rendered_;
};

/* Validates adding child `childSegment` under `parentPath` against `model`,
 * consulting `document` for cardinality. Returns std::nullopt when the add is
 * legal, otherwise the SpecCreationError describing the first rule it breaks.
 *
 * `itemId` is a caller-proposed list-item section id; `""` means "none
 * proposed", matching the `sectionId = ""` idiom SpecEditor::addListItem
 * already uses. An empty proposal is therefore not checked against the pattern
 * — there is nothing to check.
 *
 * This performs **no mutation**; it is the shared rule-check that
 * SpecNodeCreator::add (and any editor) calls before touching the tree. */
std::optional<SpecCreationError> checkAddNode(const SpecModel& model,
                                              const SpecDocument& document,
                                              const std::string& parentPath,
                                              const std::string& childSegment,
                                              const std::string& itemId = "");

/* Applies checkAddNode and performs the constrained mutation.
 *
 * Holds the model/document pair — both *borrowed*, so both must outlive the
 * creator — so callers add children by parent path and child segment without
 * re-supplying the context each time. */
class SpecNodeCreator {
 public:
  SpecNodeCreator(const SpecModel& model, SpecDocument& document)
      : model_(&model), document_(&document) {}

  const SpecModel& model() const { return *model_; }
  SpecDocument& document() const { return *document_; }

  /* Adds child `childSegment` under `parentPath` and returns the new node's
   * path. For a list field this appends a fresh item (`…/<segment>-<seq>`),
   * assigning its **section id** (AA1 criteria 3–5): `itemId` if given
   * (override), otherwise one generated from the field's `@SectionIdPattern`
   * dated `month`/`day` — both defaulting to today, the same month/day pair
   * SpecEditor::addListItem takes and for the same reason (the shared id
   * generator is language-neutral and takes exactly that). Lists with no pattern
   * (scalar lists) get no section id. For a single-valued field it returns the
   * child path without mutating the sparse store (the caller then sets its
   * value).
   *
   * Throws SpecCreationError — leaving the document untouched — when the add
   * violates a structural rule (see SpecCreationCode). */
  std::string add(const std::string& parentPath,
                  const std::string& childSegment,
                  const std::string& itemId = "",
                  std::optional<long long> month = std::nullopt,
                  std::optional<long long> day = std::nullopt);

 private:
  const SpecModel* model_;
  SpecDocument* document_;
};

}  // namespace som

#endif  // SPEC_NODE_CREATION_HPP
