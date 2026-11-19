/* spec_impact_walk — the impact walk of the `tom_specs` change mode; see
 * include/spec_impact_walk.h. A faithful port of the TypeScript
 * `spec_impact_walk.ts`. */
#include "spec_impact_walk.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "spec_paths.h"
#include "spec_reflection.h"

/* ---- rows ------------------------------------------------------------------ */

const char *spec_impact_row_kind_name(SpecImpactRowKind kind) {
  switch (kind) {
    case SPEC_IMPACT_ROW_ROOT:
      return "root";
    case SPEC_IMPACT_ROW_COMPLEX:
      return "complex";
    case SPEC_IMPACT_ROW_SECTION:
      return "section";
    case SPEC_IMPACT_ROW_LIST:
      return "list";
    case SPEC_IMPACT_ROW_ITEM:
      return "item";
    case SPEC_IMPACT_ROW_TEMPLATE:
      return "template";
  }
  return "";
}

static void row_free(SpecImpactRow *r) {
  free(r->path);
  free(r->chain);
  free(r->class_name);
  som_strlist_free(&r->routing_values);
  free(r->routing_declared_at);
}

static void root_walk_free(SpecImpactRootWalk *w) {
  free(w->type);
  free(w->section_id);
  for (size_t i = 0; i < w->rows_len; i++) {
    row_free(&w->rows[i]);
  }
  free(w->rows);
}

void spec_impact_walk_free(SpecImpactWalk *w) {
  if (w == NULL) {
    return;
  }
  for (size_t i = 0; i < w->roots_len; i++) {
    root_walk_free(&w->roots[i]);
  }
  free(w->roots);
  w->roots = NULL;
  w->roots_len = 0;
}

/* ---- the walker ------------------------------------------------------------ */

typedef struct {
  const SpecModel *model;
  const SpecDocument *doc;
  /* Every stored value's path, once per value (a content leaf, or one per
   * stored form-field value at its form's path). */
  SomStrList value_paths;
  SpecImpactRootWalk *out;
} ImpactWalker;

/* Stored values at `path` or below: a stored path equal to it, or extending
 * it after a `/` or a `-` (the prefix counts of the TS walker). */
static long long values_at(const ImpactWalker *w, const char *path) {
  size_t n = strlen(path);
  long long count = 0;
  for (size_t i = 0; i < w->value_paths.len; i++) {
    const char *p = w->value_paths.items[i];
    if (strncmp(p, path, n) == 0 &&
        (p[n] == '\0' || p[n] == '/' || p[n] == '-')) {
      count++;
    }
  }
  return count;
}

static void walker_init(ImpactWalker *w, const SpecModel *model,
                        const SpecDocument *doc, SpecImpactRootWalk *out) {
  w->model = model;
  w->doc = doc;
  w->out = out;
  som_strlist_init(&w->value_paths);
  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (spec_document_content(doc, paths.items[i]) != NULL) {
      som_strlist_push_copy(&w->value_paths, paths.items[i]);
    }
  }
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList names;
    spec_document_form_field_names(doc, paths.items[i], &names);
    for (size_t k = 0; k < names.len; k++) {
      if (spec_document_form_field(doc, paths.items[i], names.items[k]) !=
          NULL) {
        som_strlist_push_copy(&w->value_paths, paths.items[i]);
      }
    }
    som_strlist_free(&names);
  }
  som_strlist_free(&paths);
}

