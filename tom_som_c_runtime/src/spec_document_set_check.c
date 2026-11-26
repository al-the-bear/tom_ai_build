/* spec_document_set_check — the findings and report of a document set, the
 * comparison behind them (`SpecSetCheck`), and the global rename. See
 * include/spec_document_set.h and src/spec_document_set_internal.h; a port of
 * the Rust `spec_document_set.rs`. */
#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_derive_fields.h"
#include "spec_document_set_internal.h"
#include "spec_links_validator.h"
#include "spec_review_annotations.h"
#include "spec_section_id.h"

/* ---- small string helpers ---------------------------------------------------- */

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

static int str_eq(const char *a, const char *b) {
  if (a == NULL || b == NULL) return a == b;
  return strcmp(a, b) == 0;
}

static int starts_with(const char *s, const char *prefix) {
  return strncmp(s, prefix, strlen(prefix)) == 0;
}

static const char *or_empty(const char *s) { return s != NULL ? s : ""; }

static int has_text(const char *s) { return s != NULL && s[0] != '\0'; }

static char *before_last_or_all(const char *s, char c) {
  const char *at = strrchr(s, c);
  return at == NULL ? som_strdup(s) : som_strdup_n(s, (size_t)(at - s));
}

static char *before_first(const char *s, char c) {
  const char *at = strchr(s, c);
  return at == NULL ? som_strdup(s) : som_strdup_n(s, (size_t)(at - s));
}

static int under_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && (path[n] == '\0' || path[n] == '/');
}

static int beneath_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && path[n] == '/';
}

static int set_has(const SomMap *m, const char *key) {
  return som_map_get(m, key) != NULL;
}

static void set_add(SomMap *m, const char *key) { som_map_set(m, key, "1"); }

static char *trim_dup(const char *s) {
  const char *a = s;
  while (*a == ' ' || *a == '\t' || *a == '\n' || *a == '\r' || *a == '\f' ||
         *a == '\v') {
    a++;
  }
  size_t n = strlen(a);
  while (n > 0 && (a[n - 1] == ' ' || a[n - 1] == '\t' || a[n - 1] == '\n' ||
                   a[n - 1] == '\r' || a[n - 1] == '\f' || a[n - 1] == '\v')) {
    n--;
  }
  return som_strdup_n(a, n);
}

static void split_all(const char *s, char sep, SomStrList *out) {
  som_strlist_init(out);
  const char *p = s;
  for (;;) {
    const char *at = strchr(p, sep);
    if (at == NULL) {
      som_strlist_push_copy(out, p);
      return;
    }
    som_strlist_push(out, som_strdup_n(p, (size_t)(at - p)));
    p = at + 1;
  }
}

static void strlist_extend(SomStrList *dst, const SomStrList *src) {
  for (size_t i = 0; i < src->len; i++) som_strlist_push_copy(dst, src->items[i]);
}

/* ---- JSON writers ------------------------------------------------------------ */

static void jstr(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

static void jkey(SomBuf *b, int *first, const char *key) {
  if (!*first) som_buf_putc(b, ',');
  *first = 0;
  jstr(b, key);
  som_buf_putc(b, ':');
}

static void jstrs(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    jstr(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

static void jtake(SomBuf *b, char *owned) {
  som_buf_puts(b, owned);
  free(owned);
}

/* ---- values of a document ---------------------------------------------------- */

const char *spec_set_get_value(const SpecDocument *doc, const char *path,
                               const char *field) {
  const char *v;
  if (field == NULL || field[0] == '\0') {
    v = spec_document_content(doc, path);
  } else if (strcmp(field, SPEC_HEADLINE_FIELD) == 0) {
    v = spec_document_headline(doc, path);
  } else {
    v = spec_document_form_field(doc, path, field);
  }
  return v != NULL ? v : "";
}

void spec_set_set_value(SpecDocument *doc, const char *path, const char *field,
                        const char *value) {
  if (field == NULL || field[0] == '\0') {
    spec_document_set_content(doc, path, value);
  } else if (strcmp(field, SPEC_HEADLINE_FIELD) == 0) {
    spec_document_set_headline(doc, path, value);
  } else {
    spec_document_set_form_field(doc, path, field, value);
  }
}

char *spec_set_add_item(SpecDocument *doc, const char *lst, const char *id) {
  if (id == NULL) return spec_document_add_list_item(doc, lst);
  SpecSectionIdError err;
  spec_section_id_error_init(&err);
  char *item = spec_document_add_list_item_with_section_id(doc, lst, id, &err);
  if (item == NULL) {
    /* The reference runtimes raise on a colliding id. */
    fprintf(stderr, "spec_set_add_item: the id %s is taken in %s\n", id, lst);
    spec_section_id_error_free(&err);
    abort();
  }
  spec_section_id_error_free(&err);
  return item;
}

int spec_set_in_scope(const SomStrList *scope, const char *name) {
  return scope == NULL || som_strlist_contains(scope, name);
}

/* ---- places and findings ------------------------------------------------------- */

void spec_sync_place_free(SpecSyncPlace *p) {
  free(p->document);
  free(p->root);
  free(p->path);
  free(p->field);
  free(p->value);
  memset(p, 0, sizeof(*p));
}

void spec_sync_place_copy(SpecSyncPlace *dst, const SpecSyncPlace *src) {
  dst->document = src->document != NULL ? som_strdup(src->document) : NULL;
  dst->root = som_strdup(or_empty(src->root));
  dst->path = som_strdup(or_empty(src->path));
  dst->field = som_strdup(or_empty(src->field));
  dst->value = src->value != NULL ? som_strdup(src->value) : NULL;
  dst->pending_marks = src->pending_marks;
}

const char *spec_sync_place_value_or(const SpecSyncPlace *p) {
  return or_empty(p->value);
}

char *spec_sync_place_to_json(const SpecSyncPlace *p) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "root");
  jstr(&b, p->root);
  jkey(&b, &first, "path");
  jstr(&b, p->path);
  jkey(&b, &first, "document");
  if (p->document != NULL) {
    jstr(&b, p->document);
  } else {
    som_buf_puts(&b, "null");
  }
  if (has_text(p->field)) {
    jkey(&b, &first, "field");
    jstr(&b, p->field);
  }
  if (p->value != NULL) {
    jkey(&b, &first, "value");
    jstr(&b, p->value);
  }
  jkey(&b, &first, "pendingMarks");
  som_buf_puts(&b, p->pending_marks ? "true" : "false");
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_sync_finding_free(SpecSyncFinding *f) {
  free(f->pair);
  spec_sync_place_free(&f->blueprint);
  spec_sync_place_free(&f->detail);
  free(f->message);
  memset(f, 0, sizeof(*f));
}

void spec_sync_finding_copy(SpecSyncFinding *dst, const SpecSyncFinding *src) {
  dst->code = src->code;
  dst->pair = som_strdup(or_empty(src->pair));
  spec_sync_place_copy(&dst->blueprint, &src->blueprint);
  spec_sync_place_copy(&dst->detail, &src->detail);
  dst->holder = src->holder;
  dst->resolution = src->resolution;
  dst->message = som_strdup(or_empty(src->message));
}

int spec_sync_finding_is_info(const SpecSyncFinding *f) {
  return f->resolution == SPEC_SYNC_RESOLUTION_INFO;
}

char *spec_sync_finding_to_json(const SpecSyncFinding *f) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "code");
  jstr(&b, spec_sync_code_name(f->code));
  jkey(&b, &first, "pair");
  jstr(&b, f->pair);
  jkey(&b, &first, "blueprint");
  jtake(&b, spec_sync_place_to_json(&f->blueprint));
  jkey(&b, &first, "detail");
  jtake(&b, spec_sync_place_to_json(&f->detail));
  jkey(&b, &first, "holder");
  jstr(&b, spec_sync_holder_name(f->holder));
  jkey(&b, &first, "resolution");
  jstr(&b, spec_sync_resolution_name(f->resolution));
  jkey(&b, &first, "message");
  jstr(&b, f->message);
  jkey(&b, &first, "info");
  som_buf_puts(&b, spec_sync_finding_is_info(f) ? "true" : "false");
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the report ------------------------------------------------------------------ */

void spec_sync_report_free(SpecSyncReport *r) {
  for (size_t i = 0; i < r->findings_len; i++) spec_sync_finding_free(&r->findings[i]);
  free(r->findings);
  for (size_t i = 0; i < r->document_findings_len; i++) {
    free(r->document_findings[i].name);
    spec_validation_errors_free(&r->document_findings[i].errors);
  }
  free(r->document_findings);
  som_strlist_free(&r->not_started);
  som_strlist_free(&r->not_started_pairs);
  memset(r, 0, sizeof(*r));
}

void spec_sync_report_counts_by_code(const SpecSyncReport *r,
                                     size_t counts[SPEC_SYNC_CODE_COUNT]) {
  for (int i = 0; i < SPEC_SYNC_CODE_COUNT; i++) counts[i] = 0;
  for (size_t i = 0; i < r->findings_len; i++) counts[r->findings[i].code]++;
}

void spec_sync_report_counts_by_resolution(
    const SpecSyncReport *r, size_t counts[SPEC_SYNC_RESOLUTION_COUNT]) {
  for (int i = 0; i < SPEC_SYNC_RESOLUTION_COUNT; i++) counts[i] = 0;
  for (size_t i = 0; i < r->findings_len; i++) counts[r->findings[i].resolution]++;
}

int spec_sync_report_clean(const SpecSyncReport *r) {
  for (size_t i = 0; i < r->findings_len; i++) {
    if (!spec_sync_finding_is_info(&r->findings[i])) return 0;
  }
  return 1;
}

static char *counts_json(const size_t *counts, int n, int codes) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  int first = 1;
  for (int i = 0; i < n; i++) {
    if (counts[i] == 0) continue;
    if (!first) som_buf_putc(&b, ',');
    first = 0;
    som_buf_putc(&b, '[');
    jstr(&b, codes ? spec_sync_code_name((SpecSyncCode)i)
                   : spec_sync_resolution_name((SpecSyncResolution)i));
    som_buf_putc(&b, ',');
    som_buf_puti(&b, (long long)counts[i]);
    som_buf_putc(&b, ']');
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

char *spec_sync_report_counts_by_code_json(const SpecSyncReport *r) {
  size_t counts[SPEC_SYNC_CODE_COUNT];
  spec_sync_report_counts_by_code(r, counts);
  return counts_json(counts, SPEC_SYNC_CODE_COUNT, 1);
}

char *spec_sync_report_counts_by_resolution_json(const SpecSyncReport *r) {
  size_t counts[SPEC_SYNC_RESOLUTION_COUNT];
  spec_sync_report_counts_by_resolution(r, counts);
  return counts_json(counts, SPEC_SYNC_RESOLUTION_COUNT, 0);
}

char *spec_sync_report_to_json(const SpecSyncReport *r) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "findings");
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < r->findings_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    jtake(&b, spec_sync_finding_to_json(&r->findings[i]));
  }
  som_buf_putc(&b, ']');
  jkey(&b, &first, "documentFindings");
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < r->document_findings_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_putc(&b, '[');
    jstr(&b, r->document_findings[i].name);
    som_buf_putc(&b, ',');
    jtake(&b, spec_validation_errors_json(&r->document_findings[i].errors));
    som_buf_putc(&b, ']');
  }
  som_buf_putc(&b, ']');
  jkey(&b, &first, "notStarted");
  jstrs(&b, &r->not_started);
  jkey(&b, &first, "notStartedPairs");
  jstrs(&b, &r->not_started_pairs);
  jkey(&b, &first, "countsByCode");
  jtake(&b, spec_sync_report_counts_by_code_json(r));
  jkey(&b, &first, "countsByResolution");
  jtake(&b, spec_sync_report_counts_by_resolution_json(r));
  jkey(&b, &first, "clean");
  som_buf_puts(&b, spec_sync_report_clean(r) ? "true" : "false");
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the comparison helpers ---------------------------------------------------- */

/* `^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$`, any case. */
static int is_float_text(const char *t) {
  size_t i = 0, n = strlen(t);
  if (i < n && (t[i] == '+' || t[i] == '-')) i++;
  size_t int_start = i;
  while (i < n && t[i] >= '0' && t[i] <= '9') i++;
  if (i > int_start) {
    if (i < n && t[i] == '.') {
      i++;
      while (i < n && t[i] >= '0' && t[i] <= '9') i++;
    }
  } else {
    if (i >= n || t[i] != '.') return 0;
    i++;
    size_t frac = i;
    while (i < n && t[i] >= '0' && t[i] <= '9') i++;
    if (i == frac) return 0;
  }
  if (i < n && (t[i] == 'e' || t[i] == 'E')) {
    i++;
    if (i < n && (t[i] == '+' || t[i] == '-')) i++;
    size_t exp = i;
    while (i < n && t[i] >= '0' && t[i] <= '9') i++;
    if (i == exp) return 0;
  }
  return i == n;
}

