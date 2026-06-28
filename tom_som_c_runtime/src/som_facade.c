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
  l->doc = doc;
  l->list_path = som_strdup(list_path != NULL ? list_path : "");
}

void som_list_free(SomList *l) {
  free(l->list_path);
  l->list_path = NULL;
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

char *som_list_add(SomList *l) {
  return spec_document_add_list_item(l->doc, l->list_path);
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

int check_som_model_version(const char *generated, const char *document_version,
                            char **err_message) {
  if (document_version == NULL || document_version[0] == '\0') {
    return 0;
  }
  SomVersion gen = try_parse_som_version(generated);
  if (!gen.ok) {
    if (err_message != NULL) {
      *err_message =
          fmt_msg("\"%s\" is not a valid major.minor version", generated);
    }
    return 1;
  }
  SomVersion docv = try_parse_som_version(document_version);
  if (!docv.ok) {
    if (err_message != NULL) {
      *err_message = fmt_msg(
          "document model version \"%s\" is not a valid major.minor",
          document_version);
    }
    return 1;
  }
  if (docv.major != gen.major) {
    if (err_message != NULL) {
      *err_message = fmt_msg(
          "document major version %lld differs from the object model major "
          "version %lld; cross-major documents are read-only",
          docv.major, gen.major);
    }
    return 1;
  }
  if (docv.minor > gen.minor) {
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
