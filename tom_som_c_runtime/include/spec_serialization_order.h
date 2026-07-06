/* spec_serialization_order — model-aware member ordering for YAML serialization
 * (AA1 criterion 7), a faithful port of the Rust `spec_serialization_order.rs`.
 *
 * A SpecDocument is a flat, path-keyed store; the native YAML codec normally
 * emits keys alphabetically for clean diffs. Criterion 7 instead requires each
 * class's members to be emitted in the order declared by their
 * `@SerializationOrder` annotation (the SOM source declaration order).
 *
 * This helper turns a path into an ordinal tuple — the `@SerializationOrder` of
 * each field crossed on the way down (plus the numeric sequence for a list
 * item), mirroring the walk `spec_reflection_resolve` performs. Comparing those
 * tuples lexicographically reproduces a depth-first, member-order traversal.
 * Form fields (sub-keys, not path segments) are ordered by their position in the
 * owning `@Form`'s field list. Unannotated members sort after annotated ones
 * (fallback ordinal), then by path/name, so ordering is always total.
 */
#ifndef SPEC_SERIALIZATION_ORDER_H
#define SPEC_SERIALIZATION_ORDER_H

#include "som_util.h"
#include "spec_model.h"

/* The ordinal used for members without a `@SerializationOrder`, so they sort
 * after every annotated member while staying stable relative to each other. */
#define SPEC_SERIALIZATION_UNORDERED_FALLBACK (1LL << 30)

/* A thin, borrowing wrapper over a model (like SpecReflection). */
typedef struct {
  const SpecModel *model;
} SpecSerializationOrder;

SpecSerializationOrder spec_serialization_order_make(const SpecModel *model);

/* Orders `paths` by their member-order tuple (lexicographically), breaking ties
 * by the path string. Writes the ordered copy into `out` (init by callee). */
void spec_serialization_order_paths(const SpecSerializationOrder *o,
                                    const SomStrList *paths, SomStrList *out);

/* Orders the form-field names of the `@Form` at `form_path` by their declared
 * position in the form's field list; names not found in the model sort after,
 * alphabetically. Writes the ordered copy into `out` (init by callee). */
void spec_serialization_order_form_fields(const SpecSerializationOrder *o,
                                          const char *form_path,
                                          const SomStrList *field_names,
                                          SomStrList *out);

#endif /* SPEC_SERIALIZATION_ORDER_H */