static int is_hex(char c) {
  return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

/* Dart's `num.tryParse`: decimal, hex, `Infinity` and `NaN`. */
static int num_try_parse(const char *text, double *out) {
  char *t = trim_dup(text);
  int ok = 0;
  if (is_float_text(t)) {
    *out = strtod(t, NULL);
    ok = 1;
  } else {
    int neg = t[0] == '-';
    const char *body = (t[0] == '-' || t[0] == '+') ? t + 1 : t;
    size_t n = strlen(body);
    if (n > 2 && body[0] == '0' && (body[1] == 'x' || body[1] == 'X')) {
      int all = 1;
      for (size_t i = 2; i < n && all; i++) all = is_hex(body[i]);
      if (all && n - 2 <= 16) {
        double v = (double)strtoull(body + 2, NULL, 16);
        *out = neg ? -v : v;
        ok = 1;
      }
    } else if (strcmp(body, "NaN") == 0) {
      *out = NAN;
      ok = 1;
    } else if (strcmp(body, "Infinity") == 0) {
      *out = neg ? -INFINITY : INFINITY;
      ok = 1;
    }
  }
  free(t);
  return ok;
}

char *spec_set_reviewed(const char *raw) {
  char *rejected = spec_apply_inline_marks_text(or_empty(raw), 0);
  char *out = trim_dup(rejected);
  free(rejected);
  return out;
}

int spec_set_is_pending(const char *raw) {
  char *a = spec_apply_inline_marks_text(or_empty(raw), 1);
  char *r = spec_apply_inline_marks_text(or_empty(raw), 0);
  int pending = strcmp(a, r) != 0;
  free(a);
  free(r);
  return pending;
}

int spec_set_same_typed(const char *a, const char *b,
                        const FormFieldSpec *spec) {
  const char *type = spec != NULL ? or_empty(spec->type) : "";
  if (strcmp(type, "int") == 0 || strcmp(type, "double") == 0 ||
      strcmp(type, "num") == 0) {
    double x, y;
    if (num_try_parse(a, &x) && num_try_parse(b, &y)) return x == y;
  } else if (strcmp(type, "bool") == 0) {
    size_t n = strlen(a);
    if (n != strlen(b)) return 0;
    for (size_t i = 0; i < n; i++) {
      char p = a[i] >= 'A' && a[i] <= 'Z' ? (char)(a[i] + 32) : a[i];
      char q = b[i] >= 'A' && b[i] <= 'Z' ? (char)(b[i] + 32) : b[i];
      if (p != q) return 0;
    }
    return 1;
  }
  return strcmp(a, b) == 0;
}

char *spec_set_strip_kind(const char *key) {
  const char *k = strlen(key) > 2 && key[1] == ':' ? key + 2 : key;
  return before_first(k, '#');
}

/* The key with every item id dropped (`LIST[X]` -> `LIST[]`). Owned. */
static char *set_shape(const char *key) {
  SomBuf b;
  som_buf_init(&b);
  const char *rest = key;
  for (;;) {
    const char *open = strchr(rest, '[');
    if (open == NULL) break;
    const char *close = strchr(open, ']');
    if (close == NULL) break;
    som_buf_putn(&b, rest, (size_t)(open - rest));
    som_buf_puts(&b, "[]");
    rest = close + 1;
  }
  som_buf_puts(&b, rest);
  return som_buf_take(&b);
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* The distinct entries of `a` not in `b`, sorted, into `out` (initialised by
 * the callee). */
static void sorted_minus(const SomStrList *a, const SomStrList *b,
                         SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < a->len; i++) {
    if (!som_strlist_contains(b, a->items[i]) &&
        !som_strlist_contains(out, a->items[i])) {
      som_strlist_push_copy(out, a->items[i]);
    }
  }
  if (out->len > 1) qsort(out->items, out->len, sizeof(char *), cmp_str);
}

static int set_under_any(const char *path, const SomStrList *prefixes) {
  for (size_t i = 0; i < prefixes->len; i++) {
    if (under_path(path, prefixes->items[i])) return 1;
  }
  return 0;
}

char *spec_set_effective_item_id(const SpecReflection *refl,
                                 const SpecDocument *doc,
                                 const char *item_path) {
  const char *stored = spec_document_item_section_id(doc, item_path);
  if (stored != NULL) return som_strdup(stored);
  char *lst = before_last_or_all(item_path, '-');
  const char *slash = strrchr(lst, '/');
  char *stem = som_strdup(slash != NULL ? slash + 1 : lst);
  char *pattern = som_strdup("");
  SpecResolution res;
  if (spec_reflection_resolve(refl, lst, &res)) {
    if (res.field != NULL) {
      free(pattern);
      free(stem);
      pattern = som_strdup(or_empty(res.field->section_id_pattern));
      stem = som_strdup(res.field->name);
    }
    spec_resolution_free(&res);
  }
  long long position = 0;
  const SomStrList *items = spec_document_list_items(doc, lst);
  for (size_t k = 0; items != NULL && k < items->len; k++) {
    if (strcmp(items->items[k], item_path) == 0) {
      position = (long long)k + 1;
      break;
    }
  }
  char *id = spec_effective_list_item_section_id(NULL, pattern, position, stem);
  free(pattern);
  free(stem);
  free(lst);
  return id;
}

/* Whether `f` carries `@DerivedFrom`. */
static int field_is_derived(const SpecField *f) {
  SpecDerivation d;
  if (!spec_annotations_derived_from(&f->annotations, &d)) return 0;
  spec_derivation_free(&d);
  return 1;
}

/* ---- sides ---------------------------------------------------------------------- */

static SpecSetSide *side_new(const char *name, const char *root,
                             const char *anchor) {
  SpecSetSide *s = (SpecSetSide *)calloc(1, sizeof(SpecSetSide));
  s->refs = 1;
  s->name = som_strdup(name);
  s->root = som_strdup(root);
  s->anchor = som_strdup(anchor);
  som_map_init(&s->items);
  som_strlist_init(&s->item_keys);
  return s;
}

void spec_set_side_release(SpecSetSide *s) {
  if (s == NULL || --s->refs > 0) return;
  free(s->name);
  free(s->root);
  free(s->anchor);
  for (size_t i = 0; i < s->values_len; i++) {
    free(s->values[i].key);
    free(s->values[i].path);
    free(s->values[i].field);
    free(s->values[i].value);
  }
  free(s->values);
  som_map_free(&s->items);
  som_strlist_free(&s->item_keys);
  free(s);
}

static int side_find(const SpecSetSide *s, const char *key, size_t *pos) {
  size_t lo = 0, hi = s->values_len;
  while (lo < hi) {
    size_t mid = (lo + hi) / 2;
    int c = strcmp(s->values[mid].key, key);
    if (c == 0) {
      *pos = mid;
      return 1;
    }
    if (c < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  *pos = lo;
  return 0;
}

const SpecSetValue *spec_set_side_value(const SpecSetSide *s, const char *key) {
  size_t pos;
  return side_find(s, key, &pos) ? &s->values[pos] : NULL;
}

/* Inserts (or replaces) the value of `key_owned`, taking the owned strings. */
static void side_put_value(SpecSetSide *s, char *key_owned, const char *path,
                           const char *field, char *value_owned, int pending,
                           const FormFieldSpec *spec) {
  size_t pos;
  SpecSetValue *v;
  if (side_find(s, key_owned, &pos)) {
    v = &s->values[pos];
    free(v->key);
    free(v->path);
    free(v->field);
    free(v->value);
  } else {
    if (s->values_len == s->values_cap) {
      s->values_cap = s->values_cap ? s->values_cap * 2 : 8;
      s->values = (SpecSetValue *)realloc(s->values,
                                          s->values_cap * sizeof(SpecSetValue));
    }
    memmove(&s->values[pos + 1], &s->values[pos],
            (s->values_len - pos) * sizeof(SpecSetValue));
    s->values_len++;
    v = &s->values[pos];
  }
  v->key = key_owned;
  v->path = som_strdup(path);
  v->field = som_strdup(field);
  v->value = value_owned;
  v->pending = pending;
  v->spec = spec;
}

static void side_put_item(SpecSetSide *s, const char *key, const char *path) {
  if (!set_has(&s->items, key)) som_strlist_push_copy(&s->item_keys, key);
  som_map_set(&s->items, key, path);
}

/* ---- the check's caches ---------------------------------------------------------- */

typedef struct {
  char *root;
  SomStrList names;
} ReachEntry;

typedef struct {
  char *root;
  SpecSameAsBindingList list;
} SameAsEntry;

struct SpecSetCheckCache {
  SomMap item_ids;      /* "<doc>\x01<path>" -> id */
  SomMap items;         /* path -> "1" / "0" */
  SomMap forms_indexed; /* "<doc>" -> 1 */
  SomMap forms;         /* "<doc>\x01<row>" -> form paths, '\n'-joined */
  SomMap registry_docs; /* section id -> document name */
  ReachEntry *reach;
  size_t reach_len;
  SomStrList entries_keys; /* "<doc>\x01<target>" */
  SomMap *entries;         /* parallel: id -> item */
  SameAsEntry *same_as;
  size_t same_as_len;
};

static char *doc_key(const SpecDocument *doc, const char *rest) {
  char buf[64];
  snprintf(buf, sizeof(buf), "%p", (const void *)doc);
  return rest != NULL ? scat(buf, "\x01", rest, NULL) : som_strdup(buf);
}

void spec_set_check_init(SpecSetCheck *c, const SpecDocumentSet *set) {
  memset(c, 0, sizeof(*c));
  c->set = set;
  c->refl = spec_reflection_make(set->model);
  som_strlist_init(&c->not_started_pairs);
  c->cache = (SpecSetCheckCache *)calloc(1, sizeof(SpecSetCheckCache));
  som_map_init(&c->cache->item_ids);
  som_map_init(&c->cache->items);
  som_map_init(&c->cache->forms_indexed);
  som_map_init(&c->cache->forms);
  som_map_init(&c->cache->registry_docs);
  som_strlist_init(&c->cache->entries_keys);
}

void spec_set_check_free(SpecSetCheck *c) {
  for (size_t i = 0; i < c->out_len; i++) {
    free(c->out[i].key);
    spec_sync_finding_free(&c->out[i].finding);
    spec_set_side_release(c->out[i].b);
    spec_set_side_release(c->out[i].d);
  }
  free(c->out);
  som_strlist_free(&c->not_started_pairs);
  SpecSetCheckCache *k = c->cache;
  if (k != NULL) {
    som_map_free(&k->item_ids);
    som_map_free(&k->items);
    som_map_free(&k->forms_indexed);
    som_map_free(&k->forms);
    som_map_free(&k->registry_docs);
    for (size_t i = 0; i < k->reach_len; i++) {
      free(k->reach[i].root);
      som_strlist_free(&k->reach[i].names);
    }
    free(k->reach);
    for (size_t i = 0; i < k->entries_keys.len; i++) som_map_free(&k->entries[i]);
    free(k->entries);
    som_strlist_free(&k->entries_keys);
    for (size_t i = 0; i < k->same_as_len; i++) {
      free(k->same_as[i].root);
      spec_same_as_binding_list_free(&k->same_as[i].list);
    }
    free(k->same_as);
    free(k);
  }
  memset(c, 0, sizeof(*c));
}

/* Adds a finding, taking `key` and the finding's strings; `b` / `d` are
 * referenced. */
static void check_add(SpecSetCheck *c, size_t order, char *key,
                      SpecSyncFinding *finding, SpecSetSide *b,
                      SpecSetSide *d) {
  if (c->out_len == c->out_cap) {
    c->out_cap = c->out_cap ? c->out_cap * 2 : 16;
    c->out = (SpecSetFound *)realloc(c->out, c->out_cap * sizeof(SpecSetFound));
  }
  SpecSetFound *o = &c->out[c->out_len];
  o->seq = c->out_len;
  o->order = order;
  o->key = key;
  o->finding = *finding;
  memset(finding, 0, sizeof(*finding));
  o->b = b;
  o->d = d;
  if (b != NULL) b->refs++;
  if (d != NULL) d->refs++;
  c->out_len++;
}

static const char *found_value(const SpecSyncFinding *f) {
  return f->blueprint.value != NULL ? f->blueprint.value
                                    : spec_sync_place_value_or(&f->detail);
}

static int cmp_found_base(const SpecSetFound *a, const SpecSetFound *b) {
  if (a->order != b->order) return a->order < b->order ? -1 : 1;
  int k = strcmp(a->key, b->key);
  if (k != 0) return k;
  if (a->finding.code != b->finding.code) {
    return a->finding.code < b->finding.code ? -1 : 1;
  }
  return 0;
}

static int cmp_found(const void *pa, const void *pb) {
  const SpecSetFound *a = (const SpecSetFound *)pa;
  const SpecSetFound *b = (const SpecSetFound *)pb;
  int c = cmp_found_base(a, b);
  if (c != 0) return c;
  c = strcmp(found_value(&a->finding), found_value(&b->finding));
  if (c != 0) return c;
  return a->seq < b->seq ? -1 : (a->seq > b->seq ? 1 : 0);
}

static int cmp_found_by_code(const void *pa, const void *pb) {
  const SpecSetFound *a = (const SpecSetFound *)pa;
  const SpecSetFound *b = (const SpecSetFound *)pb;
  int c = cmp_found_base(a, b);
  if (c != 0) return c;
  return a->seq < b->seq ? -1 : (a->seq > b->seq ? 1 : 0);
}

void spec_set_check_sort_out(SpecSetCheck *c) {
  if (c->out_len > 1) qsort(c->out, c->out_len, sizeof(SpecSetFound), cmp_found);
}

void spec_set_check_sort_out_by_code(SpecSetCheck *c) {
  if (c->out_len > 1) {
    qsort(c->out, c->out_len, sizeof(SpecSetFound), cmp_found_by_code);
  }
}

/* The section id of the root type `type_name`. Borrowed. */
static const char *root_seg(const SpecSetCheck *c, const char *type_name) {
  for (size_t i = 0; i < c->set->model->roots_len; i++) {
    const SpecRoot *r = &c->set->model->roots[i];
    if (str_eq(r->type, type_name)) return spec_reflection_root_segment(r);
  }
  fprintf(stderr, "spec_document_set: no root %s\n", or_empty(type_name));
  abort();
}

char *spec_set_check_item_id(SpecSetCheck *c, const SpecDocument *doc,
                             const char *item_path) {
  char *key = doc_key(doc, item_path);
  const char *hit = som_map_get(&c->cache->item_ids, key);
  if (hit != NULL) {
    free(key);
    return som_strdup(hit);
  }
  char *id = spec_set_effective_item_id(&c->refl, doc, item_path);
  som_map_set(&c->cache->item_ids, key, id);
  free(key);
  return id;
}

/* Whether `path` is a list item (complex or scalar). */
static int is_item(SpecSetCheck *c, const char *path) {
  const char *hit = som_map_get(&c->cache->items, path);
  if (hit != NULL) return hit[0] == '1';
  SpecResolution r;
  int item = 0;
  if (spec_reflection_resolve(&c->refl, path, &r)) {
    item = strcmp(r.kind, SPEC_NODE_KIND_LIST_ITEM_COMPLEX) == 0 ||
           strcmp(r.kind, SPEC_NODE_KIND_LIST_ITEM_SCALAR) == 0;
    spec_resolution_free(&r);
  }
  som_map_set(&c->cache->items, path, item ? "1" : "0");
  return item;
}

/* The key of `path` below `anchor`: item segments as `LIST[id]`. Owned. */
static char *path_key(SpecSetCheck *c, const SpecDocument *doc,
                      const char *anchor, const char *path) {
  if (strcmp(path, anchor) == 0) return som_strdup("");
  size_t n = strlen(anchor);
  const char *rel = strlen(path) > n ? path + n + 1 : "";
  SomStrList segs;
  split_all(rel, '/', &segs);
  SomBuf b;
  som_buf_init(&b);
  char *at = som_strdup(anchor);
  for (size_t i = 0; i < segs.len; i++) {
    const char *seg = segs.items[i];
    char *next = scat(at, "/", seg, NULL);
    free(at);
    at = next;
    if (i > 0) som_buf_putc(&b, '/');
    if (is_item(c, at)) {
      char *base = before_last_or_all(seg, '-');
      char *id = spec_set_check_item_id(c, doc, at);
      som_buf_puts(&b, base);
      som_buf_putc(&b, '[');
      som_buf_puts(&b, id);
      som_buf_putc(&b, ']');
      free(base);
      free(id);
    } else {
      som_buf_puts(&b, seg);
    }
  }
  free(at);
  som_strlist_free(&segs);
  return som_buf_take(&b);
}

char *spec_set_check_anchor_key(SpecSetCheck *c, const SpecDocument *doc,
                                const char *path) {
  SomStrList segs;
  split_all(path, '/', &segs);
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  char *at = som_strdup("");
  for (size_t i = 0; i < segs.len; i++) {
    char *next = at[0] == '\0' ? som_strdup(segs.items[i])
                               : scat(at, "/", segs.items[i], NULL);
    free(at);
    at = next;
    if (is_item(c, at)) {
      char *id = spec_set_check_item_id(c, doc, at);
      if (!first) som_buf_putc(&b, '/');
      first = 0;
      som_buf_puts(&b, id);
      free(id);
    }
  }
  free(at);
  som_strlist_free(&segs);
  return som_buf_take(&b);
}

/* The places a set of place texts stands for under an anchor. */
typedef struct {
  SomStrList prefixes;
  SomMap fields;    /* "<path>#<field>" */
  SomMap headlines; /* path */
} SetPlaces;

static void set_places_free(SetPlaces *p) {
  som_strlist_free(&p->prefixes);
  som_map_free(&p->fields);
  som_map_free(&p->headlines);
}

static void places_of(SpecSetCheck *c, const SpecDocument *doc,
                      const SomStrList *places, const char *anchor,
                      SetPlaces *out) {
  som_strlist_init(&out->prefixes);
  som_map_init(&out->fields);
  som_map_init(&out->headlines);
  for (size_t i = 0; places != NULL && i < places->len; i++) {
    SpecPlaceResolution r;
    if (!spec_resolve_place_at(&c->refl, places->items[i], anchor, &r)) continue;
    SomStrList paths;
    spec_expand_pattern(doc, r.path, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      const char *p = paths.items[k];
      if (strcmp(r.kind, SPEC_PLACE_KIND_FORM_FIELD) == 0) {
        char *key = scat(p, "#", or_empty(spec_place_resolution_field(&r)), NULL);
        set_add(&out->fields, key);
        free(key);
      } else if (strcmp(r.kind, SPEC_PLACE_KIND_HEADLINE) == 0) {
        set_add(&out->headlines, p);
      } else if (strcmp(r.kind, SPEC_PLACE_KIND_SECTION_ID) != 0) {
        som_strlist_push_copy(&out->prefixes, p);
      }
    }
    som_strlist_free(&paths);
    spec_place_resolution_free(&r);
  }
}

static const SpecSameAsBindingList *same_as_of(SpecSetCheck *c,
                                               const char *root) {
  SpecSetCheckCache *k = c->cache;
  for (size_t i = 0; i < k->same_as_len; i++) {
    if (strcmp(k->same_as[i].root, root) == 0) return &k->same_as[i].list;
  }
  k->same_as = (SameAsEntry *)realloc(k->same_as,
                                      (k->same_as_len + 1) * sizeof(SameAsEntry));
  SameAsEntry *e = &k->same_as[k->same_as_len++];
  e->root = som_strdup(root);
  spec_same_as_bindings(&c->refl, root, &e->list);
  return &e->list;
}

/* The field the path resolves to, or NULL (borrowed from the model). */
static const SpecField *field_at(const SpecSetCheck *c, const char *path) {
  SpecResolution r;
  if (!spec_reflection_resolve(&c->refl, path, &r)) return NULL;
  const SpecField *f = r.field;
  spec_resolution_free(&r);
  return f;
}

SpecSetSide *spec_set_check_collect(SpecSetCheck *c, const char *name,
                                    const SpecDocument *doc, const char *root,
                                    const char *anchor,
                                    const SpecSyncPair *pair,
                                    const SomStrList *nested) {
  SpecSetSide *side = side_new(name, root, anchor);
  SetPlaces skip;
  places_of(c, doc, pair->has_sync ? &pair->sync.detail_only : NULL, anchor,
            &skip);
  const SpecSameAsBindingList *bindings = same_as_of(c, root);
  SomStrList excluded;
  som_strlist_init(&excluded);
  strlist_extend(&excluded, &skip.prefixes);
  if (nested != NULL) strlist_extend(&excluded, nested);
  for (size_t i = 0; i < bindings->len; i++) {
    SomStrList copies;
    spec_expand_pattern(doc, bindings->items[i].copy_path, &copies);
    strlist_extend(&excluded, &copies);
    som_strlist_free(&copies);
  }

  SomStrList lists;
  spec_document_list_paths(doc, &lists);
  /* The values a summary row repeats are derived from its detail element
   * (`@SummaryOf` repeats): never shared, like every derived place. */
  for (size_t i = 0; i < lists.len; i++) {
    const char *lst = lists.items[i];
    if (!under_path(lst, anchor)) continue;
    const SpecField *field = field_at(c, lst);
    if (field == NULL) continue;
    SpecSummaryOf s;
    if (!spec_annotations_summary_of(&field->annotations, &s)) continue;
    if (s.repeats.len > 0) {
      SomStrList repeats;
      som_strlist_init(&repeats);
      for (size_t k = 0; k < s.repeats.len; k++) {
        som_strlist_push_copy(&repeats, s.repeats.items[k].key);
      }
      const SomStrList *items = spec_document_list_items(doc, lst);
      for (size_t k = 0; items != NULL && k < items->len; k++) {
        SetPlaces r;
        places_of(c, doc, &repeats, items->items[k], &r);
        strlist_extend(&excluded, &r.prefixes);
        for (size_t m = 0; m < r.fields.len; m++) {
          set_add(&skip.fields, r.fields.entries[m].key);
        }
        for (size_t m = 0; m < r.headlines.len; m++) {
          set_add(&skip.headlines, r.headlines.entries[m].key);
        }
        set_places_free(&r);
      }
      som_strlist_free(&repeats);
    }
    spec_summary_of_free(&s);
  }

  side_put_item(side, "", anchor);
#define OUTSIDE(p) (strcmp((p), anchor) != 0 && set_under_any((p), &excluded))
  for (size_t i = 0; i < lists.len; i++) {
    const char *lst = lists.items[i];
    if (!under_path(lst, anchor) || OUTSIDE(lst)) continue;
    const SpecField *field = field_at(c, lst);
    if (field != NULL && field_is_derived(field)) {
      som_strlist_push_copy(&excluded, lst);
      continue;
    }
    const SomStrList *items = spec_document_list_items(doc, lst);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      char *key = path_key(c, doc, anchor, items->items[k]);
      side_put_item(side, key, items->items[k]);
      free(key);
    }
  }
  som_strlist_free(&lists);

  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, anchor) || OUTSIDE(p)) continue;
    const SpecField *field = field_at(c, p);
    if (field != NULL && field_is_derived(field)) continue;
    const char *raw = or_empty(spec_document_content(doc, p));
    char *k = path_key(c, doc, anchor, p);
    side_put_value(side, scat("c:", k, NULL), p, "", spec_set_reviewed(raw),
                   spec_set_is_pending(raw), NULL);
    free(k);
  }
  som_strlist_free(&paths);

  spec_document_form_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, anchor) || OUTSIDE(p)) continue;
    const SpecField *field = field_at(c, p);
    SomStrList names;
    spec_document_form_field_names(doc, p, &names);
    char *k = NULL;
    for (size_t n = 0; n < names.len; n++) {
      const char *fname = names.items[n];
      char *fkey = scat(p, "#", fname, NULL);
      int skipped = set_has(&skip.fields, fkey);
      free(fkey);
      if (skipped) continue;
      const FormFieldSpec *spec = NULL;
      for (size_t m = 0; field != NULL && m < field->form_fields_len; m++) {
        if (strcmp(field->form_fields[m].name, fname) == 0) {
          spec = &field->form_fields[m];
          break;
        }
      }
      if (spec != NULL &&
          (spec->derived_from != NULL || spec->count_of.len > 0 ||
           spec->product_of.len > 0 || has_text(spec->rank_of))) {
        continue;
      }
      const char *raw = or_empty(spec_document_form_field(doc, p, fname));
      if (k == NULL) k = path_key(c, doc, anchor, p);
      side_put_value(side, scat("f:", k, "#", fname, NULL), p, fname,
                     spec_set_reviewed(raw), spec_set_is_pending(raw), spec);
    }
    free(k);
    som_strlist_free(&names);
  }
  som_strlist_free(&paths);

  spec_document_headline_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *p = paths.items[i];
    if (!under_path(p, anchor) || OUTSIDE(p) || set_has(&skip.headlines, p)) {
      continue;
    }
    const char *raw = or_empty(spec_document_headline(doc, p));
    char *k = path_key(c, doc, anchor, p);
    side_put_value(side, scat("h:", k, NULL), p, SPEC_HEADLINE_FIELD,
                   spec_set_reviewed(raw), spec_set_is_pending(raw), NULL);
    free(k);
  }
