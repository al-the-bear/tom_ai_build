/* spec_document_merge — the merge back (see the header).
 *
 * A port of `spec_document_merge.ts` working on the values' bytes, like the
 * strip it inverts (spec_document_strip.c): every character test looks at
 * ASCII only, and every offset the edit scripts, the notation scanner and the
 * mark finder hand over falls on a character boundary. The pieces' offsets,
 * which count UTF-16 code units, are converted to bytes on the way in, and
 * the offsets the results report are converted back.
 */
#define _POSIX_C_SOURCE 200809L

#include "spec_document_merge.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#include "som_json.h"
#include "spec_document_markdown.h"
#include "spec_document_strip_internal.h"
#include "spec_notation.h"
#include "spec_review_annotations.h"

/* ---- small helpers -------------------------------------------------------- */

static int ws(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

static int blank_n(const char *s, size_t n) {
  for (size_t i = 0; i < n; i++) {
    if (!ws(s[i])) return 0;
  }
  return 1;
}

/* The UTF-16 units of `s[0..n)`. */
static size_t u16_len(const char *s, size_t n) {
  size_t u = 0;
  for (size_t i = 0; i < n; i++) {
    unsigned char c = (unsigned char)s[i];
    if ((c & 0xC0) == 0x80) continue;
    u += c >= 0xF0 ? 2 : 1;
  }
  return u;
}

/* The byte offset of UTF-16 offset `u` in `s` (its length when past it). */
static size_t byte_of_u16(const char *s, size_t u) {
  size_t i = 0, k = 0, n = strlen(s);
  while (i < n && k < u) {
    unsigned char c = (unsigned char)s[i];
    k += c >= 0xF0 ? 2 : 1;
    i++;
    while (i < n && ((unsigned char)s[i] & 0xC0) == 0x80) i++;
  }
  return i;
}

/* `«s»` with each line break written `⏎`. Owned. */
static char *visible_n(const char *s, size_t n) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "\xc2\xab");
  for (size_t i = 0; i < n; i++) {
    if (s[i] == '\n') {
      som_buf_puts(&b, "\xe2\x8f\x8e");
    } else {
      som_buf_putc(&b, s[i]);
    }
  }
  som_buf_puts(&b, "\xc2\xbb");
  return som_buf_take(&b);
}

/* Thirty UTF-16 units either side of byte offset `at` of `s`, visible. */
static char *excerpt(const char *s, size_t at) {
  size_t n = strlen(s);
  if (at > n) at = n;
  size_t len16 = u16_len(s, n);
  size_t at16 = u16_len(s, at);
  size_t a16 = (at16 < len16 ? at16 : len16);
  a16 = a16 > 30 ? a16 - 30 : 0;
  size_t z16 = at16 + 30 < len16 ? at16 + 30 : len16;
  size_t a = byte_of_u16(s, a16), z = byte_of_u16(s, z16);
  return visible_n(s + a, z - a);
}

/* The byte offset of the first character at which `a` and `b` differ (the
 * shorter length when one is a prefix of the other). */
static size_t first_difference(const char *a, const char *b) {
  size_t i = 0;
  while (a[i] != '\0' && b[i] != '\0' && a[i] == b[i]) i++;
  /* Back to the start of the character the difference falls in. */
  while (i > 0 && ((unsigned char)a[i] & 0xC0) == 0x80) i--;
  return i;
}

static size_t trailing_breaks_n(const char *s, size_t n) {
  size_t k = 0;
  while (k < n && s[n - 1 - k] == '\n') k++;
  return k;
}

static size_t leading_breaks(const char *s) {
  size_t k = 0;
  while (s[k] == '\n') k++;
  return k;
}

static int js_streq(const char *a, const char *b) {
  return (a == NULL && b == NULL) || (a != NULL && b != NULL && strcmp(a, b) == 0);
}

static SpecStripValueRef *ref_heap(const SpecStripValueRef *r) {
  SpecStripValueRef *h = malloc(sizeof(SpecStripValueRef));
  h->path = som_strdup(r->path);
  h->field = r->field != NULL ? som_strdup(r->field) : NULL;
  h->headline = r->headline;
  return h;
}

static void ref_release(SpecStripValueRef *r) {
  spec_strip_value_ref_free(r);
  free(r);
}

static void put_json_str(SomBuf *b, const char *s) {
  char *e = som_json_encode_str(s);
  som_buf_puts(b, e);
  free(e);
}

/* ---- conflicts -------------------------------------------------------------- */

typedef struct {
  SpecStripMergeConflict *items;
  size_t len, cap;
} Conflicts;

static SpecStripMergeConflict *conflict_push(Conflicts *c, const char *code,
                                             const char *message) {
  if (c->len == c->cap) {
    c->cap = c->cap ? c->cap * 2 : 4;
    c->items = realloc(c->items, c->cap * sizeof(SpecStripMergeConflict));
  }
  SpecStripMergeConflict *x = &c->items[c->len++];
  memset(x, 0, sizeof(*x));
  x->code = som_strdup(code);
  x->message = som_strdup(message);
  x->excerpt_o = som_strdup("");
  x->excerpt_b = som_strdup("");
  x->excerpt_e = som_strdup("");
  return x;
}

static void set_excerpts(SpecStripMergeConflict *x, char *o, char *b, char *e) {
  free(x->excerpt_o);
  free(x->excerpt_b);
  free(x->excerpt_e);
  x->excerpt_o = o;
  x->excerpt_b = b;
  x->excerpt_e = e;
}

static void conflict_free(SpecStripMergeConflict *x) {
  free(x->code);
  free(x->message);
  if (x->ref != NULL) ref_release(x->ref);
  free(x->removed);
  free(x->excerpt_o);
  free(x->excerpt_b);
  free(x->excerpt_e);
}

char *spec_strip_merge_label(const SpecStripValueRef *ref) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, ref->path);
  if (ref->headline) {
    som_buf_puts(&b, " (headline)");
  } else if (ref->field != NULL) {
    som_buf_puts(&b, " / ");
    som_buf_puts(&b, ref->field);
  }
  return som_buf_take(&b);
}

void spec_strip_merge_conflict_report_lines(const SpecStripMergeConflict *c,
                                            SomStrList *out) {
  som_strlist_init(out);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "CONFLICT ");
  if (c->ref == NULL) {
    som_buf_puts(&b, "(document)");
  } else {
    char *l = spec_strip_merge_label(c->ref);
    som_buf_puts(&b, l);
    free(l);
  }
  som_buf_puts(&b, " \xe2\x80\x94 ");
  som_buf_puts(&b, c->message);
  som_strlist_push(out, som_buf_take(&b));
  if (c->removed != NULL || c->excerpt_b[0] != '\0') {
    const char *tags[3] = {"  O: ", "  B: ", "  E: "};
    const char *texts[3] = {c->excerpt_o, c->excerpt_b, c->excerpt_e};
    for (int i = 0; i < 3; i++) {
      som_buf_init(&b);
      som_buf_puts(&b, tags[i]);
      som_buf_puts(&b, texts[i]);
      som_strlist_push(out, som_buf_take(&b));
    }
  }
  if (c->removed != NULL) {
    char *v = visible_n(c->removed, strlen(c->removed));
    som_buf_init(&b);
    som_buf_puts(&b, "  piece: ");
    som_buf_puts(&b, v);
    free(v);
    som_strlist_push(out, som_buf_take(&b));
  }
}

static void put_ref_json(SomBuf *b, const SpecStripValueRef *r) {
  char *j = spec_strip_value_ref_to_json(r);
  som_buf_puts(b, j);
  free(j);
}

/* ---- edit maps ---------------------------------------------------------------- */

typedef struct {
  int left, right;
  size_t start, end;
} Gap;

static Gap gap_unchanged(size_t at) {
  Gap g = {0, 0, at, at};
  return g;
}

