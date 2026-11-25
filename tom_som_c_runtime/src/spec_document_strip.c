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
#include "spec_document_strip_internal.h"
#include "spec_schema_validation.h"
#include "spec_validator.h"

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
  SomStrList finding_texts; /* the same as `<code> (line N): <message>` */
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
  som_strlist_init(&p->finding_texts);
  som_strlist_init(&p->pool);
  SpecNotationScan scan;
  spec_scan_notation(o, 1, &scan);
  for (size_t i = 0; i < scan.findings_len; i++) {
    SpecNotationFindingCode c = scan.findings[i].code;
    if (strcmp(spec_notation_severity(c), "error") == 0 &&
        c != SPEC_NOTATION_REJECTED_BLOCK) {
      som_strlist_push_copy(&p->findings, spec_notation_finding_code_name(c));
      SomBuf ft;
      som_buf_init(&ft);
      som_buf_puts(&ft, spec_notation_finding_code_name(c));
      som_buf_puts(&ft, " (line ");
      som_buf_puti(&ft, (long long)scan.findings[i].line);
      som_buf_puts(&ft, "): ");
      som_buf_puts(&ft, scan.findings[i].message);
      som_strlist_push(&p->finding_texts, som_buf_take(&ft));
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
  som_strlist_free(&p->finding_texts);
  som_strlist_free(&p->pool);
}

/* Whether the plan changes its value (`_Plan.changes`). */
static int plan_changes(const Plan *p) {
  if (p->findings.len > 0) return 0;
  if (p->has_script1 || p->ins_len > 0) return 1;
  for (size_t i = 0; i < p->n; i++) {
    if (p->del[i] != NULL) return 1;
  }
  return 0;
}

static int str_cmp_ptr(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* The UTF-16 units a byte adds (0 for a continuation byte). */
static size_t u16_units(unsigned char c) {
  if ((c & 0xC0) == 0x80) return 0;
  return c >= 0xF0 ? 2 : 1;
}

/* Finishes the plan into `*out`, numbering appendix entry `k` as
 * `numbers[k]` (NULL: `k + 1`). */
static void plan_finish(Plan *p, const long long *numbers,
                        SpecStripTextResult *out) {
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
        long entry = p->ins[x].entry;
        char *num = som_format_i64(numbers != NULL ? numbers[entry]
                                                   : (long long)entry + 1);
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
      out->appendix[k].number = numbers != NULL ? numbers[k] : (long long)k + 1;
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
  plan_finish(&p, NULL, out);
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
    spec_strip_value_ref_free(r->appendix[i].value);
    free(r->appendix[i].value);
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

/* ======================================================================== */
/* The keeping options and the readable header (SOM §11.1)                   */
/* ======================================================================== */

SpecStripOptions spec_strip_options_keeping(const SpecStripOptions *o) {
  SpecStripOptions k;
  memset(&k, 0, sizeof(k));
  unsigned comments = 1u << K_COMMENTS;
  k.unmark = o->unmark | o->appendix | (o->drop & ~comments);
  k.drop = o->drop & comments;
  k.heading_divs = o->heading_divs;
  return k;
}

/* `,`-joined kind names of `set` in canonical order. */
static void put_kind_names(SomBuf *b, unsigned set) {
  int first = 1;
  for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
    if (!has_kind(set, k)) continue;
    if (!first) som_buf_putc(b, ',');
    first = 0;
    som_buf_puts(b, SPEC_STRIP_KIND_NAMES[k]);
  }
}

char *spec_readable_header_format(const SpecStripOptions *o,
                                  const SpecReadableSource *s) {
  SomStrList parts;
  som_strlist_init(&parts);
  const char *keys[3] = {"drop=", "unmark=", "appendix="};
  unsigned sets[3] = {o->drop, o->unmark, o->appendix};
  for (int i = 0; i < 3; i++) {
    if (sets[i] == 0) continue;
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, keys[i]);
    put_kind_names(&b, sets[i]);
    som_strlist_push(&parts, som_buf_take(&b));
  }
  if (o->appendix_references) som_strlist_push_copy(&parts, "appendix-references");
  if (o->heading_divs) som_strlist_push_copy(&parts, "headings=divs");
  if (s != NULL) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "of=");
    som_buf_puts(&b, s->file);
    if (s->revision != NULL) {
      som_buf_putc(&b, '@');
      som_buf_puts(&b, s->revision);
    }
    som_strlist_push(&parts, som_buf_take(&b));
    if (s->commit != NULL) {
      som_buf_init(&b);
      som_buf_puts(&b, "commit=");
      som_buf_puts(&b, s->commit);
      if (s->dirty) som_buf_puts(&b, "+dirty");
      som_strlist_push(&parts, som_buf_take(&b));
    }
  }
  SomBuf out;
  som_buf_init(&out);
  if (parts.len == 0) {
    som_buf_puts(&out, "<!-- readable: -->");
  } else {
    som_buf_puts(&out, "<!-- readable: ");
    for (size_t i = 0; i < parts.len; i++) {
      if (i > 0) som_buf_puts(&out, "; ");
      som_buf_puts(&out, parts.items[i]);
    }
    som_buf_puts(&out, " -->");
  }
  som_strlist_free(&parts);
  return som_buf_take(&out);
}

