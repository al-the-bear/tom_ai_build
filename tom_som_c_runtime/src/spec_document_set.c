/* spec_document_set — see include/spec_document_set.h. A port of the Rust
 * `spec_document_set.rs` (itself a port of the Dart reference). */
#include "spec_document_set.h"

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_derive_fields.h"
#include "spec_document_assembly.h"
#include "spec_document_markdown.h"
#include "spec_document_set_internal.h"
#include "spec_links_validator.h"
#include "spec_meta_bridge.h"
#include "spec_review_annotations.h"
#include "spec_section_id.h"

/* ---- small string helpers ---------------------------------------------------- */

/* Concatenates the NULL-terminated argument strings. Owned. */
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

static int ends_with(const char *s, const char *suffix) {
  size_t n = strlen(s), m = strlen(suffix);
  return n >= m && strcmp(s + n - m, suffix) == 0;
}

static const char *or_empty(const char *s) { return s != NULL ? s : ""; }

/* Whether `path` is `root` or beneath it. */
static int under_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && (path[n] == '\0' || path[n] == '/');
}

/* Whether `path` is strictly beneath `root`. */
static int beneath_path(const char *path, const char *root) {
  size_t n = strlen(root);
  return strncmp(path, root, n) == 0 && path[n] == '/';
}

static int set_has(const SomMap *m, const char *key) {
  return som_map_get(m, key) != NULL;
}

static void set_add(SomMap *m, const char *key) { som_map_set(m, key, "1"); }

/* The part of `s` before its first `c` (all of it without one). Owned. */
static char *before_first(const char *s, char c) {
  const char *at = strchr(s, c);
  return at == NULL ? som_strdup(s) : som_strdup_n(s, (size_t)(at - s));
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

char *spec_validation_errors_json(const SpecValidationErrors *errors) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < errors->len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"path\":");
    jstr(&b, errors->items[i].path);
    som_buf_puts(&b, ",\"code\":");
    jstr(&b, errors->items[i].code);
    som_buf_puts(&b, ",\"message\":");
    jstr(&b, errors->items[i].message);
    som_buf_putc(&b, '}');
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

char *spec_document_stores_json(const SpecDocument *doc) {
  DocumentJson j;
  spec_document_to_json(doc, &j);
  char *out = document_json_to_canonical_json(&j);
  document_json_free(&j);
  return out;
}

void spec_document_copy(SpecDocument *dst, const SpecDocument *src) {
  DocumentJson j;
  spec_document_to_json(src, &j);
  spec_document_init(dst);
  spec_document_load_json(dst, &j);
  document_json_free(&j);
}

/* ---- the vocabulary ------------------------------------------------------------ */

static const char *const k_sync_code_names[SPEC_SYNC_CODE_COUNT] = {
    "sharedValueDiffers",   "sharedValueMissing",
    "sharedValueOnlyInBlueprint", "sharedElementMissing",
    "sharedElementOnlyInBlueprint", "sharedElementMayBeAdded",
    "crossSummaryMismatch", "crossInverseMissing",
    "pendingReview",        "unmarkable"};

const char *spec_sync_code_name(SpecSyncCode code) {
  return (unsigned)code < SPEC_SYNC_CODE_COUNT ? k_sync_code_names[code] : "";
}

int spec_sync_code_from_name(const char *name, SpecSyncCode *out) {
  for (int i = 0; i < SPEC_SYNC_CODE_COUNT; i++) {
    if (str_eq(name, k_sync_code_names[i])) {
      *out = (SpecSyncCode)i;
      return 1;
    }
  }
  return 0;
}

const char *spec_sync_resolution_name(SpecSyncResolution r) {
  switch (r) {
    case SPEC_SYNC_RESOLUTION_BACKFILL:
      return "backfill";
    case SPEC_SYNC_RESOLUTION_DERIVE_FIELDS:
      return "deriveFields";
    case SPEC_SYNC_RESOLUTION_AGENT:
      return "agent";
    case SPEC_SYNC_RESOLUTION_INFO:
      return "info";
  }
  return "";
}

const char *spec_sync_holder_name(SpecSyncHolder h) {
  return h == SPEC_SYNC_HOLDER_BLUEPRINT ? "blueprint" : "detail";
}

const char *spec_document_set_refusal_name(SpecDocumentSetRefusal r) {
  switch (r) {
    case SPEC_DOCUMENT_SET_REFUSAL_SAME_ROOT:
      return "sameRoot";
    case SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT:
      return "noRoot";
    case SPEC_DOCUMENT_SET_REFUSAL_TWO_ROOTS:
      return "twoRoots";
    case SPEC_DOCUMENT_SET_REFUSAL_PROJECTION:
      return "projection";
    case SPEC_DOCUMENT_SET_REFUSAL_OVERLAP:
      return "overlap";
    case SPEC_DOCUMENT_SET_REFUSAL_UNPAIRABLE:
      return "unpairable";
  }
  return "";
}

