/* spec_notation — the reading notation's scanner (see spec_notation.h).
 *
 * A port of the TypeScript `spec_notation.ts` `_Scanner`, line for line where
 * the languages allow: the regular expressions are matched by hand, the scan
 * works on UTF-8 byte offsets, and the UTF-16 offsets the corpus counts in are
 * derived once at the end. Whitespace is JavaScript's `\s` (ASCII plus the
 * Unicode space separators), so `trim` and `\s` agree with the other ports.
 */
#include "spec_notation.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"

const char *const
    SPEC_REGISTERED_NOTATION_KINDS[SPEC_REGISTERED_NOTATION_KINDS_COUNT] = {
        "provenance", "trace", "editorial", "aside",    "linked",
        "derived",    "refs",  "records",   "rejected",
};

int spec_notation_kind_registered(const char *kind) {
  if (kind == NULL) return 0;
  for (size_t i = 0; i < SPEC_REGISTERED_NOTATION_KINDS_COUNT; i++) {
    if (strcmp(kind, SPEC_REGISTERED_NOTATION_KINDS[i]) == 0) return 1;
  }
  return 0;
}

const char *spec_notation_element_type_name(SpecNotationElementType t) {
  switch (t) {
  case SPEC_NOTATION_DIV:
    return "div";
  case SPEC_NOTATION_SPAN:
    return "span";
  case SPEC_NOTATION_CITATION:
    return "citation";
  }
  return "div";
}

static const char *const kCodeNames[SPEC_NOTATION_FINDING_CODE_COUNT] = {
    "unclosedDiv",          "strayClosingFence",   "unclosedSpan",
    "divWithoutKind",       "unknownKind",         "markAcrossNotation",
    "annotationInsideDiv",  "divInsideAnnotation", "rejectedBlock",
};

const char *spec_notation_finding_code_name(SpecNotationFindingCode code) {
  if ((int)code < 0 || (int)code >= SPEC_NOTATION_FINDING_CODE_COUNT) {
    return "";
  }
  return kCodeNames[code];
}

const char *spec_notation_severity(SpecNotationFindingCode code) {
  return code == SPEC_NOTATION_UNKNOWN_KIND ? "warning" : "error";
}

int spec_notation_element_registered(const SpecNotationElement *e) {
  return e != NULL && spec_notation_kind_registered(e->kind);
}

/* ---- characters ----------------------------------------------------------- */

/* The byte length of the JavaScript `\s` character at s[i] (i < n), else 0. */
static size_t ws_len(const char *s, size_t i, size_t n) {
  unsigned char c = (unsigned char)s[i];
  if (c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' ||
      c == '\r') {
    return 1;
  }
  if (c == 0xC2 && i + 1 < n && (unsigned char)s[i + 1] == 0xA0) return 2;
  if (c == 0xE1 && i + 2 < n && (unsigned char)s[i + 1] == 0x9A &&
      (unsigned char)s[i + 2] == 0x80) {
    return 3; /* U+1680 */
  }
  if (c == 0xE2 && i + 2 < n) {
    unsigned char c1 = (unsigned char)s[i + 1], c2 = (unsigned char)s[i + 2];
    if (c1 == 0x80 && ((c2 >= 0x80 && c2 <= 0x8A) || c2 == 0xA8 ||
                       c2 == 0xA9 || c2 == 0xAF)) {
      return 3; /* U+2000–200A, U+2028, U+2029, U+202F */
    }
    if (c1 == 0x81 && c2 == 0x9F) return 3; /* U+205F */
  }
  if (c == 0xE3 && i + 2 < n && (unsigned char)s[i + 1] == 0x80 &&
      (unsigned char)s[i + 2] == 0x80) {
    return 3; /* U+3000 */
  }
  if (c == 0xEF && i + 2 < n && (unsigned char)s[i + 1] == 0xBB &&
      (unsigned char)s[i + 2] == 0xBF) {
    return 3; /* U+FEFF */
  }
  return 0;
}

/* Whether s[a, b) is whitespace only (JavaScript `trim() === ''`). */
static int blank(const char *s, size_t a, size_t b) {
  size_t i = a;
  while (i < b) {
    size_t w = ws_len(s, i, b);
    if (w == 0) return 0;
    i += w;
  }
  return 1;
}

/* Whether the JavaScript `.` (no line terminator) matches every character of
 * s[a, b): no `\r`, `\n`, U+2028 or U+2029. */
static int dot_all(const char *s, size_t a, size_t b) {
  for (size_t i = a; i < b; i++) {
    unsigned char c = (unsigned char)s[i];
    if (c == '\r' || c == '\n') return 0;
    if (c == 0xE2 && i + 2 < b && (unsigned char)s[i + 1] == 0x80 &&
        ((unsigned char)s[i + 2] == 0xA8 || (unsigned char)s[i + 2] == 0xA9)) {
      return 0;
    }
  }
  return 1;
}

