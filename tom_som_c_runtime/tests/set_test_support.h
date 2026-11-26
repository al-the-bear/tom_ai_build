/* What the document-set unit tests share (spec_document_set_test.c,
 * spec_derive_fields_test.c, spec_prefill_backfill_test.c): the checker, the
 * corpus tables, their models and their documents. Reads the corpus from
 * `../tom_som_conformance/corpus/` (run from the package root). */
#ifndef SET_TEST_SUPPORT_H
#define SET_TEST_SUPPORT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

static int g_checks = 0;
static int g_failures = 0;

static inline void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

static inline int report_done(const char *test) {
  if (g_failures == 0) {
    printf("%s: all %d checks passed\n", test, g_checks);
  } else {
    fprintf(stderr, "%s: %d of %d checks failed\n", test, g_failures, g_checks);
  }
  return g_failures;
}

static inline char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "fatal: cannot read %s\n", path);
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  rewind(f);
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  buf[got] = '\0';
  fclose(f);
  return buf;
}

/* A corpus table. Owned. */
static inline SomJson *table(const char *name) {
  char path[512];
  snprintf(path, sizeof(path), "../tom_som_conformance/corpus/%s", name);
  char *text = read_file(path);
  char *err = NULL;
  SomJson *v = som_json_parse(text, &err);
  free(text);
  if (v == NULL) {
    fprintf(stderr, "fatal: parse %s: %s\n", name, err != NULL ? err : "");
    exit(2);
  }
  return v;
}

/* The fixture model a table names. Owned. */
static inline SpecModel *table_model(const SomJson *t) {
  const char *name = som_json_as_str(som_json_get(t, "model"));
  char path[512];
  snprintf(path, sizeof(path), "../tom_som_conformance/corpus/%s",
           name != NULL ? name : "links.meta.json");
  char *text = read_file(path);
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(text, &err);
  free(text);
  if (m == NULL) {
    fprintf(stderr, "fatal: model %s: %s\n", path, err != NULL ? err : "");
    exit(2);
  }
  return m;
}

/* The case of `group` whose name starts with `prefix`. Borrowed. */
static inline const SomJson *case_named(const SomJson *t, const char *group,
                                 const char *prefix) {
  const SomJson *cases = som_json_get(t, group);
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *c = som_json_array_at(cases, i);
    if (strncmp(som_json_str_or(c, "name"), prefix, strlen(prefix)) == 0) return c;
  }
  fprintf(stderr, "fatal: no %s case %s\n", group, prefix);
  exit(2);
}

/* `doc` (uninitialised) holds the document a generic state decodes to. */
static inline void state_document(const SomJson *state, SpecDocument *doc) {
  DocumentJson j;
  document_json_from_json(state, &j);
  spec_document_init(doc);
  spec_document_load_json(doc, &j);
  document_json_free(&j);
}

/* The documents of a case, `[[name, state], ...]`. */
typedef struct {
  SpecDocument *docs;
  SpecNamedDocument *named;
  size_t len;
} CaseDocs;

static inline void case_docs(const SomJson *c, CaseDocs *out) {
  const SomJson *entries = som_json_get(c, "documents");
  size_t n = som_json_array_len(entries);
  out->docs = (SpecDocument *)calloc(n ? n : 1, sizeof(SpecDocument));
  out->named = (SpecNamedDocument *)calloc(n ? n : 1, sizeof(SpecNamedDocument));
  out->len = n;
  for (size_t i = 0; i < n; i++) {
    const SomJson *pair = som_json_array_at(entries, i);
    state_document(som_json_array_at(pair, 1), &out->docs[i]);
    out->named[i].name = som_json_as_str(som_json_array_at(pair, 0));
    out->named[i].document = &out->docs[i];
  }
}

static inline void case_docs_free(CaseDocs *d) {
  for (size_t i = 0; i < d->len; i++) spec_document_free(&d->docs[i]);
  free(d->docs);
  free(d->named);
}

/* `out` holds the set of a case's documents (exits when refused). */
static inline void case_set(const SpecModel *model, const SomJson *c,
                     SpecDocumentSet *out) {
  CaseDocs docs;
  case_docs(c, &docs);
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  if (!spec_document_set_new(model, docs.named, docs.len, out, &err)) {
    char *why = spec_document_set_error_display(&err);
    fprintf(stderr, "fatal: %s\n", why);
    exit(2);
  }
  spec_document_set_error_free(&err);
  case_docs_free(&docs);
}

