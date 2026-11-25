/* spec_document_strip — the strip of one text value (see the header).
 *
 * A port of `spec_document_strip.ts`'s `_Plan` and its helpers (`_compose`,
 * `_diff`, `_myers`, `_findMarks`), working on the value's bytes. Character
 * tests only ever look at ASCII (whitespace, markers), and every range the
 * notation scanner and the mark finder hand over falls on a character
 * boundary, so a byte-wise plan deletes and keeps whole characters; the
 * pieces' offsets are converted to UTF-16 code units when they are made.
 */
#include "spec_document_strip.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "spec_document_markdown.h"
#include "spec_notation.h"
#include "spec_review_annotations.h"

const char *const SPEC_STRIP_KIND_NAMES[SPEC_STRIP_KIND_COUNT] = {
    "provenance", "trace", "editorial", "aside", "linked", "derived", "comments",
};

const char *const SPEC_STRIP_NOTATION_KINDS[SPEC_STRIP_NOTATION_KIND_COUNT] = {
    "provenance", "trace", "editorial", "aside",
};

enum { K_LINKED = 4, K_DERIVED = 5, K_COMMENTS = 6 };

int spec_strip_kind_index(const char *name) {
  for (int i = 0; i < SPEC_STRIP_KIND_COUNT; i++) {
    if (strcmp(SPEC_STRIP_KIND_NAMES[i], name) == 0) return i;
  }
  return -1;
}

static int has_kind(unsigned set, int k) { return k >= 0 && (set >> k) & 1u; }

/* ---- options ----------------------------------------------------------------- */

/* The names of `list`, each item split on commas and trimmed, empty ones left
 * out. */
static void option_names(const SomStrList *list, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; list != NULL && i < list->len; i++) {
    const char *q = list->items[i];
    for (;;) {
      const char *comma = strchr(q, ',');
      const char *e = comma != NULL ? comma : q + strlen(q);
      const char *a = q;
      const char *b = e;
      while (a < b && (*a == ' ' || *a == '\t' || *a == '\n' || *a == '\r')) a++;
      while (b > a && (b[-1] == ' ' || b[-1] == '\t' || b[-1] == '\n' ||
                       b[-1] == '\r')) {
        b--;
      }
      if (b > a) som_strlist_push(out, som_strdup_n(a, (size_t)(b - a)));
      if (comma == NULL) break;
      q = comma + 1;
    }
  }
}

static char *usage(const char *a, const char *b, const char *c, const char *d,
                   const char *e) {
  SomBuf buf;
  som_buf_init(&buf);
  const char *parts[5] = {a, b, c, d, e};
  for (int i = 0; i < 5; i++) {
    if (parts[i] != NULL) som_buf_puts(&buf, parts[i]);
  }
  return som_buf_take(&buf);
}

int spec_strip_options_from_names(const SomStrList *drop,
                                  const SomStrList *unmark,
                                  const SomStrList *appendix,
                                  int appendix_references, int heading_divs,
                                  SpecStripOptions *out, char **error) {
  static const char *const keys[3] = {"drop", "unmark", "appendix"};
  SomStrList lists[3];
  option_names(drop, &lists[0]);
  option_names(unmark, &lists[1]);
  option_names(appendix, &lists[2]);
  char *err = NULL;
  for (int l = 0; l < 3 && err == NULL; l++) {
    for (size_t i = 0; i < lists[l].len && err == NULL; i++) {
      const char *n = lists[l].items[i];
      if (spec_strip_kind_index(n) < 0 && strcmp(n, "all") != 0) {
        SomBuf known;
        som_buf_init(&known);
        for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
          som_buf_puts(&known, SPEC_STRIP_KIND_NAMES[k]);
          som_buf_puts(&known, ", ");
        }
        som_buf_puts(&known, "all");
        char *ks = som_buf_take(&known);
        err = usage("unknown kind name \"", n, "\" in ", keys[l], NULL);
        char *full = usage(err, "; known names: ", ks, NULL, NULL);
        free(err);
        free(ks);
        err = full;
      }
    }
  }
  for (int a = 0; a < 3 && err == NULL; a++) {
    for (int b = a + 1; b < 3 && err == NULL; b++) {
      for (size_t i = 0; i < lists[a].len && err == NULL; i++) {
        if (som_strlist_contains(&lists[b], lists[a].items[i])) {
          char *x = usage("kind name \"", lists[a].items[i], "\" is in both ",
                          keys[a], " and ");
          err = usage(x, keys[b], NULL, NULL, NULL);
          free(x);
        }
      }
    }
  }
  if (err == NULL && som_strlist_contains(&lists[1], "comments")) {
    err = som_strdup("comments cannot be unmarked: a review annotation has no "
                     "reading without its markers; drop it or leave it");
  }
  if (err == NULL && som_strlist_contains(&lists[2], "comments")) {
    err = som_strdup(
        "comments cannot be moved to the appendix; drop them or leave them");
  }
  const char *rendered[2] = {"linked", "derived"};
  for (int r = 0; r < 2 && err == NULL; r++) {
    if (som_strlist_contains(&lists[2], rendered[r])) {
      err = usage(rendered[r],
                  " cannot be moved to the appendix: the renderer writes it "
                  "from the document; drop it or leave it",
                  NULL, NULL, NULL);
    }
  }
  unsigned explicit_set = 0;
  for (int l = 0; l < 3; l++) {
    for (size_t i = 0; i < lists[l].len; i++) {
      int k = spec_strip_kind_index(lists[l].items[i]);
      if (k >= 0) explicit_set |= 1u << k;
    }
  }
  /* `all` expands to every kind a list can hold that no list names. */
  unsigned can[3] = {0x7Fu, 0x0Fu | (1u << K_LINKED) | (1u << K_DERIVED), 0x0Fu};
  unsigned sets[3] = {0, 0, 0};
  for (int l = 0; l < 3; l++) {
    for (size_t i = 0; i < lists[l].len; i++) {
      const char *n = lists[l].items[i];
      if (strcmp(n, "all") == 0) {
        sets[l] |= can[l] & ~explicit_set;
      } else {
        int k = spec_strip_kind_index(n);
        if (k >= 0) sets[l] |= 1u << k;
      }
    }
  }
  if (err == NULL && appendix_references && sets[2] == 0) {
    err = som_strdup("appendix references need an appendix: name its kinds");
  }
  for (int l = 0; l < 3; l++) som_strlist_free(&lists[l]);
  if (err != NULL) {
    if (error != NULL) {
      *error = err;
    } else {
      free(err);
    }
    return 0;
  }
  out->drop = sets[0];
  out->unmark = sets[1];
  out->appendix = sets[2];
  out->appendix_references = appendix_references != 0;
  out->heading_divs = heading_divs != 0;
  return 1;
}

