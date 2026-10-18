/* spec_codespecs_records — implementation. See spec_codespecs_records.h; a
 * faithful port of the Dart `spec_codespecs_records.dart`. */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
/* opendir / readdir / stat for `spec_codespecs_extract_set_from_directory`,
 * which strict `-std=c11` hides otherwise. */
#define _POSIX_C_SOURCE 200809L
#endif

#include "spec_codespecs_records.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#endif

#include "som_json.h"
#include "yaml.h"

/* ---- the error ----------------------------------------------------------- */

void spec_codespecs_record_error_init(CodeSpecsRecordError *e) {
  if (e == NULL) {
    return;
  }
  e->failed = 0;
  e->message = NULL;
}

void spec_codespecs_record_error_free(CodeSpecsRecordError *e) {
  if (e == NULL) {
    return;
  }
  free(e->message);
  spec_codespecs_record_error_init(e);
}

int spec_codespecs_record_error_is_ok(const CodeSpecsRecordError *e) {
  return e == NULL || !e->failed;
}

char *spec_codespecs_record_error_string(const CodeSpecsRecordError *e) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CodeSpecsRecordError: ");
  som_buf_puts(&b, e != NULL && e->message != NULL ? e->message : "");
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

/* Records a failure in `*err` (when non-NULL), replacing any earlier one, and
 * returns 0 so every failing branch is `return fail(...)`. */
static int fail(CodeSpecsRecordError *err, const char *fmt, ...) {
  if (err == NULL) {
    return 0;
  }
  va_list ap;
  va_start(ap, fmt);
  int n = vsnprintf(NULL, 0, fmt, ap);
  va_end(ap);
  char *msg = (char *)malloc(n > 0 ? (size_t)n + 1 : 1);
  msg[0] = '\0';
  if (n > 0) {
    va_start(ap, fmt);
    vsnprintf(msg, (size_t)n + 1, fmt, ap);
    va_end(ap);
  }
  free(err->message);
  err->failed = 1;
  err->message = msg;
  return 0;
}

/* ---- YAML access --------------------------------------------------------- */

/* How a YAML node reads under the core schema the Dart reader uses. */
typedef enum { NODE_NULL, NODE_STR, NODE_INT, NODE_MAP, NODE_SEQ, NODE_OTHER } NodeKind;

/* A plain scalar YAML 1.2's core schema reads as a float (`2.5`, `1e3`,
 * `.inf`, `.nan`). Plain integers are already integers in the reader. */
static int plain_is_float(const char *s) {
  static const char *const special[] = {".inf", "+.inf", "-.inf", ".Inf",
                                        "+.Inf", "-.Inf", ".INF", "+.INF",
                                        "-.INF", ".nan", ".NaN", ".NAN"};
  for (size_t i = 0; i < sizeof(special) / sizeof(special[0]); i++) {
    if (strcmp(s, special[i]) == 0) {
      return 1;
    }
  }
  const char *p = s;
  if (*p == '+' || *p == '-') {
    p++;
  }
  int digits = 0;
  while (*p >= '0' && *p <= '9') {
    p++;
    digits++;
  }
  if (*p == '.') {
    p++;
    while (*p >= '0' && *p <= '9') {
      p++;
      digits++;
    }
  }
  if (digits == 0) {
    return 0;
  }
  if (*p == 'e' || *p == 'E') {
    p++;
    if (*p == '+' || *p == '-') {
      p++;
    }
    if (!(*p >= '0' && *p <= '9')) {
      return 0;
    }
    while (*p >= '0' && *p <= '9') {
      p++;
    }
  }
  return *p == '\0';
}

/* The node's kind. An absent node, a plain `null` / `~`, and a key written with
 * no value (which the reader yields as an empty mapping) read as null. */
static NodeKind node_kind(const YamlValue *v) {
  if (v == NULL) {
    return NODE_NULL;
  }
  switch (v->type) {
    case YAML_MAP:
      return v->as.map.len == 0 ? NODE_NULL : NODE_MAP;
    case YAML_SEQ:
      return NODE_SEQ;
    case YAML_INT:
      return NODE_INT;
    case YAML_NULL:
      return NODE_NULL;
    case YAML_STR:
      if (v->plain) {
        const char *s = v->as.str;
        if (strcmp(s, "null") == 0 || strcmp(s, "Null") == 0 ||
            strcmp(s, "NULL") == 0 || strcmp(s, "~") == 0 || s[0] == '\0') {
          return NODE_NULL;
        }
        if (strcmp(s, "true") == 0 || strcmp(s, "True") == 0 ||
            strcmp(s, "TRUE") == 0 || strcmp(s, "false") == 0 ||
            strcmp(s, "False") == 0 || strcmp(s, "FALSE") == 0 ||
            plain_is_float(s)) {
          return NODE_OTHER;
        }
      }
      return NODE_STR;
    case YAML_BOOL:
    case YAML_FLOAT:
      return NODE_OTHER;
  }
  return NODE_OTHER;
}

/* The value as Dart's string interpolation renders it, for messages. Owned. */
static char *node_text(const YamlValue *v) {
  if (node_kind(v) == NODE_NULL) {
    return som_strdup("null");
  }
  return yaml_scalar_string(v);
}

/* `_str`: "" for null, the string for a string; otherwise an error. Writes an
 * owned string to `*out` on success. */
static int read_str(const YamlValue *v, const char *name, const char *key,
                    char **out, CodeSpecsRecordError *err) {
  NodeKind k = node_kind(v);
  if (k == NODE_NULL) {
    *out = som_strdup("");
    return 1;
  }
  if (k == NODE_STR) {
    *out = som_strdup(v->as.str);
    return 1;
  }
  return fail(err, "%s: `%s` must be a string", name, key);
}

/* `_optStr`: NULL for null, the string for a string; otherwise an error. */
static int read_opt_str(const YamlValue *v, const char *name, const char *key,
                        char **out, CodeSpecsRecordError *err) {
  NodeKind k = node_kind(v);
  if (k == NODE_NULL) {
    *out = NULL;
    return 1;
  }
  if (k == NODE_STR) {
    *out = som_strdup(v->as.str);
    return 1;
  }
  return fail(err, "%s: `%s` must be a string or null", name, key);
}

/* A non-empty flow list (`["a", "b"]`, `[5]`) as the reader hands it over — a
 * plain scalar — decoded as the JSON the extract writer emits it as. NULL when
 * `v` is not such a scalar or does not decode to a JSON array. Owned. */
