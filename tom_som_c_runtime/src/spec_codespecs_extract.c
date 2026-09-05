/* spec_codespecs_extract — implementation. See spec_codespecs_extract.h; a
 * faithful port of the Dart `spec_codespecs_extract.dart`. */
#include "spec_codespecs_extract.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"

/* ---- shared emission helpers --------------------------------------------- */

/* Appends `value` as a JSON string literal, which is also a valid YAML 1.2
 * double-quoted scalar. Hand-written rather than delegated to a library encoder
 * so the nine ports have one rule to transcribe rather than nine encoders to
 * hope agree.
 *
 * The Dart original iterates over *runes* (Unicode code points); here the loop
 * is over UTF-8 **bytes**, and the two agree byte for byte: every escaped case
 * is ASCII, so it can never be a UTF-8 continuation byte, and every byte at or
 * above 0x20 — which includes all of `0x80`–`0xFF` — is copied through
 * untouched. Emitting a multi-byte code point one byte at a time therefore
 * reproduces exactly the bytes Dart writes for it. (`unsigned char` matters:
 * plain `char` may be signed, which would send every non-ASCII byte down the
 * `< 0x20` branch.) */
static void yaml_string(SomBuf *b, const char *value) {
  som_buf_putc(b, '"');
  for (const unsigned char *p = (const unsigned char *)value; *p != '\0'; p++) {
    switch (*p) {
      case 0x22:
        som_buf_puts(b, "\\\"");
        break;
      case 0x5C:
        som_buf_puts(b, "\\\\");
        break;
      case 0x08:
        som_buf_puts(b, "\\b");
        break;
      case 0x0C:
        som_buf_puts(b, "\\f");
        break;
      case 0x0A:
        som_buf_puts(b, "\\n");
        break;
      case 0x0D:
        som_buf_puts(b, "\\r");
        break;
      case 0x09:
        som_buf_puts(b, "\\t");
        break;
      default:
        if (*p < 0x20) {
          char esc[8];
          snprintf(esc, sizeof(esc), "\\u%04x", (unsigned int)*p);
          som_buf_puts(b, esc);
        } else {
          som_buf_putc(b, (char)*p);
        }
        break;
    }
  }
  som_buf_putc(b, '"');
}

/* `null` for an absent optional string, the quoted scalar otherwise. */
static void yaml_nullable_string(SomBuf *b, const char *value) {
  if (value == NULL) {
    som_buf_puts(b, "null");
  } else {
    yaml_string(b, value);
  }
}

static void yaml_string_list(SomBuf *b, const SomStrList *values) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < values->len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    yaml_string(b, values->items[i]);
  }
  som_buf_putc(b, ']');
}

static void yaml_int_list(SomBuf *b, const long long *values, size_t len) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    som_buf_puti(b, values[i]);
  }
  som_buf_putc(b, ']');
}

/* A markdown table cell: newlines folded to a space (a cell cannot hold one) and
 * `|` escaped. Applied only to catalogue prose, never to a stored value — values
 * go into fenced blocks, where they stay verbatim. */
static void md_cell(SomBuf *b, const char *value) {
  for (const char *p = value; *p != '\0'; p++) {
    if (*p == '\n') {
      som_buf_putc(b, ' ');
    } else if (*p == '|') {
      som_buf_puts(b, "\\|");
    } else {
      som_buf_putc(b, *p);
    }
  }
}

static void md_code_list(SomBuf *b, const SomStrList *values) {
  if (values->len == 0) {
    som_buf_puts(b, "—");
    return;
  }
  for (size_t i = 0; i < values->len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    som_buf_putc(b, '`');
    som_buf_puts(b, values->items[i]);
    som_buf_putc(b, '`');
  }
}

static void md_int_list(SomBuf *b, const long long *values, size_t len) {
  if (len == 0) {
    som_buf_puts(b, "—");
    return;
  }
  for (size_t i = 0; i < len; i++) {
    if (i > 0) {
      som_buf_puts(b, ", ");
    }
    som_buf_puti(b, values[i]);
  }
}

/* Appends the shortest backtick fence that cannot be closed by `value`'s own
 * content. */
static void fence_for(SomBuf *b, const char *value) {
  size_t longest = 0;
  size_t run = 0;
  for (const char *p = value; *p != '\0'; p++) {
    if (*p == 0x60) {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 0;
    }
  }
  size_t width = longest >= 3 ? longest + 1 : 3;
  for (size_t i = 0; i < width; i++) {
    som_buf_putc(b, '`');
  }
}

/* Copies an optional string: NULL stays NULL, so "absent" never collapses into
 * "authored as empty". */
static char *dup_opt(const char *s) { return s == NULL ? NULL : som_strdup(s); }

/* ---- routing verdicts ---------------------------------------------------- */

const char *spec_codespecs_verdict_name(CodeSpecsRoutingVerdict v) {
  switch (v) {
    case CODESPECS_VERDICT_FEEDS_CODE:
      return "feedsCode";
    case CODESPECS_VERDICT_FEEDS_PROCESS:
      return "feedsProcess";
    case CODESPECS_VERDICT_FEEDS_NOTHING:
      return "feedsNothing";
    case CODESPECS_VERDICT_DOCUMENT_ROOT:
      return "documentRoot";
    case CODESPECS_VERDICT_UNROUTED:
      return "unrouted";
  }
  return "";
}

void spec_codespecs_routing_free(CodeSpecsRouting *r) {
  if (r == NULL) {
    return;
  }
  free(r->path);
  free(r->class_name);
  som_strlist_free(&r->values);
  free(r->note);
  free(r->declared_at);
  r->path = NULL;
  r->class_name = NULL;
  r->note = NULL;
  r->declared_at = NULL;
}

