#include "spec_document.h"

#include <stdlib.h>
#include <string.h>

/* ---- is_under ----------------------------------------------------------- */

/* Reports whether `key` is `prefix` itself or nested beneath it (`prefix/...`
 * or `prefix-...`). Mirrors the Rust `is_under`. */
static int is_under(const char *key, const char *prefix) {
  size_t pn = strlen(prefix);
  if (strcmp(key, prefix) == 0) {
    return 1;
  }
  if (strncmp(key, prefix, pn) != 0) {
    return 0;
  }
  return key[pn] == '/' || key[pn] == '-';
}

/* ---- form store (byte-sorted array of DocFormEntry) --------------------- */

/* Binary search; returns 1 and writes `*pos` to the index when found, else 0
 * and writes the insertion point. */
static int form_search(const DocFormEntry *arr, size_t len, const char *key,
                       size_t *pos) {
  size_t lo = 0, hi = len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(arr[mid].key, key);
    if (cmp == 0) {
      *pos = mid;
      return 1;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  *pos = lo;
  return 0;
}

static DocFormEntry *form_get_or_create(DocFormEntry **arr, size_t *len,
                                        size_t *cap, const char *key) {
  size_t pos;
  if (form_search(*arr, *len, key, &pos)) {
    return &(*arr)[pos];
  }
  if (*len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    *arr = (DocFormEntry *)realloc(*arr, *cap * sizeof(DocFormEntry));
  }
  memmove(&(*arr)[pos + 1], &(*arr)[pos],
          (*len - pos) * sizeof(DocFormEntry));
  (*arr)[pos].key = som_strdup(key);
  som_map_init(&(*arr)[pos].fields);
  (*len)++;
  return &(*arr)[pos];
}

static DocFormEntry *form_get(DocFormEntry *arr, size_t len, const char *key) {
  size_t pos;
  if (form_search(arr, len, key, &pos)) {
    return &arr[pos];
  }
  return NULL;
}

static void form_remove(DocFormEntry **arr, size_t *len, const char *key) {
  size_t pos;
  if (!form_search(*arr, *len, key, &pos)) {
    return;
  }
  free((*arr)[pos].key);
  som_map_free(&(*arr)[pos].fields);
  memmove(&(*arr)[pos], &(*arr)[pos + 1],
          (*len - pos - 1) * sizeof(DocFormEntry));
  (*len)--;
}

/* ---- list-items store (byte-sorted array of DocListItems) --------------- */

static int li_search(const DocListItems *arr, size_t len, const char *key,
                     size_t *pos) {
  size_t lo = 0, hi = len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(arr[mid].key, key);
    if (cmp == 0) {
      *pos = mid;
      return 1;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  *pos = lo;
  return 0;
}

static DocListItems *li_get_or_create(DocListItems **arr, size_t *len,
                                      size_t *cap, const char *key) {
  size_t pos;
  if (li_search(*arr, *len, key, &pos)) {
    return &(*arr)[pos];
  }
  if (*len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    *arr = (DocListItems *)realloc(*arr, *cap * sizeof(DocListItems));
  }
  memmove(&(*arr)[pos + 1], &(*arr)[pos], (*len - pos) * sizeof(DocListItems));
  (*arr)[pos].key = som_strdup(key);
  som_strlist_init(&(*arr)[pos].items);
  (*len)++;
  return &(*arr)[pos];
}

static DocListItems *li_get(DocListItems *arr, size_t len, const char *key) {
  size_t pos;
  if (li_search(arr, len, key, &pos)) {
    return &arr[pos];
  }
  return NULL;
}

static void li_remove_at(DocListItems **arr, size_t *len, size_t pos) {
  free((*arr)[pos].key);
  som_strlist_free(&(*arr)[pos].items);
  memmove(&(*arr)[pos], &(*arr)[pos + 1],
          (*len - pos - 1) * sizeof(DocListItems));
  (*len)--;
}

/* ---- DocListEntry store (byte-sorted, for DocumentJson) ----------------- */

static int le_search(const DocListEntry *arr, size_t len, const char *key,
                     size_t *pos) {
  size_t lo = 0, hi = len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(arr[mid].key, key);
    if (cmp == 0) {
      *pos = mid;
      return 1;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  *pos = lo;
  return 0;
}

static DocListEntry *le_insert(DocListEntry **arr, size_t *len, size_t *cap,
                               const char *key) {
  size_t pos;
  if (le_search(*arr, *len, key, &pos)) {
    return &(*arr)[pos];
  }
  if (*len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    *arr = (DocListEntry *)realloc(*arr, *cap * sizeof(DocListEntry));
  }
  memmove(&(*arr)[pos + 1], &(*arr)[pos], (*len - pos) * sizeof(DocListEntry));
  (*arr)[pos].key = som_strdup(key);
  (*arr)[pos].seq = 0;
  som_strlist_init(&(*arr)[pos].items);
  som_map_init(&(*arr)[pos].ids);
  (*len)++;
  return &(*arr)[pos];
}

/* ======================================================================== */
/* DocumentJson                                                              */
/* ======================================================================== */

void document_json_init(DocumentJson *d) {
  som_map_init(&d->content);
  d->forms = NULL;
  d->forms_len = 0;
  d->forms_cap = 0;
  d->lists = NULL;
  d->lists_len = 0;
  d->lists_cap = 0;
}

void document_json_free(DocumentJson *d) {
  som_map_free(&d->content);
  for (size_t i = 0; i < d->forms_len; i++) {
    free(d->forms[i].key);
    som_map_free(&d->forms[i].fields);
  }
  free(d->forms);
  for (size_t i = 0; i < d->lists_len; i++) {
    free(d->lists[i].key);
    som_strlist_free(&d->lists[i].items);
    som_map_free(&d->lists[i].ids);
  }
  free(d->lists);
  document_json_init(d);
}

void document_json_from_json(const SomJson *v, DocumentJson *out) {
  document_json_init(out);

  const SomJson *content = som_json_get(v, "content");
  if (content != NULL && content->type == SOM_JSON_OBJECT) {
    for (size_t i = 0; i < content->as.object.len; i++) {
      const SomJsonMember *m = &content->as.object.members[i];
      const char *s = som_json_as_str(m->value);
      if (s != NULL) {
        som_map_set(&out->content, m->key, s);
      }
    }
  }

  const SomJson *forms = som_json_get(v, "forms");
  if (forms != NULL && forms->type == SOM_JSON_OBJECT) {
    for (size_t i = 0; i < forms->as.object.len; i++) {
      const SomJsonMember *m = &forms->as.object.members[i];
      if (m->value->type != SOM_JSON_OBJECT) {
        continue;
      }
      DocFormEntry *e =
          form_get_or_create(&out->forms, &out->forms_len, &out->forms_cap, m->key);
      for (size_t j = 0; j < m->value->as.object.len; j++) {
        const SomJsonMember *fm = &m->value->as.object.members[j];
        const char *s = som_json_as_str(fm->value);
        if (s != NULL) {
          som_map_set(&e->fields, fm->key, s);
        }
      }
    }
  }

  const SomJson *lists = som_json_get(v, "lists");
  if (lists != NULL && lists->type == SOM_JSON_OBJECT) {
    for (size_t i = 0; i < lists->as.object.len; i++) {
      const SomJsonMember *m = &lists->as.object.members[i];
      DocListEntry *e =
          le_insert(&out->lists, &out->lists_len, &out->lists_cap, m->key);
      long long seq = 0;
      som_json_as_i64(som_json_get(m->value, "seq"), &seq);
      e->seq = seq;
      const SomJson *items = som_json_get(m->value, "items");
      size_t n = som_json_array_len(items);
      for (size_t j = 0; j < n; j++) {
        const char *s = som_json_as_str(som_json_array_at(items, j));
        if (s != NULL) {
          som_strlist_push_copy(&e->items, s);
        }
      }
      const SomJson *ids = som_json_get(m->value, "ids");
      if (ids != NULL && ids->type == SOM_JSON_OBJECT) {
        for (size_t j = 0; j < ids->as.object.len; j++) {
          const SomJsonMember *im = &ids->as.object.members[j];
          const char *s = som_json_as_str(im->value);
          if (s != NULL) {
            som_map_set(&e->ids, im->key, s);
          }
        }
      }
    }
  }
}

SomMap *document_json_form_fields(DocumentJson *d, const char *key) {
  DocFormEntry *e =
      form_get_or_create(&d->forms, &d->forms_len, &d->forms_cap, key);
  return &e->fields;
}

DocListEntry *document_json_list_entry(DocumentJson *d, const char *key) {
  return le_insert(&d->lists, &d->lists_len, &d->lists_cap, key);
}

char *document_json_to_canonical_json(const DocumentJson *d) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '{');
  int first = 1;

  if (d->content.len > 0) {
    first = 0;
    som_buf_puts(&b, "\"content\":{");
    for (size_t i = 0; i < d->content.len; i++) {
      if (i > 0) {
        som_buf_putc(&b, ',');
      }
      char *k = som_json_encode_str(d->content.entries[i].key);
      char *val = som_json_encode_str(d->content.entries[i].val);
      som_buf_puts(&b, k);
      som_buf_putc(&b, ':');
      som_buf_puts(&b, val);
      free(k);
      free(val);
    }
    som_buf_putc(&b, '}');
  }

  if (d->forms_len > 0) {
    if (!first) {
      som_buf_putc(&b, ',');
    }
    first = 0;
    som_buf_puts(&b, "\"forms\":{");
    for (size_t i = 0; i < d->forms_len; i++) {
      if (i > 0) {
        som_buf_putc(&b, ',');
      }
      char *k = som_json_encode_str(d->forms[i].key);
      som_buf_puts(&b, k);
      free(k);
      som_buf_puts(&b, ":{");
      const SomMap *fields = &d->forms[i].fields;
      for (size_t j = 0; j < fields->len; j++) {
        if (j > 0) {
          som_buf_putc(&b, ',');
        }
        char *fk = som_json_encode_str(fields->entries[j].key);
        char *fv = som_json_encode_str(fields->entries[j].val);
        som_buf_puts(&b, fk);
        som_buf_putc(&b, ':');
        som_buf_puts(&b, fv);
        free(fk);
        free(fv);
      }
      som_buf_putc(&b, '}');
    }
    som_buf_putc(&b, '}');
  }

  if (d->lists_len > 0) {
    if (!first) {
      som_buf_putc(&b, ',');
    }
    som_buf_puts(&b, "\"lists\":{");
    for (size_t i = 0; i < d->lists_len; i++) {
      if (i > 0) {
        som_buf_putc(&b, ',');
      }
      char *k = som_json_encode_str(d->lists[i].key);
      som_buf_puts(&b, k);
      free(k);
      som_buf_puts(&b, ":{\"seq\":");
      som_buf_puti(&b, d->lists[i].seq);
      som_buf_puts(&b, ",\"items\":[");
      const SomStrList *items = &d->lists[i].items;
      for (size_t j = 0; j < items->len; j++) {
        if (j > 0) {
          som_buf_putc(&b, ',');
        }
        char *it = som_json_encode_str(items->items[j]);
        som_buf_puts(&b, it);
        free(it);
      }
      som_buf_putc(&b, ']');
      const SomMap *ids = &d->lists[i].ids;
      if (ids->len > 0) {
        som_buf_puts(&b, ",\"ids\":{");
        for (size_t j = 0; j < ids->len; j++) {
          if (j > 0) {
            som_buf_putc(&b, ',');
          }
          char *ik = som_json_encode_str(ids->entries[j].key);
          char *iv = som_json_encode_str(ids->entries[j].val);
          som_buf_puts(&b, ik);
          som_buf_putc(&b, ':');
          som_buf_puts(&b, iv);
          free(ik);
          free(iv);
        }
        som_buf_putc(&b, '}');
      }
      som_buf_putc(&b, '}');
    }
    som_buf_putc(&b, '}');
  }

  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ======================================================================== */
/* SpecDocument                                                             */
/* ======================================================================== */

void spec_document_init(SpecDocument *d) {
  som_map_init(&d->content);
  d->forms = NULL;
  d->forms_len = 0;
  d->forms_cap = 0;
  d->list_items = NULL;
  d->list_items_len = 0;
  d->list_items_cap = 0;
  som_map_init(&d->list_seq);
  som_map_init(&d->item_section_id);
}

void spec_document_free(SpecDocument *d) {
  som_map_free(&d->content);
  for (size_t i = 0; i < d->forms_len; i++) {
    free(d->forms[i].key);
    som_map_free(&d->forms[i].fields);
  }
  free(d->forms);
  for (size_t i = 0; i < d->list_items_len; i++) {
    free(d->list_items[i].key);
    som_strlist_free(&d->list_items[i].items);
  }
  free(d->list_items);
  som_map_free(&d->list_seq);
  som_map_free(&d->item_section_id);
  spec_document_init(d);
}

/* --- content --- */

const char *spec_document_content(const SpecDocument *d, const char *path) {
  return som_map_get(&d->content, path);
}

void spec_document_set_content(SpecDocument *d, const char *path,
                               const char *value) {
  if (value == NULL || value[0] == '\0') {
    som_map_remove(&d->content, path);
  } else {
    som_map_set(&d->content, path, value);
  }
}

/* --- forms --- */

const char *spec_document_form_field(const SpecDocument *d, const char *path,
                                     const char *field_name) {
  DocFormEntry *e = form_get(d->forms, d->forms_len, path);
  if (e == NULL) {
    return NULL;
  }
  return som_map_get(&e->fields, field_name);
}

void spec_document_set_form_field(SpecDocument *d, const char *path,
                                  const char *field_name, const char *value) {
  if (value == NULL || value[0] == '\0') {
    DocFormEntry *e = form_get(d->forms, d->forms_len, path);
    if (e != NULL) {
      som_map_remove(&e->fields, field_name);
      if (e->fields.len == 0) {
        form_remove(&d->forms, &d->forms_len, path);
      }
    }
    return;
  }
  DocFormEntry *e =
      form_get_or_create(&d->forms, &d->forms_len, &d->forms_cap, path);
  som_map_set(&e->fields, field_name, value);
}

/* --- lists --- */

const SomStrList *spec_document_list_items(const SpecDocument *d,
                                           const char *list_path) {
  DocListItems *e = li_get(d->list_items, d->list_items_len, list_path);
  return e != NULL ? &e->items : NULL;
}

char *spec_document_add_list_item(SpecDocument *d, const char *list_path) {
  long long seq = 0;
  const char *cur = som_map_get(&d->list_seq, list_path);
  if (cur != NULL) {
    som_parse_i64(cur, &seq);
  }
  seq += 1;
  char *seq_str = som_format_i64(seq);
  som_map_set(&d->list_seq, list_path, seq_str);
  free(seq_str);

  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, list_path);
  som_buf_putc(&b, '-');
  som_buf_puti(&b, seq);
  char *item_path = som_buf_take(&b);

  DocListItems *e = li_get_or_create(&d->list_items, &d->list_items_len,
                                     &d->list_items_cap, list_path);
  som_strlist_push_copy(&e->items, item_path);
  return item_path;
}

/* --- section ids --- */

/* Returns the list_items key that owns `item_path`, or NULL when none does. */
static const char *owning_list_of(const SpecDocument *d, const char *item_path) {
  for (size_t i = 0; i < d->list_items_len; i++) {
    if (som_strlist_contains(&d->list_items[i].items, item_path)) {
      return d->list_items[i].key;
    }
  }
  return NULL;
}

/* Writes `*err` (COLLISION) and returns 0 when `id` is already used by an item
 * of `list_path` other than `except_item_path` (NULL for none); else returns 1.
 * `err` may be NULL. */
static int assert_section_id_free(const SpecDocument *d, const char *list_path,
                                  const char *id, const char *except_item_path,
                                  SpecSectionIdError *err) {
  DocListItems *e = li_get(d->list_items, d->list_items_len, list_path);
  if (e != NULL) {
    for (size_t i = 0; i < e->items.len; i++) {
      const char *item_path = e->items.items[i];
      if (except_item_path != NULL && strcmp(item_path, except_item_path) == 0) {
        continue;
      }
      const char *cur = som_map_get(&d->item_section_id, item_path);
      if (cur != NULL && strcmp(cur, id) == 0) {
        if (err != NULL) {
          err->kind = SPEC_SECTION_ID_COLLISION;
          err->id = som_strdup(id);
          err->list_path = som_strdup(list_path);
        }
        return 0;
      }
    }
  }
  return 1;
}

char *spec_document_add_list_item_with_section_id(SpecDocument *d,
                                                  const char *list_path,
                                                  const char *section_id,
                                                  SpecSectionIdError *err) {
  if (!assert_section_id_free(d, list_path, section_id, NULL, err)) {
    return NULL;
  }
  char *item_path = spec_document_add_list_item(d, list_path);
  som_map_set(&d->item_section_id, item_path, section_id);
  return item_path;
}

const char *spec_document_item_section_id(const SpecDocument *d,
                                          const char *item_path) {
  return som_map_get(&d->item_section_id, item_path);
}

int spec_document_set_item_section_id(SpecDocument *d, const char *item_path,
                                      const char *id, SpecSectionIdError *err) {
  const char *owning = owning_list_of(d, item_path);
  if (owning == NULL) {
    if (err != NULL) {
      err->kind = SPEC_SECTION_ID_NOT_LIVE_ITEM;
      err->item_path = som_strdup(item_path);
    }
    return 0;
  }
  const char *cur = som_map_get(&d->item_section_id, item_path);
  if (cur != NULL && strcmp(cur, id) == 0) {
    return 1;
  }
  /* `owning` points into the store, which assert_section_id_free only reads;
   * copy defensively is unnecessary since no mutation happens before the set. */
  if (!assert_section_id_free(d, owning, id, item_path, err)) {
    return 0;
  }
  som_map_set(&d->item_section_id, item_path, id);
  return 1;
}

void spec_document_list_item_section_ids(const SpecDocument *d,
                                         const char *list_path,
                                         SomStrList *out) {
  som_strlist_init(out);
  DocListItems *e = li_get(d->list_items, d->list_items_len, list_path);
  if (e == NULL) {
    return;
  }
  for (size_t i = 0; i < e->items.len; i++) {
    const char *id = som_map_get(&d->item_section_id, e->items.items[i]);
    if (id != NULL) {
      som_strlist_push_copy(out, id);
    }
  }
}

static void purge_under(SpecDocument *d, const char *prefix) {
  for (size_t i = 0; i < d->content.len;) {
    if (is_under(d->content.entries[i].key, prefix)) {
      free(d->content.entries[i].key);
      free(d->content.entries[i].val);
      memmove(&d->content.entries[i], &d->content.entries[i + 1],
              (d->content.len - i - 1) * sizeof(SomMapEntry));
      d->content.len--;
    } else {
      i++;
    }
  }
  for (size_t i = 0; i < d->forms_len;) {
    if (is_under(d->forms[i].key, prefix)) {
      free(d->forms[i].key);
      som_map_free(&d->forms[i].fields);
      memmove(&d->forms[i], &d->forms[i + 1],
              (d->forms_len - i - 1) * sizeof(DocFormEntry));
      d->forms_len--;
    } else {
      i++;
    }
  }
  for (size_t i = 0; i < d->list_items_len;) {
    if (is_under(d->list_items[i].key, prefix)) {
      li_remove_at(&d->list_items, &d->list_items_len, i);
    } else {
      i++;
    }
  }
  for (size_t i = 0; i < d->list_seq.len;) {
    if (is_under(d->list_seq.entries[i].key, prefix)) {
      free(d->list_seq.entries[i].key);
      free(d->list_seq.entries[i].val);
      memmove(&d->list_seq.entries[i], &d->list_seq.entries[i + 1],
              (d->list_seq.len - i - 1) * sizeof(SomMapEntry));
      d->list_seq.len--;
    } else {
      i++;
    }
  }
  for (size_t i = 0; i < d->item_section_id.len;) {
    if (is_under(d->item_section_id.entries[i].key, prefix)) {
      free(d->item_section_id.entries[i].key);
      free(d->item_section_id.entries[i].val);
      memmove(&d->item_section_id.entries[i], &d->item_section_id.entries[i + 1],
              (d->item_section_id.len - i - 1) * sizeof(SomMapEntry));
      d->item_section_id.len--;
    } else {
      i++;
    }
  }
}

int spec_document_remove_list_item(SpecDocument *d, const char *item_path) {
  size_t owning = d->list_items_len;
  for (size_t i = 0; i < d->list_items_len && owning == d->list_items_len; i++) {
    if (som_strlist_contains(&d->list_items[i].items, item_path)) {
      owning = i;
    }
  }
  if (owning == d->list_items_len) {
    return 0;
  }
  SomStrList *items = &d->list_items[owning].items;
  for (size_t j = 0; j < items->len; j++) {
    if (strcmp(items->items[j], item_path) == 0) {
      som_strlist_remove_at(items, j);
      break;
    }
  }
  if (items->len == 0) {
    li_remove_at(&d->list_items, &d->list_items_len, owning);
  }
  purge_under(d, item_path);
  return 1;
}

/* --- queries --- */

int spec_document_is_empty(const SpecDocument *d) {
  return d->content.len == 0 && d->forms_len == 0 && d->list_items_len == 0;
}

int spec_document_has_values_under(const SpecDocument *d, const char *prefix) {
  for (size_t i = 0; i < d->content.len; i++) {
    if (is_under(d->content.entries[i].key, prefix)) {
      return 1;
    }
  }
  for (size_t i = 0; i < d->forms_len; i++) {
    if (is_under(d->forms[i].key, prefix)) {
      return 1;
    }
  }
  for (size_t i = 0; i < d->list_items_len; i++) {
    if (is_under(d->list_items[i].key, prefix)) {
      return 1;
    }
  }
  return 0;
}

void spec_document_content_paths(const SpecDocument *d, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < d->content.len; i++) {
    som_strlist_push_copy(out, d->content.entries[i].key);
  }
}