static SomJson *flow_list(const YamlValue *v) {
  if (v == NULL || v->type != YAML_STR || !v->plain || v->as.str[0] != '[') {
    return NULL;
  }
  char *perr = NULL;
  SomJson *j = som_json_parse(v->as.str, &perr);
  free(perr);
  if (j != NULL && j->type != SOM_JSON_ARRAY) {
    som_json_free(j);
    return NULL;
  }
  return j;
}

/* `_strList`: empty for null; each element through `_str`. */
static int read_str_list(const YamlValue *v, const char *name, const char *key,
                         SomStrList *out, CodeSpecsRecordError *err) {
  som_strlist_init(out);
  if (node_kind(v) == NODE_NULL) {
    return 1;
  }
  if (v->type == YAML_SEQ) {
    for (size_t i = 0; i < v->as.seq.len; i++) {
      char *s = NULL;
      if (!read_str(v->as.seq.items[i], name, key, &s, err)) {
        som_strlist_free(out);
        return 0;
      }
      som_strlist_push(out, s);
    }
    return 1;
  }
  SomJson *j = flow_list(v);
  if (j == NULL) {
    return fail(err, "%s: `%s` must be a list", name, key);
  }
  for (size_t i = 0; i < j->as.array.len; i++) {
    const SomJson *e = j->as.array.items[i];
    if (e->type == SOM_JSON_NULL) {
      som_strlist_push_copy(out, "");
    } else if (e->type == SOM_JSON_STR) {
      som_strlist_push_copy(out, e->as.str);
    } else {
      som_json_free(j);
      som_strlist_free(out);
      return fail(err, "%s: `%s` must be a string", name, key);
    }
  }
  som_json_free(j);
  return 1;
}

/* `_intList`: empty for null; every element must be an integer. Writes an owned
 * array (NULL when empty). */
static int read_int_list(const YamlValue *v, const char *name, const char *key,
                         long long **items, size_t *len,
                         CodeSpecsRecordError *err) {
  *items = NULL;
  *len = 0;
  if (node_kind(v) == NODE_NULL) {
    return 1;
  }
  if (v->type == YAML_SEQ) {
    if (v->as.seq.len == 0) {
      return 1;
    }
    long long *out = (long long *)calloc(v->as.seq.len, sizeof(long long));
    for (size_t i = 0; i < v->as.seq.len; i++) {
      if (node_kind(v->as.seq.items[i]) != NODE_INT) {
        free(out);
        return fail(err, "%s: `%s` must hold integers", name, key);
      }
      out[i] = v->as.seq.items[i]->as.integer;
    }
    *items = out;
    *len = v->as.seq.len;
    return 1;
  }
  SomJson *j = flow_list(v);
  if (j == NULL) {
    return fail(err, "%s: `%s` must be a list", name, key);
  }
  size_t n = j->as.array.len;
  long long *out = n > 0 ? (long long *)calloc(n, sizeof(long long)) : NULL;
  for (size_t i = 0; i < n; i++) {
    const SomJson *e = j->as.array.items[i];
    if (e->type != SOM_JSON_INT) {
      free(out);
      som_json_free(j);
      return fail(err, "%s: `%s` must hold integers", name, key);
    }
    out[i] = e->as.integer;
  }
  som_json_free(j);
  *items = out;
  *len = n;
  return 1;
}

/* Whether `text` holds no YAML content at all (blank and comment lines only) —
 * the reader's empty mapping there is Dart's null document. */
static int yaml_text_is_empty(const char *text) {
  const char *p = text;
  while (*p != '\0') {
    while (*p == ' ' || *p == '\t' || *p == '\r') {
      p++;
    }
    if (*p != '\n' && *p != '\0' && *p != '#') {
      return 0;
    }
    while (*p != '\n' && *p != '\0') {
      p++;
    }
    if (*p == '\n') {
      p++;
    }
  }
  return 1;
}

/* `_rootMapping`: parses `text` and returns its `key:` mapping (borrowed from
 * `*doc`, which the caller frees). NULL on failure, with `*doc` already freed. */
static const YamlValue *root_mapping(const char *text, const char *name,
                                     const char *key, YamlValue **doc,
                                     CodeSpecsRecordError *err) {
  *doc = yaml_parse(text != NULL ? text : "");
  if ((*doc)->type != YAML_MAP || yaml_text_is_empty(text != NULL ? text : "")) {
    yaml_value_free(*doc);
    *doc = NULL;
    fail(err, "%s does not hold a YAML mapping", name);
    return NULL;
  }
  const YamlValue *root = yaml_get(*doc, key);
  if (node_kind(root) != NODE_MAP) {
    yaml_value_free(*doc);
    *doc = NULL;
    fail(err, "%s has no top-level `%s:` mapping", name, key);
    return NULL;
  }
  return root;
}

/* ---- extract files ------------------------------------------------------- */

static void entry_push(CodeSpecsExtract *x, const CodeSpecsExtractEntry *e) {
  if (x->entries_len == x->entries_cap) {
    x->entries_cap = x->entries_cap ? x->entries_cap * 2 : 8;
    x->entries = (CodeSpecsExtractEntry *)realloc(
        x->entries, x->entries_cap * sizeof(CodeSpecsExtractEntry));
  }
  x->entries[x->entries_len++] = *e;
}

/* Reads one entry mapping into `*e` (zeroed by the caller), in the Dart
 * constructor's argument order so the first bad key is the one reported. */
static int read_entry(const YamlValue *raw, const char *name, const char *code,
                      CodeSpecsExtractEntry *e, CodeSpecsRecordError *err) {
  e->area_code = som_strdup(code);
  return read_str(yaml_get(raw, "sectionId"), name, "entries[].sectionId",
                  &e->section_id, err) &&
         read_opt_str(yaml_get(raw, "headline"), name, "entries[].headline",
                      &e->headline, err) &&
         read_opt_str(yaml_get(raw, "instanceId"), name,
                      "entries[].instanceId", &e->instance_id, err) &&
         read_str(yaml_get(raw, "path"), name, "entries[].path", &e->path,
                  err) &&
         read_str(yaml_get(raw, "className"), name, "entries[].className",
                  &e->class_name, err) &&
         read_str(yaml_get(raw, "fieldName"), name, "entries[].fieldName",
                  &e->field_name, err) &&
         read_opt_str(yaml_get(raw, "formField"), name, "entries[].formField",
                      &e->form_field, err) &&
         read_str(yaml_get(raw, "routedBy"), name, "entries[].routedBy",
                  &e->routed_by, err) &&
         read_str(yaml_get(raw, "routedAt"), name, "entries[].routedAt",
                  &e->routed_at, err) &&
         read_opt_str(yaml_get(raw, "routingNote"), name,
                      "entries[].routingNote", &e->routing_note, err) &&
         read_str(yaml_get(raw, "value"), name, "entries[].value", &e->value,
                  err);
}

