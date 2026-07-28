/* docspecs_validator — implementation. See docspecs_validator.h; a faithful
 * 1:1 port of the Go `docspecs_validator.go` (SOM §14). */
#include "docspecs_validator.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document_markdown.h"

/* ---- small helpers ------------------------------------------------------- */

/* vcat — concatenates a NULL-terminated argument list of strings. Owned. */
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

/* itoa — the Go helper's C stand-in (owned decimal string). */
static char *dv_itoa(long long v) { return som_format_i64(v); }

static int is_ascii_ws(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

static char to_upper_ascii(char c) {
  return (c >= 'a' && c <= 'z') ? (char)(c - 'a' + 'A') : c;
}

static char to_lower_ascii(char c) {
  return (c >= 'A' && c <= 'Z') ? (char)(c - 'A' + 'a') : c;
}

/* strings.TrimSpace over ASCII whitespace. Owned result. */
static char *trim_space(const char *s) {
  size_t start = 0;
  size_t end = strlen(s);
  while (start < end && is_ascii_ws(s[start])) {
    start++;
  }
  while (end > start && is_ascii_ws(s[end - 1])) {
    end--;
  }
  return som_strdup_n(s + start, end - start);
}

/* strings.ToUpper / ToLower over ASCII. Owned result. */
static char *upper_ascii(const char *s) {
  size_t n = strlen(s);
  char *out = malloc(n + 1);
  for (size_t i = 0; i < n; i++) {
    out[i] = to_upper_ascii(s[i]);
  }
  out[n] = '\0';
  return out;
}

static char *lower_ascii(const char *s) {
  size_t n = strlen(s);
  char *out = malloc(n + 1);
  for (size_t i = 0; i < n; i++) {
    out[i] = to_lower_ascii(s[i]);
  }
  out[n] = '\0';
  return out;
}

/* utf8 rune count (for text-length checks — Go uses len([]rune(text))). */
static size_t rune_count(const char *s) {
  size_t count = 0;
  for (const unsigned char *p = (const unsigned char *)s; *p != '\0'; p++) {
    if ((*p & 0xC0) != 0x80) {
      count++;
    }
  }
  return count;
}

/* ---- mini regex (hand-rolled, DocSpecs pattern subset) ------------------- */

/* A backtracking matcher for the DocSpecs `pattern-check-id` subset the Go
 * `regexp` package handles here: `^` / `$` anchors, literals, `.`, character
 * classes `[...]` (with ranges and a leading `^` negation), and the `*` / `+`
 * / `?` quantifiers. Semantics mirror Go's `MatchString` (an *unanchored*
 * search unless the pattern is `^`-anchored). Compilation never fails for a
 * well-formed subset pattern; a malformed pattern (unterminated class) makes
 * `matches` return 0 — the Go code returns false when `Compile` errors. */

typedef enum {
  RX_LITERAL,
  RX_ANY,
  RX_CLASS,
  RX_START,
  RX_END,
} RxKind;

typedef struct {
  RxKind kind;
  char literal;      /* RX_LITERAL */
  const char *cls;   /* RX_CLASS: pointer into pattern at '[' */
  size_t cls_len;    /* bytes from '[' to ']' inclusive */
  char quant;        /* 0, '*', '+', '?' */
} RxAtom;

typedef struct {
  RxAtom *atoms;
  size_t len;
  int ok;
} Rx;

/* Reports whether char `c` is in class token `[...]` (len covers '['..']'). */
static int rx_class_match(const char *cls, size_t cls_len, char c) {
  /* cls[0] == '[', cls[cls_len-1] == ']' */
  size_t i = 1;
  size_t end = cls_len - 1;
  int negate = 0;
  if (i < end && cls[i] == '^') {
    negate = 1;
    i++;
  }
  int found = 0;
  while (i < end) {
    if (i + 2 < end && cls[i + 1] == '-' && cls[i + 2] != ']') {
      char lo = cls[i];
      char hi = cls[i + 2];
      if ((unsigned char)c >= (unsigned char)lo &&
          (unsigned char)c <= (unsigned char)hi) {
        found = 1;
      }
      i += 3;
    } else {
      if (cls[i] == c) {
        found = 1;
      }
      i++;
    }
  }
  return negate ? !found : found;
}

/* Compiles the subset pattern into `rx`. */
static void rx_compile(Rx *rx, const char *pattern) {
  rx->atoms = NULL;
  rx->len = 0;
  rx->ok = 1;
  size_t cap = 0;
  size_t n = strlen(pattern);
  for (size_t i = 0; i < n;) {
    RxAtom atom;
    atom.quant = 0;
    atom.literal = 0;
    atom.cls = NULL;
    atom.cls_len = 0;
    char c = pattern[i];
    if (c == '^') {
      atom.kind = RX_START;
      i++;
    } else if (c == '$') {
      atom.kind = RX_END;
      i++;
    } else if (c == '.') {
      atom.kind = RX_ANY;
      i++;
    } else if (c == '[') {
      size_t j = i + 1;
      if (j < n && pattern[j] == '^') {
        j++;
      }
      if (j < n && pattern[j] == ']') {
        j++; /* a literal ']' as first class member */
      }
      while (j < n && pattern[j] != ']') {
        j++;
      }
      if (j >= n) {
        rx->ok = 0; /* unterminated class → compile error */
        free(rx->atoms);
        rx->atoms = NULL;
        rx->len = 0;
        return;
      }
      atom.kind = RX_CLASS;
      atom.cls = pattern + i;
      atom.cls_len = (j - i) + 1; /* include ']' */
      i = j + 1;
    } else if (c == '\\' && i + 1 < n) {
      atom.kind = RX_LITERAL;
      atom.literal = pattern[i + 1];
      i += 2;
    } else {
      atom.kind = RX_LITERAL;
      atom.literal = c;
      i++;
    }
    /* quantifier (anchors take none) */
    if (atom.kind != RX_START && atom.kind != RX_END && i < n &&
        (pattern[i] == '*' || pattern[i] == '+' || pattern[i] == '?')) {
      atom.quant = pattern[i];
      i++;
    }
    if (rx->len == cap) {
      cap = cap == 0 ? 8 : cap * 2;
      rx->atoms = realloc(rx->atoms, cap * sizeof(RxAtom));
    }
    rx->atoms[rx->len++] = atom;
  }
}

static void rx_free(Rx *rx) {
  free(rx->atoms);
  rx->atoms = NULL;
  rx->len = 0;
}

/* Reports whether a single non-quantified atom matches the char at `text[pos]`
 * (never called for anchors). */
static int rx_atom_char_match(const RxAtom *a, const char *text, size_t pos,
                              size_t tlen) {
  if (pos >= tlen) {
    return 0;
  }
  char c = text[pos];
  switch (a->kind) {
  case RX_LITERAL:
    return c == a->literal;
  case RX_ANY:
    return c != '\n';
  case RX_CLASS:
    return rx_class_match(a->cls, a->cls_len, c);
  default:
    return 0;
  }
}

/* Backtracking match of atoms[ai..] against text[pos..]. */
static int rx_match_here(const Rx *rx, size_t ai, const char *text, size_t pos,
                         size_t tlen) {
  if (ai == rx->len) {
    return 1;
  }
  const RxAtom *a = &rx->atoms[ai];
  if (a->kind == RX_START) {
    return pos == 0 ? rx_match_here(rx, ai + 1, text, pos, tlen) : 0;
  }
  if (a->kind == RX_END) {
    return pos == tlen ? rx_match_here(rx, ai + 1, text, pos, tlen) : 0;
  }
  if (a->quant == '*' || a->quant == '+') {
    /* greedy: consume as many as possible, then backtrack. */
    size_t count = 0;
    while (rx_atom_char_match(a, text, pos + count, tlen)) {
      count++;
    }
    size_t min = (a->quant == '+') ? 1 : 0;
    for (size_t k = count + 1; k-- > min;) {
      if (rx_match_here(rx, ai + 1, text, pos + k, tlen)) {
        return 1;
      }
      if (k == 0) {
        break;
      }
    }
    return 0;
  }
  if (a->quant == '?') {
    if (rx_atom_char_match(a, text, pos, tlen) &&
        rx_match_here(rx, ai + 1, text, pos + 1, tlen)) {
      return 1;
    }
    return rx_match_here(rx, ai + 1, text, pos, tlen);
  }
  if (!rx_atom_char_match(a, text, pos, tlen)) {
    return 0;
  }
  return rx_match_here(rx, ai + 1, text, pos + 1, tlen);
}

/* Go MatchString: an unanchored search. */
static int rx_search(const Rx *rx, const char *text) {
  if (!rx->ok) {
    return 0;
  }
  size_t tlen = strlen(text);
  for (size_t start = 0;; start++) {
    if (rx_match_here(rx, 0, text, start, tlen)) {
      return 1;
    }
    if (start >= tlen) {
      break;
    }
  }
  return 0;
}

int docspecs_pattern_check_matches(const DocSpecsPatternCheck *c,
                                   const char *value) {
  Rx rx;
  rx_compile(&rx, c->pattern);
  int ok = rx_search(&rx, value);
  rx_free(&rx);
  return ok;
}

/* ---- violation ----------------------------------------------------------- */

char *docspecs_violation_string(const DocSpecsViolation *v) {
  char *ln = dv_itoa(v->line);
  const char *sid_open = (v->section_id[0] != '\0') ? " [" : "";
  const char *sid_body = (v->section_id[0] != '\0') ? v->section_id : "";
  const char *sid_close = (v->section_id[0] != '\0') ? "]" : "";
  const char *p_open = (v->path[0] != '\0') ? " (" : "";
  const char *p_body = (v->path[0] != '\0') ? v->path : "";
  const char *p_close = (v->path[0] != '\0') ? ")" : "";
  char *out = vcat("line ", ln, ": ", v->rule, sid_open, sid_body, sid_close,
                   p_open, p_body, p_close, " — ", v->message, NULL);
  free(ln);
  return out;
}

void docspecs_violation_list_init(DocSpecsViolationList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

static DocSpecsViolation *dv_list_alloc(DocSpecsViolationList *l) {
  if (l->len == l->cap) {
    l->cap = l->cap == 0 ? 8 : l->cap * 2;
    l->items = realloc(l->items, l->cap * sizeof(DocSpecsViolation));
  }
  return &l->items[l->len++];
}

/* Appends a violation, taking ownership of the (owned) message. `section_id`
 * and `path` are copied ("" when NULL). */
static void dv_push(DocSpecsViolationList *l, const char *rule, int line,
                    char *message, const char *section_id, const char *path) {
  DocSpecsViolation *v = dv_list_alloc(l);
  v->rule = som_strdup(rule);
  v->line = line;
  v->message = message;
  v->section_id = som_strdup(section_id != NULL ? section_id : "");
  v->path = som_strdup(path != NULL ? path : "");
}

static void dv_violation_free(DocSpecsViolation *v) {
  free(v->rule);
  free(v->message);
  free(v->section_id);
  free(v->path);
}

void docspecs_violation_list_free(DocSpecsViolationList *l) {
  for (size_t i = 0; i < l->len; i++) {
    dv_violation_free(&l->items[i]);
  }
  free(l->items);
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

/* ---- section ------------------------------------------------------------- */

static DocSpecsSection *section_new(const char *id, const char *title,
                                    int level, int line) {
  DocSpecsSection *s = calloc(1, sizeof(DocSpecsSection));
  s->id = som_strdup(id != NULL ? id : "");
  s->title = som_strdup(title != NULL ? title : "");
  s->level = level;
  s->line = line;
  som_strlist_init(&s->body_lines);
  return s;
}

static void section_add_child(DocSpecsSection *parent, DocSpecsSection *child) {
  if (parent->children_len == parent->children_cap) {
    parent->children_cap =
        parent->children_cap == 0 ? 4 : parent->children_cap * 2;
    parent->children = realloc(parent->children,
                               parent->children_cap * sizeof(DocSpecsSection *));
  }
  parent->children[parent->children_len++] = child;
}

static void section_free(DocSpecsSection *s) {
  free(s->id);
  free(s->title);
  som_strlist_free(&s->body_lines);
  for (size_t i = 0; i < s->children_len; i++) {
    section_free(s->children[i]);
  }
  free(s->children);
  free(s);
}

int docspecs_section_body_start_line(const DocSpecsSection *s) {
  return s->line + 1;
}

char *docspecs_section_text(const DocSpecsSection *s) {
  const SomStrList *lines = &s->body_lines;
  size_t start = 0;
  size_t end = lines->len;
  while (start < end) {
    char *t = trim_space(lines->items[start]);
    int blank = t[0] == '\0';
    free(t);
    if (!blank) {
      break;
    }
    start++;
  }
  while (end > start) {
    char *t = trim_space(lines->items[end - 1]);
    int blank = t[0] == '\0';
    free(t);
    if (!blank) {
      break;
    }
    end--;
  }
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = start; i < end; i++) {
    if (i > start) {
      som_buf_putc(&b, '\n');
    }
    som_buf_puts(&b, lines->items[i]);
  }
  return som_buf_take(&b);
}

/* ---- markdown scanners (mirror the codec's regex-equivalents) ------------ */

/* mdTrailingWSRE = `\s+$` — strip trailing ASCII whitespace. Owned. */
static char *strip_trailing_ws(const char *s) {
  size_t n = strlen(s);
  while (n > 0 && is_ascii_ws(s[n - 1])) {
    n--;
  }
  return som_strdup_n(s, n);
}

/* docspecHeaderRE = `^<!--\s*docspec:\s*(\S+)\s*-->\s*$`. On match writes owned
 * group 1 to `*schema` and returns 1. */
static int match_docspec_header(const char *s, char **schema) {
  if (strncmp(s, "<!--", 4) != 0) {
    return 0;
  }
  const char *p = s + 4;
  while (is_ascii_ws(*p)) {
    p++;
  }
  if (strncmp(p, "docspec:", 8) != 0) {
    return 0;
  }
  p += 8;
  while (is_ascii_ws(*p)) {
    p++;
  }
  const char *id_start = p;
  while (*p != '\0' && !is_ascii_ws(*p)) {
    p++;
  }
  if (p == id_start) {
    return 0; /* \S+ requires at least one */
  }
  const char *id_end = p;
  while (is_ascii_ws(*p)) {
    p++;
  }
  if (strncmp(p, "-->", 3) != 0) {
    return 0;
  }
  p += 3;
  while (*p != '\0') {
    if (!is_ascii_ws(*p)) {
      return 0;
    }
    p++;
  }
  *schema = som_strdup_n(id_start, (size_t)(id_end - id_start));
  return 1;
}

/* mdHeadingLineRE = `^(#+)\s+(.*)$`. Writes hash count to `*level`, owned rest
 * (group 2) to `*rest`, returns 1. */
static int match_heading_line(const char *s, int *level, char **rest) {
  size_t hashes = 0;
  while (s[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0) {
    return 0;
  }
  const char *p = s + hashes;
  if (!is_ascii_ws(*p)) {
    return 0;
  }
  size_t ws = 0;
  while (is_ascii_ws(p[ws])) {
    ws++;
  }
  *level = (int)hashes;
  *rest = som_strdup(p + ws);
  return 1;
}

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$`. Writes owned
 * group 1 (id) to `*id` and owned group 3 (the heading title) to `*rest`,
 * returns 1. Group 2 — the optional key=value region (codespecs_mapping.md §9.2
 * `codeSpec`) between the id bracket and the closing `-->` — is skipped; the
 * validator only needs the title, which is now the third part. The middle group
 * is `[^>]*` (the
 * closing `-->` is the first `>` after the id bracket). */
static int match_headline_comment(const char *s, char **id, char **rest) {
  if (strncmp(s, "<!--[", 5) != 0) {
    return 0;
  }
  const char *p = s + 5;
  const char *close = strchr(p, ']');
  if (close == NULL || close == p) {
    return 0;
  }
  const char *region_start = close + 1;
  const char *gt = strchr(region_start, '>');
  if (gt == NULL || gt < region_start + 2 || gt[-1] != '-' || gt[-2] != '-') {
    return 0;
  }
  *id = som_strdup_n(p, (size_t)(close - p));
  const char *after = gt + 1;
  while (is_ascii_ws(*after)) {
    after++;
  }
  *rest = som_strdup(after);
  return 1;
}

/* mdFieldLabelRE = `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`. Writes owned group 1
 * (label) and group 2 (value); returns 1. */
static int match_field_label(const char *s, char **label, char **value) {
  char c0 = s[0];
  if (!((c0 >= 'A' && c0 <= 'Z') || (c0 >= 'a' && c0 <= 'z'))) {
    return 0;
  }
  size_t i = 1;
  while ((s[i] >= 'A' && s[i] <= 'Z') || (s[i] >= 'a' && s[i] <= 'z') ||
         (s[i] >= '0' && s[i] <= '9') || s[i] == '_') {
    i++;
  }
  if (s[i] != ':') {
    return 0;
  }
  size_t name_end = i;
  i++;
  if (s[i] == ' ') {
    i++;
  }
  *label = som_strdup_n(s, name_end);
  *value = som_strdup(s + i);
  return 1;
}

/* ---- document parse ------------------------------------------------------ */

char *docspecs_id_transform(const char *id) {
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0;
  size_t n = strlen(id);
  while (i < n) {
    char c = id[i];
    int alnum_us = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                   (c >= '0' && c <= '9') || c == '_';
    if (alnum_us) {
      som_buf_putc(&b, c);
      i++;
    } else {
      /* a run of non-alnum/underscore → single '_' */
      som_buf_putc(&b, '_');
      i++;
      while (i < n) {
        char d = id[i];
        int alnum2 = (d >= 'a' && d <= 'z') || (d >= 'A' && d <= 'Z') ||
                     (d >= '0' && d <= '9') || d == '_';
        if (alnum2) {
          break;
        }
        i++;
      }
    }
  }
  return som_buf_take(&b);
}

/* A parse-time stack of open sections. */
typedef struct {
  DocSpecsSection **items;
  size_t len;
  size_t cap;
} SectionStack;

static void stack_push(SectionStack *st, DocSpecsSection *s) {
  if (st->len == st->cap) {
    st->cap = st->cap == 0 ? 8 : st->cap * 2;
    st->items = realloc(st->items, st->cap * sizeof(DocSpecsSection *));
  }
  st->items[st->len++] = s;
}

DocSpecsDocument *docspecs_parse_document(const char *text) {
  DocSpecsDocument *doc = calloc(1, sizeof(DocSpecsDocument));
  doc->declared_schema = som_strdup("");
  docspecs_violation_list_init(&doc->violations);

  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  SectionStack stack;
  stack.items = NULL;
  stack.len = 0;
  stack.cap = 0;

  /* strings.Split(text, "\n") */
  size_t idx = 0;
  const char *cursor = text;
  for (;;) {
    const char *nl = strchr(cursor, '\n');
    size_t raw_len = nl != NULL ? (size_t)(nl - cursor) : strlen(cursor);
    char *raw = som_strdup_n(cursor, raw_len);
    int line_no = (int)(idx + 1);
    char *line = strip_trailing_ws(raw);

    if (!spec_markdown_fence_in_fence(&fence)) {
      if (stack.len == 0 && doc->declared_schema[0] == '\0') {
        char *sch = NULL;
        if (match_docspec_header(line, &sch)) {
          free(doc->declared_schema);
          doc->declared_schema = sch;
          spec_markdown_fence_feed(&fence, raw);
          goto next;
        }
      }
      int level = 0;
      char *rest = NULL;
      if (match_heading_line(line, &level, &rest)) {
        DocSpecsSection *section = NULL;
        char *cid = NULL;
        char *ctitle = NULL;
        if (match_headline_comment(rest, &cid, &ctitle)) {
          const char *title = ctitle;
          if (title[0] == '\0') {
            title = rest;
          }
          section = section_new(cid, title, level, line_no);
          free(cid);
          free(ctitle);
        } else {
          dv_push(&doc->violations, DOCSPECS_RULE_MALFORMED_HEADING, line_no,
                  vcat("heading \"", rest,
                       "\" carries no <!--[SECTION-ID]--> headline comment",
                       NULL),
                  "", "");
          section = section_new("", rest, level, line_no);
        }
        while (stack.len > 0 && stack.items[stack.len - 1]->level >= level) {
          stack.len--;
        }
        if (stack.len > 0) {
          section_add_child(stack.items[stack.len - 1], section);
        } else {
          if (doc->sections_len == doc->sections_cap) {
            doc->sections_cap =
                doc->sections_cap == 0 ? 4 : doc->sections_cap * 2;
            doc->sections = realloc(
                doc->sections, doc->sections_cap * sizeof(DocSpecsSection *));
          }
          doc->sections[doc->sections_len++] = section;
        }
        stack_push(&stack, section);
        free(rest);
        spec_markdown_fence_feed(&fence, raw);
        goto next;
      }
      free(rest);
    }
    if (stack.len > 0) {
      som_strlist_push_copy(&stack.items[stack.len - 1]->body_lines, raw);
    }
    spec_markdown_fence_feed(&fence, raw);

  next:
    free(line);
    free(raw);
    idx++;
    if (nl == NULL) {
      break;
    }
    cursor = nl + 1;
  }
  free(stack.items);
  return doc;
}

void docspecs_document_free(DocSpecsDocument *doc) {
  if (doc == NULL) {
    return;
  }
  free(doc->declared_schema);
  for (size_t i = 0; i < doc->sections_len; i++) {
    section_free(doc->sections[i]);
  }
  free(doc->sections);
  docspecs_violation_list_free(&doc->violations);
  free(doc);
}

/* ---- schema -------------------------------------------------------------- */

static DocSpecsPatternCheck *pattern_check_from_node(const YamlValue *node) {
  if (node == NULL) {
    return NULL;
  }
  DocSpecsPatternCheck *pc = calloc(1, sizeof(DocSpecsPatternCheck));
  if (node->type == YAML_MAP) {
    char *pat = yaml_scalar_string(yaml_get(node, "pattern"));
    char *msg = yaml_scalar_string(yaml_get(node, "error-message"));
    pc->pattern = pat;
    pc->error_message = msg;
  } else {
    pc->pattern = yaml_scalar_string(node);
    pc->error_message = som_strdup("");
  }
  return pc;
}

static void pattern_check_free(DocSpecsPatternCheck *pc) {
  if (pc == NULL) {
    return;
  }
  free(pc->pattern);
  free(pc->error_message);
  free(pc);
}

/* dvIsTrue: a plain-scalar "true" string. */
static int dv_is_true(const YamlValue *v) {
  const char *s = yaml_as_str(v);
  return s != NULL && strcmp(s, "true") == 0;
}

/* dvInt: reads the value as an int when it is one (the hand-rolled parser
 * yields YAML_INT for bare integers). */
static int dv_int(const YamlValue *v, int *out) {
  long long n;
  if (v != NULL && yaml_as_int(v, &n)) {
    *out = (int)n;
    return 1;
  }
  return 0;
}

static int is_supported_section_type_key(const char *k) {
  return strcmp(k, "prefix") == 0 || strcmp(k, "pattern-check-id") == 0 ||
         strcmp(k, "subsection-types") == 0 || strcmp(k, "format") == 0 ||
         strcmp(k, "text-required") == 0 || strcmp(k, "min-text-length") == 0 ||
         strcmp(k, "max-text-length") == 0 || strcmp(k, "description") == 0 ||
         strcmp(k, "validation-prompt") == 0;
}

static void schema_warn(DocSpecsSchema *s, char *owned) {
  som_strlist_push(&s->warnings, owned);
}

static void load_section_types(DocSpecsSchema *s, const YamlValue *node) {
  if (node == NULL || node->type != YAML_MAP) {
    return;
  }
  for (size_t mi = 0; mi < node->as.map.len; mi++) {
    const char *name = node->as.map.entries[mi].key;
    const YamlValue *raw = node->as.map.entries[mi].value;
    if (raw->type != YAML_MAP) {
      continue;
    }
    /* subsection-types */
    DocSpecsSubsectionRule *subs = NULL;
    size_t subs_len = 0;
    size_t subs_cap = 0;
    const YamlValue *sub_node = yaml_get(raw, "subsection-types");
    if (sub_node != NULL && sub_node->type == YAML_MAP) {
      for (size_t si = 0; si < sub_node->as.map.len; si++) {
        const char *sub_name = sub_node->as.map.entries[si].key;
        const YamlValue *sub_raw = sub_node->as.map.entries[si].value;
        int min_count = 0;
        int has_max = 0;
        int max_count = 0;
        if (sub_raw != NULL && sub_raw->type == YAML_MAP) {
          int n;
          if (dv_int(yaml_get(sub_raw, "min-count"), &n)) {
            min_count = n;
          }
          if (dv_int(yaml_get(sub_raw, "max-count"), &n)) {
            has_max = 1;
            max_count = n;
          }
        }
        if (subs_len == subs_cap) {
          subs_cap = subs_cap == 0 ? 4 : subs_cap * 2;
          subs = realloc(subs, subs_cap * sizeof(DocSpecsSubsectionRule));
        }
        subs[subs_len].name = som_strdup(sub_name);
        subs[subs_len].min_count = min_count;
        subs[subs_len].has_max = has_max;
        subs[subs_len].max_count = max_count;
        subs_len++;
      }
    }
    /* warn on unsupported keys */
    for (size_t ki = 0; ki < raw->as.map.len; ki++) {
      const char *key = raw->as.map.entries[ki].key;
      if (!is_supported_section_type_key(key)) {
        schema_warn(s, vcat("unsupported key \"", key,
                            "\" on section-type \"", name, "\" ignored", NULL));
      }
    }
    /* prefix */
    char *prefix;
    if (yaml_get(raw, "prefix") != NULL) {
      prefix = yaml_scalar_string(yaml_get(raw, "prefix"));
    } else {
      char *up = upper_ascii(name);
      prefix = docspecs_id_transform(up);
      free(up);
    }
    int has_min = 0, min_text = 0, has_max = 0, max_text = 0, n;
    if (dv_int(yaml_get(raw, "min-text-length"), &n)) {
      has_min = 1;
      min_text = n;
    }
    if (dv_int(yaml_get(raw, "max-text-length"), &n)) {
      has_max = 1;
      max_text = n;
    }
    if (s->section_types_len ==
        (size_t)-1) { /* unreachable guard, keeps type happy */
    }
    s->section_types =
        realloc(s->section_types,
                (s->section_types_len + 1) * sizeof(DocSpecsSectionType));
    DocSpecsSectionType *t = &s->section_types[s->section_types_len++];
    t->name = som_strdup(name);
    t->prefix = prefix;
    t->pattern_check = pattern_check_from_node(yaml_get(raw, "pattern-check-id"));
    t->subsection_types = subs;
    t->subsection_types_len = subs_len;
    t->format = yaml_scalar_string(yaml_get(raw, "format"));
    t->text_required = dv_is_true(yaml_get(raw, "text-required"));
    t->has_min_text_length = has_min;
    t->min_text_length = min_text;
    t->has_max_text_length = has_max;
    t->max_text_length = max_text;
    t->description = yaml_scalar_string(yaml_get(raw, "description"));
    t->validation_prompt = yaml_scalar_string(yaml_get(raw, "validation-prompt"));
  }
}

static void load_form_types(DocSpecsSchema *s, const YamlValue *node) {
  if (node == NULL || node->type != YAML_MAP) {
    return;
  }
  for (size_t mi = 0; mi < node->as.map.len; mi++) {
    const char *name = node->as.map.entries[mi].key;
    const YamlValue *raw = node->as.map.entries[mi].value;
    if (raw->type != YAML_MAP) {
      continue;
    }
    for (size_t ki = 0; ki < raw->as.map.len; ki++) {
      const char *key = raw->as.map.entries[ki].key;
      if (strcmp(key, "fields") != 0) {
        schema_warn(s, vcat("unsupported key \"", key, "\" on form-type \"",
                            name, "\" ignored", NULL));
      }
    }
    DocSpecsFormField *fields = NULL;
    size_t fields_len = 0;
    const YamlValue *fields_node = yaml_get(raw, "fields");
    if (fields_node != NULL && fields_node->type == YAML_SEQ) {
      fields = calloc(fields_node->as.seq.len, sizeof(DocSpecsFormField));
      for (size_t fi = 0; fi < fields_node->as.seq.len; fi++) {
        const YamlValue *fm = fields_node->as.seq.items[fi];
        if (fm->type != YAML_MAP) {
          continue;
        }
        DocSpecsFormField *f = &fields[fields_len++];
        f->name = yaml_scalar_string(yaml_get(fm, "fieldname"));
        f->required = dv_is_true(yaml_get(fm, "required"));
        f->description = yaml_scalar_string(yaml_get(fm, "description"));
        f->pattern_check = pattern_check_from_node(yaml_get(fm, "pattern-check"));
      }
    }
    s->form_types = realloc(s->form_types,
                            (s->form_types_len + 1) * sizeof(DocSpecsFormType));
    DocSpecsFormType *ft = &s->form_types[s->form_types_len++];
    ft->name = som_strdup(name);
    ft->fields = fields;
    ft->fields_len = fields_len;
  }
}

static void load_document(DocSpecsSchema *s, const YamlValue *node) {
  if (node == NULL || node->type != YAML_MAP) {
    return;
  }
  for (size_t ki = 0; ki < node->as.map.len; ki++) {
    const char *k = node->as.map.entries[ki].key;
    const YamlValue *v = node->as.map.entries[ki].value;
    if (strcmp(k, "sections") == 0) {
      if (v == NULL || v->type != YAML_MAP) {
        continue;
      }
      for (size_t si = 0; si < v->as.map.len; si++) {
        const char *s_key = v->as.map.entries[si].key;
        const YamlValue *s_raw = v->as.map.entries[si].value;
        char *section_type = som_strdup(s_key);
        int optional = 0;
        if (s_raw != NULL && s_raw->type == YAML_MAP) {
          if (yaml_get(s_raw, "section-type") != NULL) {
            free(section_type);
            section_type = yaml_scalar_string(yaml_get(s_raw, "section-type"));
          }
          optional = dv_is_true(yaml_get(s_raw, "optional"));
        }
        s->document_sections = realloc(
            s->document_sections,
            (s->document_sections_len + 1) * sizeof(DocSpecsDocumentSection));
        DocSpecsDocumentSection *ds =
            &s->document_sections[s->document_sections_len++];
        ds->key = som_strdup(s_key);
        ds->section_type = section_type;
        ds->optional = optional;
      }
    } else if (strcmp(k, "name") != 0 && strcmp(k, "description") != 0) {
      schema_warn(s, vcat("unsupported document key \"", k, "\" ignored", NULL));
    }
  }
}

int docspecs_schema_from_yaml_text(const char *text, DocSpecsSchema **out,
                                   char **err) {
  YamlValue *data = yaml_parse(text);
  int is_map = data != NULL && data->type == YAML_MAP;
  /* mirror the Go guard: a non-map root, or an empty parse of a non-blank text
   * that carries no `:` at all, is "not a YAML map". */
  char *trimmed = trim_space(text);
  int has_colon = strchr(text, ':') != NULL;
  int empty_map = is_map && data->as.map.len == 0;
  if (!is_map || (empty_map && trimmed[0] != '\0' && !has_colon)) {
    free(trimmed);
    yaml_value_free(data);
    if (err != NULL) {
      *err = som_strdup("docspecs schema must be a YAML map");
    }
    return 0;
  }
  free(trimmed);

  DocSpecsSchema *schema = calloc(1, sizeof(DocSpecsSchema));
  schema->title_format = som_strdup("");
  som_strlist_init(&schema->warnings);

  for (size_t ki = 0; ki < data->as.map.len; ki++) {
    const char *k = data->as.map.entries[ki].key;
    const YamlValue *v = data->as.map.entries[ki].value;
    if (strcmp(k, "title-format") == 0) {
      free(schema->title_format);
      schema->title_format = yaml_scalar_string(v);
    } else if (strcmp(k, "section-types") == 0) {
      load_section_types(schema, v);
    } else if (strcmp(k, "form-types") == 0) {
      load_form_types(schema, v);
    } else if (strcmp(k, "document") == 0) {
      load_document(schema, v);
    } else if (strcmp(k, "schema") == 0 || strcmp(k, "version") == 0 ||
               strcmp(k, "name") == 0 || strcmp(k, "description") == 0) {
      /* informational keys — accepted, unused */
    } else {
      schema_warn(schema, vcat("unsupported top-level schema key \"", k,
                               "\" ignored", NULL));
    }
  }
  yaml_value_free(data);
  *out = schema;
  return 1;
}

static void section_type_free(DocSpecsSectionType *t) {
  free(t->name);
  free(t->prefix);
  pattern_check_free(t->pattern_check);
  for (size_t i = 0; i < t->subsection_types_len; i++) {
    free(t->subsection_types[i].name);
  }
  free(t->subsection_types);
  free(t->format);
  free(t->description);
  free(t->validation_prompt);
}

void docspecs_schema_free(DocSpecsSchema *s) {
  if (s == NULL) {
    return;
  }
  free(s->title_format);
  for (size_t i = 0; i < s->section_types_len; i++) {
    section_type_free(&s->section_types[i]);
  }
  free(s->section_types);
  for (size_t i = 0; i < s->form_types_len; i++) {
    free(s->form_types[i].name);
    for (size_t j = 0; j < s->form_types[i].fields_len; j++) {
      free(s->form_types[i].fields[j].name);
      free(s->form_types[i].fields[j].description);
      pattern_check_free(s->form_types[i].fields[j].pattern_check);
    }
    free(s->form_types[i].fields);
  }
  free(s->form_types);
  for (size_t i = 0; i < s->document_sections_len; i++) {
    free(s->document_sections[i].key);
    free(s->document_sections[i].section_type);
  }
  free(s->document_sections);
  som_strlist_free(&s->warnings);
  free(s);
}

const DocSpecsSectionType *docspecs_schema_section_type_by_name(
    const DocSpecsSchema *s, const char *name) {
  for (size_t i = 0; i < s->section_types_len; i++) {
    if (strcmp(s->section_types[i].name, name) == 0) {
      return &s->section_types[i];
    }
  }
  return NULL;
}

const DocSpecsFormType *docspecs_schema_form_type(const DocSpecsSchema *s,
                                                  const char *name) {
  for (size_t i = 0; i < s->form_types_len; i++) {
    if (strcmp(s->form_types[i].name, name) == 0) {
      return &s->form_types[i];
    }
  }
  return NULL;
}

const DocSpecsDocumentSection *docspecs_schema_document_section(
    const DocSpecsSchema *s, const char *key) {
  for (size_t i = 0; i < s->document_sections_len; i++) {
    if (strcmp(s->document_sections[i].key, key) == 0) {
      return &s->document_sections[i];
    }
  }
  return NULL;
}

const DocSpecsSubsectionRule *docspecs_section_type_subsection(
    const DocSpecsSectionType *t, const char *name) {
  for (size_t i = 0; i < t->subsection_types_len; i++) {
    if (strcmp(t->subsection_types[i].name, name) == 0) {
      return &t->subsection_types[i];
    }
  }
  return NULL;
}

char *docspecs_schema_root_section_id(const DocSpecsSchema *s) {
  if (s->title_format[0] == '\0') {
    return som_strdup("");
  }
  /* docspecsRootIDRE = `<!--\[([^\]]+)\]-->` (search). */
  const char *p = s->title_format;
  while ((p = strstr(p, "<!--[")) != NULL) {
    const char *inner = p + 5;
    const char *close = strchr(inner, ']');
    if (close != NULL && close != inner && strncmp(close, "]-->", 4) == 0) {
      return som_strdup_n(inner, (size_t)(close - inner));
    }
    p += 5;
  }
  return som_strdup("");
}

const DocSpecsSectionType *docspecs_schema_resolve_section_type(
    const DocSpecsSchema *s, const char *id) {
  char *transformed = docspecs_id_transform(id);
  const DocSpecsSectionType *found = NULL;
  for (size_t i = 0; i < s->section_types_len; i++) {
    const char *prefix = s->section_types[i].prefix;
    if (strncmp(transformed, prefix, strlen(prefix)) == 0) {
      found = &s->section_types[i];
      break;
    }
  }
  free(transformed);
  return found;
}

/* ---- validator ----------------------------------------------------------- */

DocSpecsValidator docspecs_validator_new(const DocSpecsSchema *schema) {
  DocSpecsValidator v;
  v.schema = schema;
  return v;
}

void docspecs_validator_validate_markdown(const DocSpecsValidator *val,
                                          const char *markdown,
                                          DocSpecsViolationList *out) {
  DocSpecsDocument *doc = docspecs_parse_document(markdown);
  docspecs_validator_validate(val, doc, out);
  docspecs_document_free(doc);
}

/* resolveChild: resolves a child section's type; on no-match pushes an
 * unknownSection violation. Returns the type (may be NULL). */
static const DocSpecsSectionType *resolve_child(const DocSpecsValidator *val,
                                                const DocSpecsSection *section,
                                                DocSpecsViolationList *v) {
  if (section->id[0] == '\0') {
    return NULL; /* already reported MALFORMED_HEADING by the parse */
  }
  const DocSpecsSectionType *t =
      docspecs_schema_resolve_section_type(val->schema, section->id);
  if (t == NULL) {
    dv_push(v, DOCSPECS_RULE_UNKNOWN_SECTION, section->line,
            vcat("section id \"", section->id,
                 "\" resolves to no section-type of the schema", NULL),
            section->id, "");
  }
  return t;
}

static void validate_section(const DocSpecsValidator *val,
                             const DocSpecsSection *section,
                             const DocSpecsSectionType *t,
                             DocSpecsViolationList *v);

static void validate_text(const DocSpecsValidator *val,
                          const DocSpecsSection *section,
                          const DocSpecsSectionType *t,
                          DocSpecsViolationList *v) {
  if (t->format[0] != '\0') {
    if (docspecs_schema_form_type(val->schema, t->format) != NULL) {
      return; /* form sections carry fields, not body text */
    }
  }
  char *text = docspecs_section_text(section);
  if (t->text_required && text[0] == '\0') {
    dv_push(v, DOCSPECS_RULE_TEXT_REQUIRED, section->line,
            som_strdup("section requires body text but has none"),
            section->id, "");
    free(text);
    return;
  }
  size_t length = rune_count(text);
  int has_min = t->has_min_text_length;
  int has_max = t->has_max_text_length;
  if ((has_min && length < (size_t)t->min_text_length) ||
      (has_max && length > (size_t)t->max_text_length)) {
    char *min_str = has_min ? dv_itoa(t->min_text_length) : som_strdup("0");
    char *max_str =
        has_max ? dv_itoa(t->max_text_length) : som_strdup("\xe2\x88\x9e");
    char *len_str = dv_itoa((long long)length);
    dv_push(v, DOCSPECS_RULE_TEXT_LENGTH_OUT, section->line,
            vcat("body text length ", len_str, " is outside [", min_str, ", ",
                 max_str, "]", NULL),
            section->id, "");
    free(min_str);
    free(max_str);
    free(len_str);
  }
  free(text);
}

static void validate_form(const DocSpecsValidator *val,
                          const DocSpecsSection *section,
                          const DocSpecsFormType *form,
                          DocSpecsViolationList *v) {
  (void)val; /* form validation needs no schema lookups */
  /* Field name → collected value lines; field name → label line. Small linear
   * association tables keyed by the form's own field list. */
  size_t nf = form->fields_len;
  SomBuf *values = calloc(nf, sizeof(SomBuf));
  int *have_value = calloc(nf, sizeof(int));
  int *field_line = calloc(nf, sizeof(int));
  for (size_t i = 0; i < nf; i++) {
    som_buf_init(&values[i]);
  }

  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  int current = -1; /* index into fields */
  const SomStrList *body = &section->body_lines;
  for (size_t i = 0; i < body->len; i++) {
    const char *raw = body->items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      char *label = NULL;
      char *value = NULL;
      if (match_field_label(raw, &label, &value)) {
        /* byLower lookup */
        char *label_lower = lower_ascii(label);
        int idx = -1;
        for (size_t fi = 0; fi < nf; fi++) {
          char *fn_lower = lower_ascii(form->fields[fi].name);
          int hit = strcmp(fn_lower, label_lower) == 0;
          free(fn_lower);
          if (hit) {
            idx = (int)fi;
            break;
          }
        }
        free(label_lower);
        if (idx >= 0) {
          current = idx;
          /* reset the collected value to just group 2 */
          som_buf_free(&values[idx]);
          som_buf_init(&values[idx]);
          som_buf_puts(&values[idx], value);
          have_value[idx] = 1;
          field_line[idx] = docspecs_section_body_start_line(section) + (int)i;
          free(label);
          free(value);
          spec_markdown_fence_feed(&fence, raw);
          continue;
        }
        free(label);
        free(value);
      }
    }
    if (current >= 0) {
      som_buf_putc(&values[current], '\n');
      som_buf_puts(&values[current], raw);
    }
    spec_markdown_fence_feed(&fence, raw);
  }

  for (size_t fi = 0; fi < nf; fi++) {
    const DocSpecsFormField *field = &form->fields[fi];
    char *value;
    if (have_value[fi]) {
      char *joined = som_buf_take(&values[fi]);
      value = trim_space(joined);
      free(joined);
    } else {
      value = som_strdup("");
    }
    if (field->required && value[0] == '\0') {
      dv_push(v, DOCSPECS_RULE_MISSING_REQUIRED_FIELD, section->line,
              vcat("required form field \"", field->name, "\" of \"",
                   form->name, "\" is missing", NULL),
              section->id, "");
      free(value);
      continue;
    }
    const DocSpecsPatternCheck *pc = field->pattern_check;
    if (pc != NULL && value[0] != '\0' &&
        !docspecs_pattern_check_matches(pc, value)) {
      int line = have_value[fi] ? field_line[fi] : section->line;
      char *message;
      if (pc->error_message[0] != '\0') {
        message = som_strdup(pc->error_message);
      } else {
        message = vcat("form field \"", field->name,
                       "\" does not match pattern \"", pc->pattern, "\"", NULL);
      }
      dv_push(v, DOCSPECS_RULE_FIELD_PATTERN_MISMATCH, line, message,
              section->id, "");
    }
    free(value);
  }

  for (size_t i = 0; i < nf; i++) {
    som_buf_free(&values[i]);
  }
  free(values);
  free(have_value);
  free(field_line);
}

static void validate_format(const DocSpecsValidator *val,
                            const DocSpecsSection *section,
                            const DocSpecsSectionType *t,
                            DocSpecsViolationList *v) {
  const char *format = t->format;
  if (format[0] == '\0') {
    return;
  }
  const DocSpecsFormType *form = docspecs_schema_form_type(val->schema, format);
  if (form != NULL) {
    validate_form(val, section, form, v);
    return;
  }
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  int saw_fence = 0;
  const SomStrList *body = &section->body_lines;
  for (size_t i = 0; i < body->len; i++) {
    spec_markdown_fence_feed(&fence, body->items[i]);
    if (spec_markdown_fence_in_fence(&fence)) {
      saw_fence = 1;
    }
  }
  if (!saw_fence) {
    dv_push(v, DOCSPECS_RULE_FORMAT_MISMATCH, section->line,
            vcat("section format \"", format,
                 "\" demands a fenced code block, but the body contains none",
                 NULL),
            section->id, "");
  }
}

/* A small name→count association for occurrence tallies. */
typedef struct {
  char **names;
  int *counts;
  size_t len;
  size_t cap;
} CountMap;

static void count_map_init(CountMap *m) {
  m->names = NULL;
  m->counts = NULL;
  m->len = 0;
  m->cap = 0;
}

static void count_map_inc(CountMap *m, const char *name) {
  for (size_t i = 0; i < m->len; i++) {
    if (strcmp(m->names[i], name) == 0) {
      m->counts[i]++;
      return;
    }
  }
  if (m->len == m->cap) {
    m->cap = m->cap == 0 ? 8 : m->cap * 2;
    m->names = realloc(m->names, m->cap * sizeof(char *));
    m->counts = realloc(m->counts, m->cap * sizeof(int));
  }
  m->names[m->len] = som_strdup(name);
  m->counts[m->len] = 1;
  m->len++;
}

static int count_map_get(const CountMap *m, const char *name) {
  for (size_t i = 0; i < m->len; i++) {
    if (strcmp(m->names[i], name) == 0) {
      return m->counts[i];
    }
  }
  return 0;
}

static void count_map_free(CountMap *m) {
  for (size_t i = 0; i < m->len; i++) {
    free(m->names[i]);
  }
  free(m->names);
  free(m->counts);
}

static void validate_section(const DocSpecsValidator *val,
                             const DocSpecsSection *section,
                             const DocSpecsSectionType *t,
                             DocSpecsViolationList *v) {
  const DocSpecsPatternCheck *pc = t->pattern_check;
  if (pc != NULL && section->id[0] != '\0' &&
      !docspecs_pattern_check_matches(pc, section->id)) {
    char *message;
    if (pc->error_message[0] != '\0') {
      message = som_strdup(pc->error_message);
    } else {
      message = vcat("section id \"", section->id,
                     "\" does not match pattern \"", pc->pattern, "\"", NULL);
    }
    dv_push(v, DOCSPECS_RULE_ID_PATTERN_MISMATCH, section->line, message,
            section->id, "");
  }
  validate_text(val, section, t, v);
  validate_format(val, section, t, v);

  CountMap counts;
  count_map_init(&counts);
  for (size_t i = 0; i < section->children_len; i++) {
    const DocSpecsSection *child = section->children[i];
    const DocSpecsSectionType *child_type = resolve_child(val, child, v);
    if (child_type == NULL) {
      continue;
    }
    if (docspecs_section_type_subsection(t, child_type->name) == NULL) {
      dv_push(v, DOCSPECS_RULE_UNKNOWN_SECTION, child->line,
              vcat("section-type \"", child_type->name,
                   "\" is not an allowed subsection of \"", t->name, "\"",
                   NULL),
              child->id, "");
      continue;
    }
    count_map_inc(&counts, child_type->name);
    validate_section(val, child, child_type, v);
  }
  for (size_t i = 0; i < t->subsection_types_len; i++) {
    const DocSpecsSubsectionRule *rule = &t->subsection_types[i];
    const char *sub_key = rule->name;
    int count = count_map_get(&counts, sub_key);
    if (count < rule->min_count) {
      if (count == 0) {
        dv_push(v, DOCSPECS_RULE_MISSING_REQUIRED_SECTION, section->line,
                vcat("required subsection \"", sub_key, "\" of \"", t->name,
                     "\" is missing", NULL),
                sub_key, "");
      } else {
        char *cnt = dv_itoa(count);
        char *min = dv_itoa(rule->min_count);
        dv_push(v, DOCSPECS_RULE_TOO_FEW_ITEMS, section->line,
                vcat("subsection \"", sub_key, "\" occurs ", cnt,
                     " time(s), minimum is ", min, NULL),
                sub_key, "");
        free(cnt);
        free(min);
      }
    }
    if (rule->has_max && count > rule->max_count) {
      char *cnt = dv_itoa(count);
      char *max = dv_itoa(rule->max_count);
      dv_push(v, DOCSPECS_RULE_TOO_MANY_ITEMS, section->line,
              vcat("subsection \"", sub_key, "\" occurs ", cnt,
                   " time(s), maximum is ", max, NULL),
              sub_key, "");
      free(cnt);
      free(max);
    }
  }
  count_map_free(&counts);
}

static void validate_document_sections(const DocSpecsValidator *val,
                                       const DocSpecsSection *root,
                                       DocSpecsViolationList *v) {
  CountMap counts;
  count_map_init(&counts);
  for (size_t i = 0; i < root->children_len; i++) {
    const DocSpecsSection *child = root->children[i];
    const DocSpecsSectionType *t = resolve_child(val, child, v);
    if (t == NULL) {
      continue;
    }
    /* slotTypes membership */
    int is_slot = 0;
    for (size_t si = 0; si < val->schema->document_sections_len; si++) {
      if (strcmp(val->schema->document_sections[si].section_type, t->name) ==
          0) {
        is_slot = 1;
        break;
      }
    }
    if (!is_slot) {
      dv_push(v, DOCSPECS_RULE_UNKNOWN_SECTION, child->line,
              vcat("section-type \"", t->name,
                   "\" is not a top-level document section", NULL),
              child->id, "");
      continue;
    }
    count_map_inc(&counts, t->name);
    validate_section(val, child, t, v);
  }
  for (size_t si = 0; si < val->schema->document_sections_len; si++) {
    const DocSpecsDocumentSection *slot = &val->schema->document_sections[si];
    if (!slot->optional && count_map_get(&counts, slot->section_type) == 0) {
      dv_push(v, DOCSPECS_RULE_MISSING_REQUIRED_SECTION, root->line,
              vcat("required document section \"", slot->key, "\" (type \"",
                   slot->section_type, "\") is missing", NULL),
              slot->key, "");
    }
  }
  count_map_free(&counts);
}

void docspecs_validator_validate(const DocSpecsValidator *val,
                                 const DocSpecsDocument *doc,
                                 DocSpecsViolationList *out) {
  /* copy the parse-time violations first */
  for (size_t i = 0; i < doc->violations.len; i++) {
    const DocSpecsViolation *src = &doc->violations.items[i];
    dv_push(out, src->rule, src->line, som_strdup(src->message),
            src->section_id, src->path);
  }
  if (doc->sections_len == 0) {
    dv_push(out, DOCSPECS_RULE_FORMAT_MISMATCH, 1,
            som_strdup("document has no root heading"), "", "");
    return;
  }
  const DocSpecsSection *root = doc->sections[0];
  char *root_id = docspecs_schema_root_section_id(val->schema);
  if (root_id[0] != '\0' && strcmp(root->id, root_id) != 0) {
    dv_push(out, DOCSPECS_RULE_FORMAT_MISMATCH, root->line,
            vcat("root heading id \"", root->id,
                 "\" does not match the schema title-format id \"", root_id,
                 "\"", NULL),
            root->id, "");
  }
  free(root_id);
  for (size_t i = 1; i < doc->sections_len; i++) {
    const DocSpecsSection *extra = doc->sections[i];
    dv_push(out, DOCSPECS_RULE_UNKNOWN_SECTION, extra->line,
            som_strdup("unexpected additional top-level section"), extra->id,
            "");
  }
  validate_document_sections(val, root, out);
}

/* ---- bind ---------------------------------------------------------------- */

void docspecs_bind_markdown(const SpecModel *model, const char *text,
                            SpecMarkdownResult *out) {
  spec_markdown_parse(model, text, out);
}