static int gap_is_unchanged(Gap g) {
  return !g.left && !g.right && g.start == g.end;
}

/* An edit script from a baseline to an edited text, indexed by baseline
 * offset (`_EditMap`). */
typedef struct {
  const Op *ops;
  size_t n;
  size_t *after;
  size_t *e_before;
  unsigned char *deleted;
} EditMap;

static void edit_map_init(EditMap *m, const Op *ops, size_t n, size_t b_len) {
  m->ops = ops;
  m->n = n;
  m->after = calloc(b_len + 2, sizeof(size_t));
  m->e_before = calloc(n + 1, sizeof(size_t));
  m->deleted = calloc(b_len + 1, 1);
  size_t g = 0;
  for (size_t i = 0; i < n; i++) {
    m->e_before[i + 1] = m->e_before[i] + (ops[i].type == OP_DEL ? 0 : 1);
    if (ops[i].type != OP_INS) {
      if (ops[i].type == OP_DEL) m->deleted[g] = 1;
      g++;
      m->after[g] = i + 1;
    }
  }
}

static void edit_map_free(EditMap *m) {
  free(m->after);
  free(m->e_before);
  free(m->deleted);
}

static Gap edit_map_gap(const EditMap *m, size_t g) {
  const Op *ops = m->ops;
  size_t p = m->after[g];
  int left = g > 0 && p > 0 && ops[p - 1].type == OP_DEL;
  size_t r = p;
  while (r < m->n && ops[r].type == OP_INS) r++;
  int right = r < m->n && ops[r].type == OP_DEL;
  if (!left && r == p && !right) return gap_unchanged(m->e_before[p]);
  size_t s = p;
  while (s > 0 && ops[s - 1].type != OP_KEEP) s--;
  size_t t = p;
  while (t < m->n && ops[t].type != OP_KEEP) t++;
  Gap out = {left, right, m->e_before[s], m->e_before[t]};
  return out;
}

/* The edited-text offset of baseline range `[a, z)` kept whole, else -1. */
static long edit_map_kept_range(const EditMap *m, size_t a, size_t z) {
  size_t first = m->after[a + 1] - 1;
  for (size_t k = a; k < z; k++) {
    size_t i = m->after[k + 1] - 1;
    if (m->ops[i].type != OP_KEEP || i != first + (k - a)) return -1;
  }
  return (long)m->e_before[first];
}

/* A line edit script from a baseline to an edited text (`_LineEditMap`). */
typedef struct {
  TokVec bl, el;
  EditVec ops;
  size_t *after;
  size_t *e_before;
} LineEditMap;

static void line_map_init(LineEditMap *m, const char *b, const char *e) {
  memset(m, 0, sizeof(*m));
  spec_strip_lines(b, &m->bl);
  spec_strip_lines(e, &m->el);
  spec_strip_myers(&m->bl, &m->el, &m->ops);
  m->after = calloc(m->bl.len + 1, sizeof(size_t));
  m->e_before = calloc(m->ops.len + 1, sizeof(size_t));
  size_t k = 0;
  for (size_t i = 0; i < m->ops.len; i++) {
    const Edit *x = &m->ops.items[i];
    m->e_before[i + 1] = m->e_before[i] + (x->type == OP_DEL ? 0 : x->tok.n);
    if (x->type != OP_INS) {
      k++;
      m->after[k] = i + 1;
    }
  }
}

static void line_map_free(LineEditMap *m) {
  free(m->bl.items);
  free(m->el.items);
  free(m->ops.items);
  free(m->after);
  free(m->e_before);
}

static Gap line_map_gap(const LineEditMap *m, size_t k) {
  const Edit *ops = m->ops.items;
  size_t n = m->ops.len;
  size_t p = m->after[k];
  int left = k > 0 && p > 0 && ops[p - 1].type == OP_DEL;
  size_t r = p;
  while (r < n && ops[r].type == OP_INS) r++;
  int right = r < n && ops[r].type == OP_DEL;
  if (!left && r == p && !right) return gap_unchanged(m->e_before[p]);
  size_t s = p;
  while (s > 0 && ops[s - 1].type != OP_KEEP) s--;
  size_t t = p;
  while (t < n && ops[t].type != OP_KEEP) t++;
  Gap out = {left, right, m->e_before[s], m->e_before[t]};
  return out;
}

/* Where a block goes back when the lines on both sides of it were edited:
 * after as many inserted paragraphs as paragraphs were deleted before it. */
static size_t line_map_paragraph_place(const LineEditMap *m, Gap gap, size_t k) {
  const Edit *ops = m->ops.items;
  size_t n = m->ops.len;
  size_t p = m->after[k];
  size_t s = p;
  while (s > 0 && ops[s - 1].type != OP_KEEP) s--;
  size_t before = 0;
  int blank = 1;
  for (size_t i = s; i < p; i++) {
    if (ops[i].type != OP_DEL) continue;
    int is_blank = blank_n(ops[i].tok.p, ops[i].tok.n);
    if (!is_blank && blank) before++;
    blank = is_blank;
  }
  if (before == 0) return gap.start;
  size_t count = 0;
  blank = 1;
  for (size_t i = s; i < n && ops[i].type != OP_KEEP; i++) {
    if (ops[i].type != OP_INS) continue;
    int is_blank = blank_n(ops[i].tok.p, ops[i].tok.n);
    if (!is_blank && blank) {
      if (count == before) return m->e_before[i];
      count++;
    }
    blank = is_blank;
  }
  return gap.end;
}

/* The script with each whitespace run at an edit slid to lead (or trail) it
 * (`_slide`). Owned copy. */
static void slide(const OpVec *in, int leading, OpVec *out) {
  out->len = in->len;
  out->cap = in->len > 0 ? in->len : 1;
  out->items = malloc(out->cap * sizeof(Op));
  if (in->len > 0) memcpy(out->items, in->items, in->len * sizeof(Op));
  Op *o = out->items;
  size_t n = out->len;
  size_t s = 0;
  while (s < n) {
    if (o[s].type == OP_KEEP) {
      s++;
      continue;
    }
    size_t t = s;
    while (t < n && o[t].type == o[s].type) t++;
    if (t < n && o[t].type != OP_KEEP) {
      while (t < n && o[t].type != OP_KEEP) t++;
      s = t;
      continue;
    }
    int type = o[s].type;
    if (leading) {
      while (s > 0 && o[s - 1].type == OP_KEEP && ws(o[t - 1].ch) &&
             o[s - 1].ch == o[t - 1].ch) {
        o[t - 1].type = OP_KEEP;
        o[t - 1].label = NULL;
        o[s - 1].type = type;
        o[s - 1].label = "edit";
        s--;
        t--;
      }
    } else {
      while (t < n && o[t].type == OP_KEEP && ws(o[s].ch) && o[s].ch == o[t].ch) {
        o[s].type = OP_KEEP;
        o[s].label = NULL;
        o[t].type = type;
        o[t].label = "edit";
        s++;
        t++;
      }
    }
    s = t;
  }
}

static size_t line_index(const char *b, size_t g) {
  size_t k = 0, n = strlen(b);
  for (size_t i = 0; i < g; i++) {
    if (b[i] == '\n') k++;
  }
  if (g == n && n > 0 && b[n - 1] != '\n') k++;
  return k;
}

/* Whether the edit deleted every non-blank character of the sentence holding
 * baseline offset `g` (`_sentenceRemoved`). */
/* Whether `b[i]` ends a sentence: `.`, `!` or `?` before whitespace or the
 * end. */
static int sentence_end(const char *b, size_t n, size_t i) {
  if (i >= n) return 0;
  char c = b[i];
  return (c == '.' || c == '!' || c == '?') && (i + 1 >= n || ws(b[i + 1]));
}

