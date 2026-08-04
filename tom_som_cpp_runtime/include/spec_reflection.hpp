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
#include <set>
#include <string>
#include <vector>

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

  /* Returns every class name reachable from `typeName` by following
   * class-bearing fields — `complex`/`section` fields through their `type`,
   * complex list fields through their `elementType` — including `typeName`
   * itself.
   *
   * This is the model's notion of **document scope**. A document rooted at a
   * given `@Document` class can only ever hold sections of the classes that root
   * reaches, so a class outside the set is not merely *unpopulated* in such a
   * document — it is absent from it by construction. Any consumer that has to
   * tell "the author did not write this" from "this document could not hold it
   * in the first place" needs exactly this set.
   *
   * A name that resolves to no class contributes nothing and is not itself
   * included: an unresolved reference is not evidence of a reachable class. */
  std::set<std::string> reachableClassNames(const std::string& typeName) const;

  /* Resolves a document path to the model node it addresses. Returns the
   * resolution on success, or std::nullopt when the path does not describe a
   * reachable node. */
  std::optional<SpecResolution> resolve(const std::string& path) const;

 private:
  const SpecModel* model_;
};

}  // namespace som

#endif  // SPEC_REFLECTION_HPP