static void put_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s);
  som_buf_puts(b, q);
  free(q);
}

static void put_kinds(SomBuf *b, unsigned set) {
  som_buf_putc(b, '[');
  int first = 1;
  for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
    if (!has_kind(set, k)) continue;
    if (!first) som_buf_putc(b, ',');
    first = 0;
    put_str(b, SPEC_STRIP_KIND_NAMES[k]);
  }
  som_buf_putc(b, ']');
}

char *spec_strip_options_to_json(const SpecStripOptions *o) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"drop\":");
  put_kinds(&b, o->drop);
  som_buf_puts(&b, ",\"unmark\":");
  put_kinds(&b, o->unmark);
  som_buf_puts(&b, ",\"appendix\":");
  put_kinds(&b, o->appendix);
  som_buf_puts(&b, o->appendix_references ? ",\"appendixReferences\":true"
                                          : ",\"appendixReferences\":false");
  som_buf_puts(&b, o->heading_divs ? ",\"headingDivs\":true}"
                                   : ",\"headingDivs\":false}");
  return som_buf_take(&b);
}

/* The options an appendix entry's own content is stripped with. */
static SpecStripOptions in_entry(const SpecStripOptions *o) {
  SpecStripOptions e;
  memset(&e, 0, sizeof(e));
  e.drop = o->drop & ~(1u << K_COMMENTS);
  e.unmark = o->unmark | o->appendix;
  return e;
}

/* ---- edit scripts --------------------------------------------------------------- */

enum { OP_KEEP = 0, OP_DEL = 1, OP_INS = 2 };

typedef struct {
  int type;
  char ch;
  const char *label; /* borrowed (a plan's label pool or a literal) */
} Op;

typedef struct {
  Op *items;
  size_t len, cap;
} OpVec;

static void ops_push(OpVec *v, int type, char ch, const char *label) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 64;
    v->items = realloc(v->items, v->cap * sizeof(Op));
  }
  v->items[v->len].type = type;
  v->items[v->len].ch = ch;
  v->items[v->len].label = label;
  v->len++;
}

/* A token: a range of a string. */
typedef struct {
  const char *p;
  size_t n;
} Tok;

typedef struct {
  Tok *items;
  size_t len, cap;
} TokVec;

static void toks_push(TokVec *v, const char *p, size_t n) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 16;
    v->items = realloc(v->items, v->cap * sizeof(Tok));
  }
  v->items[v->len].p = p;
  v->items[v->len].n = n;
  v->len++;
}

static int tok_eq(Tok a, Tok b) {
  return a.n == b.n && memcmp(a.p, b.p, a.n) == 0;
}

/* `s` as lines, each with its line break. */
static void split_lines_keep(const char *s, size_t n, TokVec *out) {
  size_t i = 0;
  while (i < n) {
    const char *nl = memchr(s + i, '\n', n - i);
    size_t e = nl != NULL ? (size_t)(nl - s) + 1 : n;
    toks_push(out, s + i, e - i);
    i = e;
  }
}

static int token_kind(unsigned char c) {
  if (c == ' ' || c == '\t' || c == '\n' || c == '\r') return 2;
  if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
      c == '_' || c >= 0x80) {
    return 1;
  }
  return 0;
}

static void split_tokens(const char *s, size_t n, TokVec *out) {
  size_t i = 0;
  while (i < n) {
    int k = token_kind((unsigned char)s[i]);
    size_t j = i + 1;
    if (k != 0) {
      while (j < n && token_kind((unsigned char)s[j]) == k) j++;
    }
    toks_push(out, s + i, j - i);
    i = j;
  }
}

typedef struct {
  int type;
  Tok tok;
} Edit;

typedef struct {
  Edit *items;
  size_t len, cap;
} EditVec;

static void edits_push(EditVec *v, int type, Tok t) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 16;
    v->items = realloc(v->items, v->cap * sizeof(Edit));
  }
  v->items[v->len].type = type;
  v->items[v->len].tok = t;
  v->len++;
}

/* Myers' shortest edit script between token lists (`_myers`): at most 2000
 * rounds, else every token of `a` deleted and every token of `b` inserted. */