static int sentence_removed(const char *b, size_t g, const EditMap *map) {
  size_t n = strlen(b);
  size_t s = g;
  while (s > 0 && b[s - 1] != '\n' && !(s < g && sentence_end(b, n, s - 1))) s--;
  size_t e = g;
  while (e < n && b[e] != '\n') {
    if (sentence_end(b, n, e)) {
      e++;
      break;
    }
    e++;
  }
  int any = 0;
  for (size_t i = s; i < e; i++) {
    if (ws(b[i])) continue;
    any = 1;
    if (!map->deleted[i]) return 0;
  }
  return any;
}

/* ---- piece roles ---------------------------------------------------------------- */

enum { ROLE_WHOLE = 0, ROLE_OPENER = 1, ROLE_CLOSER = 2, ROLE_BOTH = 3 };

/* A piece with byte offsets. */
typedef struct {
  size_t anchor, origin;
  const char *removed, *inserted;
  size_t removed_len, inserted_len;
} BPiece;

typedef struct {
  const char *o;
  size_t n;
  long *at;
  unsigned char *opener, *closer;
} Roles;

static long roles_first(const Roles *r, size_t s, size_t e) {
  for (size_t k = s; k < e && k < r->n; k++) {
    if (!ws(r->o[k])) return r->at[k];
  }
  return -1;
}

static int roles_whole(const Roles *r, size_t start, size_t end) {
  if (!(start < end && start < r->n && r->at[start] >= 0)) return 0;
  for (size_t k = start; k < end; k++) {
    if (k >= r->n || r->at[k] != r->at[start]) return 0;
  }
  return 1;
}

static void roles_pair(Roles *r, size_t start, size_t open_end, size_t close_start,
                       size_t end) {
  if (roles_whole(r, start, end)) return;
  long po = roles_first(r, start, open_end);
  long pc = roles_first(r, close_start, end);
  if (po >= 0 && po != pc) r->opener[po] = 1;
  if (pc >= 0 && pc != po) r->closer[pc] = 1;
}

static void roles_walk(Roles *r, SpecNotationElement *const *list, size_t len) {
  for (size_t i = 0; i < len; i++) {
    const SpecNotationElement *e = list[i];
    if (e->type == SPEC_NOTATION_CITATION) {
      if (roles_whole(r, e->start, e->end)) continue;
      long po = roles_first(r, e->start + 1, e->content_start);
      if (po >= 0) r->opener[po] = 1;
    } else {
      roles_pair(r, e->start, e->content_start, e->content_end, e->end);
    }
    roles_walk(r, e->children, e->children_len);
  }
}

/* What each piece is, read from the original `o` (`_pieceRoles`). Owned. */
static int *piece_roles(const char *o, const BPiece *pieces, size_t np) {
  Roles r;
  r.o = o;
  r.n = strlen(o);
  r.at = malloc((r.n + 1) * sizeof(long));
  for (size_t k = 0; k <= r.n; k++) r.at[k] = -1;
  r.opener = calloc(np + 1, 1);
  r.closer = calloc(np + 1, 1);
  for (size_t i = 0; i < np; i++) {
    for (size_t k = pieces[i].origin;
         k < pieces[i].origin + pieces[i].removed_len && k < r.n; k++) {
      r.at[k] = (long)i;
    }
  }
  SpecNotationScan scan;
  spec_scan_notation(o, 1, &scan);
  roles_walk(&r, scan.elements, scan.elements_len);
  spec_notation_scan_free(&scan);
  MarkAt *marks = NULL;
  size_t ml = 0;
  spec_strip_find_marks(o, &marks, &ml);
  for (size_t i = 0; i < ml; i++) {
    roles_pair(&r, marks[i].start,
               marks[i].sep >= 0 ? (size_t)marks[i].sep + 2 : marks[i].body_start,
               marks[i].body_end, marks[i].end);
  }
  free(marks);
  int *roles = calloc(np + 1, sizeof(int));
  for (size_t i = 0; i < np; i++) {
    roles[i] = r.opener[i] && r.closer[i] ? ROLE_BOTH
               : r.opener[i]              ? ROLE_OPENER
               : r.closer[i]              ? ROLE_CLOSER
                                          : ROLE_WHOLE;
  }
  free(r.at);
  free(r.opener);
  free(r.closer);
  return roles;
}

/* ---- the merge of one value -------------------------------------------------------- */

typedef struct {
  size_t at;
  size_t order;
  char *text; /* owned */
  size_t replace;
  int normalize;
  size_t before, after;
} Put;

typedef struct {
  Put *items;
  size_t len, cap;
} Puts;

static Put *put_push(Puts *v, size_t at, size_t order, const char *text,
                     size_t text_len) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 8;
    v->items = realloc(v->items, v->cap * sizeof(Put));
  }
  Put *p = &v->items[v->len++];
  p->at = at;
  p->order = order;
  p->text = som_strdup_n(text, text_len);
  p->replace = 0;
  p->normalize = 0;
  p->before = 2;
  p->after = 2;
  return p;
}

static int put_cmp(const void *a, const void *b) {
  const Put *x = a, *y = b;
  if (x->at != y->at) return x->at < y->at ? -1 : 1;
  return x->order < y->order ? -1 : x->order > y->order ? 1 : 0;
}

static size_t notation_errors(const char *s) {
  SpecNotationScan scan;
  spec_scan_notation(s, 1, &scan);
  size_t n = 0;
  for (size_t i = 0; i < scan.findings_len; i++) {
    SpecNotationFindingCode c = scan.findings[i].code;
    if (strcmp(spec_notation_severity(c), "error") == 0 &&
        c != SPEC_NOTATION_REJECTED_BLOCK) {
      n++;
    }
  }
  spec_notation_scan_free(&scan);
  return n;
}

static size_t annotation_issues(const char *s) {
  SomStrList l;
  spec_annotation_issues_text(s, &l);
  size_t n = l.len;
  som_strlist_free(&l);
  return n;
}

static size_t distance(size_t breaks, int edge) {
  if (edge) return 2;
  if (breaks < 1) return 1;
  return breaks > 2 ? 2 : breaks;
}

static void value_conflict(Conflicts *c, const char *code, const char *message,
                           const char *o, const char *b, const char *e,
                           const BPiece *p, size_t e_at) {
  SpecStripMergeConflict *x = conflict_push(c, code, message);
  x->removed = som_strdup_n(p->removed, p->removed_len);
  set_excerpts(x, excerpt(o, p->origin), excerpt(b, p->anchor), excerpt(e, e_at));
}

