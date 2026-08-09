#include "spec_text_pattern.h"

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_util.h"

/* ---- compilation constants ----------------------------------------------- */

#define K_DOT 0x2E          /* . */
#define K_CARET 0x5E        /* ^ */
#define K_DOLLAR 0x24       /* $ */
#define K_BACKSLASH 0x5C    /* \ */
#define K_OPENBRACKET 0x5B  /* [ */
#define K_CLOSEBRACKET 0x5D /* ] */
#define K_STAR 0x2A         /* * */
#define K_PLUS 0x2B         /* + */
#define K_QUESTION 0x3F     /* ? */
#define K_DASH 0x2D         /* - */
#define K_UPPER_A 0x41
#define K_UPPER_Z 0x5A
#define K_LOWER_A 0x61
#define K_LOWER_Z 0x7A
#define K_ZERO 0x30
#define K_NINE 0x39

/* What a single term matches. */
typedef enum {
  ATOM_LITERAL = 0,
  ATOM_ANY,
  ATOM_START_ANCHOR,
  ATOM_END_ANCHOR,
  ATOM_CHAR_CLASS,
} AtomKind;

/* How many times a term's atom may repeat. */
typedef enum {
  REPEAT_ONE = 0,
  REPEAT_ZERO_OR_ONE,
  REPEAT_ZERO_OR_MORE,
  REPEAT_ONE_OR_MORE,
} Repeat;

/* One inclusive `[lo, hi]` code-unit range inside a character class. */
typedef struct {
  uint16_t lo;
  uint16_t hi;
} PatRange;

struct SomPatternTerm {
  AtomKind kind;
  uint16_t literal;  /* ATOM_LITERAL */
  PatRange *ranges;  /* ATOM_CHAR_CLASS; owned */
  size_t ranges_len;
  int negated; /* ATOM_CHAR_CLASS `[^…]` */
  Repeat repeat;
};

/* Whether an anchor can carry a quantifier — it cannot; `^*` is meaningless and
 * is far more likely to be a typo than an intent. */
static int term_is_anchor(const SomPatternTerm *t) {
  return t->kind == ATOM_START_ANCHOR || t->kind == ATOM_END_ANCHOR;
}

/* ---- UTF-16 view ---------------------------------------------------------- */

/* Spans are UTF-16 code-unit offsets because the Dart reference indexes
 * `String.codeUnits`. The runtime's strings are UTF-8, so every entry point
 * decodes into this owning view and matches over it. Malformed bytes decode to
 * U+FFFD rather than aborting: a pattern query over a value the document
 * already holds must not become a hard error. */
typedef struct {
  uint16_t *units;
  size_t len;
} Utf16View;

static void utf16_view_free(Utf16View *v) {
  free(v->units);
  v->units = NULL;
  v->len = 0;
}

static void utf16_push(Utf16View *v, size_t *cap, uint16_t unit) {
  if (v->len == *cap) {
    *cap = (*cap == 0) ? 16 : *cap * 2;
    v->units = (uint16_t *)realloc(v->units, *cap * sizeof(uint16_t));
  }
  v->units[v->len++] = unit;
}

/* Decodes the UTF-8 string `s` into UTF-16 code units (surrogate pairs for
 * astral code points, so offsets match Dart/Java/JavaScript exactly). */
static Utf16View utf16_decode(const char *s) {
  Utf16View v;
  v.units = NULL;
  v.len = 0;
  size_t cap = 0;
  if (s == NULL) {
    return v;
  }
  const unsigned char *p = (const unsigned char *)s;
  while (*p != '\0') {
    unsigned c = *p;
    unsigned long cp;
    size_t extra;
    if (c < 0x80) {
      cp = c;
      extra = 0;
    } else if ((c & 0xE0) == 0xC0) {
      cp = c & 0x1Fu;
      extra = 1;
    } else if ((c & 0xF0) == 0xE0) {
      cp = c & 0x0Fu;
      extra = 2;
    } else if ((c & 0xF8) == 0xF0) {
      cp = c & 0x07u;
      extra = 3;
    } else {
      /* A stray continuation or invalid lead byte. */
      utf16_push(&v, &cap, 0xFFFD);
      p++;
      continue;
    }
    size_t i;
    int ok = 1;
    for (i = 0; i < extra; i++) {
      unsigned cc = p[1 + i];
      if ((cc & 0xC0) != 0x80) {
        ok = 0;
        break;
      }
      cp = (cp << 6) | (cc & 0x3Fu);
    }
    if (!ok) {
      utf16_push(&v, &cap, 0xFFFD);
      p++;
      continue;
    }
    p += extra + 1;
    if (cp > 0x10FFFFul || (cp >= 0xD800ul && cp <= 0xDFFFul)) {
      utf16_push(&v, &cap, 0xFFFD);
    } else if (cp >= 0x10000ul) {
      unsigned long rest = cp - 0x10000ul;
      utf16_push(&v, &cap, (uint16_t)(0xD800ul + (rest >> 10)));
      utf16_push(&v, &cap, (uint16_t)(0xDC00ul + (rest & 0x3FFul)));
    } else {
      utf16_push(&v, &cap, (uint16_t)cp);
    }
  }
  return v;
}

