/* spec_links_validator — the link checks of one document
 * (`tom_specs_model_rules.md` §9.7). See include/spec_links_validator.h. */
#include "spec_links_validator.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_review_annotations.h"
#include "spec_section_id.h"

/* ---- small string helpers ------------------------------------------------- */

/* The concatenation of the strings up to the terminating NULL. Owned. */
static char *scat(const char *first, ...) {
  SomBuf b;
  som_buf_init(&b);
  va_list ap;
  va_start(ap, first);
  for (const char *s = first; s != NULL; s = va_arg(ap, const char *)) {
    som_buf_puts(&b, s);
  }
  va_end(ap);
  return som_buf_take(&b);
}

static int is_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

static char *trim_dup(const char *s) {
  if (s == NULL) return som_strdup("");
  while (is_space(*s)) s++;
  size_t n = strlen(s);
  while (n > 0 && is_space(s[n - 1])) n--;
  return som_strdup_n(s, n);
}

static int starts_with(const char *s, const char *prefix) {
  return strncmp(s, prefix, strlen(prefix)) == 0;
}

static int ends_with(const char *s, const char *suffix) {
  size_t n = strlen(s), m = strlen(suffix);
  return n >= m && strcmp(s + n - m, suffix) == 0;
}

static int has_text(const char *s) { return s != NULL && s[0] != '\0'; }

static int str_eq(const char *a, const char *b) {
  return strcmp(a != NULL ? a : "", b != NULL ? b : "") == 0;
}

/* `s` up to its last `c`, or NULL when it holds none. Owned. */
static char *before_last(const char *s, char c) {
  const char *p = strrchr(s, c);
  return p == NULL ? NULL : som_strdup_n(s, (size_t)(p - s));
}

/* Whether `path` lies at or beneath `root`. */
static int under_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && (path[n] == '\0' || path[n] == '/');
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void sort_list(SomStrList *l) {
  if (l->len > 1) qsort(l->items, l->len, sizeof(char *), cmp_str);
}

static int lists_equal(const SomStrList *a, const SomStrList *b) {
  if (a->len != b->len) return 0;
  for (size_t i = 0; i < a->len; i++) {
    if (strcmp(a->items[i], b->items[i]) != 0) return 0;
  }
  return 1;
}

static void push_unique(SomStrList *l, const char *s) {
  if (!som_strlist_contains(l, s)) som_strlist_push_copy(l, s);
}

static int set_has(const SomMap *m, const char *key) {
  return som_map_get(m, key) != NULL;
}

static void set_add(SomMap *m, const char *key) { som_map_set(m, key, "1"); }

/* `^[+-]?[0-9]+$`. */
static int is_int_text(const char *s) {
  if (*s == '+' || *s == '-') s++;
  if (*s == '\0') return 0;
  for (; *s; s++) {
    if (*s < '0' || *s > '9') return 0;
  }
  return 1;
}

/* `^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$`. */
static int is_float_text(const char *s) {
  if (*s == '+' || *s == '-') s++;
  size_t digits = 0;
  while (*s >= '0' && *s <= '9') {
    s++;
    digits++;
  }
  if (*s == '.') {
    s++;
    size_t frac = 0;
    while (*s >= '0' && *s <= '9') {
      s++;
      frac++;
    }
    if (digits == 0 && frac == 0) return 0;
  } else if (digits == 0) {
    return 0;
  }
  if (*s == 'e' || *s == 'E') {
    s++;
    if (*s == '+' || *s == '-') s++;
    if (*s < '0' || *s > '9') return 0;
    while (*s >= '0' && *s <= '9') s++;
  }
  return *s == '\0';
}

/* Dart's `num.tryParse` (decimal and hexadecimal forms, NaN, Infinity;
 * surrounding whitespace allowed). */
static int num_try_parse(const char *text, double *out) {
  char *t = trim_dup(text);
  int ok = 1;
  if (is_int_text(t) || is_float_text(t)) {
    *out = strtod(t, NULL);
  } else if ((t[0] == '0') && (t[1] == 'x' || t[1] == 'X') && t[2] != '\0' &&
             strspn(t + 2, "0123456789abcdefABCDEF") == strlen(t + 2)) {
    *out = (double)strtoll(t + 2, NULL, 16);
  } else if (strcmp(t, "NaN") == 0) {
    *out = 0.0 / 0.0;
  } else if (strcmp(t, "Infinity") == 0) {
    *out = 1.0 / 0.0;
  } else if (strcmp(t, "-Infinity") == 0) {
    *out = -1.0 / 0.0;
  } else {
    ok = 0;
  }
  free(t);
  return ok;
}

/* ---- the public helpers --------------------------------------------------- */

void spec_link_ids(const char *value, SomStrList *out) {
  som_strlist_init(out);
  if (value == NULL) return;
  const char *s = value;
  for (;;) {
    const char *comma = strchr(s, ',');
    size_t n = comma == NULL ? strlen(s) : (size_t)(comma - s);
    char *piece = som_strdup_n(s, n);
    char *t = trim_dup(piece);
    free(piece);
    if (t[0] != '\0') {
      som_strlist_push(out, t);
    } else {
      free(t);
    }
    if (comma == NULL) break;
    s = comma + 1;
  }
}

static int ids_contain(const char *value, const char *id) {
  SomStrList ids;
  spec_link_ids(value, &ids);
  int hit = som_strlist_contains(&ids, id);
  som_strlist_free(&ids);
  return hit;
}

void spec_expand_pattern(const SpecDocument *doc, const char *pattern,
                         SomStrList *out) {
  SomStrList paths, segs;
  som_strlist_init(&paths);
  som_strlist_push_copy(&paths, "");
  som_strlist_init(&segs);
  const char *s = pattern;
  for (;;) {
    const char *slash = strchr(s, '/');
    size_t n = slash == NULL ? strlen(s) : (size_t)(slash - s);
    som_strlist_push(&segs, som_strdup_n(s, n));
    if (slash == NULL) break;
    s = slash + 1;
  }
  for (size_t k = 0; k < segs.len; k++) {
    const char *seg = segs.items[k];
    SomStrList next;
    som_strlist_init(&next);
    for (size_t i = 0; i < paths.len; i++) {
      char *base = paths.items[i][0] == '\0' ? som_strdup(seg)
                                             : scat(paths.items[i], "/", seg, NULL);
      if (ends_with(seg, "-*")) {
        base[strlen(base) - 2] = '\0';
        const SomStrList *items = spec_document_list_items(doc, base);
        if (items != NULL) {
          for (size_t j = 0; j < items->len; j++) {
            som_strlist_push_copy(&next, items->items[j]);
          }
        }
        free(base);
      } else {
        som_strlist_push(&next, base);
      }
    }
    som_strlist_free(&paths);
    paths = next;
  }
  som_strlist_free(&segs);
  *out = paths;
}

int spec_resolve_place_at(const SpecReflection *refl, const char *place,
                          const char *anchor, SpecPlaceResolution *out) {
  SpecPlace p;
  if (!spec_place_try_parse(place, &p)) return 0;
  SpecPlaceError err;
  spec_place_error_init(&err);
  int ok = spec_place_resolve(&p, refl, anchor, out, &err);
  spec_place_error_free(&err);
  spec_place_free(&p);
  return ok;
}

int spec_resolve_link_place(const SpecReflection *refl, const SpecDocument *doc,
                            const char *place, const char *root,
                            const char *anchor, SpecPlaceResolution *out) {
  if (starts_with(place, "./")) {
    return spec_resolve_place_at(refl, place, anchor, out);
  }
  /* The grammar's own scope first: the subtree of the annotated section. */
  if (strcmp(anchor, root) != 0 &&
      spec_resolve_place_at(refl, place, anchor, out)) {
    return 1;
  }
  const char *slash = strchr(place, '/');
  if (slash == NULL) return spec_resolve_place_at(refl, place, root, out);
  char *head_text = som_strdup_n(place, (size_t)(slash - place));
  SpecPlaceResolution head;
  int ok = spec_resolve_place_at(refl, head_text, root, &head);
  free(head_text);
  if (!ok) return 0;
  char *scope = strcmp(head.kind, SPEC_PLACE_KIND_LIST) == 0
                    ? scat(head.path, "-*", NULL)
                    : som_strdup(head.path);
  spec_place_resolution_free(&head);
  /* A pattern anchor resolves through its first concrete instance; the rest
   * of the place is relative, so the pattern is rebuilt below. */
  SomStrList concrete;
  som_strlist_init(&concrete);
  if (doc != NULL) {
    spec_expand_pattern(doc, scope, &concrete);
  } else if (strstr(scope, "-*") == NULL) {
    som_strlist_push_copy(&concrete, scope);
  }
  ok = 0;
  if (concrete.len > 0) {
    SpecPlaceResolution rest;
    if (spec_resolve_place_at(refl, slash + 1, concrete.items[0], &rest)) {
      size_t n = strlen(concrete.items[0]);
      const char *tail = strlen(rest.path) > n ? rest.path + n : "";
      char *path = scat(scope, tail, NULL);
      free(rest.path);
      rest.path = path;
      *out = rest;
      ok = 1;
    }
  }
  som_strlist_free(&concrete);
  free(scope);
  return ok;
}

const char *spec_link_field_of(const SpecPlaceResolution *r) {
  if (strcmp(r->kind, SPEC_PLACE_KIND_FORM_FIELD) == 0) {
    return spec_place_resolution_field(r);
  }
  if (strcmp(r->kind, SPEC_PLACE_KIND_HEADLINE) == 0) return SPEC_HEADLINE_FIELD;
  return NULL;
}

/* ---- SpecLinkFix ----------------------------------------------------------- */

void spec_link_fix_free(SpecLinkFix *f) {
  free(f->path);
  free(f->field);
  free(f->value);
  spec_string_pairs_free(&f->values);
  for (size_t i = 0; i < f->tuples_len; i++) {
    spec_string_pairs_free(&f->tuples[i]);
  }
  free(f->tuples);
  som_strlist_free(&f->tuple_keys);
  free(f->holder);
  memset(f, 0, sizeof(*f));
}

static void put_json_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

