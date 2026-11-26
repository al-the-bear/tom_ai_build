/* spec_derive_fields — see include/spec_derive_fields.h. A port of the Rust
 * `spec_derive_fields.rs` (the Dart reference shares one document between the
 * checker and the writes, as this port does). */
#include "spec_derive_fields.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document_set.h"
#include "spec_document_set_internal.h"
#include "spec_links_validator.h"
#include "spec_review_annotations.h"

/* ---- small helpers ----------------------------------------------------------- */

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

static const char *or_empty(const char *s) { return s != NULL ? s : ""; }

static int has_text(const char *s) { return s != NULL && s[0] != '\0'; }

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

static int trimmed_equal(const char *a, const char *b) {
  char *x = trim_dup(a);
  char *y = trim_dup(b);
  int eq = strcmp(x, y) == 0;
  free(x);
  free(y);
  return eq;
}

static int under_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && (path[n] == '\0' || path[n] == '/');
}

static void jstr(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

/* ---- changes and results ------------------------------------------------------ */

const char *spec_derive_change_kind_name(SpecDeriveChangeKind kind) {
  switch (kind) {
    case SPEC_DERIVE_CHANGE_VALUE:
      return "value";
    case SPEC_DERIVE_CHANGE_ROW_ADDED:
      return "rowAdded";
    case SPEC_DERIVE_CHANGE_ROW_REMOVED:
      return "rowRemoved";
  }
  return "";
}

void spec_derive_change_free(SpecDeriveChange *c) {
  free(c->path);
  free(c->field);
  free(c->old_value);
  free(c->new_value);
  memset(c, 0, sizeof(*c));
}

char *spec_derive_change_to_json(const SpecDeriveChange *c) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"step\":");
  som_buf_puti(&b, c->step);
  som_buf_puts(&b, ",\"kind\":");
  jstr(&b, spec_derive_change_kind_name(c->kind));
  som_buf_puts(&b, ",\"path\":");
  jstr(&b, c->path);
  som_buf_puts(&b, ",\"old\":");
  jstr(&b, c->old_value);
  som_buf_puts(&b, ",\"new\":");
  jstr(&b, c->new_value);
  if (has_text(c->field)) {
    som_buf_puts(&b, ",\"field\":");
    jstr(&b, c->field);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_derive_result_free(SpecDeriveResult *r) {
  if (r->document != NULL) {
    spec_document_free(r->document);
    free(r->document);
  }
  for (size_t i = 0; i < r->changes_len; i++) spec_derive_change_free(&r->changes[i]);
  free(r->changes);
  spec_validation_errors_free(&r->unresolved);
  memset(r, 0, sizeof(*r));
}

const SpecDocument *spec_derive_result_written(const SpecDeriveResult *r,
                                               const SpecDocument *given) {
  return r->document != NULL ? r->document : given;
}

char *spec_derive_result_to_json(const SpecDeriveResult *r,
                                 const SpecDocument *given) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"changes\":[");
  for (size_t i = 0; i < r->changes_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *c = spec_derive_change_to_json(&r->changes[i]);
    som_buf_puts(&b, c);
    free(c);
  }
  som_buf_puts(&b, "],\"unresolved\":");
  char *u = spec_validation_errors_json(&r->unresolved);
  som_buf_puts(&b, u);
  free(u);
  som_buf_puts(&b, ",\"document\":");
  char *d = spec_document_stores_json(spec_derive_result_written(r, given));
  som_buf_puts(&b, d);
  free(d);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the deriver ----------------------------------------------------------------- */

typedef struct {
  const SpecModel *model;
  SpecReflection refl;
  int marked;
  const char *author; /* NULL for none */
  const char *at;     /* NULL for now */
  SpecDeriveResult *out;
  SomMap unresolved_keys;
} Deriver;

/* Records a change, taking the owned strings. */
static void push_change(Deriver *d, size_t at, long long step,
                        SpecDeriveChangeKind kind, const char *path,
                        const char *field, char *old_value, char *new_value) {
  SpecDeriveResult *r = d->out;
  if (r->changes_len == r->changes_cap) {
    r->changes_cap = r->changes_cap ? r->changes_cap * 2 : 8;
    r->changes = (SpecDeriveChange *)realloc(r->changes,
                                             r->changes_cap * sizeof(SpecDeriveChange));
  }
  memmove(&r->changes[at + 1], &r->changes[at],
          (r->changes_len - at) * sizeof(SpecDeriveChange));
  SpecDeriveChange *c = &r->changes[at];
  c->step = step;
  c->kind = kind;
  c->path = som_strdup(path);
  c->field = som_strdup(field);
  c->old_value = old_value != NULL ? old_value : som_strdup("");
  c->new_value = new_value != NULL ? new_value : som_strdup("");
  r->changes_len++;
}