/* Renders one code unit as UTF-8 for an error message (BMP only; a lone
 * surrogate is written as the replacement character). */
static void utf16_unit_to_utf8(uint16_t unit, char out[5]) {
  unsigned long cp = unit;
  if (cp >= 0xD800ul && cp <= 0xDFFFul) {
    cp = 0xFFFD;
  }
  size_t n = 0;
  if (cp < 0x80) {
    out[n++] = (char)cp;
  } else if (cp < 0x800) {
    out[n++] = (char)(0xC0 | (cp >> 6));
    out[n++] = (char)(0x80 | (cp & 0x3F));
  } else {
    out[n++] = (char)(0xE0 | (cp >> 12));
    out[n++] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[n++] = (char)(0x80 | (cp & 0x3F));
  }
  out[n] = '\0';
}

/* ---- span list ------------------------------------------------------------ */

void spec_match_span_list_init(SpecMatchSpanList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_match_span_list_push(SpecMatchSpanList *l, long long start,
                               long long end) {
  if (l->len == l->cap) {
    l->cap = (l->cap == 0) ? 4 : l->cap * 2;
    l->items =
        (SpecMatchSpan *)realloc(l->items, l->cap * sizeof(SpecMatchSpan));
  }
  l->items[l->len].start = start;
  l->items[l->len].end = end;
  l->len++;
}

void spec_match_span_list_free(SpecMatchSpanList *l) {
  free(l->items);
  spec_match_span_list_init(l);
}

/* ---- pattern error -------------------------------------------------------- */

void som_pattern_error_init(SomPatternError *err) {
  err->pattern = NULL;
  err->message = NULL;
}

void som_pattern_error_free(SomPatternError *err) {
  free(err->pattern);
  free(err->message);
  som_pattern_error_init(err);
}

char *som_pattern_error_string(const SomPatternError *err) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "SomPatternError(\"");
  som_buf_puts(&b, err->pattern == NULL ? "" : err->pattern);
  som_buf_puts(&b, "\"): ");
  som_buf_puts(&b, err->message == NULL ? "" : err->message);
  return som_buf_take(&b);
}

/* ---- compilation ---------------------------------------------------------- */

/* The compile-time scratch state, standing in for the Dart closure `bad`. */
typedef struct {
  const char *source;
  SomPatternError *err; /* borrowed; may be NULL */
  int failed;
} Compiler;