char *spec_link_fix_to_json(const SpecLinkFix *f) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"step\":");
  som_buf_puti(&b, f->step);
  som_buf_puts(&b, ",\"kind\":");
  put_json_str(&b, f->kind);
  som_buf_puts(&b, ",\"path\":");
  put_json_str(&b, f->path);
  if (strcmp(f->kind, SPEC_LINK_FIX_SET) == 0 ||
      strcmp(f->kind, SPEC_LINK_FIX_APPEND) == 0) {
    som_buf_puts(&b, ",\"field\":");
    if (f->field != NULL) {
      put_json_str(&b, f->field);
    } else {
      som_buf_puts(&b, "null");
    }
    som_buf_puts(&b, ",\"value\":");
    put_json_str(&b, f->value);
  } else if (strcmp(f->kind, SPEC_LINK_FIX_ADD_ROW) == 0) {
    char *values = spec_string_pairs_to_json(&f->values);
    som_buf_puts(&b, ",\"values\":");
    som_buf_puts(&b, values);
    free(values);
  } else if (strcmp(f->kind, SPEC_LINK_FIX_REMOVE_ROW) == 0) {
    som_buf_puts(&b, ",\"empty\":");
    som_buf_puts(&b, f->empty ? "true" : "false");
  } else if (strcmp(f->kind, SPEC_LINK_FIX_LIST) == 0) {
    som_buf_puts(&b, ",\"tuples\":[");
    for (size_t i = 0; i < f->tuples_len; i++) {
      if (i > 0) som_buf_putc(&b, ',');
      char *t = spec_string_pairs_to_json(&f->tuples[i]);
      som_buf_puts(&b, t);
      free(t);
    }
    som_buf_putc(&b, ']');
  } else if (strcmp(f->kind, SPEC_LINK_FIX_COPY) == 0) {
    som_buf_puts(&b, ",\"holder\":");
    put_json_str(&b, f->holder);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

static SpecLinkFix *fix_push(SpecLinkValidator *v, int step, const char *kind,
                             const char *path) {
  SpecLinkFixes *l = &v->fixes;
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 8;
    l->items = (SpecLinkFix *)realloc(l->items, l->cap * sizeof(SpecLinkFix));
  }
  SpecLinkFix *f = &l->items[l->len++];
  memset(f, 0, sizeof(*f));
  f->step = step;
  f->kind = kind;
  f->path = som_strdup(path);
  spec_string_pairs_init(&f->values);
  som_strlist_init(&f->tuple_keys);
  return f;
}

static void fix_set(SpecLinkValidator *v, int step, const char *path,
                    const char *field, const char *value) {
  SpecLinkFix *f = fix_push(v, step, SPEC_LINK_FIX_SET, path);
  f->field = field != NULL ? som_strdup(field) : NULL;
  f->value = som_strdup(value);
}

/* ---- the validator's private state ----------------------------------------- */

struct SpecLinkValidatorCache {
  SomMap reported; /* code path message -> 1 */
  SomMap pending;  /* path what -> 1 */
  /* The derived values computed so far (`path#field` -> value), read before
   * the stored value so a derivation from a derived place sees its derived
   * value. */
  SomMap derived;
  SomMap items; /* path -> "1" / "0" (is a complex list item) */
  int have_form_paths;
  SomStrList form_paths; /* sorted */
  SomStrList entries_keys;
  SomMap *entries; /* parallel to entries_keys: id -> item path */
  int have_valued;
  SomMap valued;
};

void spec_link_validator_init(SpecLinkValidator *v, const SpecModel *model,
                              const SpecDocument *doc, int read_proposed) {
  memset(v, 0, sizeof(*v));
  v->errors.items = NULL;
  v->errors.len = 0;
  v->errors.cap = 0;
  som_map_init(&v->item_ids);
  v->read_proposed = read_proposed;
  v->model = model;
  v->doc = doc;
  v->refl = spec_reflection_make(model);
  v->cache = (SpecLinkValidatorCache *)calloc(1, sizeof(SpecLinkValidatorCache));
  som_map_init(&v->cache->reported);
  som_map_init(&v->cache->pending);
  som_map_init(&v->cache->derived);
  som_map_init(&v->cache->items);
  som_strlist_init(&v->cache->form_paths);
  som_strlist_init(&v->cache->entries_keys);
  som_map_init(&v->cache->valued);
}

void spec_link_validator_free(SpecLinkValidator *v) {
  for (size_t i = 0; i < v->fixes.len; i++) spec_link_fix_free(&v->fixes.items[i]);
  free(v->fixes.items);
  spec_validation_errors_free(&v->errors);
  som_map_free(&v->item_ids);
  if (v->cache != NULL) {
    SpecLinkValidatorCache *c = v->cache;
    som_map_free(&c->reported);
    som_map_free(&c->pending);
    som_map_free(&c->derived);
    som_map_free(&c->items);
    som_strlist_free(&c->form_paths);
    for (size_t i = 0; i < c->entries_keys.len; i++) som_map_free(&c->entries[i]);
    free(c->entries);
    som_strlist_free(&c->entries_keys);
    som_map_free(&c->valued);
    free(c);
  }
  memset(v, 0, sizeof(*v));
}

void spec_link_validator_report(SpecLinkValidator *v, const char *code,
                                const char *path, const char *message) {
  char *key = scat(code, " ", path, " ", message, NULL);
  if (!set_has(&v->cache->reported, key)) {
    set_add(&v->cache->reported, key);
    spec_validation_errors_push(&v->errors, path, code, message);
  }
  free(key);
}

/* Reports and frees `message`. */
static void report(SpecLinkValidator *v, const char *code, const char *path,
                   char *message) {
  spec_link_validator_report(v, code, path, message);
  free(message);
}

static const SomStrList *form_paths(SpecLinkValidator *v) {
  if (!v->cache->have_form_paths) {
    spec_document_form_paths(v->doc, &v->cache->form_paths);
    sort_list(&v->cache->form_paths);
    v->cache->have_form_paths = 1;
  }
  return &v->cache->form_paths;
}

/* ---- reading values -------------------------------------------------------- */

/* The reviewed reading of a raw value (NULL: absent); a value with pending
 * marks is listed once. Owned. */
static char *reviewed(SpecLinkValidator *v, const char *raw, const char *path,
                      const char *what) {
  if (raw == NULL) return som_strdup("");
  if (v->read_proposed) {
    char *accepted = spec_apply_inline_marks_text(raw, 1);
    char *out = trim_dup(accepted);
    free(accepted);
    return out;
  }
  char *rejected = spec_apply_inline_marks_text(raw, 0);
  char *accepted = spec_apply_inline_marks_text(raw, 1);
  char *key = scat(path, " ", what, NULL);
  if (strcmp(accepted, rejected) != 0 && !set_has(&v->cache->pending, key)) {
    set_add(&v->cache->pending, key);
    report(v, SPEC_VALIDATION_CODE_LINK_VALUE_PENDING, path,
           scat(what, " holds pending change marks; it is read with every mark "
                      "rejected", NULL));
  }
  free(key);
  free(accepted);
  char *out = trim_dup(rejected);
  free(rejected);
  return out;
}

static char *derived_key(const char *path, const char *field) {
  return scat(path, "#", field != NULL ? field : "", NULL);
}

char *spec_link_validator_form_value(SpecLinkValidator *v, const char *path,
                                     const char *field) {
  char *key = derived_key(path, field);
  const char *d = som_map_get(&v->cache->derived, key);
  free(key);
  if (d != NULL) return som_strdup(d);
  char *what = scat("form field \"", field, "\"", NULL);
  char *out =
      reviewed(v, spec_document_form_field(v->doc, path, field), path, what);
  free(what);
  return out;
}

char *spec_link_validator_content_value(SpecLinkValidator *v,
                                        const char *path) {
  char *key = derived_key(path, NULL);
  const char *d = som_map_get(&v->cache->derived, key);
  free(key);
  if (d != NULL) return som_strdup(d);
  return reviewed(v, spec_document_content(v->doc, path), path, "the content");
}

char *spec_link_validator_headline_value(SpecLinkValidator *v,
                                         const char *path) {
  return reviewed(v, spec_document_headline(v->doc, path), path,
                  "the headline");
}

static char *compute_item_id(SpecLinkValidator *v, const char *item_path) {
  const char *stored = spec_document_item_section_id(v->doc, item_path);
  if (stored != NULL) return som_strdup(stored);
  char *lst = before_last(item_path, '-');
  if (lst == NULL) lst = som_strdup(item_path);
  const SomStrList *items = spec_document_list_items(v->doc, lst);
  long long position = 0;
  if (items != NULL) {
    for (size_t k = 0; k < items->len; k++) {
      if (strcmp(items->items[k], item_path) == 0) {
        position = (long long)k + 1;
        break;
      }
    }
  }
  const char *slash = strrchr(lst, '/');
  char *stem = som_strdup(slash != NULL ? slash + 1 : lst);
  char *pattern = som_strdup("");
  SpecResolution res;
  if (spec_reflection_resolve(&v->refl, lst, &res)) {
    if (res.field != NULL) {
      free(pattern);
      free(stem);
      pattern = som_strdup(res.field->section_id_pattern != NULL
                               ? res.field->section_id_pattern
                               : "");
      stem = som_strdup(res.field->name);
    }
    spec_resolution_free(&res);
  }
  char *id = spec_effective_list_item_section_id(NULL, pattern, position, stem);
  free(pattern);
  free(stem);
  free(lst);
  return id;
}

char *spec_link_validator_item_id(SpecLinkValidator *v, const char *item_path) {
  const char *hit = som_map_get(&v->item_ids, item_path);
  if (hit != NULL) return som_strdup(hit);
  char *id = compute_item_id(v, item_path);
  som_map_set(&v->item_ids, item_path, id);
  return id;
}

int spec_link_validator_is_item(SpecLinkValidator *v, const char *path) {
  const char *hit = som_map_get(&v->cache->items, path);
  if (hit != NULL) return hit[0] == '1';
  SpecResolution r;
  int item = 0;
  if (spec_reflection_resolve(&v->refl, path, &r)) {
    item = strcmp(r.kind, SPEC_NODE_KIND_LIST_ITEM_COMPLEX) == 0;
    spec_resolution_free(&r);
  }
  som_map_set(&v->cache->items, path, item ? "1" : "0");
  return item;
}

char *spec_link_validator_value(SpecLinkValidator *v,
                                const SpecPlaceResolution *r,
                                const char *path) {
  if (strcmp(r->kind, SPEC_PLACE_KIND_FORM_FIELD) == 0) {
    return spec_link_validator_form_value(v, path,
                                          spec_place_resolution_field(r));
  }
  if (strcmp(r->kind, SPEC_PLACE_KIND_CONTENT) == 0) {
    return spec_link_validator_content_value(v, path);
  }
  if (strcmp(r->kind, SPEC_PLACE_KIND_HEADLINE) == 0) {
    return spec_link_validator_headline_value(v, path);
  }
  if (strcmp(r->kind, SPEC_PLACE_KIND_SECTION_ID) == 0 &&
      spec_link_validator_is_item(v, path)) {
    return spec_link_validator_item_id(v, path);
  }
  return som_strdup("");
}

static void expand(SpecLinkValidator *v, const char *pattern, SomStrList *out) {
  spec_expand_pattern(v->doc, pattern, out);
}

static int at(SpecLinkValidator *v, const char *place, const char *anchor,
              SpecPlaceResolution *out) {
  return spec_resolve_place_at(&v->refl, place, anchor, out);
}

static int global(SpecLinkValidator *v, const char *place, const char *root,
                  const char *anchor, SpecPlaceResolution *out) {
  return spec_resolve_link_place(&v->refl, v->doc, place, root, anchor, out);
}

