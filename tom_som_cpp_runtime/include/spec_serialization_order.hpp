/* spec_serialization_order — model-aware member ordering for YAML serialization
 * (AA1 criterion 7), an idiomatic-C++ port of the C `spec_serialization_order`
 * module (which itself ports the Rust reference).
 *
 * A SpecDocument is a flat, path-keyed store; the native YAML codec normally
 * emits keys alphabetically for clean diffs. Criterion 7 instead requires each
 * class's members to be emitted in the order declared by their
 * `@SerializationOrder` annotation (the SOM source declaration order).
 *
 * This helper turns a path into an ordinal tuple — the `@SerializationOrder` of
 * each field crossed on the way down (plus the numeric sequence for a list
 * item), mirroring the walk `SpecReflection::resolve` performs. Comparing those
 * tuples lexicographically reproduces a depth-first, member-order traversal.
 * Form fields (sub-keys, not path segments) are ordered by their position in the
 * owning `@Form`'s field list. Unannotated members sort after annotated ones
 * (fallback ordinal), then by path/name, so ordering is always total.
 */
#ifndef SPEC_SERIALIZATION_ORDER_HPP
#define SPEC_SERIALIZATION_ORDER_HPP

#include <string>
#include <vector>

#include "spec_model.hpp"

namespace som {

/* The ordinal used for members without a `@SerializationOrder`, so they sort
 * after every annotated member while staying stable relative to each other. */
constexpr long long kSpecSerializationUnorderedFallback = 1LL << 30;

/* A thin, borrowing wrapper over a model (like SpecReflection). */
class SpecSerializationOrder {
 public:
  explicit SpecSerializationOrder(const SpecModel& model) : model_(&model) {}

  /* Orders `paths` by their member-order tuple (lexicographically), breaking
   * ties by the path string. */
  std::vector<std::string> orderPaths(
      const std::vector<std::string>& paths) const;

  /* Orders the form-field names of the `@Form` at `formPath` by their declared
   * position in the form's field list; names not found in the model sort after,
   * alphabetically. */
  std::vector<std::string> orderFormFields(
      const std::string& formPath,
      const std::vector<std::string>& fieldNames) const;

 private:
  const SpecModel* model_;
};

}  // namespace som

#endif  // SPEC_SERIALIZATION_ORDER_HPP