void spec_merge_stripped_value(const char *o, const char *b, const char *e,
                               const SpecStripPiece *pieces, size_t np,
                               SpecStripValueMerge *out) {
  memset(out, 0, sizeof(*out));
  if (strcmp(e, b) == 0) {
    out->text = som_strdup(o);
    out->restored = (long long)np;
    return;
  }
  size_t b_len = strlen(b), e_len = strlen(e), o_len = strlen(o);
  BPiece *bp = calloc(np + 1, sizeof(BPiece));
  for (size_t i = 0; i < np; i++) {
    bp[i].anchor = byte_of_u16(b, pieces[i].anchor);
    bp[i].origin = byte_of_u16(o, pieces[i].origin);
    bp[i].removed = pieces[i].removed;
    bp[i].inserted = pieces[i].inserted;
    bp[i].removed_len = strlen(pieces[i].removed);
    bp[i].inserted_len = strlen(pieces[i].inserted);
  }
  int *roles = piece_roles(o, bp, np);
  OpVec ops = {NULL, 0, 0};
  spec_strip_diff(b, e, "edit", &ops);
  EditMap map, trailing, leading;
  edit_map_init(&map, ops.items, ops.len, b_len);
  /* An opening marker is judged on the script whose whitespace edits trail
   * their run, a closing one on the script whose whitespace edits lead it. */
  OpVec trail_ops, lead_ops;
  slide(&ops, 0, &trail_ops);
  slide(&ops, 1, &lead_ops);
  edit_map_init(&trailing, trail_ops.items, trail_ops.len, b_len);
  edit_map_init(&leading, lead_ops.items, lead_ops.len, b_len);
  LineEditMap lines;
  int have_lines = 0;
  Puts puts = {NULL, 0, 0};
  unsigned char *placed_at = calloc(np + 1, 1);
  Conflicts conflicts = {NULL, 0, 0};
  long long restored = 0;
  char *rot = NULL;
  for (size_t i = 0; i < np; i++) {
    const BPiece *p = &bp[i];
    if (p->inserted_len > 0) {
      long at = edit_map_kept_range(&map, p->anchor, p->anchor + p->inserted_len);
      if (at < 0) {
        value_conflict(&conflicts, "stripTextEdited",
                       "the text the strip wrote in place of a piece was edited",
                       o, b, e, p, edit_map_gap(&map, p->anchor).start);
        continue;
      }
      Put *x = put_push(&puts, (size_t)at, i, p->removed, p->removed_len);
      x->replace = p->inserted_len;
      restored++;
      continue;
    }
    int role = roles[i];
    size_t g = p->anchor;
    free(rot);
    rot = som_strdup_n(p->removed, p->removed_len);
    size_t tl = p->removed_len;
    if (role == ROLE_WHOLE && memchr(rot, '\n', tl) != NULL) {
      while (g > 0 && b[g - 1] != '\n' && g < b_len && tl > 0 && rot[0] == b[g]) {
        char c0 = rot[0];
        memmove(rot, rot + 1, tl - 1);
        rot[tl - 1] = c0;
        g++;
      }
      if (g == 0 || b[g - 1] == '\n' || g == b_len) {
        if (!have_lines) {
          line_map_init(&lines, b, e);
          have_lines = 1;
        }
        size_t k = line_index(b, g);
        Gap gap = line_map_gap(&lines, k);
        if (gap_is_unchanged(gap)) {
          put_push(&puts, gap.start, i, rot, tl);
          restored++;
          continue;
        }
        size_t at = !gap.left    ? gap.start
                    : !gap.right ? gap.end
                                 : line_map_paragraph_place(&lines, gap, k);
        if (at > 0 && at < e_len && e[at - 1] != '\n') {
          value_conflict(&conflicts, "unplaceable",
                         "the block has no line boundary to go back to", o, b, e,
                         p, at);
          continue;
        }
        /* The block keeps the distance it had from the text around it in the
         * original: a blank line, or none when it stood right against a
         * line. */
        size_t core = p->origin + leading_breaks(p->removed);
        size_t core_end =
            p->origin + p->removed_len - trailing_breaks_n(p->removed, p->removed_len);
        Put *x = put_push(&puts, at, i, rot, tl);
        x->normalize = 1;
        x->before = distance(trailing_breaks_n(o, core), core == 0);
        x->after = distance(core_end <= o_len ? leading_breaks(o + core_end) : 0,
                            core_end >= o_len);
        restored++;
        continue;
      }
      g = p->anchor;
      memcpy(rot, p->removed, tl);
    }
    const EditMap *m = role == ROLE_OPENER   ? &trailing
                       : role == ROLE_CLOSER ? &leading
                                             : &map;
    Gap gap = edit_map_gap(m, g);
    if (gap_is_unchanged(gap)) {
      put_push(&puts, gap.start, i, rot, tl);
      restored++;
      continue;
    }
    if (blank_n(rot, tl)) continue; /* normalised whitespace at an edit */
    if (role == ROLE_OPENER || role == ROLE_CLOSER) {
      if (gap.left && gap.right) {
        value_conflict(&conflicts, "crossesBoundary",
                       "an edit crosses the boundary of an unmarked element", o,
                       b, e, p, gap.start);
        continue;
      }
      /* The edit on the inner side of the marker goes inside the element. */
      size_t at = role == ROLE_OPENER ? (!gap.left ? gap.start : gap.end)
                                      : (!gap.right ? gap.end : gap.start);
      put_push(&puts, at, i, rot, tl);
      restored++;
    } else if (role == ROLE_BOTH) {
      value_conflict(&conflicts, "crossesBoundary",
                     "an edit touches the boundary between two unmarked elements",
                     o, b, e, p, gap.start);
    } else {
      if (sentence_removed(b, g, &map)) {
        value_conflict(&conflicts, "sentenceRemoved",
                       "the edit removed the whole sentence holding the piece", o,
                       b, e, p, gap.start);
        continue;
      }
      put_push(&puts, gap.end, i, rot, tl);
      placed_at[i] = 1;
      restored++;
    }
  }
  free(rot);

  SpecStripMergePlaced *placed = NULL;
  size_t placed_len = 0, placed_cap = 0;
  char *merged = NULL;
  if (conflicts.len == 0) {
    if (puts.len > 1) qsort(puts.items, puts.len, sizeof(Put), put_cmp);
    SomBuf ob;
    som_buf_init(&ob);
    size_t pos = 0;
    for (size_t k = 0; k < puts.len; k++) {
      const Put *x = &puts.items[k];
      if (x->at < pos) {
        SpecStripMergeConflict *c =
            conflict_push(&conflicts, "stripTextEdited", "two pieces claim the same text");
        c->removed = som_strdup_n(bp[x->order].removed, bp[x->order].removed_len);
        continue;
      }
      som_buf_putn(&ob, e + pos, x->at - pos);
      pos = x->at;
      const char *text = x->text;
      size_t text_len = strlen(text);
      if (x->normalize) {
        size_t a = 0, z = text_len;
        while (a < z && text[a] == '\n') a++;
        while (z > a && text[z - 1] == '\n') z--;
        if (ob.len > 0) {
          size_t have = trailing_breaks_n(ob.data, ob.len);
          for (size_t q = have; q < x->before; q++) som_buf_putc(&ob, '\n');
        }
        text = x->text + a;
        text_len = z - a;
      }
      if (placed_at[x->order]) {
        if (placed_len == placed_cap) {
          placed_cap = placed_cap ? placed_cap * 2 : 4;
          placed = realloc(placed, placed_cap * sizeof(SpecStripMergePlaced));
        }
        placed[placed_len].at = u16_len(ob.data != NULL ? ob.data : "", ob.len);
        placed[placed_len].removed =
            som_strdup_n(bp[x->order].removed, bp[x->order].removed_len);
        placed_len++;
      }
      som_buf_putn(&ob, text, text_len);
      if (x->normalize && pos < e_len) {
        size_t have = leading_breaks(e + pos);
        for (size_t q = have; q < x->after; q++) som_buf_putc(&ob, '\n');
      }
      pos += x->replace;
    }
    if (pos < e_len) som_buf_puts(&ob, e + pos);
    merged = som_buf_take(&ob);
    if (notation_errors(merged) > notation_errors(e) + notation_errors(o)) {
      conflict_push(&conflicts, "notation",
                    "the merged value has a notation error neither the original "
                    "nor the edited text has");
    }
    if (annotation_issues(merged) > annotation_issues(e) + annotation_issues(o)) {
      conflict_push(&conflicts, "annotations",
                    "the merged value has a malformed review annotation neither "
                    "the original nor the edited text has");
    }
  }
  if (conflicts.len > 0) {
    free(merged);
    for (size_t k = 0; k < placed_len; k++) free(placed[k].removed);
    free(placed);
    out->conflicts = conflicts.items;
    out->conflicts_len = conflicts.len;
  } else {
    out->text = merged;
    out->restored = restored;
    out->placed = placed;
    out->placed_len = placed_len;
    free(conflicts.items);
  }
  for (size_t k = 0; k < puts.len; k++) free(puts.items[k].text);
  free(puts.items);
  free(placed_at);
  if (have_lines) line_map_free(&lines);
  edit_map_free(&map);
  edit_map_free(&trailing);
  edit_map_free(&leading);
  free(ops.items);
  free(trail_ops.items);
  free(lead_ops.items);
  free(roles);
  free(bp);
}