void spec_document_set_error_init(SpecDocumentSetError *e) {
  e->refusal = SPEC_DOCUMENT_SET_REFUSAL_SAME_ROOT;
  som_strlist_init(&e->documents);
  e->message = NULL;
  e->class_name = NULL;
}

void spec_document_set_error_free(SpecDocumentSetError *e) {
  som_strlist_free(&e->documents);
  free(e->message);
  free(e->class_name);
  spec_document_set_error_init(e);
}

char *spec_document_set_error_to_json(const SpecDocumentSetError *e) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "refusal");
  jstr(&b, spec_document_set_refusal_name(e->refusal));
  jkey(&b, &first, "documents");
  jstrs(&b, &e->documents);
  if (e->class_name != NULL && e->class_name[0] != '\0') {
    jkey(&b, &first, "className");
    jstr(&b, e->class_name);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_document_set_error_display(const SpecDocumentSetError *e) {
  return scat("SpecDocumentSetError(", spec_document_set_refusal_name(e->refusal),
              "): ", or_empty(e->message), NULL);
}

/* Fills `*err` (when non-NULL) with a refusal naming `a` (and `b`), taking
 * `message`. */
static void refuse(SpecDocumentSetError *err, SpecDocumentSetRefusal refusal,
                   const char *a, const char *b, char *message) {
  if (err == NULL) {
    free(message);
    return;
  }
  spec_document_set_error_free(err);
  err->refusal = refusal;
  if (a != NULL) som_strlist_push_copy(&err->documents, a);
  if (b != NULL) som_strlist_push_copy(&err->documents, b);
  err->message = message;
}

void spec_document_set_load_error_init(SpecDocumentSetLoadError *e) {
  e->kind = SPEC_DOCUMENT_SET_LOAD_OK;
  e->file = NULL;
  e->message = NULL;
  spec_document_set_error_init(&e->set);
}

void spec_document_set_load_error_free(SpecDocumentSetLoadError *e) {
  free(e->file);
  free(e->message);
  spec_document_set_error_free(&e->set);
  spec_document_set_load_error_init(e);
}

void spec_sync_pair_free(SpecSyncPair *p) {
  free(p->class_name);
  free(p->section_id);
  free(p->blueprint_anchor);
  free(p->detail_anchor);
  free(p->detail_root);
  if (p->has_sync) spec_sync_free(&p->sync);
  memset(p, 0, sizeof(*p));
}

char *spec_sync_pair_to_json(const SpecSyncPair *p) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  jkey(&b, &first, "pair");
  jstr(&b, p->section_id);
  jkey(&b, &first, "className");
  jstr(&b, p->class_name);
  jkey(&b, &first, "blueprint");
  jstr(&b, p->blueprint_anchor);
  jkey(&b, &first, "detail");
  jstr(&b, p->detail_anchor);
  jkey(&b, &first, "detailRoot");
  jstr(&b, p->detail_root);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the anchor pairs ------------------------------------------------------------ */

/* The roots `doc` holds a value under, in model order. */
static void set_populated_roots(const SpecReflection *refl,
                                const SpecDocument *doc, SomStrList *out) {
  SomMap segs;
  som_map_init(&segs);
  for (int k = 0; k < 4; k++) {
    SomStrList paths;
    if (k == 0) spec_document_content_paths(doc, &paths);
    if (k == 1) spec_document_form_paths(doc, &paths);
    if (k == 2) spec_document_list_paths(doc, &paths);
    if (k == 3) spec_document_headline_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      char *seg = before_first(paths.items[i], '/');
      set_add(&segs, seg);
      free(seg);
    }
    som_strlist_free(&paths);
  }
  som_strlist_init(out);
  for (size_t i = 0; i < refl->model->roots_len; i++) {
    const SpecRoot *r = &refl->model->roots[i];
    if (set_has(&segs, spec_reflection_root_segment(r))) {
      som_strlist_push_copy(out, r->type);
    }
  }
  som_map_free(&segs);
}

