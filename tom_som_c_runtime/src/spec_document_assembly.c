/* spec_document_assembly — see spec_document_assembly.h. */
#include "spec_document_assembly.h"

#include <stdlib.h>
#include <string.h>

/* ---- the writer table: (path, field) → writer fragments ------------------ */

/* One written place. `field` is NULL outside the `forms` store. Ordered by
 * path, then field — the same order as the Dart reference's compound key
 * `path\u0000field`, since NUL sorts below every other byte. */
typedef struct {
  char *path;
  char *field;
  SomStrList who;
} WriterEntry;

typedef struct {
  WriterEntry *entries;
  size_t len;
  size_t cap;
} WriterTable;

static int place_cmp(const char *path_a, const char *field_a,
                     const char *path_b, const char *field_b) {
  int c = strcmp(path_a, path_b);
  if (c != 0) {
    return c;
  }
  if (field_a == NULL || field_b == NULL) {
    return (field_a != NULL) - (field_b != NULL);
  }
  return strcmp(field_a, field_b);
}

/* Records `name` as a writer of (path, field) and returns how many fragments
 * have now written it — 1 means `name` is the first. */
static size_t writers_add(WriterTable *t, const char *path, const char *field,
                          const char *name) {
  size_t lo = 0, hi = t->len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int c = place_cmp(t->entries[mid].path, t->entries[mid].field, path, field);
    if (c == 0) {
      som_strlist_push_copy(&t->entries[mid].who, name);
      return t->entries[mid].who.len;
    }
    if (c < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (t->len == t->cap) {
    t->cap = t->cap ? t->cap * 2 : 16;
    t->entries = (WriterEntry *)realloc(t->entries, t->cap * sizeof(WriterEntry));
  }
  memmove(&t->entries[lo + 1], &t->entries[lo],
          (t->len - lo) * sizeof(WriterEntry));
  WriterEntry *e = &t->entries[lo];
  e->path = som_strdup(path);
  e->field = field != NULL ? som_strdup(field) : NULL;
  som_strlist_init(&e->who);
  som_strlist_push_copy(&e->who, name);
  t->len++;
  return 1;
}

static void writers_free(WriterTable *t) {
  for (size_t i = 0; i < t->len; i++) {
    free(t->entries[i].path);
    free(t->entries[i].field);
    som_strlist_free(&t->entries[i].who);
  }
  free(t->entries);
  t->entries = NULL;
  t->len = 0;
  t->cap = 0;
}

/* ---- stores ------------------------------------------------------------- */

/* The fixed order overlaps are reported in. */
enum { S_CONTENT, S_FORMS, S_LISTS, S_HEADLINES, S_CODE_SPECS, S_COUNT };

static const char *const k_store_names[S_COUNT] = {
    "content", "forms", "lists", "headlines", "codeSpecs"};

/* Merges one path store (content / headlines / codeSpecs): the first writer's
 * value is kept, every writer is recorded. */
static void merge_path_store(WriterTable *t, SomMap *merged, const SomMap *src,
                             const char *name) {
  for (size_t i = 0; i < src->len; i++) {
    const SomMapEntry *e = &src->entries[i];
    if (writers_add(t, e->key, NULL, name) == 1) {
      som_map_set(merged, e->key, e->val);
    }
  }
}

/* ---- public API ----------------------------------------------------------- */

char *spec_assembly_overlap_message(const SpecAssemblyOverlap *o) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, o->path);
  if (o->field != NULL) {
    som_buf_puts(&b, " field `");
    som_buf_puts(&b, o->field);
    som_buf_putc(&b, '`');
  }
  som_buf_puts(&b, " (");
  som_buf_puts(&b, o->store);
  som_buf_puts(&b, ") is written by ");
  for (size_t i = 0; i < o->fragments.len; i++) {
    if (i > 0) {
      som_buf_puts(&b, " and ");
    }
    som_buf_puts(&b, o->fragments.items[i]);
  }
  som_buf_puts(&b,
               " \xe2\x80\x94 a place two fragments both write is an "
               "authoring conflict, not something the assembly may resolve");
  return som_buf_take(&b);
}

