#include "spec_document_yaml.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "som_util.h"
#include "yaml.h"

void spec_yaml_contents_free(SpecYamlContents *c) {
  document_json_free(&c->document);
  free(c->model_version);
  c->model_version = NULL;
}

/* js_json_string / yaml_key — JSON.stringify-compatible quoting. */
static char *js_json_string(const char *s) { return som_json_encode_str(s); }

static size_t trailing_newlines(const char *value) {
  size_t n = strlen(value);
  size_t count = 0;
  while (count < n && value[n - 1 - count] == '\n') {
    count++;
  }
  return count;
}

/* Builds a `|2<chomp>` literal block, or NULL when chomping can't reproduce the
 * value's trailing newlines (two or more). Owned result. */
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

/* Reports whether re-parsing `_v: <block>` yields exactly `value`. */
static int round_trips(const char *block, const char *value) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "_v: ");
  som_buf_puts(&b, block);
  som_buf_putc(&b, '\n');
  char *probe = som_buf_take(&b);
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

/* Writes `<indent><key>: <scalar>`, re-indenting body lines to key_indent+2. */
static void write_scalar(SomBuf *out, size_t key_indent, const char *key,
                         const char *value) {
  char *repr = scalar_repr(value);
  char *ek = js_json_string(key);
  for (size_t i = 0; i < key_indent; i++) {
    som_buf_putc(out, ' ');
  }
  som_buf_puts(out, ek);
  som_buf_puts(out, ": ");
  free(ek);
  /* repr.split('\n'): first line inline, rest re-indented. */
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
        for (size_t k = 0; k < key_indent; k++) {
          som_buf_putc(out, ' ');
        }
        som_buf_putn(out, repr + start, llen);
        som_buf_putc(out, '\n');
      }
      if (i == rlen) {
        break;
      }
      start = i + 1;
    }
  }
  free(repr);
}

