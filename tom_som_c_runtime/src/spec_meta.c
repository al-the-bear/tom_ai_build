/* spec_meta — implementation. See spec_meta.h; a faithful port of the Go
 * `spec_meta.go`. */
#include "spec_meta.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"

/* ---- helpers ------------------------------------------------------------- */

static void set_err(char **err, char *owned) {
  if (err != NULL) {
    *err = owned;
  } else {
    free(owned);
  }
}

static char *concat3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

/* ---- SomFormMeta --------------------------------------------------------- */

const SomFormFieldMeta *som_form_meta_field_named(const SomFormMeta *f,
                                                  const char *name) {
  if (f == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < f->fields_len; i++) {
    if (strcmp(f->fields[i].name, name) == 0) {
      return &f->fields[i];
    }
  }
  return NULL;
}

/* ---- SomMetaNode --------------------------------------------------------- */

SomMetaNode *som_meta_node_new(void) {
  SomMetaNode *n = calloc(1, sizeof(SomMetaNode));
  n->class_name = som_strdup("");
  n->member_name = som_strdup("");
  n->section_id = som_strdup("");
  n->section_id_pattern = som_strdup("");
  n->kind = SOM_META_KIND_SCALAR;
  n->type_name = som_strdup("");
  n->content_help = som_strdup("");
  n->comment = som_strdup("");
  n->doc_comment = som_strdup("");
  n->class_doc_comment = som_strdup("");
  n->maps_to = som_strdup("");
  n->detailed_in = som_strdup("");
  n->path = som_strdup("");
  return n;
}

static void free_node_contents(SomMetaNode *n) {
  free(n->class_name);
  free(n->member_name);
  free(n->section_id);
  free(n->section_id_pattern);
  free(n->type_name);
  free(n->content_help);
  free(n->comment);
  free(n->doc_comment);
  free(n->class_doc_comment);
  free(n->maps_to);
  free(n->detailed_in);
  free(n->path);
  if (n->content_type != NULL) {
    free(n->content_type->type);
    free(n->content_type->description);
    free(n->content_type);
  }
  if (n->form != NULL) {
    for (size_t i = 0; i < n->form->fields_len; i++) {
      SomFormFieldMeta *f = &n->form->fields[i];
      free(f->name);
      free(f->type_name);
      free(f->description);
      free(f->hint);
    }
    free(n->form->fields);
    free(n->form);
  }
  if (n->document != NULL) {
    free(n->document->name);
    free(n->document->description);
    som_strlist_free(&n->document->based_on);
    free(n->document);
  }
  for (size_t i = 0; i < n->second_level_ids_len; i++) {
    free(n->second_level_ids[i].document_class);
    free(n->second_level_ids[i].id);
  }
  free(n->second_level_ids);
  for (size_t i = 0; i < n->extra_len; i++) {
    free(n->extra[i].annotation);
  }
  free(n->extra);
  free(n->children);
  free(n);
}

void som_meta_node_free(SomMetaNode *n) {
  if (n == NULL) {
    return;
  }
  for (size_t i = 0; i < n->children_len; i++) {
    som_meta_node_free(n->children[i]);
  }
  som_meta_node_free(n->element_node);
  free_node_contents(n);
}

void som_meta_node_add_child(SomMetaNode *n, SomMetaNode *child) {
  n->children = realloc(n->children, (n->children_len + 1) * sizeof(SomMetaNode *));
  n->children[n->children_len++] = child;
}

char *som_meta_node_debug_name(const SomMetaNode *n) {
  if (n->member_name[0] == '\0') {
    return som_strdup(n->class_name);
  }
  return concat3(n->class_name, ".", n->member_name);
}

SomMetaTree *som_meta_node_tree(const SomMetaNode *n, char **err) {
  if (n->tree == NULL) {
    char *name = som_meta_node_debug_name(n);
    char *msg =
        concat3("SomMetaNode(", name, ") is not attached to a SomMetaTree");
    free(name);
    set_err(err, msg);
    return NULL;
  }
  return n->tree;
}

int som_meta_node_parent(const SomMetaNode *n, SomMetaNode **out, char **err) {
  if (som_meta_node_tree(n, err) == NULL) {
    return 0;
  }
  *out = n->parent;
  return 1;
}

int som_meta_node_path(const SomMetaNode *n, const char **out, char **err) {
  if (som_meta_node_tree(n, err) == NULL) {
    return 0;
  }
  *out = n->path;
  return 1;
}

const char *som_meta_node_segment(const SomMetaNode *n) {
  if (n->section_id[0] != '\0') {
    return n->section_id;
  }
  if (n->member_name[0] != '\0') {
    return n->member_name;
  }
  return n->class_name;
}

