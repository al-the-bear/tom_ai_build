#include "som_json.h"

#include <stdlib.h>
#include <string.h>

#include "som_util.h"

/* ---- value construction / teardown -------------------------------------- */

static SomJson *json_new(SomJsonType t) {
  SomJson *v = (SomJson *)calloc(1, sizeof(SomJson));
  v->type = t;
  return v;
}

void som_json_free(SomJson *v) {
  if (v == NULL) {
    return;
  }
  switch (v->type) {
    case SOM_JSON_STR:
      free(v->as.str);
      break;
    case SOM_JSON_ARRAY:
      for (size_t i = 0; i < v->as.array.len; i++) {
        som_json_free(v->as.array.items[i]);
      }
      free(v->as.array.items);
      break;
    case SOM_JSON_OBJECT:
      for (size_t i = 0; i < v->as.object.len; i++) {
        free(v->as.object.members[i].key);
        som_json_free(v->as.object.members[i].value);
      }
      free(v->as.object.members);
      break;
    default:
      break;
  }
  free(v);
}

/* ---- accessors ---------------------------------------------------------- */

const SomJson *som_json_get(const SomJson *v, const char *key) {
  if (v == NULL || v->type != SOM_JSON_OBJECT) {
    return NULL;
  }
  for (size_t i = 0; i < v->as.object.len; i++) {
    if (strcmp(v->as.object.members[i].key, key) == 0) {
      return v->as.object.members[i].value;
    }
  }
  return NULL;
}

const char *som_json_as_str(const SomJson *v) {
  if (v != NULL && v->type == SOM_JSON_STR) {
    return v->as.str;
  }
  return NULL;
}

int som_json_as_i64(const SomJson *v, long long *out) {
  if (v == NULL) {
    return 0;
  }
  if (v->type == SOM_JSON_INT) {
    *out = v->as.integer;
    return 1;
  }
  if (v->type == SOM_JSON_FLOAT) {
    double f = v->as.real;
    if (f == (double)(long long)f) {
      *out = (long long)f;
      return 1;
    }
  }
  return 0;
}

int som_json_as_bool(const SomJson *v, int *out) {
  if (v != NULL && v->type == SOM_JSON_BOOL) {
    *out = v->as.boolean;
    return 1;
  }
  return 0;
}

const SomJson *som_json_array_at(const SomJson *v, size_t i) {
  if (v != NULL && v->type == SOM_JSON_ARRAY && i < v->as.array.len) {
    return v->as.array.items[i];
  }
  return NULL;
}

size_t som_json_array_len(const SomJson *v) {
  if (v != NULL && v->type == SOM_JSON_ARRAY) {
    return v->as.array.len;
  }
  return 0;
}

const char *som_json_str_or(const SomJson *v, const char *key) {
  const char *s = som_json_as_str(som_json_get(v, key));
  return s != NULL ? s : "";
}

int som_json_bool_or(const SomJson *v, const char *key) {
  int b = 0;
  if (som_json_as_bool(som_json_get(v, key), &b)) {
    return b;
  }
  return 0;
}

/* ---- encode_str --------------------------------------------------------- */

char *som_json_encode_str(const char *s) {
  static const char HEX[] = "0123456789abcdef";
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '"');
  for (const unsigned char *p = (const unsigned char *)s; *p != '\0'; p++) {
    unsigned char c = *p;
    switch (c) {
      case '"':
        som_buf_puts(&b, "\\\"");
        break;
      case '\\':
        som_buf_puts(&b, "\\\\");
        break;
      case '\b':
        som_buf_puts(&b, "\\b");
        break;
      case '\f':
        som_buf_puts(&b, "\\f");
        break;
      case '\n':
        som_buf_puts(&b, "\\n");
        break;
      case '\r':
        som_buf_puts(&b, "\\r");
        break;
      case '\t':
        som_buf_puts(&b, "\\t");
        break;
      default:
        if (c < 0x20) {
          som_buf_puts(&b, "\\u00");
          som_buf_putc(&b, HEX[(c >> 4) & 0xf]);
          som_buf_putc(&b, HEX[c & 0xf]);
        } else {
          som_buf_putc(&b, (char)c);
        }
        break;
    }
  }
  som_buf_putc(&b, '"');
  return som_buf_take(&b);
}

/* ---- parser ------------------------------------------------------------- */

typedef struct {
  const char *s;
  size_t len;
  size_t idx;
  char *err; /* owned once set */
} Parser;

static void p_fail(Parser *p, const char *msg) {
  if (p->err == NULL) {
    p->err = som_strdup(msg);
  }
}

static int p_peek(Parser *p) {
  if (p->idx < p->len) {
    return (unsigned char)p->s[p->idx];
  }
  return -1;
}

static void p_skip_ws(Parser *p) {
  while (p->idx < p->len) {
    char c = p->s[p->idx];
    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
      p->idx++;
    } else {
      break;
    }
  }
}

static SomJson *p_value(Parser *p);