char *spec_link_validator_place_value(SpecLinkValidator *v, const char *place,
                                      const char *anchor) {
  SpecPlaceResolution r;
  if (!at(v, place, anchor, &r)) return som_strdup("");
  SomStrList paths;
  expand(v, r.path, &paths);
  char *out = paths.len == 1 ? spec_link_validator_value(v, &r, paths.items[0])
                             : som_strdup("");
  som_strlist_free(&paths);
  spec_place_resolution_free(&r);
  return out;
}

/* The values a row's own forms (`<row>/<member>`) hold in `field`. */
static void own_values(SpecLinkValidator *v, const char *row, const char *field,
                       SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *fp = form_paths(v);
  size_t n = strlen(row);
  for (size_t i = 0; i < fp->len; i++) {
    const char *p = fp->items[i];
    const char *slash = strrchr(p, '/');
    if (slash == NULL || slash == p || (size_t)(slash - p) != n ||
        strncmp(p, row, n) != 0) {
      continue;
    }
    if (spec_document_form_field(v->doc, p, field) != NULL) {
      som_strlist_push(out, spec_link_validator_form_value(v, p, field));
    }
  }
}

static int passes(SpecLinkValidator *v, const char *where, const char *row) {
  if (!has_text(where)) return 1;
  SpecPlaceFilter f;
  if (!spec_place_filter_try_parse(where, &f)) return 1;
  int ok = 1;
  if (f.field != NULL) {
    SomStrList values;
    own_values(v, row, f.field, &values);
    ok = spec_place_filter_matches_list(&f, &values);
    som_strlist_free(&values);
  }
  spec_place_filter_free(&f);
  return ok;
}

/* The nearest list item at or above `path` (itself included); NULL when
 * there is none. Owned. */
static char *nearest_item(SpecLinkValidator *v, const char *path) {
  char *p = som_strdup(path);
  for (;;) {
    if (spec_link_validator_is_item(v, p)) return p;
    char *parent = before_last(p, '/');
    free(p);
    if (parent == NULL) return NULL;
    p = parent;
  }
}

/* ---- the document's instances ---------------------------------------------- */

typedef struct {
  char *path;
  const SpecClass *cls;
  const char *root; /* the root's segment (borrowed from the model) */
} LinkInstance;

typedef struct {
  LinkInstance *items;
  size_t len, cap;
} LinkInstances;

static int populated(SpecLinkValidator *v, const char *seg) {
  SomStrList groups[4];
  spec_document_content_paths(v->doc, &groups[0]);
  spec_document_form_paths(v->doc, &groups[1]);
  spec_document_list_paths(v->doc, &groups[2]);
  spec_document_headline_paths(v->doc, &groups[3]);
  int hit = 0;
  for (size_t g = 0; g < 4; g++) {
    for (size_t i = 0; i < groups[g].len && !hit; i++) {
      hit = under_path(groups[g].items[i], seg);
    }
    som_strlist_free(&groups[g]);
  }
  return hit;
}

static const SpecClass *member_class(SpecLinkValidator *v, const SpecField *f) {
  if (f->type == NULL) return NULL;
  SomBuf b;
  som_buf_init(&b);
  for (const char *c = f->type; *c; c++) {
    if (*c != '?') som_buf_putc(&b, *c);
  }
  char *name = som_buf_take(&b);
  const SpecClass *cls = spec_reflection_class_named(&v->refl, name);
  free(name);
  return cls;
}

static void walk(SpecLinkValidator *v, const SpecClass *cls, const char *path,
                 const char *root, LinkInstances *out,
                 const SomStrList *on_path) {
  if (out->len == out->cap) {
    out->cap = out->cap ? out->cap * 2 : 16;
    out->items =
        (LinkInstance *)realloc(out->items, out->cap * sizeof(LinkInstance));
  }
  out->items[out->len].path = som_strdup(path);
  out->items[out->len].cls = cls;
  out->items[out->len].root = root;
  out->len++;
  for (size_t i = 0; i < cls->fields_len; i++) {
    const SpecField *f = &cls->fields[i];
    if (spec_annotations_have(&f->annotations, "Reference")) continue;
    char *member_path =
        scat(path, "/", spec_reflection_field_segment(f), NULL);
    if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0 && f->element_is_complex) {
      const SpecClass *el = spec_reflection_class_named(&v->refl, f->element_type);
      const SomStrList *items =
          el != NULL ? spec_document_list_items(v->doc, member_path) : NULL;
      if (items != NULL) {
        SomStrList fresh;
        som_strlist_init(&fresh);
        /* Copy: walking may not change the list, but stay safe. */
        SomStrList copy;
        som_strlist_copy(&copy, items);
        for (size_t k = 0; k < copy.len; k++) {
          walk(v, el, copy.items[k], root, out, &fresh);
        }
        som_strlist_free(&copy);
        som_strlist_free(&fresh);
      }
    } else if (strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
               strcmp(f->kind, SPEC_FIELD_KIND_SECTION) == 0) {
      const SpecClass *child = member_class(v, f);
      if (child != NULL && !som_strlist_contains(on_path, child->name)) {
        SomStrList next;
        som_strlist_copy(&next, on_path);
        push_unique(&next, cls->name);
        walk(v, child, member_path, root, out, &next);
        som_strlist_free(&next);
      }
    }
    free(member_path);
  }
}

static char *form_path_of(SpecLinkValidator *v, const LinkInstance *i,
                          const SpecField *f) {
  (void)v;
  return scat(i->path, "/", spec_reflection_field_segment(f), NULL);
}

/* ---- @DerivedFrom and derivedFrom: ----------------------------------------- */

typedef struct {
  char *path;
  const char *field; /* NULL for content (borrowed) */
  const SpecDerivation *d;
  SpecDerivation *owned; /* the member derivation read from annotations */
  const char *anchor;    /* borrowed from the instance */
  const char *root;
  const FormFieldSpec *spec;
} LinkScalar;

/* Whether two values agree: as id sets for a multi-valued reference, as
 * numbers for a numeric field, else as text with trailing whitespace
 * ignored. */
static int same_value(const char *a, const char *b, const FormFieldSpec *spec) {
  if (spec != NULL && spec->multiple && spec->refers_to.len > 0) {
    SomStrList x, y;
    spec_link_ids(a, &x);
    spec_link_ids(b, &y);
    SomMap xs, ys;
    som_map_init(&xs);
    som_map_init(&ys);
    for (size_t i = 0; i < x.len; i++) set_add(&xs, x.items[i]);
    for (size_t i = 0; i < y.len; i++) set_add(&ys, y.items[i]);
    int same = xs.len == ys.len;
    for (size_t i = 0; i < xs.len && same; i++) {
      same = set_has(&ys, xs.entries[i].key);
    }
    som_map_free(&xs);
    som_map_free(&ys);
    som_strlist_free(&x);
    som_strlist_free(&y);
    return same;
  }
  if (spec != NULL && spec->type != NULL &&
      (strcmp(spec->type, "int") == 0 || strcmp(spec->type, "double") == 0 ||
       strcmp(spec->type, "num") == 0)) {
    double x, y;
    if (num_try_parse(a, &x) && num_try_parse(b, &y)) return x == y;
  }
  char *na = NULL, *nb = NULL;
  for (int k = 0; k < 2; k++) {
    const char *s = k == 0 ? a : b;
    SomBuf buf;
    som_buf_init(&buf);
    const char *line = s;
    for (;;) {
      const char *nl = strchr(line, '\n');
      size_t n = nl == NULL ? strlen(line) : (size_t)(nl - line);
      while (n > 0 && is_space(line[n - 1])) n--;
      som_buf_putn(&buf, line, n);
      if (nl == NULL) break;
      som_buf_putc(&buf, '\n');
      line = nl + 1;
    }
    char *joined = som_buf_take(&buf);
    char *t = trim_dup(joined);
    free(joined);
    if (k == 0) {
      na = t;
    } else {
      nb = t;
    }
  }
  int same = strcmp(na, nb) == 0;
  free(na);
  free(nb);
  return same;
}

/* The rows a `rows` / `lookup` derivation reads, in document order; 0 when
 * the document's root does not reach the source (undecidable here). */
static int derivation_rows(SpecLinkValidator *v, const SpecDerivation *d,
                           const char *anchor, const char *root,
                           SomStrList *out) {
  som_strlist_init(out);
  SpecPlaceResolution src;
  if (!global(v, d->source, root, anchor, &src)) return 0;
  int key_by = has_text(d->key) && has_text(d->by);
  char *by_value = key_by ? spec_link_validator_place_value(v, d->by, anchor)
                          : som_strdup("");
  SomStrList rows;
  expand(v, src.path, &rows);
  for (size_t i = 0; i < rows.len; i++) {
    const char *row = rows.items[i];
    if (!passes(v, d->where, row)) continue;
    if (key_by) {
      char *k = spec_link_validator_place_value(v, d->key, row);
      int match = strcmp(k, by_value) == 0;
      free(k);
      if (!match) continue;
    }
    som_strlist_push_copy(out, row);
  }
  som_strlist_free(&rows);
  free(by_value);
  spec_place_resolution_free(&src);
  return 1;
}

/* The values of `take` at `row`, the non-empty ones joined with " — ". */
static char *take_line(SpecLinkValidator *v, const SomStrList *take,
                       const char *row) {
  SomBuf b;
  som_buf_init(&b);
  int any = 0;
  for (size_t t = 0; t < take->len; t++) {
    char *val = spec_link_validator_place_value(v, take->items[t], row);
    if (val[0] != '\0') {
      if (any) som_buf_puts(&b, " \xE2\x80\x94 ");
      som_buf_puts(&b, val);
      any = 1;
    }
    free(val);
  }
  return som_buf_take(&b);
}

/* The value a scalar derivation gives into `*out` (owned); 0 when
 * undecidable. */