/* The body of `spec_codespecs_extract_from_yaml`, filling `*x` (zeroed, with
 * `owned_area` allocated) and leaving cleanup on failure to the caller. */
static int read_extract(const YamlValue *root, const char *name,
                        CodeSpecsExtract *x, CodeSpecsRecordError *err) {
  const YamlValue *version = yaml_get(root, "formatVersion");
  if (node_kind(version) != NODE_INT ||
      version->as.integer != SPEC_CODESPECS_EXTRACT_FORMAT) {
    char *v = node_text(version);
    fail(err,
         "%s declares extract format %s; this reader understands %d only — "
         "reading it would silently drop entries",
         name, v, SPEC_CODESPECS_EXTRACT_FORMAT);
    free(v);
    return 0;
  }
  const YamlValue *area = yaml_get(root, "area");
  if (node_kind(area) != NODE_MAP) {
    return fail(err, "%s has no `area:` mapping", name);
  }
  CodeSpecsArea *a = x->owned_area;
  if (!read_str(yaml_get(area, "code"), name, "area.code", &a->code, err)) {
    return 0;
  }
  if (a->code[0] == '\0') {
    return fail(err, "%s names no area code", name);
  }
  char *part = NULL;
  if (!read_str(yaml_get(area, "part"), name, "area.part", &part, err)) {
    return 0;
  }
  static const char prefix[] = "CodeSpecPart.";
  if (strncmp(part, prefix, sizeof(prefix) - 1) == 0) {
    a->part = som_strdup(part + sizeof(prefix) - 1);
    free(part);
  } else {
    a->part = part;
  }
  const YamlValue *document = yaml_get(root, "document");
  NodeKind dk = node_kind(document);
  if (dk != NODE_NULL && dk != NODE_MAP) {
    return fail(err, "%s: `document` must be a mapping", name);
  }
  const YamlValue *entries = yaml_get(root, "entries");
  NodeKind ek = node_kind(entries);
  if (ek != NODE_NULL && ek != NODE_SEQ) {
    return fail(err, "%s: `entries` must be a list", name);
  }
  if (ek == NODE_SEQ) {
    for (size_t i = 0; i < entries->as.seq.len; i++) {
      const YamlValue *raw = entries->as.seq.items[i];
      if (node_kind(raw) != NODE_MAP) {
        return fail(err, "%s has an entry that is not a mapping", name);
      }
      CodeSpecsExtractEntry e;
      memset(&e, 0, sizeof(e));
      if (!read_entry(raw, name, a->code, &e, err)) {
        spec_codespecs_extract_entry_free(&e);
        return 0;
      }
      entry_push(x, &e);
    }
  }
  const YamlValue *declared =
      dk == NODE_MAP ? yaml_get(document, "entryCount") : NULL;
  if (node_kind(declared) != NODE_NULL &&
      (node_kind(declared) != NODE_INT ||
       declared->as.integer != (long long)x->entries_len)) {
    char *d = node_text(declared);
    fail(err,
         "%s declares entryCount %s but carries %zu entries — a truncated "
         "extract must not read as a complete one",
         name, d, x->entries_len);
    free(d);
    return 0;
  }
  a->active = 1;
  return read_str(yaml_get(area, "canonicalId"), name, "area.canonicalId",
                  &a->canonical_id, err) &&
         read_str_list(yaml_get(area, "annotations"), name, "area.annotations",
                       &a->annotations, err) &&
         read_str(yaml_get(area, "builtOn"), name, "area.builtOn", &a->built_on,
                  err) &&
         read_str(yaml_get(area, "attributeSurface"), name,
                  "area.attributeSurface", &a->attribute_surface, err) &&
         read_int_list(yaml_get(area, "slices"), name, "area.slices",
                       &a->slices, &a->slices_len, err) &&
         read_int_list(yaml_get(area, "authoringSteps"), name,
                       "area.authoringSteps", &a->authoring_steps,
                       &a->authoring_steps_len, err) &&
         read_str(dk == NODE_MAP ? yaml_get(document, "root") : NULL, name,
                  "document.root", &x->document_root, err) &&
         read_str(yaml_get(root, "catalogSource"), name, "catalogSource",
                  &x->catalog_source, err) &&
         read_str_list(yaml_get(area, "projects"), name, "area.projects",
                       &x->projects, err) &&
         read_str_list(yaml_get(area, "citableParts"), name,
                       "area.citableParts", &x->citable_parts, err);
}

int spec_codespecs_extract_from_yaml(const char *text, const char *source,
                                     CodeSpecsExtract *out,
                                     CodeSpecsRecordError *err) {
  memset(out, 0, sizeof(*out));
  const char *name =
      (source == NULL || source[0] == '\0') ? "the extract" : source;
  YamlValue *doc = NULL;
  const YamlValue *root = root_mapping(text, name, "extract", &doc, err);
  if (root == NULL) {
    return 0;
  }
  out->owned_area = (CodeSpecsArea *)calloc(1, sizeof(CodeSpecsArea));
  out->area = out->owned_area;
  int ok = read_extract(root, name, out, err);
  yaml_value_free(doc);
  if (!ok) {
    spec_codespecs_extract_free(out);
    return 0;
  }
  return 1;
}

/* ---- the gate record ----------------------------------------------------- */

const char *spec_codespecs_gate_verdict_word(CodeSpecsGateVerdict v) {
  switch (v) {
    case CODESPECS_GATE_SUFFICIENT:
      return "sufficient";
    case CODESPECS_GATE_NOT_APPLICABLE:
      return "not applicable";
    case CODESPECS_GATE_INSUFFICIENT:
      return "insufficient";
  }
  return "";
}