static int js_ws(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

/* `s[0..n)` trimmed of whitespace on both ends. Owned. */
static char *trim_n(const char *s, size_t n) {
  size_t a = 0;
  while (a < n && js_ws(s[a])) a++;
  while (n > a && js_ws(s[n - 1])) n--;
  return som_strdup_n(s + a, n - a);
}

int spec_readable_header_parse(const char *line, SpecReadableHeader *out) {
  memset(out, 0, sizeof(*out));
  char *t = trim_n(line, strlen(line));
  /* `^<!--\s*readable:(.*)-->$` */
  size_t n = strlen(t);
  const char *p = t;
  if (strncmp(p, "<!--", 4) != 0) {
    free(t);
    return 0;
  }
  p += 4;
  while (js_ws(*p)) p++;
  if (strncmp(p, "readable:", 9) != 0 || n < 3 ||
      strcmp(t + n - 3, "-->") != 0 || (size_t)(p + 9 - t) > n - 3) {
    free(t);
    return 0;
  }
  const char *body = p + 9;
  size_t body_len = (size_t)(t + n - 3 - body);
  SomStrList lists[3];
  for (int i = 0; i < 3; i++) som_strlist_init(&lists[i]);
  int refs = 0, divs = 0, dirty = 0, ok = 1;
  char *file = NULL, *revision = NULL, *commit = NULL;
  size_t start = 0;
  while (ok && start <= body_len) {
    size_t end = start;
    while (end < body_len && body[end] != ';') end++;
    char *part = trim_n(body + start, end - start);
    start = end + 1;
    if (part[0] == '\0') {
      free(part);
      continue;
    }
    char *eq = strchr(part, '=');
    char *key = eq == NULL ? som_strdup(part) : som_strdup_n(part, (size_t)(eq - part));
    const char *value = eq == NULL ? "" : eq + 1;
    if (strcmp(key, "drop") == 0) {
      som_strlist_push_copy(&lists[0], value);
    } else if (strcmp(key, "unmark") == 0) {
      som_strlist_push_copy(&lists[1], value);
    } else if (strcmp(key, "appendix") == 0) {
      som_strlist_push_copy(&lists[2], value);
    } else if (strcmp(key, "appendix-references") == 0 && eq == NULL) {
      refs = 1;
    } else if (strcmp(key, "headings") == 0 && strcmp(value, "divs") == 0) {
      divs = 1;
    } else if (strcmp(key, "of") == 0) {
      const char *at = strrchr(value, '@');
      free(file);
      free(revision);
      file = at == NULL ? som_strdup(value) : som_strdup_n(value, (size_t)(at - value));
      revision = at == NULL ? NULL : som_strdup(at + 1);
    } else if (strcmp(key, "commit") == 0) {
      size_t vl = strlen(value);
      free(commit);
      dirty = vl >= 6 && strcmp(value + vl - 6, "+dirty") == 0;
      commit = dirty ? som_strdup_n(value, vl - 6) : som_strdup(value);
    } else {
      ok = 0;
    }
    free(key);
    free(part);
  }
  free(t);
  if (ok && file == NULL && commit != NULL) ok = 0;
  if (ok) {
    char *err = NULL;
    ok = spec_strip_options_from_names(&lists[0], &lists[1], &lists[2], refs,
                                       divs, &out->options, &err);
    free(err);
  }
  for (int i = 0; i < 3; i++) som_strlist_free(&lists[i]);
  if (ok && file != NULL) {
    out->source = calloc(1, sizeof(SpecReadableSource));
    out->source->file = file;
    out->source->revision = revision;
    out->source->commit = commit;
    out->source->dirty = dirty;
    return 1;
  }
  free(file);
  free(revision);
  free(commit);
  if (!ok) memset(out, 0, sizeof(*out));
  return ok;
}

void spec_readable_header_free(SpecReadableHeader *h) {
  if (h == NULL) return;
  if (h->source != NULL) {
    free(h->source->file);
    free(h->source->revision);
    free(h->source->commit);
    free(h->source);
  }
  memset(h, 0, sizeof(*h));
}

/* ======================================================================== */
/* Value references                                                          */
/* ======================================================================== */

const char *spec_strip_value_ref_read(const SpecStripValueRef *ref,
                                      const SpecDocument *doc) {
  const char *v = ref->headline ? spec_document_headline(doc, ref->path)
                  : ref->field != NULL
                      ? spec_document_form_field(doc, ref->path, ref->field)
                      : spec_document_content(doc, ref->path);
  return v != NULL ? v : "";
}

void spec_strip_value_ref_write(const SpecStripValueRef *ref, SpecDocument *doc,
                                const char *value) {
  if (ref->headline) {
    spec_document_set_headline(doc, ref->path, value);
  } else if (ref->field != NULL) {
    spec_document_set_form_field(doc, ref->path, ref->field, value);
  } else {
    spec_document_set_content(doc, ref->path, value);
  }
}

char *spec_strip_value_ref_label(const SpecStripValueRef *ref) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, ref->path);
  if (ref->headline) {
    som_buf_puts(&b, " (headline)");
  } else if (ref->field != NULL) {
    som_buf_putc(&b, '/');
    som_buf_puts(&b, ref->field);
  }
  return som_buf_take(&b);
}

static void put_ref(SomBuf *b, const SpecStripValueRef *ref) {
  som_buf_puts(b, "{\"path\":");
  put_str(b, ref->path);
  if (ref->field != NULL) {
    som_buf_puts(b, ",\"field\":");
    put_str(b, ref->field);
  }
  if (ref->headline) som_buf_puts(b, ",\"headline\":true");
  som_buf_putc(b, '}');
}

char *spec_strip_value_ref_to_json(const SpecStripValueRef *ref) {
  SomBuf b;
  som_buf_init(&b);
  put_ref(&b, ref);
  return som_buf_take(&b);
}

void spec_strip_value_ref_free(SpecStripValueRef *ref) {
  if (ref == NULL) return;
  free(ref->path);
  free(ref->field);
  ref->path = NULL;
  ref->field = NULL;
}

static SpecStripValueRef ref_copy(const SpecStripValueRef *r) {
  SpecStripValueRef c;
  c.path = som_strdup(r->path);
  c.field = r->field != NULL ? som_strdup(r->field) : NULL;
  c.headline = r->headline;
  return c;
}

static SpecStripValueRef *ref_heap(const SpecStripValueRef *r) {
  SpecStripValueRef *h = malloc(sizeof(SpecStripValueRef));
  *h = ref_copy(r);
  return h;
}

/* ======================================================================== */
/* The strip of a document (SOM §11.10)                                      */
/* ======================================================================== */

static void kp_init(KeyPaths *m) {
  som_strlist_init(&m->keys);
  som_strlist_init(&m->paths);
}

static void kp_free(KeyPaths *m) {
  som_strlist_free(&m->keys);
  som_strlist_free(&m->paths);
}

static long kp_find(const KeyPaths *m, const char *key) {
  for (size_t i = 0; i < m->keys.len; i++) {
    if (strcmp(m->keys.items[i], key) == 0) return (long)i;
  }
  return -1;
}

static void kp_set(KeyPaths *m, char *key, const char *path) {
  long at = kp_find(m, key);
  if (at >= 0) {
    free(m->paths.items[at]);
    m->paths.items[at] = som_strdup(path);
    free(key);
    return;
  }
  som_strlist_push(&m->keys, key);
  som_strlist_push_copy(&m->paths, path);
}

static SpecDocument *doc_copy(const SpecDocument *d) {
  SpecDocument *c = malloc(sizeof(SpecDocument));
  spec_document_init(c);
  DocumentJson j;
  spec_document_to_json(d, &j);
  spec_document_load_json(c, &j);
  document_json_free(&j);
  return c;
}

