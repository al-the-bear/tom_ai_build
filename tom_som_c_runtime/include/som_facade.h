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
/* Returns 1 iff this section holds no value at its path or nested beneath it
 * (delegates to `spec_document_has_values_under`) (§ item 5). */
int som_node_is_empty(const SomNode *n);
/* `can_have_content` (§ item 10) — the per-TYPE structural predicate answering
 * "does this section type declare the standard `content` text leaf?", i.e. "can
 * this section hold body text?" — has **no base runtime helper**. C has no
 * inheritance or method promotion, so (following the item-8 `editability_for`
 * and item-5 `is_empty` per-type C emission precedent) the generated
 * `tom_som_c_v0` emits a `<type>_can_have_content(const <Type>*)` accessor for
 * EVERY generated section type, returning the literal answer (1 for a
 * content-bearing type, 0 for a container-only one). It never looks at the
 * document — it describes the model, not the data — so it is deliberately
 * distinct from the STATE predicates `spec_document_has_content` ("is a value
 * present at this leaf now?") and `som_node_is_empty` ("is this subtree empty
 * now?"). */
/* Overrides this list item's section id (AA1 criterion 5): an arbitrary suffix,
 * validated unique within the owning list. An empty id is a no-op. On collision
 * or a non-live node writes `*err` and returns 0; returns 1 on success. `err`
 * may be NULL. */
int som_node_set_section_id(const SomNode *n, const char *id,
                            SpecSectionIdError *err);
/* Returns this node's stored headline (owned; "" when unset) — the per-section
 * display headline overriding the derived md heading title (YRD3). */
char *som_node_headline(const SomNode *n);
/* Sets the stored headline; an empty value clears it (YRD3). */
void som_node_set_headline(const SomNode *n, const char *value);
/* Returns this section's CodeSpecs forward link (owned; "" when the section
 * carries no mapping) — the comma-joined list of CodeSpecs code locations,
 * sparse exactly like the stored headline (codespecs_mapping.md §9.2). */
char *som_node_code_spec(const SomNode *n);
/* Sets the stored CodeSpecs forward link; an empty value clears it, returning
 * the section to "no code mapping" (§9.2). */
void som_node_set_code_spec(const SomNode *n, const char *value);

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
/* Appends a content-only item and sets its nested `<item>/content` leaf in one
 * call (SOM convenience item 9). Delegates to `som_list_add` for the append —
 * so a pattern-carrying list assigns a section id from today's date just as a
 * bare add does — then writes `content` to the item's nested `<item>/content`
 * leaf via `spec_document_set_content`. Returns the item's stable path (owned;
 * caller frees), the same handle `som_list_add` returns. Targets the nested
 * content leaf only; scalar (bare-string) lists are out of scope. */
char *som_list_add_content(SomList *l, const char *content);
/* The `(month, day)` companion to `som_list_add_content`, delegating the append
 * to `som_list_add_on` so the generated section id uses the given date for its
 * two-letter-date component (ignored for a pattern-less list). Returns the
 * item's stable path (owned; caller frees). */
char *som_list_add_content_on(SomList *l, const char *content, long long month,
                              long long day);
/* Ordered read-only view of every item's nested `<item>/content` leaf, written
 * into `out` (initialised by callee; caller frees with `som_strlist_free`). A
 * missing leaf is coalesced to the empty string "" (C's absent-content
 * sentinel), so `out` always has exactly `som_list_length(l)` entries in item
 * order. Mirrors the Dart `SomList.contents` accessor. Nested content leaf
 * only; scalar lists are out of scope. */
void som_list_contents(const SomList *l, SomStrList *out);
/* Removes the item at `index` and everything nested beneath it. */
void som_list_remove_at(SomList *l, size_t index);

/* ---- model-version guard ------------------------------------------------ */

/* The outcome of the §2.2 version check, as a value a read-only viewer can
 * branch on instead of handling the error `check_som_model_version` reports
 * (§ item 8). It is the non-erroring companion to `check_som_model_version`:
 * that function reports an error on any value other than SOM_EDITABILITY_EDITABLE,
 * while `som_editability_for` returns the same classification without an error so
 * a consumer can decide *open for edit* vs *open read-only* up front. */
typedef enum {
  /* The object model may edit the document in place: an empty stamp (a
   * brand-new document) or a same-major, minor-`<=` stamp. */
  SOM_EDITABILITY_EDITABLE,
  /* The document was authored under a different major version; it may be
   * read/converted but never edited in place. */
  SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR,
  /* The document is same-major but a newer minor than the object model; an
   * older model must not edit a newer document. */
  SOM_EDITABILITY_REJECTED_NEWER_MINOR,
  /* The document stamp is not a valid major.minor string. */
  SOM_EDITABILITY_INVALID_VERSION
} SomEditability;

/* Classifies a document's editability under the §2.2 rules without reporting an
 * error (§ item 8). `generated` is the object model's own major.minor version;
 * `document_version` is the document's recorded authoring stamp (NULL or "" for
 * a brand-new, never-stamped document — the C empty-string sentinel, CS4-D2).
 *
 * This is the single definition of the version rules; `check_som_model_version`
 * switches on the value returned here, so the two never diverge. */
SomEditability som_editability_for(const char *generated,
                                   const char *document_version);

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
