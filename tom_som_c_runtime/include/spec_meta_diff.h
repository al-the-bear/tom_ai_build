/* spec_meta_diff — structural comparison of two SomMetaNode subtrees; a
 * faithful port of the Go `spec_meta_diff.go` (which itself ports the Dart
 * reference `spec_meta_diff.dart` and the TypeScript / Python / JavaScript
 * ports).
 *
 * som_meta_node_diff is the agreement oracle for DR8: the generated facades
 * embed populated metadata trees as static code (DR1 §3.2), while
 * som_build_meta_tree derives the same tree from the exported meta-JSON at
 * runtime — the two must be field-for-field identical for every node. Tests
 * compare them with this function, which returns a human-readable description
 * of the **first** difference found (with the node's position), or an empty
 * string when the subtrees agree completely.
 *
 * C conventions (documented divergences from the Go port): the "no difference"
 * result is an owned empty string "" (never NULL) — the caller always frees the
 * result with `free`. Optional ints (`has_min` / `has_serialization_order`)
 * print as `null` when absent so the message strings stay aligned with the
 * sibling ports; numeric annotation-argument values compare by numeric value
 * across int/float (som_json's Int vs Float), matching the Go port whose JSON
 * decoder yields float64 where the generated literals are untyped constants.
 */
#ifndef SPEC_META_DIFF_H
#define SPEC_META_DIFF_H

#include "spec_meta.h"

/* Compares the `a` and `b` subtrees field by field (annotations, names, kinds,
 * form/document metadata, children and list element subtrees).
 *
 * Returns a freshly allocated string the caller must free: "" when the subtrees
 * are structurally identical, else a description of the first difference,
 * prefixed with the node's position (a `/`-joined member-name chain rooted at
 * the `<root>` marker). */
char *som_meta_node_diff(const SomMetaNode *a, const SomMetaNode *b);

#endif /* SPEC_META_DIFF_H */
