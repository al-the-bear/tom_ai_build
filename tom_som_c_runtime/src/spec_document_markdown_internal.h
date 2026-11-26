/* spec_document_markdown_internal — the Markdown codec's object and the
 * helpers its navigation (`spec_document_markdown_linked.c`, SOM §11.2,
 * §11.11) and generated parts (`spec_document_markdown_generated.c`, SOM
 * §11.12) read (private to the library). The split follows the Rust
 * runtime's `spec_document_markdown_linked.rs` /
 * `spec_document_markdown_generated.rs` child modules. */
#ifndef SPEC_DOCUMENT_MARKDOWN_INTERNAL_H
#define SPEC_DOCUMENT_MARKDOWN_INTERNAL_H

#include "spec_document_markdown.h"
#include "spec_document_set.h"
#include "spec_meta.h"
#include "spec_reflection.h"

typedef struct MdNav MdNav;
typedef struct MdGen MdGen;

/* One tree per root type, built lazily and cached. */
typedef struct {
  char *root_type; /* owned */
  SomMetaTree *tree;
} TreeEntry;

/* The class names one root's meta tree reaches (for reference links). */
typedef struct {
  char *root_type; /* owned */
  SomMap names;    /* class name -> "1" */
} MdReach;

typedef struct {
  const SpecModel *model;
  const SpecDocument *document; /* NULL while parsing */
  TreeEntry *trees;
  size_t trees_len;
  size_t trees_cap;
  /* When non-NULL, the document path of every heading written, in emission
   * order (`spec_markdown_export_root_with_map`). Borrowed. */
  SomStrList *heading_paths;
  /* The export in progress: its root and tree (borrowed), the document's
   * paths per kind (loaded once per export), the reach of each root. */
  const SpecRoot *current_root;
  const SomMetaTree *current_tree;
  SomStrList content_paths, form_paths, list_paths, units_paths, headline_paths;
  MdReach *reach;
  size_t reach_len, reach_cap;
  /* The export's options (spec_markdown_export_root_with_options): sections
   * deeper than level 6 as styled-div headings, and the readable header
   * written after the docspec line (borrowed, NULL when none). */
  int heading_divs;
  const char *readable_header;
  /* The files a link to another document root names (borrowed, NULL /
   * "" for none). */
  const char *file_stem;
  const SomMap *document_files;
  /* Whether the `linked` markers (SOM §11.11) and the generated parts (SOM
   * §11.12) are written. */
  int linked_markers;
  int generated_parts;
  /* The navigation and the generated parts of the export in progress
   * (owned; NULL outside an export, `gen` NULL without generated parts). */
  MdNav *nav;
  MdGen *gen;
  /* The model's anchor pairs, from a set of no documents (`sync_ok` 0 when
   * the model's synced positions cannot be paired). */
  int sync_loaded;
  int sync_ok;
  SpecDocumentSet sync_set;
  /* The empty document the navigation reads while parsing (owned, lazy). */
  SpecDocument *empty_document;
} MdCodec;

/* A meta node with its path relative to the node it was collected from. */
typedef struct {
  const SomMetaNode *node;
  char *rel; /* owned */
} NodeRel;

typedef struct {
  NodeRel *items;
  size_t len;
  size_t cap;
} NodeRelVec;

/* ---- the codec's helpers (spec_document_markdown.c) ---------------------- */

SomMetaTree *spec_mdi_tree_for(MdCodec *c, const char *root_type, char **err);
/* The heading id of `node` (owned). */
char *spec_mdi_heading_id_of(MdCodec *c, const SomMetaNode *node);
int spec_mdi_is_transparent_section(MdCodec *c, const SomMetaNode *n);
int spec_mdi_is_transparent_value(const SomMetaNode *n);
int spec_mdi_is_copy_node(const MdCodec *c, const SomMetaNode *n);
/* The anchor of heading `id` below a scope / section, and the new scope
 * (both owned; `*new_scope` may be NULL). */
void spec_mdi_qualify_anchor(const char *scope, const char *section,
                             const char *id, int container, int item, int copy,
                             char **anchor, char **new_scope);
/* The transparent body slots / the heading children of `node` (`*out`
 * initialised by the callee; free with spec_mdi_nrv_free). */
void spec_mdi_body_slots(MdCodec *c, const SomMetaNode *node, NodeRelVec *out);
void spec_mdi_effective_children(MdCodec *c, const SomMetaNode *node,
                                 NodeRelVec *out);
void spec_mdi_nrv_free(NodeRelVec *v);
/* `value` as a table cell, reference ids written as links. Owned. */
char *spec_mdi_linked_cell_text(MdCodec *c, const SomFormFieldMeta *f,
                                const char *value);