static void doc_release(SpecDocument *d) {
  if (d == NULL) return;
  spec_document_free(d);
  free(d);
}

static int str_cmp_items(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void sort_list(SomStrList *l) {
  if (l->len > 1) qsort(l->items, l->len, sizeof(char *), str_cmp_items);
}

static int blank(const char *s) {
  for (; *s != '\0'; s++) {
    if (!js_ws(*s)) return 0;
  }
  return 1;
}

/* The instance tier's and (given a schema) the schema tier's findings of
 * `doc`, keyed as `instance <code> <path>: <message>` / `schema <rule>
 * <section id>: <message>`, each with the path it concerns. */
static void tier_findings(const SpecModel *model, const DocSpecsSchema *schema,
                          const char *root_type, const SpecDocument *doc,
                          KeyPaths *out) {
  kp_init(out);
  SpecValidationErrors errs;
  validate_document(model, doc, &errs);
  for (size_t i = 0; i < errs.len; i++) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "instance ");
    som_buf_puts(&b, errs.items[i].code);
    som_buf_putc(&b, ' ');
    som_buf_puts(&b, errs.items[i].path);
    som_buf_puts(&b, ": ");
    som_buf_puts(&b, errs.items[i].message);
    kp_set(out, som_buf_take(&b), errs.items[i].path);
  }
  spec_validation_errors_free(&errs);
  if (schema == NULL) return;
  DocSpecsViolationList vl;
  docspecs_violation_list_init(&vl);
  char *err = NULL;
  /* No single root to render: the schema tier cannot judge it. */
  if (validate_spec_document(model, doc, schema, root_type, &vl, &err)) {
    for (size_t i = 0; i < vl.len; i++) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "schema ");
      som_buf_puts(&b, vl.items[i].rule);
      som_buf_putc(&b, ' ');
      som_buf_puts(&b, vl.items[i].section_id);
      som_buf_puts(&b, ": ");
      som_buf_puts(&b, vl.items[i].message);
      kp_set(out, som_buf_take(&b), vl.items[i].path);
    }
  }
  free(err);
  docspecs_violation_list_free(&vl);
}

static int starts_with_sep(const char *s, const char *prefix, char sep) {
  size_t n = strlen(prefix);
  return strncmp(s, prefix, n) == 0 && s[n] == sep;
}

/* Whether a finding at `finding_path` concerns `path`. */
static int concerns(const char *finding_path, const char *path) {
  return finding_path[0] == '\0' || strcmp(path, finding_path) == 0 ||
         starts_with_sep(path, finding_path, '/') ||
         starts_with_sep(path, finding_path, '-') ||
         starts_with_sep(finding_path, path, '/');
}

/* The state of one strip of a document. */
typedef struct {
  const SpecDocument *document;
  SpecDocument *copy;
  const SpecStripOptions *options;
  SpecStripValueRef *refs;
  size_t refs_len;
  char **originals;  /* per ref: its original value (owned) */
  Plan *plans;       /* per ref, valid where `planned` */
  int *planned;
  long long **numbers; /* per planned ref: its entries' numbers */
} Strip;

static void strip_set_numbers(Strip *s, size_t index) {
  free(s->numbers[index]);
  size_t n = s->plans[index].entry_kinds.len;
  s->numbers[index] = n > 0 ? calloc(n, sizeof(long long)) : NULL;
}

static void strip_apply(Strip *s) {
  for (size_t i = 0; i < s->refs_len; i++) {
    if (!s->planned[i]) continue;
    SpecStripTextResult r;
    plan_finish(&s->plans[i], s->numbers[i], &r);
    spec_strip_value_ref_write(&s->refs[i], s->copy, r.text);
    spec_strip_text_result_free(&r);
  }
}

/* The list items that are, or hold, a planned value. Sorted. */
static void items_above(Strip *s, SomStrList *out) {
  som_strlist_init(out);
  SomStrList items;
  som_strlist_init(&items);
  SomStrList lists;
  spec_document_list_paths(s->copy, &lists);
  for (size_t i = 0; i < lists.len; i++) {
    const SomStrList *it = spec_document_list_items(s->copy, lists.items[i]);
    for (size_t k = 0; it != NULL && k < it->len; k++) {
      if (!som_strlist_contains(&items, it->items[k])) {
        som_strlist_push_copy(&items, it->items[k]);
      }
    }
  }
  som_strlist_free(&lists);
  for (size_t r = 0; r < s->refs_len; r++) {
    if (!s->planned[r]) continue;
    const char *p = s->refs[r].path;
    if (som_strlist_contains(&items, p) && !som_strlist_contains(out, p)) {
      som_strlist_push_copy(out, p);
    }
    for (size_t i = 0; p[i] != '\0'; i++) {
      if (p[i] != '/') continue;
      char *pre = som_strdup_n(p, i);
      if (som_strlist_contains(&items, pre) && !som_strlist_contains(out, pre)) {
        som_strlist_push(out, pre);
      } else {
        free(pre);
      }
    }
  }
  som_strlist_free(&items);
  sort_list(out);
}

static void emptied_items(Strip *s, const SomStrList *candidates,
                          const SomStrList *keep, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < candidates->len; i++) {
    const char *item = candidates->items[i];
    if (!som_strlist_contains(keep, item) &&
        spec_document_has_values_under(s->document, item) &&
        !spec_document_has_values_under(s->copy, item)) {
      som_strlist_push_copy(out, item);
    }
  }
}

/* The emptying rule: a value whose strip adds an instance or schema finding
 * is stripped with the keeping options instead (or keeps its original when
 * even that empties it), and a list item it would empty stays; then the list
 * items left with nothing are removed and written into `removed`. */