void spec_document_form_paths(const SpecDocument *d, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < d->forms_len; i++) {
    som_strlist_push_copy(out, d->forms[i].key);
  }
}

void spec_document_list_paths(const SpecDocument *d, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < d->list_items_len; i++) {
    som_strlist_push_copy(out, d->list_items[i].key);
  }
}

void spec_document_form_field_names(const SpecDocument *d, const char *path,
                                    SomStrList *out) {
  som_strlist_init(out);
  DocFormEntry *e = form_get(d->forms, d->forms_len, path);
  if (e == NULL) {
    return;
  }
  for (size_t i = 0; i < e->fields.len; i++) {
    som_strlist_push_copy(out, e->fields.entries[i].key);
  }
}

size_t spec_document_list_item_count(const SpecDocument *d,
                                     const char *list_path) {
  DocListItems *e = li_get(d->list_items, d->list_items_len, list_path);
  return e != NULL ? e->items.len : 0;
}

/* --- persistence --- */

void spec_document_to_json(const SpecDocument *d, DocumentJson *out) {
  document_json_init(out);
  for (size_t i = 0; i < d->content.len; i++) {
    som_map_set(&out->content, d->content.entries[i].key,
                d->content.entries[i].val);
  }
  for (size_t i = 0; i < d->forms_len; i++) {
    DocFormEntry *e =
        form_get_or_create(&out->forms, &out->forms_len, &out->forms_cap,
                           d->forms[i].key);
    for (size_t j = 0; j < d->forms[i].fields.len; j++) {
      som_map_set(&e->fields, d->forms[i].fields.entries[j].key,
                  d->forms[i].fields.entries[j].val);
    }
  }
  for (size_t i = 0; i < d->list_items_len; i++) {
    DocListEntry *e =
        le_insert(&out->lists, &out->lists_len, &out->lists_cap,
                  d->list_items[i].key);
    long long seq = 0;
    const char *cur = som_map_get(&d->list_seq, d->list_items[i].key);
    if (cur != NULL) {
      som_parse_i64(cur, &seq);
    } else {
      seq = (long long)d->list_items[i].items.len;
    }
    e->seq = seq;
    som_strlist_copy(&e->items, &d->list_items[i].items);
    for (size_t j = 0; j < d->list_items[i].items.len; j++) {
      const char *item_path = d->list_items[i].items.items[j];
      const char *id = som_map_get(&d->item_section_id, item_path);
      if (id != NULL) {
        som_map_set(&e->ids, item_path, id);
      }
    }
  }
}

