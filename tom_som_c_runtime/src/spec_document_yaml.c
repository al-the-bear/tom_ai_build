/* spec_document_yaml — implementation. See spec_document_yaml.h; a faithful
 * port of the Go `spec_document_yaml.go` (hierarchical format v2). */
#include "spec_document_yaml.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "spec_paths.h"
#include "spec_section_id.h"

/* ---- small helpers ------------------------------------------------------- */

static void set_err(char **err, char *owned) {
  if (err != NULL) {
    *err = owned;
  } else {
    free(owned);
  }
}

/* Concatenates a NULL-terminated argument list of strings. Owned result. */
static char *vcat(const char *first, ...) {
  SomBuf b;
  som_buf_init(&b);
  va_list ap;
  va_start(ap, first);
  for (const char *s = first; s != NULL; s = va_arg(ap, const char *)) {
    som_buf_puts(&b, s);
  }
  va_end(ap);
  return som_buf_take(&b);
}

static void put_pad(SomBuf *b, size_t n) {
  for (size_t i = 0; i < n; i++) {
    som_buf_putc(b, ' ');
  }
}

/* Removes the first occurrence of `s` from `l`; 1 when it was present. */
static int strlist_remove_value(SomStrList *l, const char *s) {
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i], s) == 0) {
      som_strlist_remove_at(l, i);
      return 1;
    }
  }
  return 0;
}

void spec_yaml_contents_free(SpecYamlContents *c) {
  spec_document_free(&c->document);
  yaml_value_free(c->review);
  c->review = NULL;
  free(c->model_version);
  c->model_version = NULL;
}

/* ---- shared scalar machinery --------------------------------------------- */

/* js_json_string / yaml_key — JSON.stringify-compatible quoting. */
static char *js_json_string(const char *s) { return som_json_encode_str(s); }

char *spec_yaml_node_key(const SomMetaNode *node) {
  const char *name =
      node->member_name[0] != '\0' ? node->member_name : node->class_name;
  /* A section/complex node's key carries the full section id: the field-level
   * id if present, else the target class's own id (SOM §12.2 class fallback),
   * mirroring the markdown codec's heading rule. Content/scalar/enum/form and
   * list-item keys keep only their field-level id; the path segment is never
   * affected (see the node's segment()). */
  const char *id = node->section_id;
  if (id[0] == '\0' && (strcmp(node->kind, SOM_META_KIND_SECTION) == 0 ||
                        strcmp(node->kind, SOM_META_KIND_COMPLEX) == 0)) {
    id = node->class_section_id;
  }
  if (id[0] == '\0') {
    return som_strdup(name);
  }
  return vcat(id, " ", name, NULL);
}

/* plainKeyPattern: ^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$ */
static int key_first(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
         (c >= '0' && c <= '9') || c == '_';
}
static int key_last(char c) { return key_first(c) || c == '.' || c == '-'; }
static int key_mid(char c) { return key_last(c) || c == ' '; }

char *spec_yaml_plain_key(const char *key) {
  size_t n = strlen(key);
  int plain = n > 0 && key_first(key[0]);
  if (plain && n > 1) {
    plain = key_last(key[n - 1]);
    for (size_t i = 1; plain && i + 1 < n; i++) {
      plain = key_mid(key[i]);
    }
  }
  return plain ? som_strdup(key) : js_json_string(key);
}

char *spec_yaml_dedup_empty_lines(const char *value) {
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0;
  while (value[i] != '\0') {
    if (value[i] == '\n') {
      size_t run = 0;
      while (value[i + run] == '\n') {
        run++;
      }
      size_t emit = run >= 3 ? 2 : run;
      for (size_t k = 0; k < emit; k++) {
        som_buf_putc(&b, '\n');
      }
      i += run;
    } else {
      som_buf_putc(&b, value[i]);
      i++;
    }
  }
  return som_buf_take(&b);
}

/* parsedScalarStr: the string form of a parsed YAML scalar (string verbatim,
 * int formatted, "" for non-scalars). Owned result. */
static char *parsed_scalar_str(const YamlValue *v) {
  return yaml_scalar_string(v);
}

static size_t trailing_newlines(const char *value) {
  size_t n = strlen(value);
  size_t count = 0;
  while (count < n && value[n - 1 - count] == '\n') {
    count++;
  }
  return count;
}

/* Builds a `|2<chomp>` literal block with body at relative indent 2, or NULL
 * when chomping can't reproduce the value's trailing newlines (two or more) —
 * those fall back to JSON quoting. Owned result. */
static char *literal_block(const char *value) {
  size_t trailing = trailing_newlines(value);
  const char *chomp;
  size_t core_len;
  size_t vlen = strlen(value);
  if (trailing == 0) {
    chomp = "-";
    core_len = vlen;
  } else if (trailing == 1) {
    chomp = "";
    core_len = vlen - 1;
  } else {
    return NULL;
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "|2");
  som_buf_puts(&b, chomp);
  /* core.split('\n') */
  size_t start = 0;
  for (size_t i = 0;; i++) {
    if (i == core_len || value[i] == '\n') {
      som_buf_putc(&b, '\n');
      if (i > start) {
        som_buf_puts(&b, "  ");
        som_buf_putn(&b, value + start, i - start);
      }
      if (i == core_len) {
        break;
      }
      start = i + 1;
    }
  }
  return som_buf_take(&b);
}

/* Reports whether re-parsing `_v: <block>` yields exactly `value` (the
 * emitter's correctness guard). */
static int round_trips(const char *block, const char *value) {
  char *probe = vcat("_v: ", block, "\n", NULL);
  YamlValue *parsed = yaml_parse(probe);
  free(probe);
  const YamlValue *v = yaml_get(parsed, "_v");
  const char *s = yaml_as_str(v);
  int ok = (s != NULL && strcmp(s, value) == 0);
  yaml_value_free(parsed);
  return ok;
}

/* Literal block at relative indent 2 when it round-trips, else JSON quoting. */
static char *scalar_repr(const char *value) {
  char *block = literal_block(value);
  if (block != NULL) {
    if (round_trips(block, value)) {
      return block;
    }
    free(block);
  }
  return js_json_string(value);
}

/* Whether `value` is a YAML 1.1 boolean word that YAML 1.2 treats as a plain
 * string. */
