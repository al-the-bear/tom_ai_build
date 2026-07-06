#include "som_facade.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ---- SomNode ------------------------------------------------------------ */

void som_node_init(SomNode *n, SpecDocument *doc, const char *path) {
  n->doc = doc;
  n->path = som_strdup(path != NULL ? path : "");
}

void som_node_free(SomNode *n) {
  free(n->path);
  n->path = NULL;
  n->doc = NULL;
}

const char *som_node_path(const SomNode *n) { return n->path; }

SpecDocument *som_node_doc(const SomNode *n) { return n->doc; }

char *som_node_section_id(const SomNode *n) {
  const char *id = spec_document_item_section_id(n->doc, n->path);
  return som_strdup(id != NULL ? id : "");
}

/* True when no value lives at this node's path or beneath it (§ item 5). */
int som_node_is_empty(const SomNode *n) {
  return !spec_document_has_values_under(n->doc, n->path);
}

/* NOTE (§ item 10): the `can_have_content` structural predicate ("does this
 * section TYPE declare the standard `content` text leaf?") has no base helper
 * here. Unlike `som_node_is_empty` / `som_editability_for`, it is a compile-time
 * property of each generated type, not a runtime computation over the document,
 * and C has no inheritance to carry a shared default — so (following the item-8
 * `editability_for` and item-5 `is_empty` per-type C emission precedent) the
 * generated `tom_som_c_v0` emits a `<type>_can_have_content` accessor returning
 * the literal answer for every generated section type. See som_facade.h. */

int som_node_set_section_id(const SomNode *n, const char *id,
                            SpecSectionIdError *err) {
  if (id == NULL || id[0] == '\0') {
    return 1;
  }
  return spec_document_set_item_section_id(n->doc, n->path, id, err);
}

/* ---- SomScalar ---------------------------------------------------------- */

void som_scalar_init(SomScalar *s, SpecDocument *doc, const char *path) {
  som_node_init(&s->node, doc, path);
}

void som_scalar_free(SomScalar *s) { som_node_free(&s->node); }

char *som_scalar_value(const SomScalar *s) {
  const char *v = spec_document_content(s->node.doc, s->node.path);
  return som_strdup(v != NULL ? v : "");
}

void som_scalar_set_value(SomScalar *s, const char *value) {
  spec_document_set_content(s->node.doc, s->node.path, value);
}

/* ---- SomList ------------------------------------------------------------ */

void som_list_init(SomList *l, SpecDocument *doc, const char *list_path) {
  som_list_init_pattern(l, doc, list_path, "");
}

void som_list_init_pattern(SomList *l, SpecDocument *doc, const char *list_path,
                           const char *pattern) {
  l->doc = doc;
  l->list_path = som_strdup(list_path != NULL ? list_path : "");
  l->pattern = som_strdup(pattern != NULL ? pattern : "");
}

void som_list_free(SomList *l) {
  free(l->list_path);
  free(l->pattern);
  l->list_path = NULL;
  l->pattern = NULL;
  l->doc = NULL;
}

size_t som_list_length(const SomList *l) {
  return spec_document_list_item_count(l->doc, l->list_path);
}

const char *som_list_item_path_at(const SomList *l, size_t index) {
  const SomStrList *items = spec_document_list_items(l->doc, l->list_path);
  if (items == NULL || index >= items->len) {
    return NULL;
  }
  return items->items[index];
}

void som_list_item_paths(const SomList *l, SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *items = spec_document_list_items(l->doc, l->list_path);
  if (items == NULL) {
    return;
  }
  for (size_t i = 0; i < items->len; i++) {
    som_strlist_push_copy(out, items->items[i]);
  }
}

void som_list_section_ids(const SomList *l, SomStrList *out) {
  spec_document_list_item_section_ids(l->doc, l->list_path, out);
}

/* Generates a section id from the pattern using `(month, day)` and appends an
 * item carrying it. The generated id is unique by construction, so the store's
 * uniqueness guard never fires. Returns the item's stable path (owned). */
static char *som_list_add_generated(SomList *l, long long month, long long day) {
  SomStrList existing;
  spec_document_list_item_section_ids(l->doc, l->list_path, &existing);
  char *id = spec_generate_list_item_section_id(l->pattern, month, day, &existing);
  som_strlist_free(&existing);
  char *item_path = spec_document_add_list_item_with_section_id(
      l->doc, l->list_path, id, NULL);
  free(id);
  return item_path;
}

char *som_list_add(SomList *l) {
  if (l->pattern[0] == '\0') {
    return spec_document_add_list_item(l->doc, l->list_path);
  }
  long long month, day;
  spec_today_month_day(&month, &day);
  return som_list_add_generated(l, month, day);
}

char *som_list_add_on(SomList *l, long long month, long long day) {
  if (l->pattern[0] == '\0') {
    return spec_document_add_list_item(l->doc, l->list_path);
  }
  return som_list_add_generated(l, month, day);
}

int som_list_add_with_id(SomList *l, const char *section_id,
                         char **out_item_path, SpecSectionIdError *err) {
  char *item_path = spec_document_add_list_item_with_section_id(
      l->doc, l->list_path, section_id, err);
  if (item_path == NULL) {
    return 0;
  }
  if (out_item_path != NULL) {
    *out_item_path = item_path;
  } else {
    free(item_path);
  }
  return 1;
}

