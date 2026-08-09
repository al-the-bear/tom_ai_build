#include "spec_query.h"

#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"

#define K_ASTERISK 0x2A /* * */
#define K_SLASH 0x2F    /* / */

/* The package convention: `""` stands in for the other ports' `null`. These two
 * keep the `?? ` chains of the Dart reference readable. */
static int is_set(const char *s) { return s != NULL && s[0] != '\0'; }
static const char *or_empty(const char *s) { return s == NULL ? "" : s; }

/* ---- state filter --------------------------------------------------------- */

int spec_state_filter_parse(const char *name, SpecStateFilter *out) {
  if (name == NULL) {
    return 0;
  }
  if (strcmp(name, "empty") == 0) {
    *out = SPEC_STATE_EMPTY;
    return 1;
  }
  if (strcmp(name, "nonEmpty") == 0) {
    *out = SPEC_STATE_NON_EMPTY;
    return 1;
  }
  return 0;
}

const char *spec_state_filter_name(SpecStateFilter s) {
  return s == SPEC_STATE_NON_EMPTY ? "nonEmpty" : "empty";
}

/* ---- projections ---------------------------------------------------------- */

void spec_node_projection_free(SpecNodeProjection *p) {
  free(p->path);
  free(p->class_id);
  free(p->section_id);
  free(p->maps_to);
  free(p->detailed_in);
  free(p->headline);
  som_strlist_free(&p->searchable_strings);
  p->path = NULL;
  p->class_id = NULL;
  p->section_id = NULL;
  p->maps_to = NULL;
  p->detailed_in = NULL;
  p->headline = NULL;
  p->kind = NULL;
  p->has_value = 0;
}