int spec_codespecs_gate_verdict_parse(const char *word,
                                      CodeSpecsGateVerdict *out) {
  if (word == NULL) {
    return 0;
  }
  if (strcmp(word, "sufficient") == 0) {
    *out = CODESPECS_GATE_SUFFICIENT;
  } else if (strcmp(word, "not applicable") == 0) {
    *out = CODESPECS_GATE_NOT_APPLICABLE;
  } else if (strcmp(word, "insufficient") == 0) {
    *out = CODESPECS_GATE_INSUFFICIENT;
  } else {
    return 0;
  }
  return 1;
}

int spec_codespecs_gate_entry_descoped(const CodeSpecsGateEntry *e) {
  return e->resolution != NULL &&
         strcmp(e->resolution, SPEC_CODESPECS_GATE_DESCOPED) == 0;
}

char *spec_codespecs_gate_gap_line(const CodeSpecsGateGap *g) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, g->section_id != NULL ? g->section_id : "");
  som_buf_puts(&b, " — ");
  som_buf_puts(&b, g->required != NULL ? g->required : "");
  som_buf_puts(&b, " — should have been carried by ");
  som_buf_puts(&b, g->carrier != NULL ? g->carrier : "");
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

void spec_codespecs_gate_gap_free(CodeSpecsGateGap *g) {
  if (g == NULL) {
    return;
  }
  free(g->section_id);
  free(g->required);
  free(g->carrier);
  memset(g, 0, sizeof(*g));
}

void spec_codespecs_gate_entry_free(CodeSpecsGateEntry *e) {
  if (e == NULL) {
    return;
  }
  free(e->area);
  free(e->resolution);
  free(e->note);
  for (size_t i = 0; i < e->gaps_len; i++) {
    spec_codespecs_gate_gap_free(&e->gaps[i]);
  }
  free(e->gaps);
  memset(e, 0, sizeof(*e));
}

static char *dup_opt(const char *s) { return s == NULL ? NULL : som_strdup(s); }

static char *dup_or_empty(const char *s) { return som_strdup(s != NULL ? s : ""); }

static CodeSpecsGateEntry gate_entry_copy(const CodeSpecsGateEntry *e) {
  CodeSpecsGateEntry c;
  c.area = dup_or_empty(e->area);
  c.verdict = e->verdict;
  c.resolution = dup_opt(e->resolution);
  c.note = dup_opt(e->note);
  c.gaps = NULL;
  c.gaps_len = 0;
  if (e->gaps_len > 0) {
    c.gaps = (CodeSpecsGateGap *)calloc(e->gaps_len, sizeof(CodeSpecsGateGap));
    for (size_t i = 0; i < e->gaps_len; i++) {
      c.gaps[i].section_id = dup_or_empty(e->gaps[i].section_id);
      c.gaps[i].required = dup_or_empty(e->gaps[i].required);
      c.gaps[i].carrier = dup_or_empty(e->gaps[i].carrier);
    }
    c.gaps_len = e->gaps_len;
  }
  return c;
}

void spec_codespecs_gate_record_free(CodeSpecsGateRecord *r) {
  if (r == NULL) {
    return;
  }
  for (size_t i = 0; i < r->verdicts_len; i++) {
    spec_codespecs_gate_entry_free(&r->verdicts[i]);
  }
  free(r->verdicts);
  r->verdicts = NULL;
  r->verdicts_len = 0;
}

/* `^CE-[A-Z]+$`. */
static int is_area_code(const char *s) {
  if (strncmp(s, "CE-", 3) != 0 || s[3] == '\0') {
    return 0;
  }
  for (const char *p = s + 3; *p != '\0'; p++) {
    if (*p < 'A' || *p > 'Z') {
      return 0;
    }
  }
  return 1;
}

/* Dart's `\s` over ASCII: space, tab, newline, vertical tab, form feed and
 * carriage return. */
static int is_space_char(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' ||
         c == '\r';
}

/* Whether `s` is all whitespace (`value.trim().isEmpty`). */
static int is_blank(const char *s) {
  for (const char *p = s; *p != '\0'; p++) {
    if (!is_space_char(*p)) {
      return 0;
    }
  }
  return 1;
}

/* `^[^\s.]+(\.[^\s.]+)+$`: `<section-id>.<field>` — two or more dot-separated
 * parts, none empty, no whitespace. */
static int is_carrier(const char *s) {
  size_t part = 0;
  size_t parts = 1;
  for (const char *p = s; *p != '\0'; p++) {
    if (is_space_char(*p)) {
      return 0;
    }
    if (*p == '.') {
      if (part == 0) {
        return 0;
      }
      parts++;
      part = 0;
    } else {
      part++;
    }
  }
  return part > 0 && parts >= 2;
}

/* The constructor's `_check`. */
static int gate_check(const CodeSpecsGateRecord *r, const char *source,
                      CodeSpecsRecordError *err) {
  for (size_t i = 0; i < r->verdicts_len; i++) {
    const CodeSpecsGateEntry *e = &r->verdicts[i];
    if (e->area[0] == '\0') {
      return fail(err, "%s has a verdict that names no area", source);
    }
    if (!is_area_code(e->area)) {
      return fail(err, "%s names the area `%s`, which is not a CE-* code",
                  source, e->area);
    }
    for (size_t k = 0; k < i; k++) {
      if (strcmp(r->verdicts[k].area, e->area) == 0) {
        return fail(err,
                    "%s carries two verdicts for %s — a scope with two "
                    "answers for one area is no scope",
                    source, e->area);
      }
    }
    if (e->gaps_len > 0 && e->verdict != CODESPECS_GATE_INSUFFICIENT) {
      return fail(err,
                  "%s gives %s gap lines on verdict `%s` — only an "
                  "insufficient area has missing inputs",
                  source, e->area, spec_codespecs_gate_verdict_word(e->verdict));
    }
    for (size_t g = 0; g < e->gaps_len; g++) {
      const CodeSpecsGateGap *gap = &e->gaps[g];
      const char *names[3] = {"sectionId", "required", "carrier"};
      const char *values[3] = {gap->section_id, gap->required, gap->carrier};
      for (int f = 0; f < 3; f++) {
        if (values[f] == NULL || is_blank(values[f])) {
          return fail(err,
                      "%s has a gap of %s with no `%s` — a gap line "
                      "names the section, what was required and its carrier",
                      source, e->area, names[f]);
        }
      }
      if (!is_carrier(gap->carrier)) {
        return fail(err,
                    "%s gives a gap of %s the carrier `%s` — a carrier "
                    "is `<section-id>.<field>`",
                    source, e->area, gap->carrier);
      }
    }
    if (e->resolution == NULL) {
      continue;
    }
    if (e->verdict != CODESPECS_GATE_INSUFFICIENT) {
      return fail(err,
                  "%s gives %s a `resolution:` on verdict `%s` — only an "
                  "insufficient area has an L0 decision to resolve",
                  source, e->area, spec_codespecs_gate_verdict_word(e->verdict));
    }
    if (strcmp(e->resolution, SPEC_CODESPECS_GATE_DESCOPED) != 0) {
      return fail(err,
                  "%s gives %s the resolution `%s` — `descoped` is the one "
                  "resolution that admits a partial pass; any other "
                  "resolution means the area was completed and its verdict "
                  "re-taken",
                  source, e->area, e->resolution);
    }
  }
  return 1;
}

