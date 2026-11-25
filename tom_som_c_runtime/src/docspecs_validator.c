/* docspecs_validator — implementation. See docspecs_validator.h; a faithful
 * 1:1 port of the Go `docspecs_validator.go` (SOM §14). */
#include "docspecs_validator.h"

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document_markdown.h"
#include "spec_notation.h"

const char *const DOCSPECS_ALL_RULES[DOCSPECS_ALL_RULES_COUNT] = {
    DOCSPECS_RULE_UNKNOWN_SECTION,
    DOCSPECS_RULE_MISSING_REQUIRED_SECTION,
    DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    DOCSPECS_RULE_TOO_FEW_ITEMS,
    DOCSPECS_RULE_TOO_MANY_ITEMS,
    DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
    DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
    DOCSPECS_RULE_TEXT_REQUIRED,
    DOCSPECS_RULE_TEXT_LENGTH_OUT,
    DOCSPECS_RULE_FORMAT_MISMATCH,
    DOCSPECS_RULE_MALFORMED_HEADING,
    DOCSPECS_RULE_SECTION_OUT_OF_ORDER,
    DOCSPECS_RULE_DUPLICATE_ID_PATH,
    DOCSPECS_RULE_UNCLOSED_DIV,
    DOCSPECS_RULE_STRAY_CLOSING_FENCE,
    DOCSPECS_RULE_UNCLOSED_SPAN,
    DOCSPECS_RULE_DIV_WITHOUT_KIND,
    DOCSPECS_RULE_UNKNOWN_KIND,
    DOCSPECS_RULE_MARK_ACROSS_NOTATION,
    DOCSPECS_RULE_ANNOTATION_INSIDE_DIV,
    DOCSPECS_RULE_DIV_INSIDE_ANNOTATION,
    DOCSPECS_RULE_REJECTED_BLOCK,
    DOCSPECS_RULE_MALFORMED_BLOCK,
    DOCSPECS_RULE_UNKNOWN_FIELD,
};

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

/* A backtracking matcher for the DocSpecs pattern-check subset of the
 * regular expressions the other ports use: `^` / `$` anchors, literals and
 * `\` escapes (`\d`, `\w`, `\s` and their negations as classes), `.`,
 * character classes `[...]` (with ranges and a leading `^` negation), groups
 * `(...)` / `(?:...)` with alternation `|`, and the quantifiers `*`, `+`, `?`,
 * `{n}`, `{n,}`, `{n,m}`. Semantics mirror Go's `MatchString` (an *unanchored*
 * search unless the pattern is `^`-anchored). A malformed pattern (an
 * unterminated class or group) makes `matches` return 0 — the Go code returns
 * false when `Compile` errors. */

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

/* The pattern as a tree: an alternation of sequences of quantified atoms. */
typedef enum {
  RX_LITERAL,
  RX_ANY,
  RX_CLASS,
  RX_ESCAPE_CLASS, /* \d \w \s and their negations \D \W \S */
  RX_START,
  RX_END,
  RX_GROUP,
} RxKind;

typedef struct RxNode RxNode;

typedef struct {
  RxNode **items;
  size_t len;
  size_t cap;
} RxSeq;

struct RxNode {
  RxKind kind;
  char literal;    /* RX_LITERAL; the letter of RX_ESCAPE_CLASS */
  const char *cls; /* RX_CLASS: pointer into pattern at '[' */
  size_t cls_len;  /* bytes from '[' to ']' inclusive */
  RxSeq *alts;     /* RX_GROUP: its alternatives */
  size_t alts_len;
  int min;         /* repetitions: min, max (-1: unbounded) */
  int max;
};

typedef struct {
  RxNode *root; /* a group holding the whole pattern */
  int ok;
} Rx;

static void rx_node_free(RxNode *n);

static void rx_seq_free(RxSeq *s) {
  for (size_t i = 0; i < s->len; i++) rx_node_free(s->items[i]);
  free(s->items);
}

static void rx_node_free(RxNode *n) {
  if (n == NULL) return;
  for (size_t i = 0; i < n->alts_len; i++) rx_seq_free(&n->alts[i]);
  free(n->alts);
  free(n);
}

static void rx_seq_push(RxSeq *s, RxNode *n) {
  if (s->len == s->cap) {
    s->cap = s->cap ? s->cap * 2 : 4;
    s->items = realloc(s->items, s->cap * sizeof(RxNode *));
  }
  s->items[s->len++] = n;
}

static RxNode *rx_parse_alternation(const char *p, size_t n, size_t *i, int *ok);

/* A `{n}`, `{n,}` or `{n,m}` quantifier at p[*i]; 0 when there is none. */
static int rx_parse_braces(const char *p, size_t n, size_t *i, int *min,
                           int *max) {
  size_t k = *i + 1;
  if (k >= n || !(p[k] >= '0' && p[k] <= '9')) return 0;
  int a = 0;
  while (k < n && p[k] >= '0' && p[k] <= '9') a = a * 10 + (p[k++] - '0');
  int b = a;
  if (k < n && p[k] == ',') {
    k++;
    if (k < n && p[k] >= '0' && p[k] <= '9') {
      b = 0;
      while (k < n && p[k] >= '0' && p[k] <= '9') b = b * 10 + (p[k++] - '0');
    } else {
      b = -1;
    }
  }
  if (k >= n || p[k] != '}') return 0;
  *min = a;
  *max = b;
  *i = k + 1;
  return 1;
}

/* One sequence, up to `|`, `)` or the end. */
static void rx_parse_sequence(const char *p, size_t n, size_t *i, RxSeq *out,
                              int *ok) {
  while (*i < n && p[*i] != '|' && p[*i] != ')' && *ok) {
    RxNode *node = calloc(1, sizeof(RxNode));
    node->min = 1;
    node->max = 1;
    char c = p[*i];
    if (c == '^') {
      node->kind = RX_START;
      (*i)++;
    } else if (c == '$') {
      node->kind = RX_END;
      (*i)++;
    } else if (c == '.') {
      node->kind = RX_ANY;
      (*i)++;
    } else if (c == '(') {
      (*i)++;
      if (*i + 1 < n && p[*i] == '?' && p[*i + 1] == ':') *i += 2;
      RxNode *group = rx_parse_alternation(p, n, i, ok);
      if (*i >= n || p[*i] != ')') {
        *ok = 0;
        rx_node_free(group);
        free(node);
        return;
      }
      (*i)++;
      free(node);
      node = group;
    } else if (c == '[') {
      size_t j = *i + 1;
      if (j < n && p[j] == '^') j++;
      if (j < n && p[j] == ']') j++; /* a literal ']' as first member */
      while (j < n && p[j] != ']') j++;
      if (j >= n) {
        *ok = 0; /* an unterminated class */
        free(node);
        return;
      }
      node->kind = RX_CLASS;
      node->cls = p + *i;
      node->cls_len = (j - *i) + 1;
      *i = j + 1;
    } else if (c == '\\' && *i + 1 < n) {
      char e = p[*i + 1];
      if (strchr("dwsDWS", e) != NULL) {
        node->kind = RX_ESCAPE_CLASS;
      } else {
        node->kind = RX_LITERAL;
      }
      node->literal = e;
      *i += 2;
    } else {
      node->kind = RX_LITERAL;
      node->literal = c;
      (*i)++;
    }
    /* a quantifier (anchors take none); a lazy `?` after it changes nothing
     * for a yes/no match */
    if (node->kind != RX_START && node->kind != RX_END && *i < n) {
      char q = p[*i];
      int quantified = 1;
      if (q == '*') {
        node->min = 0;
        node->max = -1;
        (*i)++;
      } else if (q == '+') {
        node->min = 1;
        node->max = -1;
        (*i)++;
      } else if (q == '?') {
        node->min = 0;
        node->max = 1;
        (*i)++;
      } else if (q == '{' && rx_parse_braces(p, n, i, &node->min, &node->max)) {
        /* parsed */
      } else {
        quantified = 0;
      }
      if (quantified && *i < n && p[*i] == '?') (*i)++;
    }
    rx_seq_push(out, node);
  }
}

/* An alternation, as a group node of its sequences. */
static RxNode *rx_parse_alternation(const char *p, size_t n, size_t *i,
                                    int *ok) {
  RxNode *group = calloc(1, sizeof(RxNode));
  group->kind = RX_GROUP;
  group->min = 1;
  group->max = 1;
  size_t cap = 0;
  for (;;) {
    if (group->alts_len == cap) {
      cap = cap ? cap * 2 : 2;
      group->alts = realloc(group->alts, cap * sizeof(RxSeq));
    }
    RxSeq *seq = &group->alts[group->alts_len++];
    seq->items = NULL;
    seq->len = 0;
    seq->cap = 0;
    rx_parse_sequence(p, n, i, seq, ok);
    if (!*ok || *i >= n || p[*i] != '|') break;
    (*i)++;
  }
  return group;
}

/* Compiles the pattern into `rx`; a malformed pattern makes it not ok. */
static void rx_compile(Rx *rx, const char *pattern) {
  size_t n = strlen(pattern), i = 0;
  rx->ok = 1;
  rx->root = rx_parse_alternation(pattern, n, &i, &rx->ok);
  if (rx->ok && i != n) rx->ok = 0; /* an unmatched `)` */
}

static void rx_free(Rx *rx) {
  rx_node_free(rx->root);
  rx->root = NULL;
}

/* The byte length of the UTF-8 character at text[pos]. */
static size_t rx_char_len(const char *text, size_t pos, size_t tlen) {
  unsigned char c = (unsigned char)text[pos];
  size_t len = c < 0x80 ? 1 : c >= 0xF0 ? 4 : c >= 0xE0 ? 3 : c >= 0xC0 ? 2 : 1;
  return pos + len <= tlen ? len : 1;
}

