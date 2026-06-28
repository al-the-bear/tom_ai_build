#include "som_util.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- C strings ---------------------------------------------------------- */

char *som_strdup(const char *s) {
  if (s == NULL) {
    char *out = (char *)malloc(1);
    out[0] = '\0';
    return out;
  }
  return som_strdup_n(s, strlen(s));
}

char *som_strdup_n(const char *s, size_t n) {
  char *out = (char *)malloc(n + 1);
  if (s != NULL && n > 0) {
    memcpy(out, s, n);
  }
  out[n] = '\0';
  return out;
}

int som_parse_i64(const char *s, long long *out) {
  if (s == NULL || s[0] == '\0') {
    return 0;
  }
  size_t i = 0;
  if (s[0] == '-' || s[0] == '+') {
    if (s[1] == '\0') {
      return 0;
    }
    i = 1;
  }
  for (size_t k = i; s[k] != '\0'; k++) {
    if (s[k] < '0' || s[k] > '9') {
      return 0;
    }
  }
  long long v = strtoll(s, NULL, 10);
  *out = v;
  return 1;
}

int som_is_all_digits(const char *s) {
  if (s == NULL || s[0] == '\0') {
    return 0;
  }
  for (size_t k = 0; s[k] != '\0'; k++) {
    if (s[k] < '0' || s[k] > '9') {
      return 0;
    }
  }
  return 1;
}

char *som_format_i64(long long v) {
  char tmp[32];
  snprintf(tmp, sizeof(tmp), "%lld", v);
  return som_strdup(tmp);
}

/* ---- string builder ----------------------------------------------------- */

void som_buf_init(SomBuf *b) {
  b->data = NULL;
  b->len = 0;
  b->cap = 0;
}

static void som_buf_reserve(SomBuf *b, size_t extra) {
  size_t need = b->len + extra + 1; /* +1 for the trailing NUL */
  if (need <= b->cap) {
    return;
  }
  size_t cap = b->cap == 0 ? 64 : b->cap;
  while (cap < need) {
    cap *= 2;
  }
  b->data = (char *)realloc(b->data, cap);
  b->cap = cap;
}

void som_buf_putc(SomBuf *b, char c) {
  som_buf_reserve(b, 1);
  b->data[b->len++] = c;
  b->data[b->len] = '\0';
}

void som_buf_putn(SomBuf *b, const char *s, size_t n) {
  if (n == 0) {
    return;
  }
  som_buf_reserve(b, n);
  memcpy(b->data + b->len, s, n);
  b->len += n;
  b->data[b->len] = '\0';
}

void som_buf_puts(SomBuf *b, const char *s) {
  if (s == NULL) {
    return;
  }
  som_buf_putn(b, s, strlen(s));
}

void som_buf_puti(SomBuf *b, long long v) {
  char tmp[32];
  snprintf(tmp, sizeof(tmp), "%lld", v);
  som_buf_puts(b, tmp);
}

char *som_buf_take(SomBuf *b) {
  char *out;
  if (b->data == NULL) {
    out = som_strdup("");
  } else {
    out = b->data;
  }
  b->data = NULL;
  b->len = 0;
  b->cap = 0;
  return out;
}

void som_buf_free(SomBuf *b) {
  free(b->data);
  b->data = NULL;
  b->len = 0;
  b->cap = 0;
}

/* ---- string list -------------------------------------------------------- */

void som_strlist_init(SomStrList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

static void som_strlist_reserve(SomStrList *l, size_t extra) {
  size_t need = l->len + extra;
  if (need <= l->cap) {
    return;
  }
  size_t cap = l->cap == 0 ? 8 : l->cap;
  while (cap < need) {
    cap *= 2;
  }
  l->items = (char **)realloc(l->items, cap * sizeof(char *));
  l->cap = cap;
}

void som_strlist_push(SomStrList *l, char *owned) {
  som_strlist_reserve(l, 1);
  l->items[l->len++] = owned;
}

void som_strlist_push_copy(SomStrList *l, const char *s) {
  som_strlist_push(l, som_strdup(s));
}

int som_strlist_contains(const SomStrList *l, const char *s) {
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i], s) == 0) {
      return 1;
    }
  }
  return 0;
}

void som_strlist_remove_at(SomStrList *l, size_t index) {
  if (index >= l->len) {
    return;
  }
  free(l->items[index]);
  for (size_t i = index; i + 1 < l->len; i++) {
    l->items[i] = l->items[i + 1];
  }
  l->len--;
}

void som_strlist_copy(SomStrList *dst, const SomStrList *src) {
  som_strlist_init(dst);
  som_strlist_reserve(dst, src->len);
  for (size_t i = 0; i < src->len; i++) {
    dst->items[dst->len++] = som_strdup(src->items[i]);
  }
}

char *som_strlist_join(const SomStrList *l, const char *sep) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) {
      som_buf_puts(&b, sep);
    }
    som_buf_puts(&b, l->items[i]);
  }
  return som_buf_take(&b);
}

void som_strlist_free(SomStrList *l) {
  for (size_t i = 0; i < l->len; i++) {
    free(l->items[i]);
  }
  free(l->items);
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

/* ---- byte-sorted string map --------------------------------------------- */

void som_map_init(SomMap *m) {
  m->entries = NULL;
  m->len = 0;
  m->cap = 0;
}

/* Binary search: returns 1 when found (index written to *idx); otherwise 0 and
 * *idx is the insertion point that keeps the array strcmp-sorted. */
static int som_map_find(const SomMap *m, const char *key, size_t *idx) {
  size_t lo = 0;
  size_t hi = m->len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(m->entries[mid].key, key);
    if (cmp == 0) {
      *idx = mid;
      return 1;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  *idx = lo;
  return 0;
}

static void som_map_reserve(SomMap *m, size_t extra) {
  size_t need = m->len + extra;
  if (need <= m->cap) {
    return;
  }
  size_t cap = m->cap == 0 ? 8 : m->cap;
  while (cap < need) {
    cap *= 2;
  }
  m->entries = (SomMapEntry *)realloc(m->entries, cap * sizeof(SomMapEntry));
  m->cap = cap;
}

void som_map_set(SomMap *m, const char *key, const char *val) {
  size_t idx;
  if (som_map_find(m, key, &idx)) {
    free(m->entries[idx].val);
    m->entries[idx].val = som_strdup(val);
    return;
  }
  som_map_reserve(m, 1);
  for (size_t i = m->len; i > idx; i--) {
    m->entries[i] = m->entries[i - 1];
  }
  m->entries[idx].key = som_strdup(key);
  m->entries[idx].val = som_strdup(val);
  m->len++;
}

const char *som_map_get(const SomMap *m, const char *key) {
  size_t idx;
  if (som_map_find(m, key, &idx)) {
    return m->entries[idx].val;
  }
  return NULL;
}

int som_map_remove(SomMap *m, const char *key) {
  size_t idx;
  if (!som_map_find(m, key, &idx)) {
    return 0;
  }
  free(m->entries[idx].key);
  free(m->entries[idx].val);
  for (size_t i = idx; i + 1 < m->len; i++) {
    m->entries[i] = m->entries[i + 1];
  }
  m->len--;
  return 1;
}

void som_map_clear(SomMap *m) {
  for (size_t i = 0; i < m->len; i++) {
    free(m->entries[i].key);
    free(m->entries[i].val);
  }
  m->len = 0;
}

void som_map_free(SomMap *m) {
  som_map_clear(m);
  free(m->entries);
  m->entries = NULL;
  m->cap = 0;
}