static int derive(SpecLinkValidator *v, const SpecDerivation *d,
                  const char *anchor, const char *root,
                  const FormFieldSpec *spec, const char *target_path,
                  char **out) {
  *out = NULL;
  if (strcmp(d->kind, "copy") == 0) {
    SpecPlaceResolution src;
    if (!global(v, d->source, root, anchor, &src)) return 0;
    SomStrList paths;
    expand(v, src.path, &paths);
    int ok = paths.len == 1;
    if (ok) *out = spec_link_validator_value(v, &src, paths.items[0]);
    som_strlist_free(&paths);
    spec_place_resolution_free(&src);
    return ok;
  }
  if (strcmp(d->kind, "rows") == 0) {
    SomStrList rows;
    if (!derivation_rows(v, d, anchor, root, &rows)) {
      som_strlist_free(&rows);
      return 0;
    }
    SomBuf b;
    som_buf_init(&b);
    if (spec != NULL && spec->multiple) {
      int any = 0;
      for (size_t r = 0; r < rows.len; r++) {
        for (size_t t = 0; t < d->take.len; t++) {
          char *val =
              spec_link_validator_place_value(v, d->take.items[t], rows.items[r]);
          SomStrList ids;
          spec_link_ids(val, &ids);
          for (size_t k = 0; k < ids.len; k++) {
            if (any) som_buf_puts(&b, ", ");
            som_buf_puts(&b, ids.items[k]);
            any = 1;
          }
          som_strlist_free(&ids);
          free(val);
        }
      }
    } else {
      int any = 0;
      for (size_t r = 0; r < rows.len; r++) {
        char *line = take_line(v, &d->take, rows.items[r]);
        if (line[0] != '\0') {
          if (any) som_buf_putc(&b, '\n');
          som_buf_puts(&b, line);
          any = 1;
        }
        free(line);
      }
    }
    som_strlist_free(&rows);
    *out = som_buf_take(&b);
    return 1;
  }
  if (strcmp(d->kind, "lookup") == 0) {
    SomStrList rows;
    if (!derivation_rows(v, d, anchor, root, &rows)) {
      som_strlist_free(&rows);
      return 0;
    }
    int key_by = has_text(d->key) && has_text(d->by);
    if (key_by && rows.len != 1) {
      char *by = spec_link_validator_place_value(v, d->by, anchor);
      char n[32];
      snprintf(n, sizeof(n), "%zu", rows.len);
      report(v, SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS, target_path,
             scat("the lookup in ", d->source, " by ", d->key, " = \"", by,
                  "\" finds ", n, " rows, not one", NULL));
      free(by);
      som_strlist_free(&rows);
      return 0;
    }
    if (rows.len == 0) {
      som_strlist_free(&rows);
      *out = som_strdup("");
      return 1;
    }
    *out = take_line(v, &d->take, rows.items[rows.len - 1]);
    som_strlist_free(&rows);
    return 1;
  }
  return 0;
}

/* The tuple of `d.map` places at `at_path`: target place -> value, reading
 * the row place (`row_side`) or the target place. */
static void map_tuple(SpecLinkValidator *v, const SpecDerivation *d,
                      const char *at_path, int row_side, SpecStringPairs *out) {
  spec_string_pairs_init(out);
  for (size_t k = 0; k < d->map.len; k++) {
    const char *place = row_side ? d->map.items[k].value : d->map.items[k].key;
    char *val = spec_link_validator_place_value(v, place, at_path);
    spec_string_pairs_put(out, d->map.items[k].key, val);
    free(val);
  }
}

/* A tuple's key: its values in map order, joined with " | ". */
static char *tuple_key(const SpecDerivation *d, const SpecStringPairs *t) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t k = 0; k < d->map.len; k++) {
    if (k > 0) som_buf_puts(&b, " | ");
    const char *val = spec_string_pairs_get(t, d->map.items[k].key);
    som_buf_puts(&b, val != NULL ? val : "null");
  }
  return som_buf_take(&b);
}

/* Checks a `@DerivedFrom.rows` with `map` on a list: one element per row. */
static void check_derived_list(SpecLinkValidator *v, const LinkInstance *i,
                               const char *list_path,
                               const SpecDerivation *d) {
  if (strcmp(d->kind, "rows") != 0 || d->map.len == 0) return;
  const SomStrList *elements_ref = spec_document_list_items(v->doc, list_path);
  SomStrList elements;
  if (elements_ref != NULL) {
    som_strlist_copy(&elements, elements_ref);
  } else {
    som_strlist_init(&elements);
  }
  SomStrList rows;
  if (!derivation_rows(v, d, i->path, i->root, &rows)) {
    som_strlist_free(&rows);
    som_strlist_free(&elements);
    return; /* the source is not in this document */
  }
  SpecStringPairs *wanted = (SpecStringPairs *)calloc(
      rows.len ? rows.len : 1, sizeof(SpecStringPairs));
  SomStrList want_keys, have_keys;
  som_strlist_init(&want_keys);
  som_strlist_init(&have_keys);
  for (size_t r = 0; r < rows.len; r++) {
    map_tuple(v, d, rows.items[r], 1, &wanted[r]);
    som_strlist_push(&want_keys, tuple_key(d, &wanted[r]));
  }
  for (size_t e = 0; e < elements.len; e++) {
    SpecStringPairs t;
    map_tuple(v, d, elements.items[e], 0, &t);
    som_strlist_push(&have_keys, tuple_key(d, &t));
    spec_string_pairs_free(&t);
  }
  sort_list(&want_keys);
  sort_list(&have_keys);
  int differ = !lists_equal(&want_keys, &have_keys);
  if (differ) {
    SpecLinkFix *fix = fix_push(v, 2, SPEC_LINK_FIX_LIST, list_path);
    fix->tuples = wanted;
    fix->tuples_len = rows.len;
    wanted = NULL;
    for (size_t k = 0; k < d->map.len; k++) {
      push_unique(&fix->tuple_keys, d->map.items[k].key);
    }
  }
  if (wanted != NULL) {
    for (size_t r = 0; r < rows.len; r++) spec_string_pairs_free(&wanted[r]);
    free(wanted);
  }
  if (elements.len > 0 && differ) {
    /* The want / have lists are the tuple keys (the same values, in map
     * order, joined with " | "). */
    char *want = som_strlist_join(&want_keys, "; ");
    char *have = som_strlist_join(&have_keys, "; ");
    report(v, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH, list_path,
           scat("the list is derived (rows of ", d->source, ") as [", want,
                "], but holds [", have, "]", NULL));
    free(want);
    free(have);
  }
  som_strlist_free(&want_keys);
  som_strlist_free(&have_keys);
  som_strlist_free(&rows);
  som_strlist_free(&elements);
}

static void check_derivations(SpecLinkValidator *v, const LinkInstances *inst) {
  LinkScalar *scalar = NULL;
  size_t n = 0, cap = 0;
  for (size_t ii = 0; ii < inst->len; ii++) {
    const LinkInstance *i = &inst->items[ii];
    for (size_t fi = 0; fi < i->cls->fields_len; fi++) {
      const SpecField *f = &i->cls->fields[fi];
      char *member_path = form_path_of(v, i, f);
      SpecDerivation d;
      if (spec_annotations_derived_from(&f->annotations, &d)) {
        if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0) {
          check_derived_list(v, i, member_path, &d);
          spec_derivation_free(&d);
        } else if (strcmp(f->kind, SPEC_FIELD_KIND_CONTENT) == 0) {
          if (n == cap) {
            cap = cap ? cap * 2 : 8;
            scalar = (LinkScalar *)realloc(scalar, cap * sizeof(LinkScalar));
          }
          LinkScalar *s = &scalar[n++];
          s->path = som_strdup(member_path);
          s->field = NULL;
          s->owned = (SpecDerivation *)malloc(sizeof(SpecDerivation));
          *s->owned = d;
          s->d = s->owned;
          s->anchor = i->path;
          s->root = i->root;
          s->spec = NULL;
        } else {
          spec_derivation_free(&d);
        }
      }
      for (size_t k = 0; k < f->form_fields_len; k++) {
        const FormFieldSpec *ff = &f->form_fields[k];
        if (ff->derived_from == NULL) continue;
        if (n == cap) {
          cap = cap ? cap * 2 : 8;
          scalar = (LinkScalar *)realloc(scalar, cap * sizeof(LinkScalar));
        }
        LinkScalar *s = &scalar[n++];
        s->path = som_strdup(member_path);
        s->field = ff->name;
        s->owned = NULL;
        s->d = ff->derived_from;
        s->anchor = i->path;
        s->root = i->root;
        s->spec = ff;
      }
      free(member_path);
    }
  }
  /* Dependency order: every derivation is recomputed from the values the
   * ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
   * rounds by the number of derivations. */
  char **expected = (char **)calloc(n ? n : 1, sizeof(char *));
  int *expected_ok = (int *)calloc(n ? n : 1, sizeof(int));
  for (size_t round = 0; round <= n; round++) {
    int moved = 0;
    for (size_t k = 0; k < n; k++) {
      LinkScalar *t = &scalar[k];
      char *value = NULL;
      int ok = derive(v, t->d, t->anchor, t->root, t->spec, t->path, &value);
      if (expected_ok[k] != ok || !str_eq(expected[k], value)) {
        free(expected[k]);
        expected[k] = value != NULL ? som_strdup(value) : NULL;
        expected_ok[k] = ok;
        moved = 1;
        if (ok) {
          char *key = derived_key(t->path, t->field);
          som_map_set(&v->cache->derived, key, value);
          free(key);
        }
      }
      free(value);
    }
    if (!moved) break;
  }
  som_map_clear(&v->cache->derived);
  for (size_t k = 0; k < n; k++) {
    LinkScalar *t = &scalar[k];
    if (expected_ok[k]) {
      const char *want = expected[k] != NULL ? expected[k] : "";
      char *have = t->field == NULL
                       ? spec_link_validator_content_value(v, t->path)
                       : spec_link_validator_form_value(v, t->path, t->field);
      int same = same_value(have, want, t->spec);
      if (!same) fix_set(v, 2, t->path, t->field, want);
      /* An empty value is not derived yet: deriveFields writes it. */
      if (have[0] != '\0' && !same) {
        char *what = t->field == NULL
                         ? som_strdup("the content")
                         : scat("form field \"", t->field, "\"", NULL);
        report(v, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH, t->path,
               scat(what, " is derived (", t->d->kind, " of ", t->d->source,
                    ") as \"", want, "\", but holds \"", have, "\"", NULL));
        free(what);
      }
      free(have);
    }
  }
  for (size_t k = 0; k < n; k++) {
    free(expected[k]);
    free(scalar[k].path);
    if (scalar[k].owned != NULL) {
      spec_derivation_free(scalar[k].owned);
      free(scalar[k].owned);
    }
  }
  free(expected);
  free(expected_ok);
  free(scalar);
}

/* ---- @SummaryOf and summaryOf: ---------------------------------------------- */

typedef struct {
  SomStrList items; /* item paths, in document order */
  SomStrList ids;   /* their ids, index for index */
} LinkDetail;

static void detail_free(LinkDetail *d) {
  som_strlist_free(&d->items);
  som_strlist_free(&d->ids);
}

/* The detail elements of a summary; 0 when the detail list does not
 * resolve. */
static int detail_elements(SpecLinkValidator *v, const SpecSummaryOf *s,
                           const char *root, LinkDetail *out) {
  som_strlist_init(&out->items);
  som_strlist_init(&out->ids);
  SpecPlaceResolution r;
  if (!global(v, s->detail, root, root, &r)) return 0;
  if (strcmp(r.kind, SPEC_PLACE_KIND_LIST) != 0) {
    spec_place_resolution_free(&r);
    return 0;
  }
  SomStrList lists;
  expand(v, r.path, &lists);
  for (size_t l = 0; l < lists.len; l++) {
    const SomStrList *items = spec_document_list_items(v->doc, lists.items[l]);
    if (items == NULL) continue;
    for (size_t k = 0; k < items->len; k++) {
      if (som_strlist_contains(&out->items, items->items[k])) continue;
      som_strlist_push_copy(&out->items, items->items[k]);
      som_strlist_push(&out->ids,
                       spec_link_validator_item_id(v, items->items[k]));
    }
  }
  som_strlist_free(&lists);
  spec_place_resolution_free(&r);
  return 1;
}

