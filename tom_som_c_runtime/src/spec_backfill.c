/* spec_backfill — see include/spec_backfill.h. A port of the Rust
 * `spec_backfill.rs`. */
#include "spec_backfill.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "spec_derive_fields.h"
#include "spec_document_set_internal.h"
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

static int beneath_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && path[n] == '/';
}

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

/* The list of a list item: `item` up to its last `-`. Owned. */
static char *list_of_item(const char *item) {
  const char *at = strrchr(item, '-');
  return at == NULL ? som_strdup(item) : som_strdup_n(item, (size_t)(at - item));
}

/* The id written in the last `[...]` of a key. Owned. */
static char *bracket_id(const char *key) {
  const char *open = strrchr(key, '[');
  size_t n = strlen(key);
  size_t from = open != NULL ? (size_t)(open - key) + 1 : 0;
  return n > from ? som_strdup_n(key + from, n - from - 1) : som_strdup("");
}

static void jstr(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

/* ---- the vocabulary ------------------------------------------------------------ */

const char *spec_backfill_error_code_name(SpecBackfillErrorCode code) {
  return code == SPEC_BACKFILL_ERROR_NO_BLUEPRINT ? "noBlueprint" : "setHasMarks";
}

const char *spec_backfill_change_kind_name(SpecBackfillChangeKind kind) {
  switch (kind) {
    case SPEC_BACKFILL_CHANGE_VALUE:
      return "value";
    case SPEC_BACKFILL_CHANGE_ELEMENT_ADDED:
      return "elementAdded";
    case SPEC_BACKFILL_CHANGE_ELEMENT_REMOVED:
      return "elementRemoved";
    case SPEC_BACKFILL_CHANGE_REVISION:
      return "revision";
    case SPEC_BACKFILL_CHANGE_DERIVED:
      return "derived";
  }
  return "";
}

const char *spec_backfill_left_reason_name(SpecBackfillLeftReason reason) {
  switch (reason.kind) {
    case SPEC_BACKFILL_LEFT_HELD_HERE:
      return "heldHere";
    case SPEC_BACKFILL_LEFT_MAY_BE_ADDED:
      return "mayBeAdded";
    case SPEC_BACKFILL_LEFT_RESOLUTION:
      return spec_sync_resolution_name(reason.resolution);
  }
  return "";
}

void spec_backfill_error_init(SpecBackfillError *e) {
  memset(e, 0, sizeof(*e));
}

void spec_backfill_error_free(SpecBackfillError *e) {
  for (size_t i = 0; i < e->places_len; i++) spec_sync_place_free(&e->places[i]);
  free(e->places);
  free(e->message);
  spec_backfill_error_init(e);
}

char *spec_backfill_error_to_json(const SpecBackfillError *e) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"code\":");
  jstr(&b, spec_backfill_error_code_name(e->code));
  som_buf_puts(&b, ",\"places\":[");
  for (size_t i = 0; i < e->places_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *p = spec_sync_place_to_json(&e->places[i]);
    som_buf_puts(&b, p);
    free(p);
  }
  som_buf_puts(&b, "]}");
  return som_buf_take(&b);
}

char *spec_backfill_error_display(const SpecBackfillError *e) {
  return scat("SpecBackfillError(", spec_backfill_error_code_name(e->code), "): ",
              or_empty(e->message), NULL);
}

void spec_backfill_change_free(SpecBackfillChange *c) {
  free(c->pair);
  free(c->path);
  free(c->field);
  free(c->old_value);
  free(c->new_value);
  memset(c, 0, sizeof(*c));
}

char *spec_backfill_change_to_json(const SpecBackfillChange *c) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"pair\":");
  jstr(&b, c->pair);
  som_buf_puts(&b, ",\"kind\":");
  jstr(&b, spec_backfill_change_kind_name(c->kind));
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

void spec_backfill_result_free(SpecBackfillResult *r) {
  spec_document_free(&r->blueprint);
  for (size_t i = 0; i < r->changes_len; i++) spec_backfill_change_free(&r->changes[i]);
  free(r->changes);
  for (size_t i = 0; i < r->left_len; i++) spec_sync_finding_free(&r->left[i].finding);
  free(r->left);
  memset(r, 0, sizeof(*r));
}

