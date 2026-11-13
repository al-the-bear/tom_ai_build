/* spec_generation_units — implementation. See spec_generation_units.h; a
 * faithful port of the Dart `spec_generation_units.dart`. */
#include "spec_generation_units.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"
#include "spec_reflection.h"

/* ---- small helpers ------------------------------------------------------- */

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* A fresh owned copy of `s` (NULL reads as "") with leading/trailing whitespace
 * removed. */
static char *trim_dup(const char *s) {
  if (s == NULL) {
    return som_strdup("");
  }
  while (*s != '\0' && isspace((unsigned char)*s)) {
    s++;
  }
  size_t n = strlen(s);
  while (n > 0 && isspace((unsigned char)s[n - 1])) {
    n--;
  }
  return som_strdup_n(s, n);
}

/* ---- recognition (shared with validation phase 8) ------------------------ */

const SpecField *spec_generation_form_declaring(const SpecClass *cls,
                                                const char *name) {
  for (size_t i = 0; i < cls->fields_len; i++) {
    const SpecField *f = &cls->fields[i];
    if (strcmp(f->kind, SPEC_FIELD_KIND_FORM) != 0) {
      continue;
    }
    for (size_t k = 0; k < f->form_fields_len; k++) {
      if (strcmp(f->form_fields[k].name, name) == 0) {
        return f;
      }
    }
  }
  return NULL;
}

int spec_generation_is_register(const SpecClass *cls) {
  SpecNoArtifactLink link;
  if (!spec_annotations_no_artifact(&cls->annotations, &link)) {
    return 0;
  }
  int hit = strcmp(link.reason, "generation") == 0;
  spec_no_artifact_link_free(&link);
  return hit;
}

/* ---- the unit and its list ----------------------------------------------- */

int spec_generation_unit_maps(const SpecGenerationUnit *u,
                              const char *area_code) {
  return spec_generation_unit_mapping_for(u, area_code) != NULL;
}

const char *spec_generation_unit_mapping_for(const SpecGenerationUnit *u,
                                             const char *area_code) {
  for (size_t i = 0; i < u->mappings_len; i++) {
    if (strcmp(u->mappings[i].area, area_code) == 0) {
      return u->mappings[i].mapping;
    }
  }
  return NULL;
}

static void unit_push_mapping(SpecGenerationUnit *u, char *area,
                              char *mapping) {
  if (u->mappings_len == u->mappings_cap) {
    u->mappings_cap = u->mappings_cap == 0 ? 4 : u->mappings_cap * 2;
    u->mappings = (SpecGenerationUnitMapping *)realloc(
        u->mappings, u->mappings_cap * sizeof(SpecGenerationUnitMapping));
  }
  u->mappings[u->mappings_len].area = area;
  u->mappings[u->mappings_len].mapping = mapping;
  u->mappings_len++;
}

static void unit_free(SpecGenerationUnit *u) {
  free(u->unit_id);
  free(u->kind);
  free(u->path);
  for (size_t i = 0; i < u->mappings_len; i++) {
    free(u->mappings[i].area);
    free(u->mappings[i].mapping);
  }
  free(u->mappings);
  memset(u, 0, sizeof(*u));
}