/* Checks that the values a summary row repeats agree with its detail
 * element's. */
static void check_repeats(SpecLinkValidator *v, const SpecSummaryOf *s,
                          const char *row, const char *detail) {
  for (size_t k = 0; k < s->repeats.len; k++) {
    const char *mine_at = s->repeats.items[k].key;
    const char *theirs_at = s->repeats.items[k].value;
    SpecPlaceResolution mine, theirs;
    int have_mine = at(v, mine_at, row, &mine);
    int have_theirs = at(v, theirs_at, detail, &theirs);
    if (have_mine && have_theirs) {
      SomStrList mp, tp;
      expand(v, mine.path, &mp);
      expand(v, theirs.path, &tp);
      if (mp.len == 1 && tp.len == 1) {
        char *have = spec_link_validator_value(v, &mine, mp.items[0]);
        char *want = spec_link_validator_value(v, &theirs, tp.items[0]);
        int differ = strcmp(have, want) != 0;
        if (differ) {
          fix_set(v, 2, mp.items[0], spec_link_field_of(&mine), want);
        }
        /* Not repeated yet: deriveFields writes it. */
        if (have[0] != '\0' && differ) {
          report(v, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH, mp.items[0],
                 scat(mine_at, " repeats ", theirs_at, " of ", detail, " as \"",
                      have, "\", but the detail element holds \"", want, "\"",
                      NULL));
        }
        free(have);
        free(want);
      }
      som_strlist_free(&mp);
      som_strlist_free(&tp);
    }
    if (have_mine) spec_place_resolution_free(&mine);
    if (have_theirs) spec_place_resolution_free(&theirs);
  }
}

static void check_summary(SpecLinkValidator *v, const LinkInstance *i,
                          const SpecField *f) {
  if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) != 0) return;
  SpecSummaryOf s;
  if (!spec_annotations_summary_of(&f->annotations, &s)) return;
  LinkDetail detail;
  if (has_text(s.document) || !detail_elements(v, &s, i->root, &detail)) {
    if (!has_text(s.document)) detail_free(&detail);
    spec_summary_of_free(&s);
    return;
  }
  SomMap by_id; /* id -> item (the last one of an id) */
  som_map_init(&by_id);
  for (size_t k = 0; k < detail.items.len; k++) {
    som_map_set(&by_id, detail.ids.items[k], detail.items.items[k]);
  }
  SomMap named; /* id -> the row naming it first */
  som_map_init(&named);
  char *list_path = form_path_of(v, i, f);
  const SomStrList *els_ref = spec_document_list_items(v->doc, list_path);
  SomStrList els;
  if (els_ref != NULL) {
    som_strlist_copy(&els, els_ref);
  } else {
    som_strlist_init(&els);
  }
  for (size_t e = 0; e < els.len; e++) {
    const char *el = els.items[e];
    SomStrList ids;
    if (s.match == NULL) {
      som_strlist_init(&ids);
      som_strlist_push(&ids, spec_link_validator_item_id(v, el));
    } else {
      char *val = spec_link_validator_place_value(v, s.match, el);
      spec_link_ids(val, &ids);
      free(val);
    }
    for (size_t k = 0; k < ids.len; k++) {
      const char *id = ids.items[k];
      const char *target = som_map_get(&by_id, id);
      if (target == NULL) {
        report(v, SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL, el,
               scat("the summary row names ", id, ", which is no element of ",
                    s.detail, NULL));
        continue;
      }
      const char *first = som_map_get(&named, id);
      if (first != NULL) {
        report(v, SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE, el,
               scat("the summary row names ", id, ", which ", first,
                    " names already", NULL));
        continue;
      }
      som_map_set(&named, id, el);
      char *target_copy = som_strdup(target);
      check_repeats(v, &s, el, target_copy);
      free(target_copy);
    }
    som_strlist_free(&ids);
  }
  if (strcmp(s.relation, "equal") == 0) {
    for (size_t k = 0; k < detail.items.len; k++) {
      if (som_map_get(&named, detail.ids.items[k]) == NULL) {
        report(v, SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
               detail.items.items[k],
               scat("the detail element ", detail.ids.items[k],
                    " is named by no row of the summary ", list_path,
                    " (relation: equal)", NULL));
      }
    }
  }
  som_strlist_free(&els);
  free(list_path);
  som_map_free(&named);
  som_map_free(&by_id);
  detail_free(&detail);
  spec_summary_of_free(&s);
}

static void check_field_summary(SpecLinkValidator *v, const LinkInstance *i,
                                const char *form, const FormFieldSpec *ff) {
  const SpecSummaryOf *s = ff->summary_of;
  if (s == NULL || has_text(s->document)) return;
  if (spec_document_form_field(v->doc, form, ff->name) == NULL) return;
  LinkDetail detail;
  if (!detail_elements(v, s, i->root, &detail)) {
    detail_free(&detail);
    return;
  }
  SomMap seen;
  som_map_init(&seen);
  char *value = spec_link_validator_form_value(v, form, ff->name);
  SomStrList ids;
  spec_link_ids(value, &ids);
  free(value);
  for (size_t k = 0; k < ids.len; k++) {
    const char *id = ids.items[k];
    if (!som_strlist_contains(&detail.ids, id)) {
      report(v, SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL, form,
             scat("form field \"", ff->name, "\" names ", id,
                  ", which is no element of ", s->detail, NULL));
    } else if (set_has(&seen, id)) {
      report(v, SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE, form,
             scat("form field \"", ff->name, "\" names ", id, " twice", NULL));
    } else {
      set_add(&seen, id);
    }
  }
  if (strcmp(s->relation, "equal") == 0) {
    for (size_t k = 0; k < detail.items.len; k++) {
      if (!set_has(&seen, detail.ids.items[k])) {
        report(v, SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
               detail.items.items[k],
               scat("the detail element ", detail.ids.items[k],
                    " is not named in \"", ff->name, "\" of ", form,
                    " (relation: equal)", NULL));
      }
    }
  }
  som_strlist_free(&ids);
  som_map_free(&seen);
  detail_free(&detail);
}

/* ---- inverseOf: ------------------------------------------------------------- */

/* How the registry key `target` (`<X>.@sectionId` or `<X>.<field>`) names the
 * entry at `item` into `*out` (owned); 0 when it does not. */
static int identity(SpecLinkValidator *v, const char *item, const char *target,
                    char **out) {
  const char *dot = strchr(target, '.');
  const char *name = dot != NULL ? dot + 1 : target;
  if (strcmp(name, SPEC_SECTION_ID_SLOT) == 0) {
    *out = spec_link_validator_item_id(v, item);
    return 1;
  }
  SomStrList values;
  own_values(v, item, name, &values);
  if (values.len == 0) {
    som_strlist_free(&values);
    *out = NULL;
    return 0;
  }
  *out = som_strdup(values.items[0]);
  som_strlist_free(&values);
  return 1;
}

/* The section id part of a registry key (before the first dot). Owned. */
static char *registry_id(const char *target) {
  const char *dot = strchr(target, '.');
  return dot == NULL ? som_strdup(target)
                     : som_strdup_n(target, (size_t)(dot - target));
}

/* The entries a reference field names, by its `refersTo` registries: id ->
 * item path. Borrowed from the cache. */
static const SomMap *entries_of(SpecLinkValidator *v, const SomStrList *refers_to) {
  char *key = som_strlist_join(refers_to, ",");
  SpecLinkValidatorCache *c = v->cache;
  for (size_t i = 0; i < c->entries_keys.len; i++) {
    if (strcmp(c->entries_keys.items[i], key) == 0) {
      free(key);
      return &c->entries[i];
    }
  }
  SomMap out;
  som_map_init(&out);
  SomStrList lists;
  spec_document_list_paths(v->doc, &lists);
  sort_list(&lists);
  for (size_t l = 0; l < lists.len; l++) {
    const SomStrList *items = spec_document_list_items(v->doc, lists.items[l]);
    if (items == NULL) continue;
    for (size_t k = 0; k < items->len; k++) {
      const char *item = items->items[k];
      SpecResolution r;
      if (!spec_reflection_resolve(&v->refl, item, &r)) continue;
      const SpecClass *cls = r.target_class;
      spec_resolution_free(&r);
      if (cls == NULL) continue;
      const char *id = cls->section_id != NULL ? cls->section_id : "";
      for (size_t t = 0; t < refers_to->len; t++) {
        char *rid = registry_id(refers_to->items[t]);
        int match = strcmp(rid, id) == 0;
        free(rid);
        if (!match) continue;
        char *name = NULL;
        if (!identity(v, item, refers_to->items[t], &name) || name[0] == '\0') {
          free(name);
          continue;
        }
        if (som_map_get(&out, name) == NULL) som_map_set(&out, name, item);
        free(name);
      }
    }
  }
  som_strlist_free(&lists);
  som_strlist_push(&c->entries_keys, key);
  c->entries = (SomMap *)realloc(c->entries, c->entries_keys.len * sizeof(SomMap));
  c->entries[c->entries_keys.len - 1] = out;
  return &c->entries[c->entries_keys.len - 1];
}

/* The nearest item at or above `path` whose class is one of `classes` (the
 * registry ids of `refers_to`). Owned; NULL when none. */
static char *owner_of(SpecLinkValidator *v, const char *path,
                      const SomStrList *refers_to) {
  SomStrList classes;
  som_strlist_init(&classes);
  for (size_t t = 0; t < refers_to->len; t++) {
    char *rid = registry_id(refers_to->items[t]);
    push_unique(&classes, rid);
    free(rid);
  }
  char *p = nearest_item(v, path);
  while (p != NULL) {
    SpecResolution r;
    int hit = 0;
    if (spec_reflection_resolve(&v->refl, p, &r)) {
      hit = r.target_class != NULL && r.target_class->section_id != NULL &&
            som_strlist_contains(&classes, r.target_class->section_id);
      spec_resolution_free(&r);
    }
    if (hit) break;
    char *parent = before_last(p, '/');
    free(p);
    p = parent == NULL ? NULL : nearest_item(v, parent);
    free(parent);
  }
  som_strlist_free(&classes);
  return p;
}

static int first_identity(SpecLinkValidator *v, const char *owner,
                          const SomStrList *refers_to, char **out) {
  for (size_t t = 0; t < refers_to->len; t++) {
    if (identity(v, owner, refers_to->items[t], out)) return 1;
  }
  *out = NULL;
  return 0;
}

/* The forms directly beneath `row` (`<row>/<member>`). */
static void own_forms(SpecLinkValidator *v, const char *row, SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *fp = form_paths(v);
  size_t n = strlen(row);
  for (size_t i = 0; i < fp->len; i++) {
    const char *p = fp->items[i];
    if (strncmp(p, row, n) == 0 && p[n] == '/' && strchr(p + n + 1, '/') == NULL) {
      som_strlist_push_copy(out, p);
    }
  }
}

/* The same place beneath another entry: a `-<n>` list item generalised to
 * `-*`. Owned. */