static void placed_free(SpecStripMergePlaced *p, size_t n) {
  for (size_t i = 0; i < n; i++) free(p[i].removed);
  free(p);
}

void spec_strip_value_merge_free(SpecStripValueMerge *m) {
  if (m == NULL) return;
  free(m->text);
  placed_free(m->placed, m->placed_len);
  for (size_t i = 0; i < m->conflicts_len; i++) conflict_free(&m->conflicts[i]);
  free(m->conflicts);
  memset(m, 0, sizeof(*m));
}

int spec_strip_value_merge_ok(const SpecStripValueMerge *m) {
  return m->conflicts_len == 0;
}

static void put_conflict_json(SomBuf *b, const SpecStripMergeConflict *c) {
  som_buf_puts(b, "{\"code\":");
  put_json_str(b, c->code);
  if (c->ref != NULL) {
    som_buf_puts(b, ",\"value\":");
    put_ref_json(b, c->ref);
  }
  if (c->removed != NULL) {
    som_buf_puts(b, ",\"removed\":");
    put_json_str(b, c->removed);
  }
  som_buf_putc(b, '}');
}

char *spec_strip_value_merge_to_json(const SpecStripValueMerge *m) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"text\":");
  if (m->text == NULL) {
    som_buf_puts(&b, "null");
  } else {
    put_json_str(&b, m->text);
  }
  som_buf_puts(&b, ",\"restored\":");
  som_buf_puti(&b, m->restored);
  som_buf_puts(&b, ",\"placed\":[");
  for (size_t i = 0; i < m->placed_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"at\":");
    som_buf_puti(&b, (long long)m->placed[i].at);
    som_buf_puts(&b, ",\"removed\":");
    put_json_str(&b, m->placed[i].removed);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"conflicts\":[");
  for (size_t i = 0; i < m->conflicts_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    put_conflict_json(&b, &m->conflicts[i]);
  }
  som_buf_puts(&b, "]}");
  return som_buf_take(&b);
}

/* ---- the merge of a document --------------------------------------------------------- */

typedef struct {
  SpecStripMergeRefusal *items;
  size_t len, cap;
} Refusals;

static void refusal_push(Refusals *r, const char *code, const char *path,
                         char *message) {
  if (r->len == r->cap) {
    r->cap = r->cap ? r->cap * 2 : 4;
    r->items = realloc(r->items, r->cap * sizeof(SpecStripMergeRefusal));
  }
  r->items[r->len].code = som_strdup(code);
  r->items[r->len].path = som_strdup(path);
  r->items[r->len].message = message;
  r->len++;
}

static int refused_path(const Refusals *r, const char *path) {
  for (size_t i = 0; i < r->len; i++) {
    if (strcmp(r->items[i].path, path) == 0) return 1;
  }
  return 0;
}

/* The switches of `o` as the readable header writes them. Owned. */
static char *options_text(const SpecStripOptions *o) {
  char *h = spec_readable_header_format(o, NULL);
  size_t n = strlen(h);
  const size_t pre = strlen("<!-- readable:");
  size_t a = pre, z = n - 3;
  while (a < z && ws(h[a])) a++;
  while (z > a && ws(h[z - 1])) z--;
  char *out = som_strdup_n(h + a, z - a);
  free(h);
  return out;
}

static char *ref_key(const SpecStripValueRef *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, r->headline ? 'h' : r->field != NULL ? 'f' : 'c');
  som_buf_putc(&b, '\x01');
  som_buf_puts(&b, r->path);
  som_buf_putc(&b, '\x01');
  if (r->field != NULL) som_buf_puts(&b, r->field);
  return som_buf_take(&b);
}

static void heading_paths_walk(DocSpecsSection *const *list, size_t len,
                               const char *prefix, SomStrList *out) {
  for (size_t i = 0; i < len; i++) {
    const char *id = list[i]->id[0] != '\0' ? list[i]->id : "?";
    SomBuf b;
    som_buf_init(&b);
    if (prefix[0] != '\0') {
      som_buf_puts(&b, prefix);
      som_buf_putc(&b, '/');
    }
    som_buf_puts(&b, id);
    char *p = som_buf_take(&b);
    som_strlist_push_copy(out, p);
    heading_paths_walk(list[i]->children, list[i]->children_len, p, out);
    free(p);
  }
}

/* The section-id paths of `markdown`'s headings, in order. */
static void heading_paths(const char *markdown, SomStrList *out) {
  som_strlist_init(out);
  DocSpecsDocument *d = docspecs_parse_document(markdown);
  heading_paths_walk(d->sections, d->sections_len, "", out);
  docspecs_document_free(d);
}

static int in_roots(const SomStrList *roots, const char *p) {
  for (size_t i = 0; i < roots->len; i++) {
    const char *r = roots->items[i];
    size_t n = strlen(r);
    if (strcmp(p, r) == 0 || (strncmp(p, r, n) == 0 && (p[n] == '/' || p[n] == '-'))) {
      return 1;
    }
  }
  return 0;
}

