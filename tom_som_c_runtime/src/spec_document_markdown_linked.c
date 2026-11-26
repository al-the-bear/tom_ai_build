/* spec_document_markdown_linked — navigation between linked places of a
 * rendition (SOM §11.2 qualified anchors, SOM §11.11 the `linked` marker), a
 * port of the Rust runtime's `spec_document_markdown_linked.rs` (itself a
 * port of the Go, Python, JavaScript, TypeScript and Dart runtimes').
 *
 * Both are written from the model and the document's own values, and nothing
 * of either is stored: the parser removes the anchors and the marker.
 *
 * Internal to the Markdown codec (spec_document_markdown_internal.h). */
#include <stdlib.h>
#include <string.h>

#include "spec_document_markdown_internal.h"
#include "spec_links_validator.h"
#include "spec_model.h"
#include "spec_notation.h"
#include "spec_paths.h"
#include "spec_place.h"
#include "spec_section_id.h"

/* ---- small helpers ------------------------------------------------------- */

static char *cat3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

/* Whether `s` starts with `prefix` followed by '/'. */
static int under(const char *s, const char *prefix) {
  size_t n = strlen(prefix);
  return strncmp(s, prefix, n) == 0 && s[n] == '/';
}

/* `path` cut before its first `<list>-*` segment: that list's path. Owned. */
static char *cut_pattern(const char *path) {
  const char *star = strstr(path, "-*");
  return star != NULL ? som_strdup_n(path, (size_t)(star - path))
                      : som_strdup(path);
}

/* An item pattern's list pattern (`a/L-*` -> `a/L`). Owned. */
static char *list_pattern_of(const char *item_pattern) {
  size_t n = strlen(item_pattern);
  if (n >= 2 && strcmp(item_pattern + n - 2, "-*") == 0) {
    return som_strdup_n(item_pattern, n - 2);
  }
  return som_strdup(item_pattern);
}

/* The part of `path` before its last `/` (the whole path without one).
 * Owned. */
static char *owner_of(const char *path) {
  const char *slash = strrchr(path, '/');
  return slash != NULL ? som_strdup_n(path, (size_t)(slash - path))
                       : som_strdup(path);
}

static void add_unique(SomStrList *out, const char *v) {
  if (!som_strlist_contains(out, v)) som_strlist_push_copy(out, v);
}

/* The `@SectionIdPattern` of a list's items: the list's, else its element's. */
static const char *item_pattern_of(const SomMetaNode *list_node) {
  if (list_node->section_id_pattern[0] != '\0') {
    return list_node->section_id_pattern;
  }
  return list_node->element_node != NULL
             ? list_node->element_node->section_id_pattern
             : "";
}

/* The stem of a pattern-less list's item ids: its member name, else its
 * segment. */
static const char *member_stem_of(const SomMetaNode *list_node) {
  return list_node->member_name[0] != '\0' ? list_node->member_name
                                           : som_meta_node_segment(list_node);
}

/* The section id of a root, else its type. */
static const char *root_name(const SpecRoot *root) {
  return root->section_id != NULL && root->section_id[0] != '\0'
             ? root->section_id
             : root->type;
}

/* Number of `/`-separated segments of `path`. */
static size_t segment_count(const char *path) {
  size_t n = 1;
  for (const char *q = path; *q != '\0'; q++) {
    if (*q == '/') n++;
  }
  return n;
}

void spec_mdi_walk_free(MdWalk *w) {
  if (w == NULL) return;
  free(w->anchor);
  free(w->heading_id);
  free(w->heading_path);
  free(w->pattern);
  som_strlist_free(&w->item_ids);
  memset(w, 0, sizeof(*w));
}

/* ---- the navigation ------------------------------------------------------ */

/* One side of a `@SyncedWith` pair: its anchor here, the other root, the
 * anchor there, whether this side holds the values, the sync (all borrowed
 * from the codec's set and the model). */
typedef struct {
  const char *mine;
  const SpecRoot *other;
  const char *theirs;
  int holder;
  const SpecSync *sync;
} MdSide;

/* One derived value at a heading: a link to a source ("": none) and the
 * derived field's name ("": a derived section). Both owned. */
typedef struct {
  char *link;
  char *field;
} MdDerived;

typedef struct {
  MdDerived *items;
  size_t len, cap;
} MdDerivedVec;

static void derived_push(MdDerivedVec *v, char *link, const char *field) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 4;
    v->items = realloc(v->items, v->cap * sizeof(MdDerived));
  }
  v->items[v->len].link = link;
  v->items[v->len].field = som_strdup(field);
  v->len++;
}

static void derived_free(MdDerivedVec *v) {
  for (size_t i = 0; i < v->len; i++) {
    free(v->items[i].link);
    free(v->items[i].field);
  }
  free(v->items);
  memset(v, 0, sizeof(*v));
}

/* A detail element a summary element names: its id, its anchor and the other
 * root it is in (NULL: this document). */
typedef struct {
  char *id;
  char *anchor;
  const SpecRoot *other;
} MdTarget;

typedef struct {
  MdTarget *items;
  size_t len;
} MdTargets;

static void targets_free(MdTargets *t) {
  for (size_t i = 0; i < t->len; i++) {
    free(t->items[i].id);
    free(t->items[i].anchor);
  }
  free(t->items);
  memset(t, 0, sizeof(*t));
}

struct MdNav {
  const SpecModel *model;
  const SpecRoot *root;
  const SomMetaTree *tree;
  SpecReflection refl;
  char *root_seg;
  /* The cached walks: path -> index into `walks`. */
  SomMap walk_index;
  MdWalk **walks;
  size_t walks_len, walks_cap;
  int sides_loaded;
  MdSide *sides;
  size_t sides_len;
  int same_as_loaded;
  SpecSameAsBindingList same_as;
  /* Detail-list pattern -> the summary lists naming its elements. */
  int detail_loaded;
  SomStrList detail_keys;
  SomStrList *detail_lists;
  /* path -> "1" / "0". */
  SomMap markables;
  /* `<detail list path>#<element id>` -> links to the summary elements. */
  int summary_loaded;
  SomStrList summary_keys;
  SomStrList *summary_links;
};

MdNav *spec_mdi_nav_new(const SpecModel *model, const SpecRoot *root,
                        const SomMetaTree *tree) {
  MdNav *nav = calloc(1, sizeof(MdNav));
  nav->model = model;
  nav->root = root;
  nav->tree = tree;
  nav->refl = spec_reflection_make(model);
  nav->root_seg = som_strdup(spec_reflection_root_segment(root));
  som_map_init(&nav->walk_index);
  som_map_init(&nav->markables);
  som_strlist_init(&nav->detail_keys);
  som_strlist_init(&nav->summary_keys);
  return nav;
}