static char *generalise(const char *s) {
  const char *dash = strrchr(s, '-');
  if (dash != NULL && dash > s) {
    char *num = trim_dup(dash + 1);
    int is_int = is_int_text(num);
    free(num);
    if (is_int) {
      char *head = som_strdup_n(s, (size_t)(dash - s));
      char *out = scat(head, "-*", NULL);
      free(head);
      return out;
    }
  }
  return som_strdup(s);
}

static void check_symmetric(SpecLinkValidator *v, const char *form,
                            const FormFieldSpec *ff, const SpecInverseOf *inv,
                            const char *value, const SomMap *entries) {
  char *row = nearest_item(v, form);
  if (row == NULL) return;
  if (!passes(v, inv->where, row)) {
    free(row);
    return;
  }
  char *row_parent = before_last(row, '/');
  char *a = row_parent != NULL ? owner_of(v, row_parent, &ff->refers_to) : NULL;
  free(row_parent);
  char *a_id = NULL;
  if (a == NULL || !first_identity(v, a, &ff->refers_to, &a_id)) {
    free(a);
    free(row);
    return;
  }
  char *filter_field = NULL;
  if (has_text(inv->where)) {
    SpecPlaceFilter filt;
    if (spec_place_filter_try_parse(inv->where, &filt)) {
      if (filt.field != NULL) filter_field = som_strdup(filt.field);
      spec_place_filter_free(&filt);
    }
  }
  SomStrList where_values;
  som_strlist_init(&where_values);
  if (filter_field != NULL) {
    SomStrList own;
    own_values(v, row, filter_field, &own);
    for (size_t k = 0; k < own.len; k++) push_unique(&where_values, own.items[k]);
    som_strlist_free(&own);
  }
  /* The same place beneath the named entry, every row of it. */
  SomBuf rb;
  som_buf_init(&rb);
  {
    const char *rest = form + strlen(a);
    const char *s = rest;
    int first = 1;
    for (;;) {
      const char *slash = strchr(s, '/');
      size_t n = slash == NULL ? strlen(s) : (size_t)(slash - s);
      char *seg = som_strdup_n(s, n);
      char *g = generalise(seg);
      if (!first) som_buf_putc(&rb, '/');
      som_buf_puts(&rb, g);
      first = 0;
      free(g);
      free(seg);
      if (slash == NULL) break;
      s = slash + 1;
    }
  }
  char *rel = som_buf_take(&rb);
  SomStrList ids;
  spec_link_ids(value, &ids);
  for (size_t bi = 0; bi < ids.len; bi++) {
    const char *b = ids.items[bi];
    const char *b_path = som_map_get(entries, b);
    if (b_path == NULL || strcmp(b_path, a) == 0) continue;
    char *pattern = scat(b_path, rel, NULL);
    SomStrList candidates;
    expand(v, pattern, &candidates);
    free(pattern);
    int counterpart = 0;
    for (size_t k = 0; k < candidates.len && !counterpart; k++) {
      const char *p = candidates.items[k];
      char *r = nearest_item(v, p);
      if (r == NULL) continue;
      int ok = passes(v, inv->where, r);
      if (ok && filter_field != NULL) {
        SomStrList own;
        own_values(v, r, filter_field, &own);
        for (size_t x = 0; x < where_values.len && ok; x++) {
          ok = som_strlist_contains(&own, where_values.items[x]);
        }
        som_strlist_free(&own);
      }
      if (ok) {
        char *val = spec_link_validator_form_value(v, p, ff->name);
        counterpart = ids_contain(val, a_id);
        free(val);
      }
      free(r);
    }
    som_strlist_free(&candidates);
    if (counterpart) continue;
    const char *star = strstr(rel, "-*");
    if (star != NULL && star > rel) {
      size_t at_star = (size_t)(star - rel);
      char *head = som_strdup_n(rel, at_star);
      char *lst = scat(b_path, head, NULL);
      free(head);
      const char *below = at_star + 3 <= strlen(rel) ? rel + at_star + 3 : "";
      SpecLinkFix *fix = fix_push(v, 1, SPEC_LINK_FIX_ADD_ROW, lst);
      free(lst);
      char *k1 = scat(below, "#", ff->name, NULL);
      spec_string_pairs_put(&fix->values, k1, a_id);
      free(k1);
      if (filter_field != NULL) {
        SomStrList forms;
        own_forms(v, row, &forms);
        for (size_t k = 0; k < forms.len; k++) {
          const char *p = forms.items[k];
          if (spec_document_form_field(v->doc, p, filter_field) == NULL) continue;
          char *fk = scat(p + strlen(row) + 1, "#", filter_field, NULL);
          char *fv = spec_link_validator_form_value(v, p, filter_field);
          /* `fix` may move while the value is read (a report pushes no fix,
           * but stay safe): look it up again. */
          SpecLinkFix *last = &v->fixes.items[v->fixes.len - 1];
          spec_string_pairs_put(&last->values, fk, fv);
          free(fk);
          free(fv);
        }
        som_strlist_free(&forms);
      }
    }
    char *suffix =
        has_text(inv->where) ? scat(" (", inv->where, ")", NULL) : som_strdup("");
    report(v, SPEC_VALIDATION_CODE_INVERSE_MISSING, form,
           scat("the row names ", b, ", but ", b, " holds no row naming ", a_id,
                " back", suffix, NULL));
    free(suffix);
  }
  som_strlist_free(&ids);
  free(rel);
  som_strlist_free(&where_values);
  free(filter_field);
  free(a_id);
  free(a);
  free(row);
}

static void check_inverse(SpecLinkValidator *v, const char *form,
                          const FormFieldSpec *ff) {
  if (spec_document_form_field(v->doc, form, ff->name) == NULL) return;
  char *value = spec_link_validator_form_value(v, form, ff->name);
  if (value[0] == '\0') {
    free(value);
    return;
  }
  const SpecInverseOf *inv = ff->inverse_of;
  const SomMap *entries = entries_of(v, &ff->refers_to);
  if (spec_inverse_of_symmetric(inv)) {
    check_symmetric(v, form, ff, inv, value, entries);
    free(value);
    return;
  }
  SomStrList ids;
  spec_link_ids(value, &ids);
  free(value);
  int stop = 0;
  for (size_t bi = 0; bi < ids.len && !stop; bi++) {
    const char *b = ids.items[bi];
    const char *b_lookup = som_map_get(entries, b);
    if (b_lookup == NULL) continue; /* a registry this document does not hold */
    char *b_path = som_strdup(b_lookup);
    int resolved = 0, names_back = 0, has_a_id = 0, has_writable = 0;
    char *a_id = som_strdup("");
    char *writable_path = NULL;
    const char *writable_field = NULL;
    for (size_t e = 0; e < inv->fields.len; e++) {
      SpecPlaceResolution r;
      if (!at(v, inv->fields.items[e], b_path, &r)) continue;
      if (r.form_field == NULL) {
        spec_place_resolution_free(&r);
        continue;
      }
      char *owner = owner_of(v, form, &r.form_field->refers_to);
      if (owner == NULL) {
        spec_place_resolution_free(&r);
        continue;
      }
      if (has_text(inv->where) && !passes(v, inv->where, owner)) {
        free(owner);
        spec_place_resolution_free(&r);
        stop = 1;
        break;
      }
      free(a_id);
      has_a_id = first_identity(v, owner, &r.form_field->refers_to, &a_id);
      if (a_id == NULL) a_id = som_strdup("");
      free(owner);
      if (!has_a_id) {
        spec_place_resolution_free(&r);
        continue;
      }
      resolved = 1;
      SomStrList ends;
      expand(v, r.path, &ends);
      if (ends.len > 0 && !has_writable) {
        writable_path = som_strdup(ends.items[0]);
        writable_field = spec_place_resolution_field(&r);
        has_writable = 1;
      }
      for (size_t k = 0; k < ends.len; k++) {
        char *val =
            spec_link_validator_form_value(v, ends.items[k], spec_place_resolution_field(&r));
        if (ids_contain(val, a_id)) names_back = 1;
        free(val);
      }
      som_strlist_free(&ends);
      spec_place_resolution_free(&r);
    }
    if (!stop) {
      if (resolved && !names_back && has_writable && has_a_id) {
        SpecLinkFix *fix =
            fix_push(v, 1, SPEC_LINK_FIX_APPEND, writable_path);
        fix->field = som_strdup(writable_field);
        fix->value = som_strdup(a_id);
      }
      if (resolved && !names_back) {
        char *ends = som_strlist_join(&inv->fields, ", ");
        report(v, SPEC_VALIDATION_CODE_INVERSE_MISSING, form,
               scat("form field \"", ff->name, "\" names ", b, ", but ", b,
                    " does not name ", a_id, " back (", ends, ")", NULL));
        free(ends);
      }
    }
    free(writable_path);
    free(a_id);
    free(b_path);
  }
  som_strlist_free(&ids);
}

/* ---- @ExtractsLinks and the link rows -------------------------------------- */

static int is_alnum(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9');
}

/* The ids of `registry` named in `text`, each matched exactly (not as a part
 * of a longer id), in order of first appearance. An id as text names it:
 * letters, digits and inner hyphens. */
static void ids_in(const char *text, const SomMap *registry, SomStrList *out) {
  som_strlist_init(out);
  const char *s = text;
  while (*s) {
    if (!is_alnum(*s)) {
      s++;
      continue;
    }
    const char *start = s;
    while (is_alnum(*s) || *s == '-') s++;
    const char *end = s;
    while (end > start && end[-1] == '-') end--;
    char *id = som_strdup_n(start, (size_t)(end - start));
    if (set_has(registry, id)) push_unique(out, id);
    free(id);
    s = end;
  }
}

static void registry_of(SpecLinkValidator *v, const SomStrList *refers_to,
                        SomMap *out) {
  som_map_init(out);
  const SomMap *entries = entries_of(v, refers_to);
  for (size_t i = 0; i < entries->len; i++) set_add(out, entries->entries[i].key);
}

static const FormFieldSpec *ref_spec_from_model(SpecLinkValidator *v,
                                                const SpecField *lst,
                                                const char *ref) {
  const SpecClass *el = spec_reflection_class_named(&v->refl, lst->element_type);
  if (el == NULL) return NULL;
  const char *dot = strchr(ref, '.');
  if (dot == NULL) return NULL;
  size_t id_len = (size_t)(dot - ref);
  const char *name = dot + 1;
  for (size_t i = 0; i < el->fields_len; i++) {
    const SpecField *f = &el->fields[i];
    const char *fid = strcmp(f->name, "content") == 0 ? el->section_id
                                                      : f->section_id;
    if (fid == NULL || strlen(fid) != id_len || strncmp(fid, ref, id_len) != 0) {
      continue;
    }
    for (size_t k = 0; k < f->form_fields_len; k++) {
      if (strcmp(f->form_fields[k].name, name) == 0) return &f->form_fields[k];
    }
  }
  return NULL;
}