/* The rendition file of `root` (file stem, document files). Owned. */
char *spec_mdi_file_of_root(MdCodec *c, const SpecRoot *root);
/* The anchor pairs of the model, NULL when they cannot be paired. */
const SpecDocumentSet *spec_mdi_sync(MdCodec *c);
/* The codec's document, an empty one while parsing. */
const SpecDocument *spec_mdi_document(MdCodec *c);

/* ---- the navigation (spec_document_markdown_linked.c) -------------------- */

/* Written by the emitter where a markable place has no entry: replaced by
 * `[]{.linked}` when the value written after it begins with a `linked` span,
 * else removed with its blank line (SOM §11.11). */
#define SPEC_MDI_LINKED_PLACEHOLDER "\x1flinked\x1f"

/* A path walked through a tree: the anchor and id of the heading it ends at,
 * that heading's path, the path as a pattern (items `<list>-*`), the items'
 * ids on the way and the node reached (NULL: not reached). Owns its strings. */
typedef struct {
  char *anchor;
  char *heading_id;
  char *heading_path;
  char *pattern;
  SomStrList item_ids;
  const SomMetaNode *node;
} MdWalk;

void spec_mdi_walk_free(MdWalk *w);

MdNav *spec_mdi_nav_new(const SpecModel *model, const SpecRoot *root,
                        const SomMetaTree *tree);
void spec_mdi_nav_free(MdNav *nav);
const SomMetaTree *spec_mdi_nav_tree(const MdNav *nav);
const SpecReflection *spec_mdi_nav_refl(const MdNav *nav);
const char *spec_mdi_nav_root_seg(const MdNav *nav);

/* `path` walked through this root's tree, the items' ids read from the
 * codec's document; cached, owned by the navigation. */
const MdWalk *spec_mdi_nav_walk(MdNav *nav, MdCodec *c, const char *path);
/* The anchor of the heading `path` names in this document. Owned. */
char *spec_mdi_nav_anchor_of(MdNav *nav, MdCodec *c, const char *path);
/* Whether the heading at `path` carries one of the links of SOM §11.11. */
int spec_mdi_nav_markable(MdNav *nav, MdCodec *c, const char *path);
/* The marker's entries at the heading `path`, in the order of SOM §11.11
 * (`*out` initialised by the callee). */
void spec_mdi_nav_entries(MdNav *nav, MdCodec *c, const char *path,
                          int section_table, SomStrList *out);
/* For an item path, its list's path (owned); NULL otherwise. */
char *spec_mdi_nav_item_list_path(MdNav *nav, const char *path);
/* The `Id` cell of a records row standing for a summary element without
 * `match` (SOM §11.5, §11.11); NULL when the list is no such summary. Owned. */
char *spec_mdi_nav_summary_id_cell(MdNav *nav, MdCodec *c, const char *item,
                                   const char *list_path, const char *id);

/* Whether `paragraph` is exactly one span of kind `linked`. */
int spec_mdi_is_linked_paragraph(const char *paragraph);
/* `markdown` (consumed) with every linked placeholder resolved. Owned. */
char *spec_mdi_resolve_linked_placeholders(char *markdown);

/* ---- the generated parts (spec_document_markdown_generated.c) ------------ */

/* Written by the emitter at a generated place without a table: replaced by an
 * empty `derived` block when the value written after it begins with a
 * `derived` block, else removed with its blank line (SOM §11.12). */
#define SPEC_MDI_DERIVED_PLACEHOLDER "\x1f" "derived\x1f"

/* Whether the heading at `path` is a generated place. */
int spec_mdi_is_generated_place(MdNav *nav, MdCodec *c, const char *path);

MdGen *spec_mdi_gen_new(MdNav *nav);
void spec_mdi_gen_free(MdGen *gen);
/* The block written at the generated place `path` (its lines joined by
 * '\n'), NULL when its table has no row. Borrowed. */
const char *spec_mdi_gen_block(MdGen *gen, MdCodec *c, const char *path);
/* Whether a generated block stands at or beneath `path`. */
int spec_mdi_gen_forces(MdGen *gen, MdCodec *c, const char *path);

/* Whether `line` opens a `derived` block. */
int spec_mdi_opens_derived(const char *line);
/* Whether `line` closes the `derived` block `open` opens. */
int spec_mdi_closes_derived(const char *open, const char *line);
/* `markdown` (consumed) with every derived placeholder resolved. Owned. */
char *spec_mdi_resolve_derived_placeholders(char *markdown);

#endif /* SPEC_DOCUMENT_MARKDOWN_INTERNAL_H */