void spec_mdi_nav_free(MdNav *nav) {
  if (nav == NULL) return;
  free(nav->root_seg);
  som_map_free(&nav->walk_index);
  for (size_t i = 0; i < nav->walks_len; i++) {
    spec_mdi_walk_free(nav->walks[i]);
    free(nav->walks[i]);
  }
  free(nav->walks);
  free(nav->sides);
  if (nav->same_as_loaded) spec_same_as_binding_list_free(&nav->same_as);
  for (size_t i = 0; i < nav->detail_keys.len; i++) {
    som_strlist_free(&nav->detail_lists[i]);
  }
  free(nav->detail_lists);
  som_strlist_free(&nav->detail_keys);
  som_map_free(&nav->markables);
  for (size_t i = 0; i < nav->summary_keys.len; i++) {
    som_strlist_free(&nav->summary_links[i]);
  }
  free(nav->summary_links);
  som_strlist_free(&nav->summary_keys);
  free(nav);
}

const SomMetaTree *spec_mdi_nav_tree(const MdNav *nav) { return nav->tree; }
const SpecReflection *spec_mdi_nav_refl(const MdNav *nav) { return &nav->refl; }
const char *spec_mdi_nav_root_seg(const MdNav *nav) { return nav->root_seg; }

/* ---- anchors ------------------------------------------------------------- */

/* The heading id of the item at `item_path` of `list_node` in `d` (NULL: no
 * document), as the emitter writes it. Owned. */
static char *item_id(const SpecDocument *d, const SomMetaNode *list_node,
                     const char *item_path) {
  const char *slash = strrchr(item_path, '/');
  size_t prefix = slash != NULL ? (size_t)(slash - item_path) + 1 : 0;
  const char *seg = item_path + prefix;
  char *base = NULL;
  long long seq = 0;
  if (!spec_split_list_item_segment(seg, &base, &seq)) {
    base = som_strdup(seg);
    seq = 0;
  }
  SomBuf lp;
  som_buf_init(&lp);
  som_buf_putn(&lp, item_path, prefix);
  som_buf_puts(&lp, base);
  char *list_path = som_buf_take(&lp);
  free(base);
  long long pos = 0;
  const char *stored = NULL;
  if (d != NULL) {
    const SomStrList *items = spec_document_list_items(d, list_path);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      if (strcmp(items->items[k], item_path) == 0) {
        pos = (long long)k + 1;
        break;
      }
    }
    stored = spec_document_item_section_id(d, item_path);
  }
  free(list_path);
  if (pos == 0) pos = seq > 0 ? seq : 0;
  const char *pattern = item_pattern_of(list_node);
  return spec_effective_list_item_section_id(
      stored, pattern[0] != '\0' ? pattern : NULL, pos,
      member_stem_of(list_node));
}

/* `path` (concrete, or a pattern whose `<list>-*` segments take `ids` in
 * order) walked through `other` (NULL: this root's tree, the items' ids read
 * from the codec's document; else no document). Fills `*out` (owned). */
static void walk_into(MdNav *nav, MdCodec *c, const char *path,
                      const SomMetaTree *other, const char *const *ids,
                      size_t ids_len, MdWalk *out) {
  const SpecDocument *d = other == NULL ? spec_mdi_document(c) : NULL;
  const SomMetaTree *t = other != NULL ? other : nav->tree;
  size_t next_id = 0;
  SomStrList segs;
  spec_path_segments(path, &segs);
  const SomMetaNode *node = t->root;
  const char *first = segs.len > 0 ? segs.items[0] : "";
  char *cur = som_strdup(first);
  char *pattern = som_strdup(first);
  char *anchor = som_strdup(som_meta_node_segment(node));
  char *heading_id = som_strdup(som_meta_node_segment(node));
  char *heading_path = som_strdup(cur);
  char *scope = NULL;
  char *section = som_strdup(som_meta_node_segment(node));
  SomStrList item_ids;
  som_strlist_init(&item_ids);
  const SomMetaNode *reached = node;
  for (size_t i = 1; i < segs.len; i++) {
    const char *seg = segs.items[i];
    const SomMetaNode *child = som_meta_node_child_by_segment(node, seg);
    if (child != NULL) {
      char *x = cat3(cur, "/", seg);
      free(cur);
      cur = x;
      x = cat3(pattern, "/", seg);
      free(pattern);
      pattern = x;
      node = child;
      reached = child;
      if (spec_mdi_is_transparent_section(c, child) ||
          spec_mdi_is_transparent_value(child)) {
        continue;
      }
      char *id = spec_mdi_heading_id_of(c, child);
      int container = strcmp(child->kind, SOM_META_KIND_LIST) == 0;
      int copy = !container && spec_mdi_is_copy_node(c, child);
      char *a = NULL, *s = NULL;
      spec_mdi_qualify_anchor(scope, section, id, container, 0, copy, &a, &s);
      free(anchor);
      anchor = a;
      free(scope);
      scope = s;
      free(heading_id);
      heading_id = som_strdup(id);
      free(heading_path);
      heading_path = som_strdup(cur);
      if (!container) {
        free(section);
        section = id;
      } else {
        free(id);
      }
      continue;
    }
    size_t sl = strlen(seg);
    int star = sl >= 2 && strcmp(seg + sl - 2, "-*") == 0;
    char *base = NULL;
    long long seq = 0;
    if (star) {
      base = som_strdup_n(seg, sl - 2);
    } else if (!spec_split_list_item_segment(seg, &base, &seq)) {
      base = NULL;
    }
    const SomMetaNode *list_node =
        base != NULL ? som_meta_node_child_by_segment(node, base) : NULL;
    if (list_node == NULL || strcmp(list_node->kind, SOM_META_KIND_LIST) != 0) {
      free(base);
      reached = NULL;
      break;
    }
    char *item_path = cat3(cur, "/", seg);
    char *id;
    if (star) {
      id = som_strdup(next_id < ids_len ? ids[next_id] : "");
      next_id++;
    } else {
      id = item_id(d, list_node, item_path);
    }
    som_strlist_push_copy(&item_ids, id);
    char *a = NULL, *s = NULL;
    spec_mdi_qualify_anchor(scope, section, id, 0, 1, 0, &a, &s);
    free(anchor);
    anchor = a;
    free(scope);
    scope = s;
    free(heading_id);
    heading_id = som_strdup(id);
    free(section);
    section = id;
    free(cur);
    cur = som_strdup(item_path);
    free(heading_path);
    heading_path = item_path;
    char *x = cat3(pattern, "/", base);
    free(pattern);
    pattern = cat3(x, "-*", "");
    free(x);
    free(base);
    const SomMetaNode *element = list_node->element_node;
    node = element != NULL ? element : list_node;
    reached = node;
    if (element == NULL && i < segs.len - 1) {
      reached = NULL;
      break;
    }
  }
  free(cur);
  free(scope);
  free(section);
  som_strlist_free(&segs);
  out->anchor = anchor;
  out->heading_id = heading_id;
  out->heading_path = heading_path;
  out->pattern = pattern;
  out->item_ids = item_ids;
  out->node = reached;
}