#undef OUTSIDE
  som_strlist_free(&paths);
  som_strlist_free(&excluded);
  set_places_free(&skip);
  return side;
}

/* The path `key` stands for on `side`: the item paths it names as far as the
 * side holds them; where it stops, the list an element would go in. Owned. */
static char *path_on(const SpecSetSide *side, const char *key) {
  if (key[0] == '\0') return som_strdup(side->anchor);
  char *path = som_strdup(side->anchor);
  char *prefix = som_strdup("");
  SomStrList segs;
  split_all(key, '/', &segs);
  for (size_t i = 0; i < segs.len; i++) {
    const char *s = segs.items[i];
    char *next = prefix[0] == '\0' ? som_strdup(s) : scat(prefix, "/", s, NULL);
    free(prefix);
    prefix = next;
    const char *bracket = strchr(s, '[');
    if (bracket != NULL && bracket > s) {
      const char *item = som_map_get(&side->items, prefix);
      if (item != NULL) {
        free(path);
        path = som_strdup(item);
      } else {
        char *base = som_strdup_n(s, (size_t)(bracket - s));
        char *out = scat(path, "/", base, NULL);
        free(base);
        free(path);
        free(prefix);
        som_strlist_free(&segs);
        return out;
      }
    } else {
      char *np = scat(path, "/", s, NULL);
      free(path);
      path = np;
    }
  }
  free(prefix);
  som_strlist_free(&segs);
  return path;
}