static int is_yaml11_bool(const char *value) {
  static const char *const words[] = {
      "y",  "Y",  "yes", "Yes", "YES", "n",   "N",  "no",
      "No", "NO", "on",  "On",  "ON",  "off", "Off", "OFF"};
  for (size_t i = 0; i < sizeof(words) / sizeof(words[0]); i++) {
    if (strcmp(value, words[i]) == 0) {
      return 1;
    }
  }
  return 0;
}

/* Whether `value` is a YAML 1.1 sexagesimal literal — an int
 * (^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$) when is_float is 0, or a float
 * (^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$) when 1. A dependency-free
 * stand-in for the other ports' regexes. */
static int is_yaml11_sexagesimal(const char *value, int is_float) {
  size_t n = strlen(value);
  size_t i = 0;
  if (n == 0) {
    return 0;
  }
  if (value[i] == '+' || value[i] == '-') {
    i++;
  }
  if (i >= n) {
    return 0;
  }
  if (is_float) {
    if (!isdigit((unsigned char)value[i])) {
      return 0;
    }
  } else if (!(value[i] >= '1' && value[i] <= '9')) {
    return 0;
  }
  i++;
  while (i < n && (isdigit((unsigned char)value[i]) || value[i] == '_')) {
    i++;
  }
  size_t groups = 0;
  while (i < n && value[i] == ':') {
    i++;
    if (i >= n || !isdigit((unsigned char)value[i])) {
      return 0;
    }
    if (value[i] >= '0' && value[i] <= '5' && i + 1 < n &&
        isdigit((unsigned char)value[i + 1])) {
      i += 2;
    } else {
      i++;
    }
    groups++;
  }
  if (groups == 0) {
    return 0;
  }
  if (is_float) {
    if (i >= n || value[i] != '.') {
      return 0;
    }
    i++;
    while (i < n && (isdigit((unsigned char)value[i]) || value[i] == '_')) {
      i++;
    }
  }
  return i == n;
}

/* Whether `value`'s text is a YAML 1.1 special that a 1.1 parser would resolve
 * to a non-string, so it must never be emitted as a plain scalar (SOM §12.5).
 * Mirrors the Dart reference rule so every emitter agrees regardless of the
 * local YAML parser's schema. */
static int is_yaml11_special(const char *value) {
  return is_yaml11_bool(value) || is_yaml11_sexagesimal(value, 0) ||
         is_yaml11_sexagesimal(value, 1);
}

/* plainScalar: a plain one-line scalar for a non-text value (SOM §12.5) when
 * writing it plainly re-parses to exactly `value` (string compare, matching
 * the document's string-typed stores). Values whose text is a YAML 1.1 special
 * are forced to the quoted/block path so cross-language round-trips match. */
static int plain_scalar_ok(const char *value) {
  if (value[0] == '\0' || strchr(value, '\n') != NULL) {
    return 0;
  }
  if (is_yaml11_special(value)) {
    return 0;
  }
  char *probe = vcat("_v: ", value, "\n", NULL);
  YamlValue *parsed = yaml_parse(probe);
  free(probe);
  if (parsed == NULL || parsed->type != YAML_MAP) {
    yaml_value_free(parsed);
    return 0;
  }
  const YamlValue *v = yaml_get(parsed, "_v");
  if (v == NULL || v->type == YAML_MAP || v->type == YAML_SEQ) {
    yaml_value_free(parsed);
    return 0;
  }
  char *s = parsed_scalar_str(v);
  int ok = strcmp(s, value) == 0;
  free(s);
  yaml_value_free(parsed);
  return ok;
}

/* writeRendered: `<pad><renderedKey>: <first line>` then the remaining repr
 * lines re-indented past key_indent (empty lines stay empty). */
static void write_rendered(SomBuf *out, size_t key_indent,
                           const char *rendered_key, const char *repr) {
  put_pad(out, key_indent);
  som_buf_puts(out, rendered_key);
  som_buf_puts(out, ": ");
  size_t start = 0;
  int first = 1;
  size_t rlen = strlen(repr);
  for (size_t i = 0;; i++) {
    if (i == rlen || repr[i] == '\n') {
      size_t llen = i - start;
      if (first) {
        som_buf_putn(out, repr + start, llen);
        som_buf_putc(out, '\n');
        first = 0;
      } else if (llen == 0) {
        som_buf_putc(out, '\n');
      } else {
        put_pad(out, key_indent);
        som_buf_putn(out, repr + start, llen);
        som_buf_putc(out, '\n');
      }
      if (i == rlen) {
        break;
      }
      start = i + 1;
    }
  }
}

void spec_yaml_write_scalar(SomBuf *out, size_t key_indent, const char *key,
                            const char *value) {
  char *rendered_key = js_json_string(key);
  char *repr = scalar_repr(value);
  write_rendered(out, key_indent, rendered_key, repr);
  free(repr);
  free(rendered_key);
}

/* writeHeader: the file header comment + `version:` line, and the optional
 * `modelVersion:` stamp when non-empty. */
static void write_header(SomBuf *out, const char *model_version) {
  som_buf_puts(out,
               "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n");
  som_buf_puts(out, "version: ");
  som_buf_puti(out, SPEC_YAML_FORMAT_VERSION);
  som_buf_putc(out, '\n');
  if (model_version != NULL && model_version[0] != '\0') {
    char *mv = js_json_string(model_version);
    som_buf_puts(out, "modelVersion: ");
    som_buf_puts(out, mv);
    som_buf_putc(out, '\n');
    free(mv);
  }
}

/* ---- encode --------------------------------------------------------------- */

static int is_numeric_or_bool(const char *type_name) {
  return strcmp(type_name, "int") == 0 || strcmp(type_name, "double") == 0 ||
         strcmp(type_name, "num") == 0 || strcmp(type_name, "bool") == 0;
}

/* One encode run: it walks the metadata tree, consuming values from snapshots
 * of the document's stores so anything left unconsumed at the end is a
 * structured error (nothing is silently dropped). */
typedef struct {
  const SpecDocument *doc;
  SomMap content;         /* snapshot copy, consumed as the walk places values */
  SomStrList form_paths;  /* remaining unconsumed form paths */
  SomStrList list_paths;  /* remaining unconsumed list paths */
  SomMap headlines;       /* snapshot of stored headlines (YRD3), consumed */
  SomMap code_specs;      /* snapshot of stored codeSpecs (codespecs_mapping.md §9.2), consumed */
} YamlEncoder;