char *spec_codespecs_routing_string(const CodeSpecsRouting *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CodeSpecsRouting(");
  som_buf_puts(&b, r->path);
  som_buf_puts(&b, ", ");
  som_buf_puts(&b, r->class_name);
  som_buf_puts(&b, ", ");
  som_buf_puts(&b, spec_codespecs_verdict_name(r->verdict));
  som_buf_putc(&b, ')');
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

void spec_codespecs_routing_list_init(CodeSpecsRoutingList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_codespecs_routing_list_free(CodeSpecsRoutingList *l) {
  if (l == NULL) {
    return;
  }
  for (size_t i = 0; i < l->len; i++) {
    spec_codespecs_routing_free(&l->items[i]);
  }
  free(l->items);
  spec_codespecs_routing_list_init(l);
}

/* A deep copy — the walk keeps its own routing alive for the length of the
 * frame, so what goes into the list has to be an independent copy. */
static CodeSpecsRouting routing_copy(const CodeSpecsRouting *r) {
  CodeSpecsRouting out;
  out.path = som_strdup(r->path);
  out.class_name = som_strdup(r->class_name);
  out.verdict = r->verdict;
  som_strlist_copy(&out.values, &r->values);
  out.note = dup_opt(r->note);
  out.declared_at = som_strdup(r->declared_at);
  return out;
}

/* Appends a copy of `*r`; the list owns the copy's strings. */
static void routing_list_push(CodeSpecsRoutingList *l,
                              const CodeSpecsRouting *r) {
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 8;
    l->items =
        (CodeSpecsRouting *)realloc(l->items, l->cap * sizeof(CodeSpecsRouting));
  }
  l->items[l->len++] = routing_copy(r);
}

/* ---- extract entries ----------------------------------------------------- */

void spec_codespecs_extract_entry_free(CodeSpecsExtractEntry *e) {
  if (e == NULL) {
    return;
  }
  free(e->area_code);
  free(e->section_id);
  free(e->headline);
  free(e->path);
  free(e->class_name);
  free(e->field_name);
  free(e->form_field);
  free(e->routed_by);
  free(e->routed_at);
  free(e->routing_note);
  free(e->value);
  memset(e, 0, sizeof(*e));
}

char *spec_codespecs_extract_entry_string(const CodeSpecsExtractEntry *e) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CodeSpecsExtractEntry(");
  som_buf_puts(&b, e->area_code);
  som_buf_puts(&b, ", ");
  som_buf_puts(&b, e->path);
  som_buf_putc(&b, ')');
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

static CodeSpecsExtractEntry entry_copy(const CodeSpecsExtractEntry *e) {
  CodeSpecsExtractEntry out;
  out.area_code = som_strdup(e->area_code);
  out.section_id = som_strdup(e->section_id);
  out.headline = dup_opt(e->headline);
  out.path = som_strdup(e->path);
  out.class_name = som_strdup(e->class_name);
  out.field_name = som_strdup(e->field_name);
  out.form_field = dup_opt(e->form_field);
  out.routed_by = som_strdup(e->routed_by);
  out.routed_at = som_strdup(e->routed_at);
  out.routing_note = dup_opt(e->routing_note);
  out.value = som_strdup(e->value);
  return out;
}

/* The growable entry buffer the walk collects into, before the entries are
 * partitioned across the active areas. */
typedef struct {
  CodeSpecsExtractEntry *items;
  size_t len;
  size_t cap;
} EntryBuf;

static void entry_buf_init(EntryBuf *b) {
  b->items = NULL;
  b->len = 0;
  b->cap = 0;
}

static void entry_buf_free(EntryBuf *b) {
  for (size_t i = 0; i < b->len; i++) {
    spec_codespecs_extract_entry_free(&b->items[i]);
  }
  free(b->items);
  entry_buf_init(b);
}

static void entry_buf_push(EntryBuf *b, const CodeSpecsExtractEntry *e) {
  if (b->len == b->cap) {
    b->cap = b->cap ? b->cap * 2 : 16;
    b->items = (CodeSpecsExtractEntry *)realloc(
        b->items, b->cap * sizeof(CodeSpecsExtractEntry));
  }
  b->items[b->len++] = *e;
}

static void extract_push_entry(CodeSpecsExtract *x,
                               const CodeSpecsExtractEntry *e) {
  if (x->entries_len == x->entries_cap) {
    x->entries_cap = x->entries_cap ? x->entries_cap * 2 : 16;
    x->entries = (CodeSpecsExtractEntry *)realloc(
        x->entries, x->entries_cap * sizeof(CodeSpecsExtractEntry));
  }
  x->entries[x->entries_len++] = *e;
}

/* ---- the area catalogue -------------------------------------------------- */

/* Fills `*out` with the string elements of `parent[key]` (empty when absent). */
static void json_strlist(const SomJson *parent, const char *key,
                         SomStrList *out) {
  som_strlist_init(out);
  const SomJson *arr = som_json_get(parent, key);
  size_t n = som_json_array_len(arr);
  for (size_t i = 0; i < n; i++) {
    const char *s = som_json_as_str(som_json_array_at(arr, i));
    if (s != NULL) {
      som_strlist_push_copy(out, s);
    }
  }
}

/* Fills `*items` / `*len` with the integer elements of `parent[key]` (NULL / 0
 * when absent). Owned; free with `free`. */
static void json_intlist(const SomJson *parent, const char *key,
                         long long **items, size_t *len) {
  const SomJson *arr = som_json_get(parent, key);
  size_t n = som_json_array_len(arr);
  *items = NULL;
  *len = 0;
  if (n == 0) {
    return;
  }
  *items = (long long *)calloc(n, sizeof(long long));
  for (size_t i = 0; i < n; i++) {
    long long v = 0;
    som_json_as_i64(som_json_array_at(arr, i), &v);
    (*items)[i] = v;
  }
  *len = n;
}

/* `j[key]` when present, else `fallback` — the ports' `as bool? ?? true`. */
static int json_bool_or_default(const SomJson *j, const char *key,
                                int fallback) {
  int v = 0;
  return som_json_as_bool(som_json_get(j, key), &v) ? v : fallback;
}

static void slice_from_json(const SomJson *j, CodeSpecsSlice *out) {
  out->number = 0;
  som_json_as_i64(som_json_get(j, "number"), &out->number);
  out->title = som_strdup(som_json_str_or(j, "title"));
  out->project = som_strdup(som_json_str_or(j, "project"));
  json_intlist(j, "cites", &out->cites, &out->cites_len);
}

static void area_from_json(const SomJson *j, CodeSpecsArea *out) {
  out->code = som_strdup(som_json_str_or(j, "code"));
  out->canonical_id = som_strdup(som_json_str_or(j, "canonicalId"));
  out->part = som_strdup(som_json_str_or(j, "part"));
  json_strlist(j, "annotations", &out->annotations);
  out->built_on = som_strdup(som_json_str_or(j, "builtOn"));
  out->attribute_surface = som_strdup(som_json_str_or(j, "attributeSurface"));
  json_intlist(j, "slices", &out->slices, &out->slices_len);
  json_intlist(j, "authoringSteps", &out->authoring_steps,
               &out->authoring_steps_len);
  out->active = json_bool_or_default(j, "active", 1);
}

void spec_codespecs_area_catalog_from_json(const SomJson *v,
                                           CodeSpecsAreaCatalog *out) {
  out->source = som_strdup(som_json_str_or(v, "source"));
  out->slices = NULL;
  out->slices_len = 0;
  out->areas = NULL;
  out->areas_len = 0;

  const SomJson *slices = som_json_get(v, "slices");
  size_t n = som_json_array_len(slices);
  if (n > 0) {
    out->slices = (CodeSpecsSlice *)calloc(n, sizeof(CodeSpecsSlice));
    for (size_t i = 0; i < n; i++) {
      slice_from_json(som_json_array_at(slices, i), &out->slices[i]);
    }
    out->slices_len = n;
  }

  const SomJson *areas = som_json_get(v, "areas");
  n = som_json_array_len(areas);
  if (n > 0) {
    out->areas = (CodeSpecsArea *)calloc(n, sizeof(CodeSpecsArea));
    for (size_t i = 0; i < n; i++) {
      area_from_json(som_json_array_at(areas, i), &out->areas[i]);
    }
    out->areas_len = n;
  }
}

void spec_codespecs_area_catalog_free(CodeSpecsAreaCatalog *c) {
  if (c == NULL) {
    return;
  }
  free(c->source);
  for (size_t i = 0; i < c->slices_len; i++) {
    free(c->slices[i].title);
    free(c->slices[i].project);
    free(c->slices[i].cites);
  }
  free(c->slices);
  for (size_t i = 0; i < c->areas_len; i++) {
    free(c->areas[i].code);
    free(c->areas[i].canonical_id);
    free(c->areas[i].part);
    som_strlist_free(&c->areas[i].annotations);
    free(c->areas[i].built_on);
    free(c->areas[i].attribute_surface);
    free(c->areas[i].slices);
    free(c->areas[i].authoring_steps);
  }
  free(c->areas);
  memset(c, 0, sizeof(*c));
}

char *spec_codespecs_area_kind_value(const CodeSpecsArea *a) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CodeSpecPart.");
  som_buf_puts(&b, a->part);
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

size_t spec_codespecs_catalog_active_area_count(const CodeSpecsAreaCatalog *c) {
  size_t n = 0;
  for (size_t i = 0; i < c->areas_len; i++) {
    if (c->areas[i].active) {
      n++;
    }
  }
  return n;
}

const CodeSpecsArea *
spec_codespecs_catalog_active_area_at(const CodeSpecsAreaCatalog *c, size_t i) {
  size_t seen = 0;
  for (size_t k = 0; k < c->areas_len; k++) {
    if (!c->areas[k].active) {
      continue;
    }
    if (seen == i) {
      return &c->areas[k];
    }
    seen++;
  }
  return NULL;
}

const CodeSpecsArea *
spec_codespecs_catalog_by_code(const CodeSpecsAreaCatalog *c, const char *code) {
  if (code == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < c->areas_len; i++) {
    if (strcmp(c->areas[i].code, code) == 0) {
      return &c->areas[i];
    }
  }
  return NULL;
}

const CodeSpecsArea *
spec_codespecs_catalog_by_part(const CodeSpecsAreaCatalog *c,
                              const char *value) {
  if (value == NULL) {
    return NULL;
  }
  static const char prefix[] = "CodeSpecPart.";
  const char *bare = strncmp(value, prefix, sizeof(prefix) - 1) == 0
                         ? value + sizeof(prefix) - 1
                         : value;
  for (size_t i = 0; i < c->areas_len; i++) {
    if (strcmp(c->areas[i].part, bare) == 0) {
      return &c->areas[i];
    }
  }
  return NULL;
}

const CodeSpecsSlice *
spec_codespecs_catalog_slice_numbered(const CodeSpecsAreaCatalog *c,
                                      long long number) {
  for (size_t i = 0; i < c->slices_len; i++) {
    if (c->slices[i].number == number) {
      return &c->slices[i];
    }
  }
  return NULL;
}

void spec_codespecs_catalog_projects_for(const CodeSpecsAreaCatalog *c,
                                         const CodeSpecsArea *area,
                                         SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < area->slices_len; i++) {
    const CodeSpecsSlice *slice =
        spec_codespecs_catalog_slice_numbered(c, area->slices[i]);
    if (slice == NULL || slice->project[0] == '\0' ||
        som_strlist_contains(out, slice->project)) {
      continue;
    }
    som_strlist_push_copy(out, slice->project);
  }
}

/* Reports whether `values[0..len)` already holds `n`. */
static int int_contains(const long long *values, size_t len, long long n) {
  for (size_t i = 0; i < len; i++) {
    if (values[i] == n) {
      return 1;
    }
  }
  return 0;
}

void spec_codespecs_catalog_citable_area_codes(const CodeSpecsAreaCatalog *c,
                                               const CodeSpecsArea *area,
                                               SomStrList *out) {
  som_strlist_init(out);
  /* Both worklists are bounded by the number of slices: `reachable` is a set of
   * distinct slice numbers, and nothing is pushed onto `stack` that is not
   * either one of the area's own slices or a `cites` edge, and no number is
   * expanded twice. */
  size_t capacity = c->slices_len + area->slices_len + 1;
  long long *reachable = (long long *)calloc(capacity, sizeof(long long));
  size_t reachable_len = 0;
  long long *stack = (long long *)calloc(capacity, sizeof(long long));
  size_t stack_len = 0;
  for (size_t i = 0; i < area->slices_len && stack_len < capacity; i++) {
    stack[stack_len++] = area->slices[i];
  }
  while (stack_len > 0) {
    long long n = stack[--stack_len];
    if (int_contains(reachable, reachable_len, n)) {
      continue;
    }
    if (reachable_len < capacity) {
      reachable[reachable_len++] = n;
    }
    const CodeSpecsSlice *slice = spec_codespecs_catalog_slice_numbered(c, n);
    if (slice == NULL) {
      continue;
    }
    for (size_t i = 0; i < slice->cites_len; i++) {
      if (!int_contains(reachable, reachable_len, slice->cites[i]) &&
          stack_len < capacity) {
        stack[stack_len++] = slice->cites[i];
      }
    }
  }
  for (size_t i = 0; i < c->areas_len; i++) {
    const CodeSpecsArea *a = &c->areas[i];
    if (!a->active || strcmp(a->code, area->code) == 0) {
      continue;
    }
    for (size_t s = 0; s < a->slices_len; s++) {
      if (int_contains(reachable, reachable_len, a->slices[s])) {
        som_strlist_push_copy(out, a->code);
        break;
      }
    }
  }
  free(reachable);
  free(stack);
}

/* ---- the extract --------------------------------------------------------- */

void spec_codespecs_extract_free(CodeSpecsExtract *x) {
  if (x == NULL) {
    return;
  }
  free(x->catalog_source);
  free(x->document_root);
  som_strlist_free(&x->citable_parts);
  som_strlist_free(&x->projects);
  for (size_t i = 0; i < x->entries_len; i++) {
    spec_codespecs_extract_entry_free(&x->entries[i]);
  }
  free(x->entries);
  memset(x, 0, sizeof(*x));
}

char *spec_codespecs_extract_file_stem(const CodeSpecsExtract *x) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, x->area->code);
  som_buf_puts(&b, ".extract");
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

char *spec_codespecs_extract_to_yaml(const CodeSpecsExtract *x) {
  char *kind_value = spec_codespecs_area_kind_value(x->area);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "# ");
  som_buf_puts(&b, x->area->code);
  som_buf_puts(&b, ".extract.yaml — generated by spec_codespecs_extract. "
                   "Do not edit.\n");
  som_buf_puts(&b, "extract:\n");
  som_buf_puts(&b, "  formatVersion: ");
  som_buf_puti(&b, SPEC_CODESPECS_EXTRACT_FORMAT);
  som_buf_puts(&b, "\n  catalogSource: ");
  yaml_string(&b, x->catalog_source);
  som_buf_puts(&b, "\n  area:\n    code: ");
  yaml_string(&b, x->area->code);
  som_buf_puts(&b, "\n    canonicalId: ");
  yaml_string(&b, x->area->canonical_id);
  som_buf_puts(&b, "\n    part: ");
  yaml_string(&b, kind_value);
  som_buf_puts(&b, "\n    annotations: ");
  yaml_string_list(&b, &x->area->annotations);
  som_buf_puts(&b, "\n    builtOn: ");
  yaml_string(&b, x->area->built_on);
  som_buf_puts(&b, "\n    attributeSurface: ");
  yaml_string(&b, x->area->attribute_surface);
  som_buf_puts(&b, "\n    slices: ");
  yaml_int_list(&b, x->area->slices, x->area->slices_len);
  som_buf_puts(&b, "\n    authoringSteps: ");
  yaml_int_list(&b, x->area->authoring_steps, x->area->authoring_steps_len);
  som_buf_puts(&b, "\n    projects: ");
  yaml_string_list(&b, &x->projects);
  som_buf_puts(&b, "\n    citableParts: ");
  yaml_string_list(&b, &x->citable_parts);
  som_buf_puts(&b, "\n  document:\n    root: ");
  yaml_string(&b, x->document_root);
  som_buf_puts(&b, "\n    entryCount: ");
  som_buf_puti(&b, (long long)x->entries_len);
  som_buf_putc(&b, '\n');
  free(kind_value);
  if (x->entries_len == 0) {
    som_buf_puts(&b, "  entries: []\n");
    char *out = som_buf_take(&b);
    som_buf_free(&b);
    return out;
  }
  som_buf_puts(&b, "  entries:\n");
  for (size_t i = 0; i < x->entries_len; i++) {
    const CodeSpecsExtractEntry *e = &x->entries[i];
    som_buf_puts(&b, "    - sectionId: ");
    yaml_string(&b, e->section_id);
    som_buf_puts(&b, "\n      headline: ");
    yaml_nullable_string(&b, e->headline);
    som_buf_puts(&b, "\n      path: ");
    yaml_string(&b, e->path);
    som_buf_puts(&b, "\n      className: ");
    yaml_string(&b, e->class_name);
    som_buf_puts(&b, "\n      fieldName: ");
    yaml_string(&b, e->field_name);
    som_buf_puts(&b, "\n      formField: ");
    yaml_nullable_string(&b, e->form_field);
    som_buf_puts(&b, "\n      routedBy: ");
    yaml_string(&b, e->routed_by);
    som_buf_puts(&b, "\n      routedAt: ");
    yaml_string(&b, e->routed_at);
    som_buf_puts(&b, "\n      routingNote: ");
    yaml_nullable_string(&b, e->routing_note);
    som_buf_puts(&b, "\n      value: ");
    yaml_string(&b, e->value);
    som_buf_putc(&b, '\n');
  }
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

char *spec_codespecs_extract_to_markdown(const CodeSpecsExtract *x) {
  char *kind_value = spec_codespecs_area_kind_value(x->area);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "# ");
  som_buf_puts(&b, x->area->code);
  som_buf_puts(&b, " — ");
  som_buf_puts(&b, x->area->canonical_id);
  som_buf_puts(&b, "\n\nGenerated by `spec_codespecs_extract` from the "
                   "specification document rooted at `");
  som_buf_puts(&b, x->document_root);
  som_buf_puts(&b, "`.\n`");
  som_buf_puts(&b, x->area->code);
  som_buf_puts(&b, ".extract.yaml` beside this file is the artifact of record; "
                   "this is a view of it.\n");
  som_buf_puts(&b, "\n## Area\n\n| | |\n|---|---|\n| CE code | `");
  som_buf_puts(&b, x->area->code);
  som_buf_puts(&b, "` |\n| Canonical id | `");
  som_buf_puts(&b, x->area->canonical_id);
  som_buf_puts(&b, "` |\n| `@CodeSpecKind` value | `");
  som_buf_puts(&b, kind_value);
  som_buf_puts(&b, "` |\n| `Cs*` annotations | ");
  md_code_list(&b, &x->area->annotations);
  som_buf_puts(&b, " |\n| Built on | ");
  md_cell(&b, x->area->built_on);
  som_buf_puts(&b, " |\n| Attribute surface | ");
  md_cell(&b, x->area->attribute_surface);
  som_buf_puts(&b, " |\n| Slice(s) | ");
  md_int_list(&b, x->area->slices, x->area->slices_len);
  som_buf_puts(&b, " |\n| Authoring step(s) | ");
  md_int_list(&b, x->area->authoring_steps, x->area->authoring_steps_len);
  som_buf_puts(&b, " |\n| Project(s) | ");
  md_code_list(&b, &x->projects);
  som_buf_puts(&b, " |\n| May cite | ");
  md_code_list(&b, &x->citable_parts);
  som_buf_puts(&b, " |\n| Catalogue source | ");
  md_cell(&b, x->catalog_source);
  som_buf_puts(&b, " |\n\n## Entries (");
  som_buf_puti(&b, (long long)x->entries_len);
  som_buf_puts(&b, ")\n\n");
  if (x->entries_len == 0) {
    som_buf_puts(&b, "_No section of this document is routed to `");
    som_buf_puts(&b, kind_value);
    som_buf_puts(&b, "`._\n");
    free(kind_value);
    char *out = som_buf_take(&b);
    som_buf_free(&b);
    return out;
  }
  free(kind_value);
  for (size_t i = 0; i < x->entries_len; i++) {
    const CodeSpecsExtractEntry *e = &x->entries[i];
    som_buf_puts(&b, "### ");
    som_buf_puti(&b, (long long)(i + 1));
    som_buf_puts(&b, ". `");
    som_buf_puts(&b, e->section_id);
    som_buf_puts(&b, "` — `");
    som_buf_puts(&b, e->class_name);
    som_buf_putc(&b, '.');
    som_buf_puts(&b, e->field_name);
    if (e->form_field != NULL) {
      som_buf_putc(&b, '.');
      som_buf_puts(&b, e->form_field);
    }
    som_buf_puts(&b, "`\n\n");
    if (e->headline != NULL) {
      som_buf_puts(&b, "- headline: ");
      md_cell(&b, e->headline);
      som_buf_putc(&b, '\n');
    }
    som_buf_puts(&b, "- path: `");
    som_buf_puts(&b, e->path);
    som_buf_puts(&b, "`\n- routed by: `");
    som_buf_puts(&b, e->routed_by);
    som_buf_puts(&b, "` declared on `");
    som_buf_puts(&b, e->routed_at);
    som_buf_puts(&b, "`\n");
    if (e->routing_note != NULL) {
      som_buf_puts(&b, "- routing note: ");
      md_cell(&b, e->routing_note);
      som_buf_putc(&b, '\n');
    }
    som_buf_putc(&b, '\n');
    fence_for(&b, e->value);
    som_buf_puts(&b, " text\n");
    som_buf_puts(&b, e->value);
    som_buf_putc(&b, '\n');
    fence_for(&b, e->value);
    som_buf_puts(&b, "\n\n");
  }
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

void spec_codespecs_extract_list_init(CodeSpecsExtractList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_codespecs_extract_list_free(CodeSpecsExtractList *l) {
  if (l == NULL) {
    return;
  }
  for (size_t i = 0; i < l->len; i++) {
    spec_codespecs_extract_free(&l->items[i]);
  }
  free(l->items);
  spec_codespecs_extract_list_init(l);
}

/* Appends `*x` by value, transferring ownership of its members to the list. */
static void extract_list_push(CodeSpecsExtractList *l,
                              const CodeSpecsExtract *x) {
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 8;
    l->items =
        (CodeSpecsExtract *)realloc(l->items, l->cap * sizeof(CodeSpecsExtract));
  }
  l->items[l->len++] = *x;
}

/* ---- the error ----------------------------------------------------------- */

void spec_codespecs_extract_error_init(CodeSpecsExtractError *e) {
  if (e == NULL) {
    return;
  }
  e->failed = 0;
  e->message = NULL;
  e->path = NULL;
  e->class_name = NULL;
}

void spec_codespecs_extract_error_free(CodeSpecsExtractError *e) {
  if (e == NULL) {
    return;
  }
  free(e->message);
  free(e->path);
  free(e->class_name);
  spec_codespecs_extract_error_init(e);
}

int spec_codespecs_extract_error_is_ok(const CodeSpecsExtractError *e) {
  return e == NULL || !e->failed;
}

char *spec_codespecs_extract_error_string(const CodeSpecsExtractError *e) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CodeSpecsExtractError: ");
  som_buf_puts(&b, e->message != NULL ? e->message : "");
  som_buf_puts(&b, " (");
  som_buf_puts(&b, e->path != NULL ? e->path : "");
  som_buf_puts(&b, ", ");
  som_buf_puts(&b, e->class_name != NULL ? e->class_name : "");
  som_buf_putc(&b, ')');
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

/* ---- the extractor ------------------------------------------------------- */

/* Fills `*err` (when non-NULL) with a root-resolution failure and returns NULL,
 * so every failing branch of `resolve_root` is one line. Takes ownership of
 * `message`. */
static const SpecRoot *fail_root(CodeSpecsExtractError *err, char *message,
                                 const char *path, const char *class_name) {
  if (err != NULL) {
    err->failed = 1;
    err->message = message;
    err->path = som_strdup(path);
    err->class_name = som_strdup(class_name);
  } else {
    free(message);
  }
  return NULL;
}

/* The one root the walk starts at — see `spec_codespecs_extractor_make`. */
static const SpecRoot *resolve_root(const SpecModel *model,
                                    const SpecDocument *document,
                                    const char *root_type,
                                    CodeSpecsExtractError *err) {
  SomStrList populated_types;
  som_strlist_init(&populated_types);
  const SpecRoot *only_populated = NULL;
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *r = &model->roots[i];
    if (spec_document_has_values_under(document,
                                       spec_reflection_root_segment(r))) {
      som_strlist_push_copy(&populated_types, r->type);
      if (populated_types.len == 1) {
        only_populated = r;
      }
    }
  }
  SomStrList all_types;
  som_strlist_init(&all_types);
  for (size_t i = 0; i < model->roots_len; i++) {
    som_strlist_push_copy(&all_types, model->roots[i].type);
  }

  const SpecRoot *result = NULL;
  SomBuf b;
  if (root_type != NULL && root_type[0] != '\0') {
    const SpecRoot *named = NULL;
    for (size_t i = 0; i < model->roots_len; i++) {
      const SpecRoot *r = &model->roots[i];
      if (strcmp(r->type, root_type) == 0 ||
          strcmp(spec_reflection_root_segment(r), root_type) == 0) {
        named = r;
        break;
      }
    }
    if (named == NULL) {
      char *names = som_strlist_join(&all_types, ", ");
      som_buf_init(&b);
      som_buf_puts(&b, "no document root with type or section id \"");
      som_buf_puts(&b, root_type);
      som_buf_puts(&b, "\" (have: ");
      som_buf_puts(&b, names);
      som_buf_putc(&b, ')');
      free(names);
      result = fail_root(err, som_buf_take(&b), "", root_type);
      som_buf_free(&b);
    } else if (populated_types.len > 0 &&
               !som_strlist_contains(&populated_types, named->type)) {
      char *pop = som_strlist_join(&populated_types, ", ");
      som_buf_init(&b);
      som_buf_puts(&b, "root \"");
      som_buf_puts(&b, root_type);
      som_buf_puts(&b, "\" holds no value in this document, but ");
      som_buf_puts(&b, pop);
      som_buf_puts(&b,
                   " does — every extract would come out empty "
                   "(codespecs_prompt.md §5)");
      free(pop);
      result = fail_root(err, som_buf_take(&b),
                         spec_reflection_root_segment(named), named->type);
      som_buf_free(&b);
    } else {
      result = named;
    }
  } else if (populated_types.len == 1) {
    result = only_populated;
  } else if (populated_types.len == 0) {
    if (model->roots_len == 1) {
      result = &model->roots[0];
    } else {
      char *names = som_strlist_join(&all_types, ", ");
      som_buf_init(&b);
      som_buf_puts(&b,
                   "document has no populated root to extract from; pass "
                   "rootType to choose one (have: ");
      som_buf_puts(&b, names);
      som_buf_putc(&b, ')');
      free(names);
      result = fail_root(err, som_buf_take(&b), "", "");
      som_buf_free(&b);
    }
  } else {
    char *pop = som_strlist_join(&populated_types, ", ");
    som_buf_init(&b);
    som_buf_puts(&b, "document has ");
    som_buf_puti(&b, (long long)populated_types.len);
    som_buf_puts(&b, " populated roots (");
    som_buf_puts(&b, pop);
    som_buf_puts(&b, "); pass rootType to choose one");
    free(pop);
    result = fail_root(err, som_buf_take(&b), "", "");
    som_buf_free(&b);
  }

  som_strlist_free(&populated_types);
  som_strlist_free(&all_types);
  return result;
}