static int str_cmp_items(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* The lists of `doc` under the roots, each as its items and their ids. */
static void lists_under(const SpecDocument *doc, const SomStrList *roots,
                        SomMap *out) {
  som_map_init(out);
  DocumentJson j;
  spec_document_to_json(doc, &j);
  for (size_t i = 0; i < j.lists_len; i++) {
    const DocListEntry *l = &j.lists[i];
    if (!in_roots(roots, l->key)) continue;
    SomBuf b;
    som_buf_init(&b);
    for (size_t k = 0; k < l->items.len; k++) {
      som_buf_puts(&b, l->items.items[k]);
      som_buf_putc(&b, '\x01');
    }
    som_buf_putc(&b, '\x02');
    for (size_t k = 0; k < l->ids.len; k++) {
      som_buf_puts(&b, l->ids.entries[k].key);
      som_buf_putc(&b, '=');
      som_buf_puts(&b, l->ids.entries[k].val);
      som_buf_putc(&b, '\x01');
    }
    char *v = som_buf_take(&b);
    som_map_set(out, l->key, v);
    free(v);
  }
  document_json_free(&j);
}

static void union_sorted(const SomStrList *a, const SomStrList *b,
                         const SomStrList *roots, SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *both[2] = {a, b};
  for (int s = 0; s < 2; s++) {
    for (size_t i = 0; i < both[s]->len; i++) {
      const char *p = both[s]->items[i];
      if ((roots == NULL || in_roots(roots, p)) && !som_strlist_contains(out, p)) {
        som_strlist_push_copy(out, p);
      }
    }
  }
  if (out->len > 1) qsort(out->items, out->len, sizeof(char *), str_cmp_items);
}

static int ref_cmp(const void *a, const void *b) {
  const SpecStripValueRef *x = a, *y = b;
  int c = strcmp(x->path, y->path);
  if (c != 0) return c;
  if (x->headline != y->headline) return x->headline ? -1 : 1;
  return strcmp(x->field != NULL ? x->field : "", y->field != NULL ? y->field : "");
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

static void refs_free(SpecStripValueRef *refs, size_t n) {
  for (size_t i = 0; i < n; i++) spec_strip_value_ref_free(&refs[i]);
  free(refs);
}

/* Every value of `a` and `b` under the roots, once, sorted by path,
 * headline first, then field. Owned array. */
static void merged_refs(const SpecDocument *a, const SpecDocument *b,
                        const SomStrList *roots, SpecStripValueRef **out,
                        size_t *out_len) {
  SpecStripValueRef *ra, *rb;
  size_t na, nb;
  spec_strip_value_refs(a, &ra, &na);
  spec_strip_value_refs(b, &rb, &nb);
  SpecStripValueRef *refs = calloc(na + nb + 1, sizeof(SpecStripValueRef));
  size_t n = 0;
  SomStrList keys;
  som_strlist_init(&keys);
  for (int s = 0; s < 2; s++) {
    SpecStripValueRef *list = s == 0 ? ra : rb;
    size_t len = s == 0 ? na : nb;
    for (size_t i = 0; i < len; i++) {
      if (roots != NULL && !in_roots(roots, list[i].path)) continue;
      char *k = ref_key(&list[i]);
      if (som_strlist_contains(&keys, k)) {
        free(k);
        continue;
      }
      som_strlist_push(&keys, k);
      refs[n].path = som_strdup(list[i].path);
      refs[n].field = list[i].field != NULL ? som_strdup(list[i].field) : NULL;
      refs[n].headline = list[i].headline;
      n++;
    }
  }
  som_strlist_free(&keys);
  refs_free(ra, na);
  refs_free(rb, nb);
  if (n > 1) qsort(refs, n, sizeof(SpecStripValueRef), ref_cmp);
  *out = refs;
  *out_len = n;
}

void spec_strip_merge_result_free(SpecStripMergeResult *r) {
  if (r == NULL) return;
  doc_release(r->document);
  for (size_t i = 0; i < r->merged_len; i++) {
    spec_strip_value_ref_free(&r->merged[i].ref);
    free(r->merged[i].text);
    placed_free(r->merged[i].placed, r->merged[i].placed_len);
  }
  free(r->merged);
  for (size_t i = 0; i < r->conflicts_len; i++) conflict_free(&r->conflicts[i]);
  free(r->conflicts);
  for (size_t i = 0; i < r->refusals_len; i++) {
    free(r->refusals[i].code);
    free(r->refusals[i].path);
    free(r->refusals[i].message);
  }
  free(r->refusals);
  memset(r, 0, sizeof(*r));
}

int spec_strip_merge_result_ok(const SpecStripMergeResult *r) {
  return r->conflicts_len == 0 && r->refusals_len == 0;
}

int spec_strip_merge_result_exit_code(const SpecStripMergeResult *r) {
  return spec_strip_merge_result_ok(r) ? 0 : 1;
}

void spec_strip_merge_result_report(const SpecStripMergeResult *r,
                                    SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < r->merged_len; i++) {
    char *l = spec_strip_merge_label(&r->merged[i].ref);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "MERGED ");
    som_buf_puts(&b, l);
    som_buf_puts(&b, " \xe2\x80\x94 ");
    som_buf_puti(&b, r->merged[i].restored);
    som_buf_puts(&b, " pieces put back");
    som_strlist_push(out, som_buf_take(&b));
    for (size_t k = 0; k < r->merged[i].placed_len; k++) {
      som_buf_init(&b);
      som_buf_puts(&b, "PLACED ");
      som_buf_puts(&b, l);
      som_buf_puts(&b, " \xe2\x80\x94 check");
      som_strlist_push(out, som_buf_take(&b));
    }
    free(l);
  }
  for (size_t i = 0; i < r->conflicts_len; i++) {
    SomStrList lines;
    spec_strip_merge_conflict_report_lines(&r->conflicts[i], &lines);
    for (size_t k = 0; k < lines.len; k++) som_strlist_push_copy(out, lines.items[k]);
    som_strlist_free(&lines);
  }
  for (size_t i = 0; i < r->refusals_len; i++) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "REFUSED ");
    som_buf_puts(&b, r->refusals[i].path[0] == '\0' ? "(document)" : r->refusals[i].path);
    som_buf_puts(&b, " \xe2\x80\x94 ");
    som_buf_puts(&b, r->refusals[i].message);
    som_strlist_push(out, som_buf_take(&b));
  }
}

static void set_error(char **error, char *message) {
  if (error != NULL) {
    *error = message;
  } else {
    free(message);
  }
}

static void merged_push(SpecStripMergeResult *out, size_t *cap,
                        const SpecStripValueRef *ref, SpecStripValueMerge *m) {
  if (out->merged_len == *cap) {
    *cap = *cap ? *cap * 2 : 4;
    out->merged = realloc(out->merged, *cap * sizeof(SpecStripMergedValue));
  }
  SpecStripMergedValue *v = &out->merged[out->merged_len++];
  v->ref.path = som_strdup(ref->path);
  v->ref.field = ref->field != NULL ? som_strdup(ref->field) : NULL;
  v->ref.headline = ref->headline;
  v->text = m->text;
  v->restored = m->restored;
  v->placed = m->placed;
  v->placed_len = m->placed_len;
  m->text = NULL;
  m->placed = NULL;
  m->placed_len = 0;
}