void spec_node_projection_list_init(SpecNodeProjectionList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

static void projection_list_push(SpecNodeProjectionList *l,
                                 SpecNodeProjection p) {
  if (l->len == l->cap) {
    l->cap = (l->cap == 0) ? 16 : l->cap * 2;
    l->items = (SpecNodeProjection *)realloc(
        l->items, l->cap * sizeof(SpecNodeProjection));
  }
  l->items[l->len++] = p;
}

void spec_node_projection_list_free(SpecNodeProjectionList *l) {
  size_t i;
  for (i = 0; i < l->len; i++) {
    spec_node_projection_free(&l->items[i]);
  }
  free(l->items);
  spec_node_projection_list_init(l);
}

/* ---- matches -------------------------------------------------------------- */

void spec_query_match_free(SpecQueryMatch *m) {
  free(m->path);
  free(m->class_id);
  free(m->headline);
  free(m->snippet);
  spec_match_span_list_free(&m->spans);
  m->path = NULL;
  m->class_id = NULL;
  m->headline = NULL;
  m->snippet = NULL;
  m->kind = NULL;
}

void spec_query_match_list_init(SpecQueryMatchList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

static void match_list_push(SpecQueryMatchList *l, SpecQueryMatch m) {
  if (l->len == l->cap) {
    l->cap = (l->cap == 0) ? 8 : l->cap * 2;
    l->items =
        (SpecQueryMatch *)realloc(l->items, l->cap * sizeof(SpecQueryMatch));
  }
  l->items[l->len++] = m;
}

void spec_query_match_list_free(SpecQueryMatchList *l) {
  size_t i;
  for (i = 0; i < l->len; i++) {
    spec_query_match_free(&l->items[i]);
  }
  free(l->items);
  spec_query_match_list_init(l);
}

/* ---- the query ------------------------------------------------------------ */

void spec_query_init(SpecQuery *q) {
  q->text = NULL;
  q->regex = 0;
  q->case_insensitive = 0;
  q->kinds = NULL;
  q->class_name = NULL;
  q->section_id_exact = NULL;
  q->section_id_prefix = NULL;
  q->path_glob = NULL;
  q->maps_to = NULL;
  q->detailed_in = NULL;
  q->has_state = 0;
  q->state = SPEC_STATE_EMPTY;
}

SpecQueryEngine spec_query_engine_make(const SpecModel *model,
                                       const SpecDocument *document) {
  SpecQueryEngine e;
  e.model = model;
  e.document = document;
  e.reflection = spec_reflection_make(model);
  return e;
}

/* ---- node descriptors ----------------------------------------------------- */

/* `field?.sectionId ?? targetClass?.sectionId ?? root.sectionId` — a borrowed
 * pointer, or NULL when nothing carries one. */
static const char *section_id_of(const SpecResolution *r) {
  if (r->field != NULL && is_set(r->field->section_id)) {
    return r->field->section_id;
  }
  if (r->target_class != NULL && is_set(r->target_class->section_id)) {
    return r->target_class->section_id;
  }
  if (r->root != NULL && is_set(r->root->section_id)) {
    return r->root->section_id;
  }
  return NULL;
}

/* The headline a node actually shows: the document's **stored** headline when
 * the author set one, otherwise the model's doc comment.
 *
 * The stored value comes first because it is the one a reader sees and the one
 * an author would search for. Consulting only the doc comment made renamed
 * sections unfindable — storing a headline on `DEMO/SUM` would put text there
 * that no query could reach and that never entered the search index built from
 * the projections. Borrowed pointer, NULL when neither exists. */
static const char *headline_of(const SpecQueryEngine *e,
                               const SpecResolution *r) {
  const char *stored = spec_document_headline(e->document, r->path);
  if (is_set(stored)) {
    return stored;
  }
  if (r->field != NULL && is_set(r->field->doc)) {
    return r->field->doc;
  }
  if (r->target_class != NULL && is_set(r->target_class->doc)) {
    return r->target_class->doc;
  }
  if (strcmp(r->kind, SPEC_NODE_KIND_ROOT) == 0 && r->root != NULL &&
      is_set(r->root->description)) {
    return r->root->description;
  }
  return NULL;
}

/* The strings a `text` query searches at `r`: stored values first (content
 * leaf, scalar list item, every form field), then the node's headline.
 *
 * Form fields are walked in the model's **declaration order**, not the
 * document's storage order. The Dart reference iterates the document's own
 * (insertion-ordered) map; this runtime keeps its stores byte-sorted for
 * codec stability, so following the store would reorder the index. Declaration
 * order is what the corpus records and is the only order every port can agree
 * on. Any field held by the document but absent from the model follows,
 * byte-sorted, so nothing stored goes unindexed. */
static void searchable_strings(const SpecQueryEngine *e,
                               const SpecResolution *r, SomStrList *out) {
  som_strlist_init(out);
  const char *path = r->path;
  if (strcmp(r->kind, SPEC_NODE_KIND_CONTENT) == 0 ||
      strcmp(r->kind, SPEC_NODE_KIND_ENUM_VALUE) == 0 ||
      strcmp(r->kind, SPEC_NODE_KIND_SCALAR) == 0 ||
      strcmp(r->kind, SPEC_NODE_KIND_LIST_ITEM_SCALAR) == 0) {
    const char *value = spec_document_content(e->document, path);
    if (value != NULL) {
      som_strlist_push_copy(out, value);
    }
  } else if (strcmp(r->kind, SPEC_NODE_KIND_FORM) == 0) {
    SomStrList stored;
    spec_document_form_field_names(e->document, path, &stored);
    SomStrList seen;
    som_strlist_init(&seen);
    if (r->field != NULL) {
      size_t i;
      for (i = 0; i < r->field->form_fields_len; i++) {
        const char *name = r->field->form_fields[i].name;
        const char *value = spec_document_form_field(e->document, path, name);
        som_strlist_push_copy(&seen, name);
        if (value != NULL) {
          som_strlist_push_copy(out, value);
        }
      }
    }
    size_t i;
    for (i = 0; i < stored.len; i++) {
      if (som_strlist_contains(&seen, stored.items[i])) {
        continue;
      }
      const char *value =
          spec_document_form_field(e->document, path, stored.items[i]);
      if (value != NULL) {
        som_strlist_push_copy(out, value);
      }
    }
    som_strlist_free(&seen);
    som_strlist_free(&stored);
  }
  /* Container nodes (root / complex / section / list / complex list item) carry
   * no direct value. */
  const char *headline = headline_of(e, r);
  if (headline != NULL) {
    som_strlist_push_copy(out, headline);
  }
}

/* ---- structural-closure enumeration --------------------------------------- */

static void walk(const SpecQueryEngine *e, const char *path,
                 const SpecClass *cls, const SomStrList *ancestor_types,
                 SomStrList *out);

/* Copies `types` and appends `extra`. */
static void ancestors_with(const SomStrList *types, const char *extra,
                           SomStrList *out) {
  som_strlist_copy(out, types);
  som_strlist_push_copy(out, extra);
}

static void walk(const SpecQueryEngine *e, const char *path,
                 const SpecClass *cls, const SomStrList *ancestor_types,
                 SomStrList *out) {
  som_strlist_push_copy(out, path); /* the node itself */
  if (cls == NULL) {
    return;
  }
  size_t i;
  for (i = 0; i < cls->fields_len; i++) {
    const SpecField *field = &cls->fields[i];
    char *field_path =
        spec_path_join(path, spec_reflection_field_segment(field));
    if (strcmp(field->kind, SPEC_FIELD_KIND_CONTENT) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_ENUM) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_SCALAR) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_FORM) == 0) {
      som_strlist_push(out, field_path); /* a value leaf */
      continue;
    }
    if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0) {
      som_strlist_push_copy(out, field_path); /* the list container node */
      const SomStrList *items = spec_document_list_items(e->document, field_path);
      size_t j;
      for (j = 0; items != NULL && j < items->len; j++) {
        const char *item_path = items->items[j];
        if (field->element_is_complex && is_set(field->element_type) &&
            !som_strlist_contains(ancestor_types, field->element_type)) {
          SomStrList nested;
          ancestors_with(ancestor_types, field->element_type, &nested);
          walk(e, item_path,
               spec_model_class_named(e->model, field->element_type), &nested,
               out);
          som_strlist_free(&nested);
        } else {
          /* scalar item, or a recursive/unknown element */
          som_strlist_push_copy(out, item_path);
        }
      }
      free(field_path);
      continue;
    }
    /* complex / section */
    if (is_set(field->type) &&
        !som_strlist_contains(ancestor_types, field->type)) {
      SomStrList nested;
      ancestors_with(ancestor_types, field->type, &nested);
      walk(e, field_path, spec_model_class_named(e->model, field->type),
           &nested, out);
      som_strlist_free(&nested);
      free(field_path);
    } else {
      /* recursive/unknown target: a terminal node */
      som_strlist_push(out, field_path);
    }
  }
}