static char *compute_blueprint_root(const SpecReflection *refl) {
  SomStrList targets;
  som_strlist_init(&targets);
  for (size_t i = 0; i < refl->model->roots_len; i++) {
    const SpecClass *cls =
        spec_reflection_class_named(refl, refl->model->roots[i].type);
    if (cls == NULL) continue;
    const SpecAnnotation *doc = spec_annotations_named(&cls->annotations, "Document");
    const SomJson *based =
        doc != NULL ? spec_annotation_argument(doc, "basedOn") : NULL;
    if (based == NULL || based->type != SOM_JSON_ARRAY) continue;
    for (size_t k = 0; k < based->as.array.len; k++) {
      char *t = spec_link_json_text(based->as.array.items[k]);
      if (!som_strlist_contains(&targets, t)) {
        som_strlist_push(&targets, t);
      } else {
        free(t);
      }
    }
  }
  char *out = som_strdup(targets.len == 1 ? targets.items[0] : "");
  som_strlist_free(&targets);
  return out;
}

/* The pairable class positions of one root: member positions and `@SameAs`
 * copies left out (an index over the full list). */
typedef struct {
  char *root;
  SpecSectionPositionList all;
  size_t *idx;
  size_t len;
} PosSet;

static const SpecSectionPosition *pos_at(const PosSet *ps, size_t i) {
  return &ps->all.items[ps->idx[i]];
}

static void pos_set_free(PosSet *ps) {
  free(ps->root);
  spec_section_position_list_free(&ps->all);
  free(ps->idx);
  memset(ps, 0, sizeof(*ps));
}

static void pairable_positions(const SpecReflection *refl, const char *root,
                               PosSet *out) {
  memset(out, 0, sizeof(*out));
  out->root = som_strdup(root);
  spec_section_positions(refl, root, &out->all);
  SomStrList copies;
  som_strlist_init(&copies);
  for (size_t i = 0; i < out->all.len; i++) {
    const SpecSectionPosition *p = &out->all.items[i];
    if (!p->is_member && p->member != NULL &&
        spec_annotations_has_same_as(&p->member->annotations)) {
      som_strlist_push_copy(&copies, p->path);
    }
  }
  out->idx = (size_t *)malloc((out->all.len ? out->all.len : 1) * sizeof(size_t));
  for (size_t i = 0; i < out->all.len; i++) {
    const SpecSectionPosition *p = &out->all.items[i];
    if (p->is_member) continue;
    int copy = 0;
    for (size_t c = 0; c < copies.len && !copy; c++) {
      copy = under_path(p->path, copies.items[c]);
    }
    if (!copy) out->idx[out->len++] = i;
  }
  som_strlist_free(&copies);
}

typedef struct {
  PosSet *items;
  size_t len;
} PosSets;

static PosSet *pos_sets_get(PosSets *s, const char *root) {
  for (size_t i = 0; i < s->len; i++) {
    if (strcmp(s->items[i].root, root) == 0) return &s->items[i];
  }
  return NULL;
}

/* The key a position is paired by: the path below the nearest enclosing
 * anchor. Owned. */
static char *pair_key(const PosSet *ps, const SpecSectionPosition *p,
                      const SomMap *candidates) {
  const SpecSectionPosition *outer = NULL;
  for (size_t i = 0; i < ps->len; i++) {
    const SpecSectionPosition *q = pos_at(ps, i);
    if (strcmp(q->path, p->path) == 0 || !beneath_path(p->path, q->path)) {
      continue;
    }
    if (!set_has(candidates, q->class_name)) continue;
    if (outer == NULL || strlen(q->path) > strlen(outer->path)) outer = q;
  }
  size_t from = outer != NULL ? outer->section_ids.len : 0;
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, outer != NULL ? outer->class_name : "");
  som_buf_putc(&b, '/');
  for (size_t i = from; i < p->section_ids.len; i++) {
    if (i > from) som_buf_putc(&b, '/');
    som_buf_puts(&b, p->section_ids.items[i]);
  }
  return som_buf_take(&b);
}

static void pairs_push(SpecDocumentSet *set, const SpecSyncPair *p) {
  set->pairs = (SpecSyncPair *)realloc(set->pairs,
                                       (set->pairs_len + 1) * sizeof(SpecSyncPair));
  set->pairs[set->pairs_len++] = *p;
}