const MdWalk *spec_mdi_nav_walk(MdNav *nav, MdCodec *c, const char *path) {
  const char *hit = som_map_get(&nav->walk_index, path);
  if (hit != NULL) return nav->walks[strtoul(hit, NULL, 10)];
  MdWalk *w = calloc(1, sizeof(MdWalk));
  walk_into(nav, c, path, NULL, NULL, 0, w);
  if (nav->walks_len == nav->walks_cap) {
    nav->walks_cap = nav->walks_cap ? nav->walks_cap * 2 : 64;
    nav->walks = realloc(nav->walks, nav->walks_cap * sizeof(MdWalk *));
  }
  char *idx = som_format_i64((long long)nav->walks_len);
  som_map_set(&nav->walk_index, path, idx);
  free(idx);
  nav->walks[nav->walks_len++] = w;
  return w;
}

char *spec_mdi_nav_anchor_of(MdNav *nav, MdCodec *c, const char *path) {
  return som_strdup(spec_mdi_nav_walk(nav, c, path)->anchor);
}

/* ---- the model's links, per root ---------------------------------------- */

/* The model's root of type `t`. */
static const SpecRoot *root_of_type(const MdNav *nav, const char *t) {
  if (t == NULL) return NULL;
  for (size_t i = 0; i < nav->model->roots_len; i++) {
    if (strcmp(nav->model->roots[i].type, t) == 0) return &nav->model->roots[i];
  }
  return NULL;
}

static void side_push(MdNav *nav, size_t *cap, const char *mine,
                      const SpecRoot *other, const char *theirs, int holder,
                      const SpecSync *sync) {
  if (nav->sides_len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    nav->sides = realloc(nav->sides, *cap * sizeof(MdSide));
  }
  MdSide *s = &nav->sides[nav->sides_len++];
  s->mine = mine;
  s->other = other;
  s->theirs = theirs;
  s->holder = holder;
  s->sync = sync;
}

/* Every `@SyncedWith` pair this root is a side of. */
static void all_sides(MdNav *nav, MdCodec *c) {
  if (nav->sides_loaded) return;
  nav->sides_loaded = 1;
  const SpecDocumentSet *set = spec_mdi_sync(c);
  if (set == NULL || set->blueprint_root == NULL || set->blueprint_root[0] == '\0') {
    return;
  }
  const char *bp = set->blueprint_root;
  size_t cap = 0;
  for (size_t i = 0; i < set->pairs_len; i++) {
    const SpecSyncPair *p = &set->pairs[i];
    if (!p->has_sync) continue;
    if (strcmp(nav->root->type, bp) == 0) {
      const SpecRoot *other = root_of_type(nav, p->detail_root);
      if (other == NULL) continue;
      side_push(nav, &cap, p->blueprint_anchor, other, p->detail_anchor, 0,
                &p->sync);
    } else if (strcmp(nav->root->type, p->detail_root) == 0) {
      const SpecRoot *other = root_of_type(nav, bp);
      if (other == NULL) continue;
      side_push(nav, &cap, p->detail_anchor, other, p->blueprint_anchor, 1,
                &p->sync);
    }
  }
}

/* The `@SameAs` copies of this root with their holders. */
static const SpecSameAsBindingList *same_as_bindings(MdNav *nav) {
  if (!nav->same_as_loaded) {
    nav->same_as_loaded = 1;
    spec_same_as_bindings(&nav->refl, nav->root->type, &nav->same_as);
  }
  return &nav->same_as;
}

static int under_copy(MdNav *nav, const char *pattern) {
  const SpecSameAsBindingList *l = same_as_bindings(nav);
  for (size_t i = 0; i < l->len; i++) {
    const char *cp = l->items[i].copy_path;
    if (cp == NULL) continue;
    if (strcmp(pattern, cp) == 0 || under(pattern, cp)) return 1;
  }
  return 0;
}

/* The side whose shared list `list_pattern` is: the innermost pair anchor
 * holding it, when the list lies directly beneath it (not below an item of
 * it), outside a copy and outside the pair's `detailOnly` places. */
static const MdSide *shared_list_side(MdNav *nav, MdCodec *c,
                                      const char *list_pattern,
                                      const char *concrete_list) {
  if (under_copy(nav, list_pattern)) return NULL;
  all_sides(nav, c);
  const MdSide *best = NULL;
  for (size_t i = 0; i < nav->sides_len; i++) {
    const MdSide *s = &nav->sides[i];
    if (!under(list_pattern, s->mine)) continue;
    if (best == NULL || strlen(s->mine) > strlen(best->mine)) best = s;
  }
  if (best == NULL) return NULL;
  const char *rel = list_pattern + strlen(best->mine) + 1;
  if (strstr(rel, "-*") != NULL) return NULL;
  /* The anchor's concrete path: the list's as long as the anchor is. */
  size_t depth = segment_count(best->mine);
  SomStrList parts;
  spec_path_segments(concrete_list, &parts);
  SomBuf ab;
  som_buf_init(&ab);
  for (size_t i = 0; i < depth && i < parts.len; i++) {
    if (i > 0) som_buf_putc(&ab, '/');
    som_buf_puts(&ab, parts.items[i]);
  }
  som_strlist_free(&parts);
  char *anchor = som_buf_take(&ab);
  const MdSide *result = best;
  for (size_t i = 0; i < best->sync->detail_only.len && result != NULL; i++) {
    SpecPlaceResolution r;
    spec_place_resolution_init(&r);
    if (spec_resolve_place_at(&nav->refl, best->sync->detail_only.items[i],
                              anchor, &r)) {
      const char *p = spec_mdi_nav_walk(nav, c, r.path)->pattern;
      if (strcmp(list_pattern, p) == 0 || under(list_pattern, p)) result = NULL;
    }
    spec_place_resolution_free(&r);
  }
  free(anchor);
  return result;
}

/* The `@SummaryOf` of the list member at `list_path`: 1 filling `*out`. */
static int summary_of_list(const MdNav *nav, const char *list_path,
                           SpecSummaryOf *out) {
  SpecResolution r;
  if (!spec_reflection_resolve(&nav->refl, list_path, &r)) return 0;
  int found = r.field != NULL && spec_annotations_summary_of(&r.field->annotations, out);
  spec_resolution_free(&r);
  return found;
}