void spec_document_load_json(SpecDocument *d, const DocumentJson *j) {
  /* clear all stores */
  som_map_clear(&d->content);
  for (size_t i = 0; i < d->forms_len; i++) {
    free(d->forms[i].key);
    som_map_free(&d->forms[i].fields);
  }
  d->forms_len = 0;
  for (size_t i = 0; i < d->list_items_len; i++) {
    free(d->list_items[i].key);
    som_strlist_free(&d->list_items[i].items);
  }
  d->list_items_len = 0;
  som_map_clear(&d->list_seq);
  som_map_clear(&d->item_section_id);

  for (size_t i = 0; i < j->content.len; i++) {
    som_map_set(&d->content, j->content.entries[i].key,
                j->content.entries[i].val);
  }
  for (size_t i = 0; i < j->forms_len; i++) {
    if (j->forms[i].fields.len == 0) {
      continue;
    }
    DocFormEntry *e =
        form_get_or_create(&d->forms, &d->forms_len, &d->forms_cap,
                           j->forms[i].key);
    for (size_t k = 0; k < j->forms[i].fields.len; k++) {
      som_map_set(&e->fields, j->forms[i].fields.entries[k].key,
                  j->forms[i].fields.entries[k].val);
    }
  }
  for (size_t i = 0; i < j->lists_len; i++) {
    if (j->lists[i].items.len == 0) {
      continue;
    }
    DocListItems *e = li_get_or_create(&d->list_items, &d->list_items_len,
                                       &d->list_items_cap, j->lists[i].key);
    som_strlist_copy(&e->items, &j->lists[i].items);
    long long seq = j->lists[i].seq != 0 ? j->lists[i].seq
                                         : (long long)j->lists[i].items.len;
    char *seq_str = som_format_i64(seq);
    som_map_set(&d->list_seq, j->lists[i].key, seq_str);
    free(seq_str);
    for (size_t k = 0; k < j->lists[i].ids.len; k++) {
      som_map_set(&d->item_section_id, j->lists[i].ids.entries[k].key,
                  j->lists[i].ids.entries[k].val);
    }
  }
}
