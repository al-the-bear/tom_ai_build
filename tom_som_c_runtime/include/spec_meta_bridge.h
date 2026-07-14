/* spec_meta_bridge — bridge from the meta-JSON class graph (SpecModel) to the
 * canonical metadata tree (SomMetaTree, DR1 §3.1), a faithful port of the Go
 * `spec_meta_bridge.go` (which itself ports `spec_meta_bridge.dart` /
 * `spec_meta_bridge.ts`).
 *
 * The generated facades (DR8) emit populated SomMetaTrees directly; every
 * consumer that only has the exported spec-model meta-data (the conformance
 * harness, tooling) builds its tree here. The expansion follows the same walk
 * spec_reflection performs — crucially, a node's `section_id` is the
 * **field-level** id exactly as exported (field.section_id), so the tree's
 * path grammar stays byte-compatible with the paths a SpecDocument is keyed
 * by. (DR1 §2.2's "field id, else target-class id" resolution is applied at
 * *export* time by the model exporter / DR8 generator, not re-derived here.)
 *
 * Recursive class references become terminal re-entry nodes
 * (SomMetaNode.recursive), mirroring how the generated chains terminate.
 */
#ifndef SPEC_META_BRIDGE_H
#define SPEC_META_BRIDGE_H

#include "spec_meta.h"
#include "spec_model.h"

/* Builds the wired SomMetaTree for one document root of `model`.
 *
 * When `root_type` is NULL or "" the model's first root is used; otherwise
 * the root is looked up by type (writing that lookup's error for an unknown
 * type). Children are ordered by @SerializationOrder (annotated members
 * first, then declaration order), which is the sibling emission order of the
 * hierarchical YAML format (DR1 §2.3).
 *
 * The tree borrows the model's annotation-argument JSON (SomMetaExtra.args
 * point into the model source), so `model` must outlive the returned tree.
 * On failure returns NULL and, when `err` is non-NULL, writes an owned
 * message. Free the result with `som_meta_tree_free`. */
SomMetaTree *som_build_meta_tree(const SpecModel *model, const char *root_type,
                                 char **err);

#endif /* SPEC_META_BRIDGE_H */