/* How many bytes a single (non-group, non-anchor) atom consumes at `pos`, or
 * 0 when it does not match there. */
static size_t rx_atom_match(const RxNode *a, const char *text, size_t pos,
                            size_t tlen) {
  if (pos >= tlen) return 0;
  char c = text[pos];
  switch (a->kind) {
  case RX_LITERAL:
    return c == a->literal ? 1 : 0;
  case RX_ANY:
    return c != '\n' ? rx_char_len(text, pos, tlen) : 0;
  case RX_CLASS:
    return rx_class_match(a->cls, a->cls_len, c) ? 1 : 0;
  case RX_ESCAPE_CLASS: {
    int in;
    char e = a->literal;
    char lower = (char)(e | 0x20);
    if (lower == 'd') {
      in = c >= '0' && c <= '9';
    } else if (lower == 'w') {
      in = (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') ||
           (c >= 'a' && c <= 'z') || c == '_';
    } else {
      in = c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
           c == '\v';
    }
    if (e >= 'A' && e <= 'Z') in = !in;
    if (!in) return 0;
    return e >= 'A' && e <= 'Z' ? rx_char_len(text, pos, tlen) : 1;
  }
  default:
    return 0;
  }
}

/* What is left to match after the current point: the rest of a sequence,
 * or the remaining repetitions of a node (`rep`, `count` done so far,
 * `start` where the current repetition began). */
typedef struct RxCont {
  const RxSeq *seq;
  size_t idx;
  const RxNode *rep;
  int count;
  size_t start;
  const struct RxCont *next;
} RxCont;

static int rx_match_seq(const RxSeq *seq, size_t idx, const char *text,
                        size_t pos, size_t tlen, const RxCont *k);

static int rx_match_node(const RxNode *node, int count, const RxSeq *seq,
                         size_t idx, const char *text, size_t pos, size_t tlen,
                         const RxCont *k);

static int rx_continue(const char *text, size_t pos, size_t tlen,
                       const RxCont *k) {
  if (k == NULL) return 1;
  if (k->rep != NULL) {
    /* an empty repetition ends the loop (no endless zero-width rounds) */
    if (pos == k->start) {
      if (k->count >= k->rep->min) {
        return rx_match_seq(k->seq, k->idx + 1, text, pos, tlen, k->next);
      }
    }
    return rx_match_node(k->rep, k->count, k->seq, k->idx, text, pos, tlen,
                         k->next);
  }
  return rx_match_seq(k->seq, k->idx, text, pos, tlen, k->next);
}

/* Node `seq->items[idx]` with `count` repetitions done: one more (greedy),
 * else the rest of the sequence. */
static int rx_match_node(const RxNode *node, int count, const RxSeq *seq,
                         size_t idx, const char *text, size_t pos, size_t tlen,
                         const RxCont *k) {
  if (node->max < 0 || count < node->max) {
    if (node->kind == RX_GROUP) {
      RxCont again = {seq, idx, node, count + 1, pos, k};
      for (size_t a = 0; a < node->alts_len; a++) {
        if (rx_match_seq(&node->alts[a], 0, text, pos, tlen, &again)) return 1;
      }
    } else {
      size_t used = rx_atom_match(node, text, pos, tlen);
      if (used > 0 &&
          rx_match_node(node, count + 1, seq, idx, text, pos + used, tlen, k)) {
        return 1;
      }
    }
  }
  if (count >= node->min) {
    return rx_match_seq(seq, idx + 1, text, pos, tlen, k);
  }
  return 0;
}

static int rx_match_seq(const RxSeq *seq, size_t idx, const char *text,
                        size_t pos, size_t tlen, const RxCont *k) {
  if (idx == seq->len) return rx_continue(text, pos, tlen, k);
  const RxNode *node = seq->items[idx];
  if (node->kind == RX_START) {
    return pos == 0 ? rx_match_seq(seq, idx + 1, text, pos, tlen, k) : 0;
  }
  if (node->kind == RX_END) {
    return pos == tlen ? rx_match_seq(seq, idx + 1, text, pos, tlen, k) : 0;
  }
  return rx_match_node(node, 0, seq, idx, text, pos, tlen, k);
}

/* Go MatchString: an unanchored search. */
static int rx_search(const Rx *rx, const char *text) {
  if (!rx->ok) return 0;
  size_t tlen = strlen(text);
  RxSeq top = {(RxNode **)&rx->root, 1, 1};
  for (size_t start = 0;; start++) {
    if (rx_match_seq(&top, 0, text, start, tlen, NULL)) return 1;
    if (start >= tlen) break;
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

/* A styled-div heading (the DocSpecs specification's *Styled-div headings*):
 * a whole line `<div class="heading<N>" …>…</div>` at column 0 with N >= 7
 * reads as a heading of level N whose text is the div's inner text with
 * `&amp;`, `&lt;`, `&gt;` decoded and trimmed. A `heading<N>` div with N <= 6
 * is content. Writes the level and the owned text. */
static int match_styled_div_heading(const char *s, int *level, char **text) {
  static const char open[] = "<div class=\"heading";
  if (strncmp(s, open, sizeof(open) - 1) != 0) return 0;
  const char *p = s + sizeof(open) - 1;
  if (!(*p >= '0' && *p <= '9')) return 0;
  long n = 0;
  while (*p >= '0' && *p <= '9') {
    n = n * 10 + (*p - '0');
    if (n > 100000) return 0;
    p++;
  }
  if (*p != '"') return 0;
  p++;
  while (*p != '\0' && *p != '>') p++; /* `[^>]*` */
  if (*p != '>') return 0;
  p++;
  size_t len = strlen(p);
  if (len < 6 || strcmp(p + len - 6, "</div>") != 0) return 0;
  if (n < 7) return 0;
  char *inner = som_strdup_n(p, len - 6);
  /* `&lt;`, `&gt;`, then `&amp;` */
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; inner[i] != '\0';) {
    if (strncmp(inner + i, "&lt;", 4) == 0) {
      som_buf_putc(&b, '<');
      i += 4;
    } else if (strncmp(inner + i, "&gt;", 4) == 0) {
      som_buf_putc(&b, '>');
      i += 4;
    } else {
      som_buf_putc(&b, inner[i]);
      i++;
    }
  }
  free(inner);
  char *partial = som_buf_take(&b);
  som_buf_init(&b);
  for (size_t i = 0; partial[i] != '\0';) {
    if (strncmp(partial + i, "&amp;", 5) == 0) {
      som_buf_putc(&b, '&');
      i += 5;
    } else {
      som_buf_putc(&b, partial[i]);
      i++;
    }
  }
  free(partial);
  char *decoded = som_buf_take(&b);
  *level = (int)n;
  *text = trim_space(decoded);
  free(decoded);
  return 1;
}

/* Whether `anchor` is the own anchor of a section with `id` (Section
 * Anchors): `id` itself, or a qualified form `<A>/…/<id>` without an empty
 * segment. */
static int own_anchor(const char *anchor, const char *id) {
  if (strcmp(anchor, id) == 0) return 1;
  size_t al = strlen(anchor), il = strlen(id);
  if (al < il + 1 || anchor[al - il - 1] != '/' ||
      strcmp(anchor + al - il, id) != 0 || anchor[0] == '/') {
    return 0;
  }
  for (size_t k = 0; k + 1 < al; k++) {
    if (anchor[k] == '/' && anchor[k + 1] == '/') return 0;
  }
  return 1;
}

/* `title` without a leading own anchor `<a id="ID"></a>` (and the whitespace
 * after it) of the section `id`. Owned. */
static char *strip_own_title_anchor(const char *title, const char *id) {
  if (strncmp(title, "<a id=\"", 7) == 0) {
    const char *q = strchr(title + 7, '"');
    if (q != NULL && strncmp(q, "\"></a>", 6) == 0) {
      char *anchor = som_strdup_n(title + 7, (size_t)(q - title - 7));
      int own = own_anchor(anchor, id);
      free(anchor);
      if (own) {
        const char *r = q + 6;
        while (is_ascii_ws(*r)) r++;
        return som_strdup(r);
      }
    }
  }
  return som_strdup(title);
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
      if (match_heading_line(line, &level, &rest) ||
          match_styled_div_heading(line, &level, &rest)) {
        DocSpecsSection *section = NULL;
        char *cid = NULL;
        char *ctitle = NULL;
        if (match_headline_comment(rest, &cid, &ctitle)) {
          /* The title without the section's own anchor (Section Anchors). */
          char *trimmed_title = trim_space(ctitle);
          char *own = strip_own_title_anchor(trimmed_title, cid);
          free(trimmed_title);
          const char *title = own;
          if (title[0] == '\0') {
            title = rest;
          }
          section = section_new(cid, title, level, line_no);
          free(own);
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

static size_t docspecs_count_sections(DocSpecsSection *const *list, size_t len) {
  size_t n = len;
  for (size_t i = 0; i < len; i++) {
    n += docspecs_count_sections(list[i]->children, list[i]->children_len);
  }
  return n;
}

static void docspecs_collect_sections(DocSpecsSection *const *list, size_t len,
                                      const DocSpecsSection **out, size_t *at) {
  for (size_t i = 0; i < len; i++) {
    out[(*at)++] = list[i];
    docspecs_collect_sections(list[i]->children, list[i]->children_len, out, at);
  }
}

const DocSpecsSection **docspecs_document_all_sections(const DocSpecsDocument *doc,
                                                       size_t *out_len) {
  size_t n = docspecs_count_sections(doc->sections, doc->sections_len);
  *out_len = n;
  if (n == 0) {
    return NULL;
  }
  const DocSpecsSection **out =
      (const DocSpecsSection **)malloc(n * sizeof(*out));
  size_t at = 0;
  docspecs_collect_sections(doc->sections, doc->sections_len, out, &at);
  return out;
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

/* ---- section body replacement -------------------------------------------- */

/* strings.Split(text, "\n") into `out` (initialised by the caller). */
static void split_lines(const char *text, SomStrList *out) {
  const char *cursor = text;
  for (;;) {
    const char *nl = strchr(cursor, '\n');
    size_t len = nl != NULL ? (size_t)(nl - cursor) : strlen(cursor);
    som_strlist_push(out, som_strdup_n(cursor, len));
    if (nl == NULL) {
      return;
    }
    cursor = nl + 1;
  }
}

/* Reports whether `s` is empty or whitespace only (Dart `trim().isEmpty`). */
static int is_blank(const char *s) {
  for (; *s != '\0'; s++) {
    if (!is_ascii_ws(*s)) {
      return 0;
    }
  }
  return 1;
}

/* Depth-first, pre-order collection of the sections whose id is `id`. */
static void collect_sections(DocSpecsSection **list, size_t len, const char *id,
                             const DocSpecsSection ***out, size_t *out_len,
                             size_t *out_cap) {
  for (size_t i = 0; i < len; i++) {
    const DocSpecsSection *s = list[i];
    if (strcmp(s->id, id) == 0) {
      if (*out_len == *out_cap) {
        *out_cap = *out_cap == 0 ? 4 : *out_cap * 2;
        *out = realloc((void *)*out, *out_cap * sizeof(DocSpecsSection *));
      }
      (*out)[(*out_len)++] = s;
    }
    collect_sections(s->children, s->children_len, id, out, out_len, out_cap);
  }
}

int docspecs_replace_section_body(const char *text, const char *section_id,
                                  const char *body, char **out,
                                  char **error_out) {
  *out = NULL;
  if (error_out != NULL) {
    *error_out = NULL;
  }
  char *err = NULL;
  DocSpecsDocument *doc = docspecs_parse_document(text);
  const DocSpecsSection **matches = NULL;
  size_t matches_len = 0;
  size_t matches_cap = 0;
  collect_sections(doc->sections, doc->sections_len, section_id, &matches,
                   &matches_len, &matches_cap);
  SomStrList body_lines;
  som_strlist_init(&body_lines);

  if (matches_len == 0) {
    err = vcat("sectionId \"", section_id, "\" names no section", NULL);
    goto done;
  }
  if (matches_len > 1) {
    SomBuf lb;
    som_buf_init(&lb);
    for (size_t i = 0; i < matches_len; i++) {
      if (i > 0) {
        som_buf_puts(&lb, ", ");
      }
      char *n = dv_itoa(matches[i]->line);
      som_buf_puts(&lb, n);
      free(n);
    }
    char *lines_s = som_buf_take(&lb);
    char *count = dv_itoa((long long)matches_len);
    err = vcat("sectionId \"", section_id, "\" names ", count,
               " sections (lines ", lines_s, ")", NULL);
    free(count);
    free(lines_s);
    goto done;
  }

  split_lines(body, &body_lines);
  while (body_lines.len > 0 && is_blank(body_lines.items[0])) {
    som_strlist_remove_at(&body_lines, 0);
  }
  while (body_lines.len > 0 && is_blank(body_lines.items[body_lines.len - 1])) {
    som_strlist_remove_at(&body_lines, body_lines.len - 1);
  }
  {
    SpecMarkdownFenceTracker fence;
    spec_markdown_fence_init(&fence);
    for (size_t i = 0; i < body_lines.len; i++) {
      const char *line = body_lines.items[i];
      if (!spec_markdown_fence_in_fence(&fence)) {
        char *trimmed = strip_trailing_ws(line);
        int level = 0;
        char *rest = NULL;
        int heading = match_heading_line(trimmed, &level, &rest);
        free(rest);
        rest = NULL;
        if (!heading) heading = match_styled_div_heading(trimmed, &level, &rest);
        free(rest);
        free(trimmed);
        if (heading) {
          err = vcat("body contains a heading outside a fenced block: \"", line,
                     "\"", NULL);
          goto done;
        }
      }
      spec_markdown_fence_feed(&fence, line);
    }
    if (spec_markdown_fence_in_fence(&fence)) {
      err = som_strdup("body leaves a fenced block open");
      goto done;
    }
  }

  {
    const DocSpecsSection *section = matches[0];
    SomStrList lines;
    som_strlist_init(&lines);
    split_lines(text, &lines);
    size_t start = (size_t)section->line; /* 0-based first body line */
    size_t end = start + section->body_lines.len;
    if (start > lines.len) {
      start = lines.len;
    }
    if (end > lines.len) {
      end = lines.len;
    }
    SomStrList result;
    som_strlist_init(&result);
    for (size_t i = 0; i < start; i++) {
      som_strlist_push_copy(&result, lines.items[i]);
    }
    som_strlist_push_copy(&result, "");
    if (body_lines.len > 0) {
      for (size_t i = 0; i < body_lines.len; i++) {
        som_strlist_push_copy(&result, body_lines.items[i]);
      }
      som_strlist_push_copy(&result, "");
    }
    for (size_t i = end; i < lines.len; i++) {
      som_strlist_push_copy(&result, lines.items[i]);
    }
    *out = som_strlist_join(&result, "\n");
    som_strlist_free(&result);
    som_strlist_free(&lines);
  }

done:
  som_strlist_free(&body_lines);
  free((void *)matches);
  docspecs_document_free(doc);
  if (err != NULL) {
    if (error_out != NULL) {
      *error_out = err;
    } else {
      free(err);
    }
    return 1;
  }
  return 0;
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

/* load_document: loads the `document:` block. Returns 0 (with an owned
 * message to `*err` when non-NULL) when a section's `position` is not
 * `relative` / `any`; the slots loaded so far stay in `s` for
 * docspecs_schema_free. */
static int load_document(DocSpecsSchema *s, const YamlValue *node,
                         char **err) {
  if (node == NULL || node->type != YAML_MAP) {
    return 1;
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
        char *position = som_strdup(DOCSPECS_POSITION_RELATIVE);
        if (s_raw != NULL && s_raw->type == YAML_MAP) {
          if (yaml_get(s_raw, "section-type") != NULL) {
            free(section_type);
            section_type = yaml_scalar_string(yaml_get(s_raw, "section-type"));
          }
          optional = dv_is_true(yaml_get(s_raw, "optional"));
          const YamlValue *p = yaml_get(s_raw, "position");
          if (p != NULL && p->type != YAML_NULL) {
            free(position);
            position = yaml_scalar_string(p);
            if (strcmp(position, DOCSPECS_POSITION_RELATIVE) != 0 &&
                strcmp(position, DOCSPECS_POSITION_ANY) != 0) {
              if (err != NULL) {
                *err = vcat("document section \"", s_key, "\": position \"",
                            position, "\" is not one of relative, any", NULL);
              }
              free(position);
              free(section_type);
              return 0;
            }
          }
        }
        s->document_sections = realloc(
            s->document_sections,
            (s->document_sections_len + 1) * sizeof(DocSpecsDocumentSection));
        DocSpecsDocumentSection *ds =
            &s->document_sections[s->document_sections_len++];
        ds->key = som_strdup(s_key);
        ds->section_type = section_type;
        ds->optional = optional;
        ds->position = position;
      }
    } else if (strcmp(k, "name") != 0 && strcmp(k, "description") != 0) {
      schema_warn(s, vcat("unsupported document key \"", k, "\" ignored", NULL));
    }
  }
  return 1;
}

int docspecs_document_section_any_position(const DocSpecsDocumentSection *ds) {
  return ds->position != NULL &&
         strcmp(ds->position, DOCSPECS_POSITION_ANY) == 0;
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
      if (!load_document(schema, v, err)) {
        yaml_value_free(data);
        docspecs_schema_free(schema);
        return 0;
      }
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
    free(s->document_sections[i].position);
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
  return docspecs_validator_new_with(schema, 0);
}

DocSpecsValidator docspecs_validator_new_with(const DocSpecsSchema *schema,
                                              int tom_specs) {
  DocSpecsValidator v;
  v.schema = schema;
  v.tom_specs = tom_specs;
  return v;
}

void docspecs_validator_validate_markdown(const DocSpecsValidator *val,
                                          const char *markdown,
                                          DocSpecsViolationList *out) {
  DocSpecsDocument *doc = docspecs_parse_document(markdown);
  docspecs_validator_validate(val, doc, out);
  docspecs_document_free(doc);
}

/* ---- the walk's sections (DocSpecs specification, List Bodies) ----------- */

/* A form value given by a table row or a list body. */
typedef struct {
  char *label; /* owned; "" for a virtual body line without a label */
  char *value; /* owned */
  int line;
} DvValue;

/* A section as the validator walks it: a parsed DocSpecsSection, or a virtual
 * one rebuilt from a list body or a section table. The body is a copy, so
 * blanking a table or div never touches the parsed document. */
typedef struct DvNode DvNode;
struct DvNode {
  char *id;    /* owned; "" when none */
  int line;    /* the heading's line, or the row's / div's of a virtual one */
  SomStrList body; /* the own body lines; a list body / table read is blank */
  const DocSpecsSectionType *type; /* a virtual list item's schema type */
  DvNode **children;
  size_t children_len, children_cap;
  DvValue *values; /* form values given by a table row or a list body */
  size_t values_len, values_cap;
};

static DvNode *dv_node_virtual(const char *id, int line,
                               const DocSpecsSectionType *type) {
  DvNode *n = calloc(1, sizeof(DvNode));
  n->id = som_strdup(id != NULL ? id : "");
  n->line = line;
  som_strlist_init(&n->body);
  n->type = type;
  return n;
}

static void dv_node_add_child(DvNode *parent, DvNode *child) {
  if (parent->children_len == parent->children_cap) {
    parent->children_cap = parent->children_cap ? parent->children_cap * 2 : 4;
    parent->children =
        realloc(parent->children, parent->children_cap * sizeof(DvNode *));
  }
  parent->children[parent->children_len++] = child;
}

static void dv_node_add_value(DvNode *n, const char *label, char *value,
                              int line) {
  if (n->values_len == n->values_cap) {
    n->values_cap = n->values_cap ? n->values_cap * 2 : 4;
    n->values = realloc(n->values, n->values_cap * sizeof(DvValue));
  }
  n->values[n->values_len].label = som_strdup(label);
  n->values[n->values_len].value = value;
  n->values[n->values_len].line = line;
  n->values_len++;
}

/* The walk's view of a parsed section and its subtree. */
static DvNode *dv_node_of(const DocSpecsSection *s) {
  DvNode *n = dv_node_virtual(s->id, s->line, NULL);
  som_strlist_copy(&n->body, &s->body_lines);
  for (size_t i = 0; i < s->children_len; i++) {
    dv_node_add_child(n, dv_node_of(s->children[i]));
  }
  return n;
}

static void dv_node_free(DvNode *n) {
  if (n == NULL) return;
  free(n->id);
  som_strlist_free(&n->body);
  for (size_t i = 0; i < n->children_len; i++) dv_node_free(n->children[i]);
  free(n->children);
  for (size_t i = 0; i < n->values_len; i++) {
    free(n->values[i].label);
    free(n->values[i].value);
  }
  free(n->values);
  free(n);
}

/* The trimmed body text, after the virtual body lines of the values — the
 * text the same section has in the fields layout, where a section without a
 * form in the schema carries its values as `FieldName:` lines. Owned. */
static char *dv_node_text(const DvNode *n) {
  SomStrList lines;
  som_strlist_init(&lines);
  for (size_t i = 0; i < n->values_len; i++) {
    const DvValue *v = &n->values[i];
    som_strlist_push(&lines, v->label[0] == '\0'
                                 ? som_strdup(v->value)
                                 : vcat(v->label, ": ", v->value, NULL));
  }
  for (size_t i = 0; i < n->body.len; i++) {
    som_strlist_push_copy(&lines, n->body.items[i]);
  }
  size_t start = 0, end = lines.len;
  while (start < end) {
    char *t = trim_space(lines.items[start]);
    int blank = t[0] == '\0';
    free(t);
    if (!blank) break;
    start++;
  }
  while (end > start) {
    char *t = trim_space(lines.items[end - 1]);
    int blank = t[0] == '\0';
    free(t);
    if (!blank) break;
    end--;
  }
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = start; i < end; i++) {
    if (i > start) som_buf_putc(&b, '\n');
    som_buf_puts(&b, lines.items[i]);
  }
  som_strlist_free(&lines);
  return som_buf_take(&b);
}

/* ---- tables (DocSpecs specification, List Bodies) ------------------------ */

static void dv_skip_ws(const char *s, size_t *i) {
  while (s[*i] != '\0' && is_ascii_ws(s[*i])) (*i)++;
}

static int dv_ci_word(const char *s, size_t *i, const char *word) {
  size_t k = 0;
  while (word[k] != '\0') {
    if (to_lower_ascii(s[*i + k]) != to_lower_ascii(word[k])) return 0;
    k++;
  }
  *i += k;
  return 1;
}

static int dv_header_rest(const char *s, size_t i, int with_section) {
  dv_skip_ws(s, &i);
  if (with_section) {
    if (!dv_ci_word(s, &i, "Section")) return 0;
    dv_skip_ws(s, &i);
    if (s[i] != '|') return 0;
    i++;
    dv_skip_ws(s, &i);
  }
  if (!dv_ci_word(s, &i, "TomSpecField")) return 0;
  dv_skip_ws(s, &i);
  if (s[i] != '|') return 0;
  i++;
  dv_skip_ws(s, &i);
  if (!dv_ci_word(s, &i, "Value")) return 0;
  dv_skip_ws(s, &i);
  if (s[i] == '|') i++;
  dv_skip_ws(s, &i);
  return s[i] == '\0';
}

/* The layout table header `| TomSpecField | Value |` or
 * `| Section | TomSpecField | Value |` at column 0, any case (SOM §11.4,
 * §11.5); writes whether it names a `Section` column. */
static int dv_layout_header(const char *line, int *is_section) {
  if (line[0] != '|') return 0;
  if (dv_header_rest(line, 1, 1)) {
    *is_section = 1;
    return 1;
  }
  if (dv_header_rest(line, 1, 0)) {
    *is_section = 0;
    return 1;
  }
  return 0;
}

/* `^ {0,3}\|`. */
static int dv_table_line(const char *line) {
  size_t i = 0;
  while (i < 3 && line[i] == ' ') i++;
  return line[i] == '|';
}

/* `^:?-+:?$`. */
static int dv_delimiter_cell(const char *c) {
  size_t n = strlen(c), i = 0;
  if (n > 0 && c[0] == ':') i++;
  size_t e = n;
  if (e > i && c[e - 1] == ':') e--;
  if (e <= i) return 0;
  for (size_t k = i; k < e; k++) {
    if (c[k] != '-') return 0;
  }
  return 1;
}

/* The cells of a table row: split on every `|` not preceded by a backslash,
 * the outer pipes dropped, each cell trimmed; `\|` stays in the cell. */
static void dv_row_cells(const char *line, SomStrList *out) {
  som_strlist_init(out);
  char *t = trim_space(line);
  size_t n = strlen(t), a = 0;
  if (n > 0 && t[0] == '|') a = 1;
  if (n > a && t[n - 1] == '|' && !(n >= 2 && t[n - 2] == '\\')) n--;
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = a; i < n; i++) {
    if (t[i] == '\\' && i + 1 < n && t[i + 1] == '|') {
      som_buf_puts(&b, "\\|");
      i++;
    } else if (t[i] == '|') {
      char *cell = som_buf_take(&b);
      som_strlist_push(out, trim_space(cell));
      free(cell);
    } else {
      som_buf_putc(&b, t[i]);
    }
  }
  char *cell = som_buf_take(&b);
  som_strlist_push(out, trim_space(cell));
  free(cell);
  free(t);
}

typedef struct {
  size_t index;
  SomStrList cells;
} DvRow;

typedef struct {
  SomStrList header;
  DvRow *rows;
  size_t rows_len;
  size_t end;
} DvTable;

static void dv_table_free(DvTable *t) {
  som_strlist_free(&t->header);
  for (size_t i = 0; i < t->rows_len; i++) som_strlist_free(&t->rows[i].cells);
  free(t->rows);
}

/* Reads the table whose header is `lines[start]`; line k of `lines` is source
 * line `line_base + k`. A missing or mismatched delimiter row is a
 * malformedBlock at the header and yields no rows; a row of another cell
 * count is a malformedBlock at that row and is left out. */
static void dv_read_table(char *const *lines, size_t len, size_t start,
                          int line_base, const char *section_id,
                          DocSpecsViolationList *v, DvTable *out) {
  size_t end = start + 1;
  while (end < len && dv_table_line(lines[end])) end++;
  out->end = end;
  out->rows = NULL;
  out->rows_len = 0;
  dv_row_cells(lines[start], &out->header);
  int ok = 0;
  size_t dlen = 0;
  if (start + 1 < end) {
    SomStrList d;
    dv_row_cells(lines[start + 1], &d);
    ok = 1;
    for (size_t i = 0; i < d.len; i++) {
      if (!dv_delimiter_cell(d.items[i])) ok = 0;
    }
    dlen = d.len;
    som_strlist_free(&d);
  }
  if (!ok || dlen != out->header.len) {
    dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, line_base + (int)start,
            som_strdup(ok ? "table whose delimiter row does not match its header"
                          : "table without its delimiter row"),
            section_id, "");
    return;
  }
  if (end > start + 2) out->rows = calloc(end - start - 2, sizeof(DvRow));
  for (size_t i = start + 2; i < end; i++) {
    SomStrList cells;
    dv_row_cells(lines[i], &cells);
    if (cells.len != out->header.len) {
      char *got = dv_itoa((long long)cells.len);
      char *want = dv_itoa((long long)out->header.len);
      dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, line_base + (int)i,
              vcat("table row with ", got, " cells, the header has ", want,
                   NULL),
              section_id, "");
      free(got);
      free(want);
      som_strlist_free(&cells);
      continue;
    }
    out->rows[out->rows_len].index = i;
    out->rows[out->rows_len].cells = cells;
    out->rows_len++;
  }
}

static char *dv_replace_all(const char *s, const char *from, const char *to) {
  SomBuf b;
  som_buf_init(&b);
  size_t fl = strlen(from);
  const char *q = s, *hit;
  while ((hit = strstr(q, from)) != NULL) {
    som_buf_putn(&b, q, (size_t)(hit - q));
    som_buf_puts(&b, to);
    q = hit + fl;
  }
  som_buf_puts(&b, q);
  return som_buf_take(&b);
}

/* `\[[^\]]+\]\(<close_set>*\)` at s[*i]; `no_ws` adds `\s` to the excluded
 * characters of the target. Writes the text range and advances. */
static int dv_link_at(const char *s, size_t *i, int no_ws, size_t *ta,
                      size_t *tb) {
  size_t k = *i;
  if (s[k] != '[') return 0;
  size_t a = ++k;
  while (s[k] != '\0' && s[k] != ']') k++;
  if (s[k] != ']' || k == a) return 0;
  size_t b = k++;
  if (s[k] != '(') return 0;
  k++;
  while (s[k] != '\0' && s[k] != ')' && !(no_ws && is_ascii_ws(s[k]))) k++;
  if (s[k] != ')') return 0;
  *ta = a;
  *tb = b;
  *i = k + 1;
  return 1;
}

/* A value cell's value: `\|` unescaped, a cell of links read as their texts. */
static char *dv_cell_value(const char *cell) {
  char *text = dv_replace_all(cell, "\\|", "|");
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0, ta, tb;
  for (;;) {
    if (!dv_link_at(text, &i, 0, &ta, &tb)) break;
    if (b.len > 0) som_buf_puts(&b, ", ");
    som_buf_putn(&b, text + ta, tb - ta);
    if (text[i] == '\0') {
      free(text);
      return som_buf_take(&b);
    }
    if (text[i] != ',' || text[i + 1] != ' ') break;
    i += 2;
  }
  som_buf_free(&b);
  return text;
}

/* The range [a, b) trimmed. Owned. */
static char *dv_trimmed_range(const char *a, const char *b) {
  while (a < b && is_ascii_ws(*a)) a++;
  while (b > a && is_ascii_ws(b[-1])) b--;
  return som_strdup_n(a, (size_t)(b - a));
}

/* An `Id` or `Section` cell with its own anchors removed (Section Anchors):
 * in a `<LIST> / <ITEM>` cell each part's anchor, and one before the whole
 * cell naming its item; a link read as its text first (SOM §11.5). Owned. */
static char *dv_cell_id(const char *raw) {
  /* `[X](target)` with no whitespace in the target → X, everywhere */
  SomBuf lb;
  som_buf_init(&lb);
  for (size_t i = 0; raw[i] != '\0';) {
    size_t k = i, ta, tb;
    if (dv_link_at(raw, &k, 1, &ta, &tb)) {
      som_buf_putn(&lb, raw + ta, tb - ta);
      i = k;
    } else {
      som_buf_putc(&lb, raw[i]);
      i++;
    }
  }
  char *cell = som_buf_take(&lb);
  SomBuf out;
  som_buf_init(&out);
  size_t pos = 0;
  for (size_t i = 0; cell[i] != '\0';) {
    const char *at = cell + i;
    const char *q = strncmp(at, "<a id=\"", 7) == 0 ? strchr(at + 7, '"') : NULL;
    if (q == NULL || strncmp(q, "\"></a>", 6) != 0) {
      i++;
      continue;
    }
    size_t start = i;
    const char *e = q + 6;
    while (*e != '\0' && is_ascii_ws(*e)) e++;
    size_t end = (size_t)(e - cell);
    char *id = som_strdup_n(at + 7, (size_t)(q - at - 7));
    /* rest split on separators: the first and the last part */
    const char *rest = cell + end;
    const char *slash = strchr(rest, '/');
    char *first = dv_trimmed_range(rest, slash != NULL ? slash : rest + strlen(rest));
    const char *last_slash = strrchr(rest, '/');
    char *last = dv_trimmed_range(last_slash != NULL ? last_slash + 1 : rest,
                                  rest + strlen(rest));
    int own = own_anchor(id, first) ||
              (start == 0 && own_anchor(id, last));
    som_buf_putn(&out, cell + pos, start - pos);
    if (!own) som_buf_putn(&out, cell + start, end - start);
    pos = end;
    i = end;
    free(id);
    free(first);
    free(last);
  }
  som_buf_puts(&out, cell + pos);
  free(cell);
  return som_buf_take(&out);
}

/* The section type named `name`, or NULL. */
static const DocSpecsSectionType *dv_type_named(const DocSpecsSchema *s,
                                                const char *name) {
  return docspecs_schema_section_type_by_name(s, name);
}

/* Whether a type is allowed where a section table's child stands: a slot of
 * the document (`parent` NULL) or a subsection of `parent`. */
static int dv_allowed(const DocSpecsSchema *schema,
                      const DocSpecsSectionType *parent,
                      const DocSpecsSectionType *t) {
  if (parent != NULL) return docspecs_section_type_subsection(parent, t->name) != NULL;
  for (size_t i = 0; i < schema->document_sections_len; i++) {
    if (strcmp(schema->document_sections[i].section_type, t->name) == 0) return 1;
  }
  return 0;
}

/* The child of `parent` with `id`, else a virtual one created when the id
 * resolves to a type allowed there; NULL otherwise. */
static DvNode *dv_table_child(const DocSpecsSchema *schema, DvNode *parent,
                              const char *id, const DocSpecsSectionType *allowed,
                              int slots, int line) {
  for (size_t i = 0; i < parent->children_len; i++) {
    if (strcmp(parent->children[i]->id, id) == 0) return parent->children[i];
  }
  const DocSpecsSectionType *t = docspecs_schema_resolve_section_type(schema, id);
  if (t == NULL || !dv_allowed(schema, slots ? NULL : allowed, t)) return NULL;
  DvNode *created = dv_node_virtual(id, line, NULL);
  dv_node_add_child(parent, created);
  return created;
}

/* The child a section-table `Section` cell names under `node`: a child by its
 * id, or `<LIST> / <ITEM>` — an item of a child list. `allowed` NULL means
 * the document's slots. */
static DvNode *dv_section_table_target(const DocSpecsSchema *schema,
                                       DvNode *node, const char *cell,
                                       const DocSpecsSectionType *allowed,
                                       int line) {
  SomStrList parts;
  som_strlist_init(&parts);
  const char *q = cell;
  for (;;) {
    const char *slash = strchr(q, '/');
    const char *e = slash != NULL ? slash : q + strlen(q);
    const char *a = q;
    if (parts.len > 0) {
      while (a < e && is_ascii_ws(*a)) a++;
    }
    const char *b = e;
    if (slash != NULL) {
      while (b > a && is_ascii_ws(b[-1])) b--;
    }
    som_strlist_push(&parts, som_strdup_n(a, (size_t)(b - a)));
    if (slash == NULL) break;
    q = slash + 1;
  }
  DvNode *result = NULL;
  if (parts.len <= 2) {
    DvNode *first = dv_table_child(schema, node, parts.items[0], allowed,
                                   allowed == NULL, line);
    if (parts.len == 1 || first == NULL) {
      result = first;
    } else {
      const DocSpecsSectionType *list_type =
          first->type != NULL
              ? first->type
              : docspecs_schema_resolve_section_type(schema, parts.items[0]);
      if (list_type != NULL) {
        result = dv_table_child(schema, first, parts.items[1], list_type, 0, line);
      }
    }
  }
  som_strlist_free(&parts);
  return result;
}

/* Reads every section table of `node`'s body: each row's `Section` cell names
 * a child (an empty cell the row above's) and its `TomSpecField` / `Value`
 * cells become that child's form values; the table's lines are blanked. */
static void dv_expand_section_tables(const DocSpecsValidator *val, DvNode *node,
                                     const DocSpecsSectionType *allowed,
                                     DocSpecsViolationList *v) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  int base = node->line + 1;
  for (size_t i = 0; i < node->body.len; i++) {
    const char *line = node->body.items[i];
    int is_section = 0;
    if (spec_markdown_fence_in_fence(&fence) ||
        !dv_layout_header(line, &is_section) || !is_section) {
      spec_markdown_fence_feed(&fence, line);
      continue;
    }
    DvTable table;
    dv_read_table(node->body.items, node->body.len, i, base, node->id, v,
                  &table);
    DvNode *target = NULL;
    int skip = 0;
    for (size_t r = 0; r < table.rows_len; r++) {
      const DvRow *row = &table.rows[r];
      int line_no = base + (int)row->index;
      char *cell = dv_cell_id(row->cells.items[0]);
      if (cell[0] != '\0') {
        target = dv_section_table_target(val->schema, node, cell, allowed,
                                         line_no);
        skip = target == NULL;
        if (target == NULL) {
          dv_push(v, DOCSPECS_RULE_UNKNOWN_SECTION, line_no,
                  vcat("section-table row names no child section of \"",
                       node->id, "\"", NULL),
                  cell, "");
          free(cell);
          continue;
        }
      } else if (skip) {
        free(cell);
        continue;
      } else if (target == NULL) {
        dv_push(v, DOCSPECS_RULE_UNKNOWN_SECTION, line_no,
                som_strdup("section-table row names no section"), node->id, "");
        free(cell);
        continue;
      }
      free(cell);
      dv_node_add_value(target, row->cells.items[1],
                        dv_cell_value(row->cells.items[2]), line_no);
    }
    for (size_t k = i; k < table.end; k++) {
      free(node->body.items[k]);
      node->body.items[k] = som_strdup("");
    }
    i = table.end - 1;
    dv_table_free(&table);
  }
}