static void myers(const TokVec *a, const TokVec *b, EditVec *out) {
  long n = (long)a->len, m = (long)b->len;
  long max = n + m;
  if (max == 0) return;
  long cap = 2000;
  long off = max + 1;
  long *v = calloc((size_t)(2 * max + 3), sizeof(long));
  long **trace = calloc((size_t)(max + 2), sizeof(long *));
  long found = -1;
  for (long d = 0; d <= max && d <= cap; d++) {
    if (d > 0) {
      long *snap = malloc((size_t)(2 * d - 1) * sizeof(long));
      for (long k = -(d - 1); k <= d - 1; k++) snap[k + d - 1] = v[k + off];
      trace[d - 1] = snap;
    }
    for (long k = -d; k <= d; k += 2) {
      long x = (k == -d || (k != d && v[k - 1 + off] < v[k + 1 + off]))
                   ? v[k + 1 + off]
                   : v[k - 1 + off] + 1;
      long y = x - k;
      while (x < n && y < m && tok_eq(a->items[x], b->items[y])) {
        x++;
        y++;
      }
      v[k + off] = x;
      if (x >= n && y >= m) {
        found = d;
        break;
      }
    }
    if (found >= 0) break;
  }
  if (found < 0) {
    for (long i = 0; i < n; i++) edits_push(out, OP_DEL, a->items[i]);
    for (long i = 0; i < m; i++) edits_push(out, OP_INS, b->items[i]);
  } else {
    EditVec rev = {NULL, 0, 0};
    long x = n, y = m;
    for (long d = found; d > 0; d--) {
      long *snap = trace[d - 1];
#define AT(kk) snap[(kk) + d - 1]
      long k = x - y;
      long prev_k = (k == -d || (k != d && AT(k - 1) < AT(k + 1))) ? k + 1 : k - 1;
#undef AT
      long prev_x = snap[prev_k + d - 1];
      long prev_y = prev_x - prev_k;
      while (x > prev_x && y > prev_y) {
        edits_push(&rev, OP_KEEP, a->items[x - 1]);
        x--;
        y--;
      }
      if (x == prev_x) {
        edits_push(&rev, OP_INS, b->items[y - 1]);
      } else {
        edits_push(&rev, OP_DEL, a->items[x - 1]);
      }
      x = prev_x;
      y = prev_y;
    }
    while (x > 0 && y > 0) {
      edits_push(&rev, OP_KEEP, a->items[x - 1]);
      x--;
      y--;
    }
    for (size_t i = rev.len; i-- > 0;) edits_push(out, rev.items[i].type, rev.items[i].tok);
    free(rev.items);
  }
  for (long d = 0; d <= max + 1; d++) free(trace[d]);
  free(trace);
  free(v);
}

static void chars_push(OpVec *out, int type, Tok t, const char *label) {
  for (size_t k = 0; k < t.n; k++) {
    ops_push(out, type, t.p[k], type == OP_KEEP ? NULL : label);
  }
}

/* An edit script from `a` to `b`: Myers by line, then by word token. */
static void diff_text(const char *a, const char *b, const char *label, OpVec *out) {
  TokVec la = {NULL, 0, 0}, lb = {NULL, 0, 0};
  split_lines_keep(a, strlen(a), &la);
  split_lines_keep(b, strlen(b), &lb);
  EditVec lines = {NULL, 0, 0};
  myers(&la, &lb, &lines);
  SomBuf deleted, inserted;
  som_buf_init(&deleted);
  som_buf_init(&inserted);
#define DIFF_FLUSH()                                                           \
  do {                                                                         \
    if (deleted.len > 0 || inserted.len > 0) {                                 \
      char *ds = som_buf_take(&deleted);                                       \
      char *is = som_buf_take(&inserted);                                      \
      TokVec ta = {NULL, 0, 0}, tb = {NULL, 0, 0};                             \
      split_tokens(ds, strlen(ds), &ta);                                       \
      split_tokens(is, strlen(is), &tb);                                       \
      EditVec te = {NULL, 0, 0};                                               \
      myers(&ta, &tb, &te);                                                    \
      for (size_t q = 0; q < te.len; q++) {                                    \
        chars_push(out, te.items[q].type, te.items[q].tok, label);             \
      }                                                                        \
      free(te.items);                                                          \
      free(ta.items);                                                          \
      free(tb.items);                                                          \
      free(ds);                                                                \
      free(is);                                                                \
    }                                                                          \
  } while (0)
  for (size_t i = 0; i < lines.len; i++) {
    const Edit *e = &lines.items[i];
    if (e->type == OP_KEEP) {
      DIFF_FLUSH();
      chars_push(out, OP_KEEP, e->tok, label);
    } else if (e->type == OP_DEL) {
      som_buf_putn(&deleted, e->tok.p, e->tok.n);
    } else {
      som_buf_putn(&inserted, e->tok.p, e->tok.n);
    }
  }
  DIFF_FLUSH();
#undef DIFF_FLUSH
  som_buf_free(&deleted);
  som_buf_free(&inserted);
  free(lines.items);
  free(la.items);
  free(lb.items);
}

/* Composes the scripts original -> middle (`s1`) and middle -> result (`s2`). */
static void compose(const OpVec *s1, const OpVec *s2, OpVec *out) {
  size_t j = 0;
  for (size_t i = 0; i < s1->len; i++) {
    const Op *a = &s1->items[i];
    if (a->type == OP_DEL) {
      ops_push(out, a->type, a->ch, a->label);
      continue;
    }
    while (j < s2->len && s2->items[j].type == OP_INS) {
      ops_push(out, OP_INS, s2->items[j].ch, s2->items[j].label);
      j++;
    }
    const Op *b = &s2->items[j++];
    if (a->type == OP_KEEP) {
      if (b->type == OP_KEEP) {
        ops_push(out, a->type, a->ch, a->label);
      } else {
        ops_push(out, OP_DEL, a->ch, b->label);
      }
    } else if (b->type == OP_KEEP) {
      ops_push(out, a->type, a->ch, a->label);
    }
  }
  while (j < s2->len && s2->items[j].type == OP_INS) {
    ops_push(out, OP_INS, s2->items[j].ch, s2->items[j].label);
    j++;
  }
}