static void emptying_rule(Strip *s, const SpecModel *model,
                          const DocSpecsSchema *schema, const char *root_type,
                          const KeyPaths *base, SpecStripKept **kept,
                          size_t *kept_len, SomStrList *removed) {
  int *kept_refs = calloc(s->refs_len + 1, sizeof(int));
  SomStrList keep_items;
  som_strlist_init(&keep_items);
  SomStrList candidates;
  items_above(s, &candidates);
  SpecStripOptions keeping = spec_strip_options_keeping(s->options);
  size_t kept_cap = 0;
  for (int round = 0; round < 8; round++) {
    SomStrList items;
    emptied_items(s, &candidates, &keep_items, &items);
    SpecDocument *scratch = s->copy;
    if (items.len > 0) {
      scratch = doc_copy(s->copy);
      for (size_t i = 0; i < items.len; i++) {
        spec_document_remove_list_item(scratch, items.items[i]);
      }
    }
    KeyPaths now;
    tier_findings(model, schema, root_type, scratch, &now);
    if (scratch != s->copy) doc_release(scratch);
    KeyPaths added;
    kp_init(&added);
    for (size_t i = 0; i < now.keys.len; i++) {
      if (kp_find(base, now.keys.items[i]) < 0) {
        som_strlist_push_copy(&added.keys, now.keys.items[i]);
        som_strlist_push_copy(&added.paths, now.paths.items[i]);
      }
    }
    kp_free(&now);
    if (added.keys.len == 0) {
      kp_free(&added);
      som_strlist_free(&items);
      break;
    }
    size_t *emptied = calloc(s->refs_len + 1, sizeof(size_t));
    size_t emptied_len = 0;
    for (size_t i = 0; i < s->refs_len; i++) {
      if (s->planned[i] && !kept_refs[i] &&
          blank(spec_strip_value_ref_read(&s->refs[i], s->copy))) {
        emptied[emptied_len++] = i;
      }
    }
    int changed = 0;
    for (size_t a = 0; a < added.keys.len; a++) {
      const char *key = added.keys.items[a];
      const char *finding_path = added.paths.items[a];
      for (size_t i = 0; i < items.len; i++) {
        if (concerns(finding_path, items.items[i]) &&
            !som_strlist_contains(&keep_items, items.items[i])) {
          som_strlist_push_copy(&keep_items, items.items[i]);
          changed = 1;
        }
      }
      for (size_t e = 0; e < emptied_len; e++) {
        size_t index = emptied[e];
        const SpecStripValueRef *ref = &s->refs[index];
        if (kept_refs[index] || !concerns(finding_path, ref->path)) continue;
        kept_refs[index] = 1;
        if (*kept_len == kept_cap) {
          kept_cap = kept_cap ? kept_cap * 2 : 4;
          *kept = realloc(*kept, kept_cap * sizeof(SpecStripKept));
        }
        (*kept)[*kept_len].ref = ref_copy(ref);
        (*kept)[*kept_len].finding = som_strdup(key);
        (*kept_len)++;
        Plan k;
        plan_init(&k, s->originals[index], &keeping);
        SpecStripTextResult r;
        plan_finish(&k, NULL, &r);
        plan_free(&s->plans[index]);
        if (blank(r.text)) {
          plan_free(&k);
          s->planned[index] = 0;
          spec_strip_value_ref_write(ref, s->copy, s->originals[index]);
        } else {
          s->plans[index] = k;
          strip_set_numbers(s, index);
          spec_strip_value_ref_write(ref, s->copy, r.text);
        }
        spec_strip_text_result_free(&r);
        changed = 1;
      }
    }
    free(emptied);
    kp_free(&added);
    som_strlist_free(&items);
    if (!changed) break;
  }
  SomStrList items;
  emptied_items(s, &candidates, &keep_items, &items);
  for (size_t i = 0; i < items.len; i++) {
    spec_document_remove_list_item(s->copy, items.items[i]);
    som_strlist_push_copy(removed, items.items[i]);
  }
  som_strlist_free(&items);
  som_strlist_free(&candidates);
  som_strlist_free(&keep_items);
  free(kept_refs);
}

static void push_finding(SpecStripResult *out, size_t *cap, const char *kind,
                         char *message, const SpecStripValueRef *ref) {
  if (out->findings_len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    out->findings = realloc(out->findings, *cap * sizeof(SpecStripFinding));
  }
  SpecStripFinding *f = &out->findings[out->findings_len++];
  f->kind = som_strdup(kind);
  f->message = message;
  f->ref = ref != NULL ? ref_heap(ref) : NULL;
}

/* The heading of the rendition a value stands under: titles keyed by path,
 * in rendition order. */
typedef struct {
  SomStrList paths;
  SomStrList titles;
  int *lines;
} Headings;

static void headings_from(const SpecMarkdownRendition *r, Headings *h) {
  som_strlist_init(&h->paths);
  som_strlist_init(&h->titles);
  h->lines = r->headings_len > 0 ? calloc(r->headings_len, sizeof(int)) : NULL;
  /* Index the rendition's lines once. */
  size_t cap = 64, n = 0;
  const char **starts = malloc(cap * sizeof(char *));
  const char *p = r->markdown;
  starts[n++] = p;
  for (; *p != '\0'; p++) {
    if (*p == '\n') {
      if (n == cap) {
        cap *= 2;
        starts = realloc(starts, cap * sizeof(char *));
      }
      starts[n++] = p + 1;
    }
  }
  for (size_t i = 0; i < r->headings_len; i++) {
    int line = r->headings[i].line;
    char *text = NULL;
    if (line >= 1 && (size_t)line <= n) {
      const char *a = starts[line - 1];
      const char *e = strchr(a, '\n');
      text = e != NULL ? som_strdup_n(a, (size_t)(e - a)) : som_strdup(a);
    } else {
      text = som_strdup("");
    }
    long at = -1;
    for (size_t k = 0; k < h->paths.len; k++) {
      if (strcmp(h->paths.items[k], r->headings[i].path) == 0) at = (long)k;
    }
    char *title = spec_markdown_heading_title(text);
    free(text);
    if (at >= 0) {
      free(h->titles.items[at]);
      h->titles.items[at] = title;
      h->lines[at] = line;
    } else {
      h->lines[h->paths.len] = line;
      som_strlist_push_copy(&h->paths, r->headings[i].path);
      som_strlist_push(&h->titles, title);
    }
  }
  free(starts);
}

static void headings_free(Headings *h) {
  som_strlist_free(&h->paths);
  som_strlist_free(&h->titles);
  free(h->lines);
  h->lines = NULL;
}

/* The index of the longest heading path that is `path` or above it, or -1. */
static long headings_section(const Headings *h, const char *path) {
  long best = -1;
  size_t best_len = 0;
  for (size_t k = 0; k < h->paths.len; k++) {
    const char *p = h->paths.items[k];
    size_t pl = strlen(p);
    if ((strcmp(path, p) == 0 || starts_with_sep(path, p, '/')) &&
        (best < 0 || pl > best_len)) {
      best = (long)k;
      best_len = pl;
    }
  }
  return best;
}

