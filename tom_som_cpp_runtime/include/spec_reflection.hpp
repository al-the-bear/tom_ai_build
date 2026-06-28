/* spec_reflection — generic, value-free traversal of a SpecModel class graph (the
 * "reflection" surface), an idiomatic-C++ port of the C `spec_reflection` module.
 *
 * It answers two kinds of question about a model: enumeration (what roots,
 * classes, fields and annotations exist) and resolution (which model node a
 * concrete document path addresses). It holds no document values.
 *
 * Ownership: a `SpecResolution` holds *borrowed* pointers into the model — the
 * model must outlive any resolution derived from it; only `path` is owned.
 */
#ifndef SPEC_REFLECTION_HPP
#define SPEC_REFLECTION_HPP

#include <optional>
#include <string>

#include "spec_model.hpp"

namespace som {

/* Node kinds — what a resolved path lands on in the model. */
inline constexpr const char* kSpecNodeKindRoot = "root";
inline constexpr const char* kSpecNodeKindComplex = "complex";
inline constexpr const char* kSpecNodeKindSection = "section";
inline constexpr const char* kSpecNodeKindList = "list";
inline constexpr const char* kSpecNodeKindListItemComplex = "listItemComplex";
inline constexpr const char* kSpecNodeKindListItemScalar = "listItemScalar";
inline constexpr const char* kSpecNodeKindForm = "form";
inline constexpr const char* kSpecNodeKindContent = "content";
inline constexpr const char* kSpecNodeKindEnumValue = "enumValue";
inline constexpr const char* kSpecNodeKindScalar = "scalar";

struct SpecResolution {
  std::string path;
  std::string kind;                       // one of kSpecNodeKind*
  const SpecRoot* root = nullptr;         // borrowed from model (or null)
  const SpecField* field = nullptr;       // borrowed from model (or null)
  const SpecClass* targetClass = nullptr;  // borrowed from model (or null)

  /* Reports whether a single string value is stored directly at this node (a
   * content, enum, scalar leaf, or a scalar list item). */
  bool isValueLeaf() const;
};

/* The reflection surface is a thin, borrowing wrapper over a model. */
class SpecReflection {
 public:
  explicit SpecReflection(const SpecModel& model) : model_(&model) {}

  const SpecModel& model() const { return *model_; }

  /* Section segment of a root / field (sectionId when set, else type / name). */
  static std::string rootSegment(const SpecRoot& root);
  static std::string fieldSegment(const SpecField& field);

  /* Returns the root whose segment matches `segment`, or null. */
  const SpecRoot* rootForSegment(const std::string& segment) const;

  /* Resolves a document path to the model node it addresses. Returns the
   * resolution on success, or std::nullopt when the path does not describe a
   * reachable node. */
  std::optional<SpecResolution> resolve(const std::string& path) const;

 private:
  const SpecModel* model_;
};

}  // namespace som

#endif  // SPEC_REFLECTION_HPP