/* Takes ownership of `entries` (`len` of them) into `*out` and checks it; on
 * failure frees them and leaves `*out` empty. */
static int gate_adopt(CodeSpecsGateEntry *entries, size_t len,
                      const char *source, CodeSpecsGateRecord *out,
                      CodeSpecsRecordError *err) {
  out->verdicts = entries;
  out->verdicts_len = len;
  if (!gate_check(out, source != NULL ? source : SPEC_CODESPECS_GATE_RECORD_FILE,
                  err)) {
    spec_codespecs_gate_record_free(out);
    return 0;
  }
  return 1;
}

int spec_codespecs_gate_record_make(const CodeSpecsGateEntry *verdicts,
                                    size_t len, const char *source,
                                    CodeSpecsGateRecord *out,
                                    CodeSpecsRecordError *err) {
  CodeSpecsGateEntry *copy =
      len > 0 ? (CodeSpecsGateEntry *)calloc(len, sizeof(CodeSpecsGateEntry))
              : NULL;
  for (size_t i = 0; i < len; i++) {
    copy[i] = gate_entry_copy(&verdicts[i]);
  }
  return gate_adopt(copy, len, source, out, err);
}

/* `_gaps`: the optional `gaps:` list of the entry `e` (area already read).
 * Fills `e->gaps` / `e->gaps_len` — owned by the entry, so the caller's entry
 * free releases a partial list on failure. */
static int read_gaps(const YamlValue *raw, const char *source,
                     CodeSpecsGateEntry *e, CodeSpecsRecordError *err) {
  if (node_kind(raw) == NODE_NULL) {
    return 1;
  }
  if (node_kind(raw) != NODE_SEQ) {
    return fail(err, "%s: `%s` has `gaps:` that is not a list", source,
                e->area);
  }
  if (raw->as.seq.len == 0) {
    return 1;
  }
  e->gaps = (CodeSpecsGateGap *)calloc(raw->as.seq.len, sizeof(CodeSpecsGateGap));
  for (size_t i = 0; i < raw->as.seq.len; i++) {
    const YamlValue *g = raw->as.seq.items[i];
    if (node_kind(g) != NODE_MAP) {
      return fail(err, "%s: `%s` has a gap that is not a mapping", source,
                  e->area);
    }
    for (size_t k = 0; k < g->as.map.len; k++) {
      const char *key = g->as.map.entries[k].key;
      if (strcmp(key, "sectionId") != 0 && strcmp(key, "required") != 0 &&
          strcmp(key, "carrier") != 0) {
        return fail(err,
                    "%s has an unknown key `%s` in a gap of %s — a gap "
                    "knows `sectionId`, `required` and `carrier` only",
                    source, key, e->area);
      }
    }
    CodeSpecsGateGap *gap = &e->gaps[i];
    e->gaps_len = i + 1; /* so the entry free releases this slot on failure */
    if (!read_str(yaml_get(g, "sectionId"), source, "gaps[].sectionId",
                  &gap->section_id, err) ||
        !read_str(yaml_get(g, "required"), source, "gaps[].required",
                  &gap->required, err) ||
        !read_str(yaml_get(g, "carrier"), source, "gaps[].carrier",
                  &gap->carrier, err)) {
      return 0;
    }
  }
  return 1;
}

/* The body of `spec_codespecs_gate_record_from_yaml` past the root mapping.
 * Appends to `*entries` / `*len` (freed by the caller on failure). */
static int read_gate(const YamlValue *root, const char *source,
                     CodeSpecsGateEntry **entries, size_t *len,
                     CodeSpecsRecordError *err) {
  for (size_t i = 0; i < root->as.map.len; i++) {
    const char *key = root->as.map.entries[i].key;
    if (strcmp(key, "formatVersion") != 0 && strcmp(key, "verdicts") != 0) {
      return fail(err,
                  "%s has an unknown key `gate.%s` — the record knows "
                  "`formatVersion` and `verdicts` only",
                  source, key);
    }
  }
  const YamlValue *version = yaml_get(root, "formatVersion");
  if (node_kind(version) != NODE_INT ||
      version->as.integer != SPEC_CODESPECS_GATE_RECORD_FORMAT) {
    char *v = node_text(version);
    fail(err,
         "%s declares gate record format %s; this reader understands %d only "
         "— reading it would silently change the scope",
         source, v, SPEC_CODESPECS_GATE_RECORD_FORMAT);
    free(v);
    return 0;
  }
  const YamlValue *list = yaml_get(root, "verdicts");
  if (node_kind(list) != NODE_SEQ) {
    return fail(err, "%s has no `verdicts:` list", source);
  }
  if (list->as.seq.len > 0) {
    *entries = (CodeSpecsGateEntry *)calloc(list->as.seq.len,
                                            sizeof(CodeSpecsGateEntry));
  }
  for (size_t i = 0; i < list->as.seq.len; i++) {
    const YamlValue *raw = list->as.seq.items[i];
    if (node_kind(raw) != NODE_MAP) {
      return fail(err, "%s has a verdict that is not a mapping", source);
    }
    for (size_t k = 0; k < raw->as.map.len; k++) {
      const char *key = raw->as.map.entries[k].key;
      if (strcmp(key, "area") != 0 && strcmp(key, "verdict") != 0 &&
          strcmp(key, "resolution") != 0 && strcmp(key, "gaps") != 0 &&
          strcmp(key, "note") != 0) {
        return fail(err,
                    "%s has an unknown key `%s` in a verdict — an entry knows "
                    "`area`, `verdict`, `resolution`, `gaps` and `note` only",
                    source, key);
      }
    }
    CodeSpecsGateEntry *e = &(*entries)[i];
    *len = i + 1; /* so the caller frees this slot's strings on failure */
    char *word = NULL;
    if (!read_str(yaml_get(raw, "area"), source, "verdicts[].area", &e->area,
                  err) ||
        !read_str(yaml_get(raw, "verdict"), source, "verdicts[].verdict", &word,
                  err)) {
      return 0;
    }
    if (!spec_codespecs_gate_verdict_parse(word, &e->verdict)) {
      fail(err,
           "%s gives %s the verdict `%s` — codespecs_prompt.md §6.2 knows "
           "`sufficient`, `not applicable` and `insufficient` only",
           source, e->area, word);
      free(word);
      return 0;
    }
    free(word);
    if (!read_opt_str(yaml_get(raw, "resolution"), source,
                      "verdicts[].resolution", &e->resolution, err) ||
        !read_opt_str(yaml_get(raw, "note"), source, "verdicts[].note",
                      &e->note, err) ||
        !read_gaps(yaml_get(raw, "gaps"), source, e, err)) {
      return 0;
    }
  }
  *len = list->as.seq.len;
  return 1;
}