/* Builds the nested `<item_path>/content` leaf path (owned). */
static char *content_leaf_path(const char *item_path) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, item_path);
  som_buf_puts(&b, "/content");
  return som_buf_take(&b);
}

/* Shared body for the add-content variants: `item_path` is an owned path just
 * returned by an add; writes `content` to its nested `<item>/content` leaf and
 * returns the same (owned) item path. */
static char *set_content_leaf(SomList *l, char *item_path, const char *content) {
  char *leaf = content_leaf_path(item_path);
  spec_document_set_content(l->doc, leaf, content);
  free(leaf);
  return item_path;
}

char *som_list_add_content(SomList *l, const char *content) {
  return set_content_leaf(l, som_list_add(l), content);
}

char *som_list_add_content_on(SomList *l, const char *content, long long month,
                              long long day) {
  return set_content_leaf(l, som_list_add_on(l, month, day), content);
}

void som_list_contents(const SomList *l, SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *items = spec_document_list_items(l->doc, l->list_path);
  if (items == NULL) {
    return;
  }
  for (size_t i = 0; i < items->len; i++) {
    char *leaf = content_leaf_path(items->items[i]);
    const char *v = spec_document_content(l->doc, leaf);
    free(leaf);
    som_strlist_push_copy(out, v != NULL ? v : "");
  }
}

void som_list_remove_at(SomList *l, size_t index) {
  const char *path = som_list_item_path_at(l, index);
  if (path == NULL) {
    return;
  }
  char *owned = som_strdup(path);
  spec_document_remove_list_item(l->doc, owned);
  free(owned);
}

/* ---- model-version guard ------------------------------------------------ */

typedef struct {
  long long major;
  long long minor;
  int ok;
} SomVersion;

static int try_int(const char *raw, long long *out) {
  if (raw == NULL || raw[0] == '\0') {
    return 0;
  }
  size_t i = 0;
  if (raw[0] == '-' || raw[0] == '+') {
    if (raw[1] == '\0') {
      return 0;
    }
    i = 1;
  }
  for (size_t j = i; raw[j] != '\0'; j++) {
    if (raw[j] < '0' || raw[j] > '9') {
      return 0;
    }
  }
  return som_parse_i64(raw, out);
}

static SomVersion try_parse_som_version(const char *raw) {
  SomVersion v = {0, 0, 0};
  const char *dot = strchr(raw, '.');
  if (dot == NULL) {
    return v;
  }
  if (strchr(dot + 1, '.') != NULL) {
    return v; /* more than two parts */
  }
  char *major_part = som_strdup_n(raw, (size_t)(dot - raw));
  long long major = 0, minor = 0;
  int ok = try_int(major_part, &major) && try_int(dot + 1, &minor);
  free(major_part);
  if (!ok) {
    return v;
  }
  v.major = major;
  v.minor = minor;
  v.ok = 1;
  return v;
}

static char *fmt_msg(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  va_list ap2;
  va_copy(ap2, ap);
  int n = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  if (n < 0) {
    va_end(ap2);
    return som_strdup("");
  }
  char *buf = (char *)malloc((size_t)n + 1);
  vsnprintf(buf, (size_t)n + 1, fmt, ap2);
  va_end(ap2);
  return buf;
}

SomEditability som_editability_for(const char *generated,
                                   const char *document_version) {
  if (document_version == NULL || document_version[0] == '\0') {
    return SOM_EDITABILITY_EDITABLE;
  }
  SomVersion gen = (generated == NULL) ? (SomVersion){0, 0, 0}
                                       : try_parse_som_version(generated);
  SomVersion docv = try_parse_som_version(document_version);
  if (!gen.ok || !docv.ok) {
    return SOM_EDITABILITY_INVALID_VERSION;
  }
  if (docv.major != gen.major) {
    return SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR;
  }
  if (docv.minor > gen.minor) {
    return SOM_EDITABILITY_REJECTED_NEWER_MINOR;
  }
  return SOM_EDITABILITY_EDITABLE;
}

int check_som_model_version(const char *generated, const char *document_version,
                            char **err_message) {
  switch (som_editability_for(generated, document_version)) {
    case SOM_EDITABILITY_EDITABLE:
      return 0;
    case SOM_EDITABILITY_INVALID_VERSION: {
      /* Distinguish an unparseable generated version from an unparseable
       * document stamp, matching the original messages. */
      SomVersion gen = (generated == NULL) ? (SomVersion){0, 0, 0}
                                           : try_parse_som_version(generated);
      if (!gen.ok) {
        if (err_message != NULL) {
          *err_message =
              fmt_msg("\"%s\" is not a valid major.minor version",
                      generated != NULL ? generated : "");
        }
      } else if (err_message != NULL) {
        *err_message = fmt_msg(
            "document model version \"%s\" is not a valid major.minor",
            document_version);
      }
      return 1;
    }
    case SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR: {
      SomVersion gen = try_parse_som_version(generated);
      SomVersion docv = try_parse_som_version(document_version);
      if (err_message != NULL) {
        *err_message = fmt_msg(
            "document major version %lld differs from the object model major "
            "version %lld; cross-major documents are read-only",
            docv.major, gen.major);
      }
      return 1;
    }
    case SOM_EDITABILITY_REJECTED_NEWER_MINOR:
      if (err_message != NULL) {
        *err_message = fmt_msg(
            "document model version %s is newer than the object model version "
            "%s; an older object model cannot edit a newer document",
            document_version, generated);
      }
      return 1;
  }
  return 0;
}