CodeSpecsExtractor
spec_codespecs_extractor_make(const SpecModel *model,
                              const SpecDocument *document,
                              const CodeSpecsAreaCatalog *catalog,
                              const char *root_type,
                              CodeSpecsExtractError *err) {
  if (err != NULL) {
    spec_codespecs_extract_error_init(err);
  }
  CodeSpecsExtractor e;
  e.model = model;
  e.document = document;
  e.catalog = catalog;
  e.root = resolve_root(model, document, root_type, err);
  e.reflection = spec_reflection_make(model);
  return e;
}

/* The verdict `cls` carries. The three markers are mutually exclusive
 * (`KIND-EXCLUSIVE`), so the order they are tested in is a readability choice
 * rather than a precedence rule.
 *
 * Read through the model's own annotation accessors rather than off the raw
 * annotation bag: they already know that `@CodeSpecKind`'s list argument is
 * `kinds` while `@FollowUpKind`'s is `processes`, and they strip the enum
 * prefix, so the codes here are bare whatever spelling the meta chose. Two
 * readers of the same annotations would be two chances to disagree. */
static CodeSpecsRouting verdict_of(const SpecClass *cls, const char *path) {
  CodeSpecsRouting r;
  r.path = som_strdup(path);
  r.class_name = som_strdup(cls->name);
  r.note = NULL;

  SpecKindLink link;
  if (spec_annotations_code_spec_kind(&cls->annotations, &link)) {
    r.verdict = CODESPECS_VERDICT_FEEDS_CODE;
    r.values = link.kinds;
    r.note = link.note;
    r.declared_at = som_strdup(cls->name);
    return r;
  }
  if (spec_annotations_follow_up_kind(&cls->annotations, &link)) {
    r.verdict = CODESPECS_VERDICT_FEEDS_PROCESS;
    r.values = link.kinds;
    r.note = link.note;
    r.declared_at = som_strdup(cls->name);
    return r;
  }
  SpecNoArtifactLink none;
  if (spec_annotations_no_artifact(&cls->annotations, &none)) {
    r.verdict = CODESPECS_VERDICT_FEEDS_NOTHING;
    som_strlist_init(&r.values);
    som_strlist_push(&r.values, none.reason);
    r.note = none.note;
    r.declared_at = som_strdup(cls->name);
    return r;
  }
  som_strlist_init(&r.values);
  r.declared_at = som_strdup("");
  r.verdict = spec_annotations_have(&cls->annotations, "Document")
                  ? CODESPECS_VERDICT_DOCUMENT_ROOT
                  : CODESPECS_VERDICT_UNROUTED;
  return r;
}