int spec_document_assembly_ok(const SpecDocumentAssembly *a) {
  return a->overlaps_len == 0;
}

void spec_document_assembly_free(SpecDocumentAssembly *a) {
  if (a->document != NULL) {
    spec_document_free(a->document);
    free(a->document);
  }
  for (size_t i = 0; i < a->overlaps_len; i++) {
    free(a->overlaps[i].path);
    free(a->overlaps[i].field);
    som_strlist_free(&a->overlaps[i].fragments);
  }
  free(a->overlaps);
  a->document = NULL;
  a->overlaps = NULL;
  a->overlaps_len = 0;
}

void spec_document_assemble(const SpecAssemblyFragment *fragments,
                            size_t fragments_len, SpecDocumentAssembly *out) {
  out->document = NULL;
  out->overlaps = NULL;
  out->overlaps_len = 0;

  WriterTable writers[S_COUNT];
  memset(writers, 0, sizeof(writers));
  DocumentJson merged;
  document_json_init(&merged);

  for (size_t f = 0; f < fragments_len; f++) {
    const char *name = fragments[f].name;
    DocumentJson json;
    spec_document_to_json(fragments[f].document, &json);

    merge_path_store(&writers[S_CONTENT], &merged.content, &json.content, name);
    merge_path_store(&writers[S_HEADLINES], &merged.headlines, &json.headlines,
                     name);
    merge_path_store(&writers[S_CODE_SPECS], &merged.code_specs,
                     &json.code_specs, name);

    for (size_t i = 0; i < json.forms_len; i++) {
      const DocFormEntry *form = &json.forms[i];
      SomMap *target = document_json_form_fields(&merged, form->key);
      for (size_t j = 0; j < form->fields.len; j++) {
        const SomMapEntry *e = &form->fields.entries[j];
        if (writers_add(&writers[S_FORMS], form->key, e->key, name) == 1) {
          som_map_set(target, e->key, e->val);
        }
      }
    }

    for (size_t i = 0; i < json.lists_len; i++) {
      const DocListEntry *list = &json.lists[i];
      if (writers_add(&writers[S_LISTS], list->key, NULL, name) == 1) {
        DocListEntry *target = document_json_list_entry(&merged, list->key);
        target->seq = list->seq;
        som_strlist_copy(&target->items, &list->items);
        for (size_t j = 0; j < list->ids.len; j++) {
          som_map_set(&target->ids, list->ids.entries[j].key,
                      list->ids.entries[j].val);
        }
      }
    }

    document_json_free(&json);
  }

  /* Overlaps: store order, then (path, field) order — each table is sorted. */
  size_t cap = 0;
  for (int s = 0; s < S_COUNT; s++) {
    for (size_t i = 0; i < writers[s].len; i++) {
      WriterEntry *e = &writers[s].entries[i];
      if (e->who.len < 2) {
        continue;
      }
      if (out->overlaps_len == cap) {
        cap = cap ? cap * 2 : 4;
        out->overlaps = (SpecAssemblyOverlap *)realloc(
            out->overlaps, cap * sizeof(SpecAssemblyOverlap));
      }
      SpecAssemblyOverlap *o = &out->overlaps[out->overlaps_len++];
      o->store = k_store_names[s];
      o->path = e->path; /* move */
      o->field = e->field;
      o->fragments = e->who;
      e->path = NULL;
      e->field = NULL;
      som_strlist_init(&e->who);
    }
    writers_free(&writers[s]);
  }

  if (out->overlaps_len == 0) {
    out->document = (SpecDocument *)malloc(sizeof(SpecDocument));
    spec_document_init(out->document);
    spec_document_load_json(out->document, &merged);
  }
  document_json_free(&merged);
}