static void push_row(Deriver *d, long long step, SpecDeriveChangeKind kind,
                     const char *path) {
  push_change(d, d->out->changes_len, step, kind, path, "", NULL, NULL);
}

static void add_unresolved(Deriver *d, const char *path, const char *code,
                           const char *message) {
  char *key = scat(code, " ", path, " ", message, NULL);
  if (som_map_get(&d->unresolved_keys, key) == NULL) {
    som_map_set(&d->unresolved_keys, key, "1");
    spec_validation_errors_push(&d->out->unresolved, path, code, message);
  }
  free(key);
}

/* Writes `value` at `path` / `field` ("" content): plainly, or marked against
 * the value there (compared from its original, so a change already proposed is
 * not proposed again). */
static void write_value(Deriver *d, SpecDocument *doc, long long step,
                        const char *path, const char *field, const char *value) {
  char *current = som_strdup(spec_set_get_value(doc, path, field));
  if (!d->marked) {
    if (trimmed_equal(current, value)) {
      free(current);
      return;
    }
    spec_set_set_value(doc, path, field, value);
  } else {
    char *accepted = spec_apply_inline_marks_text(current, 1);
    int same = trimmed_equal(accepted, value);
    free(accepted);
    if (same) {
      free(current);
      return;
    }
    char *original = spec_apply_inline_marks_text(current, 0);
    SpecMarkedChange mc = spec_mark_change_text(original, value);
    int exact = mc.exact;
    spec_marked_change_free(&mc);
    free(original);
    if (!exact) {
      char *what = field[0] == '\0' ? som_strdup("the content")
                                    : scat("form field \"", field, "\"", NULL);
      char *message = scat(what, " would become \"", value,
                           "\", a change that cannot be marked exactly; it is "
                           "left for the agent",
                           NULL);
      add_unresolved(d, path, SPEC_VALIDATION_CODE_UNMARKABLE, message);
      free(message);
      free(what);
      free(current);
      return;
    }
    SpecReviewAnnotations ra = spec_review_annotations_make(doc, NULL);
    SpecMarkedChange written;
    SpecReviewAnnotationError err;
    memset(&err, 0, sizeof(err));
    spec_review_annotations_set_marked(&ra, path, field[0] == '\0' ? NULL : field,
                                       value, d->author, d->at, &written, &err);
    spec_marked_change_free(&written);
    spec_review_annotation_error_free(&err);
  }
  const char *now = spec_set_get_value(doc, path, field);
  if (strcmp(now, current) != 0) {
    push_change(d, d->out->changes_len, step, SPEC_DERIVE_CHANGE_VALUE, path,
                field, current, som_strdup(now));
  } else {
    free(current);
  }
}

/* Adds a row to `lst`, then writes `values` (`<rel>#<field>` -> value) in
 * their order beneath it. */
static void add_row(Deriver *d, SpecDocument *doc, long long step,
                    const char *lst, const SpecStringPairs *values) {
  char *item = spec_document_add_list_item(doc, lst);
  push_row(d, step, SPEC_DERIVE_CHANGE_ROW_ADDED, item);
  for (size_t i = 0; i < values->len; i++) {
    const char *k = values->items[i].key;
    const char *hash = strchr(k, '#');
    char *rel = hash != NULL ? som_strdup_n(k, (size_t)(hash - k)) : som_strdup(k);
    const char *field = hash != NULL ? hash + 1 : "";
    char *path = scat(item, "/", rel, NULL);
    write_value(d, doc, step, path, field,
                or_empty(spec_string_pairs_get(values, k)));
    free(path);
    free(rel);
  }
  free(item);
}

