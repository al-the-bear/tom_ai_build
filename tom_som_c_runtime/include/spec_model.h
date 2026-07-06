/* spec_model — in-memory representation of the exported TomSpecs class graph (the
 * spec-model meta-data file), a faithful port of the Rust `spec_model.rs`.
 *
 * The model is a class graph, not an expanded tree: each class appears once and
 * field `elementType`/`type` references are followed on demand by a traversal.
 *
 * Ownership: the model owns its whole structure plus the parsed source JSON tree
 * (annotation argument objects are borrowed pointers into it). Free with
 * `spec_model_free`.
 */
#ifndef SPEC_MODEL_H
#define SPEC_MODEL_H

#include "som_json.h"
#include "som_util.h"

#define SPEC_FIELD_KIND_LIST "list"
#define SPEC_FIELD_KIND_FORM "form"
#define SPEC_FIELD_KIND_SECTION "section"
#define SPEC_FIELD_KIND_CONTENT "content"
#define SPEC_FIELD_KIND_ENUM "enum"
#define SPEC_FIELD_KIND_COMPLEX "complex"
#define SPEC_FIELD_KIND_SCALAR "scalar"

/* Returns the canonical kind for `raw`, falling back to "scalar". The returned
 * pointer is a static string literal. */
const char *spec_parse_field_kind(const char *raw);

typedef struct {
  char *name;               /* owned */
  const SomJson *arguments; /* borrowed object node into the model source (or NULL) */
} SpecAnnotation;

typedef struct {
  SpecAnnotation *items;
  size_t len;
} SpecAnnotationList;

/* Returns the argument value for `key` on `ann`, or NULL. */
const SomJson *spec_annotation_argument(const SpecAnnotation *ann, const char *key);

typedef struct {
  char *name;
  char *label;
  char *type; /* defaults to "String" */
  char *hint;
  int required;
} FormFieldSpec;

typedef struct {
  char *name;
  char *kind;
  char *doc;
  char *help;
  char *section_id;
  char *section_id_pattern;
  char *element_type;
  int element_is_complex;
  int has_min;
  long long min;
  char *content_type;
  char *section_type;
  char *enum_type;
  SomStrList enum_values;
  char *type;
  int has_serialization_order;
  long long serialization_order;
  FormFieldSpec *form_fields;
  size_t form_fields_len;
  SpecAnnotationList annotations;
} SpecField;

/* Reports whether expanding this field reveals further tree nodes. */
int spec_field_is_expandable(const SpecField *f);

typedef struct {
  char *name;
  char *section_id;
  char *doc;
  char *help;
  char *maps_to;
  char *detailed_in;
  SpecField *fields;
  size_t fields_len;
  SpecAnnotationList annotations;
} SpecClass;

/* Returns the field named `name` on `cls`, or NULL. */
const SpecField *spec_class_field_named(const SpecClass *cls, const char *name);

typedef struct {
  char *type;
  char *title;
  char *section_id;
  char *description;
  char *doc;
} SpecRoot;

typedef struct {
  char *name;
  SpecClass *cls;
} SpecClassEntry;

typedef struct {
  SpecRoot *roots;
  size_t roots_len;
  SpecClassEntry *classes; /* sorted by name (binary-searchable) */
  size_t classes_len;
  long long model_version;
  char *model_version_label;
  SomJson *source; /* owned parsed tree; annotations borrow from it */
} SpecModel;

/* Returns the class named `name`, or NULL. */
const SpecClass *spec_model_class_named(const SpecModel *m, const char *name);

/* Returns the document root whose `type` equals `type` (§ item 12), or NULL when
 * no root carries that type. On the NULL path, when `err` is non-NULL, writes an
 * owned message naming the missing type and the ones that do exist (caller frees
 * with `free`); on success `*err` is left untouched. Replaces the recurring
 * `roots.firstWhere((r) => r.type == …)` boilerplate. */
const SpecRoot *spec_model_root_by_type(const SpecModel *m, const char *type,
                                        char **err);

/* Decodes a meta-data JSON document. On failure returns NULL and, when `err` is
 * non-NULL, writes an owned error message. */
SpecModel *spec_model_from_json_str(const char *data, char **err);

/* Builds a model from an already-parsed meta-data JSON node. The node is
 * *borrowed* (annotation arguments point into it) and must outlive the model;
 * `spec_model_free` does not free it (unlike `spec_model_from_json_str`, which
 * owns the parsed tree). */
SpecModel *spec_model_from_json(const SomJson *root);

void spec_model_free(SpecModel *m);

#endif /* SPEC_MODEL_H */
