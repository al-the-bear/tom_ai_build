#include "yaml.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "som_util.h"

/* ---- value constructors / accessors ------------------------------------- */

static YamlValue *yaml_new(YamlType t) {
  YamlValue *v = (YamlValue *)calloc(1, sizeof(YamlValue));
  v->type = t;
  return v;
}

static YamlValue *yaml_new_map(void) { return yaml_new(YAML_MAP); }
static YamlValue *yaml_new_seq(void) { return yaml_new(YAML_SEQ); }

static YamlValue *yaml_new_str(char *owned) {
  YamlValue *v = yaml_new(YAML_STR);
  v->as.str = owned;
  return v;
}

static YamlValue *yaml_new_int(long long n) {
  YamlValue *v = yaml_new(YAML_INT);
  v->as.integer = n;
  return v;
}

void yaml_value_free(YamlValue *v) {
  if (v == NULL) {
    return;
  }
  switch (v->type) {
    case YAML_MAP:
      for (size_t i = 0; i < v->as.map.len; i++) {
        free(v->as.map.entries[i].key);
        yaml_value_free(v->as.map.entries[i].value);
      }
      free(v->as.map.entries);
      break;
    case YAML_SEQ:
      for (size_t i = 0; i < v->as.seq.len; i++) {
        yaml_value_free(v->as.seq.items[i]);
      }
      free(v->as.seq.items);
      break;
    case YAML_STR:
      free(v->as.str);
      break;
    case YAML_INT:
      break;
  }
  free(v);
}

/* Inserts/replaces `key`→`value` (key copied, value owned), keeping the map
 * byte-sorted by key. */