static void write_header(SomBuf *out, const char *model_version) {
  som_buf_puts(out, "# TomSpecs document (*.docspecs.yaml).\n");
  som_buf_puts(out,
               "# `document:` holds the object-model values, sorted by section "
               "id; text\n");
  som_buf_puts(out,
               "# values use block scalars so multi-line content round-trips "
               "verbatim (\xC2\xA7""15.1).\n");
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

static void write_document_pass(SomBuf *out, const DocumentJson *doc) {
  if (doc->content.len == 0 && doc->forms_len == 0 && doc->lists_len == 0) {
    som_buf_puts(out, "document: {}\n");
    return;
  }
  som_buf_puts(out, "document:\n");

  if (doc->content.len > 0) {
    som_buf_puts(out, "  content:\n");
    for (size_t i = 0; i < doc->content.len; i++) {
      write_scalar(out, 4, doc->content.entries[i].key,
                   doc->content.entries[i].val);
    }
  }

  if (doc->forms_len > 0) {
    som_buf_puts(out, "  forms:\n");
    for (size_t i = 0; i < doc->forms_len; i++) {
      const DocFormEntry *e = &doc->forms[i];
      if (e->fields.len == 0) {
        continue;
      }
      char *ek = js_json_string(e->key);
      som_buf_puts(out, "    ");
      som_buf_puts(out, ek);
      som_buf_puts(out, ":\n");
      free(ek);
      for (size_t j = 0; j < e->fields.len; j++) {
        write_scalar(out, 6, e->fields.entries[j].key,
                     e->fields.entries[j].val);
      }
    }
  }

  if (doc->lists_len > 0) {
    som_buf_puts(out, "  lists:\n");
    for (size_t i = 0; i < doc->lists_len; i++) {
      const DocListEntry *e = &doc->lists[i];
      char *ek = js_json_string(e->key);
      som_buf_puts(out, "    ");
      som_buf_puts(out, ek);
      som_buf_puts(out, ":\n");
      free(ek);
      som_buf_puts(out, "      seq: ");
      som_buf_puti(out, e->seq);
      som_buf_putc(out, '\n');
      if (e->items.len > 0) {
        som_buf_puts(out, "      items:\n");
        for (size_t j = 0; j < e->items.len; j++) {
          char *it = js_json_string(e->items.items[j]);
          som_buf_puts(out, "        - ");
          som_buf_puts(out, it);
          som_buf_putc(out, '\n');
          free(it);
        }
      } else {
        som_buf_puts(out, "      items: []\n");
      }
    }
  }
}

char *encode_yaml(const SpecDocument *document, const char *model_version) {
  SomBuf out;
  som_buf_init(&out);
  write_header(&out, model_version);
  DocumentJson dj;
  spec_document_to_json(document, &dj);
  write_document_pass(&out, &dj);
  document_json_free(&dj);
  return som_buf_take(&out);
}

/* Converts the parsed `document:` mapping into a DocumentJson. */
static void doc_json_from_yaml(const YamlValue *v, DocumentJson *out) {
  document_json_init(out);
  if (v == NULL || v->type != YAML_MAP) {
    return;
  }
  const YamlValue *content = yaml_get(v, "content");
  if (content != NULL && content->type == YAML_MAP) {
    for (size_t i = 0; i < content->as.map.len; i++) {
      char *s = yaml_scalar_string(content->as.map.entries[i].value);
      som_map_set(&out->content, content->as.map.entries[i].key, s);
      free(s);
    }
  }
  const YamlValue *forms = yaml_get(v, "forms");
  if (forms != NULL && forms->type == YAML_MAP) {
    for (size_t i = 0; i < forms->as.map.len; i++) {
      const YamlValue *fv = forms->as.map.entries[i].value;
      if (fv->type != YAML_MAP) {
        continue;
      }
      SomMap *fields =
          document_json_form_fields(out, forms->as.map.entries[i].key);
      for (size_t j = 0; j < fv->as.map.len; j++) {
        char *s = yaml_scalar_string(fv->as.map.entries[j].value);
        som_map_set(fields, fv->as.map.entries[j].key, s);
        free(s);
      }
    }
  }
  const YamlValue *lists = yaml_get(v, "lists");
  if (lists != NULL && lists->type == YAML_MAP) {
    for (size_t i = 0; i < lists->as.map.len; i++) {
      const YamlValue *spec = lists->as.map.entries[i].value;
      if (spec->type != YAML_MAP) {
        continue;
      }
      DocListEntry *e =
          document_json_list_entry(out, lists->as.map.entries[i].key);
      long long seq = 0;
      yaml_as_int(yaml_get(spec, "seq"), &seq);
      e->seq = seq;
      const YamlValue *items = yaml_get(spec, "items");
      if (items != NULL && items->type == YAML_SEQ) {
        for (size_t j = 0; j < items->as.seq.len; j++) {
          char *s = yaml_scalar_string(items->as.seq.items[j]);
          som_strlist_push(&e->items, s);
        }
      }
    }
  }
}

void decode_yaml(const char *yaml_text, SpecYamlContents *out) {
  YamlValue *root;
  /* blank → empty map */
  char *trimmed = NULL;
  {
    size_t n = strlen(yaml_text);
    size_t s = 0, e = n;
    while (s < e && (yaml_text[s] == ' ' || yaml_text[s] == '\t' ||
                     yaml_text[s] == '\r' || yaml_text[s] == '\n')) {
      s++;
    }
    trimmed = som_strdup_n(yaml_text + s, e - s);
  }
  if (trimmed[0] == '\0') {
    root = yaml_parse("");
  } else {
    root = yaml_parse(yaml_text);
  }
  free(trimmed);

  doc_json_from_yaml(yaml_get(root, "document"), &out->document);

  const char *mv = yaml_as_str(yaml_get(root, "modelVersion"));
  out->model_version = som_strdup(mv != NULL ? mv : "");

  yaml_value_free(root);
}
