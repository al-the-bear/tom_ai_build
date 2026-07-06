/* som_facade — runtime support for the generated typed object model
 * (`tom_som_c_v0`), a faithful port of the Rust `som_facade.rs` / Go
 * `som_facade.go`.
 *
 * The generated structs are a thin editing facade over the generic
 * `SpecDocument`: every typed accessor reads or writes the path-keyed memory
 * representation directly, so a mutation through the typed surface is immediately
 * visible through the generic path and vice-versa.
 *
 * C has no `Rc<RefCell<…>>`: the one document is shared by **borrowed pointer**.
 * Every facade node holds a `SpecDocument *` it does not own plus the
 * globally-unique section path it lives at (owned). The document must outlive
 * every facade bound to it. There are no generics: `SomList` is path-based and
 * the generated typed accessors construct their element facades from the item
 * paths it yields.
 */
#ifndef SOM_FACADE_H
#define SOM_FACADE_H

#include "spec_document.h"
#include "spec_section_id.h"
#include "som_util.h"

/* ---- SomNode — the base every generated facade struct embeds ------------- */

typedef struct {
  SpecDocument *doc; /* borrowed; the document this node edits */
  char *path;        /* owned; the node's globally-unique section path */
} SomNode;

/* Binds a node to a document and a path (path is copied). */
void som_node_init(SomNode *n, SpecDocument *doc, const char *path);
void som_node_free(SomNode *n);
const char *som_node_path(const SomNode *n);
SpecDocument *som_node_doc(const SomNode *n);

/* Returns this node's list-item section id (owned; "" for non-list nodes, whose
 * id is the fixed `@SectionId` already embedded in the path). AA1 criterion 1. */
char *som_node_section_id(const SomNode *n);
/* Overrides this list item's section id (AA1 criterion 5): an arbitrary suffix,
 * validated unique within the owning list. An empty id is a no-op. On collision
 * or a non-live node writes `*err` and returns 0; returns 1 on success. `err`
 * may be NULL. */
int som_node_set_section_id(const SomNode *n, const char *id,
                            SpecSectionIdError *err);

/* ---- SomScalar — a bare string list item -------------------------------- */

typedef struct {
  SomNode node;
} SomScalar;

void som_scalar_init(SomScalar *s, SpecDocument *doc, const char *path);
void som_scalar_free(SomScalar *s);
/* Returns the value at this item's path (owned; "" when unset). */
char *som_scalar_value(const SomScalar *s);
/* Sets the value (empty string clears it, per SpecDocument). */
void som_scalar_set_value(SomScalar *s, const char *value);

/* ---- SomList — a typed view over a list field --------------------------- */

typedef struct {
  SpecDocument *doc; /* borrowed */
  char *list_path;   /* owned */
  char *pattern;     /* owned; the field's `@SectionIdPattern` ("" when none) */
} SomList;

/* Binds a pattern-less list view (equivalent to `som_list_init_pattern` with
 * pattern ""). */
void som_list_init(SomList *l, SpecDocument *doc, const char *list_path);
/* Binds a list view carrying the field's `@SectionIdPattern`, which drives
 * section-id generation on `som_list_add` / `som_list_add_on`. */
void som_list_init_pattern(SomList *l, SpecDocument *doc, const char *list_path,
                           const char *pattern);
void som_list_free(SomList *l);
size_t som_list_length(const SomList *l);
/* Borrowed item path at `index` (valid until the document is mutated). */
const char *som_list_item_path_at(const SomList *l, size_t index);
/* Every item path, in order, written into `out` (init by callee). */
void som_list_item_paths(const SomList *l, SomStrList *out);
/* The section ids currently assigned within the list, in item order (items
 * without an id are skipped), written into `out` (init by callee). */
void som_list_section_ids(const SomList *l, SomStrList *out);
/* Appends a new item and returns its stable path (owned). When the list carries
 * a pattern, the item is assigned a section id generated from that pattern using
 * today's date (AA1 criteria 3–4); a pattern-less list appends without an id. */
char *som_list_add(SomList *l);
/* Appends a new item whose generated section id uses the given `(month, day)`
 * for the two-letter-date component. For a pattern-less list the date is
 * ignored. Returns the item's stable path (owned). */
char *som_list_add_on(SomList *l, long long month, long long day);
/* Appends a new item with an explicit section id override (AA1 criterion 5),
 * validated unique within the list. On collision writes `*err` and returns 0;
 * on success writes an owned item path to `*out_item_path` (when non-NULL) and
 * returns 1. `err` may be NULL. */
int som_list_add_with_id(SomList *l, const char *section_id,
                         char **out_item_path, SpecSectionIdError *err);
/* Removes the item at `index` and everything nested beneath it. */
void som_list_remove_at(SomList *l, size_t index);

/* ---- model-version guard ------------------------------------------------ */

/* The instantiation-time check every generated root facade performs.
 * `generated` is the object model's own major.minor; `document_version` is the
 * document's recorded stamp ("" for a never-stamped document).
 *
 * Returns 0 when editing is permitted. On rejection returns non-zero and, when
 * `err_message` is non-NULL, writes an owned message there (caller frees).
 * Rules: empty stamp accepted; same major + doc-minor <= gen-minor editable;
 * doc-minor greater rejected; different major rejected (read/convert only). */
int check_som_model_version(const char *generated, const char *document_version,
                            char **err_message);

#endif /* SOM_FACADE_H */