/* Appends the UTF-8 encoding of codepoint `cp` to `b`. */
static void utf8_append(SomBuf *b, unsigned int cp) {
  if (cp <= 0x7f) {
    som_buf_putc(b, (char)cp);
  } else if (cp <= 0x7ff) {
    som_buf_putc(b, (char)(0xc0 | (cp >> 6)));
    som_buf_putc(b, (char)(0x80 | (cp & 0x3f)));
  } else if (cp <= 0xffff) {
    som_buf_putc(b, (char)(0xe0 | (cp >> 12)));
    som_buf_putc(b, (char)(0x80 | ((cp >> 6) & 0x3f)));
    som_buf_putc(b, (char)(0x80 | (cp & 0x3f)));
  } else {
    som_buf_putc(b, (char)(0xf0 | (cp >> 18)));
    som_buf_putc(b, (char)(0x80 | ((cp >> 12) & 0x3f)));
    som_buf_putc(b, (char)(0x80 | ((cp >> 6) & 0x3f)));
    som_buf_putc(b, (char)(0x80 | (cp & 0x3f)));
  }
}

static int p_hex4(Parser *p, unsigned int *out) {
  unsigned int v = 0;
  for (int k = 0; k < 4; k++) {
    if (p->idx >= p->len) {
      p_fail(p, "unterminated \\u escape");
      return 0;
    }
    char c = p->s[p->idx++];
    unsigned int d;
    if (c >= '0' && c <= '9') {
      d = (unsigned int)(c - '0');
    } else if (c >= 'a' && c <= 'f') {
      d = (unsigned int)(c - 'a' + 10);
    } else if (c >= 'A' && c <= 'F') {
      d = (unsigned int)(c - 'A' + 10);
    } else {
      p_fail(p, "bad hex digit");
      return 0;
    }
    v = v * 16 + d;
  }
  *out = v;
  return 1;
}

/* Parses a string starting at the opening quote. Returns an owned char* or NULL
 * on error. */
static char *p_string(Parser *p) {
  p->idx++; /* opening '"' */
  SomBuf b;
  som_buf_init(&b);
  for (;;) {
    if (p->idx >= p->len) {
      p_fail(p, "unterminated string");
      som_buf_free(&b);
      return NULL;
    }
    char c = p->s[p->idx++];
    if (c == '"') {
      break;
    }
    if (c == '\\') {
      if (p->idx >= p->len) {
        p_fail(p, "unterminated escape");
        som_buf_free(&b);
        return NULL;
      }
      char esc = p->s[p->idx++];
      switch (esc) {
        case '"':
          som_buf_putc(&b, '"');
          break;
        case '\\':
          som_buf_putc(&b, '\\');
          break;
        case '/':
          som_buf_putc(&b, '/');
          break;
        case 'b':
          som_buf_putc(&b, '\b');
          break;
        case 'f':
          som_buf_putc(&b, '\f');
          break;
        case 'n':
          som_buf_putc(&b, '\n');
          break;
        case 'r':
          som_buf_putc(&b, '\r');
          break;
        case 't':
          som_buf_putc(&b, '\t');
          break;
        case 'u': {
          unsigned int cp;
          if (!p_hex4(p, &cp)) {
            som_buf_free(&b);
            return NULL;
          }
          if (cp >= 0xD800 && cp <= 0xDBFF) {
            /* high surrogate — expect a following \uXXXX low surrogate. */
            if (p_peek(p) == '\\' && p->idx + 1 < p->len && p->s[p->idx + 1] == 'u') {
              p->idx += 2;
              unsigned int low;
              if (!p_hex4(p, &low)) {
                som_buf_free(&b);
                return NULL;
              }
              if (low >= 0xDC00 && low <= 0xDFFF) {
                unsigned int combined =
                    0x10000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                utf8_append(&b, combined);
              } else {
                utf8_append(&b, 0xFFFD);
                utf8_append(&b, low);
              }
            } else {
              utf8_append(&b, 0xFFFD);
            }
          } else {
            utf8_append(&b, cp);
          }
          break;
        }
        default:
          p_fail(p, "invalid escape");
          som_buf_free(&b);
          return NULL;
      }
    } else {
      som_buf_putc(&b, c);
    }
  }
  return som_buf_take(&b);
}