static int compute_pairs(const SpecReflection *refl, SpecDocumentSet *set,
                         SpecDocumentSetError *err) {
  const char *bp = set->blueprint_root;
  if (bp[0] == '\0') return 1;
  PosSets positions = {NULL, 0};
  positions.items = (PosSet *)calloc(1, sizeof(PosSet));
  pairable_positions(refl, bp, &positions.items[0]);
  positions.len = 1;

  SomMap candidates; /* class -> target root */
  som_map_init(&candidates);
  SomStrList candidate_order;
  som_strlist_init(&candidate_order);
  const PosSet *bps = &positions.items[0];
  for (size_t i = 0; i < bps->len; i++) {
    const SpecSectionPosition *p = pos_at(bps, i);
    const SpecClass *cls = spec_reflection_class_named(refl, p->class_name);
    if (cls == NULL) continue;
    char *target;
    SpecSync sync;
    if (spec_annotations_synced_with(&cls->annotations, &sync)) {
      target = som_strdup(or_empty(sync.document));
      spec_sync_free(&sync);
    } else {
      target = som_strdup(or_empty(cls->detailed_in));
    }
    if (target[0] == '\0' || strcmp(target, bp) == 0 ||
        spec_reflection_class_named(refl, target) == NULL) {
      free(target);
      continue;
    }
    if (!set_has(&candidates, p->class_name)) {
      som_map_set(&candidates, p->class_name, target);
      som_strlist_push_copy(&candidate_order, p->class_name);
    }
    free(target);
  }
  for (size_t i = 0; i < candidates.len; i++) {
    const char *target = candidates.entries[i].val;
    if (pos_sets_get(&positions, target) != NULL) continue;
    positions.items = (PosSet *)realloc(positions.items,
                                        (positions.len + 1) * sizeof(PosSet));
    pairable_positions(refl, target, &positions.items[positions.len++]);
  }

  int ok = 1;
  for (size_t ci = 0; ci < candidate_order.len && ok; ci++) {
    const char *class_name = candidate_order.items[ci];
    const char *target = som_map_get(&candidates, class_name);
    const PosSet *mine_set = pos_sets_get(&positions, bp);
    const PosSet *theirs_set = pos_sets_get(&positions, target);
    size_t n_mine = 0, n_theirs = 0;
    const SpecSectionPosition **mine = (const SpecSectionPosition **)malloc(
        (mine_set->len ? mine_set->len : 1) * sizeof(void *));
    const SpecSectionPosition **theirs = (const SpecSectionPosition **)malloc(
        (theirs_set->len ? theirs_set->len : 1) * sizeof(void *));
    for (size_t i = 0; i < mine_set->len; i++) {
      if (strcmp(pos_at(mine_set, i)->class_name, class_name) == 0) {
        mine[n_mine++] = pos_at(mine_set, i);
      }
    }
    for (size_t i = 0; i < theirs_set->len; i++) {
      if (strcmp(pos_at(theirs_set, i)->class_name, class_name) == 0) {
        theirs[n_theirs++] = pos_at(theirs_set, i);
      }
    }
    if (n_theirs == 0) {
      free(mine);
      free(theirs);
      continue;
    }
    /* The matched pairs: mine[i] with theirs[match[i]]. */
    size_t *match = (size_t *)malloc((n_mine ? n_mine : 1) * sizeof(size_t));
    size_t n_matched = 0;
    int unpairable = 0;
    if (n_mine == 1 && n_theirs == 1) {
      match[0] = 0;
      n_matched = 1;
    } else {
      SomMap by_key; /* key -> index into theirs */
      som_map_init(&by_key);
      for (size_t i = 0; i < n_theirs && !unpairable; i++) {
        char *k = pair_key(theirs_set, theirs[i], &candidates);
        if (set_has(&by_key, k)) {
          unpairable = 1;
        } else {
          char num[32];
          snprintf(num, sizeof(num), "%zu", i);
          som_map_set(&by_key, k, num);
        }
        free(k);
      }
      for (size_t i = 0; i < n_mine && !unpairable; i++) {
        char *k = pair_key(mine_set, mine[i], &candidates);
        const char *hit = som_map_get(&by_key, k);
        if (hit == NULL) {
          unpairable = 1;
        } else {
          match[n_matched++] = (size_t)strtoull(hit, NULL, 10);
          som_map_remove(&by_key, k);
        }
        free(k);
      }
      if (!unpairable && by_key.len > 0) unpairable = 1;
      som_map_free(&by_key);
    }
    if (unpairable) {
      if (err != NULL) {
        spec_document_set_error_free(err);
        err->refusal = SPEC_DOCUMENT_SET_REFUSAL_UNPAIRABLE;
        err->message = scat("the positions of ", class_name,
                            " in the Blueprint and its document cannot be "
                            "paired (SHARED-ANCHOR)",
                            NULL);
        err->class_name = som_strdup(class_name);
      }
      ok = 0;
    } else {
      const SpecClass *cls = spec_reflection_class_named(refl, class_name);
      const char *sid = cls != NULL && cls->section_id != NULL &&
                                cls->section_id[0] != '\0'
                            ? cls->section_id
                            : class_name;
      for (size_t i = 0; i < n_matched; i++) {
        SpecSyncPair p;
        memset(&p, 0, sizeof(p));
        p.class_name = som_strdup(class_name);
        p.section_id = som_strdup(sid);
        p.blueprint_anchor = som_strdup(mine[i]->path);
        p.detail_anchor = som_strdup(theirs[match[i]]->path);
        p.detail_root = som_strdup(target);
        p.has_sync = cls != NULL &&
                     spec_annotations_synced_with(&cls->annotations, &p.sync);
        pairs_push(set, &p);
      }
    }
    free(match);
    free(mine);
    free(theirs);
  }
  for (size_t i = 0; i < positions.len; i++) pos_set_free(&positions.items[i]);
  free(positions.items);
  som_map_free(&candidates);
  som_strlist_free(&candidate_order);
  return ok;
}