/* The text places of an `@ExtractsLinks` scoped as `./`. Owned. */
static char *scoped_place(const char *place) {
  return starts_with(place, "./") ? som_strdup(place) : scat("./", place, NULL);
}

static void check_extracts(SpecLinkValidator *v, const LinkInstance *i,
                           const SpecField *f) {
  if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) != 0) return;
  SpecExtractsLinksList all;
  spec_annotations_extracts_links(&f->annotations, &all);
  if (all.len == 0) return;
  char *list_path = form_path_of(v, i, f);
  const SomStrList *rows_ref = spec_document_list_items(v->doc, list_path);
  SomStrList rows;
  if (rows_ref != NULL) {
    som_strlist_copy(&rows, rows_ref);
  } else {
    som_strlist_init(&rows);
  }
  char *element = nearest_item(v, i->path);
  char *own = element != NULL ? spec_link_validator_item_id(v, element) : NULL;
  free(element);

  /* A link row holding no value at all (what accepting the marked removal of
   * a row leaves) is removed. */
  for (size_t r = 0; r < rows.len; r++) {
    if (!spec_link_validator_holds_value(v, rows.items[r])) {
      SpecLinkFix *fix = fix_push(v, 1, SPEC_LINK_FIX_REMOVE_ROW, rows.items[r]);
      fix->empty = 1;
    }
  }

  /* The ids each row names, and its type (the values `set` writes). */
  SomStrList set_keys;
  som_strlist_init(&set_keys);
  for (size_t e = 0; e < all.len; e++) {
    for (size_t k = 0; k < all.items[e].set.len; k++) {
      push_unique(&set_keys, all.items[e].set.items[k].key);
    }
  }
  sort_list(&set_keys);
  SomStrList *named = (SomStrList *)calloc(rows.len ? rows.len : 1,
                                           sizeof(SomStrList));
  SomMap seen; /* id // type -> first row */
  som_map_init(&seen);
  SomMap rowed;
  som_map_init(&rowed);
  for (size_t r = 0; r < rows.len; r++) {
    const char *row = rows.items[r];
    som_strlist_init(&named[r]);
    for (size_t e = 0; e < all.len; e++) {
      SpecPlaceResolution ref;
      if (!at(v, all.items[e].ref, row, &ref)) continue;
      SomStrList paths;
      expand(v, ref.path, &paths);
      for (size_t p = 0; p < paths.len; p++) {
        char *val = spec_link_validator_value(v, &ref, paths.items[p]);
        SomStrList ids;
        spec_link_ids(val, &ids);
        for (size_t k = 0; k < ids.len; k++) push_unique(&named[r], ids.items[k]);
        som_strlist_free(&ids);
        free(val);
      }
      som_strlist_free(&paths);
      spec_place_resolution_free(&ref);
    }
    SomBuf tb;
    som_buf_init(&tb);
    for (size_t k = 0; k < set_keys.len; k++) {
      if (k > 0) som_buf_puts(&tb, " | ");
      char *val = spec_link_validator_place_value(v, set_keys.items[k], row);
      som_buf_puts(&tb, val);
      free(val);
    }
    char *type = som_buf_take(&tb);
    for (size_t k = 0; k < named[r].len; k++) {
      const char *id = named[r].items[k];
      set_add(&rowed, id);
      char *key = scat(id, " // ", type, NULL);
      const char *first = som_map_get(&seen, key);
      if (first != NULL) {
        report(v, SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW, row,
               scat("the row names ", id, " with the type \"", type, "\", as ",
                    first, " does", NULL));
      } else {
        som_map_set(&seen, key, row);
      }
      free(key);
    }
    free(type);
  }

  char *item0 = scat(list_path, "-0", NULL);
  for (size_t e = 0; e < all.len; e++) {
    const SpecExtractsLinks *x = &all.items[e];
    const FormFieldSpec *ref_spec = NULL;
    if (rows.len == 0) {
      ref_spec = ref_spec_from_model(v, f, x->ref);
    } else {
      SpecPlaceResolution r;
      if (at(v, x->ref, rows.items[0], &r)) {
        ref_spec = r.form_field;
        spec_place_resolution_free(&r);
      }
    }
    if (ref_spec == NULL) continue;
    SomMap registry;
    registry_of(v, &ref_spec->refers_to, &registry);
    SomStrList found;
    som_strlist_init(&found);
    for (size_t pl = 0; pl < x->from.len; pl++) {
      char *p = scoped_place(x->from.items[pl]);
      SpecPlaceResolution r;
      if (at(v, p, i->path, &r)) {
        SomStrList paths;
        expand(v, r.path, &paths);
        for (size_t k = 0; k < paths.len; k++) {
          char *val = spec_link_validator_value(v, &r, paths.items[k]);
          SomStrList ids;
          ids_in(val, &registry, &ids);
          for (size_t m = 0; m < ids.len; m++) {
            if (own != NULL && strcmp(ids.items[m], own) == 0) continue;
            push_unique(&found, ids.items[m]);
          }
          som_strlist_free(&ids);
          free(val);
        }
        som_strlist_free(&paths);
        spec_place_resolution_free(&r);
      }
      free(p);
    }
    for (size_t k = 0; k < found.len; k++) {
      const char *id = found.items[k];
      if (set_has(&rowed, id)) continue;
      if (strcmp(x->mode, "generate") == 0) {
        SpecLinkFix *fix = fix_push(v, 1, SPEC_LINK_FIX_ADD_ROW, list_path);
        size_t fix_index = v->fixes.len - 1;
        (void)fix;
        size_t writes = x->set.len + 1;
        for (size_t w = 0; w < writes; w++) {
          const char *wkey = w == 0 ? x->ref : x->set.items[w - 1].key;
          const char *wvalue = w == 0 ? id : x->set.items[w - 1].value;
          SpecPlaceResolution r;
          if (!at(v, wkey, item0, &r)) continue;
          if (r.form_field != NULL && strlen(r.path) > strlen(item0)) {
            char *k2 = scat(r.path + strlen(item0) + 1, "#",
                            spec_place_resolution_field(&r), NULL);
            spec_string_pairs_put(&v->fixes.items[fix_index].values, k2, wvalue);
            free(k2);
          }
          spec_place_resolution_free(&r);
        }
      }
      char *from = som_strlist_join(&x->from, " / ");
      report(v, SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING, list_path,
             scat(id, " is named in ", from, " but has no row",
                  strcmp(x->mode, "warn") == 0 ? " (warn: the agent adds it)"
                                               : "",
                  NULL));
      free(from);
    }
    som_strlist_free(&found);
    som_map_free(&registry);
  }
  free(item0);

  /* A generated row: every `set` value of a generate-mode use matches. */
  for (size_t e = 0; e < all.len; e++) {
    const SpecExtractsLinks *x = &all.items[e];
    if (strcmp(x->mode, "generate") != 0) continue;
    SomMap mine;
    som_map_init(&mine);
    for (size_t pl = 0; pl < x->from.len; pl++) {
      char *p = scoped_place(x->from.items[pl]);
      SpecPlaceResolution r;
      if (at(v, p, i->path, &r)) {
        SomMap registry;
        som_map_init(&registry);
        if (rows.len > 0) {
          SpecPlaceResolution ref;
          if (at(v, x->ref, rows.items[0], &ref)) {
            if (ref.form_field != NULL) {
              som_map_free(&registry);
              registry_of(v, &ref.form_field->refers_to, &registry);
            }
            spec_place_resolution_free(&ref);
          }
        }
        SomStrList paths;
        expand(v, r.path, &paths);
        for (size_t k = 0; k < paths.len; k++) {
          char *val = spec_link_validator_value(v, &r, paths.items[k]);
          SomStrList ids;
          ids_in(val, &registry, &ids);
          for (size_t m = 0; m < ids.len; m++) set_add(&mine, ids.items[m]);
          som_strlist_free(&ids);
          free(val);
        }
        som_strlist_free(&paths);
        som_map_free(&registry);
        spec_place_resolution_free(&r);
      }
      free(p);
    }
    for (size_t r = 0; r < rows.len; r++) {
      int generated = 1;
      for (size_t s = 0; s < x->set.len && generated; s++) {
        char *val = spec_link_validator_place_value(v, x->set.items[s].key,
                                                    rows.items[r]);
        generated = strcmp(val, x->set.items[s].value) == 0;
        free(val);
      }
      if (!generated) continue;
      for (size_t k = 0; k < named[r].len; k++) {
        const char *id = named[r].items[k];
        if (set_has(&mine, id)) continue;
        SpecLinkFix *fix = fix_push(v, 1, SPEC_LINK_FIX_REMOVE_ROW, rows.items[r]);
        fix->empty = 0;
        char *from = som_strlist_join(&x->from, " / ");
        report(v, SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE, rows.items[r],
               scat("the generated row names ", id, ", which ", from,
                    " no longer names", NULL));
        free(from);
      }
    }
    som_map_free(&mine);
  }

  for (size_t r = 0; r < rows.len; r++) som_strlist_free(&named[r]);
  free(named);
  som_map_free(&seen);
  som_map_free(&rowed);
  som_strlist_free(&set_keys);
  free(own);
  som_strlist_free(&rows);
  free(list_path);
  spec_extracts_links_list_free(&all);
}

/* ---- @SameAs ---------------------------------------------------------------- */

/* Every value beneath a subtree root: key -> value and key -> path. */
typedef struct {
  SomMap values;
  SomMap paths;
} Subtree;

static void subtree_free(Subtree *t) {
  som_map_free(&t->values);
  som_map_free(&t->paths);
}

/* The path relative to `root` with list items written by their section id,
 * so two subtrees compare element by element. Owned. */
static char *subtree_key(SpecLinkValidator *v, const char *root,
                         const char *path) {
  if (strcmp(path, root) == 0) return som_strdup("");
  const char *rel = path + strlen(root) + 1;
  if (*rel == '\0') return som_strdup("");
  SomBuf b;
  som_buf_init(&b);
  char *at_path = som_strdup(root);
  const char *s = rel;
  int first = 1;
  for (;;) {
    const char *slash = strchr(s, '/');
    size_t n = slash == NULL ? strlen(s) : (size_t)(slash - s);
    char *seg = som_strdup_n(s, n);
    char *next = scat(at_path, "/", seg, NULL);
    free(at_path);
    at_path = next;
    if (!first) som_buf_putc(&b, '/');
    first = 0;
    if (spec_link_validator_is_item(v, at_path)) {
      char *base = before_last(seg, '-');
      char *id = spec_link_validator_item_id(v, at_path);
      som_buf_puts(&b, base != NULL ? base : seg);
      som_buf_putc(&b, '[');
      som_buf_puts(&b, id);
      som_buf_putc(&b, ']');
      free(id);
      free(base);
    } else {
      som_buf_puts(&b, seg);
    }
    free(seg);
    if (slash == NULL) break;
    s = slash + 1;
  }
  free(at_path);
  return som_buf_take(&b);
}