static void push_row(ImpactWalker *w, SpecImpactRowKind kind, const char *path,
                     const char *chain, const char *class_name,
                     long long depth, int has_items, long long items,
                     const CodeSpecsRouting *routing) {
  SpecImpactRootWalk *o = w->out;
  if (o->rows_len == o->rows_cap) {
    o->rows_cap = o->rows_cap ? o->rows_cap * 2 : 16;
    o->rows = (SpecImpactRow *)realloc(o->rows,
                                       o->rows_cap * sizeof(SpecImpactRow));
  }
  int template_path = strchr(path, '*') != NULL;
  SpecImpactRow *r = &o->rows[o->rows_len++];
  r->path = som_strdup(path);
  r->chain = som_strdup(chain);
  r->kind = kind;
  r->class_name = som_strdup(class_name);
  r->depth = depth;
  r->filled = !template_path && spec_document_has_values_under(w->doc, path);
  r->values = template_path ? 0 : values_at(w, path);
  r->has_items = has_items;
  r->items = items;
  r->routing = routing->verdict;
  som_strlist_copy(&r->routing_values, &routing->values);
  r->routing_declared_at = som_strdup(routing->declared_at);
}

static char *join_chain(const char *chain, const char *segment) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, chain);
  som_buf_puts(&b, " > ");
  som_buf_puts(&b, segment);
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

static void class_node(ImpactWalker *w, SpecImpactRowKind kind,
                       const char *path, const char *chain,
                       const SpecClass *cls, long long depth,
                       SomStrList *ancestors, const CodeSpecsRouting *process);

static void list_node(ImpactWalker *w, const SpecClass *owner,
                      const SpecField *field, const char *path,
                      const char *chain, long long depth,
                      SomStrList *ancestors, const CodeSpecsRouting *process) {
  int template_path = strchr(path, '*') != NULL;
  const SomStrList *stored =
      template_path ? NULL : spec_document_list_items(w->doc, path);
  size_t count = stored != NULL ? stored->len : 0;
  const SpecClass *element =
      field->element_is_complex && field->element_type != NULL
          ? spec_model_class_named(w->model, field->element_type)
          : NULL;

  CodeSpecsRouting own;
  int has_own = 0;
  const CodeSpecsRouting *routing = process;
  if (routing == NULL) {
    if (element != NULL) {
      own = spec_codespecs_class_routing(element, path);
    } else if (!spec_codespecs_field_routing(owner, field, &own)) {
      own = spec_codespecs_class_routing(owner, path);
    }
    has_own = 1;
    routing = &own;
  }
  push_row(w, SPEC_IMPACT_ROW_LIST, path, chain,
           element != NULL ? element->name : "", depth, 1, (long long)count,
           routing);
  if (has_own) {
    spec_codespecs_routing_free(&own);
  }

  if (element == NULL || som_strlist_contains(ancestors, element->name)) {
    return;
  }
  som_strlist_push_copy(ancestors, element->name);
  if (count == 0) {
    char *item_path = spec_path_join(path, "*");
    char *item_chain = join_chain(chain, "*");
    class_node(w, SPEC_IMPACT_ROW_TEMPLATE, item_path, item_chain, element,
               depth + 1, ancestors, process);
    free(item_path);
    free(item_chain);
  } else {
    /* The item paths are copied: nothing here mutates the document, but the
     * recursion then does not depend on that. */
    SomStrList items;
    som_strlist_copy(&items, stored);
    for (size_t i = 0; i < items.len; i++) {
      const char *item_path = items.items[i];
      const char *id = spec_document_item_section_id(w->doc, item_path);
      if (id == NULL) {
        const char *slash = strrchr(item_path, '/');
        id = slash != NULL ? slash + 1 : item_path;
      }
      char *item_chain = join_chain(chain, id);
      class_node(w, SPEC_IMPACT_ROW_ITEM, item_path, item_chain, element,
                 depth + 1, ancestors, process);
      free(item_chain);
    }
    som_strlist_free(&items);
  }
  som_strlist_remove_at(ancestors, ancestors->len - 1);
}