/* ---- the set ---------------------------------------------------------------------- */

static void set_init_empty(SpecDocumentSet *set, const SpecModel *model) {
  memset(set, 0, sizeof(*set));
  set->model = model;
  set->blueprint_root = som_strdup("");
}

/* A refused set: nothing owned (freeing it is a no-op). */
static void set_refused(SpecDocumentSet *set, const SpecModel *model) {
  memset(set, 0, sizeof(*set));
  set->model = model;
}

void spec_document_set_free(SpecDocumentSet *set) {
  for (size_t i = 0; i < set->entries_len; i++) {
    free(set->entries[i].name);
    free(set->entries[i].root);
    spec_document_free(set->entries[i].document);
    free(set->entries[i].document);
  }
  free(set->entries);
  for (size_t i = 0; i < set->pairs_len; i++) spec_sync_pair_free(&set->pairs[i]);
  free(set->pairs);
  free(set->blueprint_root);
  memset(set, 0, sizeof(*set));
}

static SpecDocumentSetEntry *entry_named(const SpecDocumentSet *set,
                                         const char *name) {
  for (size_t i = 0; i < set->entries_len; i++) {
    if (strcmp(set->entries[i].name, name) == 0) return &set->entries[i];
  }
  return NULL;
}

int spec_document_set_put(SpecDocumentSet *set, const char *name,
                          const SpecDocument *document,
                          SpecDocumentSetError *err) {
  SpecReflection refl = spec_reflection_make(set->model);
  SomStrList roots;
  set_populated_roots(&refl, document, &roots);
  if (roots.len == 0) {
    som_strlist_free(&roots);
    refuse(err, SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT, name, NULL,
           scat(name, " populates no root", NULL));
    return 0;
  }
  if (roots.len > 1) {
    char *joined = som_strlist_join(&roots, " and ");
    som_strlist_free(&roots);
    refuse(err, SPEC_DOCUMENT_SET_REFUSAL_TWO_ROOTS, name, NULL,
           scat(name, " populates ", joined, NULL));
    free(joined);
    return 0;
  }
  char *root = som_strdup(roots.items[0]);
  som_strlist_free(&roots);
  const SpecClass *cls = spec_reflection_class_named(&refl, root);
  if (cls != NULL && spec_class_is_code_specs_projection(cls)) {
    refuse(err, SPEC_DOCUMENT_SET_REFUSAL_PROJECTION, name, NULL,
           scat(name, " is the CodeSpecs projection, which is no specification",
                NULL));
    free(root);
    return 0;
  }
  for (size_t i = 0; i < set->entries_len; i++) {
    const SpecDocumentSetEntry *other = &set->entries[i];
    if (strcmp(other->root, root) == 0 && strcmp(other->name, name) != 0) {
      refuse(err, SPEC_DOCUMENT_SET_REFUSAL_SAME_ROOT, other->name, name,
             scat(other->name, " and ", name, " both populate ", root, NULL));
      free(root);
      return 0;
    }
  }
  SpecDocumentSetEntry *e = entry_named(set, name);
  if (e == NULL) {
    if (set->entries_len == set->entries_cap) {
      set->entries_cap = set->entries_cap ? set->entries_cap * 2 : 4;
      set->entries = (SpecDocumentSetEntry *)realloc(
          set->entries, set->entries_cap * sizeof(SpecDocumentSetEntry));
    }
    e = &set->entries[set->entries_len++];
    e->name = som_strdup(name);
    e->root = NULL;
    e->document = NULL;
  }
  if (e->document != NULL) {
    spec_document_free(e->document);
  } else {
    e->document = (SpecDocument *)malloc(sizeof(SpecDocument));
  }
  spec_document_copy(e->document, document);
  free(e->root);
  e->root = root;
  return 1;
}

void spec_document_set_replace(SpecDocumentSet *set, const char *name,
                               const SpecDocument *document) {
  SpecDocumentSetEntry *e = entry_named(set, name);
  if (e == NULL || e->document == document) return;
  SpecDocument copy;
  spec_document_copy(&copy, document);
  spec_document_free(e->document);
  *e->document = copy;
}