/* ---- one pair -------------------------------------------------------------------- */

/* A place of a side, `value` (owned, NULL: none) taken. */
static void side_place(const SpecSetCheck *c, const SpecSetSide *s,
                       const char *key, const char *fld, char *value,
                       SpecSyncPlace *out) {
  out->document = som_strdup(s->name);
  out->root = som_strdup(root_seg(c, s->root));
  out->path = NULL;
  out->field = som_strdup(fld);
  out->value = value;
  out->pending_marks = 0;
  const SpecSetValue *v = spec_set_side_value(s, key);
  if (v != NULL) {
    out->path = som_strdup(v->path);
    if (fld[0] == '\0') {
      free(out->field);
      out->field = som_strdup(v->field);
    }
    if (value == NULL) out->value = som_strdup(v->value);
    out->pending_marks = v->pending;
  } else if (starts_with(key, "i:")) {
    out->path = path_on(s, key + 2);
  } else {
    char *rel = spec_set_strip_kind(key);
    out->path = path_on(s, rel);
    free(rel);
  }
}

/* Emits one finding of a pair; `message`, `b_value`, `d_value` taken (NULL:
 * none); `resolution` < 0 for the default. */
static void emit(SpecSetCheck *c, const SpecSyncPair *pair, size_t order,
                 SpecSetSide *b, SpecSetSide *d, SpecSyncCode code,
                 const char *key, char *message, int held_here,
                 const char *fld, char *b_value, char *d_value,
                 int resolution) {
  SpecSyncFinding f;
  memset(&f, 0, sizeof(f));
  f.code = code;
  f.pair = som_strdup(pair->section_id);
  side_place(c, b, key, fld, b_value, &f.blueprint);
  side_place(c, d, key, fld, d_value, &f.detail);
  f.holder = held_here ? SPEC_SYNC_HOLDER_BLUEPRINT : SPEC_SYNC_HOLDER_DETAIL;
  f.resolution = resolution >= 0 ? (SpecSyncResolution)resolution
                 : held_here     ? SPEC_SYNC_RESOLUTION_AGENT
                                 : SPEC_SYNC_RESOLUTION_BACKFILL;
  f.message = message;
  check_add(c, order, som_strdup(key), &f, b, d);
}

/* The values a row's own forms (`<row>/<member>`) hold in `fld`, into `out`
 * (initialised by the callee). */
static void own_values(SpecSetCheck *c, const SpecDocument *doc,
                       const char *row, const char *fld, SomStrList *out) {
  som_strlist_init(out);
  char *dk = doc_key(doc, NULL);
  if (!set_has(&c->cache->forms_indexed, dk)) {
    set_add(&c->cache->forms_indexed, dk);
    SomStrList paths;
    spec_document_form_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      const char *slash = strrchr(p, '/');
      if (slash == NULL || slash == p) continue;
      char *owner = som_strdup_n(p, (size_t)(slash - p));
      char *key = doc_key(doc, owner);
      const char *have = som_map_get(&c->cache->forms, key);
      char *joined = have != NULL ? scat(have, "\n", p, NULL) : som_strdup(p);
      som_map_set(&c->cache->forms, key, joined);
      free(joined);
      free(key);
      free(owner);
    }
    som_strlist_free(&paths);
  }
  free(dk);
  char *key = doc_key(doc, row);
  const char *forms = som_map_get(&c->cache->forms, key);
  free(key);
  if (forms == NULL) return;
  SomStrList list;
  split_all(forms, '\n', &list);
  for (size_t i = 0; i < list.len; i++) {
    const char *v = spec_document_form_field(doc, list.items[i], fld);
    if (v != NULL) som_strlist_push(out, spec_set_reviewed(v));
  }
  som_strlist_free(&list);
}

/* Whether the Blueprint place `bp_path` (form field `fld`, "" for none) is
 * held in the Blueprint. */
static int is_held(const SetPlaces *held, const char *bp_path, const char *fld) {
  if (set_under_any(bp_path, &held->prefixes)) return 1;
  if (fld[0] == '\0') return 0;
  char *key = scat(bp_path, "#", fld, NULL);
  int hit = set_has(&held->fields, key);
  free(key);
  return hit;
}

static void compare(SpecSetCheck *c, const SpecSyncPair *pair, size_t order,
                    SpecSetSide *b, SpecSetSide *d, const SpecDocument *bp,
                    const SpecDocument *dt) {
  /* Relations: list key -> relation / where; field key -> relation. */
  SomMap list_rel, list_where, field_rel;
  som_map_init(&list_rel);
  som_map_init(&list_where);
  som_map_init(&field_rel);
  if (pair->has_sync) {
    for (size_t i = 0; i < pair->sync.relations_len; i++) {
      const SpecListRelation *r = &pair->sync.relations[i];
      SpecPlaceResolution res;
      if (!spec_resolve_place_at(&c->refl, or_empty(r->place), b->anchor, &res)) {
        continue;
      }
      SomStrList paths;
      spec_expand_pattern(bp, res.path, &paths);
      for (size_t k = 0; k < paths.len; k++) {
        char *key = path_key(c, bp, b->anchor, paths.items[k]);
        if (strcmp(res.kind, SPEC_PLACE_KIND_LIST) == 0) {
          som_map_set(&list_rel, key, or_empty(r->relation));
          som_map_set(&list_where, key, or_empty(r->where));
        } else if (strcmp(res.kind, SPEC_PLACE_KIND_FORM_FIELD) == 0) {
          char *fk = scat(key, "#", or_empty(spec_place_resolution_field(&res)),
                          NULL);
          som_map_set(&field_rel, fk, or_empty(r->relation));
          free(fk);
        }
        free(key);
      }
      som_strlist_free(&paths);
      spec_place_resolution_free(&res);
    }
  }
  /* A relation stated for a form field is the same for every element: match
   * it by its key with item ids dropped. */
  SomMap field_rel_by_shape;
  som_map_init(&field_rel_by_shape);
  for (size_t i = 0; i < field_rel.len; i++) {
    char *shape = set_shape(field_rel.entries[i].key);
    som_map_set(&field_rel_by_shape, shape, field_rel.entries[i].val);
    free(shape);
  }
  SetPlaces held;
  places_of(c, bp, pair->has_sync ? &pair->sync.held_here : NULL, b->anchor,
            &held);
#define IS_HELD(bp_path, fld) is_held(&held, (bp_path), (fld))

  /* Elements. */
  SomStrList one_sided;
  som_strlist_init(&one_sided);
  SomMap item_keys;
  som_map_init(&item_keys);
  for (size_t i = 0; i < b->items.len; i++) set_add(&item_keys, b->items.entries[i].key);
  for (size_t i = 0; i < d->items.len; i++) set_add(&item_keys, d->items.entries[i].key);
  for (size_t i = 0; i < item_keys.len; i++) {
    const char *k = item_keys.entries[i].key;
    if (k[0] == '\0') continue;
    int in_b = set_has(&b->items, k);
    int in_d = set_has(&d->items, k);
    if (in_b == in_d) continue;
    int beneath = 0;
    for (size_t o = 0; o < one_sided.len && !beneath; o++) {
      beneath = beneath_path(k, one_sided.items[o]);
    }
    if (beneath) continue;
    som_strlist_push_copy(&one_sided, k);
    const char *bracket = strrchr(k, '[');
    char *parent_list;
    if (bracket != NULL) {
      parent_list = som_strdup_n(k, (size_t)(bracket - k));
    } else {
      const char *slash = strrchr(k, '/');
      parent_list = slash != NULL ? som_strdup_n(k, (size_t)(slash - k))
                                  : som_strdup("");
    }
    const char *rel = som_map_get(&list_rel, parent_list);
    const char *where = som_map_get(&list_where, parent_list);
    const char *relation = rel != NULL ? rel : "equal";
    const char *item_path = in_b ? som_map_get(&b->items, k) : som_map_get(&d->items, k);
    const SpecDocument *doc = in_b ? bp : dt;
    if (rel != NULL && has_text(where)) {
      SpecPlaceFilter flt;
      if (spec_place_filter_try_parse(where, &flt)) {
        if (has_text(flt.field)) {
          SomStrList values;
          own_values(c, doc, item_path, flt.field, &values);
          if (!spec_place_filter_matches_list(&flt, &values)) relation = "equal";
          som_strlist_free(&values);
        }
        spec_place_filter_free(&flt);
      }
    }
    char *id;
    if (bracket != NULL) {
      size_t n = strlen(k);
      id = som_strdup_n(bracket + 1, n - (size_t)(bracket - k) - 2);
    } else {
      const char *slash = strrchr(k, '/');
      id = som_strdup(slash != NULL ? slash + 1 : k);
    }
    char *held_path = in_b ? som_strdup(item_path) : path_on(b, k);
    int held_here = IS_HELD(held_path, "");
    char *key = scat("i:", k, NULL);
    if (in_d && strcmp(relation, "subset") == 0) {
      emit(c, pair, order, b, d, SPEC_SYNC_CODE_SHARED_ELEMENT_MAY_BE_ADDED, key,
           scat(id, " is only in ", d->name, "; under subset it may be added to ",
                b->name, NULL),
           held_here, "", NULL, som_strdup(id), SPEC_SYNC_RESOLUTION_INFO);
    } else if (in_d) {
      emit(c, pair, order, b, d, SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING, key,
           scat(id, " is in ", d->name, " and missing in ", b->name, NULL),
           held_here, "", NULL, som_strdup(id), -1);
    } else if (strcmp(relation, "superset") != 0) {
      emit(c, pair, order, b, d, SPEC_SYNC_CODE_SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
           key, scat(id, " is only in ", b->name, "; ", d->name, " removed it", NULL),
           held_here, "", som_strdup(id), NULL, -1);
    }
    free(key);
    free(held_path);
    free(id);
    free(parent_list);
  }
  som_map_free(&item_keys);

  /* Values. */
  SomMap value_keys;
  som_map_init(&value_keys);
  for (size_t i = 0; i < b->values_len; i++) set_add(&value_keys, b->values[i].key);
  for (size_t i = 0; i < d->values_len; i++) set_add(&value_keys, d->values[i].key);
  for (size_t i = 0; i < value_keys.len; i++) {
    const char *k = value_keys.entries[i].key;
    char *rel_key = spec_set_strip_kind(k);
    int beneath = 0;
    for (size_t o = 0; o < one_sided.len && !beneath; o++) {
      beneath = under_path(rel_key, one_sided.items[o]);
    }
    if (beneath) {
      free(rel_key);
      continue;
    }
    const SpecSetValue *vb = spec_set_side_value(b, k);
    const SpecSetValue *vd = spec_set_side_value(d, k);
    const FormFieldSpec *spec = NULL;
    const char *fld = "";
    const char *b_value = "";
    const char *d_value = "";
    if (vb != NULL) {
      spec = vb->spec;
      fld = vb->field;
      b_value = vb->value;
    }
    if (vd != NULL) {
      if (spec == NULL) spec = vd->spec;
      if (fld[0] == '\0') fld = vd->field;
      d_value = vd->value;
    }
    char *held_path = vb != NULL ? som_strdup(vb->path) : path_on(b, rel_key);
    free(rel_key);
    int held_here = IS_HELD(held_path, fld);
    free(held_path);
    if (spec != NULL && spec->multiple && spec->refers_to.len > 0) {
      char *shape = set_shape(k + 2);
      const char *relation = som_map_get(&field_rel_by_shape, shape);
      if (relation == NULL) relation = "equal";
      free(shape);
      SomStrList ib, idd, minus;
      spec_link_ids(b_value, &ib);
      spec_link_ids(d_value, &idd);
      sorted_minus(&idd, &ib, &minus);
      for (size_t m = 0; m < minus.len; m++) {
        const char *x = minus.items[m];
        int subset = strcmp(relation, "subset") == 0;
        emit(c, pair, order, b, d,
             subset ? SPEC_SYNC_CODE_SHARED_ELEMENT_MAY_BE_ADDED
                    : SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING,
             k, scat(x, " is named in ", d->name, " and not in ", b->name, NULL),
             held_here, fld, b_value[0] != '\0' ? som_strdup(b_value) : NULL,
             som_strdup(x), subset ? SPEC_SYNC_RESOLUTION_INFO : -1);
      }
      som_strlist_free(&minus);
      if (strcmp(relation, "superset") != 0) {
        sorted_minus(&ib, &idd, &minus);
        for (size_t m = 0; m < minus.len; m++) {
          const char *x = minus.items[m];
          emit(c, pair, order, b, d,
               SPEC_SYNC_CODE_SHARED_ELEMENT_ONLY_IN_BLUEPRINT, k,
               scat(x, " is named only in ", b->name, NULL), held_here, fld,
               som_strdup(x), d_value[0] != '\0' ? som_strdup(d_value) : NULL,
               -1);
        }
        som_strlist_free(&minus);
      }
      som_strlist_free(&ib);
      som_strlist_free(&idd);
      continue;
    }
    if (b_value[0] == '\0' && d_value[0] == '\0') continue;
    if (spec_set_same_typed(b_value, d_value, spec)) continue;
    char *what = fld[0] == '\0' ? som_strdup("the value")
                                : scat("form field \"", fld, "\"", NULL);
    SpecSyncCode code;
    char *message;
    if (b_value[0] == '\0') {
      code = SPEC_SYNC_CODE_SHARED_VALUE_MISSING;
      message = scat(what, " is filled in ", d->name, " and empty in ", b->name,
                     NULL);
    } else if (d_value[0] == '\0') {
      code = SPEC_SYNC_CODE_SHARED_VALUE_ONLY_IN_BLUEPRINT;
      message = scat(what, " is filled only in ", b->name, "; ", d->name,
                     " emptied it", NULL);
    } else {
      code = SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS;
      char *base = scat(what, " differs: \"", b_value, "\" in ", b->name,
                        ", \"", d_value, "\" in ", d->name, NULL);
      message = held_here ? scat(base, " (held in ", b->name, ")", NULL)
                          : som_strdup(base);
      free(base);
    }
    free(what);
    emit(c, pair, order, b, d, code, k, message, held_here, fld, NULL, NULL, -1);
  }
#undef IS_HELD
  som_map_free(&value_keys);
  som_strlist_free(&one_sided);
  set_places_free(&held);
  som_map_free(&field_rel_by_shape);
  som_map_free(&list_rel);
  som_map_free(&list_where);
  som_map_free(&field_rel);
}

