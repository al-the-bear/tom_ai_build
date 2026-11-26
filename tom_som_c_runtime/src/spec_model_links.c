/* spec_model_links — the typed readers of the link vocabulary
 * (`tom_specs_model_rules.md` §9.7). See include/spec_model_links.h. */
#include "spec_model_links.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_model.h"

/* ---- ordered string -> string pairs -------------------------------------- */

void spec_string_pairs_init(SpecStringPairs *p) {
  p->items = NULL;
  p->len = 0;
  p->cap = 0;
}

void spec_string_pairs_free(SpecStringPairs *p) {
  for (size_t i = 0; i < p->len; i++) {
    free(p->items[i].key);
    free(p->items[i].value);
  }
  free(p->items);
  spec_string_pairs_init(p);
}

void spec_string_pairs_push(SpecStringPairs *p, const char *key,
                            const char *value) {
  if (p->len == p->cap) {
    p->cap = p->cap ? p->cap * 2 : 4;
    p->items =
        (SpecStringPair *)realloc(p->items, p->cap * sizeof(SpecStringPair));
  }
  p->items[p->len].key = som_strdup(key);
  p->items[p->len].value = som_strdup(value);
  p->len++;
}

void spec_string_pairs_put(SpecStringPairs *p, const char *key,
                           const char *value) {
  for (size_t i = 0; i < p->len; i++) {
    if (strcmp(p->items[i].key, key) == 0) {
      free(p->items[i].value);
      p->items[i].value = som_strdup(value);
      return;
    }
  }
  spec_string_pairs_push(p, key, value);
}

const char *spec_string_pairs_get(const SpecStringPairs *p, const char *key) {
  const char *found = NULL;
  for (size_t i = 0; i < p->len; i++) {
    if (strcmp(p->items[i].key, key) == 0) found = p->items[i].value;
  }
  return found;
}

void spec_string_pairs_copy(SpecStringPairs *dst, const SpecStringPairs *src) {
  spec_string_pairs_init(dst);
  for (size_t i = 0; i < src->len; i++) {
    spec_string_pairs_push(dst, src->items[i].key, src->items[i].value);
  }
}

/* ---- JSON writing -------------------------------------------------------- */

static void put_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

static void put_key(SomBuf *b, int *first, const char *key) {
  if (!*first) som_buf_putc(b, ',');
  *first = 0;
  put_str(b, key);
  som_buf_putc(b, ':');
}

static void put_str_member(SomBuf *b, int *first, const char *key,
                           const char *value) {
  put_key(b, first, key);
  put_str(b, value);
}

/* An optional member: written only when set and not empty. */
static void put_opt_member(SomBuf *b, int *first, const char *key,
                           const char *value) {
  if (value != NULL && value[0] != '\0') put_str_member(b, first, key, value);
}