int spec_strip_merge(const SpecDocument *original, const char *edited,
                     const SpecStripMergeOptions *extra,
                     SpecStripMergeResult *out, char **error) {
  memset(out, 0, sizeof(*out));
  if (error != NULL) *error = NULL;
  const SpecModel *model = extra->model;
  const DocSpecsSchema *schema = extra->schema;
  const char *root_type = extra->root_type;
  SpecMarkdownResult parsed;
  spec_markdown_parse(model, edited, &parsed);
  SpecReadableHeader header;
  memset(&header, 0, sizeof(header));
  int have_header = 0;
  if (parsed.readable_header != NULL) {
    if (!spec_readable_header_parse(parsed.readable_header, &header)) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "the readable header cannot be read: ");
      som_buf_puts(&b, parsed.readable_header);
      set_error(error, som_buf_take(&b));
      spec_markdown_result_free(&parsed);
      return 0;
    }
    have_header = 1;
  }
  SpecStripOptions opts;
  if (extra->options != NULL) {
    if (have_header) {
      char *g = options_text(extra->options);
      char *h = options_text(&header.options);
      if (strcmp(g, h) != 0) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "the switches given (");
        som_buf_puts(&b, g);
        som_buf_puts(&b, ") disagree with the readable header (");
        som_buf_puts(&b, h);
        som_buf_puts(&b, ")");
        set_error(error, som_buf_take(&b));
        free(g);
        free(h);
        spec_readable_header_free(&header);
        spec_markdown_result_free(&parsed);
        return 0;
      }
      free(g);
      free(h);
    }
    opts = *extra->options;
  } else if (have_header) {
    opts = header.options;
  } else {
    set_error(error, som_strdup("the rendition has no readable header: name the "
                                "switches it was stripped with"));
    spec_markdown_result_free(&parsed);
    return 0;
  }
  out->options = opts;

  Refusals refusals = {NULL, 0, 0};
  Conflicts conflicts = {NULL, 0, 0};
  size_t merged_cap = 0;
  SpecDocument *loaded = NULL;
  SpecStripResult strip;
  memset(&strip, 0, sizeof(strip));
  int have_strip = 0;
  SpecDocument *e_doc = NULL;
  SpecStripValueRef *refs = NULL;
  size_t refs_len = 0;

  if (parsed.rejections_len > 0) {
    for (size_t i = 0; i < parsed.rejections_len; i++) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "line ");
      som_buf_puti(&b, (long long)parsed.rejections[i].line);
      som_buf_puts(&b, ": ");
      som_buf_puts(&b, parsed.rejections[i].message);
      refusal_push(&refusals, "rejected", "", som_buf_take(&b));
    }
    goto done;
  }

  const SpecReadableSource *source = have_header ? header.source : NULL;
  const char *current = extra->current_revision;
  int stale = extra->base != NULL ||
              (source != NULL && source->revision != NULL && current != NULL &&
               strcmp(source->revision, current) != 0);
  out->stale = stale;
  const SpecDocument *origin = original;
  if (stale) {
    const SpecDocument *base = extra->base;
    if (base == NULL && source != NULL && source->commit != NULL && !source->dirty &&
        extra->load_base != NULL) {
      loaded = extra->load_base(source, extra->load_base_context);
      base = loaded;
    }
    if (base == NULL) {
      const char *why = source == NULL || source->commit == NULL ? "names no commit"
                        : source->dirty ? "names a dirty commit"
                                        : "names a commit that could not be read";
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "the original moved since the export (revision ");
      som_buf_puts(&b, source != NULL && source->revision != NULL ? source->revision
                                                                  : "null");
      som_buf_puts(&b, " then, ");
      som_buf_puts(&b, current != NULL ? current : "null");
      som_buf_puts(&b, " now) and there is no base: the header ");
      som_buf_puts(&b, why);
      som_buf_puts(&b, "; give the original as it was at the export");
      refusal_push(&refusals, "stale", "", som_buf_take(&b));
      goto done;
    }
    origin = base;
  }

  SpecDocumentStripOptions so = {model, schema, root_type, NULL,
                                 extra->file_stem, extra->document_files};
  spec_document_strip(origin, &opts, &so, &strip);
  have_strip = 1;
  if (!spec_strip_result_ok(&strip) || strip.readable == NULL) {
    for (size_t i = 0; i < strip.findings_len; i++) {
      const SpecStripFinding *f = &strip.findings[i];
      char *label = f->ref != NULL ? spec_strip_value_ref_label(f->ref) : som_strdup("");
      refusal_push(&refusals, "strip", label, spec_strip_finding_string(f));
      free(label);
    }
    if (refusals.len == 0) {
      refusal_push(&refusals, "strip", "", som_strdup("the base renders no rendition"));
    }
    goto done;
  }
  const SpecDocument *b_doc = strip.document;
  e_doc = malloc(sizeof(SpecDocument));
  spec_document_init(e_doc);
  spec_document_apply_markdown_result(e_doc, &parsed, 0, NULL);
  const SomStrList *roots = &parsed.root_prefixes;

  /* Structural edits. */
  SomStrList b_heads, e_heads;
  heading_paths(strip.readable, &b_heads);
  heading_paths(edited, &e_heads);
  int same = b_heads.len == e_heads.len;
  for (size_t i = 0; same && i < b_heads.len; i++) {
    same = strcmp(b_heads.items[i], e_heads.items[i]) == 0;
  }
  if (!same) {
    for (size_t i = 0; i < e_heads.len; i++) {
      if (!som_strlist_contains(&b_heads, e_heads.items[i])) {
        refusal_push(&refusals, "sectionAdded", e_heads.items[i],
                     som_strdup("a section added"));
      }
    }
    for (size_t i = 0; i < b_heads.len; i++) {
      if (!som_strlist_contains(&e_heads, b_heads.items[i])) {
        refusal_push(&refusals, "sectionRemoved", b_heads.items[i],
                     som_strdup("a section removed"));
      }
    }
    if (refusals.len == 0) {
      SomStrList common, want;
      som_strlist_init(&common);
      som_strlist_init(&want);
      for (size_t i = 0; i < e_heads.len; i++) {
        if (som_strlist_contains(&b_heads, e_heads.items[i])) {
          som_strlist_push_copy(&common, e_heads.items[i]);
        }
      }
      for (size_t i = 0; i < b_heads.len; i++) {
        if (som_strlist_contains(&e_heads, b_heads.items[i])) {
          som_strlist_push_copy(&want, b_heads.items[i]);
        }
      }
      for (size_t i = 0; i < common.len && i < want.len; i++) {
        if (strcmp(common.items[i], want.items[i]) != 0) {
          refusal_push(&refusals, "sectionMoved", common.items[i],
                       som_strdup("a section moved"));
          break;
        }
      }
      som_strlist_free(&common);
      som_strlist_free(&want);
    }
  }
  som_strlist_free(&b_heads);
  som_strlist_free(&e_heads);

  SomMap b_lists, e_lists;
  lists_under(b_doc, roots, &b_lists);
  lists_under(e_doc, roots, &e_lists);
  {
    SomStrList bk, ek, all;
    som_strlist_init(&bk);
    som_strlist_init(&ek);
    for (size_t i = 0; i < b_lists.len; i++) som_strlist_push_copy(&bk, b_lists.entries[i].key);
    for (size_t i = 0; i < e_lists.len; i++) som_strlist_push_copy(&ek, e_lists.entries[i].key);
    union_sorted(&bk, &ek, NULL, &all);
    for (size_t i = 0; i < all.len; i++) {
      if (!js_streq(som_map_get(&b_lists, all.items[i]), som_map_get(&e_lists, all.items[i]))) {
        refusal_push(&refusals, "listItems", all.items[i],
                     som_strdup("list items added, removed, moved or renamed"));
      }
    }
    som_strlist_free(&bk);
    som_strlist_free(&ek);
    som_strlist_free(&all);
  }
  som_map_free(&b_lists);
  som_map_free(&e_lists);
  for (int kind = 0; kind < 2; kind++) {
    SomStrList bp, ep, all;
    if (kind == 0) {
      spec_document_code_spec_paths(b_doc, &bp);
      spec_document_code_spec_paths(e_doc, &ep);
    } else {
      spec_document_units_paths(b_doc, &bp);
      spec_document_units_paths(e_doc, &ep);
    }
    union_sorted(&bp, &ep, roots, &all);
    for (size_t i = 0; i < all.len; i++) {
      const char *p = all.items[i];
      const char *bv = kind == 0 ? spec_document_code_spec(b_doc, p) : spec_document_units(b_doc, p);
      const char *ev = kind == 0 ? spec_document_code_spec(e_doc, p) : spec_document_units(e_doc, p);
      if (!js_streq(bv, ev)) {
        refusal_push(&refusals, kind == 0 ? "codeSpec" : "units", p,
                     som_strdup(kind == 0 ? "a changed codeSpec" : "a changed units"));
      }
    }
    som_strlist_free(&bp);
    som_strlist_free(&ep);
    som_strlist_free(&all);
  }
  merged_refs(b_doc, e_doc, roots, &refs, &refs_len);
  for (size_t i = 0; i < refs_len; i++) {
    const SpecStripValueRef *ref = &refs[i];
    if (spec_strip_value_ref_read(ref, b_doc)[0] == '\0' &&
        spec_strip_value_ref_read(ref, e_doc)[0] != '\0' &&
        !spec_document_has_values_under(b_doc, ref->path) &&
        !refused_path(&refusals, ref->path)) {
      refusal_push(&refusals, "sectionAdded", ref->path,
                   som_strdup("a value in a section the rendition does not show"));
    }
  }

  /* The values. */
  for (size_t i = 0; i < refs_len; i++) {
    const SpecStripValueRef *ref = &refs[i];
    const char *b_text = spec_strip_value_ref_read(ref, b_doc);
    const char *e_text = spec_strip_value_ref_read(ref, e_doc);
    /* A wrapped paragraph written in a table cell reads back on one line
     * (SOM §11.4): that alone is no edit. */
    if (strcmp(b_text, e_text) == 0) continue;
    char *joined = spec_markdown_wrapped_paragraph_joined(b_text);
    int same_joined = joined != NULL && strcmp(joined, e_text) == 0;
    free(joined);
    if (same_joined) continue;
    if (refused_path(&refusals, ref->path)) continue;
    /* A value whose section came or went with a refused edit is that edit. */
    if (refusals.len > 0 && (!spec_document_has_values_under(b_doc, ref->path) ||
                             !spec_document_has_values_under(e_doc, ref->path))) {
      continue;
    }
    const char *o = spec_strip_value_ref_read(ref, origin);
    const SpecStrippedValue *sv = NULL;
    char *key = ref_key(ref);
    for (size_t k = 0; k < strip.values_len; k++) {
      char *vk = ref_key(&strip.values[k].ref);
      if (strcmp(vk, key) == 0) sv = &strip.values[k];
      free(vk);
    }
    free(key);
    SpecStripValueMerge r;
    spec_merge_stripped_value(o, b_text, e_text, sv != NULL ? sv->pieces : NULL,
                              sv != NULL ? sv->pieces_len : 0, &r);
    const char *now = spec_strip_value_ref_read(ref, original);
    if (stale && strcmp(now, o) != 0) {
      /* The edit is already in the moved original (the same rendition merged
       * before): nothing to do for this value. */
      if (spec_strip_value_merge_ok(&r) && strcmp(r.text, now) == 0) {
        spec_strip_value_merge_free(&r);
        continue;
      }
      size_t at = first_difference(b_text, e_text);
      SpecStripMergeConflict *c = conflict_push(
          &conflicts, "changedBothSides",
          "the value changed in the original since the export, and in the rendition");
      c->ref = ref_heap(ref);
      set_excerpts(c, excerpt(now, first_difference(o, now)), excerpt(b_text, at),
                   excerpt(e_text, at));
      spec_strip_value_merge_free(&r);
      continue;
    }
    if (!spec_strip_value_merge_ok(&r)) {
      for (size_t k = 0; k < r.conflicts_len; k++) {
        SpecStripMergeConflict *src = &r.conflicts[k];
        SpecStripMergeConflict *c = conflict_push(&conflicts, src->code, src->message);
        c->ref = ref_heap(ref);
        c->removed = src->removed != NULL ? som_strdup(src->removed) : NULL;
        set_excerpts(c, som_strdup(src->excerpt_o), som_strdup(src->excerpt_b),
                     som_strdup(src->excerpt_e));
      }
      spec_strip_value_merge_free(&r);
      continue;
    }
    merged_push(out, &merged_cap, ref, &r);
    spec_strip_value_merge_free(&r);
  }
  if (conflicts.len > 0 || refusals.len > 0) goto done;

  /* Write and verify. */
  {
    SpecDocument *merged_doc = doc_copy(original);
    for (size_t i = 0; i < out->merged_len; i++) {
      spec_strip_value_ref_write(&out->merged[i].ref, merged_doc, out->merged[i].text);
    }
    SomStrList expected, changed;
    som_strlist_init(&expected);
    som_strlist_init(&changed);
    for (size_t i = 0; i < out->merged_len; i++) {
      if (strcmp(out->merged[i].text,
                 spec_strip_value_ref_read(&out->merged[i].ref, original)) != 0) {
        char *k = ref_key(&out->merged[i].ref);
        if (!som_strlist_contains(&expected, k)) {
          som_strlist_push(&expected, k);
        } else {
          free(k);
        }
      }
    }
    SpecStripValueRef *all;
    size_t all_len;
    merged_refs(original, merged_doc, NULL, &all, &all_len);
    for (size_t i = 0; i < all_len; i++) {
      if (strcmp(spec_strip_value_ref_read(&all[i], original),
                 spec_strip_value_ref_read(&all[i], merged_doc)) != 0) {
        som_strlist_push(&changed, ref_key(&all[i]));
      }
    }
    refs_free(all, all_len);
    int differ = changed.len != expected.len;
    for (size_t i = 0; !differ && i < expected.len; i++) {
      differ = !som_strlist_contains(&changed, expected.items[i]);
    }
    if (differ) {
      conflict_push(&conflicts, "newFinding",
                    "the merged document changes other values than the merged ones");
    }
    som_strlist_free(&expected);
    som_strlist_free(&changed);
    SpecStripResult again;
    spec_document_strip(merged_doc, &opts, &so, &again);
    for (size_t i = 0; i < out->merged_len; i++) {
      const SpecStripMergedValue *m = &out->merged[i];
      const char *got = spec_strip_value_ref_read(&m->ref, again.document);
      const char *want = spec_strip_value_ref_read(&m->ref, e_doc);
      if (strcmp(got, want) != 0) {
        SpecStripMergeConflict *c =
            conflict_push(&conflicts, "notStrippedBack",
                          "the merged value does not strip back to the edited text");
        c->ref = ref_heap(&m->ref);
        set_excerpts(c, excerpt(m->text, 0), excerpt(got, 0), excerpt(want, 0));
      }
    }
    spec_strip_result_free(&again);
    KeyPaths before, after;
    spec_strip_tier_findings(model, schema, root_type, original, &before);
    spec_strip_tier_findings(model, schema, root_type, merged_doc, &after);
    for (size_t i = 0; i < after.keys.len; i++) {
      if (spec_strip_key_paths_find(&before, after.keys.items[i]) >= 0) continue;
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "the merged document has a new finding: ");
      som_buf_puts(&b, after.keys.items[i]);
      char *msg = som_buf_take(&b);
      conflict_push(&conflicts, "newFinding", msg);
      free(msg);
    }
    spec_strip_key_paths_free(&before);
    spec_strip_key_paths_free(&after);
    if (conflicts.len == 0) {
      out->document = merged_doc;
    } else {
      doc_release(merged_doc);
    }
  }