static void class_node(ImpactWalker *w, SpecImpactRowKind kind,
                       const char *path, const char *chain,
                       const SpecClass *cls, long long depth,
                       SomStrList *ancestors, const CodeSpecsRouting *process) {
  CodeSpecsRouting own = spec_codespecs_class_routing(cls, path);
  const CodeSpecsRouting *routing = process != NULL ? process : &own;
  const CodeSpecsRouting *below =
      routing->verdict == CODESPECS_VERDICT_FEEDS_PROCESS ? routing : NULL;
  push_row(w, kind, path, chain, cls->name, depth, 0, 0, routing);

  for (size_t i = 0; i < cls->fields_len; i++) {
    const SpecField *field = &cls->fields[i];
    const char *segment = spec_reflection_field_segment(field);
    char *field_path = spec_path_join(path, segment);
    char *field_chain = join_chain(chain, segment);
    if (strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0) {
      const SpecClass *child = NULL;
      if (field->type != NULL && field->type[0] != '\0' &&
          !som_strlist_contains(ancestors, field->type)) {
        child = spec_model_class_named(w->model, field->type);
      }
      if (child != NULL) {
        som_strlist_push_copy(ancestors, child->name);
        class_node(w,
                   strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0
                       ? SPEC_IMPACT_ROW_COMPLEX
                       : SPEC_IMPACT_ROW_SECTION,
                   field_path, field_chain, child, depth + 1, ancestors,
                   below);
        som_strlist_remove_at(ancestors, ancestors->len - 1);
      }
    } else if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0) {
      list_node(w, cls, field, field_path, field_chain, depth + 1, ancestors,
                below);
    }
    /* any other kind is a value leaf: counted in this row */
    free(field_path);
    free(field_chain);
  }
  spec_codespecs_routing_free(&own);
}

static void walk_root(const SpecModel *model, const SpecRoot *root,
                      const SpecDocument *doc, SpecImpactRootWalk *out) {
  const SpecClass *cls = spec_model_class_named(model, root->type);
  if (cls == NULL) {
    return;
  }
  ImpactWalker w;
  walker_init(&w, model, doc, out);
  const char *segment = spec_reflection_root_segment(root);
  SomStrList ancestors;
  som_strlist_init(&ancestors);
  som_strlist_push_copy(&ancestors, cls->name);
  class_node(&w, SPEC_IMPACT_ROW_ROOT, segment, segment, cls, 0, &ancestors,
             NULL);
  som_strlist_free(&ancestors);
  som_strlist_free(&w.value_paths);
}

int spec_impact_walk(const SpecModel *model, const char *const *types,
                     const SpecDocument *const *documents, size_t documents_len,
                     SpecImpactWalk *out, char **err) {
  out->roots = NULL;
  out->roots_len = 0;
  for (size_t d = 0; d < documents_len; d++) {
    int known = 0;
    for (size_t i = 0; i < model->roots_len; i++) {
      if (strcmp(model->roots[i].type, types[d]) == 0) {
        known = 1;
        break;
      }
    }
    if (!known) {
      if (err != NULL) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "spec_impact_walk: the model has no document root ");
        som_buf_puts(&b, types[d]);
        *err = som_buf_take(&b);
        som_buf_free(&b);
      }
      return 0;
    }
  }
  if (model->roots_len == 0) {
    return 1;
  }
  out->roots = (SpecImpactRootWalk *)calloc(model->roots_len,
                                            sizeof(SpecImpactRootWalk));
  out->roots_len = model->roots_len;
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *root = &model->roots[i];
    const SpecDocument *doc = NULL;
    for (size_t d = 0; d < documents_len; d++) {
      if (strcmp(types[d], root->type) == 0) {
        doc = documents[d];
        break;
      }
    }
    SpecImpactRootWalk *rw = &out->roots[i];
    rw->type = som_strdup(root->type);
    rw->section_id = som_strdup(spec_reflection_root_segment(root));
    rw->present = doc != NULL;
    if (doc != NULL) {
      walk_root(model, root, doc, rw);
    } else {
      SpecDocument empty;
      spec_document_init(&empty);
      walk_root(model, root, &empty, rw);
      spec_document_free(&empty);
    }
  }
  return 1;
}

/* ---- JSON ------------------------------------------------------------------ */

static void json_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s);
  som_buf_puts(b, q);
  free(q);
}