/* Whether a summary names its detail elements in this document. */
static int same_document(const MdNav *nav, const SpecSummaryOf *s) {
  return s->document == NULL || s->document[0] == '\0' ||
         strcmp(s->document, nav->root->type) == 0;
}

static long detail_index(const MdNav *nav, const char *key) {
  for (size_t i = 0; i < nav->detail_keys.len; i++) {
    if (strcmp(nav->detail_keys.items[i], key) == 0) return (long)i;
  }
  return -1;
}

/* Detail-list pattern -> the summary lists (patterns) of this document naming
 * its elements, and the patterns in insertion order. */
static void detail_lists_map(MdNav *nav, MdCodec *c) {
  if (nav->detail_loaded) return;
  nav->detail_loaded = 1;
  size_t cap = 0;
  for (size_t i = 0; i < nav->tree->all_nodes_len; i++) {
    const SomMetaNode *node = nav->tree->all_nodes[i];
    if (strcmp(node->kind, SOM_META_KIND_LIST) != 0 || !node->has_path ||
        node->path == NULL || node->path[0] == '\0') {
      continue;
    }
    const char *np = node->path;
    SpecSummaryOf s;
    if (!summary_of_list(nav, np, &s)) continue;
    if (same_document(nav, &s)) {
      char *owner = owner_of(np);
      SpecPlaceResolution r;
      spec_place_resolution_init(&r);
      if (spec_resolve_link_place(&nav->refl, NULL, s.detail, nav->root_seg,
                                  owner, &r)) {
        char *cut = cut_pattern(r.path);
        const char *key = spec_mdi_nav_walk(nav, c, cut)->pattern;
        long k = detail_index(nav, key);
        if (k < 0) {
          if (nav->detail_keys.len == cap) {
            cap = cap ? cap * 2 : 4;
            nav->detail_lists = realloc(nav->detail_lists, cap * sizeof(SomStrList));
          }
          som_strlist_init(&nav->detail_lists[nav->detail_keys.len]);
          som_strlist_push_copy(&nav->detail_keys, key);
          k = (long)nav->detail_keys.len - 1;
        }
        som_strlist_push_copy(&nav->detail_lists[k], np);
        free(cut);
      }
      spec_place_resolution_free(&r);
      free(owner);
    }
    spec_summary_of_free(&s);
  }
}

/* ---- markable places (structural: the parser and the emitter agree) ----- */

static void derived_sources(MdNav *nav, MdCodec *c, const char *path,
                            const SomMetaNode *node, int probe,
                            int section_table, MdDerivedVec *out);
static void extract_from(MdNav *nav, MdCodec *c, const char *path,
                         SomStrList *out);

char *spec_mdi_nav_item_list_path(MdNav *nav, const char *path) {
  const char *slash = strrchr(path, '/');
  if (slash == NULL) return NULL;
  const char *seg = slash + 1;
  char *base = NULL;
  long long seq = 0;
  if (!spec_split_list_item_segment(seg, &base, &seq)) return NULL;
  char *parent = som_strdup_n(path, (size_t)(slash - path));
  const SomMetaNode *pnode = som_meta_tree_by_path(nav->tree, parent);
  if (pnode != NULL && som_meta_node_child_by_segment(pnode, seg) != NULL) {
    free(parent);
    free(base);
    return NULL;
  }
  char *list_path = cat3(parent, "/", base);
  free(parent);
  free(base);
  const SomMetaNode *list_node = som_meta_tree_by_path(nav->tree, list_path);
  if (list_node == NULL || strcmp(list_node->kind, SOM_META_KIND_LIST) != 0) {
    free(list_path);
    return NULL;
  }
  return list_path;
}

static int compute_markable(MdNav *nav, MdCodec *c, const char *path) {
  const MdWalk *w = spec_mdi_nav_walk(nav, c, path);
  const SomMetaNode *node = w->node;
  if (node == NULL || strcmp(w->heading_path, path) != 0) return 0;
  const char *pattern = w->pattern;
  all_sides(nav, c);
  for (size_t i = 0; i < nav->sides_len; i++) {
    if (strcmp(nav->sides[i].mine, pattern) == 0) return 1;
  }
  char *list_path = spec_mdi_nav_item_list_path(nav, path);
  if (list_path != NULL) {
    char *lp = list_pattern_of(pattern);
    int yes = shared_list_side(nav, c, lp, list_path) != NULL;
    if (!yes) {
      SpecSummaryOf s;
      if (summary_of_list(nav, list_path, &s)) {
        yes = 1;
        spec_summary_of_free(&s);
      }
    }
    if (!yes) {
      detail_lists_map(nav, c);
      yes = detail_index(nav, lp) >= 0;
    }
    free(lp);
    free(list_path);
    if (yes) return 1;
  }
  MdDerivedVec d = {NULL, 0, 0};
  derived_sources(nav, c, path, node, 1, 0, &d);
  int any = d.len > 0;
  derived_free(&d);
  if (any) return 1;
  if (strcmp(node->kind, SOM_META_KIND_LIST) == 0) {
    SomStrList from;
    extract_from(nav, c, path, &from);
    any = from.len > 0;
    som_strlist_free(&from);
    if (any) return 1;
  }
  const SpecSameAsBindingList *l = same_as_bindings(nav);
  for (size_t i = 0; i < l->len; i++) {
    const SpecSameAsBinding *b = &l->items[i];
    if ((b->copy_path != NULL && strcmp(b->copy_path, pattern) == 0) ||
        (b->holder_path != NULL && strcmp(b->holder_path, pattern) == 0)) {
      return 1;
    }
  }
  return 0;
}

int spec_mdi_nav_markable(MdNav *nav, MdCodec *c, const char *path) {
  const char *hit = som_map_get(&nav->markables, path);
  if (hit != NULL) return hit[0] == '1';
  int v = compute_markable(nav, c, path);
  som_map_set(&nav->markables, path, v ? "1" : "0");
  return v;
}

/* ---- the marker ---------------------------------------------------------- */

/* A link to `anchor` in `other` (NULL: this document), its text `id`
 * prefixed by the other root's id. Owned. */
static char *link_to_anchor(MdCodec *c, const char *id, const char *anchor,
                            const SpecRoot *other) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  if (other != NULL) {
    som_buf_puts(&b, root_name(other));
    som_buf_putc(&b, ' ');
  }
  som_buf_puts(&b, id);
  som_buf_puts(&b, "](");
  if (other != NULL) {
    char *file = spec_mdi_file_of_root(c, other);
    som_buf_puts(&b, file);
    free(file);
  }
  som_buf_putc(&b, '#');
  som_buf_puts(&b, anchor);
  som_buf_putc(&b, ')');
  return som_buf_take(&b);
}