/* Every addressable node of the document in document order: the root, each
 * singular complex/section node on the spine (bounded by cycle detection), each
 * list container, each *existing* list item, and every declared leaf. */
static void enumerate_paths(const SpecQueryEngine *e, SomStrList *out) {
  som_strlist_init(out);
  size_t i;
  for (i = 0; i < e->model->roots_len; i++) {
    const SpecRoot *root = &e->model->roots[i];
    SomStrList ancestors;
    som_strlist_init(&ancestors);
    som_strlist_push_copy(&ancestors, root->type);
    walk(e, spec_reflection_root_segment(root),
         spec_model_class_named(e->model, root->type), &ancestors, out);
    som_strlist_free(&ancestors);
  }
}

/* ---- glob ----------------------------------------------------------------- */

/* Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
 * remaining span first and give characters back until the tail fits.
 *
 * Matched directly rather than compiled to a regex, because two of the nine
 * runtimes have no regex engine and because a wildcard walk is a smaller, more
 * obviously identical thing to transcribe than an escaping rule plus somebody
 * else's matcher. Bytes rather than code units are enough here: `*` and `/` are
 * ASCII and UTF-8 is self-synchronising, so a byte walk and a code-unit walk
 * accept exactly the same (glob, path) pairs. */
static int glob_at(const char *glob, size_t gl, size_t g, const char *path,
                   size_t pl, size_t p) {
  while (g < gl) {
    if ((unsigned char)glob[g] != K_ASTERISK) {
      if (p >= pl || path[p] != glob[g]) {
        return 0;
      }
      g++;
      p++;
      continue;
    }
    int crosses_segments = g + 1 < gl && (unsigned char)glob[g + 1] == K_ASTERISK;
    size_t after_wildcard = g + (crosses_segments ? 2 : 1);
    /* Longest first, so `*` behaves greedily exactly as the regex did. */
    size_t limit = pl;
    if (!crosses_segments) {
      size_t i;
      for (i = p; i < pl; i++) {
        if ((unsigned char)path[i] == K_SLASH) {
          limit = i;
          break;
        }
      }
    }
    size_t take = limit + 1;
    while (take > p) {
      take--;
      if (glob_at(glob, gl, after_wildcard, path, pl, take)) {
        return 1;
      }
    }
    return 0;
  }
  return p == pl;
}