char *spec_backfill_result_to_json(const SpecBackfillResult *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"changes\":[");
  for (size_t i = 0; i < r->changes_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *c = spec_backfill_change_to_json(&r->changes[i]);
    som_buf_puts(&b, c);
    free(c);
  }
  som_buf_puts(&b, "],\"left\":[");
  for (size_t i = 0; i < r->left_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"finding\":");
    char *f = spec_sync_finding_to_json(&r->left[i].finding);
    som_buf_puts(&b, f);
    free(f);
    som_buf_puts(&b, ",\"reason\":");
    jstr(&b, spec_backfill_left_reason_name(r->left[i].reason));
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"blueprint\":");
  char *d = spec_document_stores_json(&r->blueprint);
  som_buf_puts(&b, d);
  free(d);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_backfill_bump(const char *v) {
  size_t n = strlen(v);
  size_t end = n;
  while (end > 0 && !(v[end - 1] >= '0' && v[end - 1] <= '9')) end--;
  if (end == 0) return n == 0 ? som_strdup("1") : scat(v, ".1", NULL);
  size_t start = end;
  while (start > 0 && v[start - 1] >= '0' && v[start - 1] <= '9') start--;
  if (end - start > 19) return scat(v, ".1", NULL);
  unsigned long long num = 0;
  for (size_t i = start; i < end; i++) {
    unsigned long long d = (unsigned long long)(v[i] - '0');
    if (num > (18446744073709551615ULL - d) / 10ULL) return scat(v, ".1", NULL);
    num = num * 10ULL + d;
  }
  if (num == 18446744073709551615ULL) return scat(v, ".1", NULL);
  char digits[32];
  snprintf(digits, sizeof(digits), "%llu", num + 1ULL);
  char *prefix = som_strdup_n(v, start);
  char *out = scat(prefix, digits, v + end, NULL);
  free(prefix);
  return out;
}

/* Today's date (UTC) as `YYYY-MM-DD` (standard C only: the civil date of
 * the days since the epoch). Owned. */
static char *spec_today(void) {
  time_t now = time(NULL);
  long long days = now == (time_t)-1 ? 0 : (long long)now / 86400;
  long long z = days + 719468;
  long long era = (z >= 0 ? z : z - 146096) / 146097;
  long long doe = z - era * 146097;
  long long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  long long y = yoe + era * 400;
  long long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
  long long mp = (5 * doy + 2) / 153;
  long long d = doy - (153 * mp + 2) / 5 + 1;
  long long m = mp < 10 ? mp + 3 : mp - 9;
  if (m <= 2) y++;
  char buf[32];
  snprintf(buf, sizeof(buf), "%04lld-%02lld-%02lld", y, m, d);
  return som_strdup(buf);
}

/* ---- the writer ------------------------------------------------------------------ */

typedef struct {
  const SpecDocumentSet *set;
  SpecReflection refl;
  SpecDocument *doc; /* the Blueprint written */
  const char *name;  /* its name */
  SpecBackfillResult *out;
  SomMap pairs; /* the pairs written */
} Backfiller;

/* Records a change, taking the owned strings (NULL: ""). */
static SpecBackfillChange *push_change(Backfiller *w, const char *pair,
                                       SpecBackfillChangeKind kind,
                                       const char *path, const char *field,
                                       char *old_value, char *new_value) {
  SpecBackfillResult *r = w->out;
  if (r->changes_len == r->changes_cap) {
    r->changes_cap = r->changes_cap ? r->changes_cap * 2 : 8;
    r->changes = (SpecBackfillChange *)realloc(
        r->changes, r->changes_cap * sizeof(SpecBackfillChange));
  }
  SpecBackfillChange *c = &r->changes[r->changes_len++];
  c->pair = som_strdup(pair);
  c->kind = kind;
  c->path = som_strdup(path);
  c->field = som_strdup(field);
  c->old_value = old_value != NULL ? old_value : som_strdup("");
  c->new_value = new_value != NULL ? new_value : som_strdup("");
  return c;
}

static void write_value(Backfiller *w, const char *pair, const char *path,
                        const char *field, const char *value) {
  char *old = som_strdup(spec_set_get_value(w->doc, path, field));
  char *a = trim_dup(old);
  char *b = trim_dup(value);
  int same = strcmp(a, b) == 0;
  free(a);
  free(b);
  if (same) {
    free(old);
    return;
  }
  spec_set_set_value(w->doc, path, field, value);
  som_map_set(&w->pairs, pair, "1");
  push_change(w, pair, SPEC_BACKFILL_CHANGE_VALUE, path, field, old,
              som_strdup(value));
}

static char *id_of(Backfiller *w, const char *item) {
  return spec_set_effective_item_id(&w->refl, w->doc, item);
}

/* The best mapping of `d_path` among `from` -> `to` (the longest `from` it is,
 * with `inclusive`, or lies beneath): its index, or -1. */
static long best_mapping(const SomStrList *from, const char *d_path,
                         int inclusive) {
  long best = -1;
  size_t best_len = 0;
  for (size_t i = 0; i < from->len; i++) {
    const char *f = from->items[i];
    if (!((inclusive && strcmp(d_path, f) == 0) || beneath_path(d_path, f))) continue;
    size_t n = strlen(f);
    if (best < 0 || n >= best_len) {
      best = (long)i;
      best_len = n;
    }
  }
  return best;
}

/* `key` renamed by the first mapping it is or lies beneath. Owned. */
static char *rename_key(const char *key, const SomStrList *from,
                        const SomStrList *to) {
  for (size_t i = 0; i < from->len; i++) {
    const char *f = from->items[i];
    size_t n = strlen(f);
    if (strcmp(key, f) == 0) return som_strdup(to->items[i]);
    if (strncmp(key, f, n) == 0 && key[n] == '/') return scat(to->items[i], key + n, NULL);
  }
  return som_strdup(key);
}