/* ---- inline marks ------------------------------------------------------------------ */

typedef struct {
  size_t start, end, body_start, body_end;
  long sep; /* `~>` of a substitution, -1 otherwise */
} MarkAt;

static const char *mark_closer(const char *t, size_t i) {
  static const char *const open[5] = {"{++", "{--", "{~~", "{==", "{>>"};
  static const char *const close[5] = {"++}", "--}", "~~}", "==}", "<<}"};
  for (int k = 0; k < 5; k++) {
    if (strncmp(t + i, open[k], 3) == 0) return close[k];
  }
  return NULL;
}

static void find_marks(const char *t, MarkAt **out, size_t *out_len) {
  size_t n = strlen(t);
  unsigned char *code = calloc(n + 1, 1);
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  size_t s = 0;
  for (;;) {
    const char *nl = strchr(t + s, '\n');
    size_t len = nl != NULL ? (size_t)(nl - (t + s)) : strlen(t + s);
    char *line = som_strdup_n(t + s, len);
    int in_fence = spec_markdown_fence_in_fence(&fence);
    spec_markdown_fence_feed(&fence, line);
    if (in_fence || spec_markdown_fence_in_fence(&fence)) {
      for (size_t i = s; i < s + len; i++) code[i] = 1;
    } else {
      size_t i = 0;
      while (i < len) {
        if (line[i] != '`') {
          i++;
          continue;
        }
        size_t j = i;
        while (j < len && line[j] == '`') j++;
        size_t ticks = j - i;
        const char *close = NULL;
        for (size_t q = j; q + ticks <= len; q++) {
          if (strncmp(line + q, line + i, ticks) == 0) {
            close = line + q;
            break;
          }
        }
        if (close == NULL) {
          i = j;
          continue;
        }
        size_t c = (size_t)(close - line);
        for (size_t k = s + i; k < s + c + ticks; k++) code[k] = 1;
        i = c + ticks;
      }
    }
    free(line);
    if (nl == NULL) break;
    s += len + 1;
  }
  MarkAt *marks = NULL;
  size_t ml = 0, mc = 0;
  size_t i = 0;
  while (i + 3 <= n) {
    const char *closer = mark_closer(t, i);
    if (closer == NULL || code[i]) {
      i++;
      continue;
    }
    /* `/\n[ \t]*\n/` from i: the paragraph's end */
    size_t limit = n;
    for (size_t q = i; q < n; q++) {
      if (t[q] != '\n') continue;
      size_t r = q + 1;
      while (r < n && (t[r] == ' ' || t[r] == '\t')) r++;
      if (r < n && t[r] == '\n') {
        limit = q;
        break;
      }
    }
    const char *close = strstr(t + i + 3, closer);
    if (close == NULL || (size_t)(close - t) + 3 > limit) {
      i++;
      continue;
    }
    size_t c = (size_t)(close - t);
    long sep = -1;
    if (strncmp(t + i, "{~~", 3) == 0) {
      const char *sp = strstr(t + i + 3, "~>");
      if (sp == NULL || (size_t)(sp - t) >= c) {
        i++;
        continue;
      }
      sep = (long)(sp - t);
    }
    if (ml == mc) {
      mc = mc ? mc * 2 : 8;
      marks = realloc(marks, mc * sizeof(MarkAt));
    }
    marks[ml].start = i;
    marks[ml].end = c + 3;
    marks[ml].body_start = i + 3;
    marks[ml].body_end = c;
    marks[ml].sep = sep;
    ml++;
    i = c + 3;
  }
  free(code);
  *out = marks;
  *out_len = ml;
}

/* ---- the plan ------------------------------------------------------------------------ */

typedef struct {
  size_t at;
  const char *label; /* borrowed from the pool */
  char *text;        /* owned; NULL for an appendix reference */
  long entry;        /* the entry index of a reference */
} Insert;

typedef struct {
  const char *o;          /* the original value (borrowed) */
  SpecStripOptions options;
  char *t;                /* owned: the value after the comments' strip */
  size_t n;               /* strlen(t) */
  OpVec script1;          /* original -> t, when comments went */
  int has_script1;
  const char **del;       /* per byte of t: the label that deletes it */
  unsigned char *block_del;
  Insert *ins;
  size_t ins_len, ins_cap;
  long long dropped[SPEC_STRIP_KIND_COUNT];
  long long unmarked[SPEC_STRIP_KIND_COUNT];
  long long appended[SPEC_STRIP_KIND_COUNT];
  long long marks_dropped;
  SomStrList entry_kinds;
  SomStrList entry_texts;
  SomStrList findings;    /* refusing finding codes */
  SomStrList pool;        /* label strings */
} Plan;

static const char *pool_label(Plan *p, const char *kind, const char *what) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, kind);
  if (what != NULL) {
    som_buf_putc(&b, ':');
    som_buf_puts(&b, what);
  }
  char *s = som_buf_take(&b);
  for (size_t i = 0; i < p->pool.len; i++) {
    if (strcmp(p->pool.items[i], s) == 0) {
      free(s);
      return p->pool.items[i];
    }
  }
  som_strlist_push(&p->pool, s);
  return s;
}

static int is_space_tab(char c) { return c == ' ' || c == '\t'; }

static int js_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' || c == '\f';
}

static void plan_mark(Plan *p, size_t s, size_t e, const char *label, int block) {
  for (size_t i = s; i < e && i < p->n; i++) {
    if (p->del[i] == NULL) p->del[i] = label;
    if (block) p->block_del[i] = 1;
  }
}