/* A field-level `@CodeSpecKind`, which overrides its class's routing for that
 * field alone. Returns 1 and fills `*out` when the field carries one, 0 when it
 * does not. */
static int field_routing(const SpecClass *cls, const SpecField *field,
                         CodeSpecsRouting *out) {
  SpecKindLink link;
  if (!spec_annotations_code_spec_kind(&field->annotations, &link)) {
    return 0;
  }
  out->path = som_strdup("");
  out->class_name = som_strdup(cls->name);
  out->verdict = CODESPECS_VERDICT_FEEDS_CODE;
  out->values = link.kinds;
  out->note = link.note;
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, cls->name);
  som_buf_putc(&b, '.');
  som_buf_puts(&b, field->name);
  out->declared_at = som_buf_take(&b);
  som_buf_free(&b);
  return 1;
}

/* Appends one entry **per area the routing names** — never deduplicated, because
 * each area's prompt must be self-sufficient (§1.1.1). */
static void emit_value(const CodeSpecsExtractor *e, EntryBuf *entries,
                       const CodeSpecsRouting *routing, const SpecClass *cls,
                       const SpecField *field, const char *path,
                       const char *form_field, const char *headline,
                       const char *value) {
  if (entries == NULL || routing == NULL) {
    return;
  }
  if (value == NULL || value[0] == '\0') {
    return;
  }
  for (size_t i = 0; i < routing->values.len; i++) {
    const CodeSpecsArea *area =
        spec_codespecs_catalog_by_part(e->catalog, routing->values.items[i]);
    if (area == NULL || !area->active) {
      continue;
    }
    CodeSpecsExtractEntry entry;
    entry.area_code = som_strdup(area->code);
    entry.section_id = som_strdup(spec_reflection_field_segment(field));
    entry.headline = dup_opt(headline);
    entry.path = som_strdup(path);
    entry.class_name = som_strdup(cls->name);
    entry.field_name = som_strdup(field->name);
    entry.form_field = dup_opt(form_field);
    entry.routed_by = spec_codespecs_area_kind_value(area);
    entry.routed_at = som_strdup(routing->declared_at);
    entry.routing_note = dup_opt(routing->note);
    entry.value = som_strdup(value);
    entry_buf_push(entries, &entry);
  }
}

