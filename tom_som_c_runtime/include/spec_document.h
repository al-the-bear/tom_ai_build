/* spec_document — a sparse, live instance of a TomSpecs document, a faithful port
 * of the Rust `spec_document.rs`.
 *
 * The structure is defined by the SpecModel class graph; this holds only the
 * values actually set, keyed by the globally-unique section-ID path. Nothing is
 * materialised until written, so an untouched document is empty (the
 * "empty = no value" rule).
 *
 * Three sparse stores cover the writable field kinds:
 *   - content     — content/scalar leaves: path → string value;
 *   - forms       — `@Form` sections: path → (form-field name → value);
 *   - list_items  — lists: list path → ordered item paths.
 *
 * List item paths are `<listPath>-<seq>` where seq is a per-list monotonic
 * counter that never reuses a number. Every store is kept byte-sorted by key so
 * iteration order matches the Rust BTreeMap (the byte-stable codecs rely on it).
 *
 * Ownership: a document owns its whole store contents; free with
 * `spec_document_free`. A `DocumentJson` likewise owns its contents
 * (`document_json_free`).
 */
#ifndef SPEC_DOCUMENT_H
#define SPEC_DOCUMENT_H

#include "som_json.h"
#include "som_util.h"
#include "spec_meta.h"
#include "spec_section_id.h"

/* ---- DocumentJson — plain-data view for persistence --------------------- */

typedef struct {
  char *key;     /* form path, owned */
  SomMap fields; /* form-field name → value */
} DocFormEntry;

typedef struct {
  char *key; /* list path, owned */
  long long seq;
  SomStrList items;
  SomMap ids; /* item path → assigned section id (empty for id-less lists) */
} DocListEntry;

typedef struct {
  SomMap content; /* path → string */
  DocFormEntry *forms;
  size_t forms_len;
  size_t forms_cap;
  DocListEntry *lists;
  size_t lists_len;
  size_t lists_cap;
  SomMap headlines; /* path → stored headline (YRD3) */
  SomMap code_specs; /* path → stored codeSpec, comma-joined code locations (§9.2) */
} DocumentJson;

void document_json_init(DocumentJson *d);
void document_json_free(DocumentJson *d);

/* Builds a DocumentJson from a parsed `{content,forms,lists}` JSON value. */
void document_json_from_json(const SomJson *v, DocumentJson *out);

/* Renders a deterministic canonical JSON string (byte-sorted keys, fixed field
 * order content/forms/lists, omitting empty stores). Owned result. */
char *document_json_to_canonical_json(const DocumentJson *d);

/* Builder helpers: return the (created if absent) form field map / list entry
 * for `key`, keeping the store byte-sorted. Used by codecs that decode into a
 * DocumentJson. The returned pointer is valid until the next insert. */
SomMap *document_json_form_fields(DocumentJson *d, const char *key);
DocListEntry *document_json_list_entry(DocumentJson *d, const char *key);

/* ---- SpecDocument — the live sparse document ---------------------------- */

typedef struct {
  char *key;
  SomStrList items;
} DocListItems;

typedef struct {
  SomMap content;
  DocFormEntry *forms;
  size_t forms_len;
  size_t forms_cap;
  DocListItems *list_items;
  size_t list_items_len;
  size_t list_items_cap;
  SomMap list_seq;         /* list path → decimal seq counter */
  SomMap item_section_id;  /* item path → assigned section id (criteria 3–6) */
  SomMap headline;         /* path → stored headline (YRD3), sparse */
  SomMap code_spec;        /* path → stored codeSpec (§9.2), sparse like headline;
                            * the comma-joined list of CodeSpecs code locations */
  char *model_version;     /* owned; the authoring object-model version
                            * (major.minor) this document was loaded from, "" for
                            * a brand-new / unstamped document. Retained by
                            * `spec_document_from_yaml` so a consumer need not
                            * thread `decoded.model_version` to the typed facade
                            * by hand; the generated `<root>_load_yaml` /
                            * `<root>_load_file` functions apply it automatically. */
} SpecDocument;

void spec_document_init(SpecDocument *d);
void spec_document_free(SpecDocument *d);

/* Loads a `*.docspecs.yaml` document in one call: decode the hierarchical v2
 * YAML against `tree` (the metadata tree of the document's root), populate the
 * sparse stores, and retain the parsed model version on the document (§ item
 * 4). Returns an owned heap document (free with `spec_document_free` +
 * `free`); on a format error returns NULL and, when `err` is non-NULL, writes
 * an owned message. */
SpecDocument *spec_document_from_yaml(const char *yaml,
                                      const SomMetaTree *tree, char **err);