static void plan_insert(Plan *p, size_t at, const char *label, char *text,
                        long entry) {
  if (p->ins_len == p->ins_cap) {
    p->ins_cap = p->ins_cap ? p->ins_cap * 2 : 8;
    p->ins = realloc(p->ins, p->ins_cap * sizeof(Insert));
  }
  p->ins[p->ins_len].at = at;
  p->ins[p->ins_len].label = label;
  p->ins[p->ins_len].text = text;
  p->ins[p->ins_len].entry = entry;
  p->ins_len++;
}

static int plan_has_insert(const Plan *p, size_t at) {
  for (size_t i = 0; i < p->ins_len; i++) {
    if (p->ins[i].at == at) return 1;
  }
  return 0;
}

static void plan_remove(Plan *p, const SpecNotationElement *e, const char *label,
                        long entry) {
  const char *t = p->t;
  int reference = entry >= 0 && p->options.appendix_references;
  if (e->type == SPEC_NOTATION_DIV) {
    plan_mark(p, e->start, e->end, label, 1);
    if (reference) plan_insert(p, e->start, label, NULL, entry);
    return;
  }
  size_t s = e->start;
  if (s > 0 && is_space_tab(t[s - 1]) && p->del[s - 1] == NULL) {
    p->del[s - 1] = label;
  } else if (!reference && (s == 0 || t[s - 1] == '\n') && e->end < p->n &&
             is_space_tab(t[e->end])) {
    p->del[e->end] = label;
  }
  plan_mark(p, e->start, e->end, label, 0);
  if (reference) plan_insert(p, e->start, label, NULL, entry);
}

static void plan_unmark(Plan *p, const SpecNotationElement *e, const char *label) {
  if (e->type == SPEC_NOTATION_DIV) {
    if (e->content_start >= e->content_end) {
      plan_mark(p, e->start, e->end, label, 1);
    } else {
      plan_mark(p, e->start, e->content_start, label, 1);
      plan_mark(p, e->content_end - 1, e->end, label, 1);
    }
  } else if (e->type == SPEC_NOTATION_SPAN) {
    plan_mark(p, e->start, e->start + 1, label, 0);
    plan_mark(p, e->content_end, e->end, label, 0);
  } else {
    plan_mark(p, e->start + 1, e->content_start, label, 0);
  }
}

static void strip_text(const char *value, const SpecStripOptions *options,
                       SpecStripTextResult *out);

static void plan_process(Plan *p, SpecNotationElement *const *list, size_t len) {
  for (size_t i = 0; i < len; i++) {
    const SpecNotationElement *e = list[i];
    int k = e->kind != NULL ? spec_strip_kind_index(e->kind) : -1;
    int registered = spec_notation_element_registered(e);
    /* A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12) is
     * removed by `drop` and `unmark` alike. */
    if (registered && (k == K_LINKED || k == K_DERIVED) &&
        (has_kind(p->options.drop, k) || has_kind(p->options.unmark, k))) {
      plan_remove(p, e, pool_label(p, e->kind, "drop"), -1);
      p->dropped[k]++;
      continue;
    }
    int secondary = registered && k >= 0 && k < SPEC_STRIP_NOTATION_KIND_COUNT;
    if (!secondary) {
      plan_process(p, e->children, e->children_len);
      continue;
    }
    if (has_kind(p->options.drop, k)) {
      plan_remove(p, e, pool_label(p, e->kind, "drop"), -1);
      p->dropped[k]++;
      continue;
    }
    if (has_kind(p->options.appendix, k)) {
      char *content;
      if (e->type == SPEC_NOTATION_CITATION) {
        content = som_strdup_n(p->t + e->start, e->end - e->start);
      } else {
        size_t a = e->content_start, b = e->content_end;
        while (b > a && p->t[b - 1] == '\n') b--;
        content = som_strdup_n(p->t + a, b - a);
      }
      SpecStripOptions eo = in_entry(&p->options);
      SpecStripTextResult er;
      strip_text(content, &eo, &er);
      som_strlist_push_copy(&p->entry_kinds, e->kind);
      som_strlist_push_copy(&p->entry_texts, er.text);
      spec_strip_text_result_free(&er);
      free(content);
      plan_remove(p, e, pool_label(p, e->kind, "appendix"),
                  (long)p->entry_kinds.len - 1);
      p->appended[k]++;
      continue;
    }
    if (has_kind(p->options.unmark, k)) {
      plan_unmark(p, e, pool_label(p, e->kind, "unmark"));
      p->unmarked[k]++;
    }
    plan_process(p, e->children, e->children_len);
  }
}

static int plan_all_deleted(const Plan *p, size_t s, size_t e) {
  for (size_t i = s; i < e; i++) {
    if (p->del[i] == NULL) return 0;
  }
  return 1;
}

static int plan_had_text(const Plan *p, size_t s, size_t e) {
  for (size_t i = s; i < e; i++) {
    if (!js_space(p->t[i])) return 1;
  }
  return 0;
}

static int plan_survives(const Plan *p, size_t s, size_t e) {
  for (size_t i = s; i < e; i++) {
    if (p->del[i] == NULL && !js_space(p->t[i])) return 1;
  }
  return 0;
}

static void plan_remove_mark(Plan *p, const MarkAt *m) {
  const char *t = p->t;
  size_t s = m->start;
  if (s > 0 && is_space_tab(t[s - 1]) && p->del[s - 1] == NULL) {
    p->del[s - 1] = "mark";
  } else if ((s == 0 || t[s - 1] == '\n') && m->end < p->n &&
             is_space_tab(t[m->end])) {
    p->del[m->end] = "mark";
  }
  plan_mark(p, m->start, m->end, "mark", 0);
}