/* Records the `ROUTE-TOTAL` violation `cls` at `path` is, when `err` is
 * non-NULL. */
static void fail_unrouted(CodeSpecsExtractError *err, const char *path,
                          const SpecClass *cls) {
  if (err == NULL) {
    return;
  }
  err->failed = 1;
  err->message = som_strdup(
      "section carries none of the three routing verdicts "
      "(@CodeSpecKind / @FollowUpKind / @NoArtifact) — "
      "tom_specs_model_rules.md §10.2 ROUTE-TOTAL");
  err->path = som_strdup(path);
  err->class_name = som_strdup(cls->name);
}

/* The walk. Returns 1 to continue, 0 when `strict` and an unrouted class was
 * reached (the Dart port's throw). */
static int walk(const CodeSpecsExtractor *e, const char *path,
                const SpecClass *cls, const SomStrList *ancestor_types,
                CodeSpecsRoutingList *routings, EntryBuf *entries, int strict,
                CodeSpecsExtractError *err) {
  if (cls == NULL) {
    return 1;
  }
  /* The frame owns its routing for its whole lifetime; the diagnostic list gets
   * a copy. Borrowing the list slot instead would be a pointer into an array a
   * deeper frame can `realloc` out from under this one. */
  CodeSpecsRouting routing = verdict_of(cls, path);
  CodeSpecsRoutingVerdict verdict = routing.verdict;
  const CodeSpecsRouting *class_routing =
      verdict == CODESPECS_VERDICT_FEEDS_CODE ? &routing : NULL;
  if (routings != NULL) {
    routing_list_push(routings, &routing);
  }

  if (verdict == CODESPECS_VERDICT_FEEDS_PROCESS) {
    /* the whole subtree is delivered by a non-generation process */
    spec_codespecs_routing_free(&routing);
    return 1;
  }
  if (verdict == CODESPECS_VERDICT_UNROUTED && strict) {
    fail_unrouted(err, path, cls);
    spec_codespecs_routing_free(&routing);
    return 0;
  }

  /* The enclosing section instance's headline, resolved once per class node
   * (YRD3 stored > YRD4 type default > NULL) and copied onto every entry
   * emitted below it. Copy-only — never a name derivation. */
  const char *stored_headline = spec_document_headline(e->document, path);
  const char *headline =
      stored_headline != NULL
          ? stored_headline
          : (cls->headline[0] != '\0' ? cls->headline : NULL);

  int ok = 1;
  for (size_t i = 0; ok && i < cls->fields_len; i++) {
    const SpecField *field = &cls->fields[i];
    char *field_path =
        spec_path_join(path, spec_reflection_field_segment(field));
    CodeSpecsRouting own_field_routing;
    int has_field_routing = field_routing(cls, field, &own_field_routing);
    const CodeSpecsRouting *routed =
        has_field_routing ? &own_field_routing : class_routing;

    if (strcmp(field->kind, SPEC_FIELD_KIND_CONTENT) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_ENUM) == 0 ||
        strcmp(field->kind, SPEC_FIELD_KIND_SCALAR) == 0) {
      emit_value(e, entries, routed, cls, field, field_path, NULL, headline,
                 spec_document_content(e->document, field_path));
    } else if (strcmp(field->kind, SPEC_FIELD_KIND_FORM) == 0) {
      for (size_t f = 0; f < field->form_fields_len; f++) {
        const char *name = field->form_fields[f].name;
        emit_value(e, entries, routed, cls, field, field_path, name, headline,
                   spec_document_form_field(e->document, field_path, name));
      }
    } else if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0) {
      const SomStrList *items = spec_document_list_items(e->document, field_path);
      size_t item_count = items == NULL ? 0 : items->len;
      for (size_t k = 0; ok && k < item_count; k++) {
        /* The item paths are re-read each step because nothing here mutates the
         * document; the copy keeps the recursion from depending on that. */
        char *item_path = som_strdup(items->items[k]);
        if (field->element_is_complex && field->element_type[0] != '\0' &&
            !som_strlist_contains(ancestor_types, field->element_type)) {
          SomStrList nested;
          som_strlist_copy(&nested, ancestor_types);
          som_strlist_push_copy(&nested, field->element_type);
          ok = walk(e, item_path,
                    spec_model_class_named(e->model, field->element_type),
                    &nested, routings, entries, strict, err);
          som_strlist_free(&nested);
        } else {
          emit_value(e, entries, routed, cls, field, item_path, NULL, headline,
                     spec_document_content(e->document, item_path));
        }
        free(item_path);
      }
    } else if (strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
               strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0) {
      if (field->type[0] != '\0' &&
          !som_strlist_contains(ancestor_types, field->type)) {
        SomStrList nested;
        som_strlist_copy(&nested, ancestor_types);
        som_strlist_push_copy(&nested, field->type);
        ok = walk(e, field_path, spec_model_class_named(e->model, field->type),
                  &nested, routings, entries, strict, err);
        som_strlist_free(&nested);
      }
    }

    if (has_field_routing) {
      spec_codespecs_routing_free(&own_field_routing);
    }
    free(field_path);
  }

  spec_codespecs_routing_free(&routing);
  return ok;
}