static void encoder_init(YamlEncoder *e, const SpecDocument *doc) {
  e->doc = doc;
  som_map_init(&e->content);
  SomStrList paths;
  som_strlist_init(&paths);
  spec_document_content_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    const char *v = spec_document_content(doc, paths.items[i]);
    som_map_set(&e->content, paths.items[i], v != NULL ? v : "");
  }
  som_strlist_free(&paths);
  som_strlist_init(&e->form_paths);
  spec_document_form_paths(doc, &e->form_paths);
  som_strlist_init(&e->list_paths);
  spec_document_list_paths(doc, &e->list_paths);
  som_map_init(&e->headlines);
  SomStrList hpaths;
  som_strlist_init(&hpaths);
  spec_document_headline_paths(doc, &hpaths);
  for (size_t i = 0; i < hpaths.len; i++) {
    const char *h = spec_document_headline(doc, hpaths.items[i]);
    som_map_set(&e->headlines, hpaths.items[i], h != NULL ? h : "");
  }
  som_strlist_free(&hpaths);
  som_map_init(&e->code_specs);
  SomStrList cspaths;
  som_strlist_init(&cspaths);
  spec_document_code_spec_paths(doc, &cspaths);
  for (size_t i = 0; i < cspaths.len; i++) {
    const char *c = spec_document_code_spec(doc, cspaths.items[i]);
    som_map_set(&e->code_specs, cspaths.items[i], c != NULL ? c : "");
  }
  som_strlist_free(&cspaths);
}

static void encoder_free(YamlEncoder *e) {
  som_map_free(&e->content);
  som_strlist_free(&e->form_paths);
  som_strlist_free(&e->list_paths);
  som_map_free(&e->headlines);
  som_map_free(&e->code_specs);
}

/* Consumes the content snapshot entry at `path`; 1 when present (writing the
 * owned value to `*out`). */
static int encoder_take_content(YamlEncoder *e, const char *path, char **out) {
  const char *v = som_map_get(&e->content, path);
  if (v == NULL) {
    return 0;
  }
  *out = som_strdup(v);
  som_map_remove(&e->content, path);
  return 1;
}

/* Consumes the headline snapshot entry at `path`; 1 when present (writing the
 * owned value to `*out`) (YRD3). */
static int encoder_take_headline(YamlEncoder *e, const char *path, char **out) {
  const char *v = som_map_get(&e->headlines, path);
  if (v == NULL) {
    return 0;
  }
  *out = som_strdup(v);
  som_map_remove(&e->headlines, path);
  return 1;
}

/* Consumes the codeSpec snapshot entry at `path`; 1 when present (writing the
 * owned value to `*out`) (codespecs_mapping.md §9.2). */
static int encoder_take_code_spec(YamlEncoder *e, const char *path,
                                  char **out) {
  const char *v = som_map_get(&e->code_specs, path);
  if (v == NULL) {
    return 0;
  }
  *out = som_strdup(v);
  som_map_remove(&e->code_specs, path);
  return 1;
}

/* writeText: empty-line dedup, then a self-verified block scalar (or the
 * JSON-quoted fallback). */
static void encoder_write_text(SomBuf *b, size_t indent, const char *key,
                               const char *value) {
  char *deduped = spec_yaml_dedup_empty_lines(value);
  char *repr = scalar_repr(deduped);
  char *pk = spec_yaml_plain_key(key);
  write_rendered(b, indent, pk, repr);
  free(pk);
  free(repr);
  free(deduped);
}

/* writeValue: a non-text value (SOM §12.5) — plain when it self-verifies, else the
 * text path. */
static void encoder_write_value(SomBuf *b, size_t indent, const char *key,
                                const char *value) {
  if (plain_scalar_ok(value)) {
    char *pk = spec_yaml_plain_key(key);
    put_pad(b, indent);
    som_buf_puts(b, pk);
    som_buf_puts(b, ": ");
    som_buf_puts(b, value);
    som_buf_putc(b, '\n');
    free(pk);
  } else {
    encoder_write_text(b, indent, key, value);
  }
}

static int encoder_mapping_body(YamlEncoder *e, const SomMetaNode *node,
                                const char *path, size_t indent, char **out,
                                char **err);

/* writeScalarWithMeta: emits a scalar-valued node (content/scalar/enum leaf or
 * scalar list item) that carries a stored headline and/or codeSpec as a
 * `{headline?: …, codeSpec?: …, content?: …}` mapping (YRD3 +
 * codespecs_mapping.md §9.2). The headline/codeSpec entries are emitted only
 * when the matching has_* flag is set (at least one is at every call site); the
 * content entry is omitted when
 * has_value is 0; `text` selects the text vs value path for content. */
static void encoder_write_scalar_with_meta(SomBuf *b, size_t indent,
                                           const char *key,
                                           const char *headline,
                                           int has_headline,
                                           const char *code_spec,
                                           int has_code_spec, const char *value,
                                           int has_value, int text) {
  char *pk = spec_yaml_plain_key(key);
  put_pad(b, indent);
  som_buf_puts(b, pk);
  som_buf_puts(b, ":\n");
  free(pk);
  if (has_headline) {
    encoder_write_text(b, indent + 2, "headline", headline);
  }
  if (has_code_spec) {
    encoder_write_text(b, indent + 2, "codeSpec", code_spec);
  }
  if (has_value) {
    if (text) {
      encoder_write_text(b, indent + 2, "content", value);
    } else {
      encoder_write_value(b, indent + 2, "content", value);
    }
  }
}