static void rename_store(SomMap *store, const SomStrList *from,
                         const SomStrList *to) {
  SomMap next;
  som_map_init(&next);
  for (size_t i = 0; i < store->len; i++) {
    char *k = rename_key(store->entries[i].key, from, to);
    som_map_set(&next, k, store->entries[i].val);
    free(k);
  }
  som_map_free(store);
  *store = next;
}

/* Puts the items of each list in `orders` in the order given, in one pass over
 * the document's stores: the lists renumbered `<list>-1 ... <list>-n`, every
 * value beneath an item travelling with it, an anonymous item whose positional
 * id would change keeping its old id. Inner lists go first, so an outer rename
 * carries their new paths. `orders[i]` is the order of `list_order[i]`. */
static void reorder(Backfiller *w, const SomStrList *list_order,
                    const SomStrList *orders) {
  if (list_order->len == 0) return;
  size_t n = list_order->len;
  size_t *idx = (size_t *)malloc(n * sizeof(size_t));
  for (size_t i = 0; i < n; i++) idx[i] = i;
  /* Stable sort by descending segment count. */
  for (size_t i = 1; i < n; i++) {
    size_t cur = idx[i];
    size_t segs = 1;
    for (const char *p = list_order->items[cur]; *p; p++) segs += *p == '/';
    size_t j = i;
    while (j > 0) {
      size_t prev_segs = 1;
      for (const char *p = list_order->items[idx[j - 1]]; *p; p++) prev_segs += *p == '/';
      if (prev_segs >= segs) break;
      idx[j] = idx[j - 1];
      j--;
    }
    idx[j] = cur;
  }
  SomMap ids;
  som_map_init(&ids);
  for (size_t i = 0; i < n; i++) {
    const SomStrList *items = spec_document_list_items(w->doc, list_order->items[idx[i]]);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      char *id = id_of(w, items->items[k]);
      som_map_set(&ids, items->items[k], id);
      free(id);
    }
  }
  DocumentJson j;
  spec_document_to_json(w->doc, &j);
  SpecDocument original;
  spec_document_copy(&original, w->doc);
  for (size_t li = 0; li < n; li++) {
    const char *lst = list_order->items[idx[li]];
    const SomStrList *order = &orders[idx[li]];
    SomStrList from, to;
    som_strlist_init(&from);
    som_strlist_init(&to);
    for (size_t i = 0; i < order->len; i++) {
      char num[32];
      snprintf(num, sizeof(num), "%zu", i + 1);
      char *target = scat(lst, "-", num, NULL);
      if (strcmp(order->items[i], target) != 0) {
        som_strlist_push_copy(&from, order->items[i]);
        som_strlist_push(&to, target);
      } else {
        free(target);
      }
    }
    if (from.len == 0) {
      som_strlist_free(&from);
      som_strlist_free(&to);
      continue;
    }
    SomMap stored_ids;
    som_map_init(&stored_ids);
    for (size_t i = 0; i < j.lists_len; i++) {
      if (strcmp(j.lists[i].key, lst) == 0) {
        for (size_t k = 0; k < j.lists[i].ids.len; k++) {
          som_map_set(&stored_ids, j.lists[i].ids.entries[k].key,
                      j.lists[i].ids.entries[k].val);
        }
      }
    }
    const SomStrList *orig = spec_document_list_items(&original, lst);
    for (size_t i = 0; i < order->len; i++) {
      const char *it = order->items[i];
      long pos = -1;
      for (size_t k = 0; orig != NULL && k < orig->len; k++) {
        if (strcmp(orig->items[k], it) == 0) {
          pos = (long)k;
          break;
        }
      }
      if (pos != (long)i && som_map_get(&stored_ids, it) == NULL) {
        const char *id = som_map_get(&ids, it);
        if (id != NULL) som_map_set(&stored_ids, it, id);
      }
    }
    rename_store(&j.content, &from, &to);
    rename_store(&j.headlines, &from, &to);
    rename_store(&j.code_specs, &from, &to);
    rename_store(&j.units, &from, &to);
    DocumentJson next;
    document_json_init(&next);
    for (size_t i = 0; i < j.forms_len; i++) {
      char *k = rename_key(j.forms[i].key, &from, &to);
      SomMap *fields = document_json_form_fields(&next, k);
      som_map_clear(fields);
      for (size_t f = 0; f < j.forms[i].fields.len; f++) {
        som_map_set(fields, j.forms[i].fields.entries[f].key,
                    j.forms[i].fields.entries[f].val);
      }
      free(k);
    }
    for (size_t i = 0; i < j.lists_len; i++) {
      const DocListEntry *value = &j.lists[i];
      char *k = rename_key(value->key, &from, &to);
      DocListEntry *e = document_json_list_entry(&next, k);
      free(k);
      som_strlist_free(&e->items);
      som_strlist_init(&e->items);
      som_map_clear(&e->ids);
      e->seq = value->seq;
      if (strcmp(value->key, lst) == 0) {
        for (size_t o = 0; o < order->len; o++) {
          char *rk = rename_key(order->items[o], &from, &to);
          const char *id = som_map_get(&stored_ids, order->items[o]);
          if (id != NULL) som_map_set(&e->ids, rk, id);
          som_strlist_push(&e->items, rk);
        }
      } else {
        for (size_t o = 0; o < value->items.len; o++) {
          som_strlist_push(&e->items, rename_key(value->items.items[o], &from, &to));
        }
        for (size_t o = 0; o < value->ids.len; o++) {
          char *rk = rename_key(value->ids.entries[o].key, &from, &to);
          som_map_set(&e->ids, rk, value->ids.entries[o].val);
          free(rk);
        }
      }
    }
    /* The renamed forms and lists replace the old ones. */
    SomMap content = j.content, headlines = j.headlines, code_specs = j.code_specs,
           units = j.units;
    som_map_init(&j.content);
    som_map_init(&j.headlines);
    som_map_init(&j.code_specs);
    som_map_init(&j.units);
    document_json_free(&j);
    j = next;
    som_map_free(&j.content);
    som_map_free(&j.headlines);
    som_map_free(&j.code_specs);
    som_map_free(&j.units);
    j.content = content;
    j.headlines = headlines;
    j.code_specs = code_specs;
    j.units = units;
    som_map_free(&stored_ids);
    som_strlist_free(&from);
    som_strlist_free(&to);
  }
  spec_document_load_json(w->doc, &j);
  document_json_free(&j);
  spec_document_free(&original);
  som_map_free(&ids);
  free(idx);
}

