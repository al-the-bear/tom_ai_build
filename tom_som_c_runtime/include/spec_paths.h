/* spec_paths — the section-path grammar shared by the in-memory document and the
 * meta-model traversal, a faithful port of the Rust `spec_paths.rs`.
 *
 * A path is the globally-unique address of a node in a concrete document:
 *   - the root is the document root's section segment;
 *   - a child field appends `/<segment>`;
 *   - a complex/section field collapses into its target class (no extra segment);
 *   - a list item appends `-<seq>` to the list field's path (no `/`).
 */
#ifndef SPEC_PATHS_H
#define SPEC_PATHS_H

#include "som_util.h"

#define SPEC_PATH_SEPARATOR "/"

/* Joins `parent` with `segment` using the path separator. Owned result. */
char *spec_path_join(const char *parent, const char *segment);

/* Splits `path` into its `/`-separated segments (an owned, ordered list). A
 * list-item sequence suffix stays attached to its segment. */
void spec_path_segments(const char *path, SomStrList *out);

/* Returns `<list_path>-<seq>` as an owned string. */
char *spec_list_item_path(const char *list_path, long long seq);

/* Splits a list-item segment `<base>-<digits>` into its base and seq when the
 * tail is all digits (and the dash is neither first nor last char). Returns 1
 * on success, writing an owned `*base` and `*seq`; 0 otherwise. A hyphenated
 * @SectionId such as `PD00-ROL` is never mis-read as a list item. */
int spec_split_list_item_segment(const char *segment, char **base, long long *seq);

#endif /* SPEC_PATHS_H */