static void remove_row(Deriver *d, SpecDocument *doc, long long step,
                       const char *row, int empty) {
  if (!d->marked || empty) {
    if (!spec_document_remove_list_item(doc, row)) return;
    push_row(d, step, SPEC_DERIVE_CHANGE_ROW_REMOVED, row);
    return;
  }
  /* Under review: every value of the row is proposed for deletion; once
   * accepted, the empty row goes with the next run. */
  size_t before = d->out->changes_len;
  char *row_copy = som_strdup(row);
  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (under_path(paths.items[i], row_copy)) {
      write_value(d, doc, step, paths.items[i], "", "");
    }
  }
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (!under_path(paths.items[i], row_copy)) continue;
    SomStrList names;
    spec_document_form_field_names(doc, paths.items[i], &names);
    for (size_t n = 0; n < names.len; n++) {
      write_value(d, doc, step, paths.items[i], names.items[n], "");
    }
    som_strlist_free(&names);
  }
  som_strlist_free(&paths);
  if (d->out->changes_len > before) {
    push_change(d, before, step, SPEC_DERIVE_CHANGE_ROW_REMOVED, row_copy, "",
                NULL, NULL);
  }
  free(row_copy);
}

/* The tuple's values in `places` order, joined with ` | `. Owned. */
static char *tuple_key(const SomStrList *places, const SpecStringPairs *t) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < places->len; i++) {
    if (i > 0) som_buf_puts(&b, " | ");
    som_buf_puts(&b, or_empty(spec_string_pairs_get(t, places->items[i])));
  }
  return som_buf_take(&b);
}

static int remove_first(SomStrList *list, const char *k) {
  for (size_t i = 0; i < list->len; i++) {
    if (strcmp(list->items[i], k) == 0) {
      som_strlist_remove_at(list, i);
      return 1;
    }
  }
  return 0;
}

/* Makes the list hold one element per wanted tuple: elements matching no
 * tuple removed, tuples matching no element added. */
static void apply_list(Deriver *d, SpecDocument *doc, const SpecLinkFix *f,
                       SpecLinkValidator *v) {
  const SomStrList *places = &f->tuple_keys;
  SomStrList wanted, keep;
  som_strlist_init(&wanted);
  som_strlist_init(&keep);
  for (size_t i = 0; i < f->tuples_len; i++) {
    som_strlist_push(&wanted, tuple_key(places, &f->tuples[i]));
  }
  char *probe = scat(f->path, "-0", NULL);
  SomStrList elements;
  const SomStrList *items = spec_document_list_items(doc, f->path);
  if (items != NULL) {
    som_strlist_copy(&elements, items);
  } else {
    som_strlist_init(&elements);
  }
  SomStrList element_keys;
  som_strlist_init(&element_keys);
  for (size_t e = 0; e < elements.len; e++) {
    SpecStringPairs t;
    spec_string_pairs_init(&t);
    for (size_t p = 0; p < places->len; p++) {
      char *value = spec_link_validator_place_value(v, places->items[p],
                                                    elements.items[e]);
      spec_string_pairs_put(&t, places->items[p], value);
      free(value);
    }
    som_strlist_push(&element_keys, tuple_key(places, &t));
    spec_string_pairs_free(&t);
  }
  /* The target place of each tuple place, relative to a new row; NULL when
   * it does not resolve. */
  char **rels = (char **)calloc(places->len ? places->len : 1, sizeof(char *));
  size_t probe_len = strlen(probe);
  for (size_t p = 0; p < places->len; p++) {
    SpecPlaceResolution r;
    if (!spec_resolve_place_at(&v->refl, places->items[p], probe, &r)) continue;
    const char *tail = strlen(r.path) > probe_len ? r.path + probe_len + 1 : "";
    const char *field = spec_place_resolution_field(&r);
    rels[p] = has_text(field) ? scat(tail, "#", field, NULL) : som_strdup(tail);
    spec_place_resolution_free(&r);
  }
  for (size_t e = 0; e < elements.len; e++) {
    if (remove_first(&wanted, element_keys.items[e])) {
      som_strlist_push_copy(&keep, element_keys.items[e]);
    } else {
      remove_row(d, doc, 2, elements.items[e], 0);
    }
  }
  for (size_t i = 0; i < f->tuples_len; i++) {
    const SpecStringPairs *t = &f->tuples[i];
    char *k = tuple_key(places, t);
    int kept = remove_first(&keep, k);
    free(k);
    if (kept) continue;
    SpecStringPairs values;
    spec_string_pairs_init(&values);
    for (size_t p = 0; p < places->len; p++) {
      if (rels[p] == NULL) continue;
      spec_string_pairs_put(&values, rels[p],
                            or_empty(spec_string_pairs_get(t, places->items[p])));
    }
    add_row(d, doc, 2, f->path, &values);
    spec_string_pairs_free(&values);
  }
  for (size_t p = 0; p < places->len; p++) free(rels[p]);
  free(rels);
  som_strlist_free(&element_keys);
  som_strlist_free(&elements);
  free(probe);
  som_strlist_free(&wanted);
  som_strlist_free(&keep);
}

