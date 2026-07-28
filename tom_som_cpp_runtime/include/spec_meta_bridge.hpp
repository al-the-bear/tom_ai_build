/* spec_meta_bridge — bridge from the meta-JSON class graph (SpecModel) to the
 * canonical metadata tree (SomMetaTree, SOM §7.1), an idiomatic-C++ port of the
 * C `spec_meta_bridge.c` (which itself ports the Go / Dart / TS references).
 *
 * The generated facades (SOM §8) emit populated SomMetaTrees directly; every
 * consumer that only has the exported spec-model meta-data (the conformance
 * harness, tooling) builds its tree here. The expansion follows the same walk
 * spec_reflection performs — crucially, a node's `sectionId` is the
 * **field-level** id exactly as exported (field.sectionId), so the tree's path
 * grammar stays byte-compatible with the paths a SpecDocument is keyed by.
 *
 * Recursive class references become terminal re-entry nodes
 * (SomMetaNode.recursive), mirroring how the generated chains terminate.
 */
#ifndef SPEC_META_BRIDGE_HPP
#define SPEC_META_BRIDGE_HPP

#include <memory>
#include <string>

#include "spec_meta.hpp"
#include "spec_model.hpp"

namespace som {

/* Builds the wired SomMetaTree for one document root of `model`.
 *
 * When `rootType` is empty the model's first root is used; otherwise the root
 * is looked up by type (writing that lookup's error for an unknown type).
 * Children are ordered by @SerializationOrder (annotated members first, then
 * declaration order), which is the sibling emission order of the hierarchical
 * YAML format (SOM §12.3).
 *
 * The tree borrows the model's annotation-argument JSON (SomMetaExtra.args
 * keep a shared reference into the model source), so it is safe past the
 * model's own scope. On failure returns nullptr and, when `err` is non-null,
 * writes an error message. */
std::unique_ptr<SomMetaTree> somBuildMetaTree(const SpecModel& model,
                                              const std::string& rootType,
                                              std::string* err);

}  // namespace som

#endif  // SPEC_META_BRIDGE_HPP