static int encoder_write_form(YamlEncoder *e, SomBuf *b, size_t indent,
                              const char *key, const SomMetaNode *node,
                              const char *path, char **err) {
  int present = strlist_remove_value(&e->form_paths, path);
  SomStrList names;
  som_strlist_init(&names);
  spec_document_form_field_names(e->doc, path, &names);
  char *headline = NULL;
  int has_headline = encoder_take_headline(e, path, &headline);
  char *code_spec = NULL;
  int has_code_spec = encoder_take_code_spec(e, path, &code_spec);
  if ((!present || names.len == 0) && !has_headline && !has_code_spec) {
    som_strlist_free(&names);
    free(headline);
    free(code_spec);
    return 1;
  }
  for (size_t i = 0; i < names.len; i++) {
    const SomFormFieldMeta *field =
        som_form_meta_field_named(node->form, names.items[i]);
    if (field == NULL) {
      set_err(err, vcat("form `", path, "` holds a field `", names.items[i],
                        "` unknown to the model", NULL));
      som_strlist_free(&names);
      free(headline);
      free(code_spec);
      return 0;
    }
  }
  som_strlist_free(&names);
  if (has_headline &&
      som_form_meta_field_named(node->form, "headline") != NULL) {
    set_err(err, vcat("cannot emit the stored headline at `", path,
                      "`: the form declares a field literally named "
                      "`headline`",
                      NULL));
    free(headline);
    free(code_spec);
    return 0;
  }
  if (has_code_spec &&
      som_form_meta_field_named(node->form, "codeSpec") != NULL) {
    set_err(err, vcat("cannot emit the stored codeSpec at `", path,
                      "`: the form declares a field literally named "
                      "`codeSpec`",
                      NULL));
    free(headline);
    free(code_spec);
    return 0;
  }
  char *pk = spec_yaml_plain_key(key);
  put_pad(b, indent);
  som_buf_puts(b, pk);
  som_buf_puts(b, ":\n");
  free(pk);
  if (has_headline) {
    encoder_write_text(b, indent + 2, "headline", headline);
  }
  free(headline);
  if (has_code_spec) {
    encoder_write_text(b, indent + 2, "codeSpec", code_spec);
  }
  free(code_spec);
  if (node->form != NULL) {
    for (size_t i = 0; i < node->form->fields_len; i++) {
      const SomFormFieldMeta *f = &node->form->fields[i];
      const char *v = spec_document_form_field(e->doc, path, f->name);
      if (v == NULL) {
        continue;
      }
      if (is_numeric_or_bool(f->type_name)) {
        encoder_write_value(b, indent + 2, f->name, v);
      } else {
        encoder_write_text(b, indent + 2, f->name, v);
      }
    }
  }
  return 1;
}

static int encoder_write_list(YamlEncoder *e, SomBuf *b, size_t indent,
                              const char *key, const SomMetaNode *node,
                              const char *path, char **err) {
  strlist_remove_value(&e->list_paths, path);
  char *headline = NULL;
  int has_headline = encoder_take_headline(e, path, &headline);
  char *code_spec = NULL;
  int has_code_spec = encoder_take_code_spec(e, path, &code_spec);
  const SomStrList *items = spec_document_list_items(e->doc, path);
  if ((items == NULL || items->len == 0) && !has_headline && !has_code_spec) {
    free(headline);
    free(code_spec);
    return 1;
  }
  char *pk = spec_yaml_plain_key(key);
  put_pad(b, indent);
  som_buf_puts(b, pk);
  som_buf_puts(b, ":\n");
  free(pk);
  if (has_headline) {
    encoder_write_text(b, indent + 2, "headline", headline);
  }
  free(headline);
  if (has_code_spec) {
    encoder_write_text(b, indent + 2, "codeSpec", code_spec);
  }
  free(code_spec);
  SomStrList used;
  som_strlist_init(&used);
  som_strlist_push_copy(&used, "headline");
  som_strlist_push_copy(&used, "codeSpec");
  long long pos = 0;
  for (size_t i = 0; items != NULL && i < items->len; i++) {
    const char *item_path = items->items[i];
    pos++;
    const char *stored_id = spec_document_item_section_id(e->doc, item_path);
    char *item_key;
    if (stored_id != NULL) {
      item_key = som_strdup(stored_id);
      if (som_strlist_contains(&used, item_key)) {
        set_err(err, vcat("duplicate list item key `", item_key, "` at `", path,
                          "`", NULL));
        free(item_key);
        som_strlist_free(&used);
        return 0;
      }
      som_strlist_push_copy(&used, item_key);
    } else {
      char *n = som_format_i64(pos);
      item_key = vcat(node->member_name, "-", n, NULL);
      free(n);
      long long bump = pos;
      while (som_strlist_contains(&used, item_key)) {
        bump++;
        free(item_key);
        n = som_format_i64(bump);
        item_key = vcat(node->member_name, "-", n, NULL);
        free(n);
      }
      som_strlist_push_copy(&used, item_key);
    }
    if (node->element_node == NULL) {
      /* Scalar list: the item is a direct value — unless it carries a stored
       * headline and/or codeSpec, in which case it becomes a
       * `{headline?: …, codeSpec?: …, content: …}` mapping (YRD3 + codespecs_mapping.md §9.2). */
      char *v = NULL;
      int has_v = encoder_take_content(e, item_path, &v);
      char *ih = NULL;
      int has_ih = encoder_take_headline(e, item_path, &ih);
      char *ics = NULL;
      int has_ics = encoder_take_code_spec(e, item_path, &ics);
      if (has_ih || has_ics) {
        encoder_write_scalar_with_meta(b, indent + 2, item_key, ih, has_ih, ics,
                                       has_ics, has_v ? v : "", has_v, 0);
      } else {
        encoder_write_value(b, indent + 2, item_key, has_v ? v : "");
      }
      free(ih);
      free(ics);
      free(v);
    } else {
      char *sub = NULL;
      if (!encoder_mapping_body(e, node->element_node, item_path, indent + 4,
                                &sub, err)) {
        free(item_key);
        som_strlist_free(&used);
        return 0;
      }
      char *ik = spec_yaml_plain_key(item_key);
      if (sub[0] == '\0') {
        put_pad(b, indent + 2);
        som_buf_puts(b, ik);
        som_buf_puts(b, ": {}\n");
      } else {
        put_pad(b, indent + 2);
        som_buf_puts(b, ik);
        som_buf_puts(b, ":\n");
        som_buf_puts(b, sub);
      }
      free(ik);
      free(sub);
    }
    free(item_key);
  }
  som_strlist_free(&used);
  return 1;
}

/* mappingBody: renders the mapping body of `node` at `path` (root, a
 * collapsed section/complex field, or a list item's element), one line per
 * populated entry at `indent`. Empty when nothing under the node is
 * populated. */