int spec_codespecs_gate_record_from_yaml(const char *text, const char *source,
                                         CodeSpecsGateRecord *out,
                                         CodeSpecsRecordError *err) {
  out->verdicts = NULL;
  out->verdicts_len = 0;
  const char *name = source != NULL ? source : SPEC_CODESPECS_GATE_RECORD_FILE;
  YamlValue *doc = NULL;
  const YamlValue *root = root_mapping(text, name, "gate", &doc, err);
  if (root == NULL) {
    return 0;
  }
  CodeSpecsGateEntry *entries = NULL;
  size_t len = 0;
  int ok = read_gate(root, name, &entries, &len, err);
  yaml_value_free(doc);
  if (!ok) {
    for (size_t i = 0; i < len; i++) {
      spec_codespecs_gate_entry_free(&entries[i]);
    }
    free(entries);
    return 0;
  }
  return gate_adopt(entries, len, name, out, err);
}

const CodeSpecsGateEntry *
spec_codespecs_gate_record_verdict_for(const CodeSpecsGateRecord *r,
                                       const char *area) {
  if (area == NULL) {
    return NULL;
  }
  for (size_t i = 0; i < r->verdicts_len; i++) {
    if (strcmp(r->verdicts[i].area, area) == 0) {
      return &r->verdicts[i];
    }
  }
  return NULL;
}

int spec_codespecs_gate_record_check_against(const CodeSpecsGateRecord *r,
                                             const CodeSpecsAreaCatalog *catalog,
                                             const char *source,
                                             CodeSpecsRecordError *err) {
  const char *name = source != NULL ? source : SPEC_CODESPECS_GATE_RECORD_FILE;
  for (size_t i = 0; i < r->verdicts_len; i++) {
    const CodeSpecsArea *area =
        spec_codespecs_catalog_by_code(catalog, r->verdicts[i].area);
    if (area == NULL || !area->active) {
      return fail(err,
                  "%s gives a verdict for %s, which is not an active area of "
                  "the catalogue",
                  name, r->verdicts[i].area);
    }
  }
  return 1;
}

int spec_codespecs_gate_record_with_verdict(const CodeSpecsGateRecord *r,
                                            const CodeSpecsGateEntry *entry,
                                            CodeSpecsGateRecord *out,
                                            CodeSpecsRecordError *err) {
  size_t cap = r->verdicts_len + 1;
  CodeSpecsGateEntry *items =
      (CodeSpecsGateEntry *)calloc(cap, sizeof(CodeSpecsGateEntry));
  size_t len = 0;
  int replaced = 0;
  for (size_t i = 0; i < r->verdicts_len; i++) {
    if (strcmp(r->verdicts[i].area, entry->area) == 0) {
      items[len++] = gate_entry_copy(entry);
      replaced = 1;
    } else {
      items[len++] = gate_entry_copy(&r->verdicts[i]);
    }
  }
  if (!replaced) {
    items[len++] = gate_entry_copy(entry);
  }
  return gate_adopt(items, len, NULL, out, err);
}

char *spec_codespecs_gate_record_to_yaml(const CodeSpecsGateRecord *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "gate:\n  formatVersion: ");
  som_buf_puti(&b, SPEC_CODESPECS_GATE_RECORD_FORMAT);
  som_buf_putc(&b, '\n');
  if (r->verdicts_len == 0) {
    som_buf_puts(&b, "  verdicts: []\n");
  } else {
    som_buf_puts(&b, "  verdicts:\n");
    for (size_t i = 0; i < r->verdicts_len; i++) {
      const CodeSpecsGateEntry *e = &r->verdicts[i];
      som_buf_puts(&b, "    - area: ");
      som_buf_puts(&b, e->area);
      som_buf_puts(&b, "\n      verdict: ");
      som_buf_puts(&b, spec_codespecs_gate_verdict_word(e->verdict));
      som_buf_putc(&b, '\n');
      if (e->resolution != NULL) {
        som_buf_puts(&b, "      resolution: ");
        som_buf_puts(&b, e->resolution);
        som_buf_putc(&b, '\n');
      }
      if (e->gaps_len > 0) {
        som_buf_puts(&b, "      gaps:\n");
        for (size_t g = 0; g < e->gaps_len; g++) {
          char *sid = spec_codespecs_yaml_string(e->gaps[g].section_id);
          char *req = spec_codespecs_yaml_string(e->gaps[g].required);
          char *car = spec_codespecs_yaml_string(e->gaps[g].carrier);
          som_buf_puts(&b, "        - sectionId: ");
          som_buf_puts(&b, sid);
          som_buf_puts(&b, "\n          required: ");
          som_buf_puts(&b, req);
          som_buf_puts(&b, "\n          carrier: ");
          som_buf_puts(&b, car);
          som_buf_putc(&b, '\n');
          free(sid);
          free(req);
          free(car);
        }
      }
      if (e->note != NULL) {
        char *q = spec_codespecs_yaml_string(e->note);
        som_buf_puts(&b, "      note: ");
        som_buf_puts(&b, q);
        som_buf_putc(&b, '\n');
        free(q);
      }
    }
  }
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

/* ---- a tree of extracts, scoped by its gate record ----------------------- */