int spec_document_set_new(const SpecModel *model,
                          const SpecNamedDocument *documents, size_t len,
                          SpecDocumentSet *out, SpecDocumentSetError *err) {
  set_init_empty(out, model);
  SpecReflection refl = spec_reflection_make(model);
  free(out->blueprint_root);
  out->blueprint_root = compute_blueprint_root(&refl);
  if (!compute_pairs(&refl, out, err)) {
    spec_document_set_free(out);
    set_refused(out, model);
    return 0;
  }
  for (size_t i = 0; i < len; i++) {
    if (!spec_document_set_put(out, documents[i].name, documents[i].document,
                               err)) {
      spec_document_set_free(out);
      set_refused(out, model);
      return 0;
    }
  }
  return 1;
}

int spec_document_set_from_fragments(const SpecModel *model,
                                     const SpecNamedDocument *fragments,
                                     size_t len, SpecDocumentSet *out,
                                     SpecDocumentSetError *err) {
  SpecReflection refl = spec_reflection_make(model);
  SomStrList root_of; /* parallel to fragments */
  som_strlist_init(&root_of);
  SomStrList root_order;
  som_strlist_init(&root_order);
  for (size_t i = 0; i < len; i++) {
    SomStrList roots;
    set_populated_roots(&refl, fragments[i].document, &roots);
    if (roots.len != 1) {
      char *what = roots.len == 0 ? som_strdup("no root")
                                  : som_strlist_join(&roots, " and ");
      refuse(err,
             roots.len == 0 ? SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT
                            : SPEC_DOCUMENT_SET_REFUSAL_TWO_ROOTS,
             fragments[i].name, NULL,
             scat(fragments[i].name, " populates ", what, NULL));
      free(what);
      som_strlist_free(&roots);
      som_strlist_free(&root_of);
      som_strlist_free(&root_order);
      set_refused(out, model);
      return 0;
    }
    som_strlist_push_copy(&root_of, roots.items[0]);
    if (!som_strlist_contains(&root_order, roots.items[0])) {
      som_strlist_push_copy(&root_order, roots.items[0]);
    }
    som_strlist_free(&roots);
  }
  SpecNamedDocument *documents = (SpecNamedDocument *)malloc(
      (root_order.len ? root_order.len : 1) * sizeof(SpecNamedDocument));
  SpecDocumentAssembly *assemblies = (SpecDocumentAssembly *)calloc(
      root_order.len ? root_order.len : 1, sizeof(SpecDocumentAssembly));
  size_t n_docs = 0;
  int ok = 1;
  for (size_t r = 0; r < root_order.len && ok; r++) {
    size_t n_group = 0;
    SpecAssemblyFragment *group = (SpecAssemblyFragment *)malloc(
        (len ? len : 1) * sizeof(SpecAssemblyFragment));
    for (size_t i = 0; i < len; i++) {
      if (strcmp(root_of.items[i], root_order.items[r]) != 0) continue;
      group[n_group].name = fragments[i].name;
      group[n_group].document = fragments[i].document;
      n_group++;
    }
    if (n_group == 1) {
      documents[n_docs].name = group[0].name;
      documents[n_docs].document = group[0].document;
      n_docs++;
    } else {
      spec_document_assemble(group, n_group, &assemblies[r]);
      if (assemblies[r].document != NULL && assemblies[r].overlaps_len == 0) {
        documents[n_docs].name = group[0].name;
        documents[n_docs].document = assemblies[r].document;
        n_docs++;
      } else {
        if (err != NULL) {
          spec_document_set_error_free(err);
          err->refusal = SPEC_DOCUMENT_SET_REFUSAL_OVERLAP;
          SomBuf b;
          som_buf_init(&b);
          som_buf_puts(&b, "the fragments ");
          for (size_t g = 0; g < n_group; g++) {
            som_strlist_push_copy(&err->documents, group[g].name);
            if (g > 0) som_buf_puts(&b, ", ");
            som_buf_puts(&b, group[g].name);
          }
          som_buf_puts(&b, " overlap");
          err->message = som_buf_take(&b);
        }
        ok = 0;
      }
    }
    free(group);
  }
  if (ok) {
    ok = spec_document_set_new(model, documents, n_docs, out, err);
  } else {
    set_refused(out, model);
  }
  for (size_t r = 0; r < root_order.len; r++) {
    spec_document_assembly_free(&assemblies[r]);
  }
  free(assemblies);
  free(documents);
  som_strlist_free(&root_of);
  som_strlist_free(&root_order);
  return ok;
}

/* Reads the file at `path` into an owned string; NULL with `*why` (owned)
 * when it cannot be read. */