static void json_strlist(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) {
      som_buf_putc(b, ',');
    }
    json_str(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

static void json_bool(SomBuf *b, int v) { som_buf_puts(b, v ? "true" : "false"); }

char *spec_impact_walk_to_json(const SpecImpactWalk *w) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < w->roots_len; i++) {
    const SpecImpactRootWalk *root = &w->roots[i];
    if (i > 0) {
      som_buf_putc(&b, ',');
    }
    som_buf_puts(&b, "{\"type\":");
    json_str(&b, root->type);
    som_buf_puts(&b, ",\"sectionId\":");
    json_str(&b, root->section_id);
    som_buf_puts(&b, ",\"present\":");
    json_bool(&b, root->present);
    som_buf_puts(&b, ",\"rows\":[");
    for (size_t k = 0; k < root->rows_len; k++) {
      const SpecImpactRow *r = &root->rows[k];
      if (k > 0) {
        som_buf_putc(&b, ',');
      }
      som_buf_puts(&b, "{\"path\":");
      json_str(&b, r->path);
      som_buf_puts(&b, ",\"chain\":");
      json_str(&b, r->chain);
      som_buf_puts(&b, ",\"kind\":");
      json_str(&b, spec_impact_row_kind_name(r->kind));
      som_buf_puts(&b, ",\"className\":");
      json_str(&b, r->class_name);
      som_buf_puts(&b, ",\"depth\":");
      som_buf_puti(&b, r->depth);
      som_buf_puts(&b, ",\"filled\":");
      json_bool(&b, r->filled);
      som_buf_puts(&b, ",\"values\":");
      som_buf_puti(&b, r->values);
      som_buf_puts(&b, ",\"items\":");
      if (r->has_items) {
        som_buf_puti(&b, r->items);
      } else {
        som_buf_puts(&b, "null");
      }
      som_buf_puts(&b, ",\"routing\":");
      json_str(&b, spec_codespecs_verdict_name(r->routing));
      som_buf_puts(&b, ",\"routingValues\":");
      json_strlist(&b, &r->routing_values);
      som_buf_puts(&b, ",\"routingDeclaredAt\":");
      json_str(&b, r->routing_declared_at);
      som_buf_putc(&b, '}');
    }
    som_buf_puts(&b, "]}");
  }
  som_buf_putc(&b, ']');
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

/* ---- folders --------------------------------------------------------------- */

void spec_impact_folder_list_init(SpecImpactFolderList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_impact_folder_list_push(SpecImpactFolderList *l, const char *path,
                                  int present) {
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 4;
    l->items = (SpecImpactFolder *)realloc(l->items,
                                           l->cap * sizeof(SpecImpactFolder));
  }
  l->items[l->len].path = som_strdup(path);
  l->items[l->len].present = present;
  l->len++;
}

void spec_impact_folder_list_free(SpecImpactFolderList *l) {
  if (l == NULL) {
    return;
  }
  for (size_t i = 0; i < l->len; i++) {
    free(l->items[i].path);
  }
  free(l->items);
  spec_impact_folder_list_init(l);
}

static void folder_list_copy(SpecImpactFolderList *dst,
                             const SpecImpactFolderList *src) {
  spec_impact_folder_list_init(dst);
  for (size_t i = 0; i < src->len; i++) {
    spec_impact_folder_list_push(dst, src->items[i].path,
                                 src->items[i].present);
  }
}

static int any_present(const SpecImpactFolderList *l) {
  for (size_t i = 0; i < l->len; i++) {
    if (l->items[i].present) {
      return 1;
    }
  }
  return 0;
}

/* ---- the listing's patterns, matched by hand ------------------------------ */

/* A listing entry as `/`-separated and without a leading `./`. Owned. */
static char *normalise_entry(const char *p) {
  char *s = som_strdup(p);
  for (char *c = s; *c != '\0'; c++) {
    if (*c == '\\') {
      *c = '/';
    }
  }
  if (s[0] == '.' && s[1] == '/') {
    memmove(s, s + 2, strlen(s + 2) + 1);
  }
  return s;
}