/* The effective id of `item`; the items the copy adds are recorded in the
 * checker's ids. Owned. */
static char *copy_item_id(Deriver *d, SpecLinkValidator *v,
                          const SpecDocument *doc, const char *item) {
  const char *hit = som_map_get(&v->item_ids, item);
  if (hit != NULL) return som_strdup(hit);
  char *id = spec_set_effective_item_id(&d->refl, doc, item);
  som_map_set(&v->item_ids, item, id);
  return id;
}

/* The path `rel` stands for in the copy at `copy_path`; `create` adds the
 * elements it names that are missing. Owned, NULL when it is not there. */
static char *path_in(Deriver *d, SpecLinkValidator *v, SpecDocument *doc,
                     const char *copy_path, const char *rel, int create) {
  char *cur = som_strdup(copy_path);
  if (rel[0] == '\0') return cur;
  const char *s = rel;
  for (;;) {
    const char *slash = strchr(s, '/');
    size_t n = slash != NULL ? (size_t)(slash - s) : strlen(s);
    char *seg = som_strdup_n(s, n);
    const char *bracket = strchr(seg, '[');
    if (bracket == NULL) {
      char *next = scat(cur, "/", seg, NULL);
      free(cur);
      cur = next;
    } else {
      char *base = som_strdup_n(seg, (size_t)(bracket - seg));
      char *lst = scat(cur, "/", base, NULL);
      free(base);
      size_t sl = strlen(seg);
      char *id = som_strdup_n(bracket + 1, sl - (size_t)(bracket - seg) - 2);
      char *found = NULL;
      const SomStrList *items = spec_document_list_items(doc, lst);
      for (size_t i = 0; items != NULL && i < items->len && found == NULL; i++) {
        char *item_id = copy_item_id(d, v, doc, items->items[i]);
        if (strcmp(item_id, id) == 0) found = som_strdup(items->items[i]);
        free(item_id);
      }
      free(cur);
      if (found != NULL) {
        cur = found;
      } else if (!create) {
        cur = NULL;
      } else {
        cur = spec_set_add_item(doc, lst, id);
        som_map_set(&v->item_ids, cur, id);
        push_row(d, 2, SPEC_DERIVE_CHANGE_ROW_ADDED, cur);
      }
      free(id);
      free(lst);
    }
    free(seg);
    if (cur == NULL || slash == NULL) break;
    s = slash + 1;
  }
  return cur;
}

/* A value key split into its relative path and field: 1, or 0 for an item
 * key or a malformed one. */
static int split_key(const char *key, char **rel, const char **field) {
  const char *body = key + 2;
  switch (key[0]) {
    case 'f': {
      const char *hash = strchr(body, '#');
      if (hash == NULL) return 0;
      *rel = som_strdup_n(body, (size_t)(hash - body));
      *field = hash + 1;
      return 1;
    }
    case 'c':
      *rel = som_strdup(body);
      *field = "";
      return 1;
    case 'h':
      *rel = som_strdup(body);
      *field = SPEC_HEADLINE_FIELD;
      return 1;
    default:
      return 0;
  }
}

static int beneath_any(const SomStrList *gone, const char *rel, int inclusive) {
  for (size_t g = 0; g < gone->len; g++) {
    size_t n = strlen(gone->items[g]);
    if (strncmp(rel, gone->items[g], n) == 0 &&
        (rel[n] == '/' || (inclusive && rel[n] == '\0'))) {
      return 1;
    }
  }
  return 0;
}

/* Writes the copy at `copy_path` from its holder: every value and element the
 * holder has, in the copy, and nothing else. */