/* `^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$`. */
static int dv_list_div_open(const char *line, const char **kind) {
  size_t i = 0;
  while (line[i] == ':') i++;
  if (i < 3) return 0;
  dv_skip_ws(line, &i);
  int braced = line[i] == '{' && line[i + 1] == '.';
  if (braced) i += 2;
  if (strncmp(line + i, "refs", 4) == 0) {
    *kind = "refs";
    i += 4;
  } else if (strncmp(line + i, "records", 7) == 0) {
    *kind = "records";
    i += 7;
  } else {
    return 0;
  }
  if (braced) {
    if (line[i] != '}') return 0;
    i++;
  }
  dv_skip_ws(line, &i);
  return line[i] == '\0';
}

/* `^:{3,}\s*$`. */
static int dv_div_close(const char *line) {
  size_t i = 0;
  while (line[i] == ':') i++;
  if (i < 3) return 0;
  dv_skip_ws(line, &i);
  return line[i] == '\0';
}

/* The form an item of `item_type` holds its values in: the type's own form,
 * else the form of its one subsection type that has one (`*child_type`).
 * With `one_field`, only forms of exactly one field count. */
static const DocSpecsFormType *dv_item_form(const DocSpecsSchema *schema,
                                            const DocSpecsSectionType *item_type,
                                            int one_field,
                                            const DocSpecsSectionType **child_type) {
  *child_type = NULL;
  const DocSpecsFormType *own =
      item_type->format[0] != '\0'
          ? docspecs_schema_form_type(schema, item_type->format)
          : NULL;
  if (own != NULL && (!one_field || own->fields_len == 1)) return own;
  const DocSpecsFormType *found = NULL;
  const DocSpecsSectionType *found_sub = NULL;
  size_t count = 0;
  for (size_t i = 0; i < item_type->subsection_types_len; i++) {
    const DocSpecsSectionType *sub =
        dv_type_named(schema, item_type->subsection_types[i].name);
    const DocSpecsFormType *f =
        sub != NULL && sub->format[0] != '\0'
            ? docspecs_schema_form_type(schema, sub->format)
            : NULL;
    if (f != NULL && (!one_field || f->fields_len == 1)) {
      count++;
      found = f;
      found_sub = sub;
    }
  }
  if (count != 1) return NULL;
  *child_type = found_sub;
  return found;
}