static void put_list(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    put_str(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

static void put_pairs(SomBuf *b, const SpecStringPairs *p) {
  som_buf_putc(b, '{');
  for (size_t i = 0; i < p->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    put_str(b, p->items[i].key);
    som_buf_putc(b, ':');
    put_str(b, p->items[i].value);
  }
  som_buf_putc(b, '}');
}

char *spec_string_pairs_to_json(const SpecStringPairs *p) {
  SomBuf b;
  som_buf_init(&b);
  put_pairs(&b, p);
  return som_buf_take(&b);
}

/* A whole double as an integer, else the shortest text that reads back. */
static void put_double(SomBuf *b, double v) {
  if (v > -1e15 && v < 1e15 && (double)(long long)v == v) {
    som_buf_puti(b, (long long)v);
    return;
  }
  char text[64];
  for (int prec = 1; prec <= 17; prec++) {
    snprintf(text, sizeof(text), "%.*g", prec, v);
    if (strtod(text, NULL) == v) break;
  }
  som_buf_puts(b, text);
}

static int cmp_members(const void *a, const void *b) {
  const SomJsonMember *x = *(const SomJsonMember *const *)a;
  const SomJsonMember *y = *(const SomJsonMember *const *)b;
  return strcmp(x->key, y->key);
}

/* Compact JSON of any value, object keys sorted (Go's json.Marshal). */
static void put_json(SomBuf *b, const SomJson *v) {
  if (v == NULL) {
    som_buf_puts(b, "null");
    return;
  }
  switch (v->type) {
    case SOM_JSON_NULL:
      som_buf_puts(b, "null");
      break;
    case SOM_JSON_BOOL:
      som_buf_puts(b, v->as.boolean ? "true" : "false");
      break;
    case SOM_JSON_INT:
      som_buf_puti(b, v->as.integer);
      break;
    case SOM_JSON_FLOAT:
      put_double(b, v->as.real);
      break;
    case SOM_JSON_STR:
      put_str(b, v->as.str);
      break;
    case SOM_JSON_ARRAY:
      som_buf_putc(b, '[');
      for (size_t i = 0; i < v->as.array.len; i++) {
        if (i > 0) som_buf_putc(b, ',');
        put_json(b, v->as.array.items[i]);
      }
      som_buf_putc(b, ']');
      break;
    case SOM_JSON_OBJECT: {
      size_t n = v->as.object.len;
      const SomJsonMember **m =
          (const SomJsonMember **)calloc(n ? n : 1, sizeof(*m));
      for (size_t i = 0; i < n; i++) m[i] = &v->as.object.members[i];
      if (n > 1) qsort(m, n, sizeof(*m), cmp_members);
      som_buf_putc(b, '{');
      for (size_t i = 0; i < n; i++) {
        if (i > 0) som_buf_putc(b, ',');
        put_str(b, m[i]->key);
        som_buf_putc(b, ':');
        put_json(b, m[i]->value);
      }
      som_buf_putc(b, '}');
      free(m);
      break;
    }
  }
}

char *spec_link_json_text(const SomJson *v) {
  if (v != NULL && v->type == SOM_JSON_STR) return som_strdup(v->as.str);
  SomBuf b;
  som_buf_init(&b);
  put_json(&b, v);
  return som_buf_take(&b);
}

/* ---- reading the arguments ----------------------------------------------- */

/* The argument `key`, NULL when absent or JSON null. */
static const SomJson *arg(const SomJson *args, const char *key) {
  if (args == NULL || args->type != SOM_JSON_OBJECT) return NULL;
  const SomJson *v = NULL;
  /* The last member of a repeated key wins, as a decoded map's does. */
  for (size_t i = 0; i < args->as.object.len; i++) {
    if (strcmp(args->as.object.members[i].key, key) == 0) {
      v = args->as.object.members[i].value;
    }
  }
  if (v != NULL && v->type == SOM_JSON_NULL) return NULL;
  return v;
}

/* A string argument with a default when absent. Owned. */
static char *arg_str(const SomJson *args, const char *key,
                     const char *fallback) {
  const SomJson *v = arg(args, key);
  return v == NULL ? som_strdup(fallback) : spec_link_json_text(v);
}

/* An optional string argument: the string, or NULL for anything else (an
 * empty string included, which the canonical forms leave out). Owned. */
static char *arg_opt(const SomJson *args, const char *key) {
  const SomJson *v = arg(args, key);
  if (v == NULL || v->type != SOM_JSON_STR || v->as.str[0] == '\0') {
    return NULL;
  }
  return som_strdup(v->as.str);
}

/* An enum argument with its type prefix stripped. Owned. */
static char *arg_enum(const SomJson *args, const char *key,
                      const char *fallback) {
  char *raw = arg_str(args, key, fallback);
  char *out = som_strdup(spec_strip_enum_prefix(raw));
  free(raw);
  return out;
}

/* A JSON list read as strings, nulls dropped; anything else as empty. */
static void arg_list(const SomJson *args, const char *key, SomStrList *out) {
  som_strlist_init(out);
  const SomJson *v = arg(args, key);
  if (v == NULL || v->type != SOM_JSON_ARRAY) return;
  for (size_t i = 0; i < v->as.array.len; i++) {
    const SomJson *e = v->as.array.items[i];
    if (e == NULL || e->type == SOM_JSON_NULL) continue;
    som_strlist_push(out, spec_link_json_text(e));
  }
}

/* A JSON object read as string -> string, in the order the meta writes it;
 * anything else as empty. */
static void arg_pairs(const SomJson *args, const char *key,
                      SpecStringPairs *out) {
  spec_string_pairs_init(out);
  const SomJson *v = arg(args, key);
  if (v == NULL || v->type != SOM_JSON_OBJECT) return;
  for (size_t i = 0; i < v->as.object.len; i++) {
    char *text = spec_link_json_text(v->as.object.members[i].value);
    spec_string_pairs_put(out, v->as.object.members[i].key, text);
    free(text);
  }
}

/* ---- the readers ----------------------------------------------------------- */

void spec_list_relation_from_arguments(const SomJson *args,
                                       SpecListRelation *out) {
  out->place = arg_str(args, "place", "");
  out->relation = arg_enum(args, "relation", "equal");
  out->where = arg_opt(args, "where");
}

void spec_list_relation_free(SpecListRelation *r) {
  free(r->place);
  free(r->relation);
  free(r->where);
  memset(r, 0, sizeof(*r));
}

static void put_relation(SomBuf *b, const SpecListRelation *r) {
  int first = 1;
  som_buf_putc(b, '{');
  put_str_member(b, &first, "place", r->place);
  put_str_member(b, &first, "relation", r->relation);
  put_opt_member(b, &first, "where", r->where);
  som_buf_putc(b, '}');
}

char *spec_list_relation_to_json(const SpecListRelation *r) {
  SomBuf b;
  som_buf_init(&b);
  put_relation(&b, r);
  return som_buf_take(&b);
}

void spec_sync_from_arguments(const SomJson *args, SpecSync *out) {
  memset(out, 0, sizeof(*out));
  out->document = arg_str(args, "document", "");
  arg_list(args, "detailOnly", &out->detail_only);
  arg_list(args, "heldHere", &out->held_here);
  const SomJson *rel = arg(args, "relations");
  if (rel != NULL && rel->type == SOM_JSON_ARRAY) {
    out->relations = (SpecListRelation *)calloc(
        rel->as.array.len ? rel->as.array.len : 1, sizeof(SpecListRelation));
    for (size_t i = 0; i < rel->as.array.len; i++) {
      const SomJson *e = rel->as.array.items[i];
      if (e == NULL || e->type != SOM_JSON_OBJECT) continue;
      spec_list_relation_from_arguments(e,
                                        &out->relations[out->relations_len++]);
    }
  }
  out->note = arg_opt(args, "note");
}

void spec_sync_free(SpecSync *s) {
  free(s->document);
  som_strlist_free(&s->detail_only);
  som_strlist_free(&s->held_here);
  for (size_t i = 0; i < s->relations_len; i++) {
    spec_list_relation_free(&s->relations[i]);
  }
  free(s->relations);
  free(s->note);
  memset(s, 0, sizeof(*s));
}

char *spec_sync_to_json(const SpecSync *s) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str_member(&b, &first, "document", s->document);
  put_key(&b, &first, "detailOnly");
  put_list(&b, &s->detail_only);
  put_key(&b, &first, "heldHere");
  put_list(&b, &s->held_here);
  put_key(&b, &first, "relations");
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < s->relations_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_relation(&b, &s->relations[i]);
  }
  som_buf_putc(&b, ']');
  put_opt_member(&b, &first, "note", s->note);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_summary_of_from_arguments(const SomJson *args, SpecSummaryOf *out) {
  out->detail = arg_str(args, "detail", "");
  out->document = arg_opt(args, "document");
  out->match = arg_opt(args, "match");
  out->relation = arg_enum(args, "relation", "subset");
  arg_pairs(args, "repeats", &out->repeats);
  out->note = arg_opt(args, "note");
}

void spec_summary_of_free(SpecSummaryOf *s) {
  free(s->detail);
  free(s->document);
  free(s->match);
  free(s->relation);
  spec_string_pairs_free(&s->repeats);
  free(s->note);
  memset(s, 0, sizeof(*s));
}

char *spec_summary_of_to_json(const SpecSummaryOf *s) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str_member(&b, &first, "detail", s->detail);
  put_opt_member(&b, &first, "document", s->document);
  put_opt_member(&b, &first, "match", s->match);
  put_str_member(&b, &first, "relation", s->relation);
  put_key(&b, &first, "repeats");
  put_pairs(&b, &s->repeats);
  put_opt_member(&b, &first, "note", s->note);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_derivation_from_arguments(const SomJson *args, SpecDerivation *out) {
  out->kind = arg_enum(args, "kind", "copy");
  out->source = arg_str(args, "source", "");
  out->where = arg_opt(args, "where");
  arg_list(args, "take", &out->take);
  out->key = arg_opt(args, "key");
  out->by = arg_opt(args, "by");
  arg_pairs(args, "map", &out->map);
  out->note = arg_opt(args, "note");
}

void spec_derivation_free(SpecDerivation *d) {
  free(d->kind);
  free(d->source);
  free(d->where);
  som_strlist_free(&d->take);
  free(d->key);
  free(d->by);
  spec_string_pairs_free(&d->map);
  free(d->note);
  memset(d, 0, sizeof(*d));
}

char *spec_derivation_to_json(const SpecDerivation *d) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str_member(&b, &first, "kind", d->kind);
  put_str_member(&b, &first, "source", d->source);
  put_opt_member(&b, &first, "where", d->where);
  put_key(&b, &first, "take");
  put_list(&b, &d->take);
  put_opt_member(&b, &first, "key", d->key);
  put_opt_member(&b, &first, "by", d->by);
  put_key(&b, &first, "map");
  put_pairs(&b, &d->map);
  put_opt_member(&b, &first, "note", d->note);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_inverse_of_from_arguments(const SomJson *args, SpecInverseOf *out) {
  arg_list(args, "fields", &out->fields);
  out->where = arg_opt(args, "where");
}

void spec_inverse_of_free(SpecInverseOf *i) {
  som_strlist_free(&i->fields);
  free(i->where);
  memset(i, 0, sizeof(*i));
}

int spec_inverse_of_symmetric(const SpecInverseOf *i) {
  return i->fields.len == 1 && strcmp(i->fields.items[0], "@self") == 0;
}

char *spec_inverse_of_to_json(const SpecInverseOf *i) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_key(&b, &first, "fields");
  put_list(&b, &i->fields);
  put_opt_member(&b, &first, "where", i->where);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_extracts_links_from_arguments(const SomJson *args,
                                        SpecExtractsLinks *out) {
  arg_list(args, "from", &out->from);
  out->ref = arg_str(args, "ref", "");
  arg_pairs(args, "set", &out->set);
  out->mode = arg_enum(args, "mode", "generate");
  out->note = arg_opt(args, "note");
}

void spec_extracts_links_free(SpecExtractsLinks *e) {
  free(e->ref);
  som_strlist_free(&e->from);
  spec_string_pairs_free(&e->set);
  free(e->mode);
  free(e->note);
  memset(e, 0, sizeof(*e));
}

char *spec_extracts_links_to_json(const SpecExtractsLinks *e) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_key(&b, &first, "from");
  put_list(&b, &e->from);
  put_str_member(&b, &first, "ref", e->ref);
  put_key(&b, &first, "set");
  put_pairs(&b, &e->set);
  put_str_member(&b, &first, "mode", e->mode);
  put_opt_member(&b, &first, "note", e->note);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_extracts_links_list_free(SpecExtractsLinksList *l) {
  for (size_t i = 0; i < l->len; i++) spec_extracts_links_free(&l->items[i]);
  free(l->items);
  l->items = NULL;
  l->len = 0;
}

void spec_same_as_from_arguments(const SomJson *args, SpecSameAs *out) {
  out->holder = arg_opt(args, "holder");
  out->note = arg_opt(args, "note");
}

void spec_same_as_free(SpecSameAs *s) {
  free(s->holder);
  free(s->note);
  memset(s, 0, sizeof(*s));
}

char *spec_same_as_to_json(const SpecSameAs *s) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_opt_member(&b, &first, "holder", s->holder);
  put_opt_member(&b, &first, "note", s->note);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the accessors on annotation lists (spec_model.h) -------------------- */

int spec_annotations_synced_with(const SpecAnnotationList *l, SpecSync *out) {
  const SpecAnnotation *a = spec_annotations_named(l, "SyncedWith");
  if (a == NULL) return 0;
  spec_sync_from_arguments(a->arguments, out);
  return 1;
}

int spec_annotations_summary_of(const SpecAnnotationList *l,
                                SpecSummaryOf *out) {
  const SpecAnnotation *a = spec_annotations_named(l, "SummaryOf");
  if (a == NULL) return 0;
  spec_summary_of_from_arguments(a->arguments, out);
  return 1;
}

int spec_annotations_derived_from(const SpecAnnotationList *l,
                                  SpecDerivation *out) {
  const SpecAnnotation *a = spec_annotations_named(l, "DerivedFrom");
  if (a == NULL) return 0;
  spec_derivation_from_arguments(a->arguments, out);
  return 1;
}

void spec_annotations_extracts_links(const SpecAnnotationList *l,
                                     SpecExtractsLinksList *out) {
  out->items = NULL;
  out->len = 0;
  size_t n = 0;
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i].name, "ExtractsLinks") == 0) n++;
  }
  if (n == 0) return;
  out->items = (SpecExtractsLinks *)calloc(n, sizeof(SpecExtractsLinks));
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i].name, "ExtractsLinks") != 0) continue;
    spec_extracts_links_from_arguments(l->items[i].arguments,
                                       &out->items[out->len++]);
  }
}