static int encoder_mapping_body(YamlEncoder *e, const SomMetaNode *node,
                                const char *path, size_t indent, char **out,
                                char **err) {
  SomBuf b;
  som_buf_init(&b);

  /* The node's own stored headline — the literal `headline` key (YRD3). */
  char *own_headline = NULL;
  if (encoder_take_headline(e, path, &own_headline)) {
    for (size_t i = 0; i < node->children_len; i++) {
      char *ck = spec_yaml_node_key(node->children[i]);
      int clash = strcmp(ck, "headline") == 0;
      free(ck);
      if (clash) {
        char *name = som_meta_node_debug_name(node);
        set_err(err, vcat("cannot emit the stored headline at `", path,
                          "`: a child of ", name,
                          " also serializes as key `headline`", NULL));
        free(name);
        free(own_headline);
        som_buf_free(&b);
        return 0;
      }
    }
    encoder_write_text(&b, indent, "headline", own_headline);
    free(own_headline);
  }

  /* The node's own stored codeSpec — the literal `codeSpec` key (codespecs_mapping.md §9.2). */
  char *own_code_spec = NULL;
  if (encoder_take_code_spec(e, path, &own_code_spec)) {
    for (size_t i = 0; i < node->children_len; i++) {
      char *ck = spec_yaml_node_key(node->children[i]);
      int clash = strcmp(ck, "codeSpec") == 0;
      free(ck);
      if (clash) {
        char *name = som_meta_node_debug_name(node);
        set_err(err, vcat("cannot emit the stored codeSpec at `", path,
                          "`: a child of ", name,
                          " also serializes as key `codeSpec`", NULL));
        free(name);
        free(own_code_spec);
        som_buf_free(&b);
        return 0;
      }
    }
    encoder_write_text(&b, indent, "codeSpec", own_code_spec);
    free(own_code_spec);
  }

  /* The node's own body text — the literal `content` key (SOM §12.2). */
  char *own = NULL;
  if (encoder_take_content(e, path, &own)) {
    for (size_t i = 0; i < node->children_len; i++) {
      char *ck = spec_yaml_node_key(node->children[i]);
      int clash = strcmp(ck, "content") == 0;
      free(ck);
      if (clash) {
        char *name = som_meta_node_debug_name(node);
        set_err(err, vcat("cannot emit body text at `", path,
                          "`: a child of ", name,
                          " also serializes as key `content`", NULL));
        free(name);
        free(own);
        som_buf_free(&b);
        return 0;
      }
    }
    encoder_write_text(&b, indent, "content", own);
    free(own);
  }

  for (size_t i = 0; i < node->children_len; i++) {
    const SomMetaNode *child = node->children[i];
    char *child_path = spec_path_join(path, som_meta_node_segment(child));
    char *key = spec_yaml_node_key(child);
    int ok = 1;
    if (strcmp(child->kind, SOM_META_KIND_CONTENT) == 0) {
      char *v = NULL;
      int has_v = encoder_take_content(e, child_path, &v);
      char *h = NULL;
      int has_h = encoder_take_headline(e, child_path, &h);
      char *cs = NULL;
      int has_cs = encoder_take_code_spec(e, child_path, &cs);
      if (has_h || has_cs) {
        encoder_write_scalar_with_meta(&b, indent, key, h, has_h, cs, has_cs,
                                       has_v ? v : "", has_v, 1);
      } else if (has_v) {
        encoder_write_text(&b, indent, key, v);
      }
      free(h);
      free(cs);
      free(v);
    } else if (strcmp(child->kind, SOM_META_KIND_SCALAR) == 0 ||
               strcmp(child->kind, SOM_META_KIND_ENUM_VALUE) == 0) {
      char *v = NULL;
      int has_v = encoder_take_content(e, child_path, &v);
      char *h = NULL;
      int has_h = encoder_take_headline(e, child_path, &h);
      char *cs = NULL;
      int has_cs = encoder_take_code_spec(e, child_path, &cs);
      if (has_h || has_cs) {
        encoder_write_scalar_with_meta(&b, indent, key, h, has_h, cs, has_cs,
                                       has_v ? v : "", has_v, 0);
      } else if (has_v) {
        encoder_write_value(&b, indent, key, v);
      }
      free(h);
      free(cs);
      free(v);
    } else if (strcmp(child->kind, SOM_META_KIND_FORM) == 0) {
      ok = encoder_write_form(e, &b, indent, key, child, child_path, err);
    } else if (strcmp(child->kind, SOM_META_KIND_SECTION) == 0 ||
               strcmp(child->kind, SOM_META_KIND_COMPLEX) == 0) {
      char *sub = NULL;
      ok = encoder_mapping_body(e, child, child_path, indent + 2, &sub, err);
      if (ok && sub[0] != '\0') {
        char *pk = spec_yaml_plain_key(key);
        put_pad(&b, indent);
        som_buf_puts(&b, pk);
        som_buf_puts(&b, ":\n");
        som_buf_puts(&b, sub);
        free(pk);
      }
      free(sub);
    } else if (strcmp(child->kind, SOM_META_KIND_LIST) == 0) {
      ok = encoder_write_list(e, &b, indent, key, child, child_path, err);
    }
    free(key);
    free(child_path);
    if (!ok) {
      som_buf_free(&b);
      return 0;
    }
  }
  *out = som_buf_take(&b);
  return 1;
}

static int encoder_assert_nothing_left(YamlEncoder *e, char **err) {
  SomStrList leftovers;
  som_strlist_init(&leftovers);
  for (size_t i = 0; i < e->content.len; i++) {
    som_strlist_push(&leftovers,
                     vcat("content at `", e->content.entries[i].key, "`", NULL));
  }
  for (size_t i = 0; i < e->form_paths.len; i++) {
    som_strlist_push(
        &leftovers, vcat("form values at `", e->form_paths.items[i], "`", NULL));
  }
  for (size_t i = 0; i < e->list_paths.len; i++) {
    som_strlist_push(
        &leftovers, vcat("list items at `", e->list_paths.items[i], "`", NULL));
  }
  for (size_t i = 0; i < e->headlines.len; i++) {
    som_strlist_push(&leftovers, vcat("headline at `",
                                      e->headlines.entries[i].key, "`", NULL));
  }
  for (size_t i = 0; i < e->code_specs.len; i++) {
    som_strlist_push(&leftovers, vcat("codeSpec at `",
                                      e->code_specs.entries[i].key, "`", NULL));
  }
  if (leftovers.len == 0) {
    som_strlist_free(&leftovers);
    return 1;
  }
  /* sortStrings (ascending). */
  for (size_t i = 1; i < leftovers.len; i++) {
    for (size_t j = i; j > 0 && strcmp(leftovers.items[j], leftovers.items[j - 1]) < 0;
         j--) {
      char *tmp = leftovers.items[j];
      leftovers.items[j] = leftovers.items[j - 1];
      leftovers.items[j - 1] = tmp;
    }
  }
  char *joined = som_strlist_join(&leftovers, "; ");
  som_strlist_free(&leftovers);
  set_err(err, vcat("document holds values the metadata tree cannot place: ",
                    joined, NULL));
  free(joined);
  return 0;
}