char *som_meta_node_item_path(const SomMetaNode *n, long long seq, char **err) {
  if (strcmp(n->kind, SOM_META_KIND_LIST) != 0) {
    char *name = som_meta_node_debug_name(n);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "itemPath() requires a list node, ");
    som_buf_puts(&b, name);
    som_buf_puts(&b, " is ");
    som_buf_puts(&b, n->kind);
    free(name);
    set_err(err, som_buf_take(&b));
    return NULL;
  }
  const char *path = NULL;
  if (!som_meta_node_path(n, &path, err)) {
    return NULL;
  }
  if (!n->has_path) {
    char *name = som_meta_node_debug_name(n);
    char *msg = concat3(
        "list ", name, " sits inside a list element subtree and has no static path");
    free(name);
    set_err(err, msg);
    return NULL;
  }
  return spec_list_item_path(path, seq);
}

SomMetaNode *som_meta_node_child_by_member(const SomMetaNode *n,
                                           const char *name) {
  for (size_t i = 0; i < n->children_len; i++) {
    if (strcmp(n->children[i]->member_name, name) == 0) {
      return n->children[i];
    }
  }
  return NULL;
}

SomMetaNode *som_meta_node_child_by_segment(const SomMetaNode *n,
                                            const char *seg) {
  for (size_t i = 0; i < n->children_len; i++) {
    if (strcmp(som_meta_node_segment(n->children[i]), seg) == 0) {
      return n->children[i];
    }
  }
  return NULL;
}

/* ---- section-id pattern matching ----------------------------------------- */

/* Recursive backtracking matcher for `^p0[0-9]+p1[0-9]+…pn$` where the p_i are
 * the pattern split on "xxx" (mirroring Go's regexp construction). */
static int pattern_match_from(const char *pat, const char *id) {
  const char *x = strstr(pat, "xxx");
  if (x == NULL) {
    return strcmp(pat, id) == 0;
  }
  size_t prefix_len = (size_t)(x - pat);
  if (strncmp(pat, id, prefix_len) != 0 || strlen(id) < prefix_len) {
    return 0;
  }
  const char *rest_pat = x + 3;
  const char *digits = id + prefix_len;
  size_t run = 0;
  while (isdigit((unsigned char)digits[run])) {
    run++;
  }
  if (run == 0) {
    return 0;
  }
  for (size_t k = 1; k <= run; k++) {
    if (pattern_match_from(rest_pat, digits + k)) {
      return 1;
    }
  }
  return 0;
}

int som_matches_section_id_pattern(const char *pattern, const char *id) {
  return pattern_match_from(pattern, id);
}

/* ---- SomMetaTree --------------------------------------------------------- */

static void tree_track(SomMetaTree *t, SomMetaNode *node) {
  if (t->all_nodes_len == t->all_nodes_cap) {
    t->all_nodes_cap = t->all_nodes_cap == 0 ? 16 : t->all_nodes_cap * 2;
    t->all_nodes = realloc(t->all_nodes, t->all_nodes_cap * sizeof(SomMetaNode *));
  }
  t->all_nodes[t->all_nodes_len++] = node;
}

static int tree_wire(SomMetaTree *t, SomMetaNode *node, SomMetaNode *parent,
                     char *path /* owned */, int has_path, char **err) {
  if (node->tree != NULL) {
    char *name = som_meta_node_debug_name(node);
    char *msg = concat3("SomMetaNode(", name,
                        ") is already attached to a SomMetaTree; nodes belong "
                        "to exactly one tree");
    free(name);
    set_err(err, msg);
    free(path);
    return 0;
  }
  node->tree = t;
  node->parent = parent;
  free(node->path);
  node->path = path;
  node->has_path = has_path;
  tree_track(t, node);
  for (size_t i = 0; i < node->children_len; i++) {
    SomMetaNode *child = node->children[i];
    char *child_path = has_path
                           ? spec_path_join(node->path, som_meta_node_segment(child))
                           : som_strdup("");
    if (!tree_wire(t, child, node, child_path, has_path, err)) {
      return 0;
    }
  }
  if (node->element_node != NULL) {
    /* Item positions are dynamic (`<listPath>-<seq>`), so the element subtree
     * carries no static paths. */
    if (!tree_wire(t, node->element_node, node, som_strdup(""), 0, err)) {
      return 0;
    }
  }
  return 1;
}

/* Undoes the partial wiring of a failed som_meta_tree_new: detaches every node
 * this tree attached, so ownership can safely return to the caller. */
static void tree_unwind(SomMetaTree *t) {
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    SomMetaNode *n = t->all_nodes[i];
    if (n->tree == t) {
      n->tree = NULL;
      n->parent = NULL;
      n->has_path = 0;
    }
  }
}

SomMetaTree *som_meta_tree_new(SomMetaNode *root, char **err) {
  if (root->document == NULL) {
    char *name = som_meta_node_debug_name(root);
    char *msg = concat3(
        "the tree root must carry @Document metadata (SomMetaNode.document): ",
        name, "");
    free(name);
    set_err(err, msg);
    return NULL;
  }
  SomMetaTree *t = calloc(1, sizeof(SomMetaTree));
  t->root = root;
  if (!tree_wire(t, root, NULL, som_strdup(som_meta_node_segment(root)), 1,
                 err)) {
    tree_unwind(t);
    free(t->all_nodes);
    free(t);
    return NULL;
  }
  return t;
}