/* ---- JSON equality (object keys compared as a set) -------------------------- */

static inline int cmp_member_key(const void *a, const void *b) {
  return strcmp((*(const SomJsonMember *const *)a)->key,
                (*(const SomJsonMember *const *)b)->key);
}

static inline void canon_into(SomBuf *b, const SomJson *v) {
  if (v == NULL || v->type == SOM_JSON_NULL) {
    som_buf_puts(b, "null");
  } else if (v->type == SOM_JSON_BOOL) {
    som_buf_puts(b, v->as.boolean ? "true" : "false");
  } else if (v->type == SOM_JSON_INT) {
    som_buf_puti(b, v->as.integer);
  } else if (v->type == SOM_JSON_FLOAT) {
    char num[64];
    snprintf(num, sizeof(num), "%.17g", v->as.real);
    som_buf_puts(b, num);
  } else if (v->type == SOM_JSON_STR) {
    char *q = som_json_encode_str(v->as.str);
    som_buf_puts(b, q);
    free(q);
  } else if (v->type == SOM_JSON_ARRAY) {
    som_buf_putc(b, '[');
    for (size_t i = 0; i < v->as.array.len; i++) {
      if (i > 0) som_buf_putc(b, ',');
      canon_into(b, v->as.array.items[i]);
    }
    som_buf_putc(b, ']');
  } else {
    size_t n = v->as.object.len;
    const SomJsonMember **ms =
        (const SomJsonMember **)malloc((n ? n : 1) * sizeof(SomJsonMember *));
    for (size_t i = 0; i < n; i++) ms[i] = &v->as.object.members[i];
    qsort(ms, n, sizeof(SomJsonMember *), cmp_member_key);
    som_buf_putc(b, '{');
    for (size_t i = 0; i < n; i++) {
      if (i > 0) som_buf_putc(b, ',');
      char *q = som_json_encode_str(ms[i]->key);
      som_buf_puts(b, q);
      free(q);
      som_buf_putc(b, ':');
      canon_into(b, ms[i]->value);
    }
    som_buf_putc(b, '}');
    free(ms);
  }
}

static inline char *canon(const SomJson *v) {
  SomBuf b;
  som_buf_init(&b);
  canon_into(&b, v);
  return som_buf_take(&b);
}

/* Whether the JSON text `got` equals the JSON value `want`. */
static inline int json_text_eq(const char *got, const SomJson *want) {
  char *err = NULL;
  SomJson *g = som_json_parse(got, &err);
  if (g == NULL) {
    free(err);
    return 0;
  }
  char *x = canon(g);
  char *y = canon(want);
  int eq = strcmp(x, y) == 0;
  free(x);
  free(y);
  som_json_free(g);
  return eq;
}

/* Whether two JSON texts are equal as JSON. */
static inline int json_texts_eq(const char *a, const char *b) {
  char *err = NULL;
  SomJson *w = som_json_parse(b, &err);
  if (w == NULL) {
    free(err);
    return 0;
  }
  int eq = json_text_eq(a, w);
  som_json_free(w);
  return eq;
}

/* Whether two documents hold the same stores. */
static inline int same_doc(const SpecDocument *a, const SpecDocument *b) {
  if (a == NULL || b == NULL) return a == b;
  char *x = spec_document_stores_json(a);
  char *y = spec_document_stores_json(b);
  int eq = strcmp(x, y) == 0;
  free(x);
  free(y);
  return eq;
}

static inline int strlist_is(const SomStrList *l, const char *const *want, size_t n) {
  if (l->len != n) return 0;
  for (size_t i = 0; i < n; i++) {
    if (strcmp(l->items[i], want[i]) != 0) return 0;
  }
  return 1;
}

/* The `link_rendition_cases.json` case whose intent names a token, with the
 * model it runs against (an inline one, the real one for a case marked `som`,
 * else the links fixture) and its document. Owns everything. */
typedef struct {
  SomJson *table;
  const SomJson *kase; /* borrowed from `table` */
  SpecModel *model;
  SpecDocument doc;
} RenditionFixture;