static void plan_convert(Plan *p, const MarkAt *m, const char *delimiter,
                         size_t s, size_t e) {
  plan_mark(p, m->start + 1, m->start + 3, "mark", 0);
  plan_insert(p, m->start + 3, "mark", som_strdup(delimiter), -1);
  plan_mark(p, s, e, "mark", 0);
  plan_mark(p, m->end - 3, m->end - 1, "mark", 0);
  plan_insert(p, m->end - 1, "mark", som_strdup(delimiter), -1);
}

static void plan_marks(Plan *p) {
  MarkAt *marks = NULL;
  size_t ml = 0;
  find_marks(p->t, &marks, &ml);
  for (size_t i = 0; i < ml; i++) {
    const MarkAt *m = &marks[i];
    if (plan_all_deleted(p, m->start, m->end)) {
      p->marks_dropped++;
      continue;
    }
    if (m->sep < 0) {
      if (plan_had_text(p, m->body_start, m->body_end) &&
          !plan_survives(p, m->body_start, m->body_end)) {
        plan_remove_mark(p, m);
      }
      continue;
    }
    size_t sep = (size_t)m->sep;
    int old_had = plan_had_text(p, m->body_start, sep);
    int new_had = plan_had_text(p, sep + 2, m->body_end);
    int old_left = plan_survives(p, m->body_start, sep);
    int new_left = plan_survives(p, sep + 2, m->body_end);
    if (!old_left && !new_left && (old_had || new_had)) {
      plan_remove_mark(p, m);
    } else if (old_had && !old_left) {
      plan_convert(p, m, "++", m->body_start, sep + 2);
    } else if (new_had && !new_left) {
      plan_convert(p, m, "--", sep, m->body_end);
    }
  }
  free(marks);
}

/* The whitespace the removals leave (`_normalise`). */
static void plan_normalise(Plan *p) {
  const char *t = p->t;
  size_t n = p->n;
  const char **del = p->del;
  /* lines emptied by a removal (not a whole block's) go with their break */
  size_t s = 0;
  for (;;) {
    const char *nl = memchr(t + s, '\n', n - s);
    size_t e = nl != NULL ? (size_t)(nl - t) : n;
    int blank = 1;
    for (size_t i = s; i < e; i++) {
      if (!js_space(t[i])) blank = 0;
    }
    if (!blank) {
      int touched = 0, survives = 0, all_block = 1;
      for (size_t i = s; i < e; i++) {
        if (del[i] != NULL) {
          touched = 1;
        } else if (!js_space(t[i])) {
          survives = 1;
        }
        if (!p->block_del[i]) all_block = 0;
      }
      for (size_t i = s; i <= e; i++) {
        if (plan_has_insert(p, i)) survives = 1;
      }
      if (touched && !survives && !all_block) {
        plan_mark(p, s, e, "whitespace", 0);
        if (e < n) {
          if (del[e] == NULL) del[e] = "whitespace";
        } else if (s > 0) {
          if (del[s - 1] == NULL) del[s - 1] = "whitespace";
        }
      }
    }
    if (nl == NULL) break;
    s = e + 1;
  }
  /* Blank-line runs, read on the text as it now stands. */
  long *kept = malloc((n + 1 + 64) * sizeof(long));
  size_t kept_cap = n + 1 + 64, kl = 0;
  SomBuf bb;
  som_buf_init(&bb);
  for (size_t i = 0; i <= n; i++) {
    for (size_t x = 0; x < p->ins_len; x++) {
      if (p->ins[x].at != i) continue;
      const char *str = p->ins[x].text != NULL ? p->ins[x].text : "x";
      for (size_t k = 0; str[k] != '\0'; k++) {
        if (kl == kept_cap) {
          kept_cap *= 2;
          kept = realloc(kept, kept_cap * sizeof(long));
        }
        kept[kl++] = -1;
      }
      som_buf_puts(&bb, str);
    }
    if (i < n && del[i] == NULL) {
      if (kl == kept_cap) {
        kept_cap *= 2;
        kept = realloc(kept, kept_cap * sizeof(long));
      }
      kept[kl++] = (long)i;
      som_buf_putc(&bb, t[i]);
    }
  }
  char *b = som_buf_take(&bb);
  size_t bl = kl;
#define SOLID(c) (!js_space(c))
  size_t first = 0;
  while (first < bl && !SOLID(b[first])) first++;
  if (first == bl) {
    for (size_t k = 0; k < kl; k++) {
      if (kept[k] >= 0 && del[kept[k]] == NULL) del[kept[k]] = "whitespace";
    }
    free(b);
    free(kept);
    return;
  }
  size_t last = bl - 1;
  while (!SOLID(b[last])) last--;
  long lead = -1;
  for (size_t k = 0; k <= first; k++) {
    if (b[k] == '\n') lead = (long)k;
  }
  for (long k = 0; k <= lead; k++) {
    if (kept[k] >= 0 && del[kept[k]] == NULL) del[kept[k]] = "whitespace";
  }
  long trail = -1;
  for (size_t k = last; k < bl; k++) {
    if (b[k] == '\n') {
      trail = (long)k;
      break;
    }
  }
  if (trail >= 0) {
    for (size_t k = (size_t)trail; k < bl; k++) {
      if (kept[k] >= 0 && del[kept[k]] == NULL) del[kept[k]] = "whitespace";
    }
  }
  size_t k = first;
  while (k < last) {
    if (SOLID(b[k])) {
      k++;
      continue;
    }
    size_t run_start = k;
    while (!SOLID(b[k])) k++;
    size_t run_end = k;
    size_t breaks_n = 0, first_break = 0, last_break = 0;
    for (size_t j = run_start; j < run_end; j++) {
      if (b[j] == '\n') {
        if (breaks_n == 0) first_break = j;
        last_break = j;
        breaks_n++;
      }
    }
    if (breaks_n <= 2) continue;
    long from = kept[run_start - 1];
    long to = kept[run_end];
    int at_removal = 0;
    if (from >= 0 && to >= 0) {
      for (long i = from + 1; i < to; i++) {
        if (del[i] != NULL && strcmp(del[i], "whitespace") != 0) at_removal = 1;
      }
    } else {
      at_removal = 1;
    }
    if (!at_removal) continue;
    for (size_t j = first_break + 1; j + 1 <= last_break; j++) {
      if (kept[j] >= 0 && del[kept[j]] == NULL) del[kept[j]] = "whitespace";
    }
  }
#undef SOLID
  free(b);
  free(kept);
}