/* Glob match over a whole path: `**` spans `/`, a single `*` stays within one
 * segment, every other character is literal. */
static int glob_matches(const char *glob, const char *path) {
  return glob_at(glob, strlen(glob), 0, path, strlen(path), 0);
}

/* ---- predicates ----------------------------------------------------------- */

/* The model-fixed dimensions (kind / class / id / path / mapsTo / detailedIn). */
static int matches_structural(const SpecQuery *q, const SpecResolution *r) {
  if (q->kinds != NULL && !som_strlist_contains(q->kinds, r->kind)) {
    return 0;
  }
  if (q->class_name != NULL) {
    const char *name = r->target_class == NULL ? NULL : r->target_class->name;
    if (name == NULL || strcmp(name, q->class_name) != 0) {
      return 0;
    }
  }

  const char *section_id = section_id_of(r);
  if (q->section_id_exact != NULL &&
      (section_id == NULL || strcmp(section_id, q->section_id_exact) != 0)) {
    return 0;
  }
  if (q->section_id_prefix != NULL) {
    size_t n = strlen(q->section_id_prefix);
    if (section_id == NULL || strncmp(section_id, q->section_id_prefix, n) != 0) {
      return 0;
    }
  }
  if (q->path_glob != NULL && !glob_matches(q->path_glob, r->path)) {
    return 0;
  }
  if (q->maps_to != NULL) {
    const char *v = r->target_class == NULL ? NULL : r->target_class->maps_to;
    if (!is_set(v) || strcmp(v, q->maps_to) != 0) {
      return 0;
    }
  }
  if (q->detailed_in != NULL) {
    const char *v = r->target_class == NULL ? NULL : r->target_class->detailed_in;
    if (!is_set(v) || strcmp(v, q->detailed_in) != 0) {
      return 0;
    }
  }
  return 1;
}

/* ---- path liveness (cursor stability) ------------------------------------- */

/* Whether `path` still exists in the live document: every `-<seq>` list-item
 * segment must still be present in its parent list. Model-fixed segments (root,
 * complex/section, declared leaves) are always structurally live, so only list
 * items can go stale (via `spec_document_remove_list_item`). */