void spec_set_check_compare_pair(SpecSetCheck *c, const SpecSyncPair *pair,
                                 size_t order) {
  const SpecDocumentSet *set = c->set;
  const char *bp_name = spec_document_set_name_of(set, set->blueprint_root);
  const char *dt_name = spec_document_set_name_of(set, pair->detail_root);
  if (bp_name == NULL || dt_name == NULL) return; /* not started */
  const SpecDocument *bp = spec_document_set_get(set, bp_name);
  const SpecDocument *dt = spec_document_set_get(set, dt_name);

  SomMap bp_anchors, dt_anchors;
  som_map_init(&bp_anchors);
  som_map_init(&dt_anchors);
  SomStrList key_order;
  som_strlist_init(&key_order);
  SomStrList anchors;
  spec_expand_pattern(bp, pair->blueprint_anchor, &anchors);
  for (size_t i = 0; i < anchors.len; i++) {
    char *k = spec_set_check_anchor_key(c, bp, anchors.items[i]);
    if (!set_has(&bp_anchors, k)) som_strlist_push_copy(&key_order, k);
    som_map_set(&bp_anchors, k, anchors.items[i]);
    free(k);
  }
  som_strlist_free(&anchors);
  spec_expand_pattern(dt, pair->detail_anchor, &anchors);
  int any = 0;
  for (size_t i = 0; i < anchors.len; i++) {
    char *k = spec_set_check_anchor_key(c, dt, anchors.items[i]);
    som_map_set(&dt_anchors, k, anchors.items[i]);
    free(k);
  }
  som_strlist_free(&anchors);
  /* A pair the Phase 3 document has not written yet is not started, never
   * findings. */
  for (size_t i = 0; i < dt_anchors.len && !any; i++) {
    any = spec_document_has_values_under(dt, dt_anchors.entries[i].val);
  }
  if (!any) {
    som_strlist_push_copy(&c->not_started_pairs, pair->section_id);
  } else {
    /* Nested pairs are compared on their own. */
    int nested_done = 0;
    SomStrList bp_nested_all, dt_nested_all;
    som_strlist_init(&bp_nested_all);
    som_strlist_init(&dt_nested_all);
    for (size_t ki = 0; ki < key_order.len; ki++) {
      const char *k = key_order.items[ki];
      const char *ba = som_map_get(&bp_anchors, k);
      const char *da = som_map_get(&dt_anchors, k);
      if (da == NULL) continue; /* the outer list reports it */
      if (!nested_done) {
        nested_done = 1;
        for (size_t p = 0; p < set->pairs_len; p++) {
          const SpecSyncPair *other = &set->pairs[p];
          if (other == pair) continue;
          SomStrList ex;
          spec_expand_pattern(bp, other->blueprint_anchor, &ex);
          strlist_extend(&bp_nested_all, &ex);
          som_strlist_free(&ex);
          if (strcmp(other->detail_root, pair->detail_root) == 0) {
            spec_expand_pattern(dt, other->detail_anchor, &ex);
            strlist_extend(&dt_nested_all, &ex);
            som_strlist_free(&ex);
          }
        }
      }
      SomStrList bp_nested, dt_nested;
      som_strlist_init(&bp_nested);
      som_strlist_init(&dt_nested);
      for (size_t i = 0; i < bp_nested_all.len; i++) {
        if (beneath_path(bp_nested_all.items[i], ba)) {
          som_strlist_push_copy(&bp_nested, bp_nested_all.items[i]);
        }
      }
      for (size_t i = 0; i < dt_nested_all.len; i++) {
        if (beneath_path(dt_nested_all.items[i], da)) {
          som_strlist_push_copy(&dt_nested, dt_nested_all.items[i]);
        }
      }
      SpecSetSide *b = spec_set_check_collect(c, bp_name, bp, set->blueprint_root,
                                              ba, pair, &bp_nested);
      SpecSetSide *d = spec_set_check_collect(c, dt_name, dt, pair->detail_root,
                                              da, pair, &dt_nested);
      compare(c, pair, order, b, d, bp, dt);
      spec_set_side_release(b);
      spec_set_side_release(d);
      som_strlist_free(&bp_nested);
      som_strlist_free(&dt_nested);
    }
    som_strlist_free(&bp_nested_all);
    som_strlist_free(&dt_nested_all);
  }
  som_strlist_free(&key_order);
  som_map_free(&bp_anchors);
  som_map_free(&dt_anchors);
}


/* ---- unmarkable derived changes ----------------------------------------------- */

/* A place of the document `name` at `path` / `field` ("" none), `value`
 * taken (NULL: none). */
static void doc_place(const SpecSetCheck *c, const char *name, const char *path,
                      const char *field, char *value, int pending,
                      SpecSyncPlace *out) {
  out->document = som_strdup(name);
  out->root = som_strdup(root_seg(c, spec_document_set_root_of(c->set, name)));
  out->path = som_strdup(path);
  out->field = som_strdup(field);
  out->value = value;
  out->pending_marks = pending;
}

/* Lists every change `deriveFields` would write in a document under review
 * that cannot be marked exactly: left for the agent. */
static void unmarkable_scan(SpecSetCheck *c, size_t order) {
  SomStrList names;
  spec_document_set_names(c->set, &names);
  for (size_t i = 0; i < names.len; i++) {
    const char *name = names.items[i];
    const SpecDocument *doc = spec_document_set_get(c->set, name);
    SpecDeriveOptions options;
    memset(&options, 0, sizeof(options));
    options.marked = 1;
    SpecDeriveResult derived;
    spec_derive_fields_dry_run(c->set->model, doc, &options, &derived);
    for (size_t u = 0; u < derived.unresolved.len; u++) {
      const SpecValidationError *e = &derived.unresolved.items[u];
      if (strcmp(e->code, SPEC_VALIDATION_CODE_UNMARKABLE) != 0) continue;
      SpecSyncFinding f;
      memset(&f, 0, sizeof(f));
      f.code = SPEC_SYNC_CODE_UNMARKABLE;
      f.pair = som_strdup("");
      doc_place(c, name, e->path, "", NULL, 0, &f.blueprint);
      spec_sync_place_copy(&f.detail, &f.blueprint);
      f.holder = SPEC_SYNC_HOLDER_DETAIL;
      f.resolution = SPEC_SYNC_RESOLUTION_AGENT;
      f.message = scat(e->message, " (in ", name, ")", NULL);
      check_add(c, order, scat(name, " ", e->path, NULL), &f, NULL, NULL);
    }
    spec_derive_result_free(&derived);
  }
  som_strlist_free(&names);
}

/* ---- pending marks ---------------------------------------------------------------- */

static void pending_one(SpecSetCheck *c, size_t order, const char *name,
                        const char *path, const char *fld, const char *raw) {
  if (!spec_set_is_pending(raw)) return;
  SpecSyncFinding f;
  memset(&f, 0, sizeof(f));
  f.code = SPEC_SYNC_CODE_PENDING_REVIEW;
  f.pair = som_strdup("");
  doc_place(c, name, path, fld, spec_set_reviewed(raw), 1, &f.blueprint);
  spec_sync_place_copy(&f.detail, &f.blueprint);
  f.holder = SPEC_SYNC_HOLDER_DETAIL;
  f.resolution = SPEC_SYNC_RESOLUTION_INFO;
  char *what = fld[0] == '\0' ? som_strdup("the value")
                              : scat("form field \"", fld, "\"", NULL);
  f.message = scat(what, " at ", path, " in ", name,
                   " holds pending change marks", NULL);
  free(what);
  check_add(c, order, scat(name, " ", path, " ", fld, NULL), &f, NULL, NULL);
}

/* Lists every value of every document that holds pending change marks. */
static void pending_scan(SpecSetCheck *c, size_t order) {
  SomStrList names;
  spec_document_set_names(c->set, &names);
  for (size_t i = 0; i < names.len; i++) {
    const char *name = names.items[i];
    const SpecDocument *doc = spec_document_set_get(c->set, name);
    SomStrList paths;
    spec_document_content_paths(doc, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      pending_one(c, order, name, paths.items[k], "",
                  or_empty(spec_document_content(doc, paths.items[k])));
    }
    som_strlist_free(&paths);
    spec_document_form_paths(doc, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      SomStrList fields;
      spec_document_form_field_names(doc, paths.items[k], &fields);
      for (size_t f = 0; f < fields.len; f++) {
        pending_one(c, order, name, paths.items[k], fields.items[f],
                    or_empty(spec_document_form_field(doc, paths.items[k],
                                                      fields.items[f])));
      }
      som_strlist_free(&fields);
    }
    som_strlist_free(&paths);
    spec_document_headline_paths(doc, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      pending_one(c, order, name, paths.items[k], "",
                  or_empty(spec_document_headline(doc, paths.items[k])));
    }
    som_strlist_free(&paths);
  }
  som_strlist_free(&names);
}

/* ---- links across two documents ------------------------------------------------ */