static void normalise_listing(const SomStrList *listing, SomStrList *out) {
  som_strlist_init(out);
  if (listing == NULL) {
    return;
  }
  for (size_t i = 0; i < listing->len; i++) {
    som_strlist_push(out, normalise_entry(listing->items[i]));
  }
}

static int starts_with(const char *s, const char *prefix) {
  return strncmp(s, prefix, strlen(prefix)) == 0;
}

/* Whether `s` matches `<head>[^/]{min,}<tail>` in full: no `/` in it, it
 * starts with `head` and ends with `tail`, with at least `min_middle` bytes
 * between them. */
static int segment_matches(const char *s, const char *head, size_t min_middle,
                           const char *tail) {
  if (strchr(s, '/') != NULL) {
    return 0;
  }
  size_t n = strlen(s), h = strlen(head), t = strlen(tail);
  if (n < h + min_middle + t) {
    return 0;
  }
  return strncmp(s, head, h) == 0 && strcmp(s + n - t, tail) == 0;
}

/* Whether `f` matches `^<folder head>[^/]*\/<file pattern>$`: one `/`, a
 * first segment starting with `folder_head`, a second matching
 * `segment_matches(file_head, min_middle, file_tail)`. */
static int folder_file_matches(const char *f, const char *folder_head,
                               const char *file_head, size_t min_middle,
                               const char *file_tail) {
  const char *slash = strchr(f, '/');
  if (slash == NULL || !starts_with(f, folder_head) ||
      (size_t)(slash - f) < strlen(folder_head)) {
    return 0;
  }
  return segment_matches(slash + 1, file_head, min_middle, file_tail);
}