static void apply_copy(Deriver *d, SpecDocument *doc, const char *copy_path,
                       const char *holder, SpecLinkValidator *v) {
  SomMap theirs, theirs_paths, mine, mine_paths;
  spec_link_validator_subtree(v, holder, &theirs, &theirs_paths);
  spec_link_validator_subtree(v, copy_path, &mine, &mine_paths);
  /* Elements the holder lacks go first, and nothing beneath them is
   * written. */
  SomStrList gone;
  som_strlist_init(&gone);
  for (size_t i = 0; i < mine.len; i++) {
    const char *k = mine.entries[i].key;
    if (strncmp(k, "i:", 2) != 0 || som_map_get(&theirs, k) != NULL) continue;
    const char *rel = k + 2;
    if (beneath_any(&gone, rel, 0)) continue;
    som_strlist_push_copy(&gone, rel);
    remove_row(d, doc, 2, som_map_get(&mine_paths, k), 0);
  }
  for (size_t i = 0; i < theirs.len; i++) {
    const char *k = theirs.entries[i].key;
    if (strncmp(k, "i:", 2) == 0) {
      char *p = path_in(d, v, doc, copy_path, k + 2, 1);
      free(p);
      continue;
    }
    char *rel;
    const char *field;
    if (!split_key(k, &rel, &field)) continue;
    char *path = path_in(d, v, doc, copy_path, rel, 1);
    if (path != NULL) write_value(d, doc, 2, path, field, theirs.entries[i].val);
    free(path);
    free(rel);
  }
  for (size_t i = 0; i < mine.len; i++) {
    const char *k = mine.entries[i].key;
    if (som_map_get(&theirs, k) != NULL || strncmp(k, "i:", 2) == 0) continue;
    char *rel;
    const char *field;
    if (!split_key(k, &rel, &field)) continue;
    if (!beneath_any(&gone, rel, 1)) {
      char *path = path_in(d, v, doc, copy_path, rel, 0);
      if (path != NULL) write_value(d, doc, 2, path, field, "");
      free(path);
    }
    free(rel);
  }
  som_strlist_free(&gone);
  som_map_free(&theirs);
  som_map_free(&theirs_paths);
  som_map_free(&mine);
  som_map_free(&mine_paths);
}

static void apply_fix(Deriver *d, SpecDocument *doc, const SpecLinkFix *f,
                      SpecLinkValidator *v) {
  const char *kind = f->kind;
  if (strcmp(kind, SPEC_LINK_FIX_SET) == 0) {
    write_value(d, doc, f->step, f->path, or_empty(f->field), or_empty(f->value));
  } else if (strcmp(kind, SPEC_LINK_FIX_APPEND) == 0) {
    char *now = spec_link_validator_form_value(v, f->path, or_empty(f->field));
    SomStrList ids;
    spec_link_ids(now, &ids);
    free(now);
    if (!som_strlist_contains(&ids, or_empty(f->value))) {
      som_strlist_push_copy(&ids, or_empty(f->value));
      char *joined = som_strlist_join(&ids, ", ");
      write_value(d, doc, f->step, f->path, or_empty(f->field), joined);
      free(joined);
    }
    som_strlist_free(&ids);
  } else if (strcmp(kind, SPEC_LINK_FIX_ADD_ROW) == 0) {
    add_row(d, doc, f->step, f->path, &f->values);
  } else if (strcmp(kind, SPEC_LINK_FIX_REMOVE_ROW) == 0) {
    remove_row(d, doc, f->step, f->path, f->empty);
  } else if (strcmp(kind, SPEC_LINK_FIX_LIST) == 0) {
    apply_list(d, doc, f, v);
  } else if (strcmp(kind, SPEC_LINK_FIX_COPY) == 0) {
    apply_copy(d, doc, f->path, or_empty(f->holder), v);
  }
}