/* One class instance of a document: its path and class. */
typedef struct {
  char *path;
  const SpecClass *cls;
} SetInstance;

typedef struct {
  SetInstance *items;
  size_t len;
  size_t cap;
} SetInstances;

static void walk_instances(const SpecReflection *refl, const SpecDocument *doc,
                           const SpecClass *cls, const char *path,
                           const SomStrList *on_path, SetInstances *out) {
  if (out->len == out->cap) {
    out->cap = out->cap ? out->cap * 2 : 16;
    out->items = (SetInstance *)realloc(out->items, out->cap * sizeof(SetInstance));
  }
  out->items[out->len].path = som_strdup(path);
  out->items[out->len].cls = cls;
  out->len++;
  for (size_t i = 0; i < cls->fields_len; i++) {
    const SpecField *f = &cls->fields[i];
    if (spec_annotations_have(&f->annotations, "Reference")) continue;
    char *member = scat(path, "/", spec_reflection_field_segment(f), NULL);
    if (str_eq(f->kind, SPEC_FIELD_KIND_LIST) && f->element_is_complex) {
      const SpecClass *el = spec_model_class_named(refl->model, f->element_type);
      const SomStrList *items =
          el != NULL ? spec_document_list_items(doc, member) : NULL;
      for (size_t k = 0; items != NULL && k < items->len; k++) {
        SomStrList none;
        som_strlist_init(&none);
        walk_instances(refl, doc, el, items->items[k], &none, out);
      }
    } else if (str_eq(f->kind, SPEC_FIELD_KIND_COMPLEX) ||
               str_eq(f->kind, SPEC_FIELD_KIND_SECTION)) {
      SomBuf tb;
      som_buf_init(&tb);
      for (const char *t = or_empty(f->type); *t != '\0'; t++) {
        if (*t != '?') som_buf_putc(&tb, *t);
      }
      char *type = som_buf_take(&tb);
      const SpecClass *child = spec_model_class_named(refl->model, type);
      free(type);
      if (child != NULL && !som_strlist_contains(on_path, child->name)) {
        SomStrList next;
        som_strlist_copy(&next, on_path);
        if (!som_strlist_contains(&next, cls->name)) {
          som_strlist_push_copy(&next, cls->name);
        }
        walk_instances(refl, doc, child, member, &next, out);
        som_strlist_free(&next);
      }
    }
    free(member);
  }
}

static void instances_free(SetInstances *l) {
  for (size_t i = 0; i < l->len; i++) free(l->items[i].path);
  free(l->items);
  memset(l, 0, sizeof(*l));
}

/* The document a registry class is read in: the one whose root details it,
 * else the Blueprint ("" for none). Owned. */
static char *registry_document(SpecSetCheck *c, const char *section_id) {
  const char *hit = som_map_get(&c->cache->registry_docs, section_id);
  if (hit != NULL) return som_strdup(hit);
  SomMap classes;
  som_map_init(&classes);
  for (size_t i = 0; i < c->set->model->classes_len; i++) {
    const SpecClass *cls = c->set->model->classes[i].cls;
    if (str_eq(cls->section_id, section_id)) set_add(&classes, cls->name);
  }
  char *blueprint = som_strdup("");
  char *found = NULL;
  SomStrList names;
  spec_document_set_names(c->set, &names);
  for (size_t i = 0; i < names.len && found == NULL; i++) {
    const char *root = spec_document_set_root_of(c->set, names.items[i]);
    SpecSetCheckCache *k = c->cache;
    ReachEntry *reach = NULL;
    for (size_t r = 0; r < k->reach_len; r++) {
      if (strcmp(k->reach[r].root, root) == 0) reach = &k->reach[r];
    }
    if (reach == NULL) {
      k->reach = (ReachEntry *)realloc(k->reach,
                                       (k->reach_len + 1) * sizeof(ReachEntry));
      reach = &k->reach[k->reach_len++];
      reach->root = som_strdup(root);
      spec_reflection_reachable_class_names(&c->refl, root, &reach->names);
    }
    int reaches = 0;
    for (size_t r = 0; r < reach->names.len && !reaches; r++) {
      reaches = set_has(&classes, reach->names.items[r]);
    }
    if (!reaches) continue;
    if (strcmp(root, c->set->blueprint_root) == 0) {
      free(blueprint);
      blueprint = som_strdup(names.items[i]);
    } else {
      found = som_strdup(names.items[i]);
    }
  }
  som_strlist_free(&names);
  som_map_free(&classes);
  char *out = blueprint;
  if (found != NULL) {
    free(blueprint);
    out = found;
  }
  som_map_set(&c->cache->registry_docs, section_id, out);
  return out;
}

/* The identity of `item` as `target` (`<SID>.<field>`) names it: 1 and
 * `*out` (owned), or 0. */
static int identity(SpecSetCheck *c, const SpecDocument *doc, const char *item,
                    const char *target, char **out) {
  const char *dot = strchr(target, '.');
  const char *fld = dot != NULL ? dot + 1 : target;
  if (strcmp(fld, SPEC_SECTION_ID_SLOT) == 0) {
    *out = spec_set_check_item_id(c, doc, item);
    return 1;
  }
  SomStrList values;
  own_values(c, doc, item, fld, &values);
  int ok = values.len > 0;
  if (ok) *out = som_strdup(values.items[0]);
  som_strlist_free(&values);
  return ok;
}

/* The entry of `doc` that `refers_to` names `id` by. Owned, NULL for none. */
static char *entry_of(SpecSetCheck *c, const SpecDocument *doc,
                      const SomStrList *refers_to, const char *id) {
  SpecSetCheckCache *k = c->cache;
  for (size_t t = 0; t < refers_to->len; t++) {
    const char *target = refers_to->items[t];
    char *key = doc_key(doc, target);
    size_t at = 0;
    while (at < k->entries_keys.len && strcmp(k->entries_keys.items[at], key) != 0) {
      at++;
    }
    if (at == k->entries_keys.len) {
      SomMap index;
      som_map_init(&index);
      char *sid = before_first(target, '.');
      SomStrList lists;
      spec_document_list_paths(doc, &lists);
      for (size_t l = 0; l < lists.len; l++) {
        const SomStrList *items = spec_document_list_items(doc, lists.items[l]);
        for (size_t i = 0; items != NULL && i < items->len; i++) {
          const char *item = items->items[i];
          SpecResolution r;
          int ok = 0;
          if (spec_reflection_resolve(&c->refl, item, &r)) {
            ok = r.target_class != NULL && str_eq(r.target_class->section_id, sid);
            spec_resolution_free(&r);
          }
          if (!ok) continue;
          char *name = NULL;
          if (identity(c, doc, item, target, &name)) {
            if (!set_has(&index, name)) som_map_set(&index, name, item);
            free(name);
          }
        }
      }
      som_strlist_free(&lists);
      free(sid);
      k->entries = (SomMap *)realloc(k->entries, (at + 1) * sizeof(SomMap));
      k->entries[at] = index;
      som_strlist_push_copy(&k->entries_keys, key);
    }
    free(key);
    const char *hit = som_map_get(&k->entries[at], id);
    if (hit != NULL) return som_strdup(hit);
  }
  return NULL;
}

/* The nearest list item at or above `path`. Owned, NULL for none. */
static char *nearest_item(SpecSetCheck *c, const char *path) {
  char *p = som_strdup(path);
  for (;;) {
    if (is_item(c, p)) return p;
    char *slash = strrchr(p, '/');
    if (slash == NULL) {
      free(p);
      return NULL;
    }
    *slash = '\0';
  }
}

/* One detail element of a cross summary: its item and id. */
typedef struct {
  char *item;
  char *id;
} SetElement;

typedef struct {
  SetElement *items;
  size_t len;
} SetElements;

static void elements_free(SetElements *e) {
  for (size_t i = 0; i < e->len; i++) {
    free(e->items[i].item);
    free(e->items[i].id);
  }
  free(e->items);
  memset(e, 0, sizeof(*e));
}

/* The detail elements of a cross summary: 1 with the document name
 * (borrowed), document and elements, 0 when the detail is not started or
 * does not resolve. */
static int cross_detail(SpecSetCheck *c, const SpecSummaryOf *s,
                        const char **name_out, const SpecDocument **doc_out,
                        SetElements *out) {
  memset(out, 0, sizeof(*out));
  const char *name = spec_document_set_name_of(c->set, or_empty(s->document));
  if (name == NULL) return 0; /* not started */
  const SpecDocument *doc = spec_document_set_get(c->set, name);
  const char *seg = root_seg(c, spec_document_set_root_of(c->set, name));
  const char *detail = or_empty(s->detail);
  const char *slash = strchr(detail, '/');
  SpecPlaceResolution r;
  int resolved = 0;
  if (slash == NULL) {
    resolved = spec_resolve_place_at(&c->refl, detail, seg, &r);
  } else {
    char *head_text = som_strdup_n(detail, (size_t)(slash - detail));
    SpecPlaceResolution head;
    if (spec_resolve_place_at(&c->refl, head_text, seg, &head)) {
      char *scope = strcmp(head.kind, SPEC_PLACE_KIND_LIST) == 0
                        ? scat(head.path, "-*", NULL)
                        : som_strdup(head.path);
      SomStrList concrete;
      spec_expand_pattern(doc, scope, &concrete);
      if (concrete.len > 0) {
        SpecPlace p;
        if (spec_place_try_parse(slash + 1, &p)) {
          SpecPlaceError perr;
          spec_place_error_init(&perr);
          resolved = spec_place_resolve(&p, &c->refl, concrete.items[0], &r, &perr);
          spec_place_error_free(&perr);
          spec_place_free(&p);
        }
      }
      som_strlist_free(&concrete);
      free(scope);
      spec_place_resolution_free(&head);
    }
    free(head_text);
  }
  if (!resolved) return 0;
  if (strcmp(r.kind, SPEC_PLACE_KIND_LIST) != 0) {
    spec_place_resolution_free(&r);
    return 0;
  }
  SomMap seen; /* item -> index */
  som_map_init(&seen);
  SomStrList lists;
  spec_expand_pattern(doc, r.path, &lists);
  for (size_t l = 0; l < lists.len; l++) {
    const SomStrList *items = spec_document_list_items(doc, lists.items[l]);
    for (size_t i = 0; items != NULL && i < items->len; i++) {
      const char *item = items->items[i];
      char *id = spec_set_check_item_id(c, doc, item);
      const char *at = som_map_get(&seen, item);
      if (at != NULL) {
        size_t idx = (size_t)strtoull(at, NULL, 10);
        free(out->items[idx].id);
        out->items[idx].id = id;
        continue;
      }
      char num[32];
      snprintf(num, sizeof(num), "%zu", out->len);
      som_map_set(&seen, item, num);
      out->items = (SetElement *)realloc(out->items,
                                         (out->len + 1) * sizeof(SetElement));
      out->items[out->len].item = som_strdup(item);
      out->items[out->len].id = id;
      out->len++;
    }
  }
  som_strlist_free(&lists);
  som_map_free(&seen);
  spec_place_resolution_free(&r);
  *name_out = name;
  *doc_out = doc;
  return 1;
}

/* A place of the document `name` ("" none); `value` taken (NULL: none). */
static void place_of(const SpecSetCheck *c, const char *name, const char *path,
                     const char *fld, char *value, SpecSyncPlace *out) {
  out->document = name[0] == '\0' ? NULL : som_strdup(name);
  out->root = som_strdup(name[0] == '\0'
                             ? ""
                             : root_seg(c, spec_document_set_root_of(c->set, name)));
  out->path = som_strdup(path);
  out->field = som_strdup(fld);
  out->value = value;
  out->pending_marks = 0;
}

/* Adds one cross finding, taking the places and the message. */
static void cross(SpecSetCheck *c, size_t order, SpecSyncCode code,
                  const char *pair, SpecSyncPlace *here, SpecSyncPlace *there,
                  char *message) {
  char *key = scat(here->document != NULL ? here->document : "None", " ",
                   here->path, " ", here->field, " ",
                   spec_sync_place_value_or(there), NULL);
  SpecSyncFinding f;
  memset(&f, 0, sizeof(f));
  f.code = code;
  f.pair = som_strdup(pair);
  f.blueprint = *here;
  f.detail = *there;
  memset(here, 0, sizeof(*here));
  memset(there, 0, sizeof(*there));
  f.holder = SPEC_SYNC_HOLDER_DETAIL;
  f.resolution = SPEC_SYNC_RESOLUTION_AGENT;
  f.message = message;
  check_add(c, order, key, &f, NULL, NULL);
}

static char *list_of_elements(const SetElements *e) {
  return e->len > 0 ? before_last_or_all(e->items[0].item, '-') : som_strdup("");
}