done:
  out->conflicts = conflicts.items;
  out->conflicts_len = conflicts.len;
  out->refusals = refusals.items;
  out->refusals_len = refusals.len;
  refs_free(refs, refs_len);
  doc_release(e_doc);
  doc_release(loaded);
  if (have_strip) spec_strip_result_free(&strip);
  spec_readable_header_free(&header);
  spec_markdown_result_free(&parsed);
  return 1;
}

/* ---- the base read from git ------------------------------------------------------------ */

char *spec_strip_merge_git_show_file(const char *commit, const char *file_path) {
  /* The file's folder and name, resolved against the working directory. */
  char *absolute;
  if (file_path[0] == '/') {
    absolute = som_strdup(file_path);
  } else {
    char cwd[4096];
    if (getcwd(cwd, sizeof(cwd)) == NULL) return NULL;
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, cwd);
    som_buf_putc(&b, '/');
    som_buf_puts(&b, file_path);
    absolute = som_buf_take(&b);
  }
  char *slash = strrchr(absolute, '/');
  char *dir = slash == absolute ? som_strdup("/")
                                : som_strdup_n(absolute, (size_t)(slash - absolute));
  SomBuf spec;
  som_buf_init(&spec);
  som_buf_puts(&spec, commit);
  som_buf_puts(&spec, ":./");
  som_buf_puts(&spec, slash + 1);
  char *object = som_buf_take(&spec);
  free(absolute);
  int fds[2];
  if (pipe(fds) != 0) {
    free(dir);
    free(object);
    return NULL;
  }
  pid_t pid = fork();
  if (pid < 0) {
    close(fds[0]);
    close(fds[1]);
    free(dir);
    free(object);
    return NULL;
  }
  if (pid == 0) {
    close(fds[0]);
    if (chdir(dir) != 0) _exit(127);
    dup2(fds[1], 1);
    close(fds[1]);
    FILE *devnull = freopen("/dev/null", "r", stdin);
    (void)devnull;
    devnull = freopen("/dev/null", "w", stderr);
    (void)devnull;
    execlp("git", "git", "show", object, (char *)NULL);
    _exit(127);
  }
  close(fds[1]);
  SomBuf data;
  som_buf_init(&data);
  char chunk[8192];
  for (;;) {
    ssize_t n = read(fds[0], chunk, sizeof(chunk));
    if (n <= 0) break;
    som_buf_putn(&data, chunk, (size_t)n);
  }
  close(fds[0]);
  int status = 0;
  waitpid(pid, &status, 0);
  free(dir);
  free(object);
  if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
    som_buf_free(&data);
    return NULL;
  }
  return som_buf_take(&data);
}