static int walk_all(const CodeSpecsExtractor *e, CodeSpecsRoutingList *routings,
                    EntryBuf *entries, int strict, CodeSpecsExtractError *err) {
  /* The factory already failed and said why; this only stops a caller that
   * ignored the error from walking a half-built extractor. */
  if (e->root == NULL) {
    fail_root(err, som_strdup("extractor has no resolved root"), "", "");
    return 0;
  }
  SomStrList ancestors;
  som_strlist_init(&ancestors);
  som_strlist_push_copy(&ancestors, e->root->type);
  int ok = walk(e, spec_reflection_root_segment(e->root),
                spec_model_class_named(e->model, e->root->type), &ancestors,
                routings, entries, strict, err);
  som_strlist_free(&ancestors);
  return ok;
}

void spec_codespecs_extractor_routings(const CodeSpecsExtractor *e,
                                       CodeSpecsRoutingList *out) {
  spec_codespecs_routing_list_init(out);
  walk_all(e, out, NULL, 0, NULL);
}

int spec_codespecs_extractor_extract_all(const CodeSpecsExtractor *e,
                                         CodeSpecsExtractList *out,
                                         CodeSpecsExtractError *err) {
  spec_codespecs_extract_list_init(out);
  EntryBuf entries;
  entry_buf_init(&entries);
  if (!walk_all(e, NULL, &entries, 1, err)) {
    entry_buf_free(&entries);
    return 0;
  }
  const char *root = spec_reflection_root_segment(e->root);
  size_t active = spec_codespecs_catalog_active_area_count(e->catalog);
  for (size_t i = 0; i < active; i++) {
    const CodeSpecsArea *area =
        spec_codespecs_catalog_active_area_at(e->catalog, i);
    CodeSpecsExtract x;
    x.area = area;
    x.catalog_source = som_strdup(e->catalog->source);
    x.document_root = som_strdup(root);
    spec_codespecs_catalog_citable_area_codes(e->catalog, area,
                                              &x.citable_parts);
    spec_codespecs_catalog_projects_for(e->catalog, area, &x.projects);
    x.entries = NULL;
    x.entries_len = 0;
    x.entries_cap = 0;
    for (size_t k = 0; k < entries.len; k++) {
      if (strcmp(entries.items[k].area_code, area->code) == 0) {
        CodeSpecsExtractEntry copy = entry_copy(&entries.items[k]);
        extract_push_entry(&x, &copy);
      }
    }
    extract_list_push(out, &x);
  }
  entry_buf_free(&entries);
  return 1;
}

int spec_codespecs_extractor_extract_for(const CodeSpecsExtractor *e,
                                         const char *area_code,
                                         CodeSpecsExtract *out,
                                         CodeSpecsExtractError *err) {
  CodeSpecsExtractList all;
  if (!spec_codespecs_extractor_extract_all(e, &all, err)) {
    spec_codespecs_extract_list_free(&all);
    return 0;
  }
  int found = 0;
  for (size_t i = 0; i < all.len; i++) {
    if (area_code != NULL && strcmp(all.items[i].area->code, area_code) == 0) {
      *out = all.items[i];
      /* Hand the members over rather than copying them; zeroing the slot keeps
       * the list free below from releasing what `*out` now owns. */
      memset(&all.items[i], 0, sizeof(all.items[i]));
      found = 1;
      break;
    }
  }
  spec_codespecs_extract_list_free(&all);
  return found;
}