typedef struct {
  size_t index;
  size_t entry;
  int line;
} EntryAt;

static int entry_cmp(const void *a, const void *b) {
  const EntryAt *x = a, *y = b;
  if (x->line != y->line) return x->line < y->line ? -1 : 1;
  if (x->index != y->index) return x->index < y->index ? -1 : 1;
  return x->entry < y->entry ? -1 : x->entry > y->entry ? 1 : 0;
}

static int appendix_cmp(const void *a, const void *b) {
  const SpecAppendixEntry *x = a, *y = b;
  return x->number < y->number ? -1 : x->number > y->number ? 1 : 0;
}

/* The rendition with the appendix *Notes* after its marker. Owned. */
static char *with_appendix(const char *markdown, const SpecAppendixEntry *entries,
                           size_t n, const Headings *titles, int references) {
  SomBuf b;
  som_buf_init(&b);
  size_t len = strlen(markdown);
  while (len > 0 && markdown[len - 1] == '\n') len--;
  som_buf_putn(&b, markdown, len);
  som_buf_puts(&b, "\n\n" SPEC_MARKDOWN_APPENDIX_MARKER "\n\n## Notes\n");
  char *section = NULL;
  for (size_t i = 0; i < n; i++) {
    const SpecAppendixEntry *e = &entries[i];
    const char *path = "", *title = "";
    if (e->value != NULL) {
      long k = headings_section(titles, e->value->path);
      path = k >= 0 ? titles->paths.items[k] : e->value->path;
      title = k >= 0 ? titles->titles.items[k] : e->value->path;
    }
    if (section == NULL || strcmp(path, section) != 0) {
      som_buf_puts(&b, "\n### ");
      som_buf_puts(&b, title);
      som_buf_putc(&b, '\n');
      free(section);
      section = som_strdup(path);
    }
    SomBuf text;
    som_buf_init(&text);
    const char *line = e->text;
    for (;;) {
      if (line[0] == '#') som_buf_putc(&text, '\\');
      const char *nl = strchr(line, '\n');
      if (nl == NULL) {
        som_buf_puts(&text, line);
        break;
      }
      som_buf_putn(&text, line, (size_t)(nl - line) + 1);
      line = nl + 1;
    }
    char *t = som_buf_take(&text);
    char *num = som_format_i64(e->number);
    if (references) {
      som_buf_puts(&b, "\n<a id=\"note-");
      som_buf_puts(&b, num);
      som_buf_puts(&b, "\"></a>**[");
      som_buf_puts(&b, num);
      som_buf_puts(&b, "]** ");
      som_buf_puts(&b, t);
      som_buf_puts(&b, " [\xe2\x86\xa9](#note-");
      som_buf_puts(&b, num);
      som_buf_puts(&b, "-ref)\n");
    } else {
      som_buf_puts(&b, "\n**[");
      som_buf_puts(&b, num);
      som_buf_puts(&b, "]** ");
      som_buf_puts(&b, t);
      som_buf_putc(&b, '\n');
    }
    free(num);
    free(t);
  }
  free(section);
  return som_buf_take(&b);
}


/* `a` + `b` + `c`. Owned. */
static char *join3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

static int in_root(const char *prefix, const char *p) {
  return strcmp(p, prefix) == 0 || starts_with_sep(p, prefix, '/');
}

/* Compares what the rendition reads back as (`got`) with what the stripped
 * document holds (`want`), both keyed by path, under the root. */
static void compare_read_back(const char *what, const char *prefix,
                              const SomMap *want, const SomMap *got,
                              SpecStripResult *out, size_t *cap) {
  SomStrList keys;
  som_strlist_init(&keys);
  for (size_t i = 0; i < want->len; i++) som_strlist_push_copy(&keys, want->entries[i].key);
  for (size_t i = 0; i < got->len; i++) {
    if (!som_strlist_contains(&keys, got->entries[i].key)) {
      som_strlist_push_copy(&keys, got->entries[i].key);
    }
  }
  sort_list(&keys);
  for (size_t i = 0; i < keys.len; i++) {
    const char *k = keys.items[i];
    if (!in_root(prefix, k)) continue;
    const char *w = som_map_get(want, k);
    const char *g = som_map_get(got, k);
    if (w != NULL && g != NULL && strcmp(w, g) == 0) continue;
    /* A wrapped paragraph written in a table cell reads back on one line
     * (SOM §11.4). */
    if (w != NULL && g != NULL) {
      char *joined = spec_markdown_wrapped_paragraph_joined(w);
      int same = joined != NULL && strcmp(joined, g) == 0;
      free(joined);
      if (same) continue;
    }
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, what);
    som_buf_puts(&b, " at ");
    som_buf_puts(&b, k);
    som_buf_puts(&b, " reads back as ");
    if (g == NULL) {
      som_buf_puts(&b, "nothing");
    } else {
      som_buf_putc(&b, '"');
      som_buf_puts(&b, g);
      som_buf_putc(&b, '"');
    }
    som_buf_puts(&b, " instead of ");
    if (w == NULL) {
      som_buf_puts(&b, "nothing");
    } else {
      som_buf_putc(&b, '"');
      som_buf_puts(&b, w);
      som_buf_putc(&b, '"');
    }
    push_finding(out, cap, "parse", som_buf_take(&b), NULL);
  }
  som_strlist_free(&keys);
}

static char *violation_key(const DocSpecsViolation *v) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, v->rule);
  som_buf_putc(&b, ' ');
  som_buf_puts(&b, v->section_id);
  som_buf_puts(&b, ": ");
  som_buf_puts(&b, v->message);
  return som_buf_take(&b);
}

/* The readable rendition reads back as the stripped document, and neither
 * it nor the stripped document adds a finding. */