static int is_live_path(const SpecQueryEngine *e, const char *path) {
  SomStrList segments;
  spec_path_segments(path, &segments);
  char *prefix = som_strdup("");
  int live = 1;
  size_t i;
  for (i = 0; i < segments.len; i++) {
    char *previous = prefix;
    prefix = (i == 0) ? som_strdup(segments.items[i])
                      : spec_path_join(previous, segments.items[i]);
    char *base = NULL;
    long long seq = 0;
    if (spec_split_list_item_segment(segments.items[i], &base, &seq)) {
      char *list_path =
          (i == 0) ? som_strdup(base) : spec_path_join(previous, base);
      SpecResolution res;
      if (spec_reflection_resolve(&e->reflection, list_path, &res)) {
        if (strcmp(res.kind, SPEC_NODE_KIND_LIST) == 0) {
          const SomStrList *items =
              spec_document_list_items(e->document, list_path);
          if (items == NULL || !som_strlist_contains(items, prefix)) {
            live = 0;
          }
        }
        spec_resolution_free(&res);
      }
      free(list_path);
      free(base);
    }
    free(previous);
    if (!live) {
      break;
    }
  }
  free(prefix);
  som_strlist_free(&segments);
  return live;
}

/* ---- live evaluation ------------------------------------------------------ */

/* The value-reading dimensions (text / state), re-evaluated against the live
 * document. Returns 1 and fills `*out` with the built match (snippet/spans), or
 * 0 when the node no longer satisfies the query. Assumes the path was
 * structurally valid when the cursor captured it. */
static int evaluate_live(const SpecQueryEngine *e, const SpecQuery *q,
                         const SomTextPattern *pattern, const char *path,
                         SpecQueryMatch *out) {
  if (!is_live_path(e, path)) {
    return 0;
  }
  SpecResolution r;
  if (!spec_reflection_resolve(&e->reflection, path, &r)) {
    return 0;
  }

  if (q->has_state) {
    int has_value = spec_document_has_values_under(e->document, path);
    int want_value = q->state == SPEC_STATE_NON_EMPTY;
    if ((has_value != 0) != want_value) {
      spec_resolution_free(&r);
      return 0;
    }
  }

  char *snippet = NULL;
  SpecMatchSpanList spans;
  spec_match_span_list_init(&spans);
  if (pattern != NULL) {
    /* Search each candidate string in turn; the first that hits wins, so the
     * snippet is the actual text the pattern matched. */
    SomStrList texts;
    searchable_strings(e, &r, &texts);
    size_t i;
    for (i = 0; i < texts.len; i++) {
      spec_text_pattern_all_matches(pattern, texts.items[i], &spans);
      if (spans.len > 0) {
        snippet = som_strdup(texts.items[i]);
        break;
      }
    }
    som_strlist_free(&texts);
    if (snippet == NULL) {
      spec_match_span_list_free(&spans);
      spec_resolution_free(&r);
      return 0;
    }
  }

  const char *headline = headline_of(e, &r);
  out->path = som_strdup(path);
  out->kind = r.kind;
  out->class_id =
      som_strdup(r.target_class == NULL ? "" : or_empty(r.target_class->name));
  out->headline = som_strdup(or_empty(headline));
  out->snippet = snippet == NULL ? som_strdup("") : snippet;
  out->spans = spans;
  spec_resolution_free(&r);
  return 1;
}

/* ---- engine entry points -------------------------------------------------- */

int spec_query_engine_query(const SpecQueryEngine *e, const SpecQuery *q,
                            SpecQueryCursor *out, SomPatternError *err) {
  SomTextPattern pattern;
  pattern.terms = NULL;
  pattern.terms_len = 0;
  pattern.case_insensitive = 0;
  int has_pattern = 0;
  if (q->text != NULL) {
    if (q->regex) {
      if (!spec_text_pattern_compile(&pattern, q->text, q->case_insensitive,
                                     err)) {
        return 0;
      }
    } else {
      spec_text_pattern_literal(&pattern, q->text, q->case_insensitive);
    }
    has_pattern = 1;
  }

  SomStrList paths;
  enumerate_paths(e, &paths);
  SomStrList candidates;
  som_strlist_init(&candidates);
  size_t i;
  for (i = 0; i < paths.len; i++) {
    SpecResolution r;
    if (!spec_reflection_resolve(&e->reflection, paths.items[i], &r)) {
      continue;
    }
    if (matches_structural(q, &r)) {
      som_strlist_push_copy(&candidates, paths.items[i]);
    }
    spec_resolution_free(&r);
  }
  som_strlist_free(&paths);

  out->engine = e;
  out->query = *q;
  out->pattern = pattern;
  out->has_pattern = has_pattern;
  out->candidate_paths = candidates;
  out->position = 0;
  return 1;
}