/* A virtual item of `item_type` added to `list`; returns the section its form
 * values go to — the item, or its virtual child of `child_type` (id: the
 * child type's name upper-cased). */
static DvNode *dv_add_item(DvNode *list, const DocSpecsSectionType *item_type,
                           const DocSpecsSectionType *child_type,
                           const char *id, int line) {
  DvNode *item = dv_node_virtual(id, line, item_type);
  dv_node_add_child(list, item);
  if (child_type == NULL) return item;
  char *cid = upper_ascii(child_type->name);
  DvNode *child = dv_node_virtual(cid, line, child_type);
  free(cid);
  dv_node_add_child(item, child);
  return child;
}

/* A `refs` div: ids split on commas and whitespace, a link counting as its
 * text; item <n> gets the positional id (the container's id with `-LST`
 * replaced by `-<n>`, else `<id>-<n>`) and the value of the item's one-field
 * form (or a virtual body line). */
static void dv_refs_items(const DocSpecsSchema *schema, DvNode *node,
                          const DocSpecsSectionType *item_type,
                          char *const *inner, size_t inner_len, int at) {
  const DocSpecsSectionType *child_type = NULL;
  const DocSpecsFormType *form = dv_item_form(schema, item_type, 1, &child_type);
  SomBuf joined;
  som_buf_init(&joined);
  for (size_t k = 0; k < inner_len; k++) {
    if (k > 0) som_buf_putc(&joined, ' ');
    som_buf_puts(&joined, inner[k]);
  }
  char *all = som_buf_take(&joined);
  SomStrList ids;
  som_strlist_init(&ids);
  for (size_t i = 0; all[i] != '\0';) {
    while (all[i] != '\0' && (all[i] == ',' || is_ascii_ws(all[i]))) i++;
    size_t a = i;
    while (all[i] != '\0' && all[i] != ',' && !is_ascii_ws(all[i])) i++;
    if (i == a) continue;
    char *token = som_strdup_n(all + a, i - a);
    char *id = NULL;
    for (size_t k = 0; token[k] != '\0' && id == NULL; k++) {
      size_t at_k = k, ta, tb;
      if (dv_link_at(token, &at_k, 0, &ta, &tb)) id = som_strdup_n(token + ta, tb - ta);
    }
    som_strlist_push(&ids, id != NULL ? id : som_strdup(token));
    free(token);
  }
  free(all);
  size_t cl = strlen(node->id);
  char *stem = cl >= 4 && strcmp(node->id + cl - 4, "-LST") == 0
                   ? som_strdup_n(node->id, cl - 4)
                   : som_strdup(node->id);
  for (size_t n = 1; n <= ids.len; n++) {
    char *num = dv_itoa((long long)n);
    char *id = vcat(stem, "-", num, NULL);
    DvNode *holder = dv_add_item(node, item_type, form != NULL ? child_type : NULL,
                                 id, at);
    dv_node_add_value(holder, form != NULL ? form->fields[0].name : "",
                      som_strdup(ids.items[n - 1]), at);
    free(id);
    free(num);
  }
  free(stem);
  som_strlist_free(&ids);
}