static void check_output(const SpecModel *model, const DocSpecsSchema *schema,
                         const SpecRoot *root, const char *root_type,
                         const KeyPaths *before, const SpecDocument *document,
                         const SpecDocument *copy, const char *readable,
                         SpecStripResult *out, size_t *cap) {
  SpecMarkdownResult parsed;
  spec_markdown_parse(model, readable, &parsed);
  for (size_t i = 0; i < parsed.rejections_len; i++) {
    char *d = spec_markdown_rejection_display(&parsed.rejections[i]);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "the rendition rejects: ");
    som_buf_puts(&b, d);
    free(d);
    push_finding(out, cap, "parse", som_buf_take(&b), NULL);
  }
  const char *prefix = root->section_id != NULL && root->section_id[0] != '\0'
                           ? root->section_id
                           : root->type;
  SomMap want, got;
  som_map_init(&want);
  som_map_init(&got);
  SomStrList paths;
  spec_document_content_paths(copy, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    som_map_set(&want, paths.items[i], spec_document_content(copy, paths.items[i]));
  }
  som_strlist_free(&paths);
  compare_read_back("content", prefix, &want, &parsed.staged.content, out, cap);
  som_map_clear(&want);
  spec_document_form_paths(copy, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList fields;
    spec_document_form_field_names(copy, paths.items[i], &fields);
    for (size_t f = 0; f < fields.len; f++) {
      char *key = join3(paths.items[i], "/", fields.items[f]);
      som_map_set(&want, key,
                  spec_document_form_field(copy, paths.items[i], fields.items[f]));
      free(key);
    }
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
  for (size_t i = 0; i < parsed.staged.forms_len; i++) {
    const DocFormEntry *fe = &parsed.staged.forms[i];
    for (size_t f = 0; f < fe->fields.len; f++) {
      char *key = join3(fe->key, "/", fe->fields.entries[f].key);
      som_map_set(&got, key, fe->fields.entries[f].val);
      free(key);
    }
  }
  compare_read_back("the form field", prefix, &want, &got, out, cap);
  som_map_free(&want);
  som_map_free(&got);
  spec_markdown_result_free(&parsed);

  KeyPaths after;
  tier_findings(model, schema, root_type, copy, &after);
  for (size_t i = 0; i < after.keys.len; i++) {
    const char *key = after.keys.items[i];
    if (kp_find(before, key) >= 0) continue;
    push_finding(out, cap, strncmp(key, "schema", 6) == 0 ? "schema" : "instance",
                 som_strdup(key), NULL);
  }
  kp_free(&after);
  if (schema == NULL) return;
  char *err = NULL;
  char *original = spec_markdown_export_root(model, document, root, &err);
  free(err);
  if (original == NULL) return;
  DocSpecsValidator val = docspecs_validator_new_with(schema, 1);
  DocSpecsViolationList had, now;
  docspecs_violation_list_init(&had);
  docspecs_violation_list_init(&now);
  docspecs_validator_validate_markdown(&val, original, &had);
  docspecs_validator_validate_markdown(&val, readable, &now);
  SomStrList had_keys;
  som_strlist_init(&had_keys);
  for (size_t i = 0; i < had.len; i++) som_strlist_push(&had_keys, violation_key(&had.items[i]));
  for (size_t i = 0; i < now.len; i++) {
    char *k = violation_key(&now.items[i]);
    if (!som_strlist_contains(&had_keys, k)) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "the rendition: line ");
      som_buf_puti(&b, (long long)now.items[i].line);
      som_buf_puts(&b, ": ");
      som_buf_puts(&b, k);
      push_finding(out, cap, "schema", som_buf_take(&b), NULL);
    }
    free(k);
  }
  som_strlist_free(&had_keys);
  docspecs_violation_list_free(&had);
  docspecs_violation_list_free(&now);
  free(original);
}

/* Every value of `doc`: stored headlines, content, form fields, each group
 * sorted. */