static void subtree_put(Subtree *t, char *key_owned, const char *path,
                        char *value_owned) {
  if (value_owned[0] != '\0') {
    som_map_set(&t->values, key_owned, value_owned);
    som_map_set(&t->paths, key_owned, path);
  } else {
    som_map_remove(&t->values, key_owned);
    som_map_remove(&t->paths, key_owned);
  }
  free(key_owned);
  free(value_owned);
}

static void subtree_of(SpecLinkValidator *v, const char *root, Subtree *out) {
  som_map_init(&out->values);
  som_map_init(&out->paths);
  SomStrList paths;
  spec_document_content_paths(v->doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, root)) continue;
    char *k = subtree_key(v, root, p);
    char *key = scat("c:", k, NULL);
    free(k);
    subtree_put(out, key, p, spec_link_validator_content_value(v, p));
  }
  som_strlist_free(&paths);
  spec_document_form_paths(v->doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, root)) continue;
    SomStrList names;
    spec_document_form_field_names(v->doc, p, &names);
    sort_list(&names);
    char *k = subtree_key(v, root, p);
    for (size_t n = 0; n < names.len; n++) {
      char *key = scat("f:", k, "#", names.items[n], NULL);
      subtree_put(out, key, p,
                  spec_link_validator_form_value(v, p, names.items[n]));
    }
    free(k);
    som_strlist_free(&names);
  }
  som_strlist_free(&paths);
  spec_document_headline_paths(v->doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, root)) continue;
    char *k = subtree_key(v, root, p);
    char *key = scat("h:", k, NULL);
    free(k);
    subtree_put(out, key, p, spec_link_validator_headline_value(v, p));
  }
  som_strlist_free(&paths);
  spec_document_list_paths(v->doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *lst = paths.items[i];
    if (!under_path(lst, root)) continue;
    const SomStrList *items = spec_document_list_items(v->doc, lst);
    if (items == NULL) continue;
    for (size_t k = 0; k < items->len; k++) {
      const char *item = items->items[k];
      char *kk = subtree_key(v, root, item);
      char *key = scat("i:", kk, NULL);
      free(kk);
      subtree_put(out, key, item, spec_link_validator_item_id(v, item));
    }
  }
  som_strlist_free(&paths);
}

void spec_link_validator_subtree(SpecLinkValidator *v, const char *root,
                                 SomMap *values, SomMap *paths) {
  Subtree t;
  subtree_of(v, root, &t);
  *values = t.values;
  *paths = t.paths;
}

/* Reports every difference of the copy from the holder; whether there is
 * one. */
static int compare_subtrees(SpecLinkValidator *v, const char *copy_path,
                            const char *holder) {
  Subtree mine, theirs;
  subtree_of(v, copy_path, &mine);
  subtree_of(v, holder, &theirs);
  SomMap keys;
  som_map_init(&keys);
  for (size_t i = 0; i < mine.values.len; i++) set_add(&keys, mine.values.entries[i].key);
  for (size_t i = 0; i < theirs.values.len; i++) {
    set_add(&keys, theirs.values.entries[i].key);
  }
  /* An element on one side only is one finding; its values are not
   * compared. */
  SomStrList one_sided;
  som_strlist_init(&one_sided);
  for (size_t i = 0; i < keys.len; i++) {
    const char *k = keys.entries[i].key;
    int in_mine = som_map_get(&mine.values, k) != NULL;
    int in_theirs = som_map_get(&theirs.values, k) != NULL;
    if (starts_with(k, "i:") && in_mine != in_theirs) {
      som_strlist_push_copy(&one_sided, k + 2);
    }
  }
  int differs = 0;
  for (size_t i = 0; i < keys.len; i++) {
    const char *k = keys.entries[i].key;
    const char *a = som_map_get(&mine.values, k);
    const char *b = som_map_get(&theirs.values, k);
    int has_a = a != NULL, has_b = b != NULL;
    if (has_a == has_b && str_eq(a, b)) continue;
    int beneath = 0;
    if (!starts_with(k, "i:")) {
      const char *hash = strchr(k + 2, '#');
      char *rel = hash == NULL ? som_strdup(k + 2)
                               : som_strdup_n(k + 2, (size_t)(hash - k - 2));
      for (size_t o = 0; o < one_sided.len && !beneath; o++) {
        const char *os = one_sided.items[o];
        size_t n = strlen(os);
        beneath = strcmp(rel, os) == 0 ||
                  (strncmp(rel, os, n) == 0 && rel[n] == '/');
      }
      free(rel);
    }
    if (beneath) continue;
    differs = 1;
    char *what;
    if (starts_with(k, "i:")) {
      what = scat("element ", has_a ? a : b, NULL);
    } else if (starts_with(k, "h:")) {
      what = som_strdup("the headline");
    } else if (starts_with(k, "c:")) {
      what = som_strdup("the content");
    } else {
      const char *hash = strchr(k, '#');
      what = scat("form field \"", hash != NULL ? hash + 1 : k, "\"", NULL);
    }
    const char *at_path = has_a ? som_map_get(&mine.paths, k) : copy_path;
    report(v, SPEC_VALIDATION_CODE_SAME_AS_MISMATCH, at_path,
           scat("the copy of ", holder, " differs in ", what,
                ": the copy holds \"", has_a ? a : "", "\", the holder \"",
                has_b ? b : "", "\"", NULL));
    free(what);
  }
  som_strlist_free(&one_sided);
  som_map_free(&keys);
  subtree_free(&mine);
  subtree_free(&theirs);
  return differs;
}

static void check_same_as(SpecLinkValidator *v, const char *root_type) {
  SpecSameAsBindingList bindings;
  spec_same_as_bindings(&v->refl, root_type, &bindings);
  for (size_t i = 0; i < bindings.len; i++) {
    const SpecSameAsBinding *b = &bindings.items[i];
    if (b->holder_path == NULL) continue;
    SomStrList copies, holders;
    expand(v, b->copy_path, &copies);
    expand(v, b->holder_path, &holders);
    if (copies.len == holders.len) {
      for (size_t k = 0; k < copies.len; k++) {
        if (compare_subtrees(v, copies.items[k], holders.items[k])) {
          SpecLinkFix *fix =
              fix_push(v, 2, SPEC_LINK_FIX_COPY, copies.items[k]);
          fix->holder = som_strdup(holders.items[k]);
        }
      }
    }
    som_strlist_free(&copies);
    som_strlist_free(&holders);
  }
  spec_same_as_binding_list_free(&bindings);
}

/* ---- holds a value ----------------------------------------------------------- */

static void mark_up(SomMap *valued, const char *p, int self) {
  char *cur = self ? som_strdup(p) : before_last(p, '/');
  while (cur != NULL && cur[0] != '\0' && !set_has(valued, cur)) {
    set_add(valued, cur);
    char *parent = before_last(cur, '/');
    free(cur);
    cur = parent;
  }
  free(cur);
}

int spec_link_validator_holds_value(SpecLinkValidator *v, const char *path) {
  SpecLinkValidatorCache *c = v->cache;
  if (!c->have_valued) {
    const SpecDocument *doc = v->doc;
    SomStrList paths;
    spec_document_content_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      char *t = trim_dup(spec_document_content(doc, paths.items[i]));
      if (t[0] != '\0') mark_up(&c->valued, paths.items[i], 1);
      free(t);
    }
    som_strlist_free(&paths);
    spec_document_form_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      SomStrList names;
      spec_document_form_field_names(doc, paths.items[i], &names);
      for (size_t n = 0; n < names.len; n++) {
        char *t = trim_dup(
            spec_document_form_field(doc, paths.items[i], names.items[n]));
        int filled = t[0] != '\0';
        free(t);
        if (filled) {
          mark_up(&c->valued, paths.items[i], 1);
          break;
        }
      }
      som_strlist_free(&names);
    }
    som_strlist_free(&paths);
    spec_document_headline_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *h = spec_document_headline(doc, paths.items[i]);
      if (h != NULL && h[0] != '\0') mark_up(&c->valued, paths.items[i], 0);
    }
    som_strlist_free(&paths);
    spec_document_list_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      if (spec_document_list_item_count(doc, paths.items[i]) > 0) {
        mark_up(&c->valued, paths.items[i], 1);
      }
    }
    som_strlist_free(&paths);
    c->have_valued = 1;
  }
  return set_has(&c->valued, path);
}

/* ---- running ------------------------------------------------------------------ */

void spec_link_validator_run(SpecLinkValidator *v) {
  LinkInstances inst;
  memset(&inst, 0, sizeof(inst));
  for (size_t r = 0; r < v->model->roots_len; r++) {
    const SpecRoot *root = &v->model->roots[r];
    const char *seg = spec_reflection_root_segment(root);
    if (!populated(v, seg)) continue;
    const SpecClass *cls = spec_reflection_class_named(&v->refl, root->type);
    if (cls == NULL) continue;
    SomStrList on_path;
    som_strlist_init(&on_path);
    walk(v, cls, seg, seg, &inst, &on_path);
    som_strlist_free(&on_path);
  }
  check_derivations(v, &inst);
  for (size_t ii = 0; ii < inst.len; ii++) {
    const LinkInstance *i = &inst.items[ii];
    for (size_t fi = 0; fi < i->cls->fields_len; fi++) {
      const SpecField *f = &i->cls->fields[fi];
      check_summary(v, i, f);
      check_extracts(v, i, f);
      for (size_t k = 0; k < f->form_fields_len; k++) {
        const FormFieldSpec *ff = &f->form_fields[k];
        char *form = form_path_of(v, i, f);
        if (ff->inverse_of != NULL) check_inverse(v, form, ff);
        if (ff->summary_of != NULL) check_field_summary(v, i, form, ff);
        free(form);
      }
    }
  }
  for (size_t r = 0; r < v->model->roots_len; r++) {
    const SpecRoot *root = &v->model->roots[r];
    if (populated(v, spec_reflection_root_segment(root))) {
      check_same_as(v, root->type);
    }
  }
  for (size_t ii = 0; ii < inst.len; ii++) free(inst.items[ii].path);
  free(inst.items);
}

void spec_validate_links(const SpecModel *model, const SpecDocument *doc,
                         SpecValidationErrors *out) {
  SpecLinkValidator v;
  spec_link_validator_init(&v, model, doc, 0);
  spec_link_validator_run(&v);
  *out = v.errors;
  v.errors.items = NULL;
  v.errors.len = 0;
  v.errors.cap = 0;
  spec_link_validator_free(&v);
  /* By path, then by code (declaration order), then by message; stable. */
  for (size_t i = 1; i < out->len; i++) {
    SpecValidationError moving = out->items[i];
    size_t j = i;
    while (j > 0) {
      const SpecValidationError *prev = &out->items[j - 1];
      int c = strcmp(prev->path, moving.path);
      if (c == 0) {
        int pi = spec_validation_code_index(prev->code);
        int mi = spec_validation_code_index(moving.code);
        c = pi != mi ? (pi > mi ? 1 : -1) : strcmp(prev->message, moving.message);
      }
      if (c <= 0) break;
      out->items[j] = out->items[j - 1];
      j--;
    }
    out->items[j] = moving;
  }
}
