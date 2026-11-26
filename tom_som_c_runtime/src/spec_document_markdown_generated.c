/* spec_document_markdown_generated — generated parts of a rendition (SOM
 * §11.12): tables the rendition derives completely from the links of a
 * document, written at the start of the section they belong to as a
 * `derived` block and read back as nothing. A port of the Rust runtime's
 * `spec_document_markdown_generated.rs` (itself a port of the Go, Python,
 * JavaScript, TypeScript and Dart runtimes').
 *
 * Internal to the Markdown codec (spec_document_markdown_internal.h). */
#include <stdlib.h>
#include <string.h>

#include "spec_document_markdown_internal.h"
#include "spec_links_validator.h"
#include "spec_place.h"

/* The requirement classes whose elements are the rows of the requirement
 * views: every element `INTR.relatedRequirements` may name. */
static const char *const REQUIREMENT_CLASSES[] = {"FRE", "TERQ", "SECRQ", "ORRQ",
                                                  NULL};
static const char *const DEPENDENCY_ROWS[] = {"RQDEP", NULL};
static const char *const USE_CASE_ROWS[] = {"INEN", NULL};
static const char *const NO_CLASSES[] = {NULL};

/* A column of a generated table: its header, the place its cells read ("":
 * the row's id), whether it says only `yes` / `no`. */
typedef struct {
  const char *header;
  const char *place;
  int covered;
} GenColumn;

/* A generated table: the section ids it opens, its label, the classes of its
 * rows, the classes the row's id is taken from (empty: the row's own), its
 * columns. */
typedef struct {
  const char *const *at;
  const char *label;
  const char *const *rows;
  const char *const *owner;
  const GenColumn *columns;
  size_t columns_len;
} GenTable;

static const char *const AT_TRACE[] = {"RSP-TRAC", "RO-TRAC", NULL};
static const char *const AT_COVERAGE[] = {"REQCOV", NULL};
static const char *const AT_RELATIONSHIPS[] = {"RERE-REQU-LST", NULL};
static const char *const AT_USE_CASES[] = {"USCATR", NULL};

static const GenColumn TRACE_COLUMNS[] = {
    {"Requirement", "", 0},
    {"Use cases", "RT-TRAC.relatedUseCases", 0},
    {"Screens", "RETRAR.relatedScreens", 0},
    {"Data entities", "RETRAR.relatedDataEntities", 0},
    {"Tests", "RETRAR.relatedTestCases", 0},
};
static const GenColumn COVERAGE_COLUMNS[] = {
    {"Requirement", "", 0},
    {"Covered", "RETRAR.relatedTestCases", 1},
    {"By", "RETRAR.relatedTestCases", 0},
};
static const GenColumn RELATIONSHIP_COLUMNS[] = {
    {"Requirement", "", 0},
    {"Dependency", "RQDEP.dependencyType", 0},
    {"Related requirement", "RQDEP-RELA-REF.ref", 0},
};
static const GenColumn USE_CASE_COLUMNS[] = {
    {"Use case", "", 0},
    {"Process", "INTR.relatedProcess", 0},
    {"Requirements", "INTR.relatedRequirements", 0},
    {"Tests", "INTR.relatedTestCases", 0},
};

#define COUNT(a) (sizeof(a) / sizeof((a)[0]))

/* The generated tables (SOM §11.12): the requirement views of
 * DP-part-model-links-5 / -11 (D1–D4) where the links hold a table. */
static const GenTable GENERATED_TABLES[] = {
    {AT_TRACE, "Generated from each requirement's traceability; edit it there",
     REQUIREMENT_CLASSES, NO_CLASSES, TRACE_COLUMNS, COUNT(TRACE_COLUMNS)},
    {AT_COVERAGE, "Generated from each requirement's test cases; edit them there",
     REQUIREMENT_CLASSES, NO_CLASSES, COVERAGE_COLUMNS, COUNT(COVERAGE_COLUMNS)},
    {AT_RELATIONSHIPS,
     "Generated from each requirement's dependencies; edit them there",
     DEPENDENCY_ROWS, REQUIREMENT_CLASSES, RELATIONSHIP_COLUMNS,
     COUNT(RELATIONSHIP_COLUMNS)},
    {AT_USE_CASES, "Generated from each use case's traceability; edit it there",
     USE_CASE_ROWS, NO_CLASSES, USE_CASE_COLUMNS, COUNT(USE_CASE_COLUMNS)},
};