static void value_refs(const SpecDocument *doc, SpecStripValueRef **out,
                       size_t *out_len) {
  size_t cap = 16, n = 0;
  SpecStripValueRef *refs = malloc(cap * sizeof(SpecStripValueRef));
#define PUSH_REF(P, F, H)                                          \
  do {                                                             \
    if (n == cap) {                                                \
      cap *= 2;                                                    \
      refs = realloc(refs, cap * sizeof(SpecStripValueRef));       \
    }                                                              \
    refs[n].path = som_strdup(P);                                  \
    refs[n].field = (F) != NULL ? som_strdup(F) : NULL;            \
    refs[n].headline = (H);                                        \
    n++;                                                           \
  } while (0)
  SomStrList paths;
  spec_document_headline_paths(doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) PUSH_REF(paths.items[i], (const char *)NULL, 1);
  som_strlist_free(&paths);
  spec_document_content_paths(doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) PUSH_REF(paths.items[i], (const char *)NULL, 0);
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  sort_list(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList fields;
    spec_document_form_field_names(doc, paths.items[i], &fields);
    sort_list(&fields);
    for (size_t f = 0; f < fields.len; f++) PUSH_REF(paths.items[i], fields.items[f], 0);
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
#undef PUSH_REF
  *out = refs;
  *out_len = n;
}

void spec_document_strip(const SpecDocument *document,
                         const SpecStripOptions *options,
                         const SpecDocumentStripOptions *extra,
                         SpecStripResult *out) {
  memset(out, 0, sizeof(*out));
  som_strlist_init(&out->removed_items);
  const SpecModel *model = extra != NULL ? extra->model : NULL;
  const DocSpecsSchema *schema = extra != NULL ? extra->schema : NULL;
  const char *root_type = extra != NULL ? extra->root_type : NULL;
  const SpecReadableSource *source = extra != NULL ? extra->source : NULL;
  size_t findings_cap = 0;

  Strip s;
  memset(&s, 0, sizeof(s));
  s.document = document;
  s.options = options;
  value_refs(document, &s.refs, &s.refs_len);
  size_t nr = s.refs_len + 1;
  s.originals = calloc(nr, sizeof(char *));
  s.plans = calloc(nr, sizeof(Plan));
  s.planned = calloc(nr, sizeof(int));
  s.numbers = calloc(nr, sizeof(long long *));
  for (size_t i = 0; i < s.refs_len; i++) {
    const char *text = spec_strip_value_ref_read(&s.refs[i], document);
    if (text[0] == '\0') continue;
    s.originals[i] = som_strdup(text);
    plan_init(&s.plans[i], s.originals[i], options);
    if (s.plans[i].findings.len > 0) {
      for (size_t f = 0; f < s.plans[i].finding_texts.len; f++) {
        push_finding(out, &findings_cap, "notation",
                     som_strdup(s.plans[i].finding_texts.items[f]), &s.refs[i]);
      }
      plan_free(&s.plans[i]);
      continue;
    }
    if (plan_changes(&s.plans[i])) {
      s.planned[i] = 1;
    } else {
      plan_free(&s.plans[i]);
    }
  }

  s.copy = doc_copy(document);
  long long next = 1;
  for (size_t i = 0; i < s.refs_len; i++) {
    if (!s.planned[i]) continue;
    strip_set_numbers(&s, i);
    for (size_t k = 0; k < s.plans[i].entry_kinds.len; k++) s.numbers[i][k] = next++;
  }
  strip_apply(&s);
  KeyPaths base;
  kp_init(&base);
  size_t kept_len = 0;
  if (model != NULL) {
    kp_free(&base);
    tier_findings(model, schema, root_type, document, &base);
    emptying_rule(&s, model, schema, root_type, &base, &out->kept, &kept_len,
                  &out->removed_items);
  }
  out->kept_len = kept_len;

  /* The appendix, numbered through the rendition. */
  size_t entries_len = 0;
  for (size_t i = 0; i < s.refs_len; i++) {
    if (s.planned[i]) entries_len += s.plans[i].entry_kinds.len;
  }
  EntryAt *entries = calloc(entries_len + 1, sizeof(EntryAt));
  size_t e = 0;
  for (size_t i = 0; i < s.refs_len; i++) {
    if (!s.planned[i]) continue;
    for (size_t k = 0; k < s.plans[i].entry_kinds.len; k++) {
      entries[e].index = i;
      entries[e].entry = k;
      e++;
    }
  }
  const SpecRoot *root = NULL;
  if (model != NULL) {
    char *err = NULL;
    root = spec_document_root_to_export(model, s.copy, root_type, &err);
    if (root == NULL) {
      push_finding(out, &findings_cap, "parse",
                   som_strdup(err != NULL ? err : "no root to export"), NULL);
    }
    free(err);
  }
  Headings titles;
  memset(&titles, 0, sizeof(titles));
  som_strlist_init(&titles.paths);
  som_strlist_init(&titles.titles);
  if (entries_len > 0 && root != NULL) {
    SpecMarkdownRendition map;
    char *err = NULL;
    if (spec_markdown_export_root_with_map(model, s.copy, root, &map, &err)) {
      headings_free(&titles);
      headings_from(&map, &titles);
      for (size_t k = 0; k < entries_len; k++) {
        long sec = headings_section(&titles, s.refs[entries[k].index].path);
        entries[k].line = sec >= 0 ? titles.lines[sec] : 0;
      }
      qsort(entries, entries_len, sizeof(EntryAt), entry_cmp);
      spec_markdown_rendition_free(&map);
    } else {
      push_finding(out, &findings_cap, "parse",
                   som_strdup(err != NULL ? err : "the document does not render"),
                   NULL);
    }
    free(err);
  }
  for (size_t k = 0; k < entries_len; k++) {
    s.numbers[entries[k].index][entries[k].entry] = (long long)k + 1;
  }
  free(entries);
  strip_apply(&s);

  size_t values_cap = 0, appendix_cap = 0;
  for (size_t i = 0; i < s.refs_len; i++) {
    if (!s.planned[i]) continue;
    SpecStripTextResult r;
    plan_finish(&s.plans[i], s.numbers[i], &r);
    if (out->values_len == values_cap) {
      values_cap = values_cap ? values_cap * 2 : 8;
      out->values = realloc(out->values, values_cap * sizeof(SpecStrippedValue));
    }
    SpecStrippedValue *v = &out->values[out->values_len++];
    v->ref = ref_copy(&s.refs[i]);
    v->original = som_strdup(s.originals[i]);
    v->stripped = r.text;
    v->pieces = r.pieces;
    v->pieces_len = r.pieces_len;
    r.text = NULL;
    r.pieces = NULL;
    r.pieces_len = 0;
    for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
      out->dropped[k] += r.dropped[k];
      out->unmarked[k] += r.unmarked[k];
      out->appended[k] += r.appended[k];
    }
    out->marks_dropped += r.marks_dropped;
    for (size_t k = 0; k < r.appendix_len; k++) {
      if (out->appendix_len == appendix_cap) {
        appendix_cap = appendix_cap ? appendix_cap * 2 : 8;
        out->appendix =
            realloc(out->appendix, appendix_cap * sizeof(SpecAppendixEntry));
      }
      SpecAppendixEntry *a = &out->appendix[out->appendix_len++];
      a->number = r.appendix[k].number;
      a->kind = r.appendix[k].kind;
      a->text = r.appendix[k].text;
      a->value = ref_heap(&s.refs[i]);
      r.appendix[k].kind = NULL;
      r.appendix[k].text = NULL;
    }
    spec_strip_text_result_free(&r);
  }
  if (out->appendix_len > 1) {
    qsort(out->appendix, out->appendix_len, sizeof(SpecAppendixEntry),
          appendix_cmp);
  }

  out->readable_header = spec_readable_header_format(options, source);
  if (root != NULL) {
    SpecMarkdownExportOptions mo;
    mo.heading_divs = options->heading_divs;
    mo.readable_header = out->readable_header;
    SpecMarkdownRendition rendition;
    char *err = NULL;
    if (spec_markdown_export_root_with_options(model, s.copy, root, &mo,
                                               &rendition, &err)) {
      if (titles.paths.len == 0 && out->appendix_len > 0) {
        headings_free(&titles);
        headings_from(&rendition, &titles);
      }
      out->readable =
          out->appendix_len == 0
              ? som_strdup(rendition.markdown)
              : with_appendix(rendition.markdown, out->appendix,
                              out->appendix_len, &titles,
                              options->appendix_references);
      spec_markdown_rendition_free(&rendition);
      check_output(model, schema, root, root_type, &base, document, s.copy,
                   out->readable, out, &findings_cap);
    } else {
      push_finding(out, &findings_cap, "parse",
                   som_strdup(err != NULL ? err : "the document does not render"),
                   NULL);
    }
    free(err);
  }
  headings_free(&titles);
  kp_free(&base);

  out->document = s.copy;
  for (size_t i = 0; i < s.refs_len; i++) {
    if (s.planned[i]) plan_free(&s.plans[i]);
    free(s.originals[i]);
    free(s.numbers[i]);
    spec_strip_value_ref_free(&s.refs[i]);
  }
  free(s.refs);
  free(s.originals);
  free(s.plans);
  free(s.planned);
  free(s.numbers);
}