/* The ids to add to and drop from one reference field. */
typedef struct {
  char *key; /* "<path>#<field>" */
  char *pair;
  SomStrList add;
  SomStrList drop;
} BackfillIds;

/* One element added: its list, id and the Phase 3 order of its list's ids. */
typedef struct {
  char *lst;
  char *id;
  SomStrList order;
} Addition;

static void apply(Backfiller *w, SpecSetFound *const *found, size_t n) {
  /* 1. Elements only in the Blueprint go, first. */
  for (size_t i = 0; i < n; i++) {
    const SpecSetFound *o = found[i];
    if (o->finding.code != SPEC_SYNC_CODE_SHARED_ELEMENT_ONLY_IN_BLUEPRINT ||
        strncmp(o->key, "i:", 2) != 0 || o->b == NULL) {
      continue;
    }
    const char *item_c = som_map_get(&o->b->items, o->key + 2);
    if (item_c == NULL) continue;
    char *item = som_strdup(item_c);
    if (spec_document_remove_list_item(w->doc, item)) {
      som_map_set(&w->pairs, o->finding.pair, "1");
      push_change(w, o->finding.pair, SPEC_BACKFILL_CHANGE_ELEMENT_REMOVED, item, "",
                  som_strdup(spec_sync_place_value_or(&o->finding.blueprint)), NULL);
    }
    free(item);
  }

  /* 2. Values, and the ids of reference fields. */
  BackfillIds *ids = NULL;
  size_t ids_len = 0;
  for (size_t i = 0; i < n; i++) {
    const SpecSetFound *o = found[i];
    const SpecSyncFinding *f = &o->finding;
    if (strncmp(o->key, "i:", 2) == 0) continue;
    const char *field = or_empty(f->blueprint.field);
    switch (f->code) {
      case SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS:
      case SPEC_SYNC_CODE_SHARED_VALUE_MISSING: {
        const SpecSetValue *v = o->d != NULL ? spec_set_side_value(o->d, o->key) : NULL;
        write_value(w, f->pair, f->blueprint.path, field, v != NULL ? v->value : "");
        break;
      }
      case SPEC_SYNC_CODE_SHARED_VALUE_ONLY_IN_BLUEPRINT:
        write_value(w, f->pair, f->blueprint.path, field, "");
        break;
      case SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING:
      case SPEC_SYNC_CODE_SHARED_ELEMENT_ONLY_IN_BLUEPRINT: {
        char *key = scat(f->blueprint.path, "#", field, NULL);
        BackfillIds *e = NULL;
        for (size_t k = 0; k < ids_len; k++) {
          if (strcmp(ids[k].key, key) == 0) e = &ids[k];
        }
        if (e == NULL) {
          ids = (BackfillIds *)realloc(ids, (ids_len + 1) * sizeof(BackfillIds));
          e = &ids[ids_len++];
          e->key = som_strdup(key);
          e->pair = som_strdup(f->pair);
          som_strlist_init(&e->add);
          som_strlist_init(&e->drop);
        }
        free(key);
        int missing = f->code == SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING;
        SomStrList *list = missing ? &e->add : &e->drop;
        const char *x = missing ? spec_sync_place_value_or(&f->detail)
                                : spec_sync_place_value_or(&f->blueprint);
        if (!som_strlist_contains(list, x)) som_strlist_push_copy(list, x);
        break;
      }
      default:
        break;
    }
  }
  for (size_t k = 0; k < ids_len; k++) {
    BackfillIds *e = &ids[k];
    const char *hash = strrchr(e->key, '#');
    char *p = som_strdup_n(e->key, (size_t)(hash - e->key));
    const char *field = hash + 1;
    SomStrList now;
    som_strlist_init(&now);
    const char *cur = spec_set_get_value(w->doc, p, field);
    const char *s = cur;
    for (;;) {
      const char *comma = strchr(s, ',');
      size_t len = comma != NULL ? (size_t)(comma - s) : strlen(s);
      char *piece = som_strdup_n(s, len);
      char *t = trim_dup(piece);
      free(piece);
      if (t[0] != '\0' && !som_strlist_contains(&e->drop, t)) {
        som_strlist_push(&now, t);
      } else {
        free(t);
      }
      if (comma == NULL) break;
      s = comma + 1;
    }
    for (size_t a = 0; a < e->add.len; a++) {
      if (!som_strlist_contains(&now, e->add.items[a])) {
        som_strlist_push_copy(&now, e->add.items[a]);
      }
    }
    char *joined = som_strlist_join(&now, ", ");
    write_value(w, e->pair, p, field, joined);
    free(joined);
    som_strlist_free(&now);
    free(p);
  }
  for (size_t k = 0; k < ids_len; k++) {
    free(ids[k].key);
    free(ids[k].pair);
    som_strlist_free(&ids[k].add);
    som_strlist_free(&ids[k].drop);
  }
  free(ids);

  /* 3. Elements only in the Phase 3 document come in, each with every value
   * the pair shares beneath it, then take their place. */
  Addition *additions = NULL;
  size_t additions_len = 0;
  for (size_t i = 0; i < n; i++) {
    const SpecSetFound *o = found[i];
    if (o->finding.code != SPEC_SYNC_CODE_SHARED_ELEMENT_MISSING ||
        strncmp(o->key, "i:", 2) != 0 || o->d == NULL) {
      continue;
    }
    const SpecSetSide *d = o->d;
    const char *rel = o->key + 2;
    char *id = bracket_id(rel);
    const char *lst = o->finding.blueprint.path;
    char *detail_item = som_strdup(or_empty(som_map_get(&d->items, rel)));
    char *item = spec_set_add_item(w->doc, lst, id);
    som_map_set(&w->pairs, o->finding.pair, "1");
    push_change(w, o->finding.pair, SPEC_BACKFILL_CHANGE_ELEMENT_ADDED, item, "",
                NULL, som_strdup(id));
    /* Nested elements first (shortest key first), then the values. */
    SomStrList from, to;
    som_strlist_init(&from);
    som_strlist_init(&to);
    som_strlist_push_copy(&from, detail_item);
    som_strlist_push_copy(&to, item);
    char *rel_prefix = scat(rel, "/", NULL);
    SomStrList nested;
    som_strlist_init(&nested);
    for (size_t k = 0; k < d->item_keys.len; k++) {
      if (strncmp(d->item_keys.items[k], rel_prefix, strlen(rel_prefix)) == 0) {
        som_strlist_push_copy(&nested, d->item_keys.items[k]);
      }
    }
    /* Stable sort by length. */
    for (size_t a = 1; a < nested.len; a++) {
      char *cur = nested.items[a];
      size_t b = a;
      while (b > 0 && strlen(nested.items[b - 1]) > strlen(cur)) {
        nested.items[b] = nested.items[b - 1];
        b--;
      }
      nested.items[b] = cur;
    }
    for (size_t k = 0; k < nested.len; k++) {
      const char *nk = nested.items[k];
      char *d_path = som_strdup(or_empty(som_map_get(&d->items, nk)));
      long m = best_mapping(&from, d_path, 0);
      if (m < 0) {
        free(d_path);
        continue;
      }
      const char *seg = d_path + strlen(from.items[m]) + 1;
      char *nested_id = bracket_id(nk);
      char *seg_list = list_of_item(seg);
      char *target_list = scat(to.items[m], "/", seg_list, NULL);
      char *new_item = spec_set_add_item(w->doc, target_list, nested_id);
      som_strlist_push(&from, d_path);
      som_strlist_push(&to, new_item);
      free(target_list);
      free(seg_list);
      free(nested_id);
    }
    som_strlist_free(&nested);
    for (size_t k = 0; k < d->values_len; k++) {
      const SpecSetValue *v = &d->values[k];
      const char *body = v->key + 2;
      const char *hash = strchr(body, '#');
      char *r = hash != NULL ? som_strdup_n(body, (size_t)(hash - body))
                             : som_strdup(body);
      int ours = strcmp(r, rel) == 0 || strncmp(r, rel_prefix, strlen(rel_prefix)) == 0;
      free(r);
      if (!ours) continue;
      long m = best_mapping(&from, v->path, 1);
      if (m < 0 || v->value[0] == '\0') continue;
      char *target = scat(to.items[m], v->path + strlen(from.items[m]), NULL);
      spec_set_set_value(w->doc, target, v->field, v->value);
      free(target);
    }
    free(rel_prefix);
    som_strlist_free(&from);
    som_strlist_free(&to);
    /* The detail list's order, by id. */
    SomStrList order;
    som_strlist_init(&order);
    const SpecDocument *detail_doc =
        o->finding.detail.document != NULL
            ? spec_document_set_get(w->set, o->finding.detail.document)
            : NULL;
    if (detail_doc != NULL) {
      char *dl = list_of_item(detail_item);
      const SomStrList *items = spec_document_list_items(detail_doc, dl);
      for (size_t k = 0; items != NULL && k < items->len; k++) {
        som_strlist_push(&order, spec_set_effective_item_id(&w->refl, detail_doc,
                                                            items->items[k]));
      }
      free(dl);
    }
    additions = (Addition *)realloc(additions,
                                    (additions_len + 1) * sizeof(Addition));
    additions[additions_len].lst = som_strdup(lst);
    additions[additions_len].id = id;
    additions[additions_len].order = order;
    additions_len++;
    free(item);
    free(detail_item);
  }
  /* Each list takes its new elements in one reorder: an element goes after its
   * nearest preceding neighbour (in the Phase 3 order) the Blueprint holds, or
   * first. */
  SomStrList list_order;
  som_strlist_init(&list_order);
  for (size_t a = 0; a < additions_len; a++) {
    if (!som_strlist_contains(&list_order, additions[a].lst)) {
      som_strlist_push_copy(&list_order, additions[a].lst);
    }
  }
  SomStrList *orders = (SomStrList *)calloc(list_order.len ? list_order.len : 1,
                                            sizeof(SomStrList));
  for (size_t l = 0; l < list_order.len; l++) {
    const char *lst = list_order.items[l];
    SomMap new_ids;
    som_map_init(&new_ids);
    for (size_t a = 0; a < additions_len; a++) {
      if (strcmp(additions[a].lst, lst) == 0) som_map_set(&new_ids, additions[a].id, "1");
    }
    SomStrList items, item_ids;
    const SomStrList *live = spec_document_list_items(w->doc, lst);
    if (live != NULL) {
      som_strlist_copy(&items, live);
    } else {
      som_strlist_init(&items);
    }
    som_strlist_init(&item_ids);
    for (size_t k = 0; k < items.len; k++) som_strlist_push(&item_ids, id_of(w, items.items[k]));
    SomStrList order_now, order_now_ids;
    som_strlist_init(&order_now);
    som_strlist_init(&order_now_ids);
    for (size_t k = 0; k < items.len; k++) {
      if (som_map_get(&new_ids, item_ids.items[k]) == NULL) {
        som_strlist_push_copy(&order_now, items.items[k]);
        som_strlist_push_copy(&order_now_ids, item_ids.items[k]);
      }
    }
    for (size_t a = 0; a < additions_len; a++) {
      if (strcmp(additions[a].lst, lst) != 0) continue;
      const char *id = additions[a].id;
      const SomStrList *order = &additions[a].order;
      const char *item = "";
      for (size_t k = 0; k < items.len; k++) {
        if (strcmp(item_ids.items[k], id) == 0) {
          item = items.items[k];
          break;
        }
      }
      size_t before_len = 0;
      long at_id = -1;
      for (size_t k = 0; k < order->len; k++) {
        if (strcmp(order->items[k], id) == 0) {
          at_id = (long)k;
          break;
        }
      }
      if (at_id >= 0) {
        before_len = (size_t)at_id;
      } else if (order->len > 0) {
        before_len = order->len - 1;
      }
      size_t at = 0;
      for (size_t b = before_len; b > 0; b--) {
        const char *want = order->items[b - 1];
        long k_hit = -1;
        for (size_t k = 0; k < order_now_ids.len; k++) {
          if (strcmp(order_now_ids.items[k], want) == 0) {
            k_hit = (long)k;
            break;
          }
        }
        if (k_hit >= 0) {
          at = (size_t)k_hit + 1;
          break;
        }
      }
      /* Insert at `at` in both lists. */
      som_strlist_push_copy(&order_now, item);
      som_strlist_push_copy(&order_now_ids, id);
      for (size_t k = order_now.len - 1; k > at; k--) {
        char *t = order_now.items[k];
        order_now.items[k] = order_now.items[k - 1];
        order_now.items[k - 1] = t;
        t = order_now_ids.items[k];
        order_now_ids.items[k] = order_now_ids.items[k - 1];
        order_now_ids.items[k - 1] = t;
      }
    }
    orders[l] = order_now;
    som_strlist_free(&order_now_ids);
    som_strlist_free(&items);
    som_strlist_free(&item_ids);
    som_map_free(&new_ids);
  }
  reorder(w, &list_order, orders);
  for (size_t l = 0; l < list_order.len; l++) som_strlist_free(&orders[l]);
  free(orders);
  som_strlist_free(&list_order);
  for (size_t a = 0; a < additions_len; a++) {
    free(additions[a].lst);
    free(additions[a].id);
    som_strlist_free(&additions[a].order);
  }
  free(additions);
  /* Each added element is reported at the place it took. */
  for (size_t i = 0; i < w->out->changes_len; i++) {
    SpecBackfillChange *ch = &w->out->changes[i];
    if (ch->kind != SPEC_BACKFILL_CHANGE_ELEMENT_ADDED) continue;
    char *lst = list_of_item(ch->path);
    const SomStrList *items = spec_document_list_items(w->doc, lst);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      char *id = id_of(w, items->items[k]);
      int hit = strcmp(id, ch->new_value) == 0;
      free(id);
      if (hit) {
        if (strcmp(items->items[k], ch->path) != 0) {
          free(ch->path);
          ch->path = som_strdup(items->items[k]);
        }
        break;
      }
    }
    free(lst);
  }
}