static int in_set(const char *const *set, const char *s) {
  for (size_t i = 0; set[i] != NULL; i++) {
    if (strcmp(set[i], s) == 0) return 1;
  }
  return 0;
}

/* The generated table opening a heading with section id `id`, or NULL. */
static const GenTable *table_at(const char *id) {
  for (size_t i = 0; i < COUNT(GENERATED_TABLES); i++) {
    if (in_set(GENERATED_TABLES[i].at, id)) return &GENERATED_TABLES[i];
  }
  return NULL;
}

static char *cat3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

int spec_mdi_is_generated_place(MdNav *nav, MdCodec *c, const char *path) {
  const SomMetaNode *node = som_meta_tree_by_path(spec_mdi_nav_tree(nav), path);
  if (node == NULL) return 0;
  if (strcmp(spec_mdi_nav_walk(nav, c, path)->heading_path, path) != 0) return 0;
  char *id = spec_mdi_heading_id_of(c, node);
  int yes = table_at(id) != NULL;
  free(id);
  return yes;
}

/* ---- one root's generated parts ----------------------------------------- */

struct MdGen {
  MdNav *nav; /* borrowed */
  int blocks_loaded;
  SomMap blocks; /* heading path -> block lines joined by '\n' */
  int items_loaded;
  SomStrList items;
};

MdGen *spec_mdi_gen_new(MdNav *nav) {
  MdGen *g = calloc(1, sizeof(MdGen));
  g->nav = nav;
  som_map_init(&g->blocks);
  som_strlist_init(&g->items);
  return g;
}

void spec_mdi_gen_free(MdGen *gen) {
  if (gen == NULL) return;
  som_map_free(&gen->blocks);
  som_strlist_free(&gen->items);
  free(gen);
}

static void collect_items(MdGen *g, MdCodec *c, const SomMetaNode *node,
                          const char *path) {
  const SpecDocument *doc = spec_mdi_document(c);
  NodeRelVec eff;
  spec_mdi_effective_children(c, node, &eff);
  for (size_t i = 0; i < eff.len; i++) {
    const SomMetaNode *child = eff.items[i].node;
    char *p = cat3(path, "/", eff.items[i].rel);
    if (!spec_document_has_values_under(doc, p)) {
      free(p);
      continue;
    }
    if (strcmp(child->kind, SOM_META_KIND_LIST) == 0) {
      const SomStrList *items = spec_document_list_items(doc, p);
      for (size_t k = 0; items != NULL && k < items->len; k++) {
        char *item = som_strdup(items->items[k]);
        som_strlist_push_copy(&g->items, item);
        const SomMetaNode *element = child->element_node;
        if (element != NULL && !element->recursive) {
          collect_items(g, c, element, item);
        }
        free(item);
      }
    } else if (strcmp(child->kind, SOM_META_KIND_SECTION) == 0 ||
               strcmp(child->kind, SOM_META_KIND_COMPLEX) == 0) {
      collect_items(g, c, child, p);
    }
    free(p);
  }
  spec_mdi_nrv_free(&eff);
}

/* Every element of the document, in rendition order. */
static const SomStrList *items_of(MdGen *g, MdCodec *c) {
  if (!g->items_loaded) {
    g->items_loaded = 1;
    collect_items(g, c, spec_mdi_nav_tree(g->nav)->root,
                  spec_mdi_nav_root_seg(g->nav));
  }
  return &g->items;
}

/* The section id of the class of the element at `item`, "" when it does not
 * resolve (borrowed from the model). */
static const char *class_id(MdGen *g, const char *item) {
  SpecResolution r;
  if (!spec_reflection_resolve(spec_mdi_nav_refl(g->nav), item, &r)) return "";
  const char *id = r.target_class != NULL && r.target_class->section_id != NULL
                       ? r.target_class->section_id
                       : "";
  spec_resolution_free(&r);
  return id;
}

/* The element a row names: itself, or its nearest owner of the table's owner
 * classes ("": none). Owned. */
static char *row_owner(MdGen *g, const char *item, const GenTable *table) {
  if (table->owner[0] == NULL) return som_strdup(item);
  char *p = som_strdup(item);
  for (;;) {
    char *slash = strrchr(p, '/');
    if (slash == NULL) break;
    *slash = '\0';
    char *list_path = spec_mdi_nav_item_list_path(g->nav, p);
    if (list_path != NULL) {
      free(list_path);
      const char *id = class_id(g, p);
      if (id[0] != '\0' && in_set(table->owner, id)) return p;
    }
  }
  free(p);
  return som_strdup("");
}