/* A value read at a place: its path, value and field (all owned). */
typedef struct {
  char *path;
  char *value;
  char *field;
} SetValueAt;

static void value_at_free(SetValueAt *v) {
  free(v->path);
  free(v->value);
  free(v->field);
}

/* The value of `place` under the concrete `anchor`: 1 and `*out`, or 0. */
static int value_at(SpecSetCheck *c, const SpecDocument *doc, const char *place,
                    const char *anchor, SetValueAt *out) {
  SpecPlaceResolution r;
  if (!spec_resolve_place_at(&c->refl, place, anchor, &r)) return 0;
  SomStrList paths;
  spec_expand_pattern(doc, r.path, &paths);
  int ok = paths.len == 1;
  if (ok) {
    const char *p = paths.items[0];
    const char *field = or_empty(spec_place_resolution_field(&r));
    char *raw;
    if (strcmp(r.kind, SPEC_PLACE_KIND_FORM_FIELD) == 0) {
      raw = som_strdup(or_empty(spec_document_form_field(doc, p, field)));
    } else if (strcmp(r.kind, SPEC_PLACE_KIND_CONTENT) == 0) {
      raw = som_strdup(or_empty(spec_document_content(doc, p)));
    } else if (strcmp(r.kind, SPEC_PLACE_KIND_HEADLINE) == 0) {
      raw = som_strdup(or_empty(spec_document_headline(doc, p)));
    } else if (strcmp(r.kind, SPEC_PLACE_KIND_SECTION_ID) == 0 && is_item(c, p)) {
      raw = spec_set_check_item_id(c, doc, p);
    } else {
      raw = som_strdup("");
    }
    out->path = som_strdup(p);
    out->value = spec_set_reviewed(raw);
    out->field = som_strdup(field);
    free(raw);
  }
  som_strlist_free(&paths);
  spec_place_resolution_free(&r);
  return ok;
}

static void cross_summary_rows(SpecSetCheck *c, size_t order, const char *pair,
                               const char *name, const SpecDocument *doc,
                               const char *lst, const SpecSummaryOf *s) {
  const char *d_name = NULL;
  const SpecDocument *d_doc = NULL;
  SetElements elements;
  if (!cross_detail(c, s, &d_name, &d_doc, &elements)) return;
  SomMap by_id;
  som_map_init(&by_id);
  for (size_t i = 0; i < elements.len; i++) {
    som_map_set(&by_id, elements.items[i].id, elements.items[i].item);
  }
  char *list_of = list_of_elements(&elements);
  const char *detail = or_empty(s->detail);
  SomMap named; /* id -> row */
  som_map_init(&named);
  const SomStrList *rows = spec_document_list_items(doc, lst);
  for (size_t ri = 0; rows != NULL && ri < rows->len; ri++) {
    const char *row = rows->items[ri];
    SomStrList ids;
    if (!has_text(s->match)) {
      som_strlist_init(&ids);
      som_strlist_push(&ids, spec_set_check_item_id(c, doc, row));
    } else {
      SetValueAt v;
      if (value_at(c, doc, s->match, row, &v)) {
        spec_link_ids(v.value, &ids);
        value_at_free(&v);
      } else {
        som_strlist_init(&ids);
      }
    }
    for (size_t ii = 0; ii < ids.len; ii++) {
      const char *id = ids.items[ii];
      const char *target_c = som_map_get(&by_id, id);
      if (target_c == NULL) {
        SpecSyncPlace here, there;
        place_of(c, name, row, "", som_strdup(id), &here);
        place_of(c, d_name, list_of, "", som_strdup(id), &there);
        cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here, &there,
              scat("the summary row names ", id, ", which is no element of ",
                   detail, " in ", d_name, NULL));
        continue;
      }
      char *target = som_strdup(target_c);
      const char *prev = som_map_get(&named, id);
      if (prev != NULL) {
        SpecSyncPlace here, there;
        place_of(c, name, row, "", som_strdup(id), &here);
        place_of(c, d_name, target, "", som_strdup(id), &there);
        cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here, &there,
              scat("the summary row names ", id, ", which ", prev,
                   " names already", NULL));
        free(target);
        continue;
      }
      som_map_set(&named, id, row);
      for (size_t rp = 0; rp < s->repeats.len; rp++) {
        const char *mine_place = s->repeats.items[rp].key;
        const char *theirs_place = s->repeats.items[rp].value;
        SetValueAt mine, theirs;
        int has_mine = value_at(c, doc, mine_place, row, &mine);
        int has_theirs = value_at(c, d_doc, theirs_place, target, &theirs);
        if (has_mine && has_theirs && mine.value[0] != '\0' &&
            strcmp(mine.value, theirs.value) != 0) {
          SpecSyncPlace here, there;
          place_of(c, name, mine.path, mine.field, som_strdup(mine.value), &here);
          place_of(c, d_name, theirs.path, theirs.field, som_strdup(theirs.value),
                   &there);
          cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here,
                &there,
                scat(mine_place, " repeats ", theirs_place, " of ", id, " as \"",
                     mine.value, "\", but ", d_name, " holds \"", theirs.value,
                     "\"", NULL));
        }
        if (has_mine) value_at_free(&mine);
        if (has_theirs) value_at_free(&theirs);
      }
      free(target);
    }
    som_strlist_free(&ids);
  }
  if (str_eq(s->relation, "equal")) {
    for (size_t i = 0; i < elements.len; i++) {
      const SetElement *e = &elements.items[i];
      if (set_has(&named, e->id)) continue;
      SpecSyncPlace here, there;
      place_of(c, name, lst, "", NULL, &here);
      place_of(c, d_name, e->item, "", som_strdup(e->id), &there);
      cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here, &there,
            scat("the detail element ", e->id, " of ", d_name,
                 " is named by no row of ", lst, " (relation: equal)", NULL));
    }
  }
  som_map_free(&named);
  free(list_of);
  som_map_free(&by_id);
  elements_free(&elements);
}

static void cross_summary_field(SpecSetCheck *c, size_t order, const char *pair,
                                const char *name, const SpecDocument *doc,
                                const char *form, const FormFieldSpec *ff) {
  const char *raw = spec_document_form_field(doc, form, ff->name);
  if (raw == NULL || ff->summary_of == NULL) return;
  const SpecSummaryOf *s = ff->summary_of;
  const char *d_name = NULL;
  const SpecDocument *d_doc = NULL;
  SetElements elements;
  if (!cross_detail(c, s, &d_name, &d_doc, &elements)) return;
  SomMap known, seen;
  som_map_init(&known);
  som_map_init(&seen);
  for (size_t i = 0; i < elements.len; i++) set_add(&known, elements.items[i].id);
  char *list_of = list_of_elements(&elements);
  char *reviewed = spec_set_reviewed(raw);
  SomStrList ids;
  spec_link_ids(reviewed, &ids);
  free(reviewed);
  for (size_t i = 0; i < ids.len; i++) {
    const char *id = ids.items[i];
    int fresh = !set_has(&seen, id);
    set_add(&seen, id);
    int is_known = set_has(&known, id);
    if (!is_known || !fresh) {
      char *message =
          is_known ? scat("form field \"", ff->name, "\" names ", id, " twice", NULL)
                   : scat("form field \"", ff->name, "\" names ", id,
                          ", which is no element of ", or_empty(s->detail), " in ",
                          d_name, NULL);
      SpecSyncPlace here, there;
      place_of(c, name, form, ff->name, som_strdup(id), &here);
      place_of(c, d_name, list_of, "", som_strdup(id), &there);
      cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here, &there,
            message);
    }
  }
  som_strlist_free(&ids);
  if (str_eq(s->relation, "equal")) {
    for (size_t i = 0; i < elements.len; i++) {
      const SetElement *e = &elements.items[i];
      if (set_has(&seen, e->id)) continue;
      SpecSyncPlace here, there;
      place_of(c, name, form, ff->name, NULL, &here);
      place_of(c, d_name, e->item, "", som_strdup(e->id), &there);
      cross(c, order, SPEC_SYNC_CODE_CROSS_SUMMARY_MISMATCH, pair, &here, &there,
            scat("the detail element ", e->id, " of ", d_name,
                 " is not named in \"", ff->name, "\" (relation: equal)", NULL));
    }
  }
  free(list_of);
  som_map_free(&known);
  som_map_free(&seen);
  elements_free(&elements);
}

/* The section id of the class the path reaches. Owned. */
static char *sid_of(const SpecSetCheck *c, const char *p) {
  SpecResolution r;
  char *out = som_strdup("");
  if (spec_reflection_resolve(&c->refl, p, &r)) {
    if (r.target_class != NULL) {
      free(out);
      out = som_strdup(or_empty(r.target_class->section_id));
    }
    spec_resolution_free(&r);
  }
  return out;
}

static void cross_inverse(SpecSetCheck *c, size_t order, const char *pair,
                          const char *name, const SpecDocument *doc,
                          const char *form, const FormFieldSpec *ff) {
  const char *raw = spec_document_form_field(doc, form, ff->name);
  if (raw == NULL || ff->inverse_of == NULL) return;
  char *value = spec_set_reviewed(raw);
  if (value[0] == '\0') {
    free(value);
    return;
  }
  const SpecInverseOf *inv = ff->inverse_of;
  SomStrList bs;
  spec_link_ids(value, &bs);
  free(value);
  SomStrList registries;
  som_strlist_init(&registries);
  for (size_t t = 0; t < ff->refers_to.len; t++) {
    char *r = before_first(ff->refers_to.items[t], '.');
    if (!som_strlist_contains(&registries, r)) {
      som_strlist_push(&registries, r);
    } else {
      free(r);
    }
  }
  char *inv_fields = som_strlist_join(&inv->fields, ", ");
  for (size_t bi = 0; bi < bs.len; bi++) {
    const char *b = bs.items[bi];
    for (size_t ri = 0; ri < registries.len; ri++) {
      const char *registry = registries.items[ri];
      char *other = registry_document(c, registry);
      if (other[0] == '\0' || strcmp(other, name) == 0) {
        free(other);
        continue;
      }
      const SpecDocument *o_doc = spec_document_set_get(c->set, other);
      SomStrList targets;
      som_strlist_init(&targets);
      for (size_t t = 0; t < ff->refers_to.len; t++) {
        char *r = before_first(ff->refers_to.items[t], '.');
        if (strcmp(r, registry) == 0) som_strlist_push_copy(&targets, ff->refers_to.items[t]);
        free(r);
      }
      char *b_path = entry_of(c, o_doc, &targets, b);
      som_strlist_free(&targets);
      if (b_path == NULL) {
        free(other);
        continue;
      }
      for (size_t ei = 0; ei < inv->fields.len; ei++) {
        SpecPlaceResolution r;
        if (!spec_resolve_place_at(&c->refl, inv->fields.items[ei], b_path, &r)) {
          continue;
        }
        const FormFieldSpec *end_ff = r.form_field;
        if (end_ff == NULL) {
          spec_place_resolution_free(&r);
          continue;
        }
        /* This field's entry, named as the other end names it, and read in its
         * own registry document only. */
        SomMap a_classes;
        som_map_init(&a_classes);
        for (size_t t = 0; t < end_ff->refers_to.len; t++) {
          char *sid = before_first(end_ff->refers_to.items[t], '.');
          set_add(&a_classes, sid);
          free(sid);
        }
        char *a = nearest_item(c, form);
        while (a != NULL) {
          char *sid = sid_of(c, a);
          int hit = set_has(&a_classes, sid);
          free(sid);
          if (hit) break;
          char *slash = strrchr(a, '/');
          char *next = NULL;
          if (slash != NULL) {
            *slash = '\0';
            next = nearest_item(c, a);
          }
          free(a);
          a = next;
        }
        som_map_free(&a_classes);
        if (a == NULL) {
          spec_place_resolution_free(&r);
          continue;
        }
        char *a_sid = sid_of(c, a);
        char *a_doc = registry_document(c, a_sid);
        int mine = strcmp(a_doc, name) == 0;
        free(a_doc);
        free(a_sid);
        char *a_id = NULL;
        if (mine) {
          for (size_t t = 0; t < end_ff->refers_to.len && a_id == NULL; t++) {
            char *v = NULL;
            if (identity(c, doc, a, end_ff->refers_to.items[t], &v)) a_id = v;
          }
        }
        if (a_id != NULL) {
          SomStrList ends;
          spec_expand_pattern(o_doc, r.path, &ends);
          const char *fld = or_empty(spec_place_resolution_field(&r));
          int names_back = 0;
          for (size_t p = 0; p < ends.len && !names_back; p++) {
            char *rv = spec_set_reviewed(
                or_empty(spec_document_form_field(o_doc, ends.items[p], fld)));
            SomStrList back;
            spec_link_ids(rv, &back);
            names_back = som_strlist_contains(&back, a_id);
            som_strlist_free(&back);
            free(rv);
          }
          if (!names_back) {
            const char *end_path = ends.len > 0 ? ends.items[0] : b_path;
            SpecSyncPlace here, there;
            place_of(c, name, form, ff->name, som_strdup(b), &here);
            place_of(c, other, end_path, fld, som_strdup(a_id), &there);
            cross(c, order, SPEC_SYNC_CODE_CROSS_INVERSE_MISSING, pair, &here,
                  &there,
                  scat("form field \"", ff->name, "\" in ", name, " names ", b,
                       ", but ", b, " in ", other, " does not name ", a_id,
                       " back (", inv_fields, ")", NULL));
          }
          som_strlist_free(&ends);
          free(a_id);
        }
        free(a);
        spec_place_resolution_free(&r);
      }
      free(b_path);
      free(other);
    }
  }
  free(inv_fields);
  som_strlist_free(&registries);
  som_strlist_free(&bs);
}