/* Adds one entry to the Blueprint's revision history naming the pairs. */
static void revision_entry(Backfiller *w, const char *author, const char *date) {
  SpecSectionPositionList positions;
  spec_section_positions(&w->refl, w->set->blueprint_root, &positions);
  char *lst = NULL;
  for (size_t i = 0; i < positions.len && lst == NULL; i++) {
    const SpecSectionPosition *p = &positions.items[i];
    const SpecField *member = p->member;
    if (!p->is_member || member == NULL ||
        strcmp(member->kind, SPEC_FIELD_KIND_LIST) != 0) {
      continue;
    }
    if (strstr(p->path, "-*") != NULL) continue;
    const SpecClass *el = spec_reflection_class_named(&w->refl, member->element_type);
    if (el == NULL || strcmp(or_empty(el->section_id), "RVENT") != 0) continue;
    lst = som_strdup(p->path);
  }
  spec_section_position_list_free(&positions);
  if (lst == NULL) return;
  const SomStrList *items = spec_document_list_items(w->doc, lst);
  char *last = som_strdup("");
  if (items != NULL && items->len > 0) {
    char *form = scat(items->items[items->len - 1], "/content", NULL);
    free(last);
    last = som_strdup(or_empty(spec_document_form_field(w->doc, form, "version")));
    free(form);
  }
  char *version = spec_backfill_bump(last);
  free(last);
  char *item = spec_document_add_list_item(w->doc, lst);
  SomStrList names;
  som_strlist_init(&names);
  for (size_t p = 0; p < w->set->pairs_len; p++) {
    const char *sid = w->set->pairs[p].section_id;
    if (som_map_get(&w->pairs, sid) != NULL && !som_strlist_contains(&names, sid)) {
      som_strlist_push_copy(&names, sid);
    }
  }
  SomStrList all, others;
  spec_document_set_names(w->set, &all);
  som_strlist_init(&others);
  for (size_t i = 0; i < all.len; i++) {
    if (strcmp(all.items[i], w->name) != 0) som_strlist_push_copy(&others, all.items[i]);
  }
  char *others_j = som_strlist_join(&others, ", ");
  char *names_j = som_strlist_join(&names, ", ");
  char *summary = scat("Backfilled from ", others_j, ": ", names_j, NULL);
  char *form = scat(item, "/content", NULL);
  spec_document_set_form_field(w->doc, form, "version", version);
  spec_document_set_form_field(w->doc, form, "date", date);
  spec_document_set_form_field(w->doc, form, "author", author);
  spec_document_set_form_field(w->doc, form, "summary", summary);
  push_change(w, "", SPEC_BACKFILL_CHANGE_REVISION, item, "", NULL, version);
  free(form);
  free(summary);
  free(others_j);
  free(names_j);
  som_strlist_free(&all);
  som_strlist_free(&others);
  som_strlist_free(&names);
  free(item);
  free(lst);
}