static void map_set(YamlValue *m, const char *key, YamlValue *value) {
  size_t lo = 0, hi = m->as.map.len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(m->as.map.entries[mid].key, key);
    if (cmp == 0) {
      yaml_value_free(m->as.map.entries[mid].value);
      m->as.map.entries[mid].value = value;
      return;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  if (m->as.map.len == m->as.map.cap) {
    m->as.map.cap = m->as.map.cap ? m->as.map.cap * 2 : 4;
    m->as.map.entries = (YamlMapEntry *)realloc(
        m->as.map.entries, m->as.map.cap * sizeof(YamlMapEntry));
  }
  memmove(&m->as.map.entries[lo + 1], &m->as.map.entries[lo],
          (m->as.map.len - lo) * sizeof(YamlMapEntry));
  m->as.map.entries[lo].key = som_strdup(key);
  m->as.map.entries[lo].value = value;
  m->as.map.len++;
}

static void seq_push(YamlValue *s, YamlValue *item) {
  if (s->as.seq.len == s->as.seq.cap) {
    s->as.seq.cap = s->as.seq.cap ? s->as.seq.cap * 2 : 4;
    s->as.seq.items = (YamlValue **)realloc(
        s->as.seq.items, s->as.seq.cap * sizeof(YamlValue *));
  }
  s->as.seq.items[s->as.seq.len++] = item;
}

const YamlValue *yaml_get(const YamlValue *v, const char *key) {
  if (v == NULL || v->type != YAML_MAP) {
    return NULL;
  }
  for (size_t i = 0; i < v->as.map.len; i++) {
    if (strcmp(v->as.map.entries[i].key, key) == 0) {
      return v->as.map.entries[i].value;
    }
  }
  return NULL;
}

const char *yaml_as_str(const YamlValue *v) {
  return (v != NULL && v->type == YAML_STR) ? v->as.str : NULL;
}

int yaml_as_int(const YamlValue *v, long long *out) {
  if (v != NULL && v->type == YAML_INT) {
    *out = v->as.integer;
    return 1;
  }
  return 0;
}

char *yaml_scalar_string(const YamlValue *v) {
  if (v == NULL) {
    return som_strdup("");
  }
  if (v->type == YAML_STR) {
    return som_strdup(v->as.str);
  }
  if (v->type == YAML_INT) {
    return som_format_i64(v->as.integer);
  }
  return som_strdup("");
}

/* ---- small string helpers ----------------------------------------------- */

static int is_ws(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

/* Copies s[0..n), trims ASCII whitespace from both ends. Owned result. */
static char *trim_dup(const char *s, size_t n) {
  size_t start = 0, end = n;
  while (start < end && is_ws(s[start])) {
    start++;
  }
  while (end > start && is_ws(s[end - 1])) {
    end--;
  }
  return som_strdup_n(s + start, end - start);
}

static size_t yaml_leading(const char *line) {
  size_t i = 0;
  while (line[i] == ' ') {
    i++;
  }
  return i;
}

static int yaml_is_integer(const char *s) {
  if (s[0] == '\0') {
    return 0;
  }
  size_t i = 0;
  if (s[0] == '-' || s[0] == '+') {
    if (s[1] == '\0') {
      return 0;
    }
    i = 1;
  }
  for (; s[i] != '\0'; i++) {
    if (s[i] < '0' || s[i] > '9') {
      return 0;
    }
  }
  return 1;
}

/* Index of the structural ':' in `content`, or -1. Mirrors yaml_find_colon. */
static long find_colon(const char *content) {
  if (content[0] == '"') {
    size_t i = 1;
    while (content[i] != '\0') {
      char c = content[i];
      if (c == '\\') {
        i += 2;
        continue;
      }
      if (c == '"') {
        i += 1;
        break;
      }
      i += 1;
    }
    for (; content[i] != '\0'; i++) {
      if (content[i] == ':') {
        return (long)i;
      }
    }
    return -1;
  }
  for (size_t i = 0; content[i] != '\0'; i++) {
    if (content[i] == ':') {
      return (long)i;
    }
  }
  return -1;
}

/* Parses a JSON-quoted scalar string, or returns it verbatim. Owned result.
 * `for_key`: when true a non-string parse yields "". */
static char *parse_quoted(const char *t, int for_key) {
  if (t[0] == '"') {
    char *err = NULL;
    SomJson *j = som_json_parse(t, &err);
    char *out;
    if (j != NULL && j->type == SOM_JSON_STR) {
      out = som_strdup(j->as.str);
    } else {
      out = for_key ? som_strdup("") : som_strdup(t);
    }
    som_json_free(j);
    free(err);
    return out;
  }
  return som_strdup(t);
}

static int line_is_blank_or_comment(const char *line) {
  char *t = trim_dup(line, strlen(line));
  int r = (t[0] == '\0' || t[0] == '#');
  free(t);
  return r;
}

/* ---- reader ------------------------------------------------------------- */

typedef struct {
  SomStrList lines;
  size_t idx;
} YamlReader;

static long next_significant(YamlReader *r, size_t from) {
  for (size_t i = from; i < r->lines.len; i++) {
    if (!line_is_blank_or_comment(r->lines.items[i])) {
      return (long)i;
    }
  }
  return -1;
}

static YamlValue *parse_node(YamlReader *r, size_t min_indent);
static YamlValue *parse_mapping(YamlReader *r, size_t indent);
static YamlValue *parse_sequence(YamlReader *r, size_t indent);
static YamlValue *parse_nested_after_key(YamlReader *r, size_t parent_indent);
static YamlValue *parse_flow_scalar(const char *s);
static char *parse_block_scalar(YamlReader *r, const char *header,
                                size_t key_indent);

static YamlValue *parse_node(YamlReader *r, size_t min_indent) {
  long i = next_significant(r, r->idx);
  if (i < 0) {
    return yaml_new_map();
  }
  const char *line = r->lines.items[i];
  size_t indent = yaml_leading(line);
  if (indent < min_indent) {
    return yaml_new_map();
  }
  const char *content = line + indent;
  if (strcmp(content, "-") == 0 || strncmp(content, "- ", 2) == 0) {
    return parse_sequence(r, indent);
  }
  return parse_mapping(r, indent);
}

static YamlValue *parse_mapping(YamlReader *r, size_t indent) {
  YamlValue *m = yaml_new_map();
  for (;;) {
    long i = next_significant(r, r->idx);
    if (i < 0) {
      break;
    }
    const char *line = r->lines.items[i];
    size_t cur_indent = yaml_leading(line);
    if (cur_indent != indent) {
      break; /* dedent → belongs to the parent. */
    }
    r->idx = (size_t)i + 1;
    const char *content = line + indent;
    long colon = find_colon(content);
    if (colon < 0) {
      continue; /* not a mapping entry — tolerate and skip. */
    }
    char *key_part = trim_dup(content, (size_t)colon);
    char *key = parse_quoted(key_part, 1);
    free(key_part);
    char *rest = trim_dup(content + colon + 1, strlen(content + colon + 1));
    YamlValue *value;
    if (rest[0] == '\0') {
      value = parse_nested_after_key(r, indent);
    } else if (rest[0] == '|' || rest[0] == '>') {
      value = yaml_new_str(parse_block_scalar(r, rest, indent));
    } else {
      value = parse_flow_scalar(rest);
    }
    map_set(m, key, value);
    free(key);
    free(rest);
  }
  return m;
}

static YamlValue *parse_sequence(YamlReader *r, size_t indent) {
  YamlValue *list = yaml_new_seq();
  for (;;) {
    long i = next_significant(r, r->idx);
    if (i < 0) {
      break;
    }
    const char *line = r->lines.items[i];
    size_t cur_indent = yaml_leading(line);
    if (cur_indent != indent) {
      break;
    }
    const char *content = line + indent;
    if (strcmp(content, "-") != 0 && strncmp(content, "- ", 2) != 0) {
      break;
    }
    r->idx = (size_t)i + 1;
    char *item_text;
    if (strcmp(content, "-") == 0) {
      item_text = som_strdup("");
    } else {
      item_text = trim_dup(content + 2, strlen(content + 2));
    }
    if (item_text[0] == '\0') {
      seq_push(list, parse_nested_after_key(r, indent));
    } else if (item_text[0] == '|' || item_text[0] == '>') {
      seq_push(list, yaml_new_str(parse_block_scalar(r, item_text, indent)));
    } else {
      seq_push(list, parse_flow_scalar(item_text));
    }
    free(item_text);
  }
  return list;
}

static YamlValue *parse_nested_after_key(YamlReader *r, size_t parent_indent) {
  long i = next_significant(r, r->idx);
  if (i < 0) {
    return yaml_new_map();
  }
  size_t child_indent = yaml_leading(r->lines.items[i]);
  if (child_indent <= parent_indent) {
    return yaml_new_map();
  }
  return parse_node(r, child_indent);
}

static YamlValue *parse_flow_scalar(const char *s) {
  char *t = trim_dup(s, strlen(s));
  YamlValue *out;
  if (strcmp(t, "{}") == 0) {
    out = yaml_new_map();
  } else if (strcmp(t, "[]") == 0) {
    out = yaml_new_seq();
  } else if (t[0] == '"') {
    out = yaml_new_str(parse_quoted(t, 0));
  } else if (yaml_is_integer(t)) {
    long long n;
    if (som_parse_i64(t, &n)) {
      out = yaml_new_int(n);
    } else {
      out = yaml_new_str(som_strdup(t));
    }
  } else {
    out = yaml_new_str(som_strdup(t));
  }
  free(t);
  return out;
}

static char *parse_block_scalar(YamlReader *r, const char *header,
                                size_t key_indent) {
  size_t hlen = strlen(header);
  size_t p = 1; /* skip the leading '|' (or '>'). */
  size_t digits_start = p;
  while (p < hlen && header[p] >= '0' && header[p] <= '9') {
    p++;
  }
  int has_explicit = (p > digits_start);
  long long explicit_indent = 0;
  if (has_explicit) {
    char *d = som_strdup_n(header + digits_start, p - digits_start);
    som_parse_i64(d, &explicit_indent);
    free(d);
  }
  char chomp = ' ';
  while (p < hlen) {
    char c = header[p];
    if (c == '-' || c == '+') {
      chomp = c;
    }
    p++;
  }

  /* Collect the raw body: blank lines plus any line indented past the key. */
  SomStrList raw;
  som_strlist_init(&raw);
  while (r->idx < r->lines.len) {
    const char *l = r->lines.items[r->idx];
    char *t = trim_dup(l, strlen(l));
    int blank = (t[0] == '\0');
    free(t);
    if (blank) {
      som_strlist_push_copy(&raw, "");
      r->idx++;
      continue;
    }
    if (yaml_leading(l) <= key_indent) {
      break;
    }
    som_strlist_push_copy(&raw, l);
    r->idx++;
  }
  /* Drop trailing blank lines that belong to the following node. */
  while (raw.len > 0 && raw.items[raw.len - 1][0] == '\0') {
    som_strlist_remove_at(&raw, raw.len - 1);
  }

  size_t content_indent;
  if (has_explicit) {
    content_indent = key_indent + (size_t)explicit_indent;
  } else {
    size_t min = (size_t)-1;
    for (size_t i = 0; i < raw.len; i++) {
      if (raw.items[i][0] != '\0') {
        size_t ld = yaml_leading(raw.items[i]);
        if (ld < min) {
          min = ld;
        }
      }
    }
    content_indent = (min == (size_t)-1) ? key_indent + 1 : min;
  }

  SomBuf body;
  som_buf_init(&body);
  for (size_t i = 0; i < raw.len; i++) {
    if (i > 0) {
      som_buf_putc(&body, '\n');
    }
    const char *l = raw.items[i];
    if (l[0] != '\0') {
      size_t len = strlen(l);
      size_t strip = content_indent < len ? content_indent : len;
      som_buf_puts(&body, l + strip);
    }
  }
  som_strlist_free(&raw);
  char *joined = som_buf_take(&body);

  /* chomping */
  size_t jlen = strlen(joined);
  if (chomp == '+') {
    return joined; /* keep */
  }
  /* trim trailing '\n' */
  size_t end = jlen;
  while (end > 0 && joined[end - 1] == '\n') {
    end--;
  }
  if (chomp == '-') {
    char *out = som_strdup_n(joined, end);
    free(joined);
    return out;
  }
  /* clip (default): exactly one trailing newline when non-empty. */
  if (end == 0) {
    free(joined);
    return som_strdup("");
  }
  SomBuf out;
  som_buf_init(&out);
  som_buf_putn(&out, joined, end);
  som_buf_putc(&out, '\n');
  free(joined);
  return som_buf_take(&out);
}

/* ---- entry points ------------------------------------------------------- */

static void split_lines(const char *text, SomStrList *out) {
  som_strlist_init(out);
  const char *start = text;
  for (const char *p = text;; p++) {
    if (*p == '\n' || *p == '\0') {
      som_strlist_push(out, som_strdup_n(start, (size_t)(p - start)));
      if (*p == '\0') {
        break;
      }
      start = p + 1;
    }
  }
}

YamlValue *yaml_parse(const char *text) {
  YamlReader r;
  split_lines(text, &r.lines);
  r.idx = 0;
  YamlValue *result;
  if (next_significant(&r, 0) < 0) {
    result = yaml_new_map();
  } else {
    result = parse_node(&r, 0);
  }
  som_strlist_free(&r.lines);
  return result;
}

YamlValue *yaml_parse_map(const char *text) {
  YamlValue *v = yaml_parse(text);
  if (v->type == YAML_MAP) {
    return v;
  }
  yaml_value_free(v);
  return yaml_new_map();
}