static SomJson *p_object(Parser *p) {
  p->idx++; /* '{' */
  SomJson *v = json_new(SOM_JSON_OBJECT);
  size_t cap = 0;
  p_skip_ws(p);
  if (p_peek(p) == '}') {
    p->idx++;
    return v;
  }
  for (;;) {
    p_skip_ws(p);
    if (p_peek(p) != '"') {
      p_fail(p, "expected object key");
      som_json_free(v);
      return NULL;
    }
    char *key = p_string(p);
    if (key == NULL) {
      som_json_free(v);
      return NULL;
    }
    p_skip_ws(p);
    if (p_peek(p) != ':') {
      p_fail(p, "expected ':'");
      free(key);
      som_json_free(v);
      return NULL;
    }
    p->idx++;
    SomJson *val = p_value(p);
    if (val == NULL) {
      free(key);
      som_json_free(v);
      return NULL;
    }
    if (v->as.object.len == cap) {
      cap = cap == 0 ? 8 : cap * 2;
      v->as.object.members =
          (SomJsonMember *)realloc(v->as.object.members, cap * sizeof(SomJsonMember));
    }
    v->as.object.members[v->as.object.len].key = key;
    v->as.object.members[v->as.object.len].value = val;
    v->as.object.len++;
    p_skip_ws(p);
    int c = p_peek(p);
    if (c == ',') {
      p->idx++;
    } else if (c == '}') {
      p->idx++;
      break;
    } else {
      p_fail(p, "expected ',' or '}'");
      som_json_free(v);
      return NULL;
    }
  }
  return v;
}

static SomJson *p_array(Parser *p) {
  p->idx++; /* '[' */
  SomJson *v = json_new(SOM_JSON_ARRAY);
  size_t cap = 0;
  p_skip_ws(p);
  if (p_peek(p) == ']') {
    p->idx++;
    return v;
  }
  for (;;) {
    SomJson *item = p_value(p);
    if (item == NULL) {
      som_json_free(v);
      return NULL;
    }
    if (v->as.array.len == cap) {
      cap = cap == 0 ? 8 : cap * 2;
      v->as.array.items = (SomJson **)realloc(v->as.array.items, cap * sizeof(SomJson *));
    }
    v->as.array.items[v->as.array.len++] = item;
    p_skip_ws(p);
    int c = p_peek(p);
    if (c == ',') {
      p->idx++;
    } else if (c == ']') {
      p->idx++;
      break;
    } else {
      p_fail(p, "expected ',' or ']'");
      som_json_free(v);
      return NULL;
    }
  }
  return v;
}

static int p_matches(Parser *p, const char *lit) {
  size_t n = strlen(lit);
  if (p->idx + n > p->len) {
    return 0;
  }
  if (memcmp(p->s + p->idx, lit, n) != 0) {
    return 0;
  }
  p->idx += n;
  return 1;
}

static SomJson *p_number(Parser *p) {
  size_t start = p->idx;
  int is_float = 0;
  if (p_peek(p) == '-') {
    p->idx++;
  }
  while (p->idx < p->len) {
    char c = p->s[p->idx];
    if (c >= '0' && c <= '9') {
      p->idx++;
    } else if (c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-') {
      is_float = 1;
      p->idx++;
    } else {
      break;
    }
  }
  char *num = som_strdup_n(p->s + start, p->idx - start);
  SomJson *v;
  if (is_float) {
    v = json_new(SOM_JSON_FLOAT);
    v->as.real = strtod(num, NULL);
  } else {
    long long iv;
    if (som_parse_i64(num, &iv)) {
      v = json_new(SOM_JSON_INT);
      v->as.integer = iv;
    } else {
      v = json_new(SOM_JSON_FLOAT);
      v->as.real = strtod(num, NULL);
    }
  }
  free(num);
  return v;
}

static SomJson *p_value(Parser *p) {
  p_skip_ws(p);
  int c = p_peek(p);
  switch (c) {
    case '{':
      return p_object(p);
    case '[':
      return p_array(p);
    case '"': {
      char *s = p_string(p);
      if (s == NULL) {
        return NULL;
      }
      SomJson *v = json_new(SOM_JSON_STR);
      v->as.str = s;
      return v;
    }
    case 't':
    case 'f': {
      if (p_matches(p, "true")) {
        SomJson *v = json_new(SOM_JSON_BOOL);
        v->as.boolean = 1;
        return v;
      }
      if (p_matches(p, "false")) {
        SomJson *v = json_new(SOM_JSON_BOOL);
        v->as.boolean = 0;
        return v;
      }
      p_fail(p, "invalid literal");
      return NULL;
    }
    case 'n':
      if (p_matches(p, "null")) {
        return json_new(SOM_JSON_NULL);
      }
      p_fail(p, "invalid literal");
      return NULL;
    default:
      if (c == '-' || (c >= '0' && c <= '9')) {
        return p_number(p);
      }
      p_fail(p, "unexpected token");
      return NULL;
  }
}

SomJson *som_json_parse(const char *text, char **err) {
  Parser p;
  p.s = text;
  p.len = strlen(text);
  p.idx = 0;
  p.err = NULL;
  p_skip_ws(&p);
  SomJson *v = p_value(&p);
  if (v == NULL) {
    if (err != NULL) {
      *err = p.err != NULL ? p.err : som_strdup("parse error");
    } else {
      free(p.err);
    }
    return NULL;
  }
  p_skip_ws(&p);
  if (p.idx != p.len) {
    som_json_free(v);
    if (err != NULL) {
      *err = som_strdup("trailing data");
    }
    free(p.err);
    return NULL;
  }
  if (err != NULL) {
    *err = NULL;
  }
  return v;
}