static void plan_init(Plan *p, const char *o, const SpecStripOptions *options) {
  memset(p, 0, sizeof(*p));
  p->o = o;
  p->options = *options;
  som_strlist_init(&p->entry_kinds);
  som_strlist_init(&p->entry_texts);
  som_strlist_init(&p->findings);
  som_strlist_init(&p->pool);
  SpecNotationScan scan;
  spec_scan_notation(o, 1, &scan);
  for (size_t i = 0; i < scan.findings_len; i++) {
    SpecNotationFindingCode c = scan.findings[i].code;
    if (strcmp(spec_notation_severity(c), "error") == 0 &&
        c != SPEC_NOTATION_REJECTED_BLOCK) {
      som_strlist_push_copy(&p->findings, spec_notation_finding_code_name(c));
    }
  }
  spec_notation_scan_free(&scan);
  if (p->findings.len > 0) {
    p->t = som_strdup(o);
    p->n = strlen(p->t);
    return;
  }
  if (has_kind(options->drop, K_COMMENTS)) {
    p->t = spec_strip_annotations_text(o);
    if (strcmp(p->t, o) != 0) {
      p->dropped[K_COMMENTS] = (long long)spec_count_annotations_text(o);
      diff_text(o, p->t, "comments", &p->script1);
      p->has_script1 = 1;
    }
  } else {
    p->t = som_strdup(o);
  }
  p->n = strlen(p->t);
  p->del = calloc(p->n + 1, sizeof(const char *));
  p->block_del = calloc(p->n + 1, 1);
  SpecNotationScan s2;
  spec_scan_notation(p->t, 1, &s2);
  plan_process(p, s2.elements, s2.elements_len);
  spec_notation_scan_free(&s2);
  if (!has_kind(options->drop, K_COMMENTS)) plan_marks(p);
  for (size_t i = 0; i < p->n; i++) {
    if (p->del[i] != NULL) {
      plan_normalise(p);
      break;
    }
  }
}

static void plan_free(Plan *p) {
  free(p->t);
  free(p->script1.items);
  free(p->del);
  free(p->block_del);
  for (size_t i = 0; i < p->ins_len; i++) free(p->ins[i].text);
  free(p->ins);
  som_strlist_free(&p->entry_kinds);
  som_strlist_free(&p->entry_texts);
  som_strlist_free(&p->findings);
  som_strlist_free(&p->pool);
}

static int str_cmp_ptr(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* The UTF-16 units a byte adds (0 for a continuation byte). */
static size_t u16_units(unsigned char c) {
  if ((c & 0xC0) == 0x80) return 0;
  return c >= 0xF0 ? 2 : 1;
}

static void plan_finish(Plan *p, SpecStripTextResult *out) {
  memset(out, 0, sizeof(*out));
  som_strlist_init(&out->refused);
  if (p->findings.len > 0) {
    out->text = som_strdup(p->o);
    som_strlist_copy(&out->refused, &p->findings);
    return;
  }
  const char *t = p->t;
  OpVec script2 = {NULL, 0, 0};
  for (size_t i = 0; i <= p->n; i++) {
    for (size_t x = 0; x < p->ins_len; x++) {
      if (p->ins[x].at != i) continue;
      char *text;
      if (p->ins[x].text != NULL) {
        text = som_strdup(p->ins[x].text);
      } else {
        char *num = som_format_i64((long long)p->ins[x].entry + 1);
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "<a id=\"note-");
        som_buf_puts(&b, num);
        som_buf_puts(&b, "-ref\"></a>[\\[");
        som_buf_puts(&b, num);
        som_buf_puts(&b, "\\]](#note-");
        som_buf_puts(&b, num);
        som_buf_puts(&b, ")");
        text = som_buf_take(&b);
        free(num);
      }
      for (size_t k = 0; text[k] != '\0'; k++) {
        ops_push(&script2, OP_INS, text[k], p->ins[x].label);
      }
      free(text);
    }
    if (i < p->n) {
      if (p->del[i] == NULL) {
        ops_push(&script2, OP_KEEP, t[i], NULL);
      } else {
        ops_push(&script2, OP_DEL, t[i], p->del[i]);
      }
    }
  }
  OpVec composed = {NULL, 0, 0};
  const OpVec *ops = &script2;
  if (p->has_script1) {
    compose(&p->script1, &script2, &composed);
    ops = &composed;
  }
  SomBuf text;
  som_buf_init(&text);
  size_t o16 = 0, b16 = 0;
  size_t pieces_cap = 0;
  size_t i = 0;
  while (i < ops->len) {
    if (ops->items[i].type == OP_KEEP) {
      som_buf_putc(&text, ops->items[i].ch);
      size_t u = u16_units((unsigned char)ops->items[i].ch);
      o16 += u;
      b16 += u;
      i++;
      continue;
    }
    size_t anchor = b16, origin = o16;
    SomBuf removed, inserted;
    som_buf_init(&removed);
    som_buf_init(&inserted);
    SomStrList labels;
    som_strlist_init(&labels);
    while (i < ops->len && ops->items[i].type != OP_KEEP) {
      const Op *op = &ops->items[i];
      if (op->label != NULL && !som_strlist_contains(&labels, op->label)) {
        som_strlist_push_copy(&labels, op->label);
      }
      size_t u = u16_units((unsigned char)op->ch);
      if (op->type == OP_DEL) {
        som_buf_putc(&removed, op->ch);
        o16 += u;
      } else {
        som_buf_putc(&inserted, op->ch);
        som_buf_putc(&text, op->ch);
        b16 += u;
      }
      i++;
    }
    if (labels.len > 1) {
      qsort(labels.items, labels.len, sizeof(char *), str_cmp_ptr);
    }
    if (out->pieces_len == pieces_cap) {
      pieces_cap = pieces_cap ? pieces_cap * 2 : 8;
      out->pieces = realloc(out->pieces, pieces_cap * sizeof(SpecStripPiece));
    }
    SpecStripPiece *pc = &out->pieces[out->pieces_len++];
    pc->anchor = anchor;
    pc->origin = origin;
    pc->removed = som_buf_take(&removed);
    pc->inserted = som_buf_take(&inserted);
    pc->labels = labels;
  }
  out->text = som_buf_take(&text);
  memcpy(out->dropped, p->dropped, sizeof(p->dropped));
  memcpy(out->unmarked, p->unmarked, sizeof(p->unmarked));
  memcpy(out->appended, p->appended, sizeof(p->appended));
  out->marks_dropped = p->marks_dropped;
  out->appendix_len = p->entry_kinds.len;
  if (out->appendix_len > 0) {
    out->appendix = calloc(out->appendix_len, sizeof(SpecAppendixEntry));
    for (size_t k = 0; k < out->appendix_len; k++) {
      out->appendix[k].number = (long long)k + 1;
      out->appendix[k].kind = som_strdup(p->entry_kinds.items[k]);
      out->appendix[k].text = som_strdup(p->entry_texts.items[k]);
    }
  }
  free(script2.items);
  free(composed.items);
}

