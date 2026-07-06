#include "spec_serialization_order.h"

#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"
#include "spec_reflection.h"

SpecSerializationOrder spec_serialization_order_make(const SpecModel *model) {
  SpecSerializationOrder o;
  o.model = model;
  return o;
}

/* ---- i64 ordinal tuple -------------------------------------------------- */

typedef struct {
  long long *data;
  size_t len;
  size_t cap;
} I64Vec;

static void i64vec_init(I64Vec *v) {
  v->data = NULL;
  v->len = 0;
  v->cap = 0;
}

static void i64vec_push(I64Vec *v, long long x) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 4;
    v->data = (long long *)realloc(v->data, v->cap * sizeof(long long));
  }
  v->data[v->len++] = x;
}

static void i64vec_free(I64Vec *v) {
  free(v->data);
  v->data = NULL;
  v->len = 0;
  v->cap = 0;
}

static long long order_of(const SpecField *field) {
  return field->has_serialization_order ? field->serialization_order
                                        : SPEC_SERIALIZATION_UNORDERED_FALLBACK;
}

/* Returns the field of `cls` whose section segment equals `segment`, or NULL. */
static const SpecField *match_field(const SpecClass *cls, const char *segment) {
  for (size_t i = 0; i < cls->fields_len; i++) {
    if (strcmp(spec_reflection_field_segment(&cls->fields[i]), segment) == 0) {
      return &cls->fields[i];
    }
  }
  return NULL;
}

/* Computes the ordinal tuple for `path`: one entry per field crossed (its
 * `@SerializationOrder` or the fallback), plus a trailing entry for a list
 * item's numeric sequence. A path that does not resolve yields an empty tuple
 * (so it sorts by its string form only). */
static void order_key(const SpecSerializationOrder *o, const char *path,
                      I64Vec *key) {
  i64vec_init(key);

  SomStrList segs;
  spec_path_segments(path, &segs);
  if (segs.len == 0 || segs.items[0][0] == '\0') {
    som_strlist_free(&segs);
    return;
  }

  SpecReflection refl = spec_reflection_make(o->model);
  const SpecRoot *root = spec_reflection_root_for_segment(&refl, segs.items[0]);
  if (root == NULL) {
    som_strlist_free(&segs);
    return;
  }

  const SpecClass *cur_class = spec_model_class_named(o->model, root->type);
  size_t i = 1;
  while (i < segs.len) {
    if (cur_class == NULL) {
      break;
    }
    const char *seg = segs.items[i];

    const SpecField *field = match_field(cur_class, seg);
    if (field != NULL) {
      i64vec_push(key, order_of(field));
      if (strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
          strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0) {
        cur_class = spec_model_class_named(o->model, field->type);
        i++;
        continue;
      }
      break; /* list container / leaf / form terminates the descent */
    }

    /* A list item segment: `<base>-<seq>`. */
    char *base = NULL;
    long long seq = 0;
    if (!spec_split_list_item_segment(seg, &base, &seq)) {
      break;
    }
    const SpecField *list_field = match_field(cur_class, base);
    free(base);
    if (list_field == NULL ||
        strcmp(list_field->kind, SPEC_FIELD_KIND_LIST) != 0) {
      break;
    }
    i64vec_push(key, order_of(list_field));
    i64vec_push(key, seq);
    if (list_field->element_is_complex) {
      cur_class = spec_model_class_named(o->model, list_field->element_type);
      i++;
      continue;
    }
    break; /* scalar list item is a leaf */
  }

  som_strlist_free(&segs);
}

/* Reproduces the Rust `compare_order_keys` total order: element-wise on the
 * shared prefix, then by length, then ties break on the path string. */
static int compare_order_keys(const I64Vec *a, const char *a_path,
                              const I64Vec *b, const char *b_path) {
  size_t n = a->len < b->len ? a->len : b->len;
  for (size_t i = 0; i < n; i++) {
    if (a->data[i] != b->data[i]) {
      return a->data[i] < b->data[i] ? -1 : 1;
    }
  }
  if (a->len != b->len) {
    return a->len < b->len ? -1 : 1;
  }
  return strcmp(a_path, b_path);
}

typedef struct {
  char *path; /* borrowed from input list */
  I64Vec key;
} PathKey;

static int path_key_cmp(const void *a, const void *b) {
  const PathKey *pa = (const PathKey *)a;
  const PathKey *pb = (const PathKey *)b;
  return compare_order_keys(&pa->key, pa->path, &pb->key, pb->path);
}

void spec_serialization_order_paths(const SpecSerializationOrder *o,
                                    const SomStrList *paths, SomStrList *out) {
  som_strlist_init(out);
  size_t n = paths->len;
  if (n == 0) {
    return;
  }
  PathKey *items = (PathKey *)calloc(n, sizeof(PathKey));
  for (size_t i = 0; i < n; i++) {
    items[i].path = paths->items[i];
    order_key(o, paths->items[i], &items[i].key);
  }
  qsort(items, n, sizeof(PathKey), path_key_cmp);
  for (size_t i = 0; i < n; i++) {
    som_strlist_push_copy(out, items[i].path);
    i64vec_free(&items[i].key);
  }
  free(items);
}

/* ---- form fields -------------------------------------------------------- */

typedef struct {
  const char *name; /* borrowed from input list */
  size_t pos;
} FieldPos;

static int field_pos_cmp(const void *a, const void *b) {
  const FieldPos *fa = (const FieldPos *)a;
  const FieldPos *fb = (const FieldPos *)b;
  if (fa->pos != fb->pos) {
    return fa->pos < fb->pos ? -1 : 1;
  }
  return strcmp(fa->name, fb->name);
}

void spec_serialization_order_form_fields(const SpecSerializationOrder *o,
                                          const char *form_path,
                                          const SomStrList *field_names,
                                          SomStrList *out) {
  som_strlist_init(out);
  size_t n = field_names->len;
  if (n == 0) {
    return;
  }

  /* Resolve the form's declared field order (positions), if any. */
  const FormFieldSpec *form_fields = NULL;
  size_t form_fields_len = 0;
  SpecReflection refl = spec_reflection_make(o->model);
  SpecResolution res;
  int resolved = spec_reflection_resolve(&refl, form_path, &res);
  if (resolved) {
    if (res.field != NULL) {
      form_fields = res.field->form_fields;
      form_fields_len = res.field->form_fields_len;
    }
  }

  FieldPos *items = (FieldPos *)calloc(n, sizeof(FieldPos));
  for (size_t i = 0; i < n; i++) {
    items[i].name = field_names->items[i];
    size_t pos = (size_t)SPEC_SERIALIZATION_UNORDERED_FALLBACK;
    for (size_t j = 0; j < form_fields_len; j++) {
      if (strcmp(form_fields[j].name, field_names->items[i]) == 0) {
        pos = j;
        break;
      }
    }
    items[i].pos = pos;
  }
  if (resolved) {
    spec_resolution_free(&res);
  }

  qsort(items, n, sizeof(FieldPos), field_pos_cmp);
  for (size_t i = 0; i < n; i++) {
    som_strlist_push_copy(out, items[i].name);
  }
  free(items);
}