/* `held here` / `held there`, with the places held here. Owned. */
static char *held_note(const MdSide *s) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, s->holder ? "held here" : "held there");
  if (s->sync->held_here.len > 0) {
    char *j = som_strlist_join(&s->sync->held_here, ", ");
    som_buf_puts(&b, " except ");
    som_buf_puts(&b, j);
    free(j);
  }
  return som_buf_take(&b);
}

static char *also_in(MdCodec *c, const char *id, const char *anchor,
                     const MdSide *s) {
  char *link = link_to_anchor(c, id, anchor, s->other);
  char *note = held_note(s);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "Also in ");
  som_buf_puts(&b, link);
  som_buf_puts(&b, ", ");
  som_buf_puts(&b, note);
  free(link);
  free(note);
  return som_buf_take(&b);
}

static void summary_ids(MdNav *nav, MdCodec *c, const char *element,
                        const SpecSummaryOf *s, const char *own_id,
                        SomStrList *out);
static void summary_targets(MdNav *nav, MdCodec *c, const char *element,
                            const char *list_path, const char *own_id,
                            const SpecSummaryOf *s, MdTargets *out);
static const SomStrList *summary_links_for(MdNav *nav, MdCodec *c,
                                           const char *key);

static const char *const *ids_of(const MdWalk *w) {
  return (const char *const *)w->item_ids.items;
}

void spec_mdi_nav_entries(MdNav *nav, MdCodec *c, const char *path,
                          int section_table, SomStrList *out) {
  som_strlist_init(out);
  if (!spec_mdi_nav_markable(nav, c, path)) return;
  const MdWalk *w = spec_mdi_nav_walk(nav, c, path);
  const SomMetaNode *node = w->node;
  if (node == NULL) return;
  const char *pattern = w->pattern;
  all_sides(nav, c);

  /* Also in (@SyncedWith). */
  for (size_t i = 0; i < nav->sides_len; i++) {
    const MdSide *s = &nav->sides[i];
    if (strcmp(s->mine, pattern) != 0) continue;
    char *err = NULL;
    SomMetaTree *other_tree = spec_mdi_tree_for(c, s->other->type, &err);
    free(err);
    if (other_tree == NULL) continue;
    MdWalk there;
    walk_into(nav, c, s->theirs, other_tree, ids_of(w), w->item_ids.len, &there);
    som_strlist_push(out, also_in(c, w->heading_id, there.anchor, s));
    spec_mdi_walk_free(&there);
  }
  char *list_path = spec_mdi_nav_item_list_path(nav, path);
  if (list_path != NULL) {
    char *lp = list_pattern_of(pattern);
    const MdSide *side = shared_list_side(nav, c, lp, list_path);
    if (side != NULL) {
      char *err = NULL;
      SomMetaTree *other_tree = spec_mdi_tree_for(c, side->other->type, &err);
      free(err);
      if (other_tree != NULL) {
        const char *rel = lp + strlen(side->mine);
        char *x = cat3(side->theirs, rel, "-*");
        MdWalk there;
        walk_into(nav, c, x, other_tree, ids_of(w), w->item_ids.len, &there);
        som_strlist_push(out, also_in(c, w->heading_id, there.anchor, side));
        spec_mdi_walk_free(&there);
        free(x);
      }
    }
    free(lp);

    /* Summary of (@SummaryOf on the list). */
    SpecSummaryOf summary;
    if (summary_of_list(nav, list_path, &summary)) {
      MdTargets t = {NULL, 0};
      summary_targets(nav, c, path, list_path, w->heading_id, &summary, &t);
      if (t.len > 0) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "Summary of ");
        for (size_t i = 0; i < t.len; i++) {
          if (i > 0) som_buf_puts(&b, ", ");
          char *link = link_to_anchor(c, t.items[i].id, t.items[i].anchor,
                                      t.items[i].other);
          som_buf_puts(&b, link);
          free(link);
        }
        som_strlist_push(out, som_buf_take(&b));
      }
      targets_free(&t);
      spec_summary_of_free(&summary);
    }

    /* Summarised in: the summary elements of this document naming it. */
    char *key = cat3(list_path, "#", w->heading_id);
    const SomStrList *named = summary_links_for(nav, c, key);
    if (named != NULL) {
      char *j = som_strlist_join(named, ", ");
      som_strlist_push(out, cat3("Summarised in ", j, ""));
      free(j);
    }
    free(key);
    free(list_path);
  }

  /* Derived from. */
  MdDerivedVec derived = {NULL, 0, 0};
  derived_sources(nav, c, path, node, 0, section_table, &derived);
  if (derived.len > 0) {
    SomStrList dlinks, fields;
    som_strlist_init(&dlinks);
    som_strlist_init(&fields);
    for (size_t i = 0; i < derived.len; i++) {
      if (derived.items[i].link[0] != '\0') add_unique(&dlinks, derived.items[i].link);
      if (derived.items[i].field[0] != '\0') add_unique(&fields, derived.items[i].field);
    }
    if (dlinks.len > 0) {
      SomBuf b;
      som_buf_init(&b);
      char *j = som_strlist_join(&dlinks, ", ");
      som_buf_puts(&b, "Derived from ");
      som_buf_puts(&b, j);
      free(j);
      if (fields.len > 0) {
        j = som_strlist_join(&fields, ", ");
        som_buf_puts(&b, ": ");
        som_buf_puts(&b, j);
        free(j);
      }
      som_strlist_push(out, som_buf_take(&b));
    }
    som_strlist_free(&dlinks);
    som_strlist_free(&fields);
  }
  derived_free(&derived);

  /* Extracted from (@ExtractsLinks, generate). */
  if (strcmp(node->kind, SOM_META_KIND_LIST) == 0) {
    SomStrList from;
    extract_from(nav, c, path, &from);
    if (from.len > 0) {
      char *j = som_strlist_join(&from, ", ");
      som_strlist_push(out, cat3("Extracted from ", j, ""));
      free(j);
    }
    som_strlist_free(&from);
  }

  /* Copy of / Copied to (@SameAs). */
  const SpecSameAsBindingList *l = same_as_bindings(nav);
  for (size_t i = 0; i < l->len; i++) {
    const SpecSameAsBinding *b = &l->items[i];
    if (b->copy_path == NULL || strcmp(b->copy_path, pattern) != 0 ||
        b->holder_path == NULL || b->holder_path[0] == '\0') {
      continue;
    }
    MdWalk h;
    walk_into(nav, c, b->holder_path, NULL, ids_of(w), w->item_ids.len, &h);
    char *link = link_to_anchor(c, h.heading_id, h.anchor, NULL);
    som_strlist_push(out, cat3("Copy of ", link, ", edit it there"));
    free(link);
    spec_mdi_walk_free(&h);
  }
  SomStrList copies;
  som_strlist_init(&copies);
  for (size_t i = 0; i < l->len; i++) {
    const SpecSameAsBinding *b = &l->items[i];
    if (b->holder_path == NULL || strcmp(b->holder_path, pattern) != 0) continue;
    MdWalk cw;
    walk_into(nav, c, b->copy_path, NULL, ids_of(w), w->item_ids.len, &cw);
    som_strlist_push(&copies, link_to_anchor(c, cw.heading_id, cw.anchor, NULL));
    spec_mdi_walk_free(&cw);
  }
  if (copies.len > 0) {
    char *j = som_strlist_join(&copies, ", ");
    som_strlist_push(out, cat3("Copied to ", j, ""));
    free(j);
  }
  som_strlist_free(&copies);
}