static void strip_text(const char *value, const SpecStripOptions *options,
                       SpecStripTextResult *out) {
  Plan p;
  plan_init(&p, value != NULL ? value : "", options);
  plan_finish(&p, out);
  plan_free(&p);
}

void spec_strip_notation_text(const char *value, const SpecStripOptions *options,
                              SpecStripTextResult *out) {
  strip_text(value, options, out);
}

void spec_strip_text_result_free(SpecStripTextResult *r) {
  if (r == NULL) return;
  free(r->text);
  for (size_t i = 0; i < r->pieces_len; i++) {
    free(r->pieces[i].removed);
    free(r->pieces[i].inserted);
    som_strlist_free(&r->pieces[i].labels);
  }
  free(r->pieces);
  for (size_t i = 0; i < r->appendix_len; i++) {
    free(r->appendix[i].kind);
    free(r->appendix[i].text);
  }
  free(r->appendix);
  som_strlist_free(&r->refused);
  memset(r, 0, sizeof(*r));
}

int spec_strip_text_result_refused(const SpecStripTextResult *r) {
  return r->refused.len > 0;
}

static void put_counts(SomBuf *b, const long long *counts) {
  som_buf_putc(b, '{');
  int first = 1;
  for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
    if (counts[k] == 0) continue;
    if (!first) som_buf_putc(b, ',');
    first = 0;
    put_str(b, SPEC_STRIP_KIND_NAMES[k]);
    som_buf_putc(b, ':');
    som_buf_puti(b, counts[k]);
  }
  som_buf_putc(b, '}');
}

char *spec_strip_text_result_to_json(const SpecStripTextResult *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"text\":");
  put_str(&b, r->text);
  som_buf_puts(&b, ",\"dropped\":");
  put_counts(&b, r->dropped);
  som_buf_puts(&b, ",\"unmarked\":");
  put_counts(&b, r->unmarked);
  som_buf_puts(&b, ",\"appended\":");
  put_counts(&b, r->appended);
  som_buf_puts(&b, ",\"marksDropped\":");
  som_buf_puti(&b, r->marks_dropped);
  som_buf_puts(&b, ",\"appendix\":[");
  for (size_t i = 0; i < r->appendix_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"number\":");
    som_buf_puti(&b, r->appendix[i].number);
    som_buf_puts(&b, ",\"kind\":");
    put_str(&b, r->appendix[i].kind);
    som_buf_puts(&b, ",\"text\":");
    put_str(&b, r->appendix[i].text);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"pieces\":[");
  for (size_t i = 0; i < r->pieces_len; i++) {
    const SpecStripPiece *pc = &r->pieces[i];
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"anchor\":");
    som_buf_puti(&b, (long long)pc->anchor);
    som_buf_puts(&b, ",\"origin\":");
    som_buf_puti(&b, (long long)pc->origin);
    som_buf_puts(&b, ",\"removed\":");
    put_str(&b, pc->removed);
    som_buf_puts(&b, ",\"inserted\":");
    put_str(&b, pc->inserted);
    som_buf_puts(&b, ",\"labels\":[");
    for (size_t k = 0; k < pc->labels.len; k++) {
      if (k > 0) som_buf_putc(&b, ',');
      put_str(&b, pc->labels.items[k]);
    }
    som_buf_puts(&b, "]}");
  }
  som_buf_puts(&b, "],\"refused\":[");
  for (size_t i = 0; i < r->refused.len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_str(&b, r->refused.items[i]);
  }
  som_buf_puts(&b, "]}");
  return som_buf_take(&b);
}