static void run(Deriver *d, SpecDocument *doc) {
  /* Step 1: link ends and rows. Removals first, so a row removed and a row
   * added for the same id do not cancel out. */
  SpecLinkValidator v;
  spec_link_validator_init(&v, d->model, doc, d->marked);
  spec_link_validator_run(&v);
  size_t n = v.fixes.len;
  for (size_t i = 0; i < n; i++) {
    const SpecLinkFix *f = &v.fixes.items[i];
    if (f->step == 1 && strcmp(f->kind, SPEC_LINK_FIX_REMOVE_ROW) == 0) {
      remove_row(d, doc, 1, f->path, f->empty);
    }
  }
  for (size_t i = 0; i < n; i++) {
    if (v.fixes.items[i].step == 1 &&
        strcmp(v.fixes.items[i].kind, SPEC_LINK_FIX_REMOVE_ROW) != 0) {
      apply_fix(d, doc, &v.fixes.items[i], &v);
    }
  }

  /* Step 2: derived values and lists, then (reading them) the repeats and the
   * copies; again until nothing moves, which DERIVE-ACYCLIC bounds. */
  SpecValidationErrors last;
  memset(&last, 0, sizeof(last));
  for (size_t i = 0; i < v.errors.len; i++) {
    spec_validation_errors_push(&last, v.errors.items[i].path,
                                v.errors.items[i].code, v.errors.items[i].message);
  }
  spec_link_validator_free(&v);
  for (int round = 0; round < 4; round++) {
    SpecLinkValidator v2;
    spec_link_validator_init(&v2, d->model, doc, d->marked);
    spec_link_validator_run(&v2);
    size_t before = d->out->changes_len;
    n = v2.fixes.len;
    for (size_t i = 0; i < n; i++) {
      if (v2.fixes.items[i].step == 2 &&
          strcmp(v2.fixes.items[i].kind, SPEC_LINK_FIX_COPY) != 0) {
        apply_fix(d, doc, &v2.fixes.items[i], &v2);
      }
    }
    spec_link_validator_free(&v2);
    SpecLinkValidator v3;
    spec_link_validator_init(&v3, d->model, doc, d->marked);
    spec_link_validator_run(&v3);
    spec_validation_errors_free(&last);
    memset(&last, 0, sizeof(last));
    for (size_t i = 0; i < v3.errors.len; i++) {
      spec_validation_errors_push(&last, v3.errors.items[i].path,
                                  v3.errors.items[i].code,
                                  v3.errors.items[i].message);
    }
    n = v3.fixes.len;
    for (size_t i = 0; i < n; i++) {
      if (strcmp(v3.fixes.items[i].kind, SPEC_LINK_FIX_COPY) == 0) {
        apply_fix(d, doc, &v3.fixes.items[i], &v3);
      }
    }
    spec_link_validator_free(&v3);
    if (d->out->changes_len == before) break;
  }
  for (size_t i = 0; i < last.len; i++) {
    if (strcmp(last.items[i].code, SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS) == 0) {
      add_unresolved(d, last.items[i].path, last.items[i].code,
                     last.items[i].message);
    }
  }
  spec_validation_errors_free(&last);

  /* Step 3: counts, products, ranks. */
  SpecDerivedNumbers numbers;
  spec_derived_numbers(d->model, doc, d->marked, &numbers);
  for (size_t i = 0; i < numbers.len; i++) {
    write_value(d, doc, 3, numbers.items[i].path, numbers.items[i].field,
                numbers.items[i].value);
  }
  spec_derived_numbers_free(&numbers);
}

static void derive_into(const SpecModel *model, SpecDocument *doc,
                        const SpecDeriveOptions *options, SpecDeriveResult *out) {
  Deriver d;
  d.model = model;
  d.refl = spec_reflection_make(model);
  d.marked = options != NULL && options->marked;
  d.author = options != NULL && has_text(options->author) ? options->author : NULL;
  d.at = options != NULL && has_text(options->at) ? options->at : NULL;
  d.out = out;
  som_map_init(&d.unresolved_keys);
  run(&d, doc);
  som_map_free(&d.unresolved_keys);
}

void spec_derive_fields(const SpecModel *model, SpecDocument *doc,
                        const SpecDeriveOptions *options,
                        SpecDeriveResult *out) {
  if (options != NULL && options->dry_run) {
    spec_derive_fields_dry_run(model, doc, options, out);
    return;
  }
  memset(out, 0, sizeof(*out));
  derive_into(model, doc, options, out);
}

void spec_derive_fields_dry_run(const SpecModel *model, const SpecDocument *doc,
                                const SpecDeriveOptions *options,
                                SpecDeriveResult *out) {
  memset(out, 0, sizeof(*out));
  SpecDocument *target = (SpecDocument *)malloc(sizeof(SpecDocument));
  spec_document_copy(target, doc);
  derive_into(model, target, options, out);
  out->document = target;
}