/* `<detail list path>#<element id>` -> the links to the summary elements of
 * this document naming that element, in document order. */
static void summary_links_load(MdNav *nav, MdCodec *c) {
  if (nav->summary_loaded) return;
  nav->summary_loaded = 1;
  detail_lists_map(nav, c);
  SomStrList summaries;
  som_strlist_init(&summaries);
  for (size_t k = 0; k < nav->detail_keys.len; k++) {
    for (size_t i = 0; i < nav->detail_lists[k].len; i++) {
      add_unique(&summaries, nav->detail_lists[k].items[i]);
    }
  }
  const SpecDocument *doc = spec_mdi_document(c);
  size_t cap = 0;
  for (size_t si = 0; si < summaries.len; si++) {
    SomStrList concretes;
    spec_expand_pattern(doc, summaries.items[si], &concretes);
    for (size_t ci = 0; ci < concretes.len; ci++) {
      const char *concrete = concretes.items[ci];
      SpecSummaryOf s;
      if (!summary_of_list(nav, concrete, &s)) continue;
      char *owner = owner_of(concrete);
      SpecPlaceResolution r;
      spec_place_resolution_init(&r);
      if (spec_resolve_link_place(&nav->refl, doc, s.detail, nav->root_seg,
                                  owner, &r)) {
        char *detail = cut_pattern(r.path);
        const SomStrList *items = spec_document_list_items(doc, concrete);
        for (size_t e = 0; items != NULL && e < items->len; e++) {
          char *item = som_strdup(items->items[e]);
          const MdWalk *ew = spec_mdi_nav_walk(nav, c, item);
          SomStrList ids;
          summary_ids(nav, c, item, &s, ew->heading_id, &ids);
          for (size_t m = 0; m < ids.len; m++) {
            char *link = link_to_anchor(c, ew->heading_id, ew->anchor, NULL);
            char *key = cat3(detail, "#", ids.items[m]);
            long found = -1;
            for (size_t q = 0; q < nav->summary_keys.len; q++) {
              if (strcmp(nav->summary_keys.items[q], key) == 0) {
                found = (long)q;
                break;
              }
            }
            if (found < 0) {
              if (nav->summary_keys.len == cap) {
                cap = cap ? cap * 2 : 4;
                nav->summary_links =
                    realloc(nav->summary_links, cap * sizeof(SomStrList));
              }
              som_strlist_init(&nav->summary_links[nav->summary_keys.len]);
              som_strlist_push(&nav->summary_keys, key);
              found = (long)nav->summary_keys.len - 1;
            } else {
              free(key);
            }
            add_unique(&nav->summary_links[found], link);
            free(link);
          }
          som_strlist_free(&ids);
          free(item);
        }
        free(detail);
      }
      spec_place_resolution_free(&r);
      free(owner);
      spec_summary_of_free(&s);
    }
    som_strlist_free(&concretes);
  }
  som_strlist_free(&summaries);
}

static const SomStrList *summary_links_for(MdNav *nav, MdCodec *c,
                                           const char *key) {
  summary_links_load(nav, c);
  for (size_t i = 0; i < nav->summary_keys.len; i++) {
    if (strcmp(nav->summary_keys.items[i], key) == 0) return &nav->summary_links[i];
  }
  return NULL;
}

/* The ids summary element `element` names: its `match` field's ids, else its
 * own `own_id` (`*out` initialised by the callee). */
static void summary_ids(MdNav *nav, MdCodec *c, const char *element,
                        const SpecSummaryOf *s, const char *own_id,
                        SomStrList *out) {
  som_strlist_init(out);
  if (s->match == NULL || s->match[0] == '\0') {
    som_strlist_push_copy(out, own_id);
    return;
  }
  SpecPlaceResolution r;
  spec_place_resolution_init(&r);
  if (spec_resolve_place_at(&nav->refl, s->match, element, &r)) {
    const char *field = spec_place_resolution_field(&r);
    if (field != NULL && field[0] != '\0') {
      const char *raw = spec_document_form_field(spec_mdi_document(c), r.path, field);
      if (raw != NULL) {
        SomStrList ids;
        spec_link_ids(raw, &ids);
        for (size_t i = 0; i < ids.len; i++) som_strlist_push_copy(out, ids.items[i]);
        som_strlist_free(&ids);
      }
    }
  }
  spec_place_resolution_free(&r);
}

/* The detail elements summary element `element` of `list_path` names
 * (`*out` filled by the callee). */
static void summary_targets(MdNav *nav, MdCodec *c, const char *element,
                            const char *list_path, const char *own_id,
                            const SpecSummaryOf *s, MdTargets *out) {
  out->items = NULL;
  out->len = 0;
  SomStrList ids;
  summary_ids(nav, c, element, s, own_id, &ids);
  if (ids.len == 0) {
    som_strlist_free(&ids);
    return;
  }
  char *owner = owner_of(list_path);
  if (same_document(nav, s)) {
    SpecPlaceResolution r;
    spec_place_resolution_init(&r);
    if (spec_resolve_link_place(&nav->refl, spec_mdi_document(c), s->detail,
                                nav->root_seg, owner, &r)) {
      char *cut = cut_pattern(r.path);
      char *list = cat3(cut, "-*", "");
      out->items = calloc(ids.len, sizeof(MdTarget));
      for (size_t i = 0; i < ids.len; i++) {
        const char *one[1] = {ids.items[i]};
        MdWalk w;
        walk_into(nav, c, list, NULL, one, 1, &w);
        out->items[i].id = som_strdup(ids.items[i]);
        out->items[i].anchor = w.anchor;
        w.anchor = NULL;
        out->items[i].other = NULL;
        spec_mdi_walk_free(&w);
      }
      out->len = ids.len;
      free(list);
      free(cut);
    }
    spec_place_resolution_free(&r);
    free(owner);
    som_strlist_free(&ids);
    return;
  }
  free(owner);
  const SpecRoot *other = root_of_type(nav, s->document);
  if (other == NULL) {
    som_strlist_free(&ids);
    return;
  }
  const char *other_seg = spec_reflection_root_segment(other);
  SpecPlaceResolution r;
  spec_place_resolution_init(&r);
  int resolved = spec_resolve_link_place(&nav->refl, NULL, s->detail, other_seg,
                                         other_seg, &r);
  char *err = NULL;
  SomMetaTree *other_tree = spec_mdi_tree_for(c, other->type, &err);
  free(err);
  out->items = calloc(ids.len, sizeof(MdTarget));
  for (size_t i = 0; i < ids.len; i++) {
    char *anchor = som_strdup(ids.items[i]);
    if (resolved && other_tree != NULL && strstr(r.path, "-*") == NULL) {
      char *list = cat3(r.path, "-*", "");
      const char *one[1] = {ids.items[i]};
      MdWalk w;
      walk_into(nav, c, list, other_tree, one, 1, &w);
      free(anchor);
      anchor = w.anchor;
      w.anchor = NULL;
      spec_mdi_walk_free(&w);
      free(list);
    }
    out->items[i].id = som_strdup(ids.items[i]);
    out->items[i].anchor = anchor;
    out->items[i].other = other;
  }
  out->len = ids.len;
  spec_place_resolution_free(&r);
  som_strlist_free(&ids);
}

