/* spec_meta_diff — structural comparison of two SomMetaNode subtrees; an
 * idiomatic-C++ port of the C `spec_meta_diff` module (which itself ports the
 * Go / Dart / TS references).
 *
 * somMetaNodeDiff is the agreement oracle: the generated facades embed
 * populated metadata trees as static code (SOM §7.2), while somBuildMetaTree
 * derives the same tree from the exported meta-JSON at runtime — the two must be
 * field-for-field identical for every node. Tests compare them with this
 * function, which returns a human-readable description of the **first**
 * difference found (with the node's position), or an empty string when the
 * subtrees agree completely.
 *
 * C++ conventions (documented divergences from the C port): the "no difference"
 * result is the empty std::string "" (never a NULL pointer); no manual frees.
 * Numeric annotation-argument values compare by numeric value across int/float
 * (som_json's Int vs Float), matching the sibling ports.
 */
#ifndef SPEC_META_DIFF_HPP
#define SPEC_META_DIFF_HPP

#include <string>

#include "spec_meta.hpp"

namespace som {

/* Compares the `a` and `b` subtrees field by field (annotations, names, kinds,
 * form/document metadata, children and list element subtrees).
 *
 * Returns "" when the subtrees are structurally identical, else a description of
 * the first difference, prefixed with the node's position (a `/`-joined
 * member-name chain rooted at the `<root>` marker). */
std::string somMetaNodeDiff(const SomMetaNode& a, const SomMetaNode& b);

}  // namespace som

#endif  // SPEC_META_DIFF_HPP