/* A `records` div: one table, `Id` first, `Title` optionally second, then
 * field names of the item's form; each row one virtual item in row order. */
static void dv_record_items(const DocSpecsSchema *schema, DvNode *node,
                            const DocSpecsSectionType *item_type,
                            char *const *inner, size_t inner_len, int at,
                            DocSpecsViolationList *v) {
  int base = at + 1;
  size_t start = 0;
  while (start < inner_len) {
    char *t = trim_space(inner[start]);
    int empty = t[0] == '\0';
    free(t);
    if (!empty) break;
    start++;
  }
  if (start >= inner_len || !dv_table_line(inner[start])) {
    dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, at,
            som_strdup("a records div holding no table"), node->id, "");
    return;
  }
  SomStrList header;
  dv_row_cells(inner[start], &header);
  if (strcmp(header.items[0], "Id") != 0) {
    dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, at,
            som_strdup("a records table whose first column is not Id"),
            node->id, "");
    som_strlist_free(&header);
    return;
  }
  /* The item type's own form decides the columns; an item type the schema
   * gives no form of its own takes its columns as virtual body lines
   * unchecked. A record's cells are the item's own body lines (DocSpecs
   * specification, *The record table*): unlike a `refs` reference they never
   * go to a child's form. */
  const DocSpecsSectionType *child_type = NULL;
  const DocSpecsFormType *form =
      item_type->format[0] != '\0'
          ? docspecs_schema_form_type(schema, item_type->format)
          : NULL;
  int with_title = header.len > 1 && strcmp(header.items[1], "Title") == 0;
  size_t first_column = with_title ? 2 : 1;
  SomStrList columns;
  som_strlist_init(&columns);
  for (size_t c = first_column; c < header.len; c++) {
    const char *label = header.items[c];
    const char *name = NULL;
    if (form == NULL) {
      name = label;
    } else {
      char *lower = lower_ascii(label);
      for (size_t f = 0; f < form->fields_len && name == NULL; f++) {
        char *fl = lower_ascii(form->fields[f].name);
        if (strcmp(fl, lower) == 0) name = form->fields[f].name;
        free(fl);
      }
      free(lower);
    }
    if (name == NULL) {
      dv_push(v, DOCSPECS_RULE_UNKNOWN_FIELD, base + (int)start,
              vcat("records column \"", label, "\" names no field of the items",
                   NULL),
              node->id, "");
      som_strlist_free(&columns);
      som_strlist_free(&header);
      return;
    }
    som_strlist_push_copy(&columns, name);
  }
  som_strlist_free(&header);
  DvTable table;
  dv_read_table(inner, inner_len, start, base, node->id, v, &table);
  for (size_t r = 0; r < table.rows_len; r++) {
    const DvRow *row = &table.rows[r];
    int line_no = base + (int)row->index;
    char *id = dv_cell_id(row->cells.items[0]);
    DvNode *holder = dv_add_item(node, item_type, form != NULL ? child_type : NULL,
                                 id, line_no);
    free(id);
    for (size_t c = 0; c < columns.len; c++) {
      char *value = dv_cell_value(row->cells.items[first_column + c]);
      if (value[0] == '\0') {
        free(value);
        continue;
      }
      dv_node_add_value(holder, columns.items[c], value, line_no);
    }
  }
  dv_table_free(&table);
  som_strlist_free(&columns);
}