void spec_strip_result_free(SpecStripResult *r) {
  if (r == NULL) return;
  doc_release(r->document);
  for (size_t i = 0; i < r->values_len; i++) {
    SpecStrippedValue *v = &r->values[i];
    spec_strip_value_ref_free(&v->ref);
    free(v->original);
    free(v->stripped);
    for (size_t k = 0; k < v->pieces_len; k++) {
      free(v->pieces[k].removed);
      free(v->pieces[k].inserted);
      som_strlist_free(&v->pieces[k].labels);
    }
    free(v->pieces);
  }
  free(r->values);
  for (size_t i = 0; i < r->kept_len; i++) {
    spec_strip_value_ref_free(&r->kept[i].ref);
    free(r->kept[i].finding);
  }
  free(r->kept);
  som_strlist_free(&r->removed_items);
  for (size_t i = 0; i < r->appendix_len; i++) {
    free(r->appendix[i].kind);
    free(r->appendix[i].text);
    spec_strip_value_ref_free(r->appendix[i].value);
    free(r->appendix[i].value);
  }
  free(r->appendix);
  free(r->readable_header);
  free(r->readable);
  for (size_t i = 0; i < r->findings_len; i++) {
    free(r->findings[i].kind);
    free(r->findings[i].message);
    spec_strip_value_ref_free(r->findings[i].ref);
    free(r->findings[i].ref);
  }
  free(r->findings);
  memset(r, 0, sizeof(*r));
}

int spec_strip_result_ok(const SpecStripResult *r) {
  return r->findings_len == 0;
}

void spec_strip_result_report(const SpecStripResult *r, SomStrList *out) {
  som_strlist_init(out);
  for (int k = 0; k < SPEC_STRIP_KIND_COUNT; k++) {
    long long d = r->dropped[k], u = r->unmarked[k], a = r->appended[k];
    if (d + u + a <= 0) continue;
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, SPEC_STRIP_KIND_NAMES[k]);
    som_buf_puts(&b, ": ");
    som_buf_puti(&b, d);
    som_buf_puts(&b, " dropped, ");
    som_buf_puti(&b, u);
    som_buf_puts(&b, " unmarked, ");
    som_buf_puti(&b, a);
    som_buf_puts(&b, " moved");
    som_strlist_push(out, som_buf_take(&b));
  }
  if (r->marks_dropped > 0) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "review marks inside dropped elements: ");
    som_buf_puti(&b, r->marks_dropped);
    som_strlist_push(out, som_buf_take(&b));
  }
  for (size_t i = 0; i < r->kept_len; i++) {
    char *label = spec_strip_value_ref_label(&r->kept[i].ref);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "KEPT (would empty a required value): ");
    som_buf_puts(&b, label);
    som_buf_puts(&b, " \xe2\x80\x94 ");
    som_buf_puts(&b, r->kept[i].finding);
    free(label);
    som_strlist_push(out, som_buf_take(&b));
  }
}

char *spec_strip_finding_string(const SpecStripFinding *f) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, f->kind);
  som_buf_puts(&b, ": ");
  if (f->ref != NULL) {
    char *label = spec_strip_value_ref_label(f->ref);
    som_buf_puts(&b, label);
    som_buf_puts(&b, ": ");
    free(label);
  }
  som_buf_puts(&b, f->message);
  return som_buf_take(&b);
}

char *spec_strip_result_to_json(const SpecStripResult *r) {
  SomBuf b;
  som_buf_init(&b);
  DocumentJson dj;
  spec_document_to_json(r->document, &dj);
  char *doc = document_json_to_canonical_json(&dj);
  document_json_free(&dj);
  som_buf_puts(&b, "{\"document\":");
  som_buf_puts(&b, doc);
  free(doc);
  som_buf_puts(&b, ",\"kept\":[");
  for (size_t i = 0; i < r->kept_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_ref(&b, &r->kept[i].ref);
  }
  som_buf_puts(&b, "],\"removedItems\":[");
  for (size_t i = 0; i < r->removed_items.len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_str(&b, r->removed_items.items[i]);
  }
  som_buf_puts(&b, "],\"appendix\":[");
  for (size_t i = 0; i < r->appendix_len; i++) {
    const SpecAppendixEntry *a = &r->appendix[i];
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"number\":");
    som_buf_puti(&b, a->number);
    som_buf_puts(&b, ",\"kind\":");
    put_str(&b, a->kind);
    som_buf_puts(&b, ",\"text\":");
    put_str(&b, a->text);
    if (a->value != NULL) {
      som_buf_puts(&b, ",\"value\":");
      put_ref(&b, a->value);
    }
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"dropped\":");
  put_counts(&b, r->dropped);
  som_buf_puts(&b, ",\"unmarked\":");
  put_counts(&b, r->unmarked);
  som_buf_puts(&b, ",\"appended\":");
  put_counts(&b, r->appended);
  som_buf_puts(&b, ",\"marksDropped\":");
  som_buf_puti(&b, r->marks_dropped);
  som_buf_puts(&b, ",\"readableHeader\":");
  put_str(&b, r->readable_header);
  som_buf_puts(&b, ",\"readable\":");
  if (r->readable == NULL) {
    som_buf_puts(&b, "null");
  } else {
    put_str(&b, r->readable);
  }
  som_buf_puts(&b, ",\"findings\":[");
  for (size_t i = 0; i < r->findings_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_str(&b, r->findings[i].kind);
  }
  som_buf_puts(&b, "]}");
  return som_buf_take(&b);
}

/* ---- shared with the merge back (spec_document_strip_internal.h) ---------- */

void spec_strip_ops_push(OpVec *v, int type, char ch, const char *label) {
  ops_push(v, type, ch, label);
}

void spec_strip_diff(const char *a, const char *b, const char *label,
                     OpVec *out) {
  diff_text(a, b, label, out);
}

void spec_strip_lines(const char *s, TokVec *out) {
  split_lines_keep(s, strlen(s), out);
}

void spec_strip_myers(const TokVec *a, const TokVec *b, EditVec *out) {
  myers(a, b, out);
}

void spec_strip_find_marks(const char *t, MarkAt **out, size_t *out_len) {
  find_marks(t, out, out_len);
}

void spec_strip_value_refs(const SpecDocument *doc, SpecStripValueRef **out,
                           size_t *out_len) {
  value_refs(doc, out, out_len);
}

void spec_strip_tier_findings(const SpecModel *model,
                              const DocSpecsSchema *schema,
                              const char *root_type, const SpecDocument *doc,
                              KeyPaths *out) {
  tier_findings(model, schema, root_type, doc, out);
}

long spec_strip_key_paths_find(const KeyPaths *m, const char *key) {
  return kp_find(m, key);
}

void spec_strip_key_paths_free(KeyPaths *m) { kp_free(m); }