void spec_set_check_cross_checks(SpecSetCheck *c, const SomStrList *pairs,
                                 size_t order) {
  SomStrList names;
  spec_document_set_names(c->set, &names);
  for (size_t ni = 0; ni < names.len; ni++) {
    const char *name = names.items[ni];
    const SpecDocument *doc = spec_document_set_get(c->set, name);
    const char *root = spec_document_set_root_of(c->set, name);
    SetInstances inst;
    memset(&inst, 0, sizeof(inst));
    const SpecClass *cls = spec_model_class_named(c->set->model, root);
    if (cls != NULL) {
      SomStrList none;
      som_strlist_init(&none);
      walk_instances(&c->refl, doc, cls, root_seg(c, root), &none, &inst);
    }
    for (size_t i = 0; i < inst.len; i++) {
      const SpecClass *ic = inst.items[i].cls;
      const char *pair_id = has_text(ic->section_id) ? ic->section_id : ic->name;
      if (!spec_set_in_scope(pairs, pair_id)) continue;
      for (size_t fi = 0; fi < ic->fields_len; fi++) {
        const SpecField *f = &ic->fields[fi];
        char *member = scat(inst.items[i].path, "/",
                            spec_reflection_field_segment(f), NULL);
        SpecSummaryOf s;
        if (spec_annotations_summary_of(&f->annotations, &s)) {
          if (has_text(s.document) && str_eq(f->kind, SPEC_FIELD_KIND_LIST)) {
            cross_summary_rows(c, order, pair_id, name, doc, member, &s);
          }
          spec_summary_of_free(&s);
        }
        for (size_t k = 0; k < f->form_fields_len; k++) {
          const FormFieldSpec *ff = &f->form_fields[k];
          if (ff->summary_of != NULL && has_text(ff->summary_of->document)) {
            cross_summary_field(c, order, pair_id, name, doc, member, ff);
          }
          if (ff->inverse_of != NULL && !spec_inverse_of_symmetric(ff->inverse_of)) {
            cross_inverse(c, order, pair_id, name, doc, member, ff);
          }
        }
        free(member);
      }
    }
    instances_free(&inst);
  }
  som_strlist_free(&names);
}

/* ---- the report ----------------------------------------------------------------- */

void spec_sync_report(const SpecDocumentSet *set, const SomStrList *pairs,
                      SpecSyncReport *out) {
  memset(out, 0, sizeof(*out));
  SpecSetCheck c;
  spec_set_check_init(&c, set);
  size_t index = 0;
  for (size_t i = 0; i < set->pairs_len; i++) {
    if (spec_set_in_scope(pairs, set->pairs[i].section_id)) {
      spec_set_check_compare_pair(&c, &set->pairs[i], index);
    }
    index++;
  }
  spec_set_check_cross_checks(&c, pairs, index);
  if (pairs == NULL) {
    pending_scan(&c, index + 1);
    unmarkable_scan(&c, index + 2);
  }
  spec_set_check_sort_out(&c);
  SomStrList names;
  spec_document_set_names(set, &names);
  out->document_findings = (SpecDocumentFindings *)calloc(
      names.len ? names.len : 1, sizeof(SpecDocumentFindings));
  for (size_t i = 0; i < names.len; i++) {
    const SpecDocument *doc = spec_document_set_get(set, names.items[i]);
    SpecDocumentFindings *d = &out->document_findings[i];
    d->name = som_strdup(names.items[i]);
    validate_document(set->model, doc, &d->errors);
    SpecValidationErrors links;
    spec_validate_links(set->model, doc, &links);
    for (size_t k = 0; k < links.len; k++) {
      spec_validation_errors_push(&d->errors, links.items[k].path,
                                  links.items[k].code, links.items[k].message);
    }
    spec_validation_errors_free(&links);
  }
  out->document_findings_len = names.len;
  som_strlist_free(&names);
  out->findings = (SpecSyncFinding *)calloc(c.out_len ? c.out_len : 1,
                                            sizeof(SpecSyncFinding));
  for (size_t i = 0; i < c.out_len; i++) {
    out->findings[i] = c.out[i].finding;
    memset(&c.out[i].finding, 0, sizeof(SpecSyncFinding));
  }
  out->findings_len = c.out_len;
  spec_document_set_missing_roots(set, &out->not_started);
  out->not_started_pairs = c.not_started_pairs;
  som_strlist_init(&c.not_started_pairs);
  spec_set_check_free(&c);
}

/* ---- the global rename ------------------------------------------------------------ */

void spec_rename_error_init(SpecRenameError *e) {
  som_strlist_init(&e->documents);
  e->message = NULL;
}

void spec_rename_error_free(SpecRenameError *e) {
  som_strlist_free(&e->documents);
  free(e->message);
  spec_rename_error_init(e);
}

char *spec_rename_error_display(const SpecRenameError *e) {
  return scat("SpecRenameError: ", or_empty(e->message), NULL);
}

void spec_rename_changes_free(SpecRenameChanges *c) {
  for (size_t i = 0; i < c->len; i++) {
    free(c->items[i].document);
    free(c->items[i].path);
    free(c->items[i].old_value);
    free(c->items[i].new_value);
    free(c->items[i].field);
  }
  free(c->items);
  memset(c, 0, sizeof(*c));
}

char *spec_rename_change_to_json(const SpecRenameChange *c) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "document");
  jstr(&b, c->document);
  jkey(&b, &first, "path");
  jstr(&b, c->path);
  jkey(&b, &first, "kind");
  jstr(&b, c->kind);
  jkey(&b, &first, "old");
  jstr(&b, c->old_value);
  jkey(&b, &first, "new");
  jstr(&b, c->new_value);
  if (has_text(c->field)) {
    jkey(&b, &first, "field");
    jstr(&b, c->field);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

static void rename_push(SpecRenameChanges *out, const char *document,
                        const char *path, const char *kind, const char *old_value,
                        const char *new_value, const char *field) {
  if (out->len == out->cap) {
    out->cap = out->cap ? out->cap * 2 : 8;
    out->items = (SpecRenameChange *)realloc(out->items,
                                             out->cap * sizeof(SpecRenameChange));
  }
  SpecRenameChange *c = &out->items[out->len++];
  c->document = som_strdup(document);
  c->path = som_strdup(path);
  c->kind = kind;
  c->old_value = som_strdup(old_value);
  c->new_value = som_strdup(new_value);
  c->field = som_strdup(field);
}

static void all_items(const SpecDocument *doc, SomStrList *out) {
  som_strlist_init(out);
  SomStrList lists;
  spec_document_list_paths(doc, &lists);
  for (size_t l = 0; l < lists.len; l++) {
    const SomStrList *items = spec_document_list_items(doc, lists.items[l]);
    for (size_t i = 0; items != NULL && i < items->len; i++) {
      som_strlist_push_copy(out, items->items[i]);
    }
  }
  som_strlist_free(&lists);
}

static int id_byte(char b) {
  return b == '-' || (b >= '0' && b <= '9') || (b >= 'a' && b <= 'z') ||
         (b >= 'A' && b <= 'Z');
}

/* Every whole-token occurrence of `from` in `v` replaced with `to`; NULL when
 * there is none. Owned. */
static char *replace_token(const char *v, const char *from, const char *to) {
  size_t fl = strlen(from), n = strlen(v);
  if (fl == 0) return NULL;
  SomBuf b;
  som_buf_init(&b);
  int found = 0;
  size_t i = 0;
  while (i < n) {
    if (strncmp(v + i, from, fl) == 0 && (i == 0 || !id_byte(v[i - 1])) &&
        (i + fl >= n || !id_byte(v[i + fl]))) {
      som_buf_puts(&b, to);
      i += fl;
      found = 1;
      continue;
    }
    som_buf_putc(&b, v[i]);
    i++;
  }
  if (!found) {
    som_buf_free(&b);
    return NULL;
  }
  return som_buf_take(&b);
}

int spec_rename_id(SpecDocumentSet *set, const char *from, const char *to,
                   SpecRenameChanges *out, SpecRenameError *err) {
  memset(out, 0, sizeof(*out));
  SpecReflection refl = spec_reflection_make(set->model);
  SomStrList names;
  spec_document_set_names(set, &names);
  /* The effective ids, read before anything changes. */
  SomMap ids; /* "<name>\x01<item>" -> id */
  som_map_init(&ids);
  SomStrList holders;
  som_strlist_init(&holders);
  for (size_t ni = 0; ni < names.len; ni++) {
    const SpecDocument *doc = spec_document_set_get(set, names.items[ni]);
    SomStrList items;
    all_items(doc, &items);
    int holds = 0;
    for (size_t i = 0; i < items.len; i++) {
      char *id = spec_set_effective_item_id(&refl, doc, items.items[i]);
      holds = holds || strcmp(id, to) == 0;
      char *key = scat(names.items[ni], "\x01", items.items[i], NULL);
      som_map_set(&ids, key, id);
      free(key);
      free(id);
    }
    som_strlist_free(&items);
    if (holds) som_strlist_push_copy(&holders, names.items[ni]);
  }
  if (holders.len > 0) {
    if (err != NULL) {
      spec_rename_error_free(err);
      char *joined = som_strlist_join(&holders, ", ");
      err->message = scat(to, " is already an id in ", joined, NULL);
      free(joined);
      err->documents = holders;
    } else {
      som_strlist_free(&holders);
    }
    som_map_free(&ids);
    som_strlist_free(&names);
    return 0;
  }
  som_strlist_free(&holders);
  int stopped = 0;
  for (size_t ni = 0; ni < names.len && !stopped; ni++) {
    const char *name = names.items[ni];
    SpecDocument *doc = spec_document_set_get_mut(set, name);
    if (doc == NULL) continue;
    SomStrList items;
    all_items(doc, &items);
    for (size_t i = 0; i < items.len && !stopped; i++) {
      char *key = scat(name, "\x01", items.items[i], NULL);
      const char *id = som_map_get(&ids, key);
      free(key);
      if (!str_eq(id, from)) continue;
      SpecSectionIdError serr;
      spec_section_id_error_init(&serr);
      if (!spec_document_set_item_section_id(doc, items.items[i], to, &serr)) {
        stopped = 1;
      } else {
        rename_push(out, name, items.items[i], "sectionId", from, to, "");
      }
      spec_section_id_error_free(&serr);
    }
    som_strlist_free(&items);
    if (stopped) break;
    SomStrList paths;
    spec_document_content_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      char *v = som_strdup(or_empty(spec_document_content(doc, paths.items[i])));
      char *n = replace_token(v, from, to);
      if (n != NULL) {
        spec_document_set_content(doc, paths.items[i], n);
        rename_push(out, name, paths.items[i], "value", v, n, "");
        free(n);
      }
      free(v);
    }
    som_strlist_free(&paths);
    spec_document_form_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      SomStrList fields;
      spec_document_form_field_names(doc, paths.items[i], &fields);
      for (size_t f = 0; f < fields.len; f++) {
        char *v = som_strdup(
            or_empty(spec_document_form_field(doc, paths.items[i], fields.items[f])));
        char *n = replace_token(v, from, to);
        if (n != NULL) {
          spec_document_set_form_field(doc, paths.items[i], fields.items[f], n);
          rename_push(out, name, paths.items[i], "value", v, n, fields.items[f]);
          free(n);
        }
        free(v);
      }
      som_strlist_free(&fields);
    }
    som_strlist_free(&paths);
  }
  som_map_free(&ids);
  som_strlist_free(&names);
  return 1;
}