void spec_query_cursor_free(SpecQueryCursor *c) {
  if (c->has_pattern) {
    spec_text_pattern_free(&c->pattern);
    c->has_pattern = 0;
  }
  som_strlist_free(&c->candidate_paths);
  c->engine = NULL;
  c->position = 0;
}

int spec_query_cursor_next(SpecQueryCursor *c, SpecQueryMatch *out) {
  while (c->position < c->candidate_paths.len) {
    const char *path = c->candidate_paths.items[c->position++];
    if (evaluate_live(c->engine, &c->query,
                      c->has_pattern ? &c->pattern : NULL, path, out)) {
      return 1;
    }
  }
  return 0;
}

void spec_query_cursor_take(SpecQueryCursor *c, size_t n,
                            SpecQueryMatchList *out) {
  size_t i;
  for (i = 0; i < n; i++) {
    SpecQueryMatch m;
    if (!spec_query_cursor_next(c, &m)) {
      break;
    }
    match_list_push(out, m);
  }
}

void spec_query_cursor_to_list(SpecQueryCursor *c, SpecQueryMatchList *out) {
  SpecQueryMatch m;
  while (spec_query_cursor_next(c, &m)) {
    match_list_push(out, m);
  }
}

size_t spec_query_cursor_count(const SpecQueryCursor *c) {
  size_t remaining = 0;
  size_t i;
  for (i = c->position; i < c->candidate_paths.len; i++) {
    SpecQueryMatch m;
    if (evaluate_live(c->engine, &c->query, c->has_pattern ? &c->pattern : NULL,
                      c->candidate_paths.items[i], &m)) {
      remaining++;
      spec_query_match_free(&m);
    }
  }
  return remaining;
}

/* ---- flat node projection ------------------------------------------------- */

int spec_query_engine_project_node(const SpecQueryEngine *e, const char *path,
                                   SpecNodeProjection *out) {
  SpecResolution r;
  if (!spec_reflection_resolve(&e->reflection, path, &r)) {
    return 0;
  }
  const char *section_id = section_id_of(&r);
  const char *headline = headline_of(e, &r);
  out->path = som_strdup(path);
  out->kind = r.kind;
  out->class_id =
      som_strdup(r.target_class == NULL ? "" : or_empty(r.target_class->name));
  out->section_id = som_strdup(or_empty(section_id));
  out->maps_to = som_strdup(
      r.target_class == NULL ? "" : or_empty(r.target_class->maps_to));
  out->detailed_in = som_strdup(
      r.target_class == NULL ? "" : or_empty(r.target_class->detailed_in));
  out->headline = som_strdup(or_empty(headline));
  searchable_strings(e, &r, &out->searchable_strings);
  out->has_value = spec_document_has_values_under(e->document, path) ? 1 : 0;
  spec_resolution_free(&r);
  return 1;
}

void spec_query_engine_project_nodes(const SpecQueryEngine *e,
                                     SpecNodeProjectionList *out) {
  spec_node_projection_list_init(out);
  SomStrList paths;
  enumerate_paths(e, &paths);
  size_t i;
  for (i = 0; i < paths.len; i++) {
    SpecNodeProjection p;
    if (spec_query_engine_project_node(e, paths.items[i], &p)) {
      projection_list_push(out, p);
    }
  }
  som_strlist_free(&paths);
}