char *spec_mdi_nav_summary_id_cell(MdNav *nav, MdCodec *c, const char *item,
                                   const char *list_path, const char *id) {
  SpecSummaryOf s;
  if (!summary_of_list(nav, list_path, &s)) return NULL;
  char *out = NULL;
  /* Without `match` a summary element names exactly one detail element. */
  if (s.match == NULL || s.match[0] == '\0') {
    MdTargets t = {NULL, 0};
    summary_targets(nav, c, item, list_path, id, &s, &t);
    if (t.len > 0) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "<a id=\"");
      som_buf_puts(&b, spec_mdi_nav_walk(nav, c, item)->anchor);
      som_buf_puts(&b, "\"></a>[");
      som_buf_puts(&b, id);
      som_buf_puts(&b, "](");
      if (t.items[0].other != NULL) {
        char *file = spec_mdi_file_of_root(c, t.items[0].other);
        som_buf_puts(&b, file);
        free(file);
      }
      som_buf_putc(&b, '#');
      som_buf_puts(&b, t.items[0].anchor);
      som_buf_putc(&b, ')');
      out = som_buf_take(&b);
    }
    targets_free(&t);
  }
  spec_summary_of_free(&s);
  return out;
}

/* A link to the heading `target` (a pattern cut at its first list item).
 * Owned. */
static char *link_to(MdNav *nav, MdCodec *c, const char *target) {
  char *cut = cut_pattern(target);
  const MdWalk *t = spec_mdi_nav_walk(nav, c, cut);
  free(cut);
  return link_to_anchor(c, t->heading_id, t->anchor, NULL);
}

/* The link to the source `place` of a link annotated at `owner`; "" when
 * probing or when it does not resolve. Owned. */
static char *source_link(MdNav *nav, MdCodec *c, const char *place,
                         const char *owner, int probe) {
  if (probe) return som_strdup("");
  SpecPlaceResolution r;
  spec_place_resolution_init(&r);
  char *out;
  if (spec_resolve_link_place(&nav->refl, spec_mdi_document(c), place,
                              nav->root_seg, owner, &r)) {
    out = link_to(nav, c, r.path);
  } else {
    out = som_strdup("");
  }
  spec_place_resolution_free(&r);
  return out;
}

/* The derived form fields of the form at `form_path`, named with `prefix`. */
static void derived_form(MdNav *nav, MdCodec *c, const char *form_path,
                         const char *prefix, int probe, MdDerivedVec *out) {
  SpecResolution res;
  if (!spec_reflection_resolve(&nav->refl, form_path, &res)) return;
  const SpecField *field = res.field;
  spec_resolution_free(&res);
  if (field == NULL) return;
  char *owner = owner_of(form_path);
  for (size_t i = 0; i < field->form_fields_len; i++) {
    const FormFieldSpec *ff = &field->form_fields[i];
    char *name = prefix[0] == '\0' ? som_strdup(ff->name)
                                   : cat3(prefix, ".", ff->name);
    if (ff->derived_from != NULL) {
      derived_push(out, source_link(nav, c, ff->derived_from->source, owner, probe),
                   name);
    }
    for (size_t k = 0; k < ff->count_of.len; k++) {
      SpecPlaceFilter f;
      if (!spec_place_filter_try_parse(ff->count_of.items[k], &f)) continue;
      char *place = f.scoped ? cat3("./", f.section_id, "") : som_strdup(f.section_id);
      derived_push(out, source_link(nav, c, place, owner, probe), name);
      free(place);
      spec_place_filter_free(&f);
    }
    for (size_t k = 0; k < ff->product_of.len; k++) {
      const char *operand = ff->product_of.items[k];
      char *link;
      if (probe) {
        link = som_strdup("");
      } else {
        const char *dot = strchr(operand, '.');
        if (dot == NULL) {
          link = link_to(nav, c, form_path);
        } else {
          char *op = som_strdup_n(operand, (size_t)(dot - operand));
          char *target = cat3(owner, "/", op);
          link = link_to(nav, c, target);
          free(target);
          free(op);
        }
      }
      derived_push(out, link, name);
    }
    if (ff->rank_of != NULL && ff->rank_of[0] != '\0') {
      char *link;
      if (probe) {
        link = som_strdup("");
      } else {
        char *list_path = spec_mdi_nav_item_list_path(nav, owner);
        link = link_to(nav, c, list_path != NULL ? list_path : form_path);
        free(list_path);
      }
      derived_push(out, link, name);
    }
    free(name);
  }
  free(owner);
}

/* A member carrying `@DerivedFrom`: `name` for one written in its owner's
 * body (no heading of its own), "" for the heading itself. */
static void derived_member(MdNav *nav, MdCodec *c, const char *member_path,
                           const char *name, int probe, MdDerivedVec *out) {
  SpecResolution res;
  if (!spec_reflection_resolve(&nav->refl, member_path, &res)) return;
  const SpecField *field = res.field;
  spec_resolution_free(&res);
  if (field == NULL) return;
  SpecDerivation d;
  if (!spec_annotations_derived_from(&field->annotations, &d)) return;
  char *owner = owner_of(member_path);
  derived_push(out, source_link(nav, c, d.source, owner, probe), name);
  free(owner);
  spec_derivation_free(&d);
}

/* The derived values at the heading `path`: a link to a source ("": none) and
 * the derived field's name ("": a derived section) per source. `probe`:
 * whether there is any, structurally (no links built). */