char *encode_yaml(const SpecDocument *document, const SomMetaTree *tree,
                  const char *model_version, char **err) {
  SomBuf out;
  som_buf_init(&out);
  write_header(&out, model_version);
  YamlEncoder e;
  encoder_init(&e, document);
  char *body = NULL;
  if (!encoder_mapping_body(&e, tree->root,
                            som_meta_node_segment(tree->root), 4, &body, err)) {
    encoder_free(&e);
    som_buf_free(&out);
    return NULL;
  }
  if (!encoder_assert_nothing_left(&e, err)) {
    free(body);
    encoder_free(&e);
    som_buf_free(&out);
    return NULL;
  }
  encoder_free(&e);
  if (body[0] == '\0') {
    som_buf_puts(&out, "document: {}\n");
  } else {
    som_buf_puts(&out, "document:\n");
    char *nk = spec_yaml_node_key(tree->root);
    char *pk = spec_yaml_plain_key(nk);
    som_buf_puts(&out, "  ");
    som_buf_puts(&out, pk);
    som_buf_puts(&out, ":\n");
    som_buf_puts(&out, body);
    free(pk);
    free(nk);
  }
  free(body);
  return som_buf_take(&out);
}

/* ---- decode --------------------------------------------------------------- */

/* Deep-clones a parsed YAML value (the `review:` pass is returned owned). */
static YamlValue *clone_yaml(const YamlValue *v);

static YamlValue *clone_yaml(const YamlValue *v) {
  YamlValue *out = calloc(1, sizeof(YamlValue));
  out->type = v->type;
  switch (v->type) {
  case YAML_MAP:
    out->as.map.len = v->as.map.len;
    out->as.map.cap = v->as.map.len;
    if (v->as.map.len > 0) {
      out->as.map.entries = calloc(v->as.map.len, sizeof(YamlMapEntry));
      for (size_t i = 0; i < v->as.map.len; i++) {
        out->as.map.entries[i].key = som_strdup(v->as.map.entries[i].key);
        out->as.map.entries[i].value = clone_yaml(v->as.map.entries[i].value);
      }
    }
    break;
  case YAML_SEQ:
    out->as.seq.len = v->as.seq.len;
    out->as.seq.cap = v->as.seq.len;
    if (v->as.seq.len > 0) {
      out->as.seq.items = calloc(v->as.seq.len, sizeof(YamlValue *));
      for (size_t i = 0; i < v->as.seq.len; i++) {
        out->as.seq.items[i] = clone_yaml(v->as.seq.items[i]);
      }
    }
    break;
  case YAML_STR:
    out->as.str = som_strdup(v->as.str);
    break;
  case YAML_INT:
    out->as.integer = v->as.integer;
    break;
  }
  return out;
}

static YamlValue *new_empty_map(void) {
  YamlValue *v = calloc(1, sizeof(YamlValue));
  v->type = YAML_MAP;
  return v;
}

/* versionRepr: the raw parsed `version:` value for the unsupported-version
 * error message (a non-scalar mapping renders as "[object Object]",
 * mirroring JS/TS string interpolation). Owned result. */
static char *version_repr(const YamlValue *v) {
  if (v != NULL && v->type == YAML_MAP) {
    return som_strdup("[object Object]");
  }
  return parsed_scalar_str(v);
}

/* decoderScalarOf: coerces a parsed leaf value to the document's string
 * store. The hand-rolled parser yields an empty mapping for a bare `key:`
 * (where a real YAML parser yields null), so an *empty* mapping counts as the
 * empty string; a populated mapping or a sequence is still a structural
 * error. Returns 1 writing owned `*out`, or 0 writing `*err`. */
static int decoder_scalar_of(const YamlValue *value, const char *where,
                             char **out, char **err) {
  if (value == NULL) {
    *out = som_strdup("");
    return 1;
  }
  if (value->type == YAML_SEQ ||
      (value->type == YAML_MAP && value->as.map.len > 0)) {
    set_err(err, vcat("expected a scalar value at `", where, "`", NULL));
    return 0;
  }
  if (value->type == YAML_MAP) {
    *out = som_strdup("");
    return 1;
  }
  *out = parsed_scalar_str(value);
  return 1;
}

typedef struct {
  SpecDocument *doc;
  const SomMetaTree *tree;
} YamlDecoder;

static const SomMetaNode *decoder_child_by_key(const SomMetaNode *node,
                                               const char *key) {
  for (size_t i = 0; i < node->children_len; i++) {
    char *nk = spec_yaml_node_key(node->children[i]);
    int hit = strcmp(nk, key) == 0;
    free(nk);
    if (hit) {
      return node->children[i];
    }
  }
  return NULL;
}

static char *decoder_expected_keys(const SomMetaNode *node) {
  SomStrList out;
  som_strlist_init(&out);
  for (size_t i = 0; i < node->children_len; i++) {
    char *nk = spec_yaml_node_key(node->children[i]);
    som_strlist_push(&out, vcat("`", nk, "`", NULL));
    free(nk);
  }
  som_strlist_push_copy(&out, "`content`");
  som_strlist_push_copy(&out, "`headline`");
  som_strlist_push_copy(&out, "`codeSpec`");
  char *joined = som_strlist_join(&out, ", ");
  som_strlist_free(&out);
  return joined;
}

static int decoder_load_mapping(YamlDecoder *d, const SomMetaNode *node,
                                const char *path, const YamlValue *body,
                                char **err);

/* loadScalarWithMeta: loads a headline-/codeSpec-extended scalar node
 * (YRD3 + codespecs_mapping.md §9.2): a mapping holding only the literal keys
 * `headline`,
 * `codeSpec` and `content`. */