static char *read_text_file(const char *path, char **why) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    *why = som_strdup(strerror(errno));
    return NULL;
  }
  SomBuf b;
  som_buf_init(&b);
  char chunk[8192];
  size_t n;
  while ((n = fread(chunk, 1, sizeof(chunk), f)) > 0) som_buf_putn(&b, chunk, n);
  int failed = ferror(f);
  fclose(f);
  if (failed) {
    som_buf_free(&b);
    *why = som_strdup("read error");
    return NULL;
  }
  return som_buf_take(&b);
}

/* Whether a line of `text`, its leading whitespace dropped, starts with
 * `key`. */
static int some_line_starts_with(const char *text, const char *key) {
  const char *p = text;
  size_t n = strlen(key);
  while (*p != '\0') {
    const char *q = p;
    while (*q == ' ' || *q == '\t' || *q == '\r' || *q == '\f' || *q == '\v') q++;
    if (strncmp(q, key, n) == 0) return 1;
    const char *nl = strchr(p, '\n');
    if (nl == NULL) break;
    p = nl + 1;
  }
  return 0;
}

int spec_document_set_load(const SpecModel *model, const char *const *files,
                           size_t len, SpecDocumentSet *out,
                           SpecDocumentSetLoadError *err) {
  int built = 0; /* from_fragments filled `out` */
  SomStrList tree_roots;
  som_strlist_init(&tree_roots);
  SomMetaTree **trees =
      (SomMetaTree **)calloc(model->roots_len ? model->roots_len : 1, sizeof(void *));
  SpecDocument **docs = (SpecDocument **)calloc(len ? len : 1, sizeof(void *));
  SomStrList names;
  som_strlist_init(&names);
  int ok = 1;
  for (size_t i = 0; i < len && ok; i++) {
    const char *file = files[i];
    char *why = NULL;
    char *text = read_text_file(file, &why);
    if (text == NULL) {
      if (err != NULL) {
        spec_document_set_load_error_free(err);
        err->kind = SPEC_DOCUMENT_SET_LOAD_READ;
        err->file = som_strdup(file);
        err->message = why;
      } else {
        free(why);
      }
      ok = 0;
      break;
    }
    char *normalized = som_strdup(file);
    for (char *c = normalized; *c != '\0'; c++) {
      if (*c == '\\') *c = '/';
    }
    const char *slash = strrchr(normalized, '/');
    char *name = som_strdup(slash != NULL ? slash + 1 : normalized);
    free(normalized);
    SpecDocument *doc = NULL;
    if (ends_with(file, ".md")) {
      SpecMarkdownImport imp;
      spec_document_from_markdown(text, model, &imp);
      doc = imp.document;
      imp.document = NULL;
      spec_markdown_import_free(&imp);
    } else {
      const SpecRoot *root = NULL;
      for (size_t r = 0; r < model->roots_len && root == NULL; r++) {
        char *key = scat(model->roots[r].section_id, " ", model->roots[r].type,
                         ":", NULL);
        if (some_line_starts_with(text, key)) root = &model->roots[r];
        free(key);
      }
      if (root == NULL) {
        if (err != NULL) {
          spec_document_set_load_error_free(err);
          err->kind = SPEC_DOCUMENT_SET_LOAD_SET;
          err->set.refusal = SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT;
          som_strlist_push_copy(&err->set.documents, name);
          err->set.message = scat(name, " names no root of the model", NULL);
        }
        ok = 0;
      } else {
        size_t t = 0;
        while (t < tree_roots.len && strcmp(tree_roots.items[t], root->type) != 0) {
          t++;
        }
        if (t == tree_roots.len) {
          char *terr = NULL;
          SomMetaTree *tree = som_build_meta_tree(model, root->type, &terr);
          if (tree == NULL) {
            if (err != NULL) {
              spec_document_set_load_error_free(err);
              err->kind = SPEC_DOCUMENT_SET_LOAD_DECODE;
              err->file = som_strdup(file);
              err->message = terr != NULL ? terr : som_strdup("no meta tree");
            } else {
              free(terr);
            }
            ok = 0;
          } else {
            som_strlist_push_copy(&tree_roots, root->type);
            trees[t] = tree;
          }
        }
        if (ok) {
          char *derr = NULL;
          doc = spec_document_from_yaml(text, trees[t], &derr);
          if (doc == NULL) {
            if (err != NULL) {
              spec_document_set_load_error_free(err);
              err->kind = SPEC_DOCUMENT_SET_LOAD_DECODE;
              err->file = som_strdup(file);
              err->message = derr != NULL ? derr : som_strdup("does not decode");
            } else {
              free(derr);
            }
            ok = 0;
          }
        }
      }
    }
    free(text);
    if (ok && doc != NULL) {
      docs[names.len] = doc;
      som_strlist_push(&names, name);
    } else {
      free(name);
      if (doc != NULL) {
        spec_document_free(doc);
        free(doc);
      }
    }
  }
  if (ok) {
    SpecNamedDocument *frags = (SpecNamedDocument *)malloc(
        (names.len ? names.len : 1) * sizeof(SpecNamedDocument));
    for (size_t i = 0; i < names.len; i++) {
      frags[i].name = names.items[i];
      frags[i].document = docs[i];
    }
    SpecDocumentSetError serr;
    spec_document_set_error_init(&serr);
    ok = spec_document_set_from_fragments(model, frags, names.len, out, &serr);
    built = 1;
    if (!ok && err != NULL) {
      spec_document_set_load_error_free(err);
      err->kind = SPEC_DOCUMENT_SET_LOAD_SET;
      err->set = serr;
    } else {
      spec_document_set_error_free(&serr);
    }
    free(frags);
  }
  for (size_t i = 0; i < names.len; i++) {
    spec_document_free(docs[i]);
    free(docs[i]);
  }
  free(docs);
  som_strlist_free(&names);
  for (size_t t = 0; t < tree_roots.len; t++) som_meta_tree_free(trees[t]);
  free(trees);
  som_strlist_free(&tree_roots);
  if (!built) set_refused(out, model);
  return ok;
}