static void derived_sources(MdNav *nav, MdCodec *c, const char *path,
                            const SomMetaNode *node, int probe,
                            int section_table, MdDerivedVec *out) {
  char *list_path = spec_mdi_nav_item_list_path(nav, path);
  int is_item = list_path != NULL;
  free(list_path);
  if (strcmp(node->kind, SOM_META_KIND_FORM) == 0) {
    derived_form(nav, c, path, "", probe, out);
  }
  if (!is_item && strchr(path, '/') != NULL) {
    derived_member(nav, c, path, "", probe, out);
  }
  if (strcmp(node->kind, SOM_META_KIND_SECTION) == 0 ||
      strcmp(node->kind, SOM_META_KIND_COMPLEX) == 0 || is_item) {
    NodeRelVec slots;
    spec_mdi_body_slots(c, node, &slots);
    for (size_t i = 0; i < slots.len; i++) {
      const SomMetaNode *sn = slots.items[i].node;
      char *slot_path = cat3(path, "/", slots.items[i].rel);
      if (strcmp(sn->kind, SOM_META_KIND_FORM) == 0) {
        derived_form(nav, c, slot_path, "", probe, out);
      } else {
        const char *name = sn->member_name[0] != '\0' ? sn->member_name
                                                      : som_meta_node_segment(sn);
        derived_member(nav, c, slot_path, name, probe, out);
      }
      free(slot_path);
    }
    spec_mdi_nrv_free(&slots);
    if (section_table || probe) {
      NodeRelVec eff;
      spec_mdi_effective_children(c, node, &eff);
      for (size_t i = 0; i < eff.len; i++) {
        const SomMetaNode *child = eff.items[i].node;
        if (strcmp(child->kind, SOM_META_KIND_FORM) != 0) continue;
        char *child_path = cat3(path, "/", eff.items[i].rel);
        if (probe ||
            spec_document_has_values_under(spec_mdi_document(c), child_path)) {
          char *hid = spec_mdi_heading_id_of(c, child);
          derived_form(nav, c, child_path, hid, probe, out);
          free(hid);
        }
        free(child_path);
      }
      spec_mdi_nrv_free(&eff);
    }
  }
}

/* The `Extracted from` links of the link-row list at `path`: the text places
 * of its `@ExtractsLinks` in `generate` mode (`*out` initialised by the
 * callee). */
static void extract_from(MdNav *nav, MdCodec *c, const char *path,
                         SomStrList *out) {
  som_strlist_init(out);
  SpecResolution res;
  if (!spec_reflection_resolve(&nav->refl, path, &res)) return;
  const SpecField *field = res.field;
  spec_resolution_free(&res);
  if (field == NULL) return;
  SpecExtractsLinksList list;
  spec_annotations_extracts_links(&field->annotations, &list);
  char *owner = owner_of(path);
  for (size_t i = 0; i < list.len; i++) {
    const SpecExtractsLinks *e = &list.items[i];
    if (e->mode == NULL || strcmp(e->mode, "generate") != 0) continue;
    for (size_t k = 0; k < e->from.len; k++) {
      SpecPlaceResolution r;
      spec_place_resolution_init(&r);
      if (spec_resolve_link_place(&nav->refl, spec_mdi_document(c),
                                  e->from.items[k], nav->root_seg, owner, &r)) {
        char *link = link_to(nav, c, r.path);
        add_unique(out, link);
        free(link);
      }
      spec_place_resolution_free(&r);
    }
  }
  free(owner);
  spec_extracts_links_list_free(&list);
}

/* ---- the marker's paragraph and placeholders ----------------------------- */

static int is_space(char ch) {
  return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\f' ||
         ch == '\v';
}

int spec_mdi_is_linked_paragraph(const char *paragraph) {
  const char *s = paragraph;
  while (*s != '\0' && is_space(*s)) s++;
  size_t n = strlen(s);
  while (n > 0 && is_space(s[n - 1])) n--;
  static const char tail[] = "{.linked}";
  size_t tl = sizeof(tail) - 1;
  if (n == 0 || s[0] != '[' || n < tl || memcmp(s + n - tl, tail, tl) != 0) {
    return 0;
  }
  char *text = som_strdup_n(s, n);
  SpecNotationScan scan;
  spec_scan_notation(text, 0, &scan);
  int ok = scan.elements_len == 1;
  if (ok) {
    const SpecNotationElement *e = scan.elements[0];
    ok = e->type == SPEC_NOTATION_SPAN && e->kind != NULL &&
         strcmp(e->kind, "linked") == 0 && e->start == 0 && e->end == n;
  }
  spec_notation_scan_free(&scan);
  free(text);
  return ok;
}

/* `text` split on '\n' into `out` (initialised by the callee). */
static void split_on_newlines(const char *text, SomStrList *out) {
  som_strlist_init(out);
  const char *p = text;
  for (;;) {
    const char *nl = strchr(p, '\n');
    if (nl == NULL) {
      som_strlist_push_copy(out, p);
      break;
    }
    som_strlist_push(out, som_strdup_n(p, (size_t)(nl - p)));
    p = nl + 1;
  }
}

static int blank(const char *s) {
  while (*s != '\0') {
    if (!is_space(*s)) return 0;
    s++;
  }
  return 1;
}

char *spec_mdi_resolve_linked_placeholders(char *markdown) {
  if (strstr(markdown, SPEC_MDI_LINKED_PLACEHOLDER) == NULL) return markdown;
  SomStrList lines;
  split_on_newlines(markdown, &lines);
  free(markdown);
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  size_t i = 0;
  while (i < lines.len) {
    if (strcmp(lines.items[i], SPEC_MDI_LINKED_PLACEHOLDER) != 0) {
      if (!first) som_buf_putc(&b, '\n');
      som_buf_puts(&b, lines.items[i]);
      first = 0;
      i++;
      continue;
    }
    /* The placeholder, its blank line, then the paragraph that follows. */
    size_t k = i + 1;
    while (k < lines.len && blank(lines.items[k])) k++;
    size_t j = k;
    while (j < lines.len && !blank(lines.items[j])) j++;
    int linked = 0;
    if (j > k) {
      SomBuf para;
      som_buf_init(&para);
      for (size_t m = k; m < j; m++) {
        if (m > k) som_buf_putc(&para, '\n');
        som_buf_puts(&para, lines.items[m]);
      }
      char *p = som_buf_take(&para);
      linked = spec_mdi_is_linked_paragraph(p);
      free(p);
    }
    if (linked) {
      if (!first) som_buf_putc(&b, '\n');
      som_buf_puts(&b, "[]{.linked}");
      first = 0;
      i++;
    } else {
      i += 2; /* the blank line after the placeholder goes with it */
    }
  }
  som_strlist_free(&lines);
  return som_buf_take(&b);
}