/* A list container's body: one `refs` div or one `records` div stands for
 * its items when the container has no item heading; the items become virtual
 * sections of the container's one subsection type, the div's lines blank. */
static void dv_expand_list_body(const DocSpecsValidator *val, DvNode *node,
                                const DocSpecsSectionType *type,
                                DocSpecsViolationList *v) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  for (size_t i = 0; i < node->body.len; i++) {
    const char *line = node->body.items[i];
    const char *kind = NULL;
    if (spec_markdown_fence_in_fence(&fence) || !dv_list_div_open(line, &kind)) {
      spec_markdown_fence_feed(&fence, line);
      continue;
    }
    int at = node->line + 1 + (int)i;
    size_t close = node->body.len;
    for (size_t k = i + 1; k < node->body.len; k++) {
      if (dv_div_close(node->body.items[k])) {
        close = k;
        break;
      }
    }
    if (close == node->body.len) {
      dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, at,
              vcat("unclosed ", kind, " fence", NULL), node->id, "");
      return; /* its lines stay text */
    }
    int beside_text = 0;
    for (size_t k = 0; k < node->body.len; k++) {
      if (k >= i && k <= close) continue;
      char *t = trim_space(node->body.items[k]);
      if (t[0] != '\0') beside_text = 1;
      free(t);
    }
    int has_items = node->children_len > 0;
    SomStrList inner;
    som_strlist_init(&inner);
    for (size_t k = i + 1; k < close; k++) {
      som_strlist_push_copy(&inner, node->body.items[k]);
    }
    for (size_t k = i; k <= close; k++) {
      free(node->body.items[k]);
      node->body.items[k] = som_strdup("");
    }
    if (beside_text || has_items) {
      dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, at,
              vcat("a ", kind, " div beside ",
                   has_items ? "item headings" : "other text",
                   " in a list container", NULL),
              node->id, "");
      som_strlist_free(&inner);
      return;
    }
    const DocSpecsSectionType *item_type =
        type->subsection_types_len == 1
            ? dv_type_named(val->schema, type->subsection_types[0].name)
            : NULL;
    if (item_type == NULL) {
      dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, at,
              vcat("a ", kind, " div in a section that is not a list container",
                   NULL),
              node->id, "");
      som_strlist_free(&inner);
      return;
    }
    if (strcmp(kind, "refs") == 0) {
      dv_refs_items(val->schema, node, item_type, inner.items, inner.len, at);
    } else {
      dv_record_items(val->schema, node, item_type, inner.items, inner.len, at,
                      v);
    }
    som_strlist_free(&inner);
    return;
  }
}