/* A link to the element at `item` by its id and anchor. Owned. */
static char *id_cell(MdGen *g, MdCodec *c, const char *item) {
  if (item[0] == '\0') return som_strdup("");
  const MdWalk *w = spec_mdi_nav_walk(g->nav, c, item);
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  som_buf_puts(&b, w->heading_id);
  som_buf_puts(&b, "](#");
  som_buf_puts(&b, w->anchor);
  som_buf_putc(&b, ')');
  return som_buf_take(&b);
}

/* `s` trimmed of surrounding whitespace. Owned. */
static char *trimmed(const char *s) {
  while (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r') s++;
  size_t n = strlen(s);
  while (n > 0 && (s[n - 1] == ' ' || s[n - 1] == '\t' || s[n - 1] == '\n' ||
                   s[n - 1] == '\r')) {
    n--;
  }
  return som_strdup_n(s, n);
}

/* The block of `table` (its lines joined by '\n'), NULL when it has no row.
 * Owned. */
static char *block_of(MdGen *g, MdCodec *c, const GenTable *table) {
  const SpecDocument *doc = spec_mdi_document(c);
  const SpecReflection *refl = spec_mdi_nav_refl(g->nav);
  const SomStrList *items = items_of(g, c);
  SomBuf rows;
  som_buf_init(&rows);
  size_t row_count = 0;
  for (size_t i = 0; i < items->len; i++) {
    const char *item = items->items[i];
    const char *cid = class_id(g, item);
    if (cid[0] == '\0' || !in_set(table->rows, cid)) continue;
    som_buf_putc(&rows, '\n');
    som_buf_puts(&rows, "|");
    for (size_t k = 0; k < table->columns_len; k++) {
      const GenColumn *col = &table->columns[k];
      char *cell;
      if (col->place[0] == '\0') {
        char *owner = row_owner(g, item, table);
        cell = id_cell(g, c, owner);
        free(owner);
      } else {
        SpecPlaceResolution r;
        spec_place_resolution_init(&r);
        int resolved = spec_resolve_place_at(refl, col->place, item, &r);
        const char *fld = resolved ? spec_place_resolution_field(&r) : NULL;
        char *value = NULL;
        if (fld != NULL && fld[0] != '\0') {
          const char *raw = spec_document_form_field(doc, r.path, fld);
          value = trimmed(raw != NULL ? raw : "");
        } else {
          value = som_strdup("");
        }
        if (col->covered) {
          cell = som_strdup(value[0] == '\0' ? "no" : "yes");
        } else if (value[0] == '\0') {
          cell = som_strdup("");
        } else {
          const SomMetaNode *form_node =
              som_meta_tree_by_path(spec_mdi_nav_tree(g->nav), r.path);
          const SomFormFieldMeta *meta =
              form_node != NULL && form_node->form != NULL
                  ? som_form_meta_field_named(form_node->form, fld)
                  : NULL;
          if (meta != NULL) {
            cell = spec_mdi_linked_cell_text(c, meta, value);
          } else {
            SomBuf e;
            som_buf_init(&e);
            for (const char *q = value; *q != '\0'; q++) {
              if (*q == '|') som_buf_putc(&e, '\\');
              som_buf_putc(&e, *q);
            }
            cell = som_buf_take(&e);
          }
        }
        free(value);
        spec_place_resolution_free(&r);
      }
      som_buf_putc(&rows, ' ');
      som_buf_puts(&rows, cell);
      som_buf_puts(&rows, " |");
      free(cell);
    }
    row_count++;
  }
  if (row_count == 0) {
    som_buf_free(&rows);
    return NULL;
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "::: {.derived label=\"");
  som_buf_puts(&b, table->label);
  som_buf_puts(&b, "\"}\n|");
  for (size_t k = 0; k < table->columns_len; k++) {
    som_buf_putc(&b, ' ');
    som_buf_puts(&b, table->columns[k].header);
    som_buf_puts(&b, " |");
  }
  som_buf_puts(&b, "\n|");
  for (size_t k = 0; k < table->columns_len; k++) som_buf_puts(&b, " --- |");
  char *r = som_buf_take(&rows);
  som_buf_puts(&b, r);
  free(r);
  som_buf_puts(&b, "\n:::");
  return som_buf_take(&b);
}

/* The blocks of this document, by heading path: only the places whose table
 * has rows. */
static const SomMap *blocks_of(MdGen *g, MdCodec *c) {
  if (g->blocks_loaded) return &g->blocks;
  g->blocks_loaded = 1;
  const SomMetaTree *tree = spec_mdi_nav_tree(g->nav);
  for (size_t i = 0; i < tree->all_nodes_len; i++) {
    const SomMetaNode *n = tree->all_nodes[i];
    if (!n->has_path || n->path == NULL || n->path[0] == '\0' ||
        spec_mdi_is_transparent_section(c, n) || spec_mdi_is_transparent_value(n)) {
      continue;
    }
    char *id = spec_mdi_heading_id_of(c, n);
    const GenTable *table = table_at(id);
    free(id);
    if (table == NULL) continue;
    char *block = block_of(g, c, table);
    if (block != NULL) {
      som_map_set(&g->blocks, n->path, block);
      free(block);
    }
  }
  return &g->blocks;
}

const char *spec_mdi_gen_block(MdGen *gen, MdCodec *c, const char *path) {
  return som_map_get(blocks_of(gen, c), path);
}

int spec_mdi_gen_forces(MdGen *gen, MdCodec *c, const char *path) {
  const SomMap *blocks = blocks_of(gen, c);
  size_t n = strlen(path);
  for (size_t i = 0; i < blocks->len; i++) {
    const char *p = blocks->entries[i].key;
    if (strncmp(p, path, n) == 0 && (p[n] == '\0' || p[n] == '/')) return 1;
  }
  return 0;
}

/* ---- the derived fence --------------------------------------------------- */

/* The length of the `:::` run opening a `derived` block on `line`
 * (`^ {0,3}:{3,}[ \t]*\{\.derived[\s}]`), 0 when it opens none. */
static size_t derived_fence(const char *line) {
  size_t indent = 0;
  while (line[indent] == ' ') indent++;
  if (indent > 3) return 0;
  const char *rest = line + indent;
  size_t colons = 0;
  while (rest[colons] == ':') colons++;
  if (colons < 3) return 0;
  rest += colons;
  while (*rest == ' ' || *rest == '\t') rest++;
  static const char open[] = "{.derived";
  if (strncmp(rest, open, sizeof(open) - 1) != 0) return 0;
  char ch = rest[sizeof(open) - 1];
  if (ch == '}' || ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' ||
      ch == '\f' || ch == '\v') {
    return colons;
  }
  return 0;
}

int spec_mdi_opens_derived(const char *line) { return derived_fence(line) > 0; }

int spec_mdi_closes_derived(const char *open, const char *line) {
  size_t n = derived_fence(open);
  if (n == 0) return 0;
  size_t indent = 0;
  while (line[indent] == ' ') indent++;
  if (indent > 3) return 0;
  const char *rest = line + indent;
  size_t colons = 0;
  while (rest[colons] == ':') colons++;
  if (colons < n) return 0;
  for (const char *q = rest + colons; *q != '\0'; q++) {
    if (*q != ' ' && *q != '\t') return 0;
  }
  return 1;
}

static int blank(const char *s) {
  for (; *s != '\0'; s++) {
    if (*s != ' ' && *s != '\t' && *s != '\n' && *s != '\r' && *s != '\f' &&
        *s != '\v') {
      return 0;
    }
  }
  return 1;
}

char *spec_mdi_resolve_derived_placeholders(char *markdown) {
  if (strstr(markdown, SPEC_MDI_DERIVED_PLACEHOLDER) == NULL) return markdown;
  SomStrList lines;
  som_strlist_init(&lines);
  const char *p = markdown;
  for (;;) {
    const char *nl = strchr(p, '\n');
    if (nl == NULL) {
      som_strlist_push_copy(&lines, p);
      break;
    }
    som_strlist_push(&lines, som_strdup_n(p, (size_t)(nl - p)));
    p = nl + 1;
  }
  free(markdown);
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  size_t i = 0;
  while (i < lines.len) {
    if (strcmp(lines.items[i], SPEC_MDI_DERIVED_PLACEHOLDER) != 0) {
      if (!first) som_buf_putc(&b, '\n');
      som_buf_puts(&b, lines.items[i]);
      first = 0;
      i++;
      continue;
    }
    size_t k = i + 1;
    while (k < lines.len && blank(lines.items[k])) k++;
    if (k < lines.len && spec_mdi_opens_derived(lines.items[k])) {
      if (!first) som_buf_putc(&b, '\n');
      som_buf_puts(&b, "::: {.derived}\n:::");
      first = 0;
      i++;
    } else {
      i += 2; /* the blank line after the placeholder goes with it */
    }
  }
  som_strlist_free(&lines);
  return som_buf_take(&b);
}