static int decoder_load_scalar_with_meta(YamlDecoder *d, const char *path,
                                         const char *key,
                                         const YamlValue *value, char **err) {
  for (size_t i = 0; i < value->as.map.len; i++) {
    const char *name = value->as.map.entries[i].key;
    const YamlValue *v = value->as.map.entries[i].value;
    if (strcmp(name, "headline") == 0) {
      char *where = vcat(path, " (headline)", NULL);
      char *s = NULL;
      int ok = decoder_scalar_of(v, where, &s, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_headline(d->doc, path, s);
      free(s);
    } else if (strcmp(name, "codeSpec") == 0) {
      char *where = vcat(path, " (codeSpec)", NULL);
      char *s = NULL;
      int ok = decoder_scalar_of(v, where, &s, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_code_spec(d->doc, path, s);
      free(s);
    } else if (strcmp(name, "content") == 0) {
      char *where = vcat(path, "/content", NULL);
      char *s = NULL;
      int ok = decoder_scalar_of(v, where, &s, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_content(d->doc, path, s);
      free(s);
    } else {
      set_err(err, vcat("scalar node `", key, "` at `", path,
                        "` may only hold `headline`/`codeSpec`/`content` keys "
                        "when written as a mapping, found `",
                        name, "`", NULL));
      return 0;
    }
  }
  return 1;
}

static int decoder_load_list(YamlDecoder *d, const SomMetaNode *node,
                             const char *path, const YamlValue *items,
                             char **err) {
  size_t member_len = strlen(node->member_name);
  for (size_t i = 0; i < items->as.map.len; i++) {
    const char *key = items->as.map.entries[i].key;
    const YamlValue *value = items->as.map.entries[i].value;
    if (strcmp(key, "headline") == 0) {
      /* The list container's own stored headline (YRD3), not an item. */
      char *where = vcat(path, " (headline)", NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_headline(d->doc, path, v);
      free(v);
      continue;
    }
    if (strcmp(key, "codeSpec") == 0) {
      /* The list container's own stored codeSpec (codespecs_mapping.md §9.2), not an item. */
      char *where = vcat(path, " (codeSpec)", NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_code_spec(d->doc, path, v);
      free(v);
      continue;
    }
    /* anonymous: ^<memberName>-[0-9]+$ */
    int anonymous = strncmp(key, node->member_name, member_len) == 0 &&
                    key[member_len] == '-' &&
                    som_is_all_digits(key + member_len + 1);
    char *item_path = NULL;
    if (anonymous) {
      item_path = spec_document_add_list_item(d->doc, path);
    } else {
      SpecSectionIdError id_err;
      spec_section_id_error_init(&id_err);
      item_path =
          spec_document_add_list_item_with_section_id(d->doc, path, key, &id_err);
      if (item_path == NULL) {
        /* Byte-match the Go *SpecSectionIDCollision Error() string. */
        set_err(err, vcat("SpecSectionIdCollision: section id \"", key,
                          "\" is already used in list \"", path,
                          "\"; section ids within a list must be unique.",
                          NULL));
        spec_section_id_error_free(&id_err);
        return 0;
      }
      spec_section_id_error_free(&id_err);
    }
    if (node->element_node == NULL) {
      /* Scalar list item: the value is the item itself — or a
       * `{headline: …, content: …}` mapping when it carries a stored
       * headline (YRD3). The hand-rolled parser cannot distinguish a bare
       * `key:` (null) from `key: {}`, so an empty mapping counts as "no
       * value" here. */
      if (value->type == YAML_SEQ) {
        set_err(err, vcat("scalar list item `", key, "` at `", path,
                          "` must hold a scalar", NULL));
        free(item_path);
        return 0;
      }
      if (value->type == YAML_MAP) {
        if (value->as.map.len > 0 &&
            !decoder_load_scalar_with_meta(d, item_path, key, value, err)) {
          free(item_path);
          return 0;
        }
        free(item_path);
        continue;
      }
      char *v = parsed_scalar_str(value);
      spec_document_set_content(d->doc, item_path, v);
      free(v);
      free(item_path);
      continue;
    }
    if (value->type != YAML_MAP) {
      set_err(err, vcat("list item `", key, "` at `", path,
                        "` must hold a mapping (use `{}` for an empty item)",
                        NULL));
      free(item_path);
      return 0;
    }
    if (!decoder_load_mapping(d, node->element_node, item_path, value, err)) {
      free(item_path);
      return 0;
    }
    free(item_path);
  }
  return 1;
}

static int decoder_load_child(YamlDecoder *d, const SomMetaNode *child,
                              const char *path, const char *key,
                              const YamlValue *value, char **err) {
  if (strcmp(child->kind, SOM_META_KIND_CONTENT) == 0 ||
      strcmp(child->kind, SOM_META_KIND_SCALAR) == 0 ||
      strcmp(child->kind, SOM_META_KIND_ENUM_VALUE) == 0) {
    /* A populated mapping is a headline-/codeSpec-extended scalar node
     * (YRD3 + codespecs_mapping.md §9.2): `{headline: …, codeSpec: …, content:
     * …}`. An empty mapping is the hand-rolled parser's spelling of a bare
     * `key:` and stays
     * the empty scalar. */
    if (value != NULL && value->type == YAML_MAP && value->as.map.len > 0) {
      return decoder_load_scalar_with_meta(d, path, key, value, err);
    }
    char *v = NULL;
    if (!decoder_scalar_of(value, path, &v, err)) {
      return 0;
    }
    spec_document_set_content(d->doc, path, v);
    free(v);
    return 1;
  }
  if (strcmp(child->kind, SOM_META_KIND_FORM) == 0) {
    if (value->type != YAML_MAP) {
      set_err(err, vcat("form `", key, "` at `", path,
                        "` must hold a field mapping", NULL));
      return 0;
    }
    for (size_t i = 0; i < value->as.map.len; i++) {
      const char *name = value->as.map.entries[i].key;
      const SomFormFieldMeta *field =
          som_form_meta_field_named(child->form, name);
      if (field == NULL) {
        if (strcmp(name, "headline") == 0) {
          /* The form section's own stored headline (YRD3). */
          char *where = vcat(path, " (headline)", NULL);
          char *hv = NULL;
          int ok = decoder_scalar_of(value->as.map.entries[i].value, where,
                                     &hv, err);
          free(where);
          if (!ok) {
            return 0;
          }
          spec_document_set_headline(d->doc, path, hv);
          free(hv);
          continue;
        }
        if (strcmp(name, "codeSpec") == 0) {
          /* The form section's own stored codeSpec (codespecs_mapping.md §9.2). */
          char *where = vcat(path, " (codeSpec)", NULL);
          char *cv = NULL;
          int ok = decoder_scalar_of(value->as.map.entries[i].value, where,
                                     &cv, err);
          free(where);
          if (!ok) {
            return 0;
          }
          spec_document_set_code_spec(d->doc, path, cv);
          free(cv);
          continue;
        }
        set_err(err, vcat("form `", path, "` has no field `", name,
                          "` in the model", NULL));
        return 0;
      }
      char *where = vcat(path, ".", name, NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value->as.map.entries[i].value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_form_field(d->doc, path, name, v);
      free(v);
    }
    return 1;
  }
  if (strcmp(child->kind, SOM_META_KIND_SECTION) == 0 ||
      strcmp(child->kind, SOM_META_KIND_COMPLEX) == 0) {
    if (value->type != YAML_MAP) {
      set_err(err, vcat("section `", key, "` at `", path,
                        "` must hold a mapping, not a scalar", NULL));
      return 0;
    }
    return decoder_load_mapping(d, child, path, value, err);
  }
  if (strcmp(child->kind, SOM_META_KIND_LIST) == 0) {
    if (value->type != YAML_MAP) {
      set_err(err, vcat("list `", key, "` at `", path,
                        "` must hold an item mapping", NULL));
      return 0;
    }
    return decoder_load_list(d, child, path, value, err);
  }
  return 1;
}

static int decoder_load_mapping(YamlDecoder *d, const SomMetaNode *node,
                                const char *path, const YamlValue *body,
                                char **err) {
  for (size_t i = 0; i < body->as.map.len; i++) {
    const char *key = body->as.map.entries[i].key;
    const YamlValue *value = body->as.map.entries[i].value;
    const SomMetaNode *child = decoder_child_by_key(node, key);
    if (child != NULL) {
      char *child_path = spec_path_join(path, som_meta_node_segment(child));
      int ok = decoder_load_child(d, child, child_path, key, value, err);
      free(child_path);
      if (!ok) {
        return 0;
      }
      continue;
    }
    if (strcmp(key, "content") == 0) {
      char *where = vcat(path, "/content", NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_content(d->doc, path, v);
      free(v);
      continue;
    }
    if (strcmp(key, "headline") == 0) {
      char *where = vcat(path, " (headline)", NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_headline(d->doc, path, v);
      free(v);
      continue;
    }
    if (strcmp(key, "codeSpec") == 0) {
      char *where = vcat(path, " (codeSpec)", NULL);
      char *v = NULL;
      int ok = decoder_scalar_of(value, where, &v, err);
      free(where);
      if (!ok) {
        return 0;
      }
      spec_document_set_code_spec(d->doc, path, v);
      free(v);
      continue;
    }
    char *name = som_meta_node_debug_name(node);
    char *expected = decoder_expected_keys(node);
    set_err(err, vcat("key `", key, "` under `", path,
                      "` matches no member of ", name, " (expected one of: ",
                      expected, ")", NULL));
    free(expected);
    free(name);
    return 0;
  }
  return 1;
}

int decode_yaml(const char *yaml_text, const SomMetaTree *tree,
                SpecYamlContents *out, char **err) {
  /* Blank input is not a mapping (Go leaves root nil for blank text). */
  const char *p = yaml_text;
  while (*p == ' ' || *p == '\t' || *p == '\r' || *p == '\n') {
    p++;
  }
  YamlValue *root = NULL;
  if (*p != '\0') {
    root = yaml_parse(yaml_text);
  }
  if (root == NULL || root->type != YAML_MAP) {
    yaml_value_free(root);
    set_err(err, som_strdup(
                     "not a *.docspecs.yaml mapping (expected version/document keys)"));
    return 0;
  }

  const YamlValue *version = yaml_get(root, "version");
  char *vstr = parsed_scalar_str(version);
  if (version == NULL || strcmp(vstr, "2") != 0) {
    char *msg;
    if (version == NULL) {
      msg = som_strdup("missing `version:` (expected version: 2)");
    } else if (strcmp(vstr, "1") == 0) {
      msg = som_strdup("format version 1 (flat path-map) is no longer "
                       "supported; re-save the document in the hierarchical "
                       "v2 format");
    } else {
      char *repr = version_repr(version);
      msg = vcat("unsupported format version `", repr, "` (expected 2)", NULL);
      free(repr);
    }
    free(vstr);
    yaml_value_free(root);
    set_err(err, msg);
    return 0;
  }
  free(vstr);

  char *stamp = parsed_scalar_str(yaml_get(root, "modelVersion"));

  const YamlValue *rev = yaml_get(root, "review");
  YamlValue *review = (rev != NULL && rev->type == YAML_MAP)
                          ? clone_yaml(rev)
                          : new_empty_map();

  SpecDocument document;
  spec_document_init(&document);
  free(document.model_version);
  document.model_version = som_strdup(stamp);

  const YamlValue *doc_pass = yaml_get(root, "document");
  if (doc_pass != NULL && doc_pass->type != YAML_MAP) {
    set_err(err, som_strdup("`document:` must be a mapping"));
    goto fail;
  }
  if (doc_pass != NULL && doc_pass->as.map.len > 0) {
    char *root_key = spec_yaml_node_key(tree->root);
    if (doc_pass->as.map.len != 1 ||
        strcmp(doc_pass->as.map.entries[0].key, root_key) != 0) {
      SomStrList found;
      som_strlist_init(&found);
      for (size_t i = 0; i < doc_pass->as.map.len; i++) {
        som_strlist_push(
            &found, vcat("`", doc_pass->as.map.entries[i].key, "`", NULL));
      }
      char *joined = som_strlist_join(&found, ", ");
      som_strlist_free(&found);
      set_err(err, vcat("expected the single document root key `", root_key,
                        "`, found: ", joined, NULL));
      free(joined);
      free(root_key);
      goto fail;
    }
    const YamlValue *body = doc_pass->as.map.entries[0].value;
    if (body->type != YAML_MAP) {
      set_err(err, vcat("root `", root_key,
                        "` must hold a mapping, not a scalar", NULL));
      free(root_key);
      goto fail;
    }
    free(root_key);
    YamlDecoder d = {&document, tree};
    if (!decoder_load_mapping(&d, tree->root,
                              som_meta_node_segment(tree->root), body, err)) {
      goto fail;
    }
  }

  yaml_value_free(root);
  out->document = document;
  out->review = review;
  out->model_version = stamp;
  return 1;

fail:
  spec_document_free(&document);
  yaml_value_free(review);
  free(stamp);
  yaml_value_free(root);
  return 0;
}