void spec_codespecs_extract_set_free(CodeSpecsExtractSet *s) {
  if (s == NULL) {
    return;
  }
  spec_codespecs_extract_list_free(&s->extracts);
  som_strlist_free(&s->sources);
  for (size_t i = 0; i < s->excluded_len; i++) {
    free(s->excluded[i].area);
    free(s->excluded[i].source);
  }
  free(s->excluded);
  spec_codespecs_gate_record_free(&s->gate);
  memset(s, 0, sizeof(*s));
}

static void set_push_extract(CodeSpecsExtractList *l, CodeSpecsExtract *x) {
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 8;
    l->items =
        (CodeSpecsExtract *)realloc(l->items, l->cap * sizeof(CodeSpecsExtract));
  }
  l->items[l->len++] = *x;
  memset(x, 0, sizeof(*x));
}

static void set_push_excluded(CodeSpecsExtractSet *s, const char *area,
                              CodeSpecsGateVerdict verdict, int descoped,
                              const CodeSpecsExtract *x, const char *source) {
  s->excluded = (CodeSpecsExcludedArea *)realloc(
      s->excluded, (s->excluded_len + 1) * sizeof(CodeSpecsExcludedArea));
  CodeSpecsExcludedArea *e = &s->excluded[s->excluded_len++];
  e->area = som_strdup(area);
  e->verdict = verdict;
  e->descoped = descoped;
  e->entry_count = x != NULL ? x->entries_len : 0;
  e->source = som_strdup(source);
}

static const char *basename_of(const char *name) {
  const char *slash = strrchr(name, '/');
  return slash != NULL ? slash + 1 : name;
}

/* The index of the extract for `area` in `l`, or -1. Slots already moved out
 * (zeroed, `area` NULL) are skipped. */
static long index_of_area(const CodeSpecsExtractList *l, const char *area) {
  for (size_t i = 0; i < l->len; i++) {
    if (l->items[i].area != NULL && strcmp(l->items[i].area->code, area) == 0) {
      return (long)i;
    }
  }
  return -1;
}

/* Scopes the parsed extracts `all` (with `sources`) by `gate` into `*out`.
 * Moves the in-scope extracts out of `all`. */
static int scope_by_gate(const CodeSpecsGateRecord *gate, const char *gate_name,
                         CodeSpecsExtractList *all, const SomStrList *sources,
                         CodeSpecsExtractSet *out, CodeSpecsRecordError *err) {
  for (size_t i = 0; i < all->len; i++) {
    if (spec_codespecs_gate_record_verdict_for(gate, all->items[i].area->code) ==
        NULL) {
      return fail(err,
                  "%s carries no verdict for %s (%s) — the gate record must "
                  "be total over the supplied extracts",
                  gate_name, all->items[i].area->code, sources->items[i]);
    }
  }
  for (size_t v = 0; v < gate->verdicts_len; v++) {
    const CodeSpecsGateEntry *e = &gate->verdicts[v];
    long i = index_of_area(all, e->area);
    CodeSpecsExtract *x = i < 0 ? NULL : &all->items[i];
    const char *src = i < 0 ? "" : sources->items[i];
    switch (e->verdict) {
      case CODESPECS_GATE_SUFFICIENT:
        if (x != NULL) {
          som_strlist_push_copy(&out->sources, src);
          set_push_extract(&out->extracts, x);
        }
        break;
      case CODESPECS_GATE_NOT_APPLICABLE:
        if (x != NULL && x->entries_len > 0) {
          size_t n = x->entries_len;
          return fail(err,
                      "%s marks %s `not applicable`, but %s carries %zu "
                      "routed entr%s — a routed value is evidence the area "
                      "applies (codespecs_prompt.md §6.4)",
                      gate_name, e->area, src, n, n == 1 ? "y" : "ies");
        }
        set_push_excluded(out, e->area, e->verdict, 0, x, src);
        break;
      case CODESPECS_GATE_INSUFFICIENT:
        if (!spec_codespecs_gate_entry_descoped(e)) {
          return fail(err,
                      "%s marks %s `insufficient` without `resolution: "
                      "descoped` — codespecs_prompt.md §6.2 says the run does "
                      "not continue past an unresolved insufficient area; "
                      "recording the descope is what legitimizes a partial "
                      "pass",
                      gate_name, e->area);
        }
        set_push_excluded(out, e->area, e->verdict, 1, x, src);
        break;
    }
  }
  return 1;
}

int spec_codespecs_extract_set_from_files(const CodeSpecsRecordFile *files,
                                          size_t n, CodeSpecsExtractSet *out,
                                          CodeSpecsRecordError *err) {
  memset(out, 0, sizeof(*out));
  spec_codespecs_extract_list_init(&out->extracts);
  som_strlist_init(&out->sources);

  long gate_index = -1;
  CodeSpecsExtractList all;
  spec_codespecs_extract_list_init(&all);
  SomStrList sources;
  som_strlist_init(&sources);
  int ok = 1;
  for (size_t f = 0; f < n && ok; f++) {
    const char *name = files[f].name != NULL ? files[f].name : "";
    if (strcmp(basename_of(name), SPEC_CODESPECS_GATE_RECORD_FILE) == 0) {
      if (gate_index >= 0) {
        ok = fail(err,
                  "both %s and %s are gate records — the scope must have one "
                  "author",
                  files[gate_index].name, name);
        break;
      }
      gate_index = (long)f;
      continue;
    }
    CodeSpecsExtract x;
    if (!spec_codespecs_extract_from_yaml(files[f].text, name, &x, err)) {
      ok = 0;
      break;
    }
    long earlier = index_of_area(&all, x.area->code);
    if (earlier >= 0) {
      ok = fail(err, "%s and %s are both extracts for %s",
                sources.items[earlier], name, x.area->code);
      spec_codespecs_extract_free(&x);
      break;
    }
    set_push_extract(&all, &x);
    som_strlist_push_copy(&sources, name);
  }

  if (ok && gate_index < 0) {
    /* No record: every extract is in scope, in source order. */
    out->extracts = all;
    out->sources = sources;
    return 1;
  }
  if (ok) {
    const char *gate_name = files[gate_index].name;
    ok = spec_codespecs_gate_record_from_yaml(files[gate_index].text, gate_name,
                                              &out->gate, err);
    if (ok) {
      out->has_gate = 1;
      ok = scope_by_gate(&out->gate, gate_name, &all, &sources, out, err);
    }
  }
  spec_codespecs_extract_list_free(&all);
  som_strlist_free(&sources);
  if (!ok) {
    spec_codespecs_extract_set_free(out);
    spec_codespecs_extract_list_init(&out->extracts);
    som_strlist_init(&out->sources);
    return 0;
  }
  return 1;
}

