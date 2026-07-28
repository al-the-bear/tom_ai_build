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
  char *headline; /* @Headline(text) default headline (YRD4), "" when unannotated */
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
  char *headline; /* class-level @Headline(text) default (YRD4), "" when unannotated */
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
  /* Generation stamp. Every key is optional — a pre-stamp snapshot leaves the
   * `has_*` flag 0, which is *not* the same as a declared count of zero. C has
   * no calendar type, so the instant is carried as epoch seconds and the
   * sub-second part of the stamp is accepted but discarded. */
  int has_generated_at;
  long long generated_at; /* seconds since 1970-01-01T00:00:00Z */
  int has_meta_schema_version;
  long long meta_schema_version;
  int has_class_count;
  long long class_count;
  int has_root_count;
  long long root_count;
  char *container_root;
  SomJson *source; /* owned parsed tree; annotations borrow from it */
} SpecModel;

/* ---- generation stamp ---------------------------------------------------- */

#define SPEC_SECONDS_PER_DAY 86400LL
#define SPEC_DEFAULT_MAX_SNAPSHOT_AGE_SECONDS (14LL * SPEC_SECONDS_PER_DAY)

/* Parses the exporter's ISO-8601 stamp grammar
 * `YYYY-MM-DD[T ]hh:mm:ss[.fraction][Z|(+|-)hh[:]mm]` and writes the resulting
 * epoch seconds to `*out`. Returns 1 on success, 0 when `raw` does not match.
 *
 * The grammar is walked explicitly rather than handed to a platform parser, so
 * that all nine runtimes accept exactly the same set of strings: a zone-less
 * stamp is read as UTC (never local time), a day that does not exist in its
 * month is rejected rather than rolled over, and a date-only string is outside
 * the grammar. The fractional part is accepted and discarded. */
int spec_parse_stamp_timestamp(const char *raw, long long *out);

/* The verdict of comparing a snapshot's stamp against the world. */
typedef struct {
  int has_age;
  long long age_seconds;
  long long max_age_seconds;
  int has_declared_class_count;
  long long declared_class_count;
  long long actual_class_count;
  int has_declared_root_count;
  long long declared_root_count;
  long long actual_root_count;
} SpecModelStampCheck;

/* The snapshot is older than the threshold. */
int spec_stamp_check_is_aged(const SpecModelStampCheck *c);
/* The stamp's declared class count disagrees with what the snapshot carries. */
int spec_stamp_check_class_count_disagrees(const SpecModelStampCheck *c);
/* The stamp's declared root count disagrees with what the snapshot carries. */
int spec_stamp_check_root_count_disagrees(const SpecModelStampCheck *c);
/* Either count disagrees — the file was edited after export. */
int spec_stamp_check_counts_disagree(const SpecModelStampCheck *c);
/* Aged or edited: the snapshot should not be trusted as-is. */
int spec_stamp_check_is_stale(const SpecModelStampCheck *c);
/* Human-readable warnings, one per failed check, in age -> classes -> roots
 * order. Empty when the snapshot is sound. `out` is initialised by the callee;
 * the caller frees it with `som_strlist_free`. */
void spec_stamp_check_warnings(const SpecModelStampCheck *c, SomStrList *out);

/* Compares this model's stamp against `now_epoch_seconds` (seconds since the
 * Unix epoch) with `max_age_seconds` as the staleness threshold. */
SpecModelStampCheck spec_model_check_stamp(const SpecModel *m,
                                           long long max_age_seconds,
                                           long long now_epoch_seconds);

/* Returns the class named `name`, or NULL. */
const SpecClass *spec_model_class_named(const SpecModel *m, const char *name);

/* Returns the document root whose `type` equals `type` (SOM §21), or NULL when
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

/* Derives the `major.minor` DocSpecs version string from a model's integer
 * version and its optional free-form label (port of the Go
 * `SomModelVersionString` / Python `som_model_version_string`).
 *
 * When the label's `+`-stripped core has at least two dot-separated integer
 * components, those become `major.minor`; otherwise the result is `<major>.0`.
 * Owned result (caller frees with `free`). */
char *som_model_version_string(long long major, const char *label);

#endif /* SPEC_MODEL_H */