void spec_generation_unit_list_init(SpecGenerationUnitList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_generation_unit_list_free(SpecGenerationUnitList *l) {
  for (size_t i = 0; i < l->len; i++) {
    unit_free(&l->items[i]);
  }
  free(l->items);
  spec_generation_unit_list_init(l);
}

/* Appends `u` (ownership moves into the list). */
static void unit_list_push(SpecGenerationUnitList *l, SpecGenerationUnit *u) {
  if (l->len == l->cap) {
    l->cap = l->cap == 0 ? 4 : l->cap * 2;
    l->items = (SpecGenerationUnit *)realloc(
        l->items, l->cap * sizeof(SpecGenerationUnit));
  }
  l->items[l->len++] = *u;
}

/* ---- the register -------------------------------------------------------- */

/* A recognised mapping before it is given to its unit. */
typedef struct {
  char *path;
  char *area;
  char *mapping;
} RawMapping;

/* The path of the unit a mapping at `mapping_path` belongs to: the longest unit
 * path (of every recognised unit, a skipped duplicate included) that is a proper
 * prefix of it, or NULL. Borrowed from `units`. */
static const char *owner_of(const char *mapping_path,
                            const SpecGenerationUnitList *units) {
  const char *best = NULL;
  size_t best_len = 0;
  for (size_t i = 0; i < units->len; i++) {
    const char *p = units->items[i].path;
    size_t n = strlen(p);
    if (strncmp(mapping_path, p, n) == 0 && mapping_path[n] == '/' &&
        (best == NULL || n > best_len)) {
      best = p;
      best_len = n;
    }
  }
  return best;
}

void spec_generation_units(const SpecModel *model, const SpecDocument *doc,
                           SpecGenerationUnitList *out) {
  spec_generation_unit_list_init(out);
  SpecReflection refl = spec_reflection_make(model);

  /* Every recognised unit in visit order (duplicates included, as the owner
   * lookup sees them), and every recognised mapping. */
  SpecGenerationUnitList raw_units;
  spec_generation_unit_list_init(&raw_units);
  RawMapping *mappings = NULL;
  size_t mappings_len = 0;
  size_t mappings_cap = 0;

  SomStrList list_paths;
  spec_document_list_paths(doc, &list_paths);
  if (list_paths.len > 1) {
    qsort(list_paths.items, list_paths.len, sizeof(char *), cmp_str);
  }
  for (size_t li = 0; li < list_paths.len; li++) {
    const SomStrList *items =
        spec_document_list_items(doc, list_paths.items[li]);
    for (size_t ii = 0; items != NULL && ii < items->len; ii++) {
      const char *item = items->items[ii];
      SpecResolution res;
      if (!spec_reflection_resolve(&refl, item, &res)) {
        continue;
      }
      const SpecClass *cls = res.target_class;
      spec_resolution_free(&res);
      if (cls == NULL || !spec_generation_is_register(cls)) {
        continue;
      }

      const SpecField *unit_form = spec_generation_form_declaring(cls, "unitId");
      if (unit_form != NULL) {
        char *form_path =
            spec_path_join(item, spec_reflection_field_segment(unit_form));
        char *id = trim_dup(spec_document_form_field(doc, form_path, "unitId"));
        if (id[0] != '\0') {
          SpecGenerationUnit u;
          memset(&u, 0, sizeof(u));
          u.unit_id = id;
          u.kind = trim_dup(spec_document_form_field(doc, form_path, "kind"));
          u.path = som_strdup(item);
          unit_list_push(&raw_units, &u);
        } else {
          free(id);
        }
        free(form_path);
      }

      const SpecField *area_form = spec_generation_form_declaring(cls, "area");
      if (area_form != NULL) {
        char *form_path =
            spec_path_join(item, spec_reflection_field_segment(area_form));
        char *area = trim_dup(spec_document_form_field(doc, form_path, "area"));
        if (area[0] != '\0') {
          if (mappings_len == mappings_cap) {
            mappings_cap = mappings_cap == 0 ? 4 : mappings_cap * 2;
            mappings = (RawMapping *)realloc(mappings,
                                             mappings_cap * sizeof(RawMapping));
          }
          mappings[mappings_len].path = som_strdup(item);
          mappings[mappings_len].area = area;
          mappings[mappings_len].mapping =
              trim_dup(spec_document_form_field(doc, form_path, "mapping"));
          mappings_len++;
        } else {
          free(area);
        }
        free(form_path);
      }
    }
  }
  som_strlist_free(&list_paths);

  SomStrList seen;
  som_strlist_init(&seen);
  for (size_t i = 0; i < raw_units.len; i++) {
    const SpecGenerationUnit *raw = &raw_units.items[i];
    if (som_strlist_contains(&seen, raw->unit_id)) {
      continue;
    }
    som_strlist_push_copy(&seen, raw->unit_id);
    SpecGenerationUnit u;
    memset(&u, 0, sizeof(u));
    u.unit_id = som_strdup(raw->unit_id);
    u.kind = som_strdup(raw->kind);
    u.path = som_strdup(raw->path);
    for (size_t m = 0; m < mappings_len; m++) {
      const char *owner = owner_of(mappings[m].path, &raw_units);
      if (owner != NULL && strcmp(owner, raw->path) == 0) {
        unit_push_mapping(&u, som_strdup(mappings[m].area),
                          som_strdup(mappings[m].mapping));
      }
    }
    unit_list_push(out, &u);
  }
  som_strlist_free(&seen);

  for (size_t m = 0; m < mappings_len; m++) {
    free(mappings[m].path);
    free(mappings[m].area);
    free(mappings[m].mapping);
  }
  free(mappings);
  spec_generation_unit_list_free(&raw_units);
}

void spec_default_units(const SpecGenerationUnitList *units,
                        const char *area_code, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; units != NULL && i < units->len; i++) {
    if (spec_generation_unit_maps(&units->items[i], area_code)) {
      som_strlist_push_copy(out, units->items[i].unit_id);
    }
  }
}