/* ---- backfill -------------------------------------------------------------------- */

int spec_backfill(SpecDocumentSet *set, const SpecBackfillOptions *options,
                  SpecBackfillResult *out, SpecBackfillError *err) {
  memset(out, 0, sizeof(*out));
  spec_document_init(&out->blueprint);
  SpecBackfillOptions none;
  memset(&none, 0, sizeof(none));
  if (options == NULL) options = &none;
  const SomStrList *scope = options->pairs;
  const char *bp_name_c = spec_document_set_name_of(set, set->blueprint_root);
  if (bp_name_c == NULL) {
    if (err != NULL) {
      spec_backfill_error_free(err);
      err->code = SPEC_BACKFILL_ERROR_NO_BLUEPRINT;
      err->message = som_strdup("the set holds no Blueprint");
    }
    return 0;
  }
  char *bp_name = som_strdup(bp_name_c);
  SpecReflection refl = spec_reflection_make(set->model);

  /* No review in progress. */
  SpecSyncPlace *marked = NULL;
  size_t marked_len = 0;
  SomStrList names;
  spec_document_set_names(set, &names);
  for (size_t ni = 0; ni < names.len; ni++) {
    const char *name = names.items[ni];
    SpecDocument *doc = spec_document_set_get_mut(set, name);
    if (doc == NULL) continue;
    const char *root_type = spec_document_set_root_of(set, name);
    const char *root = "";
    for (size_t r = 0; r < set->model->roots_len; r++) {
      if (strcmp(set->model->roots[r].type, root_type) == 0) {
        root = spec_reflection_root_segment(&set->model->roots[r]);
        break;
      }
    }
    SomMap seen;
    som_map_init(&seen);
    SpecReviewAnnotations ra = spec_review_annotations_make(doc, NULL);
    SpecReviewAnnotationList list;
    spec_review_annotations_list(&ra, &list);
    for (size_t a = 0; a < list.len; a++) {
      const SpecReviewAnnotation *an = &list.items[a];
      const char *field = or_empty(an->field);
      char *key = scat(an->path, "#", field, NULL);
      int fresh = som_map_get(&seen, key) == NULL;
      som_map_set(&seen, key, "1");
      free(key);
      if (!fresh) continue;
      marked = (SpecSyncPlace *)realloc(marked, (marked_len + 1) * sizeof(SpecSyncPlace));
      SpecSyncPlace *p = &marked[marked_len++];
      p->document = som_strdup(name);
      p->root = som_strdup(root);
      p->path = som_strdup(an->path);
      p->field = som_strdup(field);
      p->value = NULL;
      p->pending_marks = 0;
    }
    spec_review_annotation_list_free(&list);
    som_map_free(&seen);
  }
  som_strlist_free(&names);
  if (marked_len > 0) {
    if (err != NULL) {
      spec_backfill_error_free(err);
      err->code = SPEC_BACKFILL_ERROR_SET_HAS_MARKS;
      char count[32];
      snprintf(count, sizeof(count), "%zu", marked_len);
      err->message = scat("the set holds ", count,
                          " value(s) with inline marks or annotation blocks; "
                          "backfill carries the end state of an accepted review, "
                          "so decide them first",
                          NULL);
      err->places = marked;
      err->places_len = marked_len;
    } else {
      for (size_t i = 0; i < marked_len; i++) spec_sync_place_free(&marked[i]);
      free(marked);
    }
    free(bp_name);
    return 0;
  }

  spec_document_free(&out->blueprint);
  spec_document_copy(&out->blueprint, spec_document_set_get(set, bp_name));
  SpecSetCheck c;
  spec_set_check_init(&c, set);
  size_t index = 0;
  for (size_t i = 0; i < set->pairs_len; i++) {
    if (spec_set_in_scope(scope, set->pairs[i].section_id)) {
      spec_set_check_compare_pair(&c, &set->pairs[i], index);
    }
    index++;
  }
  /* The links across two documents are the agent's; they are listed as
   * left. */
  spec_set_check_cross_checks(&c, scope, index);
  spec_set_check_sort_out_by_code(&c);

  Backfiller w;
  w.set = set;
  w.refl = refl;
  w.doc = &out->blueprint;
  w.name = bp_name;
  w.out = out;
  som_map_init(&w.pairs);
  SpecSetFound **to_apply =
      (SpecSetFound **)malloc((c.out_len ? c.out_len : 1) * sizeof(SpecSetFound *));
  size_t n_apply = 0;
  const char *path = or_empty(options->path);
  out->left = (SpecBackfillLeft *)calloc(c.out_len ? c.out_len : 1,
                                         sizeof(SpecBackfillLeft));
  for (size_t i = 0; i < c.out_len; i++) {
    SpecSetFound *o = &c.out[i];
    const SpecSyncFinding *f = &o->finding;
    if (path[0] != '\0' && strcmp(f->blueprint.path, path) != 0 &&
        !beneath_path(f->blueprint.path, path)) {
      continue;
    }
    if (f->resolution == SPEC_SYNC_RESOLUTION_BACKFILL) {
      to_apply[n_apply++] = o;
      continue;
    }
    SpecBackfillLeft *l = &out->left[out->left_len++];
    spec_sync_finding_copy(&l->finding, f);
    if (f->holder == SPEC_SYNC_HOLDER_BLUEPRINT) {
      l->reason.kind = SPEC_BACKFILL_LEFT_HELD_HERE;
    } else if (f->code == SPEC_SYNC_CODE_SHARED_ELEMENT_MAY_BE_ADDED) {
      l->reason.kind = SPEC_BACKFILL_LEFT_MAY_BE_ADDED;
    } else {
      l->reason.kind = SPEC_BACKFILL_LEFT_RESOLUTION;
    }
    l->reason.resolution = f->resolution;
  }
  apply(&w, to_apply, n_apply);
  free(to_apply);
  if (out->changes_len > 0) {
    char *date = has_text(options->date) ? som_strdup(options->date) : spec_today();
    revision_entry(&w, has_text(options->author) ? options->author : "backfill", date);
    free(date);
    SpecDeriveOptions plain;
    memset(&plain, 0, sizeof(plain));
    SpecDeriveResult derived;
    spec_derive_fields(set->model, &out->blueprint, &plain, &derived);
    for (size_t i = 0; i < derived.changes_len; i++) {
      const SpecDeriveChange *dc = &derived.changes[i];
      push_change(&w, "", SPEC_BACKFILL_CHANGE_DERIVED, dc->path, dc->field,
                  som_strdup(dc->old_value), som_strdup(dc->new_value));
    }
    spec_derive_result_free(&derived);
  }
  som_map_free(&w.pairs);
  spec_set_check_free(&c);
  if (!options->dry_run) spec_document_set_replace(set, bp_name, &out->blueprint);
  free(bp_name);
  return 1;
}