/* Loads a `*.docspecs.yaml` document from the file at `path` — the file
 * companion to `spec_document_from_yaml` the generated `<root>_load_file`
 * functions delegate to. Returns NULL (writing `*err`) when the file cannot
 * be read or fails to decode. */
SpecDocument *spec_document_from_file(const char *path,
                                      const SomMetaTree *tree, char **err);

/* content: returns the value at `path` or NULL; set with empty value to clear. */
const char *spec_document_content(const SpecDocument *d, const char *path);
void spec_document_set_content(SpecDocument *d, const char *path,
                               const char *value);
/* Returns 1 iff a non-empty content leaf exists at exactly `path` (leaf-exact;
 * a value nested beneath `path` does not count). The null-free companion to
 * `spec_document_content` (§ item 5). */
int spec_document_has_content(const SpecDocument *d, const char *path);

/* forms: returns form `field_name` at `path` or NULL; empty value clears it. */
const char *spec_document_form_field(const SpecDocument *d, const char *path,
                                     const char *field_name);
void spec_document_set_form_field(SpecDocument *d, const char *path,
                                  const char *field_name, const char *value);

/* lists: borrowed item list at `list_path` (NULL when none). */
const SomStrList *spec_document_list_items(const SpecDocument *d,
                                           const char *list_path);
/* Appends a new item and returns its stable path (owned). */
char *spec_document_add_list_item(SpecDocument *d, const char *list_path);
/* Removes `item_path` and everything nested beneath it; 1 if removed. */
int spec_document_remove_list_item(SpecDocument *d, const char *item_path);

/* section ids (AA1 criteria 3–6):
 * Appends a new item, assigns it `section_id`, and returns its stable path
 * (owned). On a uniqueness collision writes `*err` (COLLISION), leaves the
 * document untouched, and returns NULL. `err` may be NULL. */
char *spec_document_add_list_item_with_section_id(SpecDocument *d,
                                                  const char *list_path,
                                                  const char *section_id,
                                                  SpecSectionIdError *err);
/* Returns the section id assigned to `item_path`, or NULL when unset. */
const char *spec_document_item_section_id(const SpecDocument *d,
                                          const char *item_path);
/* Overrides the section id of the live list item at `item_path`. Assigning the
 * current id is a no-op. On collision writes `*err` (COLLISION) and returns 0;
 * if `item_path` is not a live item writes `*err` (NOT_LIVE_ITEM) and returns 0.
 * Returns 1 on success. `err` may be NULL. */
int spec_document_set_item_section_id(SpecDocument *d, const char *item_path,
                                      const char *id, SpecSectionIdError *err);
/* Writes the section ids currently assigned within `list_path` in item order
 * (items without an id are skipped) into `out` (initialised by callee). */
void spec_document_list_item_section_ids(const SpecDocument *d,
                                         const char *list_path, SomStrList *out);

/* headlines (YRD3): the stored per-section headline at `path`, or NULL when
 * unset. Set with an empty value to clear. */
const char *spec_document_headline(const SpecDocument *d, const char *path);
void spec_document_set_headline(SpecDocument *d, const char *path,
                                const char *value);
/* Writes every path carrying a stored headline (byte-sorted) into `out`
 * (initialised by callee). */
void spec_document_headline_paths(const SpecDocument *d, SomStrList *out);

/* codeSpec (§9.2): the stored per-section forward DocSpecs→CodeSpecs link at
 * `path` (the comma-joined list of code locations), or NULL when unset. Set
 * with an empty value to clear. Sparse like the headline. */
const char *spec_document_code_spec(const SpecDocument *d, const char *path);
void spec_document_set_code_spec(SpecDocument *d, const char *path,
                                 const char *value);
/* Writes every path carrying a stored codeSpec (byte-sorted) into `out`
 * (initialised by callee). */
void spec_document_code_spec_paths(const SpecDocument *d, SomStrList *out);

int spec_document_is_empty(const SpecDocument *d);
int spec_document_has_values_under(const SpecDocument *d, const char *prefix);

/* Enumerations (all byte-sorted) written into `out` (initialised by callee). */
void spec_document_content_paths(const SpecDocument *d, SomStrList *out);
void spec_document_form_paths(const SpecDocument *d, SomStrList *out);
void spec_document_list_paths(const SpecDocument *d, SomStrList *out);
void spec_document_form_field_names(const SpecDocument *d, const char *path,
                                    SomStrList *out);
size_t spec_document_list_item_count(const SpecDocument *d,
                                     const char *list_path);

/* Persistence: plain-data view / replace-all from a plain-data view. */
void spec_document_to_json(const SpecDocument *d, DocumentJson *out);
void spec_document_load_json(SpecDocument *d, const DocumentJson *j);

#endif /* SPEC_DOCUMENT_H */