/* `^<prefix><segment pattern>$` with a fixed folder prefix. */
static int in_folder_matches(const char *f, const char *prefix,
                             const char *head, size_t min_middle,
                             const char *tail) {
  return starts_with(f, prefix) &&
         segment_matches(f + strlen(prefix), head, min_middle, tail);
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void sort_strlist(SomStrList *l) {
  if (l->len > 1) {
    qsort(l->items, l->len, sizeof(char *), cmp_str);
  }
}

/* ---- the level ------------------------------------------------------------- */

void spec_impact_level_free(SpecImpactLevel *l) {
  if (l == NULL) {
    return;
  }
  for (size_t i = 0; i < l->documents_len; i++) {
    free(l->documents[i].type);
    free(l->documents[i].section_id);
  }
  free(l->documents);
  som_strlist_free(&l->gates);
  spec_impact_folder_list_free(&l->tests);
  spec_impact_folder_list_free(&l->code);
  memset(l, 0, sizeof(*l));
}

static const SpecRoot *root_of_type(const SpecModel *model, const char *type) {
  for (size_t i = 0; i < model->roots_len; i++) {
    if (strcmp(model->roots[i].type, type) == 0) {
      return &model->roots[i];
    }
  }
  return NULL;
}

static int is_sbp(const SpecRoot *root) {
  return root->section_id != NULL && strcmp(root->section_id, "SBP") == 0;
}

void spec_impact_level(const SpecModel *model, const SpecImpactWalk *walk,
                       const SomStrList *listing,
                       const SpecImpactFolderList *tests,
                       const SpecImpactFolderList *code, SpecImpactLevel *out) {
  memset(out, 0, sizeof(*out));
  SomStrList files;
  normalise_listing(listing, &files);

  out->documents_len = walk->roots_len;
  out->documents = walk->roots_len > 0
                       ? (SpecImpactLevelDocument *)calloc(
                             walk->roots_len, sizeof(SpecImpactLevelDocument))
                       : NULL;
  for (size_t i = 0; i < walk->roots_len; i++) {
    out->documents[i].type = som_strdup(walk->roots[i].type);
    out->documents[i].section_id = som_strdup(walk->roots[i].section_id);
    out->documents[i].present = walk->roots[i].present;
  }

  som_strlist_init(&out->gates);
  for (size_t i = 0; i < files.len; i++) {
    const char *f = files.items[i];
    if (folder_file_matches(f, "phase1_", "", 1, ".md")) {
      out->project_idea = 1;
    }
    if (in_folder_matches(f, "generated-doc/codespecs_extracts/", "CE-", 1,
                          ".extract.yaml")) {
      out->extracts++;
    }
    if (strcmp(f, "generated-doc/codespecs_extracts/gate.verdicts.yaml") == 0) {
      out->gate_record = 1;
    }
    if (in_folder_matches(f, "irspecs/", "", 1, ".ir.yaml")) {
      out->ir++;
    }
    if (in_folder_matches(f, "gates/", "G", 0, ".checklist.yaml") ||
        in_folder_matches(f, "quality/evidence/gates/", "", 1, ".md")) {
      som_strlist_push_copy(&out->gates, f);
    }
  }
  sort_strlist(&out->gates);
  som_strlist_free(&files);

  out->has_tests = tests != NULL;
  if (tests != NULL) {
    folder_list_copy(&out->tests, tests);
  } else {
    spec_impact_folder_list_init(&out->tests);
  }
  out->has_code = code != NULL;
  if (code != NULL) {
    folder_list_copy(&out->code, code);
  } else {
    spec_impact_folder_list_init(&out->code);
  }

  int sbp_present = 0, other_present = 0;
  for (size_t i = 0; i < walk->roots_len; i++) {
    const SpecImpactRootWalk *w = &walk->roots[i];
    const SpecRoot *root = root_of_type(model, w->type);
    if (!w->present || root == NULL) {
      continue;
    }
    if (is_sbp(root)) {
      sbp_present = 1;
    } else if (!spec_model_is_generation_input(model, root)) {
      other_present = 1;
    }
  }
  int reached[7] = {0};
  reached[1] = out->project_idea;
  reached[2] = sbp_present;
  reached[3] = other_present;
  reached[4] = out->extracts > 0 || out->ir > 0;
  reached[5] = tests != NULL && any_present(tests);
  reached[6] = code != NULL && any_present(code);
  for (int p = 1; p <= 6; p++) {
    if (reached[p]) {
      out->phases_reached[out->phases_reached_len++] = p;
    } else {
      out->phases_left_out[out->phases_left_out_len++] = p;
    }
  }
}

static void json_folders(SomBuf *b, int given, const SpecImpactFolderList *l) {
  if (!given) {
    som_buf_puts(b, "null");
    return;
  }
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) {
      som_buf_putc(b, ',');
    }
    som_buf_puts(b, "{\"path\":");
    json_str(b, l->items[i].path);
    som_buf_puts(b, ",\"present\":");
    json_bool(b, l->items[i].present);
    som_buf_putc(b, '}');
  }
  som_buf_putc(b, ']');
}

static void json_ints(SomBuf *b, const int *values, size_t len) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < len; i++) {
    if (i > 0) {
      som_buf_putc(b, ',');
    }
    som_buf_puti(b, values[i]);
  }
  som_buf_putc(b, ']');
}