static inline void rendition_fixture(const char *token, RenditionFixture *out) {
  out->table = table("link_rendition_cases.json");
  out->kase = NULL;
  const SomJson *cases = som_json_get(out->table, "cases");
  for (size_t i = 0; i < som_json_array_len(cases) && out->kase == NULL; i++) {
    const SomJson *c = som_json_array_at(cases, i);
    const SomJson *intent = som_json_get(c, "intent");
    for (size_t k = 0; k < som_json_array_len(intent); k++) {
      const char *t = som_json_as_str(som_json_array_at(intent, k));
      if (t != NULL && strcmp(t, token) == 0) out->kase = c;
    }
  }
  if (out->kase == NULL) {
    fprintf(stderr, "fatal: no rendition case with intent %s\n", token);
    exit(2);
  }
  const SomJson *inline_model = som_json_get(out->kase, "inline");
  if (inline_model != NULL && inline_model->type == SOM_JSON_OBJECT) {
    out->model = spec_model_from_json(inline_model);
  } else if (strcmp(som_json_str_or(out->kase, "model"), "som") == 0) {
    char *text = read_file("../tom_som_dart_v0/meta/spec_model.meta.json");
    char *err = NULL;
    out->model = spec_model_from_json_str(text, &err);
    free(text);
    if (out->model == NULL) {
      fprintf(stderr, "fatal: the SOM model: %s\n", err != NULL ? err : "");
      exit(2);
    }
  } else {
    out->model = table_model(out->table);
  }
  state_document(som_json_get(out->kase, "state"), &out->doc);
}

static inline void rendition_fixture_free(RenditionFixture *f) {
  spec_document_free(&f->doc);
  spec_model_free(f->model);
  som_json_free(f->table);
}

/* The golden rendition of the fixture's case. Borrowed. */
static inline const char *rendition_golden(const RenditionFixture *f) {
  return som_json_str_or(som_json_get(f->kase, "expect"), "markdown");
}

/* The first root (with a section id) `doc` holds a value under. */
static inline const SpecRoot *populated_root(const SpecModel *model,
                                             const SpecDocument *doc) {
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *r = &model->roots[i];
    if (r->section_id[0] != '\0' && spec_document_has_values_under(doc, r->section_id)) {
      return r;
    }
  }
  fprintf(stderr, "fatal: no populated root\n");
  exit(2);
}

/* The root with section id `id`. */
static inline const SpecRoot *root_with_id(const SpecModel *model, const char *id) {
  for (size_t i = 0; i < model->roots_len; i++) {
    if (strcmp(model->roots[i].section_id, id) == 0) return &model->roots[i];
  }
  fprintf(stderr, "fatal: no root %s\n", id);
  exit(2);
}

/* `root` of `doc` rendered with `o` (NULL: file stem `links`, markers and
 * generated parts on). Owned. */
static inline char *render_root(const SpecModel *model, const SpecDocument *doc,
                                const SpecRoot *root,
                                const SpecMarkdownExportOptions *o) {
  SpecMarkdownExportOptions dflt;
  memset(&dflt, 0, sizeof(dflt));
  dflt.file_stem = "links";
  SpecMarkdownRendition r;
  char *err = NULL;
  if (!spec_markdown_export_root_with_options(model, doc, root, o != NULL ? o : &dflt,
                                              &r, &err)) {
    fprintf(stderr, "fatal: export: %s\n", err != NULL ? err : "");
    exit(2);
  }
  char *md = r.markdown;
  r.markdown = NULL;
  spec_markdown_rendition_free(&r);
  return md;
}

/* Whether `md` parses back to `doc` without a rejection. */
static inline int round_trips(const char *md, const SpecModel *model,
                              const SpecDocument *doc) {
  SpecMarkdownImport imp;
  spec_document_from_markdown(md, model, &imp);
  int ok = imp.result.rejections_len == 0 && same_doc(imp.document, doc);
  spec_markdown_import_free(&imp);
  return ok;
}

/* `s` with the first `from` replaced by `to`. Owned. */
static inline char *replace_first(const char *s, const char *from, const char *to) {
  const char *at = strstr(s, from);
  if (at == NULL) return som_strdup(s);
  size_t a = (size_t)(at - s), fl = strlen(from), tl = strlen(to);
  char *out = (char *)malloc(strlen(s) - fl + tl + 1);
  memcpy(out, s, a);
  memcpy(out + a, to, tl);
  strcpy(out + a + tl, at + fl);
  return out;
}

#endif /* SET_TEST_SUPPORT_H */