/* The root type `root_type` (a type name or a section id) names, or NULL. */
static const char *type_of(const SpecDocumentSet *set, const char *root_type) {
  if (root_type == NULL || root_type[0] == '\0') return NULL;
  for (size_t i = 0; i < set->model->roots_len; i++) {
    const SpecRoot *r = &set->model->roots[i];
    if (str_eq(r->type, root_type) || str_eq(r->section_id, root_type)) {
      return r->type;
    }
  }
  return NULL;
}

static int has_root(const SpecDocumentSet *set, const char *t) {
  for (size_t i = 0; i < set->entries_len; i++) {
    if (strcmp(set->entries[i].root, t) == 0) return 1;
  }
  return 0;
}

const char *spec_document_set_name_of(const SpecDocumentSet *set,
                                      const char *root_type) {
  const char *t = type_of(set, root_type);
  if (t == NULL) return NULL;
  for (size_t i = 0; i < set->entries_len; i++) {
    if (strcmp(set->entries[i].root, t) == 0) return set->entries[i].name;
  }
  return NULL;
}

const SpecDocument *spec_document_set_document(const SpecDocumentSet *set,
                                               const char *root_type) {
  const char *name = spec_document_set_name_of(set, root_type);
  return name != NULL ? spec_document_set_get(set, name) : NULL;
}

const SpecDocument *spec_document_set_blueprint(const SpecDocumentSet *set) {
  if (set->blueprint_root == NULL || set->blueprint_root[0] == '\0') return NULL;
  return spec_document_set_document(set, set->blueprint_root);
}

void spec_document_set_roots(const SpecDocumentSet *set, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < set->model->roots_len; i++) {
    if (has_root(set, set->model->roots[i].type)) {
      som_strlist_push_copy(out, set->model->roots[i].type);
    }
  }
}

void spec_document_set_names(const SpecDocumentSet *set, SomStrList *out) {
  SomStrList roots;
  spec_document_set_roots(set, &roots);
  som_strlist_init(out);
  for (size_t i = 0; i < roots.len; i++) {
    const char *n = spec_document_set_name_of(set, roots.items[i]);
    if (n != NULL) som_strlist_push_copy(out, n);
  }
  som_strlist_free(&roots);
}

void spec_document_set_missing_roots(const SpecDocumentSet *set,
                                     SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < set->model->roots_len; i++) {
    const char *t = set->model->roots[i].type;
    int paired = 0;
    for (size_t p = 0; p < set->pairs_len && !paired; p++) {
      paired = strcmp(set->pairs[p].detail_root, t) == 0;
    }
    if (paired && !has_root(set, t)) som_strlist_push_copy(out, t);
  }
}

const SpecDocument *spec_document_set_get(const SpecDocumentSet *set,
                                          const char *name) {
  const SpecDocumentSetEntry *e = name != NULL ? entry_named(set, name) : NULL;
  return e != NULL ? e->document : NULL;
}

SpecDocument *spec_document_set_get_mut(SpecDocumentSet *set,
                                        const char *name) {
  SpecDocumentSetEntry *e = name != NULL ? entry_named(set, name) : NULL;
  return e != NULL ? e->document : NULL;
}

const char *spec_document_set_root_of(const SpecDocumentSet *set,
                                      const char *name) {
  const SpecDocumentSetEntry *e = name != NULL ? entry_named(set, name) : NULL;
  return e != NULL ? e->root : "";
}