/* resolveChild: resolves a child section's type; on no-match pushes an
 * unknownSection violation. Returns the type (may be NULL). */
static const DocSpecsSectionType *resolve_child(const DocSpecsValidator *val,
                                                DvNode *section,
                                                DocSpecsViolationList *v) {
  if (section->type != NULL) {
    return section->type; /* a virtual list item: the schema's type */
  }
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
                             DvNode *section,
                             const DocSpecsSectionType *t,
                             DocSpecsViolationList *v);

static void validate_text(const DocSpecsValidator *val,
                          DvNode *section,
                          const DocSpecsSectionType *t,
                          DocSpecsViolationList *v) {
  if (t->format[0] != '\0') {
    if (docspecs_schema_form_type(val->schema, t->format) != NULL) {
      return; /* form sections carry fields, not body text */
    }
  }
  char *text = dv_node_text(section);
  if (t->text_required && text[0] == '\0') {
    dv_push(v, DOCSPECS_RULE_TEXT_REQUIRED, section->line,
            som_strdup("section requires body text but has none"),
            section->id, "");
    free(text);
    return;
  }
  /* A list body or section table already read is blank in the body, so a
   * container written with one counts as empty (`max-text-length: 0`). */
  if (text[0] == '\0') {
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

/* One form-field occurrence: a `Field:` paragraph, a form-table row or a
 * value a section table / list body gave. */
typedef struct {
  char *label;
  char *value;
  int line;
  int from_label;
  size_t order;
} DvOccurrence;

static int dv_occurrence_cmp(const void *pa, const void *pb) {
  const DvOccurrence *a = pa, *b = pb;
  if (a->line != b->line) return a->line < b->line ? -1 : 1;
  return a->order < b->order ? -1 : (a->order > b->order ? 1 : 0);
}

/* Parses the section body in the DocSpecs plain-text form format
 * (`FieldName: value`, case-insensitive labels, continuation lines) and its
 * form tables (`TomSpecField | Value`), takes the values a section table or
 * list body gave the section, and checks required fields + field
 * pattern-checks. A field given twice keeps its first occurrence and reports
 * the second (malformedBlock): a `Field:` label counts as given even with an
 * empty value, a row only with a value. A row naming no field is
 * unknownField. */
static void validate_form(const DocSpecsValidator *val, DvNode *section,
                          const DocSpecsFormType *form,
                          DocSpecsViolationList *v) {
  (void)val;
  size_t nf = form->fields_len;
  DvOccurrence *occ = NULL;
  size_t occ_len = 0, occ_cap = 0;
#define OCC_PUSH(lbl, val_owned, ln, fl)                                       \
  do {                                                                         \
    if (occ_len == occ_cap) {                                                  \
      occ_cap = occ_cap ? occ_cap * 2 : 8;                                     \
      occ = realloc(occ, occ_cap * sizeof(DvOccurrence));                      \
    }                                                                          \
    occ[occ_len].label = som_strdup(lbl);                                      \
    occ[occ_len].value = (val_owned);                                          \
    occ[occ_len].line = (ln);                                                  \
    occ[occ_len].from_label = (fl);                                            \
    occ[occ_len].order = occ_len;                                              \
    occ_len++;                                                                 \
  } while (0)

  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  const SomStrList *body = &section->body;
  int base = section->line + 1;
  const char *current = NULL; /* the open field's name */
  int current_line = 0;
  SomBuf current_lines;
  som_buf_init(&current_lines);
#define FORM_FLUSH()                                                           \
  do {                                                                         \
    if (current != NULL) {                                                     \
      char *joined = som_buf_take(&current_lines);                             \
      OCC_PUSH(current, trim_space(joined), current_line, 1);                  \
      free(joined);                                                            \
      current = NULL;                                                          \
    }                                                                          \
    som_buf_free(&current_lines);                                              \
    som_buf_init(&current_lines);                                              \
  } while (0)

  for (size_t i = 0; i < body->len; i++) {
    const char *raw = body->items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      int is_section = 0;
      if (dv_layout_header(raw, &is_section) && !is_section) {
        /* A form table ends the open field; its rows are fields. */
        FORM_FLUSH();
        DvTable table;
        dv_read_table(body->items, body->len, i, base, section->id, v, &table);
        for (size_t r = 0; r < table.rows_len; r++) {
          OCC_PUSH(table.rows[r].cells.items[0],
                   dv_cell_value(table.rows[r].cells.items[1]),
                   base + (int)table.rows[r].index, 0);
        }
        i = table.end - 1;
        dv_table_free(&table);
        continue;
      }
      char *label = NULL;
      char *value = NULL;
      if (match_field_label(raw, &label, &value)) {
        char *label_lower = lower_ascii(label);
        const char *name = NULL;
        for (size_t fi = 0; fi < nf && name == NULL; fi++) {
          char *fn_lower = lower_ascii(form->fields[fi].name);
          if (strcmp(fn_lower, label_lower) == 0) name = form->fields[fi].name;
          free(fn_lower);
        }
        free(label_lower);
        if (name != NULL) {
          FORM_FLUSH();
          current = name;
          current_line = base + (int)i;
          som_buf_puts(&current_lines, value);
          free(label);
          free(value);
          spec_markdown_fence_feed(&fence, raw);
          continue;
        }
        free(label);
        free(value);
      }
    }
    if (current != NULL) {
      som_buf_putc(&current_lines, '\n');
      som_buf_puts(&current_lines, raw);
    }
    spec_markdown_fence_feed(&fence, raw);
  }
  FORM_FLUSH();
#undef FORM_FLUSH
  som_buf_free(&current_lines);
  for (size_t k = 0; k < section->values_len; k++) {
    OCC_PUSH(section->values[k].label, som_strdup(section->values[k].value),
             section->values[k].line, 0);
  }
#undef OCC_PUSH
  /* Source order decides which occurrence is the first; values from a
   * parent's section table stand above the section's own body. */
  if (occ_len > 1) qsort(occ, occ_len, sizeof(DvOccurrence), dv_occurrence_cmp);

  const char **values = calloc(nf ? nf : 1, sizeof(char *));
  int *field_line = calloc(nf ? nf : 1, sizeof(int));
  int *given = calloc(nf ? nf : 1, sizeof(int));
  for (size_t k = 0; k < occ_len; k++) {
    const DvOccurrence *o = &occ[k];
    char *lower = lower_ascii(o->label);
    int idx = -1;
    for (size_t fi = 0; fi < nf && idx < 0; fi++) {
      char *fl = lower_ascii(form->fields[fi].name);
      if (strcmp(fl, lower) == 0) idx = (int)fi;
      free(fl);
    }
    free(lower);
    if (idx < 0) {
      dv_push(v, DOCSPECS_RULE_UNKNOWN_FIELD, o->line,
              vcat("row \"", o->label, "\" names no field of \"", form->name,
                   "\"", NULL),
              section->id, "");
      continue;
    }
    if (!o->from_label && o->value[0] == '\0') continue;
    if (given[idx]) {
      dv_push(v, DOCSPECS_RULE_MALFORMED_BLOCK, o->line,
              vcat("field \"", form->fields[idx].name, "\" given twice", NULL),
              section->id, "");
      continue;
    }
    given[idx] = 1;
    field_line[idx] = o->line;
    if (o->value[0] != '\0') values[idx] = o->value;
  }

  for (size_t fi = 0; fi < nf; fi++) {
    const DocSpecsFormField *field = &form->fields[fi];
    const char *value = values[fi] != NULL ? values[fi] : "";
    if (field->required && value[0] == '\0') {
      dv_push(v, DOCSPECS_RULE_MISSING_REQUIRED_FIELD, section->line,
              vcat("required form field \"", field->name, "\" of \"",
                   form->name, "\" is missing", NULL),
              section->id, "");
      continue;
    }
    const DocSpecsPatternCheck *pc = field->pattern_check;
    if (pc != NULL && value[0] != '\0' &&
        !docspecs_pattern_check_matches(pc, value)) {
      int line = given[fi] ? field_line[fi] : section->line;
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
  }
  free((void *)values);
  free(field_line);
  free(given);
  for (size_t k = 0; k < occ_len; k++) {
    free(occ[k].label);
    free(occ[k].value);
  }
  free(occ);
}

static void validate_format(const DocSpecsValidator *val,
                            DvNode *section,
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
  const SomStrList *body = &section->body;
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
                             DvNode *section,
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
  /* List bodies and section tables become virtual sections before anything
   * is counted or checked (DocSpecs specification, List Bodies). */
  dv_expand_section_tables(val, section, t, v);
  dv_expand_list_body(val, section, t, v);
  validate_text(val, section, t, v);
  validate_format(val, section, t, v);

  CountMap counts;
  count_map_init(&counts);
  for (size_t i = 0; i < section->children_len; i++) {
    DvNode *child = section->children[i];
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
  /* The offending section is the CONTAINER, not the absent child: a cardinality
   * breach has no child occurrence to point at, and `sub_key` is a schema type
   * name, not a section id. Dart is the golden reference here. */
  for (size_t i = 0; i < t->subsection_types_len; i++) {
    const DocSpecsSubsectionRule *rule = &t->subsection_types[i];
    const char *sub_key = rule->name;
    int count = count_map_get(&counts, sub_key);
    if (count < rule->min_count) {
      if (count == 0) {
        dv_push(v, DOCSPECS_RULE_MISSING_REQUIRED_SECTION, section->line,
                vcat("required subsection \"", sub_key, "\" of \"", t->name,
                     "\" is missing", NULL),
                section->id, "");
      } else {
        char *cnt = dv_itoa(count);
        char *min = dv_itoa(rule->min_count);
        dv_push(v, DOCSPECS_RULE_TOO_FEW_ITEMS, section->line,
                vcat("subsection \"", sub_key, "\" occurs ", cnt,
                     " time(s), minimum is ", min, NULL),
                section->id, "");
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
              section->id, "");
      free(cnt);
      free(max);
    }
  }
  count_map_free(&counts);
}

/* check_order: the order check of one root child. `order` holds the slots'
 * section types in slot order, NULL for a `position: any` slot. The child's
 * slot is the first of its type at or after the last slot taken, else the
 * first of its type anywhere; a slot before the last one taken is
 * sectionOutOfOrder. Answers the last slot taken afterwards. */
static long check_order(DvNode *child, const char *type_name,
                        const char *const *order, size_t order_len,
                        long last_index, DocSpecsViolationList *v) {
  long index = -1;
  for (size_t i = last_index > 0 ? (size_t)last_index : 0; i < order_len;
       i++) {
    if (order[i] != NULL && strcmp(order[i], type_name) == 0) {
      index = (long)i;
      break;
    }
  }
  if (index == -1) {
    for (size_t i = 0; i < order_len; i++) {
      if (order[i] != NULL && strcmp(order[i], type_name) == 0) {
        index = (long)i;
        break;
      }
    }
  }
  if (index == -1) {
    return last_index;
  }
  if (index < last_index) {
    dv_push(v, DOCSPECS_RULE_SECTION_OUT_OF_ORDER, child->line,
            vcat("section \"", child->id, "\" (type \"", type_name,
                 "\") stands out of the order of the document sections", NULL),
            child->id, "");
    return last_index;
  }
  return index;
}

static void validate_document_sections(const DocSpecsValidator *val,
                                       DvNode *root,
                                       DocSpecsViolationList *v) {
  CountMap counts;
  count_map_init(&counts);
  size_t slots_len = val->schema->document_sections_len;
  const char **order =
      slots_len > 0 ? calloc(slots_len, sizeof(const char *)) : NULL;
  for (size_t si = 0; si < slots_len; si++) {
    const DocSpecsDocumentSection *slot = &val->schema->document_sections[si];
    order[si] =
        docspecs_document_section_any_position(slot) ? NULL : slot->section_type;
  }
  long last_index = -1;
  /* A section table in the root's body rebuilds root children first. */
  dv_expand_section_tables(val, root, NULL, v);
  for (size_t i = 0; i < root->children_len; i++) {
    DvNode *child = root->children[i];
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
    /* a type in the set of `position: any` slot types stands anywhere */
    int anywhere = 0;
    for (size_t si = 0; si < slots_len; si++) {
      const DocSpecsDocumentSection *slot = &val->schema->document_sections[si];
      if (docspecs_document_section_any_position(slot) &&
          strcmp(slot->section_type, t->name) == 0) {
        anywhere = 1;
        break;
      }
    }
    if (!anywhere) {
      last_index = check_order(child, t->name, order, slots_len, last_index, v);
    }
    count_map_inc(&counts, t->name);
    validate_section(val, child, t, v);
  }
  free(order);
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

/* validate_id_paths: every section's id path (the ids from the root down to
 * it) is unique: a section whose id repeats an earlier sibling's is a
 * duplicateIdPath. Its descendants repeat paths only through it and are not
 * reported again. Sections without an id are skipped (already
 * malformedHeading) but their children are walked. Depth-first, source
 * order. */
static void validate_id_paths(DocSpecsSection *const *sections, size_t len,
                              DocSpecsViolationList *v) {
  for (size_t i = 0; i < len; i++) {
    const DocSpecsSection *s = sections[i];
    if (s->id[0] != '\0') {
      int seen = 0;
      for (size_t j = 0; j < i; j++) {
        if (strcmp(sections[j]->id, s->id) == 0) {
          seen = 1;
          break;
        }
      }
      if (seen) {
        dv_push(v, DOCSPECS_RULE_DUPLICATE_ID_PATH, s->line,
                vcat("section id \"", s->id,
                     "\" repeats a sibling's id, so its id path is not unique",
                     NULL),
                s->id, "");
        continue;
      }
    }
    validate_id_paths(s->children, s->children_len, v);
  }
}

/* ---- the reading notation ------------------------------------------------ */

/* `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`: a form field's label line. Writes the
 * label's length; the rest must hold no line terminator. */
static int field_label_line(const char *line, size_t *label_len) {
  size_t n = strlen(line);
  if (n == 0 || !((line[0] >= 'A' && line[0] <= 'Z') ||
                  (line[0] >= 'a' && line[0] <= 'z'))) {
    return 0;
  }
  size_t i = 1;
  while (i < n && ((line[i] >= 'A' && line[i] <= 'Z') ||
                   (line[i] >= 'a' && line[i] <= 'z') ||
                   (line[i] >= '0' && line[i] <= '9') || line[i] == '_')) {
    i++;
  }
  if (i >= n || line[i] != ':') return 0;
  if (strchr(line + i + 1, '\r') != NULL) return 0;
  *label_len = i;
  return 1;
}

/* Whether the form has a field named `label` (its first `len` bytes), in any
 * case. */
static int form_has_label(const DocSpecsFormType *form, const char *label,
                          size_t len) {
  for (size_t f = 0; f < form->fields_len; f++) {
    const char *name = form->fields[f].name;
    if (strlen(name) != len) continue;
    size_t k = 0;
    while (k < len) {
      char a = name[k], b = label[k];
      if (a >= 'A' && a <= 'Z') a = (char)(a - 'A' + 'a');
      if (b >= 'A' && b <= 'Z') b = (char)(b - 'A' + 'a');
      if (a != b) break;
      k++;
    }
    if (k == len) return 1;
  }
  return 0;
}

/* Scans the body lines [first, last) of `section` as one value and appends
 * its findings, their lines counted from the section's first body line. */
static void scan_notation_value(const DocSpecsValidator *val,
                                const DocSpecsSection *section, size_t first,
                                size_t last, DocSpecsViolationList *out) {
  SomBuf text;
  som_buf_init(&text);
  for (size_t i = first; i < last; i++) {
    if (i > first) som_buf_putc(&text, '\n');
    som_buf_puts(&text, section->body_lines.items[i]);
  }
  char *value = som_buf_take(&text);
  SpecNotationScan scan;
  spec_scan_notation(value, val->tom_specs, &scan);
  int body_start = docspecs_section_body_start_line(section);
  for (size_t k = 0; k < scan.findings_len; k++) {
    const SpecNotationFinding *f = &scan.findings[k];
    dv_push(out, spec_notation_finding_code_name(f->code),
            body_start + (int)first + f->line - 1, som_strdup(f->message),
            section->id, "");
  }
  spec_notation_scan_free(&scan);
  free(value);
}

/* The reading notation of every section's own body: one value per section,
 * and in a TomSpecs rendition one per form field of a form-formatted section
 * (its preamble included). */
static void validate_notation(const DocSpecsValidator *val,
                              const DocSpecsDocument *doc,
                              DocSpecsViolationList *out) {
  size_t count = 0;
  const DocSpecsSection **all = docspecs_document_all_sections(doc, &count);
  for (size_t s = 0; s < count; s++) {
    const DocSpecsSection *section = all[s];
    size_t lines = section->body_lines.len;
    const DocSpecsFormType *form = NULL;
    if (val->tom_specs && section->id[0] != '\0') {
      const DocSpecsSectionType *type =
          docspecs_schema_resolve_section_type(val->schema, section->id);
      if (type != NULL && type->format[0] != '\0') {
        form = docspecs_schema_form_type(val->schema, type->format);
      }
    }
    if (form == NULL) {
      scan_notation_value(val, section, 0, lines, out);
      continue;
    }
    SpecMarkdownFenceTracker fence;
    spec_markdown_fence_init(&fence);
    size_t first = 0;
    for (size_t i = 0; i < lines; i++) {
      const char *line = section->body_lines.items[i];
      size_t label_len = 0;
      if (!spec_markdown_fence_in_fence(&fence) && i > first &&
          field_label_line(line, &label_len) &&
          form_has_label(form, line, label_len)) {
        scan_notation_value(val, section, first, i, out);
        first = i;
      }
      spec_markdown_fence_feed(&fence, line);
    }
    scan_notation_value(val, section, first, lines, out);
  }
  free((void *)all);
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
  DvNode *root_node = dv_node_of(root);
  validate_document_sections(val, root_node, out);
  dv_node_free(root_node);
  validate_notation(val, doc, out);
  validate_id_paths(doc->sections, doc->sections_len, out);
}

/* ---- bind ---------------------------------------------------------------- */

void docspecs_bind_markdown(const SpecModel *model, const char *text,
                            SpecMarkdownResult *out) {
  spec_markdown_parse(model, text, out);
}