int spec_annotations_same_as(const SpecAnnotationList *l, SpecSameAs *out) {
  const SpecAnnotation *a = spec_annotations_named(l, "SameAs");
  if (a == NULL) return 0;
  spec_same_as_from_arguments(a->arguments, out);
  return 1;
}

int spec_annotations_has_same_as(const SpecAnnotationList *l) {
  return spec_annotations_have(l, "SameAs");
}

int spec_class_is_code_specs_projection(const SpecClass *cls) {
  return cls != NULL &&
         spec_annotations_have(&cls->annotations, "CodeSpecsProjection");
}

/* ---- the form-field qualifiers ------------------------------------------- */

static const SomJson *qualifier(const SomJson *ff, const char *key) {
  const SomJson *v = som_json_get(ff, key);
  return (v != NULL && v->type == SOM_JSON_OBJECT) ? v : NULL;
}

void spec_form_field_links_from_json(const SomJson *ff, FormFieldSpec *out) {
  const SomJson *q = qualifier(ff, "derivedFrom");
  if (q != NULL) {
    out->derived_from = (SpecDerivation *)calloc(1, sizeof(SpecDerivation));
    spec_derivation_from_arguments(q, out->derived_from);
  }
  q = qualifier(ff, "inverseOf");
  if (q != NULL) {
    out->inverse_of = (SpecInverseOf *)calloc(1, sizeof(SpecInverseOf));
    spec_inverse_of_from_arguments(q, out->inverse_of);
  }
  q = qualifier(ff, "summaryOf");
  if (q != NULL) {
    out->summary_of = (SpecSummaryOf *)calloc(1, sizeof(SpecSummaryOf));
    spec_summary_of_from_arguments(q, out->summary_of);
  }
}

void spec_form_field_links_free(FormFieldSpec *ff) {
  if (ff->derived_from != NULL) {
    spec_derivation_free(ff->derived_from);
    free(ff->derived_from);
    ff->derived_from = NULL;
  }
  if (ff->inverse_of != NULL) {
    spec_inverse_of_free(ff->inverse_of);
    free(ff->inverse_of);
    ff->inverse_of = NULL;
  }
  if (ff->summary_of != NULL) {
    spec_summary_of_free(ff->summary_of);
    free(ff->summary_of);
    ff->summary_of = NULL;
  }
}