static int is_alpha(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

static int is_digit(char c) { return c >= '0' && c <= '9'; }

static int starts_with(const char *s, size_t i, size_t n, const char *p) {
  size_t m = strlen(p);
  return i + m <= n && memcmp(s + i, p, m) == 0;
}

/* ---- line patterns -------------------------------------------------------- */

/* Up to three leading spaces (` {0,3}`): the index after them. */
static size_t indent3(const char *l, size_t n) {
  size_t i = 0;
  while (i < n && i < 3 && l[i] == ' ') i++;
  return i;
}

/* `^ {0,3}:{3,}[ \t]*(?:\{(.*)\}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*$` on l[0, n).
 * On a match writes the braces' inner range (`*braced` 1) or the word's range
 * (`*braced` 0), relative to l. */
static int match_div_open(const char *l, size_t n, int *braced, size_t *a,
                          size_t *b) {
  size_t i = indent3(l, n);
  size_t colons = 0;
  while (i < n && l[i] == ':') {
    i++;
    colons++;
  }
  if (colons < 3) return 0;
  while (i < n && (l[i] == ' ' || l[i] == '\t')) i++;
  if (i < n && l[i] == '{') {
    size_t e = n;
    while (e > i && (l[e - 1] == ' ' || l[e - 1] == '\t')) e--;
    if (e >= i + 2 && l[e - 1] == '}' && dot_all(l, i + 1, e - 1)) {
      if (braced) *braced = 1;
      if (a) *a = i + 1;
      if (b) *b = e - 1;
      return 1;
    }
    return 0;
  }
  if (i < n && is_alpha(l[i])) {
    size_t w = i + 1;
    while (w < n &&
           (is_alpha(l[w]) || is_digit(l[w]) || l[w] == '_' || l[w] == '-')) {
      w++;
    }
    size_t t = w;
    while (t < n && (l[t] == ' ' || l[t] == '\t')) t++;
    if (t != n) return 0;
    if (braced) *braced = 0;
    if (a) *a = i;
    if (b) *b = w;
    return 1;
  }
  return 0;
}

/* `^ {0,3}:{3,}[ \t]*$`. */
static int match_div_close(const char *l, size_t n) {
  size_t i = indent3(l, n);
  size_t colons = 0;
  while (i < n && l[i] == ':') {
    i++;
    colons++;
  }
  if (colons < 3) return 0;
  while (i < n && (l[i] == ' ' || l[i] == '\t')) i++;
  return i == n;
}

/* `^ {0,3}(`{3,}|~{3,})(.*)$`: writes the run's start and length and the
 * rest's start (relative to l). */
static int match_code_fence_open(const char *l, size_t n, size_t *run_at,
                                 size_t *run_len, size_t *rest_at) {
  size_t i = indent3(l, n);
  if (i >= n || (l[i] != '`' && l[i] != '~')) return 0;
  char ch = l[i];
  size_t r = i;
  while (r < n && l[r] == ch) r++;
  if (r - i < 3) return 0;
  if (!dot_all(l, r, n)) return 0;
  *run_at = i;
  *run_len = r - i;
  *rest_at = r;
  return 1;
}

/* `^ {0,3}>`. */
static int match_quote_line(const char *l, size_t n) {
  size_t i = indent3(l, n);
  return i < n && l[i] == '>';
}

/* `^ {0,3}> ?(?:⬆|\*\*❓|⚖)`. */
static int match_annotation_start(const char *l, size_t n) {
  size_t i = indent3(l, n);
  if (i >= n || l[i] != '>') return 0;
  i++;
  for (int pass = 0; pass < 2; pass++) {
    size_t j = i;
    if (pass == 0) {
      if (j < n && l[j] == ' ') {
        j++;
      } else {
        continue;
      }
    }
    if (starts_with(l, j, n, "\xE2\xAC\x86") ||
        starts_with(l, j, n, "**\xE2\x9D\x93") ||
        starts_with(l, j, n, "\xE2\x9A\x96")) {
      return 1;
    }
  }
  return 0;
}

/* `^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$`. */
static int match_quoted_div_open(const char *l, size_t n) {
  size_t i = indent3(l, n);
  if (i >= n || l[i] != '>') return 0;
  i++;
  if (i < n && (l[i] == ' ' || l[i] == '\t') &&
      match_div_open(l + i + 1, n - i - 1, NULL, NULL, NULL)) {
    return 1;
  }
  return match_div_open(l + i, n - i, NULL, NULL, NULL);
}

/* ---- attributes ----------------------------------------------------------- */

typedef struct {
  SomStrList classes;
  char *id;
  SomStrList keys;
  SomStrList values;
} Attributes;

static void attributes_init(Attributes *a) {
  som_strlist_init(&a->classes);
  a->id = NULL;
  som_strlist_init(&a->keys);
  som_strlist_init(&a->values);
}

/* `[^\s.#}="']`. */
static size_t token_char(const char *s, size_t i, size_t n) {
  if (ws_len(s, i, n) > 0) return 0;
  char c = s[i];
  if (c == '.' || c == '#' || c == '}' || c == '=' || c == '"' || c == '\'') {
    return 0;
  }
  return 1;
}

static void set_pair(Attributes *a, char *key, char *value) {
  for (size_t k = 0; k < a->keys.len; k++) {
    if (strcmp(a->keys.items[k], key) == 0) {
      free(a->values.items[k]);
      a->values.items[k] = value;
      free(key);
      return;
    }
  }
  som_strlist_push(&a->keys, key);
  som_strlist_push(&a->values, value);
}

/* The attribute tokens of s[a, b) (the `_attributeToken` global regex):
 * `.class`, `#id` (the first counts), `key=value` (quotes stripped). */
static void parse_attributes(const char *s, size_t a, size_t b,
                             Attributes *out) {
  attributes_init(out);
  size_t p = a;
  while (p < b) {
    char c = s[p];
    if (c == '.' || c == '#') {
      size_t q = p + 1;
      while (q < b && token_char(s, q, b)) q++;
      if (q > p + 1) {
        if (c == '.') {
          som_strlist_push(&out->classes, som_strdup_n(s + p + 1, q - p - 1));
        } else if (out->id == NULL) {
          out->id = som_strdup_n(s + p + 1, q - p - 1);
        }
        p = q;
        continue;
      }
      p++;
      continue;
    }
    if (is_alpha(c) || c == '_') {
      size_t q = p + 1;
      while (q < b && (is_alpha(s[q]) || is_digit(s[q]) || s[q] == '_' ||
                       s[q] == ':' || s[q] == '.' || s[q] == '-')) {
        q++;
      }
      if (q < b && s[q] == '=') {
        size_t v = q + 1;
        size_t e = v; /* the value's end, v when none matches */
        if (v < b && (s[v] == '"' || s[v] == '\'')) {
          const char *close = memchr(s + v + 1, s[v], b - v - 1);
          if (close != NULL) e = (size_t)(close - s) + 1;
        }
        if (e == v) {
          while (e < b && ws_len(s, e, b) == 0 && s[e] != '}') e++;
        }
        if (e > v) {
          size_t va = v, vb = e;
          if (vb - va >= 2 &&
              ((s[va] == '"' && s[vb - 1] == '"') ||
               (s[va] == '\'' && s[vb - 1] == '\''))) {
            va++;
            vb--;
          }
          set_pair(out, som_strdup_n(s + p, q - p),
                   som_strdup_n(s + va, vb - va));
          p = e;
          continue;
        }
      }
      p++;
      continue;
    }
    p++;
  }
}

/* ---- the scanner ---------------------------------------------------------- */

typedef struct {
  size_t start;
  size_t content_start;
  int line;
  Attributes attributes;
} OpenDiv;

typedef struct {
  const char *text;
  size_t n;
  int tom_specs;
  size_t *line_starts;
  size_t *line_lens;
  size_t lines_len;
  SpecNotationElement **elements; /* every element, in the order found */
  size_t elements_len, elements_cap;
  SpecNotationFinding *findings;
  size_t findings_len, findings_cap;
} Scanner;

static int line_of(const Scanner *sc, size_t offset) {
  size_t lo = 0, hi = sc->lines_len - 1;
  while (lo < hi) {
    size_t mid = (lo + hi + 1) / 2;
    if (sc->line_starts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return (int)lo + 1;
}

static void find(Scanner *sc, SpecNotationFindingCode code, size_t offset,
                 char *message) {
  if (sc->findings_len == sc->findings_cap) {
    sc->findings_cap = sc->findings_cap ? sc->findings_cap * 2 : 8;
    sc->findings = realloc(sc->findings,
                           sc->findings_cap * sizeof(SpecNotationFinding));
  }
  SpecNotationFinding *f = &sc->findings[sc->findings_len++];
  f->code = code;
  f->offset = offset;
  f->offset_utf16 = 0;
  f->line = line_of(sc, offset);
  f->message = message;
}

static void add_element(Scanner *sc, SpecNotationElement *e) {
  if (sc->elements_len == sc->elements_cap) {
    sc->elements_cap = sc->elements_cap ? sc->elements_cap * 2 : 8;
    sc->elements = realloc(sc->elements,
                           sc->elements_cap * sizeof(SpecNotationElement *));
  }
  sc->elements[sc->elements_len++] = e;
}

/* A new element, taking the attributes' strings. */
static SpecNotationElement *new_element(SpecNotationElementType type,
                                        Attributes *a, char *shape,
                                        size_t start, size_t end,
                                        size_t content_start,
                                        size_t content_end, int line,
                                        int end_line, int closed) {
  SpecNotationElement *e = calloc(1, sizeof(SpecNotationElement));
  e->type = type;
  e->classes = a->classes;
  e->kind = a->classes.len > 0 ? som_strdup(a->classes.items[0]) : NULL;
  e->id = a->id;
  e->attr_keys = a->keys;
  e->attr_values = a->values;
  e->shape = shape;
  e->start = start;
  e->end = end;
  e->content_start = content_start;
  e->content_end = content_end;
  e->line = line;
  e->end_line = end_line;
  e->closed = closed;
  return e;
}

static void add_div(Scanner *sc, OpenDiv *d, size_t end, size_t content_end,
                    int closed) {
  size_t content_start =
      d->content_start > content_end ? content_end : d->content_start;
  add_element(sc, new_element(SPEC_NOTATION_DIV, &d->attributes, NULL,
                              d->start, end, content_start, content_end,
                              d->line,
                              line_of(sc, end > d->start ? end - 1 : d->start),
                              closed));
}

static void inline_region(Scanner *sc, size_t start, size_t end);

/* --- blocks --- */

static void blocks(Scanner *sc) {
  const char *text = sc->text;
  OpenDiv *open = NULL;
  size_t open_len = 0, open_cap = 0;
  const char *fence = NULL; /* the open code fence's run, in text */
  size_t flen = 0;
  int in_fence = 0;
  int in_annotation = 0;
  int has_region = 0;
  size_t region_start = 0, region_end = 0;

#define END_REGION()                                                          \
  do {                                                                         \
    if (has_region) inline_region(sc, region_start, region_end);               \
    has_region = 0;                                                            \
  } while (0)

  for (size_t i = 0; i < sc->lines_len; i++) {
    const char *line = text + sc->line_starts[i];
    size_t len = sc->line_lens[i];
    size_t start = sc->line_starts[i];
    size_t line_end = start + len;
    size_t next = i + 1 < sc->lines_len ? sc->line_starts[i + 1] : sc->n;

    if (in_fence) {
      size_t t = 0, units = 0;
      for (;;) {
        size_t w = t < len ? ws_len(line, t, len) : 0;
        if (w == 0) break;
        t += w;
        units++;
      }
      if (units <= 3 && t + flen <= len && memcmp(line + t, fence, flen) == 0) {
        int rest_blank = 1;
        size_t k = t + flen;
        while (k < len) {
          if (line[k] == fence[0]) {
            k++;
            continue;
          }
          size_t w = ws_len(line, k, len);
          if (w == 0) {
            rest_blank = 0;
            break;
          }
          k += w;
        }
        if (rest_blank) in_fence = 0;
      }
      continue;
    }

    if (match_annotation_start(line, len)) {
      if (!in_annotation && open_len > 0) {
        find(sc, SPEC_NOTATION_ANNOTATION_INSIDE_DIV, start,
             som_strdup("a comment or question block stands inside a div"));
      }
      in_annotation = 1;
    } else if (!match_quote_line(line, len)) {
      in_annotation = 0;
    }
    if (in_annotation) {
      if (match_quoted_div_open(line, len)) {
        find(sc, SPEC_NOTATION_DIV_INSIDE_ANNOTATION, start,
             som_strdup("a div stands inside a comment or question block"));
      }
      if (!has_region) {
        has_region = 1;
        region_start = start;
      }
      region_end = line_end;
      continue;
    }

    size_t run_at, run_len, rest_at;
    if (match_code_fence_open(line, len, &run_at, &run_len, &rest_at) &&
        !(line[run_at] == '`' &&
          memchr(line + rest_at, '`', len - rest_at) != NULL)) {
      END_REGION();
      fence = line + run_at;
      flen = run_len;
      in_fence = 1;
      continue;
    }

    int braced = 0;
    size_t a = 0, b = 0;
    if (match_div_open(line, len, &braced, &a, &b)) {
      END_REGION();
      if (open_len == open_cap) {
        open_cap = open_cap ? open_cap * 2 : 4;
        open = realloc(open, open_cap * sizeof(OpenDiv));
      }
      OpenDiv *d = &open[open_len++];
      d->start = start;
      d->content_start = next;
      d->line = (int)i + 1;
      if (braced) {
        parse_attributes(line, a, b, &d->attributes);
      } else {
        attributes_init(&d->attributes);
        som_strlist_push(&d->attributes.classes, som_strdup_n(line + a, b - a));
      }
      continue;
    }

    if (match_div_close(line, len)) {
      END_REGION();
      if (open_len == 0) {
        find(sc, SPEC_NOTATION_STRAY_CLOSING_FENCE, start,
             som_strdup("a closing fence has no open div"));
      } else {
        add_div(sc, &open[--open_len], line_end, start, 1);
      }
      continue;
    }

    if (blank(line, 0, len)) {
      END_REGION();
      continue;
    }
    if (!has_region) {
      has_region = 1;
      region_start = start;
    }
    region_end = line_end;
  }
  END_REGION();
#undef END_REGION
  while (open_len > 0) {
    OpenDiv *d = &open[--open_len];
    find(sc, SPEC_NOTATION_UNCLOSED_DIV, d->start,
         som_strdup("an opening fence has no closing fence"));
    add_div(sc, d, sc->n, sc->n, 0);
  }
  free(open);
}

/* --- inline --- */

static const char *const kMarkOpeners[5] = {"{++", "{--", "{~~", "{==",
                                            "{>>"};
static const char *const kMarkClosers[5] = {"++}", "--}", "~~}", "==}",
                                            "<<}"};

static int mark_opener_at(const char *s, size_t i, size_t n) {
  for (int k = 0; k < 5; k++) {
    if (starts_with(s, i, n, kMarkOpeners[k])) return k;
  }
  return -1;
}

static int ascii_punctuation(char c) {
  return c != '\0' && strchr("!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~", c) != NULL;
}

static long closing_backticks(const char *s, size_t from, size_t end,
                              size_t n) {
  size_t i = from;
  while (i < end) {
    if (s[i] == '`') {
      size_t m = 0;
      while (i + m < end && s[i + m] == '`') m++;
      if (m == n) return (long)i;
      i += m;
    } else {
      i++;
    }
  }
  return -1;
}

static long closing_brace(const char *s, size_t from, size_t end) {
  char quote = 0;
  for (size_t i = from; i < end; i++) {
    char c = s[i];
    if (quote != 0) {
      if (c == quote) quote = 0;
    } else if (c == '"' || c == '\'') {
      quote = c;
    } else if (c == '}') {
      return (long)i;
    } else if (c == '{') {
      return -1;
    }
  }
  return -1;
}

static long closing_parenthesis(const char *s, size_t from, size_t end,
                                const size_t *literal) {
  int depth = 0;
  size_t i = from;
  while (i < end) {
    if (literal[i] != 0) {
      i = literal[i];
      continue;
    }
    char c = s[i];
    if (c == '(') {
      depth++;
    } else if (c == ')') {
      if (depth == 0) return (long)i;
      depth--;
    }
    i++;
  }
  return -1;
}

static void inline_region(Scanner *sc, size_t start, size_t end) {
  const char *text = sc->text;
  size_t n = sc->n;
  /* literal[i]: the end of the code span opening at i (0: none);
   * escaped[i]: the character at i is escaped. */
  size_t *literal = calloc(n + 1, sizeof(size_t));
  unsigned char *escaped = calloc(n + 2, 1);
  for (size_t i = start; i < end; i++) {
    char c = text[i];
    if (c == '\\' && i + 1 < end && ascii_punctuation(text[i + 1])) {
      escaped[i + 1] = 1;
      i++;
      continue;
    }
    if (c == '`') {
      size_t k = 0;
      while (i + k < end && text[i + k] == '`') k++;
      long close = closing_backticks(text, i + k, end, k);
      if (close >= 0) {
        literal[i] = (size_t)close + k;
        i = (size_t)close + k - 1;
      } else {
        i += k - 1;
      }
    }
  }

  SpecNotationElement **spans = NULL;
  size_t spans_len = 0, spans_cap = 0;
  size_t *marks = NULL; /* pairs: start, end */
  size_t marks_len = 0, marks_cap = 0;
  size_t *brackets = NULL;
  size_t brackets_len = 0, brackets_cap = 0;

  size_t i = start;
  while (i < end) {
    if (literal[i] != 0) {
      i = literal[i];
      continue;
    }
    char c = text[i];
    if (escaped[i] || (c == '\\' && escaped[i + 1])) {
      i++;
      continue;
    }
    if (c == '{') {
      int k = mark_opener_at(text, i, n);
      if (k >= 0) {
        const char *close = strstr(text + i + 3, kMarkClosers[k]);
        if (close != NULL && (size_t)(close - text) + 3 <= end) {
          if (marks_len + 2 > marks_cap) {
            marks_cap = marks_cap ? marks_cap * 2 : 8;
            marks = realloc(marks, marks_cap * sizeof(size_t));
          }
          marks[marks_len++] = i;
          marks[marks_len++] = (size_t)(close - text) + 3;
        }
        i += 3;
        continue;
      }
    }
    if (c == '[') {
      if (brackets_len == brackets_cap) {
        brackets_cap = brackets_cap ? brackets_cap * 2 : 8;
        brackets = realloc(brackets, brackets_cap * sizeof(size_t));
      }
      brackets[brackets_len++] = i;
    } else if (c == ']' && brackets_len > 0) {
      size_t open_at = brackets[--brackets_len];
      if (i + 1 < end && text[i + 1] == '{' && !escaped[i + 1] &&
          mark_opener_at(text, i + 1, n) < 0) {
        long close = closing_brace(text, i + 2, end);
        if (close < 0) {
          find(sc, SPEC_NOTATION_UNCLOSED_SPAN, i + 1,
               som_strdup("a span's attribute braces do not close on the "
                          "paragraph"));
        } else {
          Attributes a;
          parse_attributes(text, i + 2, (size_t)close, &a);
          SpecNotationElement *span = new_element(
              SPEC_NOTATION_SPAN, &a, NULL, open_at, (size_t)close + 1,
              open_at + 1, i, line_of(sc, open_at), line_of(sc, (size_t)close),
              1);
          if (spans_len == spans_cap) {
            spans_cap = spans_cap ? spans_cap * 2 : 8;
            spans = realloc(spans, spans_cap * sizeof(*spans));
          }
          spans[spans_len++] = span;
          add_element(sc, span);
          i = (size_t)close + 1;
          continue;
        }
      }
    } else if (c == '(' && i + 3 < end && text[i + 3] == ' ') {
      const char *kind = NULL;
      if (text[i + 1] == '-' && text[i + 2] == '>') {
        kind = "trace";
      } else if (text[i + 1] == '<' &&
                 (text[i + 2] == '-' || text[i + 2] == '~')) {
        kind = "provenance";
      }
      if (kind != NULL) {
        long close = closing_parenthesis(text, i + 4, end, literal);
        if (close > (long)(i + 4) && !blank(text, i + 4, (size_t)close)) {
          Attributes a;
          attributes_init(&a);
          som_strlist_push_copy(&a.classes, kind);
          SpecNotationElement *citation = new_element(
              SPEC_NOTATION_CITATION, &a, som_strdup_n(text + i + 1, 2), i,
              (size_t)close + 1, i + 4, (size_t)close, line_of(sc, i),
              line_of(sc, (size_t)close), 1);
          if (spans_len == spans_cap) {
            spans_cap = spans_cap ? spans_cap * 2 : 8;
            spans = realloc(spans, spans_cap * sizeof(*spans));
          }
          spans[spans_len++] = citation;
          add_element(sc, citation);
          i += 4;
          continue;
        }
      }
    }
    i++;
  }

  for (size_t m = 0; m < marks_len; m += 2) {
    size_t ms = marks[m], me = marks[m + 1];
    for (size_t k = 0; k < spans_len; k++) {
      const SpecNotationElement *e = spans[k];
      int crosses = (ms < e->start && e->start < me && me < e->end) ||
                    (e->start < ms && ms < e->end && e->end < me);
      if (crosses) {
        SomBuf msg;
        som_buf_init(&msg);
        som_buf_puts(&msg, "an inline review mark crosses the boundary of a ");
        som_buf_puts(&msg, spec_notation_element_type_name(e->type));
        find(sc, SPEC_NOTATION_MARK_ACROSS_NOTATION, ms, som_buf_take(&msg));
        break;
      }
    }
  }

  free(spans);
  free(marks);
  free(brackets);
  free(literal);
  free(escaped);
}

/* --- kinds --- */

static void kind_findings(Scanner *sc) {
  size_t count = sc->elements_len;
  for (size_t k = 0; k < count; k++) {
    const SpecNotationElement *e = sc->elements[k];
    if (e->type == SPEC_NOTATION_CITATION) continue;
    if (e->type == SPEC_NOTATION_DIV && e->kind != NULL &&
        strcmp(e->kind, "rejected") == 0) {
      find(sc, SPEC_NOTATION_REJECTED_BLOCK, e->start,
           som_strdup("a rejected block waits for its resolution"));
    }
    if (!sc->tom_specs) continue;
    if (e->kind == NULL) {
      if (e->type == SPEC_NOTATION_DIV) {
        find(sc, SPEC_NOTATION_DIV_WITHOUT_KIND, e->start,
             som_strdup("a div's attributes hold no class"));
      }
    } else if (!spec_notation_kind_registered(e->kind)) {
      SomBuf msg;
      som_buf_init(&msg);
      som_buf_puts(&msg, "the kind \"");
      som_buf_puts(&msg, e->kind);
      som_buf_puts(&msg, "\" is not registered");
      find(sc, SPEC_NOTATION_UNKNOWN_KIND, e->start, som_buf_take(&msg));
    }
  }
}

/* --- ordering --- */

typedef struct {
  SpecNotationElement *e;
  size_t index;
} ElementSlot;

static int element_cmp(const void *pa, const void *pb) {
  const ElementSlot *a = pa, *b = pb;
  if (a->e->start != b->e->start) return a->e->start < b->e->start ? -1 : 1;
  if (a->e->end != b->e->end) return a->e->end > b->e->end ? -1 : 1;
  if (a->e->type != b->e->type) return (int)a->e->type - (int)b->e->type;
  return a->index < b->index ? -1 : (a->index > b->index ? 1 : 0);
}

typedef struct {
  SpecNotationFinding f;
  size_t index;
} FindingSlot;

static int finding_cmp(const void *pa, const void *pb) {
  const FindingSlot *a = pa, *b = pb;
  if (a->f.offset != b->f.offset) return a->f.offset < b->f.offset ? -1 : 1;
  if (a->f.code != b->f.code) return (int)a->f.code - (int)b->f.code;
  return a->index < b->index ? -1 : (a->index > b->index ? 1 : 0);
}

static void push_child(SpecNotationElement *parent, SpecNotationElement *e) {
  if (parent->children_len == parent->children_cap) {
    parent->children_cap = parent->children_cap ? parent->children_cap * 2 : 4;
    parent->children =
        realloc(parent->children,
                parent->children_cap * sizeof(SpecNotationElement *));
  }
  parent->children[parent->children_len++] = e;
}

/* ---- public --------------------------------------------------------------- */

void spec_scan_notation(const char *text, int tom_specs,
                        SpecNotationScan *out) {
  memset(out, 0, sizeof(*out));
  if (text == NULL) text = "";
  Scanner sc;
  memset(&sc, 0, sizeof(sc));
  sc.text = text;
  sc.n = strlen(text);
  sc.tom_specs = tom_specs;

  size_t lines = 1;
  for (size_t i = 0; i < sc.n; i++) {
    if (text[i] == '\n') lines++;
  }
  sc.line_starts = malloc(lines * sizeof(size_t));
  sc.line_lens = malloc(lines * sizeof(size_t));
  size_t at = 0, li = 0;
  for (size_t i = 0; i <= sc.n; i++) {
    if (i == sc.n || text[i] == '\n') {
      sc.line_starts[li] = at;
      sc.line_lens[li] = i - at;
      li++;
      at = i + 1;
    }
  }
  sc.lines_len = lines;

  blocks(&sc);
  kind_findings(&sc);

  /* UTF-16 offsets: units[i] is the count of UTF-16 code units before byte i. */
  size_t *units = malloc((sc.n + 1) * sizeof(size_t));
  size_t u = 0;
  for (size_t i = 0; i < sc.n; i++) {
    units[i] = u;
    unsigned char c = (unsigned char)text[i];
    if ((c & 0xC0) == 0x80) continue; /* continuation byte */
    u += c >= 0xF0 ? 2 : 1;
  }
  units[sc.n] = u;

  ElementSlot *slots =
      sc.elements_len ? malloc(sc.elements_len * sizeof(ElementSlot)) : NULL;
  for (size_t k = 0; k < sc.elements_len; k++) {
    SpecNotationElement *e = sc.elements[k];
    e->start_utf16 = units[e->start];
    e->end_utf16 = units[e->end];
    e->content_start_utf16 = units[e->content_start];
    e->content_end_utf16 = units[e->content_end];
    slots[k].e = e;
    slots[k].index = k;
  }
  if (sc.elements_len > 1) {
    qsort(slots, sc.elements_len, sizeof(ElementSlot), element_cmp);
  }
  SpecNotationElement **stack =
      sc.elements_len ? malloc(sc.elements_len * sizeof(*stack)) : NULL;
  size_t depth = 0;
  out->elements =
      sc.elements_len ? malloc(sc.elements_len * sizeof(*out->elements)) : NULL;
  for (size_t k = 0; k < sc.elements_len; k++) {
    SpecNotationElement *e = slots[k].e;
    while (depth > 0 && !(e->start >= stack[depth - 1]->start &&
                          e->end <= stack[depth - 1]->end)) {
      depth--;
    }
    if (depth == 0) {
      out->elements[out->elements_len++] = e;
    } else {
      push_child(stack[depth - 1], e);
    }
    stack[depth++] = e;
  }
  free(stack);
  free(slots);

  FindingSlot *fs =
      sc.findings_len ? malloc(sc.findings_len * sizeof(FindingSlot)) : NULL;
  for (size_t k = 0; k < sc.findings_len; k++) {
    fs[k].f = sc.findings[k];
    fs[k].f.offset_utf16 = units[fs[k].f.offset];
    fs[k].index = k;
  }
  if (sc.findings_len > 1) {
    qsort(fs, sc.findings_len, sizeof(FindingSlot), finding_cmp);
  }
  out->findings = sc.findings; /* reuse the storage, now in order */
  for (size_t k = 0; k < sc.findings_len; k++) out->findings[k] = fs[k].f;
  out->findings_len = sc.findings_len;
  free(fs);

  out->text = som_strdup(text);
  free(units);
  free(sc.elements);
  free(sc.line_starts);
  free(sc.line_lens);
}

static void element_free(SpecNotationElement *e) {
  if (e == NULL) return;
  for (size_t i = 0; i < e->children_len; i++) element_free(e->children[i]);
  free(e->children);
  free(e->kind);
  som_strlist_free(&e->classes);
  free(e->id);
  som_strlist_free(&e->attr_keys);
  som_strlist_free(&e->attr_values);
  free(e->shape);
  free(e);
}

void spec_notation_scan_free(SpecNotationScan *scan) {
  if (scan == NULL) return;
  for (size_t i = 0; i < scan->elements_len; i++) {
    element_free(scan->elements[i]);
  }
  free(scan->elements);
  for (size_t i = 0; i < scan->findings_len; i++) {
    free(scan->findings[i].message);
  }
  free(scan->findings);
  free(scan->text);
  memset(scan, 0, sizeof(*scan));
}

int spec_notation_scan_has_errors(const SpecNotationScan *scan) {
  for (size_t i = 0; i < scan->findings_len; i++) {
    if (scan->findings[i].code != SPEC_NOTATION_UNKNOWN_KIND) return 1;
  }
  return 0;
}

static void collect(const SpecNotationElement *const *list, size_t len,
                    const SpecNotationElement **out, size_t *n) {
  for (size_t i = 0; i < len; i++) {
    out[(*n)++] = list[i];
    collect((const SpecNotationElement *const *)list[i]->children,
            list[i]->children_len, out, n);
  }
}

static size_t count_all(const SpecNotationElement *const *list, size_t len) {
  size_t n = 0;
  for (size_t i = 0; i < len; i++) {
    n += 1 + count_all((const SpecNotationElement *const *)list[i]->children,
                       list[i]->children_len);
  }
  return n;
}

const SpecNotationElement **spec_notation_scan_all(const SpecNotationScan *scan,
                                                   size_t *out_len) {
  const SpecNotationElement *const *roots =
      (const SpecNotationElement *const *)scan->elements;
  size_t total = count_all(roots, scan->elements_len);
  *out_len = 0;
  if (total == 0) return NULL;
  const SpecNotationElement **out = malloc(total * sizeof(*out));
  collect(roots, scan->elements_len, out, out_len);
  return out;
}

/* ---- JSON ----------------------------------------------------------------- */

static void put_str(SomBuf *b, const char *s) {
  if (s == NULL) {
    som_buf_puts(b, "null");
    return;
  }
  char *q = som_json_encode_str(s);
  som_buf_puts(b, q);
  free(q);
}

static void put_range(SomBuf *b, const char *text, size_t a, size_t z) {
  char *s = som_strdup_n(text + a, z - a);
  put_str(b, s);
  free(s);
}

static void element_json(SomBuf *b, const SpecNotationElement *e,
                         const char *text) {
  som_buf_puts(b, "{\"type\":");
  put_str(b, spec_notation_element_type_name(e->type));
  som_buf_puts(b, ",\"kind\":");
  put_str(b, e->kind);
  som_buf_puts(b, ",\"classes\":[");
  for (size_t i = 0; i < e->classes.len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    put_str(b, e->classes.items[i]);
  }
  som_buf_puts(b, "],\"id\":");
  put_str(b, e->id);
  som_buf_puts(b, ",\"attributes\":{");
  for (size_t i = 0; i < e->attr_keys.len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    put_str(b, e->attr_keys.items[i]);
    som_buf_putc(b, ':');
    put_str(b, e->attr_values.items[i]);
  }
  som_buf_puts(b, "},\"shape\":");
  put_str(b, e->shape);
  som_buf_puts(b, ",\"start\":");
  som_buf_puti(b, (long long)e->start_utf16);
  som_buf_puts(b, ",\"end\":");
  som_buf_puti(b, (long long)e->end_utf16);
  som_buf_puts(b, ",\"line\":");
  som_buf_puti(b, e->line);
  som_buf_puts(b, ",\"endLine\":");
  som_buf_puti(b, e->end_line);
  som_buf_puts(b, e->closed ? ",\"closed\":true" : ",\"closed\":false");
  som_buf_puts(b, ",\"source\":");
  put_range(b, text, e->start, e->end);
  som_buf_puts(b, ",\"content\":");
  put_range(b, text, e->content_start, e->content_end);
  som_buf_puts(b, ",\"children\":[");
  for (size_t i = 0; i < e->children_len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    element_json(b, e->children[i], text);
  }
  som_buf_puts(b, "]}");
}

char *spec_notation_element_to_json(const SpecNotationElement *e,
                                    const char *text) {
  SomBuf b;
  som_buf_init(&b);
  element_json(&b, e, text);
  return som_buf_take(&b);
}

static void finding_json(SomBuf *b, const SpecNotationFinding *f) {
  som_buf_puts(b, "{\"code\":");
  put_str(b, spec_notation_finding_code_name(f->code));
  som_buf_puts(b, ",\"severity\":");
  put_str(b, spec_notation_severity(f->code));
  som_buf_puts(b, ",\"line\":");
  som_buf_puti(b, f->line);
  som_buf_putc(b, '}');
}

char *spec_notation_finding_to_json(const SpecNotationFinding *f) {
  SomBuf b;
  som_buf_init(&b);
  finding_json(&b, f);
  return som_buf_take(&b);
}

char *spec_notation_scan_elements_json(const SpecNotationScan *scan) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < scan->elements_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    element_json(&b, scan->elements[i], scan->text);
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

char *spec_notation_scan_findings_json(const SpecNotationScan *scan) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < scan->findings_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    finding_json(&b, &scan->findings[i]);
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}