void som_meta_tree_free(SomMetaTree *t) {
  if (t == NULL) {
    return;
  }
  /* all_nodes holds every node exactly once — free flat (no recursion needed,
   * but the recursive free is fine since children are owned by parents; use
   * the flat list to avoid double-free bookkeeping). */
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    free_node_contents(t->all_nodes[i]);
  }
  free(t->all_nodes);
  free(t);
}

SomMetaNode **som_meta_tree_all_by_id(const SomMetaTree *t,
                                      const char *section_id, size_t *len) {
  size_t count = 0;
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    if (strcmp(t->all_nodes[i]->section_id, section_id) == 0) {
      count++;
    }
  }
  *len = count;
  if (count == 0) {
    return NULL;
  }
  SomMetaNode **out = malloc(count * sizeof(SomMetaNode *));
  size_t j = 0;
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    if (strcmp(t->all_nodes[i]->section_id, section_id) == 0) {
      out[j++] = t->all_nodes[i];
    }
  }
  return out;
}

SomMetaNode *som_meta_tree_by_id(const SomMetaTree *t, const char *section_id) {
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    if (strcmp(t->all_nodes[i]->section_id, section_id) == 0) {
      return t->all_nodes[i];
    }
  }
  for (size_t i = 0; i < t->all_nodes_len; i++) {
    SomMetaNode *node = t->all_nodes[i];
    if (node->section_id_pattern[0] != '\0' &&
        som_matches_section_id_pattern(node->section_id_pattern, section_id)) {
      if (node->element_node != NULL) {
        return node->element_node;
      }
      return node;
    }
  }
  return NULL;
}

SomMetaNode *som_meta_tree_by_path(const SomMetaTree *t, const char *path) {
  SomStrList segs;
  som_strlist_init(&segs);
  spec_path_segments(path, &segs);
  if (segs.len == 0 ||
      strcmp(segs.items[0], som_meta_node_segment(t->root)) != 0) {
    som_strlist_free(&segs);
    return NULL;
  }

  SomMetaNode *node = t->root;
  for (size_t i = 1; i < segs.len; i++) {
    const char *seg = segs.items[i];
    int last = i == segs.len - 1;

    /* Prefer an exact segment match; only then try a list-item suffix, so a
     * hyphenated @SectionId is never mis-read as an item. */
    SomMetaNode *child = som_meta_node_child_by_segment(node, seg);
    if (child != NULL) {
      if (strcmp(child->kind, SOM_META_KIND_LIST) == 0 && !last) {
        som_strlist_free(&segs);
        return NULL; /* a list path needs a `-<seq>` item suffix */
      }
      if (child->recursive && !last) {
        som_strlist_free(&segs);
        return NULL; /* chains terminate at recursive re-entries */
      }
      node = child;
      continue;
    }

    char *base = NULL;
    long long seq = 0;
    if (!spec_split_list_item_segment(seg, &base, &seq)) {
      som_strlist_free(&segs);
      return NULL;
    }
    SomMetaNode *list_node = som_meta_node_child_by_segment(node, base);
    free(base);
    if (list_node == NULL || strcmp(list_node->kind, SOM_META_KIND_LIST) != 0) {
      som_strlist_free(&segs);
      return NULL;
    }
    if (list_node->element_node == NULL) {
      /* Scalar list without an element subtree: the item is a value leaf. */
      som_strlist_free(&segs);
      return last ? list_node : NULL;
    }
    node = list_node->element_node;
  }
  som_strlist_free(&segs);
  return node;
}

/* ---- SomMetaRef / SomListMetaRef ----------------------------------------- */

void som_meta_ref_init(SomMetaRef *r, const SomMetaTree *tree,
                       const char *path) {
  r->tree = tree;
  r->path = som_strdup(path);
}

void som_meta_ref_free(SomMetaRef *r) {
  if (r == NULL) {
    return;
  }
  free(r->path);
  r->path = NULL;
  r->tree = NULL;
}

const SomMetaNode *som_meta_ref_meta(const SomMetaRef *r, char **err) {
  const SomMetaNode *node = som_meta_tree_by_path(r->tree, r->path);
  if (node == NULL) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "no metadata node at \"");
    som_buf_puts(&b, r->path);
    som_buf_puts(&b, "\" \xE2\x80\x94 the position lies beyond a recursive "
                     "re-entry; use the dynamic tree lookups instead");
    set_err(err, som_buf_take(&b));
    return NULL;
  }
  return node;
}

void som_list_meta_ref_init(SomListMetaRef *r, const SomMetaTree *tree,
                            const char *path, SomMetaRefFactory element) {
  som_meta_ref_init(&r->ref, tree, path);
  r->element = element;
}

void som_list_meta_ref_free(SomListMetaRef *r) {
  if (r == NULL) {
    return;
  }
  som_meta_ref_free(&r->ref);
  r->element = NULL;
}

void *som_list_meta_ref_item(const SomListMetaRef *r, long long seq) {
  char *item_path = spec_list_item_path(r->ref.path, seq);
  void *out = r->element(r->ref.tree, item_path);
  free(item_path);
  return out;
}