char *spec_impact_level_to_json(const SpecImpactLevel *l) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"documents\":[");
  for (size_t i = 0; i < l->documents_len; i++) {
    if (i > 0) {
      som_buf_putc(&b, ',');
    }
    som_buf_puts(&b, "{\"type\":");
    json_str(&b, l->documents[i].type);
    som_buf_puts(&b, ",\"sectionId\":");
    json_str(&b, l->documents[i].section_id);
    som_buf_puts(&b, ",\"present\":");
    json_bool(&b, l->documents[i].present);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"projectIdea\":");
  json_bool(&b, l->project_idea);
  som_buf_puts(&b, ",\"extracts\":");
  som_buf_puti(&b, l->extracts);
  som_buf_puts(&b, ",\"gateRecord\":");
  json_bool(&b, l->gate_record);
  som_buf_puts(&b, ",\"ir\":");
  som_buf_puti(&b, l->ir);
  som_buf_puts(&b, ",\"gates\":");
  json_strlist(&b, &l->gates);
  som_buf_puts(&b, ",\"tests\":");
  json_folders(&b, l->has_tests, &l->tests);
  som_buf_puts(&b, ",\"code\":");
  json_folders(&b, l->has_code, &l->code);
  som_buf_puts(&b, ",\"phasesReached\":");
  json_ints(&b, l->phases_reached, l->phases_reached_len);
  som_buf_puts(&b, ",\"phasesLeftOut\":");
  json_ints(&b, l->phases_left_out, l->phases_left_out_len);
  som_buf_putc(&b, '}');
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

void spec_impact_document_files(const SomStrList *listing, SomStrList *out) {
  SomStrList files;
  normalise_listing(listing, &files);
  som_strlist_init(out);
  for (size_t i = 0; i < files.len; i++) {
    if (folder_file_matches(files.items[i], "phase", "", 1,
                            ".tomspecs.yaml")) {
      som_strlist_push_copy(out, files.items[i]);
    }
  }
  som_strlist_free(&files);
  sort_strlist(out);
}

/* ---- the Markdown table ---------------------------------------------------- */

/* `text` with every `|` escaped as `\|`. */
static void cell(SomBuf *b, const char *text) {
  for (const char *c = text; *c != '\0'; c++) {
    if (*c == '|') {
      som_buf_putc(b, '\\');
    }
    som_buf_putc(b, *c);
  }
}

static const char *yes_no(int v) { return v ? "yes" : "no"; }

static void md_folders(SomBuf *b, int given, const SpecImpactFolderList *l) {
  if (!given) {
    som_buf_puts(b, "not given");
    return;
  }
  if (l->len == 0) {
    som_buf_puts(b, "none");
    return;
  }
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    som_buf_putc(b, '`');
    som_buf_puts(b, l->items[i].path);
    som_buf_puts(b, "` (");
    som_buf_puts(b, l->items[i].present ? "present" : "absent");
    som_buf_putc(b, ')');
  }
}

static void md_section_ids(SomBuf *b, const SpecImpactLevel *l, int present) {
  int any = 0;
  for (size_t i = 0; i < l->documents_len; i++) {
    if ((l->documents[i].present != 0) != (present != 0)) {
      continue;
    }
    if (any) {
      som_buf_puts(b, ", ");
    }
    som_buf_puts(b, l->documents[i].section_id);
    any = 1;
  }
  if (!any) {
    som_buf_puts(b, "none");
  }
}

static void md_phases(SomBuf *b, const int *values, size_t len) {
  if (len == 0) {
    som_buf_puts(b, "none");
    return;
  }
  for (size_t i = 0; i < len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    som_buf_puti(b, values[i]);
  }
}