static int name_cmp(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static int ends_with(const char *s, const char *suffix) {
  size_t n = strlen(s), k = strlen(suffix);
  return n >= k && strcmp(s + n - k, suffix) == 0;
}

static int wanted_name(const char *n) {
  return ends_with(n, SPEC_CODESPECS_EXTRACT_FILE_SUFFIX) ||
         strcmp(n, SPEC_CODESPECS_GATE_RECORD_FILE) == 0;
}

/* Reads a whole file into an owned NUL-terminated buffer, or NULL. */
static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    return NULL;
  }
  SomBuf b;
  som_buf_init(&b);
  char chunk[4096];
  size_t got;
  while ((got = fread(chunk, 1, sizeof(chunk), f)) > 0) {
    som_buf_putn(&b, chunk, got);
  }
  int bad = ferror(f);
  fclose(f);
  if (bad) {
    som_buf_free(&b);
    return NULL;
  }
  char *out = som_buf_take(&b);
  som_buf_free(&b);
  return out;
}

/* Lists the regular files of `path` whose names `wanted_name` accepts. Returns
 * 0 when the directory cannot be opened. */
static int list_names(const char *path, SomStrList *names) {
  som_strlist_init(names);
#ifdef _WIN32
  SomBuf pattern;
  som_buf_init(&pattern);
  som_buf_puts(&pattern, path);
  som_buf_puts(&pattern, "\\*");
  char *glob = som_buf_take(&pattern);
  som_buf_free(&pattern);
  WIN32_FIND_DATAA fd;
  HANDLE h = FindFirstFileA(glob, &fd);
  free(glob);
  if (h == INVALID_HANDLE_VALUE) {
    DWORD attrs = GetFileAttributesA(path);
    return attrs != INVALID_FILE_ATTRIBUTES &&
           (attrs & FILE_ATTRIBUTE_DIRECTORY) != 0;
  }
  do {
    if ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0 &&
        wanted_name(fd.cFileName)) {
      som_strlist_push_copy(names, fd.cFileName);
    }
  } while (FindNextFileA(h, &fd));
  FindClose(h);
  return 1;
#else
  DIR *dir = opendir(path);
  if (dir == NULL) {
    return 0;
  }
  struct dirent *ent;
  while ((ent = readdir(dir)) != NULL) {
    if (!wanted_name(ent->d_name)) {
      continue;
    }
    SomBuf full;
    som_buf_init(&full);
    som_buf_puts(&full, path);
    som_buf_putc(&full, '/');
    som_buf_puts(&full, ent->d_name);
    char *p = som_buf_take(&full);
    som_buf_free(&full);
    struct stat st;
    /* stat follows a symlink, as Dart's listing does. */
    if (stat(p, &st) == 0 && S_ISREG(st.st_mode)) {
      som_strlist_push_copy(names, ent->d_name);
    }
    free(p);
  }
  closedir(dir);
  return 1;
#endif
}

int spec_codespecs_extract_set_from_directory(const char *path,
                                              CodeSpecsExtractSet *out,
                                              CodeSpecsRecordError *err) {
  memset(out, 0, sizeof(*out));
  SomStrList names;
  if (!list_names(path, &names)) {
    som_strlist_free(&names);
    return fail(err, "extract directory not found: %s", path);
  }
  if (names.len > 1) {
    qsort(names.items, names.len, sizeof(char *), name_cmp);
  }
  CodeSpecsRecordFile *files =
      names.len > 0
          ? (CodeSpecsRecordFile *)calloc(names.len, sizeof(CodeSpecsRecordFile))
          : NULL;
  char **texts = names.len > 0 ? (char **)calloc(names.len, sizeof(char *)) : NULL;
  int ok = 1;
  for (size_t i = 0; i < names.len; i++) {
    SomBuf full;
    som_buf_init(&full);
    som_buf_puts(&full, path);
    som_buf_putc(&full, '/');
    som_buf_puts(&full, names.items[i]);
    char *p = som_buf_take(&full);
    som_buf_free(&full);
    texts[i] = read_file(p);
    if (texts[i] == NULL) {
      ok = fail(err, "cannot read %s", p);
      free(p);
      break;
    }
    free(p);
    files[i].name = names.items[i];
    files[i].text = texts[i];
  }
  if (ok) {
    ok = spec_codespecs_extract_set_from_files(files, names.len, out, err);
  }
  for (size_t i = 0; i < names.len; i++) {
    free(texts[i]);
  }
  free(texts);
  free(files);
  som_strlist_free(&names);
  return ok;
}

const CodeSpecsExtract *
spec_codespecs_extract_set_by_area(const CodeSpecsExtractSet *s,
                                   const char *area) {
  if (area == NULL) {
    return NULL;
  }
  long i = index_of_area(&s->extracts, area);
  return i < 0 ? NULL : &s->extracts.items[i];
}

/* Collects the in-scope entries whose `section_id` (by_section) or `path`
 * equals `want`. */
static size_t collect_entries(const CodeSpecsExtractSet *s, const char *want,
                              int by_section,
                              const CodeSpecsExtractEntry ***out) {
  *out = NULL;
  if (want == NULL) {
    return 0;
  }
  size_t len = 0, cap = 0;
  const CodeSpecsExtractEntry **items = NULL;
  for (size_t i = 0; i < s->extracts.len; i++) {
    const CodeSpecsExtract *x = &s->extracts.items[i];
    for (size_t k = 0; k < x->entries_len; k++) {
      const CodeSpecsExtractEntry *e = &x->entries[k];
      if (strcmp(by_section ? e->section_id : e->path, want) != 0) {
        continue;
      }
      if (len == cap) {
        cap = cap ? cap * 2 : 8;
        items = (const CodeSpecsExtractEntry **)realloc(
            (void *)items, cap * sizeof(*items));
      }
      items[len++] = e;
    }
  }
  *out = items;
  return len;
}

size_t spec_codespecs_extract_set_entries_for_section(
    const CodeSpecsExtractSet *s, const char *section_id,
    const CodeSpecsExtractEntry ***out) {
  return collect_entries(s, section_id, 1, out);
}

size_t spec_codespecs_extract_set_entries_at_path(
    const CodeSpecsExtractSet *s, const char *path,
    const CodeSpecsExtractEntry ***out) {
  return collect_entries(s, path, 0, out);
}