static void bad(Compiler *c, const char *fmt, ...) {
  if (c->failed) {
    return; /* keep the first diagnosis, as the Dart `throw` does */
  }
  c->failed = 1;
  if (c->err == NULL) {
    return;
  }
  char buf[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  c->err->pattern = som_strdup(c->source);
  c->err->message = som_strdup(buf);
}

static void term_init(SomPatternTerm *t, AtomKind kind) {
  t->kind = kind;
  t->literal = 0;
  t->ranges = NULL;
  t->ranges_len = 0;
  t->negated = 0;
  t->repeat = REPEAT_ONE;
}

/* An owning, growable term array used while compiling. */
typedef struct {
  SomPatternTerm *items;
  size_t len;
  size_t cap;
} TermList;

static void term_list_init(TermList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

static void term_list_push(TermList *l, SomPatternTerm t) {
  if (l->len == l->cap) {
    l->cap = (l->cap == 0) ? 8 : l->cap * 2;
    l->items =
        (SomPatternTerm *)realloc(l->items, l->cap * sizeof(SomPatternTerm));
  }
  l->items[l->len++] = t;
}

static void term_list_free(TermList *l) {
  size_t i;
  for (i = 0; i < l->len; i++) {
    free(l->items[i].ranges);
  }
  free(l->items);
  term_list_init(l);
}

static void range_push(PatRange **items, size_t *len, size_t *cap, uint16_t lo,
                       uint16_t hi) {
  if (*len == *cap) {
    *cap = (*cap == 0) ? 4 : *cap * 2;
    *items = (PatRange *)realloc(*items, *cap * sizeof(PatRange));
  }
  (*items)[*len].lo = lo;
  (*items)[*len].hi = hi;
  (*len)++;
}

/* Rejects `\` followed by an ASCII letter or digit.
 *
 * Every character class shorthand other dialects define — `\d` `\w` `\s` `\b`
 * `\n` `\1` — lives in exactly this space, and none of them has a literal
 * reading anyone intends: nobody writes `\w` meaning the letter `w`. Accepting
 * them as literals would make `slip\w+` quietly mean "slip, then one or more
 * `w`", which matches nothing and reports no error. Escapes of
 * *non*-alphanumerics stay legal, so `\.` `\[` `\(` still write those characters
 * literally. */
static void reject_class_escape(Compiler *c, uint16_t escaped) {
  int is_alpha = (escaped >= K_UPPER_A && escaped <= K_UPPER_Z) ||
                 (escaped >= K_LOWER_A && escaped <= K_LOWER_Z);
  int is_digit = escaped >= K_ZERO && escaped <= K_NINE;
  if (!is_alpha && !is_digit) {
    return;
  }
  char ch[5];
  utf16_unit_to_utf8(escaped, ch);
  bad(c,
      "escape \"\\%s\" is outside the portable subset — it has no "
      "character-class shorthands, and reading it as a literal \"%s\" would "
      "not be what was meant",
      ch, ch);
}

/* Parses the character class starting at `units[open]` (which is `[`), writing
 * the term to `*out` and returning the index just past the closing `]`. */
static size_t parse_class(Compiler *c, const uint16_t *units, size_t len,
                          size_t open, SomPatternTerm *out) {
  size_t i = open + 1;
  int negated = 0;
  if (i < len && units[i] == K_CARET) {
    negated = 1;
    i++;
  }
  PatRange *ranges = NULL;
  size_t ranges_len = 0;
  size_t ranges_cap = 0;
  /* A `]` immediately after `[` (or `[^`) is a literal `]`, the POSIX rule —
   * adopted because the alternative is an empty class, which can never match
   * and is therefore never what was meant. */
  int first = 1;
  while (i < len && (units[i] != K_CLOSEBRACKET || first)) {
    first = 0;
    uint16_t lo = units[i];
    if (lo == K_BACKSLASH) {
      if (i + 1 >= len) {
        bad(c, "dangling escape inside a character class");
        free(ranges);
        return 0;
      }
      reject_class_escape(c, units[i + 1]);
      if (c->failed) {
        free(ranges);
        return 0;
      }
      lo = units[i + 1];
      i += 2;
    } else {
      i++;
    }
    /* `-` is a range only between two members; trailing `-` is a literal. */
    if (i + 1 < len && units[i] == K_DASH && units[i + 1] != K_CLOSEBRACKET) {
      uint16_t hi = units[i + 1];
      size_t step = 2;
      if (hi == K_BACKSLASH) {
        if (i + 2 >= len) {
          bad(c, "dangling escape inside a character class");
          free(ranges);
          return 0;
        }
        reject_class_escape(c, units[i + 2]);
        if (c->failed) {
          free(ranges);
          return 0;
        }
        hi = units[i + 2];
        step = 3;
      }
      if (hi < lo) {
        char a[5];
        char b[5];
        utf16_unit_to_utf8(lo, a);
        utf16_unit_to_utf8(hi, b);
        bad(c, "character class range \"%s-%s\" runs backwards", a, b);
        free(ranges);
        return 0;
      }
      range_push(&ranges, &ranges_len, &ranges_cap, lo, hi);
      i += step;
    } else {
      range_push(&ranges, &ranges_len, &ranges_cap, lo, lo);
    }
  }
  if (i >= len) {
    bad(c, "character class opened at %zu is never closed", open);
    free(ranges);
    return 0;
  }
  term_init(out, ATOM_CHAR_CLASS);
  out->ranges = ranges;
  out->ranges_len = ranges_len;
  out->negated = negated;
  return i + 1;
}

void spec_text_pattern_literal(SomTextPattern *out, const char *text,
                               int case_insensitive) {
  Utf16View v = utf16_decode(text);
  TermList terms;
  term_list_init(&terms);
  size_t i;
  for (i = 0; i < v.len; i++) {
    SomPatternTerm t;
    term_init(&t, ATOM_LITERAL);
    t.literal = v.units[i];
    term_list_push(&terms, t);
  }
  utf16_view_free(&v);
  out->terms = terms.items;
  out->terms_len = terms.len;
  out->case_insensitive = case_insensitive ? 1 : 0;
}

int spec_text_pattern_compile(SomTextPattern *out, const char *source,
                              int case_insensitive, SomPatternError *err) {
  Compiler c;
  c.source = source == NULL ? "" : source;
  c.err = err;
  c.failed = 0;

  Utf16View v = utf16_decode(source);
  TermList terms;
  term_list_init(&terms);

  size_t i = 0;
  while (i < v.len && !c.failed) {
    uint16_t ch = v.units[i];
    SomPatternTerm term;
    term_init(&term, ATOM_LITERAL);
    switch (ch) {
      case K_DOT:
        term_init(&term, ATOM_ANY);
        i++;
        break;
      case K_CARET:
        term_init(&term, ATOM_START_ANCHOR);
        i++;
        break;
      case K_DOLLAR:
        term_init(&term, ATOM_END_ANCHOR);
        i++;
        break;
      case K_BACKSLASH:
        if (i + 1 >= v.len) {
          bad(&c, "pattern ends with a dangling escape");
          break;
        }
        reject_class_escape(&c, v.units[i + 1]);
        if (c.failed) {
          break;
        }
        term_init(&term, ATOM_LITERAL);
        term.literal = v.units[i + 1];
        i += 2;
        break;
      case K_OPENBRACKET: {
        size_t next = parse_class(&c, v.units, v.len, i, &term);
        if (c.failed) {
          break;
        }
        i = next;
        break;
      }
      case K_STAR:
      case K_PLUS:
      case K_QUESTION: {
        char q[5];
        utf16_unit_to_utf8(ch, q);
        bad(&c, "quantifier \"%s\" at offset %zu has nothing to repeat", q, i);
        break;
      }
      default:
        term_init(&term, ATOM_LITERAL);
        term.literal = ch;
        i++;
        break;
    }
    if (c.failed) {
      free(term.ranges);
      break;
    }

    if (i < v.len) {
      Repeat repeat = REPEAT_ONE;
      switch (v.units[i]) {
        case K_STAR:
          repeat = REPEAT_ZERO_OR_MORE;
          break;
        case K_PLUS:
          repeat = REPEAT_ONE_OR_MORE;
          break;
        case K_QUESTION:
          repeat = REPEAT_ZERO_OR_ONE;
          break;
        default:
          break;
      }
      if (repeat != REPEAT_ONE) {
        if (term_is_anchor(&term)) {
          /* Note: the Dart reference reports the *atom* character `ch` here,
           * not the quantifier — transcribed as-is so the messages match. */
          char a[5];
          utf16_unit_to_utf8(ch, a);
          bad(&c, "anchor \"%s\" at offset %zu cannot carry a quantifier", a,
              i);
          free(term.ranges);
          break;
        }
        term.repeat = repeat;
        i++;
      }
    }
    term_list_push(&terms, term);
  }

  utf16_view_free(&v);
  if (c.failed) {
    term_list_free(&terms);
    return 0;
  }
  out->terms = terms.items;
  out->terms_len = terms.len;
  out->case_insensitive = case_insensitive ? 1 : 0;
  return 1;
}

void spec_text_pattern_free(SomTextPattern *p) {
  size_t i;
  for (i = 0; i < p->terms_len; i++) {
    free(p->terms[i].ranges);
  }
  free(p->terms);
  p->terms = NULL;
  p->terms_len = 0;
  p->case_insensitive = 0;
}

/* ---- matching ------------------------------------------------------------- */

static uint16_t to_lower_ascii(uint16_t unit) {
  return (unit >= K_UPPER_A && unit <= K_UPPER_Z) ? (uint16_t)(unit + 0x20)
                                                  : unit;
}

static uint16_t swap_case(uint16_t unit) {
  if (unit >= K_UPPER_A && unit <= K_UPPER_Z) {
    return (uint16_t)(unit + 0x20);
  }
  if (unit >= K_LOWER_A && unit <= K_LOWER_Z) {
    return (uint16_t)(unit - 0x20);
  }
  return unit;
}

static uint16_t fold(const SomTextPattern *p, uint16_t unit) {
  return p->case_insensitive ? to_lower_ascii(unit) : unit;
}

/* Whether `unit` falls in `r`, honouring ASCII-only case folding: an insensitive
 * `[a-z]` must also admit `Q`, which a single folded comparison of the code unit
 * cannot express (folding `Q` to `q` would also make `[A-Z]` admit `q`, which is
 * the same answer — but folding the *bounds* would break `[A-z]`). So both cases
 * of the unit are tried against the raw range. */
static int in_range(const SomTextPattern *p, const PatRange *r, uint16_t unit) {
  if (unit >= r->lo && unit <= r->hi) {
    return 1;
  }
  if (!p->case_insensitive) {
    return 0;
  }
  uint16_t swapped = swap_case(unit);
  return swapped != unit && swapped >= r->lo && swapped <= r->hi;
}

static int accepts(const SomTextPattern *p, const SomPatternTerm *term,
                   uint16_t unit) {
  switch (term->kind) {
    case ATOM_ANY:
      return 1;
    case ATOM_LITERAL:
      return fold(p, unit) == fold(p, term->literal);
    case ATOM_CHAR_CLASS: {
      int inside = 0;
      size_t i;
      for (i = 0; i < term->ranges_len; i++) {
        if (in_range(p, &term->ranges[i], unit)) {
          inside = 1;
          break;
        }
      }
      return term->negated ? !inside : inside;
    }
    case ATOM_START_ANCHOR:
    case ATOM_END_ANCHOR:
      break;
  }
  return 0;
}

/* Matches the pattern's terms from `term_index` against `units` starting at
 * `at`, returning the end offset of the match or `-1`. Greedy with
 * backtracking: a repeated atom consumes as much as it can, then gives back one
 * character at a time until the remainder of the pattern fits. */
static long long match_at(const SomTextPattern *p, const uint16_t *units,
                          size_t len, size_t term_index, size_t at) {
  if (term_index == p->terms_len) {
    return (long long)at;
  }
  const SomPatternTerm *term = &p->terms[term_index];

  switch (term->kind) {
    case ATOM_START_ANCHOR:
      return at == 0 ? match_at(p, units, len, term_index + 1, at) : -1;
    case ATOM_END_ANCHOR:
      return at == len ? match_at(p, units, len, term_index + 1, at) : -1;
    case ATOM_LITERAL:
    case ATOM_ANY:
    case ATOM_CHAR_CLASS:
      break;
  }

  switch (term->repeat) {
    case REPEAT_ONE:
      if (at < len && accepts(p, term, units[at])) {
        return match_at(p, units, len, term_index + 1, at + 1);
      }
      return -1;
    case REPEAT_ZERO_OR_ONE:
      if (at < len && accepts(p, term, units[at])) {
        long long with_one = match_at(p, units, len, term_index + 1, at + 1);
        if (with_one >= 0) {
          return with_one;
        }
      }
      return match_at(p, units, len, term_index + 1, at);
    case REPEAT_ZERO_OR_MORE:
    case REPEAT_ONE_OR_MORE: {
      size_t minimum = term->repeat == REPEAT_ONE_OR_MORE ? 1 : 0;
      size_t consumed = at;
      while (consumed < len && accepts(p, term, units[consumed])) {
        consumed++;
      }
      while (consumed - at >= minimum) {
        long long rest = match_at(p, units, len, term_index + 1, consumed);
        if (rest >= 0) {
          return rest;
        }
        if (consumed == at) {
          break;
        }
        consumed--;
      }
      return -1;
    }
  }
  return -1;
}

void spec_text_pattern_all_matches(const SomTextPattern *p, const char *text,
                                   SpecMatchSpanList *out) {
  Utf16View v = utf16_decode(text);
  size_t start = 0;
  while (start <= v.len) {
    long long end = match_at(p, v.units, v.len, 0, start);
    if (end < 0) {
      start++;
      continue;
    }
    spec_match_span_list_push(out, (long long)start, end);
    /* Non-overlapping: resume past the match, but never stand still. */
    start = (size_t)end > start ? (size_t)end : start + 1;
  }
  utf16_view_free(&v);
}

int spec_text_pattern_has_match(const SomTextPattern *p, const char *text) {
  SpecMatchSpanList spans;
  spec_match_span_list_init(&spans);
  spec_text_pattern_all_matches(p, text, &spans);
  int any = spans.len > 0;
  spec_match_span_list_free(&spans);
  return any;
}