char *spec_impact_walk_markdown(const SpecImpactWalk *walk,
                                const SpecImpactLevel *level) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "# Impact walk\n\n");
  som_buf_puts(
      &b,
      "Every section of every document root, filled or not: the section-id "
      "chain, the model class, whether it holds values, and its CodeSpecs "
      "routing. A list counts its items; an empty list of sections shows what "
      "a new item holds at `<list>/*`.\n\n");
  for (size_t i = 0; i < walk->roots_len; i++) {
    const SpecImpactRootWalk *root = &walk->roots[i];
    long long filled = 0;
    for (size_t k = 0; k < root->rows_len; k++) {
      if (root->rows[k].filled) {
        filled++;
      }
    }
    som_buf_puts(&b, "## ");
    som_buf_puts(&b, root->section_id);
    som_buf_puts(&b, " \xE2\x80\x94 ");
    som_buf_puts(&b, root->type);
    if (!root->present) {
      som_buf_puts(&b, " (absent)");
    }
    som_buf_puts(&b, "\n\n");
    som_buf_puti(&b, (long long)root->rows_len);
    som_buf_puts(&b, " rows, ");
    som_buf_puti(&b, filled);
    som_buf_puts(&b, " holding values.\n\n");
    som_buf_puts(&b,
                 "| Section-id chain | Path | Kind | Class | Values | Items | "
                 "Routing |\n| --- | --- | --- | --- | --- | --- | --- |\n");
    for (size_t k = 0; k < root->rows_len; k++) {
      const SpecImpactRow *r = &root->rows[k];
      som_buf_puts(&b, "| ");
      cell(&b, r->chain);
      som_buf_puts(&b, " | `");
      cell(&b, r->path);
      som_buf_puts(&b, "` | ");
      som_buf_puts(&b, spec_impact_row_kind_name(r->kind));
      som_buf_puts(&b, " | ");
      cell(&b, r->class_name);
      som_buf_puts(&b, " | ");
      if (r->filled) {
        som_buf_puti(&b, r->values);
      } else {
        som_buf_puts(&b, "\xE2\x80\x94");
      }
      som_buf_puts(&b, " | ");
      if (r->has_items) {
        som_buf_puti(&b, r->items);
      }
      som_buf_puts(&b, " | ");
      SomBuf routing;
      som_buf_init(&routing);
      som_buf_puts(&routing, spec_codespecs_verdict_name(r->routing));
      if (r->routing_values.len > 0) {
        som_buf_puts(&routing, ": ");
        char *joined = som_strlist_join(&r->routing_values, ", ");
        som_buf_puts(&routing, joined);
        free(joined);
      }
      char *routing_text = som_buf_take(&routing);
      som_buf_free(&routing);
      cell(&b, routing_text);
      free(routing_text);
      som_buf_puts(&b, " |\n");
    }
    som_buf_putc(&b, '\n');
  }
  if (level != NULL) {
    som_buf_puts(&b, "## Level\n\n");
    som_buf_puts(&b, "- Documents present: ");
    md_section_ids(&b, level, 1);
    som_buf_puts(&b, "\n- Documents absent: ");
    md_section_ids(&b, level, 0);
    som_buf_puts(&b, "\n- Project Idea: ");
    som_buf_puts(&b, yes_no(level->project_idea));
    som_buf_puts(&b, "\n- CodeSpecs extracts: ");
    som_buf_puti(&b, level->extracts);
    som_buf_puts(&b, "; gate record: ");
    som_buf_puts(&b, yes_no(level->gate_record));
    som_buf_puts(&b, "\n- IR Specs: ");
    som_buf_puti(&b, level->ir);
    som_buf_puts(&b, "\n- Gates: ");
    if (level->gates.len == 0) {
      som_buf_puts(&b, "none");
    }
    for (size_t i = 0; i < level->gates.len; i++) {
      if (i > 0) {
        som_buf_puts(&b, ", ");
      }
      som_buf_putc(&b, '`');
      som_buf_puts(&b, level->gates.items[i]);
      som_buf_putc(&b, '`');
    }
    som_buf_puts(&b, "\n- Tests: ");
    md_folders(&b, level->has_tests, &level->tests);
    som_buf_puts(&b, "\n- Code: ");
    md_folders(&b, level->has_code, &level->code);
    som_buf_puts(&b, "\n- Phases reached: ");
    md_phases(&b, level->phases_reached, level->phases_reached_len);
    som_buf_puts(&b, "; left out by a change: ");
    md_phases(&b, level->phases_left_out, level->phases_left_out_len);
    som_buf_puts(&b,
                 " (Phases 7\xE2\x80\x93"
                 "8 are not visible on disk)\n\n");
  }
  /* The TS joins its lines with "\n": the output ends without the final
   * newline of the last (empty) line. */
  if (b.len > 0 && b.data[b.len - 1] == '\n') {
    b.len--;
    b.data[b.len] = '\0';
  }
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}
