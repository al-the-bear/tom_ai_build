/* spec_review_annotations — review annotations (SOM §11.9), a faithful port of
 * the Dart `spec_review_annotations.dart`. See the header for the contract.
 *
 * Offsets inside a value are UTF-8 byte offsets here (the Dart reference uses
 * UTF-16 code units); they never leave this file. Every delimiter is either
 * ASCII or matched as a whole UTF-8 sequence, so the two agree on every
 * decision. */
#include "spec_review_annotations.h"

#include <ctype.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define ARROW "\xE2\xAC\x86"         /* U+2B06 */
#define VS16 "\xEF\xB8\x8F"          /* U+FE0F */
#define QOPEN "**\xE2\x9D\x93"       /* `**❓` */
#define COMBINED_OPENER QOPEN " Open questions on these fields**"
#define ANSWER_LABEL "**Answer:**"
#define EM_SEP " \xE2\x80\x94 "      /* ` — ` */
#define STAR "\xE2\x98\x85"          /* U+2605 */

#define PUSH(arr, len, cap, val)                                         \
  do {                                                                   \
    if ((len) == (cap)) {                                                \
      (cap) = (cap) ? (cap) * 2 : 4;                                     \
      (arr) = realloc((arr), (cap) * sizeof(*(arr)));                    \
    }                                                                    \
    (arr)[(len)++] = (val);                                              \
  } while (0)

/* ---- names, errors ------------------------------------------------------- */

const char *spec_review_annotation_kind_name(SpecReviewAnnotationKind kind) {
  switch (kind) {
    case SPEC_REVIEW_ANNOTATION_COMMENT:
      return "comment";
    case SPEC_REVIEW_ANNOTATION_QUESTION:
      return "question";
    case SPEC_REVIEW_ANNOTATION_MARK:
      return "mark";
  }
  return "";
}

const char *spec_mark_kind_name(SpecMarkKind kind) {
  switch (kind) {
    case SPEC_MARK_COMMENT:
      return "comment";
    case SPEC_MARK_HIGHLIGHT:
      return "highlight";
    case SPEC_MARK_INSERTION:
      return "insertion";
    case SPEC_MARK_DELETION:
      return "deletion";
    case SPEC_MARK_SUBSTITUTION:
      return "substitution";
  }
  return "";
}

void spec_review_annotation_error_init(SpecReviewAnnotationError *err) {
  err->message = NULL;
}

void spec_review_annotation_error_free(SpecReviewAnnotationError *err) {
  free(err->message);
  err->message = NULL;
}

static void set_error(SpecReviewAnnotationError *err, const char *fmt, ...) {
  if (err == NULL) return;
  char buf[2048];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  free(err->message);
  err->message = som_strdup(buf);
}

static char *fmt(const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int n = vsnprintf(NULL, 0, f, ap);
  va_end(ap);
  char *buf = malloc((size_t)(n < 0 ? 0 : n) + 1);
  va_start(ap, f);
  vsnprintf(buf, (size_t)(n < 0 ? 0 : n) + 1, f, ap);
  va_end(ap);
  return buf;
}

/* ---- small string helpers ------------------------------------------------ */

static int starts_with(const char *s, const char *p) {
  return strncmp(s, p, strlen(p)) == 0;
}

/* Strips spaces and tabs from the left. */
static const char *lstrip(const char *s) {
  while (*s == ' ' || *s == '\t') s++;
  return s;
}

/* Decodes one UTF-8 code point at `*s` (never past `end`), advancing it.
 * Malformed bytes decode to themselves, one byte at a time. */
static unsigned long next_cp(const unsigned char **s, const unsigned char *end) {
  const unsigned char *p = *s;
  unsigned long c = p[0];
  size_t n = 1;
  size_t left = (size_t)(end - p);
  if (c >= 0xF0 && left >= 4) {
    c = ((c & 0x07UL) << 18) | ((p[1] & 0x3FUL) << 12) |
        ((p[2] & 0x3FUL) << 6) | (p[3] & 0x3FUL);
    n = 4;
  } else if (c >= 0xE0 && c < 0xF0 && left >= 3) {
    c = ((c & 0x0FUL) << 12) | ((p[1] & 0x3FUL) << 6) | (p[2] & 0x3FUL);
    n = 3;
  } else if (c >= 0xC0 && c < 0xE0 && left >= 2) {
    c = ((c & 0x1FUL) << 6) | (p[1] & 0x3FUL);
    n = 2;
  }
  *s = p + n;
  return c;
}

/* The whitespace Dart's `String.trim` removes. */
static int dart_is_space(unsigned long c) {
  return (c >= 0x09 && c <= 0x0D) || c == 0x20 || c == 0x85 || c == 0xA0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200A) || c == 0x2028 ||
         c == 0x2029 || c == 0x202F || c == 0x205F || c == 0x3000 ||
         c == 0xFEFF;
}

/* The bounds of `s[0, len)` trimmed the way Dart's `trim` trims. */
static void trim_bounds(const char *s, size_t len, size_t *b, size_t *e) {
  const unsigned char *p = (const unsigned char *)s;
  const unsigned char *end = p + len;
  const unsigned char *q = p;
  int any = 0;
  size_t first = 0, last = 0;
  while (q < end) {
    const unsigned char *st = q;
    unsigned long c = next_cp(&q, end);
    if (!dart_is_space(c)) {
      if (!any) {
        first = (size_t)(st - p);
        any = 1;
      }
      last = (size_t)(q - p);
    }
  }
  *b = any ? first : 0;
  *e = any ? last : 0;
}

static char *trim_n(const char *s, size_t len) {
  size_t b, e;
  trim_bounds(s, len, &b, &e);
  return som_strdup_n(s + b, e - b);
}

static char *trim_dup(const char *s) { return trim_n(s, strlen(s)); }

/* `s.trimRight()`. Owned. */
static char *trim_right_dup(const char *s) {
  size_t len = strlen(s);
  size_t b, e;
  trim_bounds(s, len, &b, &e);
  return som_strdup_n(s, e);
}

static int blank_n(const char *s, size_t len) {
  size_t b, e;
  trim_bounds(s, len, &b, &e);
  return e == b;
}

static int is_blank(const char *s) { return blank_n(s, strlen(s)); }

/* The index of `needle` in `s[0, len)` at or after `from`, or -1. */
static long long find(const char *s, size_t len, size_t from,
                      const char *needle) {
  size_t nl = strlen(needle);
  for (size_t i = from; i + nl <= len; i++) {
    if (memcmp(s + i, needle, nl) == 0) return (long long)i;
  }
  return -1;
}

/* Whether a code point is a cased letter: one whose lower case differs from
 * its upper case, as Dart's `toLowerCase() != toUpperCase()` decides on a
 * UTF-16 code unit. Covers ASCII and the cased letters of the common BMP
 * scripts (Latin, Greek, Cyrillic, Armenian, Georgian, Cherokee, Glagolitic,
 * Coptic, fullwidth Latin, circled letters, Roman numerals); a code point
 * outside the BMP is a surrogate pair in Dart and never cased there. */
static int is_cased(unsigned long c) {
  if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) return 1;
  if (c < 0x80) return 0;
  if (c == 0xB5) return 1;
  if (c >= 0xC0 && c <= 0xFF) return c != 0xD7 && c != 0xF7;
  if (c >= 0x100 && c <= 0x24F) {
    return !(c == 0x138 || c == 0x18D || c == 0x1AA || c == 0x1AB ||
             c == 0x1BA || c == 0x1BB || c == 0x1BE ||
             (c >= 0x1C0 && c <= 0x1C3) || c == 0x221 ||
             (c >= 0x234 && c <= 0x239));
  }
  if ((c >= 0x370 && c <= 0x373) || c == 0x376 || c == 0x377 ||
      (c >= 0x37B && c <= 0x37D) || c == 0x37F || c == 0x386)
    return 1;
  if (c >= 0x388 && c <= 0x3FF) {
    return !(c == 0x38B || c == 0x38D || c == 0x3A2 || c == 0x3F6);
  }
  if ((c >= 0x400 && c <= 0x481) || (c >= 0x48A && c <= 0x52F)) return 1;
  if ((c >= 0x531 && c <= 0x556) || (c >= 0x561 && c <= 0x587)) return 1;
  if ((c >= 0x10A0 && c <= 0x10C5) || (c >= 0x10D0 && c <= 0x10FA)) return 1;
  if ((c >= 0x13A0 && c <= 0x13F5) || (c >= 0x13F8 && c <= 0x13FD)) return 1;
  if (c >= 0x1E00 && c <= 0x1FFC) return 1;
  if (c >= 0x2160 && c <= 0x217F) return 1;
  if (c >= 0x24B6 && c <= 0x24E9) return 1;
  if (c >= 0x2C00 && c <= 0x2CF3) return 1;
  if ((c >= 0xA640 && c <= 0xA69B) || (c >= 0xA722 && c <= 0xA7FF)) return 1;
  if ((c >= 0xFF21 && c <= 0xFF3A) || (c >= 0xFF41 && c <= 0xFF5A)) return 1;
  return 0;
}

static int is_word_cp(unsigned long c, size_t bytes) {
  if (c >= '0' && c <= '9') return 1;
  if (bytes == 4) return 0;
  return is_cased(c);
}

/* Whether the first character of `s` is a word character. */
static int word_char_first(const char *s, size_t len) {
  if (len == 0) return 0;
  const unsigned char *p = (const unsigned char *)s;
  const unsigned char *q = p;
  unsigned long c = next_cp(&q, p + len);
  return is_word_cp(c, (size_t)(q - p));
}

/* Whether the last character of `s[0, len)` is a word character. */
static int word_char_last(const char *s, size_t len) {
  if (len == 0) return 0;
  size_t i = len - 1;
  while (i > 0 && ((unsigned char)s[i] & 0xC0) == 0x80 && len - i < 4) i--;
  const unsigned char *p = (const unsigned char *)s + i;
  const unsigned char *q = p;
  unsigned long c = next_cp(&q, (const unsigned char *)s + len);
  if ((size_t)(q - p) != len - i) {
    /* Not a well-formed final sequence: judge the last byte alone. */
    unsigned char b = (unsigned char)s[len - 1];
    return is_word_cp(b, 1) && b < 0x80;
  }
  return is_word_cp(c, (size_t)(q - p));
}

/* Splits on `\n` only (Dart `split('\n')`; "" is one empty line). */
static void split_lines(const char *v, SomStrList *out) {
  som_strlist_init(out);
  const char *s = v;
  for (;;) {
    const char *nl = strchr(s, '\n');
    if (nl == NULL) {
      som_strlist_push_copy(out, s);
      return;
    }
    som_strlist_push(out, som_strdup_n(s, (size_t)(nl - s)));
    s = nl + 1;
  }
}

/* Joins `pieces[from, to]` (inclusive; empty when to < from) after `head`. */
static char *join_from(const char *head, const char *const *pieces,
                       long long from, long long to) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, head);
  for (long long k = from; k <= to; k++) {
    som_buf_putc(&b, '\n');
    som_buf_puts(&b, pieces[k]);
  }
  return som_buf_take(&b);
}

/* ---- the parse of one value ---------------------------------------------- */

typedef struct {
  size_t start;
  size_t end;
  SpecReviewAnnotationKind kind;
  size_t comment; /* index into comments, for a comment block */
  size_t q_first; /* questions of a question block */
  size_t q_len;
  int combined;
} Block;

typedef struct {
  size_t header;          /* value line of the header */
  size_t region_end;      /* last value line of the region (inclusive) */
  long long answer_line;  /* value line of `**Answer:**`, or -1 */
  char *id;
  char *topic;
  int starred;
  char *text;
  char *answer;
  SpecQuestionOption *options;
  size_t options_len;
  char *recommended; /* NULL for none */
} Question;

typedef struct {
  size_t block;
  char *id;
  char *author;
  char *text;
  char *context;
  char *header_prefix; /* the first line up to where the text starts */
  size_t marker_end;   /* where an id is inserted into the first line */
} Comment;

typedef struct {
  size_t start; /* byte offsets into the value; never exported */
  size_t end;
  size_t line;
  SpecMarkKind kind;
  char *text;
  char *new_text;
  char *comment;
} Mark;

typedef struct {
  size_t line;
  const char *code;
} MarkIssue;

typedef struct {
  SomStrList lines;
  unsigned char *code; /* per line: inside a fenced block (fence lines too) */
  Block *blocks;
  size_t blocks_len, blocks_cap;
  Comment *comments;
  size_t comments_len, comments_cap;
  Question *questions;
  size_t questions_len, questions_cap;
  Mark *marks;
  size_t marks_len, marks_cap;
  SomStrList malformed;
  /* Malformed inline marks: (value line, issue code) — `unclosed`, `nested`,
   * `noArrow`. The codes are static strings. */
  MarkIssue *mark_issues;
  size_t mark_issues_len, mark_issues_cap;
} Parsed;

#define LINE(p, k) ((p)->lines.items[(k)])

static void parsed_free(Parsed *p) {
  som_strlist_free(&p->lines);
  free(p->code);
  free(p->blocks);
  for (size_t i = 0; i < p->comments_len; i++) {
    Comment *c = &p->comments[i];
    free(c->id);
    free(c->author);
    free(c->text);
    free(c->context);
    free(c->header_prefix);
  }
  free(p->comments);
  for (size_t i = 0; i < p->questions_len; i++) {
    Question *q = &p->questions[i];
    free(q->id);
    free(q->topic);
    free(q->text);
    free(q->answer);
    for (size_t o = 0; o < q->options_len; o++) {
      free(q->options[o].letter);
      free(q->options[o].text);
    }
    free(q->options);
    free(q->recommended);
  }
  free(p->questions);
  for (size_t i = 0; i < p->marks_len; i++) {
    free(p->marks[i].text);
    free(p->marks[i].new_text);
    free(p->marks[i].comment);
  }
  free(p->marks);
  som_strlist_free(&p->malformed);
  free(p->mark_issues);
}

/* The fenced-code flag of every line. */
static unsigned char *code_lines(const SomStrList *lines) {
  unsigned char *code = calloc(lines->len ? lines->len : 1, 1);
  char fence = 0;
  size_t fence_len = 0;
  for (size_t i = 0; i < lines->len; i++) {
    const char *t = lstrip(lines->items[i]);
    if (fence == 0) {
      char c = t[0];
      if (c == '`' || c == '~') {
        size_t n = 0;
        while (t[n] == c) n++;
        if (n >= 3) {
          fence = c;
          fence_len = n;
          code[i] = 1;
        }
      }
    } else {
      code[i] = 1;
      size_t n = 0;
      while (t[n] == fence) n++;
      if (n >= fence_len && is_blank(t + n)) fence = 0;
    }
  }
  return code;
}

static int is_quote_line(const char *line) { return lstrip(line)[0] == '>'; }

/* The line inside the quote: after `>` and one following space. */
static const char *inner_of(const char *line) {
  const char *t = lstrip(line) + 1;
  if (*t == ' ') t++;
  return t;
}

static char *context_of(const Parsed *p, size_t block_start) {
  long long k = (long long)block_start - 1;
  while (k >= 0 && (is_blank(LINE(p, k)) || is_quote_line(LINE(p, k)))) k--;
  if (k < 0) return som_strdup("");
  long long end = k;
  while (k - 1 >= 0 && !is_blank(LINE(p, k - 1)) &&
         !is_quote_line(LINE(p, k - 1)))
    k--;
  return join_from(LINE(p, k), (const char *const *)p->lines.items, k + 1, end);
}

static int is_comment_number(const char *n) {
  if (n[0] < '1' || n[0] > '9') return 0;
  for (const char *s = n + 1; *s; s++) {
    if (*s < '0' || *s > '9') return 0;
  }
  return 1;
}

static void parse_comment(Parsed *p, size_t bi) {
  const Block *b = &p->blocks[bi];
  const char *raw0 = LINE(p, b->start);
  const char *rest = inner_of(raw0) + strlen(ARROW);
  if (starts_with(rest, VS16)) rest += strlen(VS16);
  size_t marker_end = (size_t)(rest - raw0);
  rest = lstrip(rest);
  char *id = NULL;
  if (starts_with(rest, "**C-")) {
    long long close = find(rest, strlen(rest), 4, "**");
    if (close >= 0) {
      char *n = som_strdup_n(rest + 4, (size_t)close - 4);
      if (is_comment_number(n)) {
        id = fmt("C-%s", n);
      } else {
        som_strlist_push(&p->malformed,
                         fmt("line %zu: comment id \"C-%s\" is not C-<number> "
                             "(SOM \xC2\xA7"
                             "11.9.1)",
                             b->start, n));
      }
      free(n);
      rest = lstrip(rest + close + 2);
    }
  }
  char *author = NULL;
  if (rest[0] == '(') {
    const char *close = strchr(rest, ')');
    if (close != NULL && close > rest) {
      author = som_strdup_n(rest + 1, (size_t)(close - rest - 1));
      rest = close + 1;
      if (rest[0] == ':') rest++;
      rest = lstrip(rest);
    }
  } else if (rest[0] == ':') {
    rest = lstrip(rest + 1);
  }
  char *header_prefix = som_strdup_n(raw0, (size_t)(rest - raw0));
  SomBuf tb;
  som_buf_init(&tb);
  som_buf_puts(&tb, rest);
  for (size_t k = b->start + 1; k <= b->end; k++) {
    const char *inner = inner_of(LINE(p, k));
    const char *t = lstrip(inner);
    if (starts_with(t, QOPEN) || starts_with(t, ANSWER_LABEL)) {
      som_strlist_push(&p->malformed,
                       fmt("line %zu: a comment block holds a question or an "
                           "answer; the question goes into its own block "
                           "after the comment (SOM \xC2\xA7"
                           "11.9.1)",
                           k));
    }
    som_buf_putc(&tb, '\n');
    som_buf_puts(&tb, inner);
  }
  char *joined = som_buf_take(&tb);
  Comment c;
  c.block = bi;
  c.id = id;
  c.author = author;
  c.text = trim_dup(joined);
  free(joined);
  c.context = context_of(p, b->start);
  c.header_prefix = header_prefix;
  c.marker_end = marker_end;
  PUSH(p->comments, p->comments_len, p->comments_cap, c);
}

static int is_question_id(const char *s) {
  if (!(s[0] >= 'A' && s[0] <= 'Z')) return 0;
  size_t i = 1;
  while ((s[i] >= 'A' && s[i] <= 'Z') || (s[i] >= '0' && s[i] <= '9')) i++;
  if (s[i] != '-') return 0;
  i++;
  if (!(s[i] >= '0' && s[i] <= '9')) return 0;
  while (s[i] >= '0' && s[i] <= '9') i++;
  return s[i] == '\0';
}

typedef struct {
  size_t k;
  char *id;
  char *topic;
  int starred;
  const char *rest; /* borrowed from the line */
} Header;

/* Parses a question header's remainder after `**❓ `; 0 when malformed. */
static int parse_header(const char *inner, Header *out) {
  const char *h = inner + strlen(QOPEN) + 1;
  const char *sep = strstr(h, EM_SEP);
  if (sep == NULL || sep == h) return 0;
  char *id = som_strdup_n(h, (size_t)(sep - h));
  if (!is_question_id(id)) {
    free(id);
    return 0;
  }
  const char *t = sep + strlen(EM_SEP);
  int starred = 0;
  if (starts_with(t, STAR " ")) {
    starred = 1;
    t += strlen(STAR) + 1;
  }
  const char *close = strstr(t, ":**");
  if (close == NULL) {
    free(id);
    return 0;
  }
  out->id = id;
  out->topic = som_strdup_n(t, (size_t)(close - t));
  out->starred = starred;
  const char *rest = close + 3;
  if (*rest == ' ') rest++;
  out->rest = rest;
  return 1;
}

static int is_letter(char c) { return c >= 'a' && c <= 'z'; }

/* The letter of a leading `(x)` or `**(x)**` in `s` (spaces skipped), as an
 * owned one-character string; NULL for none. */
static char *leading_letter(const char *s) {
  const unsigned char *q = (const unsigned char *)s;
  const unsigned char *end = q + strlen(s);
  while (q < end) {
    const unsigned char *st = q;
    if (!dart_is_space(next_cp(&q, end))) {
      q = st;
      break;
    }
  }
  const char *t = (const char *)q;
  if (starts_with(t, "**")) t += 2;
  if (t[0] == '(' && is_letter(t[1]) && t[2] == ')') {
    return som_strdup_n(t + 1, 1);
  }
  return NULL;
}

static int is_blank_trimmed(const char *s) {
  size_t b, e;
  trim_bounds(s, strlen(s), &b, &e);
  return e == b;
}

/* Contains `recommended` after ASCII lower-casing. */
static int says_recommended(const char *s) {
  const char *w = "recommended";
  size_t n = strlen(w), len = strlen(s);
  for (size_t i = 0; i + n <= len; i++) {
    size_t k = 0;
    while (k < n && tolower((unsigned char)s[i + k]) == w[k]) k++;
    if (k == n) return 1;
  }
  return 0;
}

/* The options of a question and its recommended letter (SOM §11.9.2), read
 * from `in[from..to]` (inclusive): one option per line, `- (a) …`, the
 * recommended one bold, `- **(b)** …`. The recommended letter is the first
 * bold option's; else the first option's whose text says "recommended"; else
 * the letter a `*Recommendation:*` line names; else none. */
static void parse_options(const char **in, long long from, long long to,
                          Question *qq) {
  SpecQuestionOption *opts = NULL;
  size_t len = 0, cap = 0;
  char letter = 0;
  char *text = NULL;
  int bold = 0;
#define CLOSE_OPTION()                                     \
  do {                                                     \
    if (letter) {                                          \
      SpecQuestionOption o;                                \
      o.letter = som_strdup_n(&letter, 1);                 \
      o.text = trim_dup(text);                             \
      o.bold = bold;                                       \
      PUSH(opts, len, cap, o);                             \
    }                                                      \
    free(text);                                            \
    text = NULL;                                           \
    letter = 0;                                            \
  } while (0)
  for (long long k = from; k <= to; k++) {
    const char *l = in[k];
    if (starts_with(l, "- ")) {
      const char *r = l + 2;
      size_t rl = strlen(r);
      if (rl >= 7 && starts_with(r, "**(") && is_letter(r[3]) &&
          strncmp(r + 4, ")**", 3) == 0) {
        CLOSE_OPTION();
        letter = r[3];
        text = som_strdup(r + 7);
        bold = 1;
        continue;
      }
      if (rl >= 3 && r[0] == '(' && is_letter(r[1]) && r[2] == ')') {
        CLOSE_OPTION();
        letter = r[1];
        text = som_strdup(r + 3);
        bold = 0;
        continue;
      }
    }
    if (letter && l[0] == ' ' && !is_blank_trimmed(l)) {
      char *a = trim_dup(text);
      char *b = trim_dup(l);
      free(text);
      text = fmt("%s %s", a, b);
      free(a);
      free(b);
      continue;
    }
    CLOSE_OPTION();
  }
  CLOSE_OPTION();
#undef CLOSE_OPTION
  qq->options = opts;
  qq->options_len = len;
  qq->recommended = NULL;
  for (size_t i = 0; i < len && !qq->recommended; i++) {
    if (opts[i].bold) qq->recommended = som_strdup(opts[i].letter);
  }
  for (size_t i = 0; i < len && !qq->recommended; i++) {
    if (says_recommended(opts[i].text)) {
      qq->recommended = som_strdup(opts[i].letter);
    }
  }
  const char *label = "*Recommendation:*";
  for (long long k = from; k <= to && !qq->recommended; k++) {
    const char *i = strstr(in[k], label);
    if (i == NULL) continue;
    qq->recommended = leading_letter(i + strlen(label));
  }
}

static void parse_questions(Parsed *p, size_t bi) {
  Block *b = &p->blocks[bi];
  size_t cnt = b->end - b->start + 1;
  const char **in = malloc(cnt * sizeof(char *));
  for (size_t k = 0; k < cnt; k++) in[k] = inner_of(LINE(p, b->start + k));
  b->combined = starts_with(in[0], COMBINED_OPENER);
  Header *hs = NULL;
  size_t hs_len = 0, hs_cap = 0;
  for (size_t k = 0; k < cnt; k++) {
    if (!starts_with(in[k], QOPEN " ")) continue;
    if (starts_with(in[k], COMBINED_OPENER)) continue;
    Header h;
    if (!parse_header(in[k], &h)) {
      som_strlist_push(&p->malformed,
                       fmt("line %zu: question header is not "
                           "\"**\xE2\x9D\x93 <ID> \xE2\x80\x94 <topic>:**\" "
                           "(SOM \xC2\xA7"
                           "11.9.2)",
                           b->start + k));
      continue;
    }
    h.k = k;
    PUSH(hs, hs_len, hs_cap, h);
  }
  b->q_first = p->questions_len;
  b->q_len = hs_len;
  for (size_t q = 0; q < hs_len; q++) {
    size_t k = hs[q].k;
    size_t region_end = q + 1 < hs_len ? hs[q + 1].k - 1 : cnt - 1;
    long long answer = -1;
    for (size_t m = k + 1; m <= region_end; m++) {
      if (starts_with(in[m], ANSWER_LABEL)) {
        answer = (long long)m;
        break;
      }
    }
    long long text_end = answer < 0 ? (long long)region_end : answer - 1;
    char *joined = join_from(hs[q].rest, in, (long long)k + 1, text_end);
    Question qq;
    parse_options(in, (long long)k + 1, text_end, &qq);
    qq.text = trim_dup(joined);
    free(joined);
    if (answer >= 0) {
      char *aj = join_from(in[answer] + strlen(ANSWER_LABEL), in, answer + 1,
                           (long long)region_end);
      qq.answer = trim_dup(aj);
      free(aj);
    } else {
      qq.answer = som_strdup("");
    }
    qq.header = b->start + k;
    qq.region_end = b->start + region_end;
    qq.answer_line = answer < 0 ? -1 : (long long)b->start + answer;
    qq.id = hs[q].id;
    qq.topic = hs[q].topic;
    qq.starred = hs[q].starred;
    PUSH(p->questions, p->questions_len, p->questions_cap, qq);
  }
  free(hs);
  free(in);
}

static const char *const K_OPENERS[5] = {"{>>", "{==", "{++", "{--", "{~~"};
static const char *const K_CLOSERS[5] = {"<<}", "==}", "++}", "--}", "~~}"};

static int contains_opener(const char *s, size_t len) {
  for (int i = 0; i < 5; i++) {
    if (find(s, len, 0, K_OPENERS[i]) >= 0) return 1;
  }
  return 0;
}

/* The offset of the first blank line's start after `from` (the paragraph
 * end), or the text length. */
static size_t paragraph_end(const char *t, size_t len, size_t from) {
  long long i = find(t, len, from, "\n");
  while (i >= 0) {
    long long next = find(t, len, (size_t)i + 1, "\n");
    size_t le = next < 0 ? len : (size_t)next;
    if (blank_n(t + i + 1, le - (size_t)i - 1)) return (size_t)i;
    i = next;
  }
  return len;
}

static size_t line_of(const size_t *line_start, size_t n, size_t offset) {
  size_t lo = 0;
  for (size_t k = 0; k < n; k++) {
    if (line_start[k] <= offset) lo = k;
  }
  return lo;
}

static void add_mark(Parsed *p, size_t start, size_t end, size_t line,
                     SpecMarkKind kind, char *text, char *new_text,
                     char *comment) {
  Mark m = {start, end, line, kind, text, new_text, comment};
  PUSH(p->marks, p->marks_len, p->marks_cap, m);
}

static void add_issue(Parsed *p, size_t line, const char *code) {
  MarkIssue m = {line, code};
  PUSH(p->mark_issues, p->mark_issues_len, p->mark_issues_cap, m);
}

static void scan_segment(Parsed *p, const char *seg, size_t len, size_t base,
                         const size_t *line_start) {
  size_t i = 0;
  while (i < len) {
    char c = seg[i];
    if (c == '`') {
      size_t n = 0;
      while (i + n < len && seg[i + n] == '`') n++;
      /* Find the next run of exactly n backticks. */
      size_t j = i + n;
      long long close_at = -1;
      while (j < len) {
        if (seg[j] == '`') {
          size_t m = 0;
          while (j + m < len && seg[j + m] == '`') m++;
          if (m == n) {
            close_at = (long long)j;
            break;
          }
          j += m;
        } else {
          j++;
        }
      }
      i = close_at < 0 ? i + n : (size_t)close_at + n;
      continue;
    }
    if (c != '{' || i + 3 > len) {
      i++;
      continue;
    }
    int oi = -1;
    for (int o = 0; o < 5; o++) {
      if (memcmp(seg + i, K_OPENERS[o], 3) == 0) {
        oi = o;
        break;
      }
    }
    if (oi < 0) {
      i++;
      continue;
    }
    long long close = find(seg, len, i + 3, K_CLOSERS[oi]);
    size_t pend = paragraph_end(seg, len, i);
    size_t line = line_of(line_start, p->lines.len, base + i);
    if (close < 0 || (size_t)close > pend) {
      som_strlist_push(&p->malformed,
                       fmt("line %zu: inline mark \"%s\" is not closed in its "
                           "paragraph (SOM \xC2\xA7"
                           "11.9.3)",
                           line, K_OPENERS[oi]));
      add_issue(p, line, "unclosed");
      i += 3;
      continue;
    }
    const char *inner = seg + i + 3;
    size_t inner_len = (size_t)close - i - 3;
    if (contains_opener(inner, inner_len)) {
      som_strlist_push(&p->malformed,
                       fmt("line %zu: inline marks do not nest (SOM \xC2\xA7"
                           "11.9.3)",
                           line));
      add_issue(p, line, "nested");
      i = (size_t)close + 3;
      continue;
    }
    size_t end = (size_t)close + 3;
    switch (oi) {
      case 0:
        add_mark(p, base + i, base + end, line, SPEC_MARK_COMMENT,
                 som_strdup(""), NULL, trim_n(inner, inner_len));
        break;
      case 1: {
        char *comment = NULL;
        if (end + 3 <= len && memcmp(seg + end, "{>>", 3) == 0) {
          long long c2 = find(seg, len, end + 3, "<<}");
          if (c2 >= 0 && (size_t)c2 <= paragraph_end(seg, len, end)) {
            const char *ci = seg + end + 3;
            size_t ci_len = (size_t)c2 - end - 3;
            if (!contains_opener(ci, ci_len)) {
              comment = trim_n(ci, ci_len);
              end = (size_t)c2 + 3;
            }
          }
        }
        add_mark(p, base + i, base + end, line, SPEC_MARK_HIGHLIGHT,
                 trim_n(inner, inner_len), NULL, comment);
        break;
      }
      case 2:
        add_mark(p, base + i, base + end, line, SPEC_MARK_INSERTION,
                 trim_n(inner, inner_len), NULL, NULL);
        break;
      case 3:
        add_mark(p, base + i, base + end, line, SPEC_MARK_DELETION,
                 trim_n(inner, inner_len), NULL, NULL);
        break;
      default: {
        long long arrow = find(inner, inner_len, 0, "~>");
        if (arrow < 0) {
          som_strlist_push(&p->malformed,
                           fmt("line %zu: a substitution has no \"~>\" "
                               "(SOM \xC2\xA7"
                               "11.9.3)",
                               line));
          add_issue(p, line, "noArrow");
          i = end;
          continue;
        }
        add_mark(p, base + i, base + end, line, SPEC_MARK_SUBSTITUTION,
                 trim_n(inner, (size_t)arrow),
                 trim_n(inner + arrow + 2, inner_len - (size_t)arrow - 2),
                 NULL);
        break;
      }
    }
    i = end;
  }
}

static void parse_marks(Parsed *p) {
  size_t n = p->lines.len;
  size_t *line_start = malloc((n ? n : 1) * sizeof(size_t));
  size_t off = 0;
  for (size_t k = 0; k < n; k++) {
    line_start[k] = off;
    off += strlen(LINE(p, k)) + 1;
  }
  char *value = som_strlist_join(&p->lines, "\n");
  size_t k = 0;
  while (k < n) {
    if (p->code[k]) {
      k++;
      continue;
    }
    /* A run of non-code lines is scanned as one segment. */
    size_t seg_start_line = k;
    while (k < n && !p->code[k]) k++;
    size_t seg_start = line_start[seg_start_line];
    size_t seg_end = line_start[k - 1] + strlen(LINE(p, k - 1));
    scan_segment(p, value + seg_start, seg_end - seg_start, seg_start,
                 line_start);
  }
  free(value);
  free(line_start);
}

static void parse(const char *value, Parsed *p) {
  memset(p, 0, sizeof(*p));
  split_lines(value, &p->lines);
  p->code = code_lines(&p->lines);
  som_strlist_init(&p->malformed);
  size_t n = p->lines.len;
  size_t i = 0;
  while (i < n) {
    if (p->code[i] || !is_quote_line(LINE(p, i))) {
      i++;
      continue;
    }
    size_t s = i;
    while (i + 1 < n && !p->code[i + 1] && is_quote_line(LINE(p, i + 1))) i++;
    size_t e = i;
    const char *first = inner_of(LINE(p, s));
    if (starts_with(first, ARROW)) {
      Block b = {s, e, SPEC_REVIEW_ANNOTATION_COMMENT, p->comments_len, 0, 0, 0};
      PUSH(p->blocks, p->blocks_len, p->blocks_cap, b);
      parse_comment(p, p->blocks_len - 1);
    } else if (starts_with(first, QOPEN)) {
      Block b = {s, e, SPEC_REVIEW_ANNOTATION_QUESTION, 0, 0, 0, 0};
      PUSH(p->blocks, p->blocks_len, p->blocks_cap, b);
      parse_questions(p, p->blocks_len - 1);
    }
    i = e + 1;
  }
  parse_marks(p);
}

/* ---- annotation records -------------------------------------------------- */

void spec_review_annotation_free(SpecReviewAnnotation *a) {
  free(a->path);
  free(a->field);
  free(a->id);
  free(a->qualified_id);
  free(a->author);
  free(a->text);
  free(a->context);
  free(a->topic);
  free(a->answer);
  for (size_t i = 0; i < a->options_len; i++) {
    free(a->options[i].letter);
    free(a->options[i].text);
  }
  free(a->options);
  free(a->recommended);
  free(a->new_text);
  free(a->comment);
  memset(a, 0, sizeof(*a));
}

int spec_review_annotation_is_open(const SpecReviewAnnotation *a) {
  return a->kind == SPEC_REVIEW_ANNOTATION_QUESTION &&
         (a->answer == NULL || a->answer[0] == '\0');
}

void spec_review_annotation_list_init(SpecReviewAnnotationList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_review_annotation_list_free(SpecReviewAnnotationList *l) {
  for (size_t i = 0; i < l->len; i++) spec_review_annotation_free(&l->items[i]);
  free(l->items);
  spec_review_annotation_list_init(l);
}

static char *dup_or_null(const char *s) { return s ? som_strdup(s) : NULL; }

static void put_key(SomBuf *b, int *first, const char *key) {
  if (!*first) som_buf_putc(b, ',');
  *first = 0;
  char *k = som_json_encode_str(key);
  som_buf_puts(b, k);
  free(k);
  som_buf_putc(b, ':');
}

static void put_str(SomBuf *b, int *first, const char *key, const char *v) {
  put_key(b, first, key);
  if (v == NULL) {
    som_buf_puts(b, "null");
    return;
  }
  char *e = som_json_encode_str(v);
  som_buf_puts(b, e);
  free(e);
}

static void put_bool(SomBuf *b, int *first, const char *key, int v) {
  put_key(b, first, key);
  som_buf_puts(b, v ? "true" : "false");
}

static void put_int(SomBuf *b, int *first, const char *key, long long v) {
  put_key(b, first, key);
  som_buf_puti(b, v);
}

char *spec_review_annotation_answer_letter(const SpecReviewAnnotation *a) {
  if (a->kind != SPEC_REVIEW_ANNOTATION_QUESTION) return NULL;
  return leading_letter(a->answer ? a->answer : "");
}

char *spec_question_option_to_json(const SpecQuestionOption *o) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "letter", o->letter);
  put_str(&b, &first, "text", o->text);
  put_bool(&b, &first, "bold", o->bold);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_review_annotation_to_json(const SpecReviewAnnotation *a) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "kind", spec_review_annotation_kind_name(a->kind));
  put_str(&b, &first, "path", a->path);
  put_str(&b, &first, "field", a->field);
  put_int(&b, &first, "line", (long long)a->line);
  switch (a->kind) {
    case SPEC_REVIEW_ANNOTATION_COMMENT:
      put_str(&b, &first, "id", a->id);
      put_str(&b, &first, "qualifiedId", a->qualified_id);
      put_str(&b, &first, "author", a->author);
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "context", a->context);
      break;
    case SPEC_REVIEW_ANNOTATION_QUESTION:
      put_str(&b, &first, "id", a->id);
      put_str(&b, &first, "topic", a->topic);
      put_bool(&b, &first, "starred", a->starred);
      put_bool(&b, &first, "combined", a->combined);
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "answer", a->answer);
      put_bool(&b, &first, "open", spec_review_annotation_is_open(a));
      put_key(&b, &first, "options");
      som_buf_putc(&b, '[');
      for (size_t i = 0; i < a->options_len; i++) {
        if (i) som_buf_putc(&b, ',');
        char *o = spec_question_option_to_json(&a->options[i]);
        som_buf_puts(&b, o);
        free(o);
      }
      som_buf_putc(&b, ']');
      put_str(&b, &first, "recommended", a->recommended);
      {
        char *al = spec_review_annotation_answer_letter(a);
        put_str(&b, &first, "answerLetter", al);
        free(al);
      }
      break;
    case SPEC_REVIEW_ANNOTATION_MARK:
      put_str(&b, &first, "markKind", spec_mark_kind_name(a->mark_kind));
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "newText", a->new_text);
      put_str(&b, &first, "comment", a->comment);
      break;
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_review_annotation_counts_to_json(const SpecReviewAnnotationCounts *c) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_int(&b, &first, "questions", (long long)c->questions);
  put_int(&b, &first, "openQuestions", (long long)c->open_questions);
  put_int(&b, &first, "answeredQuestions", (long long)c->answered_questions);
  put_int(&b, &first, "comments", (long long)c->comments);
  put_int(&b, &first, "marks", (long long)c->marks);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

typedef struct {
  size_t line;
  int rank; /* 0: a block, 1: a mark */
  size_t seq;
  SpecReviewAnnotation a;
} Ordered;

static int cmp_ordered(const void *x, const void *y) {
  const Ordered *a = (const Ordered *)x;
  const Ordered *b = (const Ordered *)y;
  if (a->line != b->line) return a->line < b->line ? -1 : 1;
  if (a->rank != b->rank) return a->rank < b->rank ? -1 : 1;
  if (a->seq != b->seq) return a->seq < b->seq ? -1 : 1;
  return 0;
}

static SpecReviewAnnotation blank_annotation(SpecReviewAnnotationKind kind,
                                             const char *path,
                                             const char *field, size_t line) {
  SpecReviewAnnotation a;
  memset(&a, 0, sizeof(a));
  a.kind = kind;
  a.path = som_strdup(path);
  a.field = dup_or_null(field);
  a.line = line;
  return a;
}

/* The annotations of one value, in order: by line, blocks before marks, marks
 * in scan order; appended to `out`. */
static void annotations_of(const Parsed *p, const char *path, const char *field,
                           const char *qualifier, SpecReviewAnnotationList *out) {
  Ordered *o = NULL;
  size_t len = 0, cap = 0, seq = 0;
  for (size_t bi = 0; bi < p->blocks_len; bi++) {
    const Block *b = &p->blocks[bi];
    if (b->kind == SPEC_REVIEW_ANNOTATION_COMMENT) {
      const Comment *c = &p->comments[b->comment];
      Ordered e;
      e.line = b->start;
      e.rank = 0;
      e.seq = seq++;
      e.a = blank_annotation(SPEC_REVIEW_ANNOTATION_COMMENT, path, field,
                             b->start);
      e.a.id = dup_or_null(c->id);
      e.a.qualified_id = (qualifier != NULL && c->id != NULL)
                             ? fmt("%s %s", qualifier, c->id)
                             : NULL;
      e.a.author = dup_or_null(c->author);
      e.a.text = som_strdup(c->text);
      e.a.context = som_strdup(c->context);
      e.a.answer = som_strdup("");
      PUSH(o, len, cap, e);
    } else {
      for (size_t qi = 0; qi < b->q_len; qi++) {
        const Question *q = &p->questions[b->q_first + qi];
        Ordered e;
        e.line = q->header;
        e.rank = 0;
        e.seq = seq++;
        e.a = blank_annotation(SPEC_REVIEW_ANNOTATION_QUESTION, path, field,
                               q->header);
        e.a.id = som_strdup(q->id);
        e.a.topic = som_strdup(q->topic);
        e.a.starred = q->starred;
        e.a.combined = b->combined;
        e.a.text = som_strdup(q->text);
        e.a.context = som_strdup("");
        e.a.answer = som_strdup(q->answer);
        e.a.options_len = q->options_len;
        e.a.options = q->options_len
                          ? malloc(q->options_len * sizeof(SpecQuestionOption))
                          : NULL;
        for (size_t oi = 0; oi < q->options_len; oi++) {
          e.a.options[oi].letter = som_strdup(q->options[oi].letter);
          e.a.options[oi].text = som_strdup(q->options[oi].text);
          e.a.options[oi].bold = q->options[oi].bold;
        }
        e.a.recommended = dup_or_null(q->recommended);
        PUSH(o, len, cap, e);
      }
    }
  }
  for (size_t mi = 0; mi < p->marks_len; mi++) {
    const Mark *m = &p->marks[mi];
    Ordered e;
    e.line = m->line;
    e.rank = 1;
    e.seq = seq++;
    e.a = blank_annotation(SPEC_REVIEW_ANNOTATION_MARK, path, field, m->line);
    e.a.mark_kind = m->kind;
    e.a.text = som_strdup(m->text);
    e.a.context = som_strdup("");
    e.a.answer = som_strdup("");
    e.a.new_text = dup_or_null(m->new_text);
    e.a.comment = dup_or_null(m->comment);
    PUSH(o, len, cap, e);
  }
  if (len > 1) qsort(o, len, sizeof(Ordered), cmp_ordered);
  for (size_t i = 0; i < len; i++) PUSH(out->items, out->len, out->cap, o[i].a);
  free(o);
}

/* ---- paragraph and line helpers ----------------------------------------- */

/* The last line of every paragraph of a value, blank-separated and
 * fence-aware (a blank line inside a fenced block does not split). Returns
 * the count; `*ends` is owned by the caller. */
static size_t paragraph_ends(const SomStrList *lines, const unsigned char *code,
                             size_t **ends) {
  size_t *out = NULL;
  size_t len = 0, cap = 0;
  size_t k = 0;
  while (k < lines->len) {
    if (is_blank(lines->items[k]) && !code[k]) {
      k++;
      continue;
    }
    while (k + 1 < lines->len &&
           !(is_blank(lines->items[k + 1]) && !code[k + 1]))
      k++;
    PUSH(out, len, cap, k);
    k++;
  }
  *ends = out;
  return len;
}

/* Inserts `block` after value line `end` (-1: at the start), one blank line
 * on each side. Owned. */
static char *insert_after_line(const char *value, long long end,
                               const SomStrList *block) {
  if (value[0] == '\0') return som_strlist_join(block, "\n");
  SomStrList lines;
  split_lines(value, &lines);
  SomStrList out;
  som_strlist_init(&out);
  for (long long k = 0; k <= end; k++) som_strlist_push_copy(&out, lines.items[k]);
  if (end + 1 > 0) som_strlist_push_copy(&out, "");
  for (size_t k = 0; k < block->len; k++)
    som_strlist_push_copy(&out, block->items[k]);
  size_t rest = (size_t)(end + 1);
  if (rest < lines.len) {
    if (!is_blank(lines.items[rest])) som_strlist_push_copy(&out, "");
    for (size_t k = rest; k < lines.len; k++)
      som_strlist_push_copy(&out, lines.items[k]);
  }
  char *s = som_strlist_join(&out, "\n");
  som_strlist_free(&out);
  som_strlist_free(&lines);
  return s;
}

/* Joins `lines` minus `[from, to]` (inclusive). Owned. */
static char *join_without(const SomStrList *lines, size_t from, size_t to) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  for (size_t k = 0; k < lines->len; k++) {
    if (k >= from && k <= to) continue;
    if (!first) som_buf_putc(&b, '\n');
    first = 0;
    som_buf_puts(&b, lines->items[k]);
  }
  return som_buf_take(&b);
}

/* Removes value lines [s, e] and one adjacent blank line. Owned. */
static char *remove_lines(const char *value, size_t s, size_t e) {
  SomStrList lines;
  split_lines(value, &lines);
  size_t from = s, to = e;
  if (to + 1 < lines.len && is_blank(lines.items[to + 1])) {
    to++;
  } else if (from >= 1 && is_blank(lines.items[from - 1])) {
    from--;
  }
  char *out = join_without(&lines, from, to);
  som_strlist_free(&lines);
  if (is_blank(out)) {
    free(out);
    return som_strdup("");
  }
  return out;
}

/* Pushes `t[from..]` quoted: `>` for an empty line, else `> line`. */
static void push_quoted(SomStrList *out, const SomStrList *t, size_t from) {
  for (size_t k = from; k < t->len; k++) {
    if (t->items[k][0] == '\0') {
      som_strlist_push_copy(out, ">");
    } else {
      som_strlist_push(out, fmt("> %s", t->items[k]));
    }
  }
}

/* Replaces lines [from, to] of `lines` by `with` (in place). */
static void replace_range(SomStrList *lines, size_t from, size_t to,
                          const SomStrList *with) {
  SomStrList out;
  som_strlist_init(&out);
  for (size_t k = 0; k < from; k++) som_strlist_push_copy(&out, lines->items[k]);
  for (size_t k = 0; k < with->len; k++)
    som_strlist_push_copy(&out, with->items[k]);
  for (size_t k = to + 1; k < lines->len; k++)
    som_strlist_push_copy(&out, lines->items[k]);
  som_strlist_free(lines);
  *lines = out;
}

void spec_format_comment_block(const char *id, const char *text,
                               const char *author, SomStrList *out) {
  SomStrList t;
  split_lines(text, &t);
  SomBuf head;
  som_buf_init(&head);
  som_buf_puts(&head, "> " ARROW VS16 " **");
  som_buf_puts(&head, id);
  som_buf_puts(&head, "**");
  if (author != NULL && author[0] != '\0') {
    som_buf_puts(&head, " (");
    som_buf_puts(&head, author);
    som_buf_puts(&head, "):");
  }
  if (t.items[0][0] != '\0') {
    som_buf_putc(&head, ' ');
    som_buf_puts(&head, t.items[0]);
  }
  som_strlist_init(out);
  som_strlist_push(out, som_buf_take(&head));
  push_quoted(out, &t, 1);
  som_strlist_free(&t);
}

void spec_format_question_block(const SpecQuestionDraft *q, SomStrList *out) {
  SomStrList t;
  split_lines(q->text, &t);
  som_strlist_init(out);
  som_strlist_push(out, fmt("> " QOPEN " %s" EM_SEP "%s%s:** %s", q->id,
                            q->starred ? STAR " " : "", q->topic, t.items[0]));
  push_quoted(out, &t, 1);
  for (size_t i = 0; i < q->options_len; i++) {
    const char *o = q->options[i];
    if (q->recommended != NULL && strlen(o) >= 3 && o[0] == '(' &&
        strncmp(o + 1, q->recommended, strlen(q->recommended)) == 0 &&
        o[1 + strlen(q->recommended)] == ')') {
      som_strlist_push(out, fmt("> - **(%s)**%s", q->recommended, o + 3));
    } else {
      som_strlist_push(out, fmt("> - %s", o));
    }
  }
  int has_rec = q->recommendation != NULL && q->recommendation[0] != '\0';
  int has_asm = q->assumption != NULL && q->assumption[0] != '\0';
  if (has_rec || has_asm) {
    som_strlist_push_copy(out, ">");
    if (has_rec) {
      som_strlist_push(out, fmt("> *Recommendation:* %s", q->recommendation));
    }
    if (has_asm) {
      som_strlist_push(out, fmt("> *Working assumption until answered:* %s",
                                q->assumption));
    }
  }
  som_strlist_push_copy(out, ">");
  som_strlist_push_copy(out, "> " ANSWER_LABEL);
  som_strlist_free(&t);
}

static int is_sp(char c) { return c == ' ' || c == '\t'; }

/* Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
 * never join two words, never leave a double space or a space before
 * punctuation, and a mark that was a whole line leaves no blank line. Owned. */
static char *replace_mark(const char *value, const Mark *m,
                          const char *replacement) {
  size_t blen = m->start;
  const char *after = value + m->end;
  size_t rlen = strlen(replacement);
  int pre = 0, post = 0;
  if (rlen == 0) {
    size_t tb = blen;
    while (tb > 0 && is_sp(value[tb - 1])) tb--;
    int line_start = tb == 0 || value[tb - 1] == '\n';
    size_t as = 0;
    while (is_sp(after[as])) as++;
    int line_end = after[as] == '\0' || after[as] == '\n';
    if (line_start && line_end) {
      /* The mark was the whole line: the line goes, and with it one of the
       * newlines around it; a blank line left doubled is merged. */
      blen = tb;
      after += as;
      if (after[0] == '\n') {
        after++;
      } else if (blen > 0 && value[blen - 1] == '\n') {
        blen--;
      }
      if ((blen == 0 ||
           (blen >= 2 && value[blen - 1] == '\n' && value[blen - 2] == '\n')) &&
          after[0] == '\n') {
        after++;
      }
      if (after[0] == '\0') {
        while (blen > 0 && value[blen - 1] == '\n') blen--;
      }
    } else if (blen > 0 && is_sp(value[blen - 1])) {
      if (is_sp(after[0])) {
        while (is_sp(after[0])) after++;
      } else if (after[0] == '\0' || after[0] == '\n' ||
                 strchr(".,;:!?)]}", after[0]) != NULL) {
        while (blen > 0 && is_sp(value[blen - 1])) blen--;
      }
    } else if ((blen == 0 || value[blen - 1] == '\n') && is_sp(after[0])) {
      while (is_sp(after[0])) after++;
    }
  } else {
    size_t alen = strlen(after);
    /* Never join two words: a mark written flush against a word keeps a
     * space on that side. */
    pre = word_char_last(value, blen) && word_char_first(replacement, rlen);
    post = word_char_last(replacement, rlen) && alen > 0 &&
           word_char_first(after, alen);
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, value, blen);
  if (pre) som_buf_putc(&b, ' ');
  som_buf_puts(&b, replacement);
  if (post) som_buf_putc(&b, ' ');
  som_buf_puts(&b, after);
  return som_buf_take(&b);
}

static const char *mark_replacement(const Mark *m, int accept) {
  switch (m->kind) {
    case SPEC_MARK_INSERTION:
      return accept ? m->text : "";
    case SPEC_MARK_DELETION:
      return accept ? "" : m->text;
    case SPEC_MARK_SUBSTITUTION:
      return accept ? m->new_text : m->text;
    case SPEC_MARK_HIGHLIGHT:
      return m->text;
    case SPEC_MARK_COMMENT:
      return "";
  }
  return "";
}

char *spec_apply_inline_marks_text(const char *value, int accept) {
  char *v = som_strdup(value);
  Parsed p;
  parse(value, &p);
  for (size_t k = p.marks_len; k-- > 0;) {
    const Mark *m = &p.marks[k];
    char *next = replace_mark(v, m, mark_replacement(m, accept));
    free(v);
    v = next;
  }
  parsed_free(&p);
  return v;
}

char *spec_strip_annotations_text(const char *value) {
  char *v = som_strdup(value);
  /* Blocks, from the last up, so earlier line numbers stay valid. */
  for (;;) {
    Parsed p;
    parse(v, &p);
    if (p.blocks_len == 0) {
      parsed_free(&p);
      break;
    }
    const Block *b = &p.blocks[p.blocks_len - 1];
    char *next = remove_lines(v, b->start, b->end);
    parsed_free(&p);
    free(v);
    v = next;
  }
  for (;;) {
    Parsed p;
    parse(v, &p);
    if (p.marks_len == 0) {
      parsed_free(&p);
      break;
    }
    const Mark *m = &p.marks[p.marks_len - 1];
    char *next = replace_mark(v, m, mark_replacement(m, 1));
    parsed_free(&p);
    free(v);
    v = next;
  }
  return v;
}

/* ---- document level ------------------------------------------------------ */

typedef struct {
  char *path;
  char *field; /* NULL for content */
  char *text;
} Value;

typedef struct {
  Value *items;
  size_t len, cap;
} Values;

static void values_free(Values *v) {
  for (size_t i = 0; i < v->len; i++) {
    free(v->items[i].path);
    free(v->items[i].field);
    free(v->items[i].text);
  }
  free(v->items);
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* Every value as (path, field or NULL, text), in document order. */
static void values_of(const SpecDocument *doc, Values *out) {
  memset(out, 0, sizeof(*out));
  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  if (paths.len > 1) qsort(paths.items, paths.len, sizeof(char *), cmp_str);
  for (size_t i = 0; i < paths.len; i++) {
    const char *t = spec_document_content(doc, paths.items[i]);
    Value v = {som_strdup(paths.items[i]), NULL, som_strdup(t ? t : "")};
    PUSH(out->items, out->len, out->cap, v);
  }
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  if (paths.len > 1) qsort(paths.items, paths.len, sizeof(char *), cmp_str);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList fields;
    spec_document_form_field_names(doc, paths.items[i], &fields);
    if (fields.len > 1) qsort(fields.items, fields.len, sizeof(char *), cmp_str);
    for (size_t f = 0; f < fields.len; f++) {
      const char *t =
          spec_document_form_field(doc, paths.items[i], fields.items[f]);
      Value v = {som_strdup(paths.items[i]), som_strdup(fields.items[f]),
                 som_strdup(t ? t : "")};
      PUSH(out->items, out->len, out->cap, v);
    }
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
}

static const char *get_value(const SpecDocument *doc, const char *path,
                             const char *field) {
  const char *v = field == NULL ? spec_document_content(doc, path)
                                : spec_document_form_field(doc, path, field);
  return v ? v : "";
}

static void set_value(SpecDocument *doc, const char *path, const char *field,
                      const char *value) {
  if (field == NULL) {
    spec_document_set_content(doc, path, value);
  } else {
    spec_document_set_form_field(doc, path, field, value);
  }
}

SpecReviewAnnotations spec_review_annotations_make(SpecDocument *doc,
                                                   const char *qualifier) {
  SpecReviewAnnotations r;
  r.doc = doc;
  r.qualifier = qualifier;
  return r;
}

void spec_review_annotations_list(const SpecReviewAnnotations *r,
                                  SpecReviewAnnotationList *out) {
  spec_review_annotation_list_init(out);
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    Parsed p;
    parse(vals.items[i].text, &p);
    annotations_of(&p, vals.items[i].path, vals.items[i].field, r->qualifier,
                   out);
    parsed_free(&p);
  }
  values_free(&vals);
}

SpecReviewAnnotationCounts
spec_review_annotations_counts(const SpecReviewAnnotations *r) {
  SpecReviewAnnotationCounts c = {0, 0, 0, 0, 0};
  SpecReviewAnnotationList l;
  spec_review_annotations_list(r, &l);
  for (size_t i = 0; i < l.len; i++) {
    switch (l.items[i].kind) {
      case SPEC_REVIEW_ANNOTATION_QUESTION:
        c.questions++;
        if (spec_review_annotation_is_open(&l.items[i])) c.open_questions++;
        break;
      case SPEC_REVIEW_ANNOTATION_COMMENT:
        c.comments++;
        break;
      case SPEC_REVIEW_ANNOTATION_MARK:
        c.marks++;
        break;
    }
  }
  c.answered_questions = c.questions - c.open_questions;
  spec_review_annotation_list_free(&l);
  return c;
}

static long long highest_comment_number(const SpecReviewAnnotations *r) {
  long long high = 0;
  SpecReviewAnnotationList l;
  spec_review_annotations_list(r, &l);
  for (size_t i = 0; i < l.len; i++) {
    const SpecReviewAnnotation *a = &l.items[i];
    if (a->kind == SPEC_REVIEW_ANNOTATION_COMMENT && a->id != NULL) {
      long long n = strtoll(a->id + 2, NULL, 10);
      if (n > high) high = n;
    }
  }
  spec_review_annotation_list_free(&l);
  return high;
}

char *spec_review_annotations_next_comment_id(const SpecReviewAnnotations *r,
                                              long long floor) {
  long long high = highest_comment_number(r);
  return fmt("C-%lld", (high > floor ? high : floor) + 1);
}

void spec_review_annotations_assign_comment_ids(const SpecReviewAnnotations *r,
                                                long long floor,
                                                SomStrList *out) {
  som_strlist_init(out);
  long long high = highest_comment_number(r);
  long long next = (high > floor ? high : floor) + 1;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    Parsed p;
    parse(vals.items[i].text, &p);
    int any = 0;
    SomStrList lines;
    split_lines(vals.items[i].text, &lines);
    for (size_t ci = 0; ci < p.comments_len; ci++) {
      const Comment *c = &p.comments[ci];
      if (c->id != NULL) continue;
      any = 1;
      char *id = fmt("C-%lld", next++);
      size_t line = p.blocks[c->block].start;
      const char *raw = lines.items[line];
      size_t at = c->marker_end;
      size_t raw_len = strlen(raw);
      char *updated;
      if (at < raw_len && raw[at] == ' ') {
        updated = fmt("%.*s**%s** %s", (int)(at + 1), raw, id, raw + at + 1);
      } else if (at >= raw_len) {
        updated = fmt("%s **%s**", raw, id);
      } else {
        updated = fmt("%.*s **%s** %s", (int)at, raw, id, raw + at);
      }
      free(lines.items[line]);
      lines.items[line] = updated;
      som_strlist_push(out, id);
    }
    if (any) {
      char *joined = som_strlist_join(&lines, "\n");
      set_value(r->doc, vals.items[i].path, vals.items[i].field, joined);
      free(joined);
    }
    som_strlist_free(&lines);
    parsed_free(&p);
  }
  values_free(&vals);
}

/* The last line of paragraph `after_paragraph` (-1 for -1); 0 on error. */
static int paragraph_last_line(const char *value, long long after_paragraph,
                               long long *out, SpecReviewAnnotationError *err) {
  if (after_paragraph < 0) {
    *out = -1;
    return 1;
  }
  SomStrList lines;
  split_lines(value, &lines);
  unsigned char *code = code_lines(&lines);
  size_t *ends = NULL;
  size_t n = paragraph_ends(&lines, code, &ends);
  int ok = 1;
  if (value[0] == '\0' || (unsigned long long)after_paragraph >= n) {
    set_error(err, "the value has %zu paragraph(s); there is no paragraph %lld",
          value[0] == '\0' ? (size_t)0 : n, after_paragraph);
    ok = 0;
  } else {
    *out = (long long)ends[after_paragraph];
  }
  free(ends);
  free(code);
  som_strlist_free(&lines);
  return ok;
}

char *spec_review_annotations_insert_comment(const SpecReviewAnnotations *r,
                                             const char *path,
                                             const char *field,
                                             long long after_paragraph,
                                             const char *text,
                                             const char *author,
                                             const char *id,
                                             SpecReviewAnnotationError *err) {
  char *cid = id != NULL ? som_strdup(id)
                         : spec_review_annotations_next_comment_id(r, 0);
  char *value = som_strdup(get_value(r->doc, path, field));
  long long end;
  if (!paragraph_last_line(value, after_paragraph, &end, err)) {
    free(value);
    free(cid);
    return NULL;
  }
  SomStrList block;
  spec_format_comment_block(cid, text, author, &block);
  char *updated = insert_after_line(value, end, &block);
  set_value(r->doc, path, field, updated);
  free(updated);
  som_strlist_free(&block);
  free(value);
  return cid;
}

int spec_review_annotations_insert_question(const SpecReviewAnnotations *r,
                                            const char *path,
                                            const char *field,
                                            long long after_paragraph,
                                            const SpecQuestionDraft *question,
                                            SpecReviewAnnotationError *err) {
  char *value = som_strdup(get_value(r->doc, path, field));
  long long end;
  if (!paragraph_last_line(value, after_paragraph, &end, err)) {
    free(value);
    return 0;
  }
  SomStrList block;
  spec_format_question_block(question, &block);
  char *updated = insert_after_line(value, end, &block);
  set_value(r->doc, path, field, updated);
  free(updated);
  som_strlist_free(&block);
  free(value);
  return 1;
}

/* A located comment or question: its value (owned) and the parse of it. */
typedef struct {
  Value value;
  Parsed parsed;
  size_t index; /* comment or question index in `parsed` */
  size_t block;
} Found;

static void found_free(Found *f) {
  free(f->value.path);
  free(f->value.field);
  free(f->value.text);
  parsed_free(&f->parsed);
}

static void take_value(Values *vals, size_t i, Value *out) {
  *out = vals->items[i];
  vals->items[i].path = NULL;
  vals->items[i].field = NULL;
  vals->items[i].text = NULL;
}

static int find_comment(const SpecReviewAnnotations *r, const char *id,
                        Found *out, SpecReviewAnnotationError *err) {
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    Parsed p;
    parse(vals.items[i].text, &p);
    for (size_t ci = 0; ci < p.comments_len; ci++) {
      if (p.comments[ci].id != NULL && strcmp(p.comments[ci].id, id) == 0) {
        take_value(&vals, i, &out->value);
        out->parsed = p;
        out->index = ci;
        out->block = p.comments[ci].block;
        values_free(&vals);
        return 1;
      }
    }
    parsed_free(&p);
  }
  values_free(&vals);
  set_error(err, "no comment %s in the document", id);
  return 0;
}

static int find_question(const SpecReviewAnnotations *r, const char *id,
                         Found *out, SpecReviewAnnotationError *err) {
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    Parsed p;
    parse(vals.items[i].text, &p);
    for (size_t bi = 0; bi < p.blocks_len; bi++) {
      const Block *b = &p.blocks[bi];
      if (b->kind != SPEC_REVIEW_ANNOTATION_QUESTION) continue;
      for (size_t qi = 0; qi < b->q_len; qi++) {
        if (strcmp(p.questions[b->q_first + qi].id, id) == 0) {
          take_value(&vals, i, &out->value);
          out->parsed = p;
          out->index = b->q_first + qi;
          out->block = bi;
          values_free(&vals);
          return 1;
        }
      }
    }
    parsed_free(&p);
  }
  values_free(&vals);
  set_error(err, "no question %s in the document", id);
  return 0;
}

int spec_review_annotations_insert_question_after_comment(
    const SpecReviewAnnotations *r, const char *comment_id,
    const SpecQuestionDraft *question, SpecReviewAnnotationError *err) {
  Found f;
  if (!find_comment(r, comment_id, &f, err)) return 0;
  SomStrList block;
  spec_format_question_block(question, &block);
  char *updated = insert_after_line(
      f.value.text, (long long)f.parsed.blocks[f.block].end, &block);
  set_value(r->doc, f.value.path, f.value.field, updated);
  free(updated);
  som_strlist_free(&block);
  found_free(&f);
  return 1;
}

int spec_review_annotations_set_answer(const SpecReviewAnnotations *r,
                                       const char *question_id,
                                       const char *answer,
                                       SpecReviewAnnotationError *err) {
  Found f;
  if (!find_question(r, question_id, &f, err)) return 0;
  const Question *q = &f.parsed.questions[f.index];
  SomStrList lines;
  split_lines(f.value.text, &lines);
  SomStrList a;
  split_lines(answer, &a);
  SomStrList written;
  som_strlist_init(&written);
  if (answer[0] == '\0') {
    som_strlist_push_copy(&written, "> " ANSWER_LABEL);
  } else {
    som_strlist_push(&written, fmt("> " ANSWER_LABEL " %s", a.items[0]));
    push_quoted(&written, &a, 1);
  }
  /* The answer runs to the region's last non-empty line. */
  size_t last = q->region_end;
  while (last > q->header && is_blank(inner_of(lines.items[last]))) last--;
  if (q->answer_line >= 0) {
    size_t from = (size_t)q->answer_line;
    size_t to = last < from ? from : last;
    replace_range(&lines, from, to, &written);
  } else {
    SomStrList with;
    som_strlist_init(&with);
    som_strlist_push_copy(&with, ">");
    for (size_t k = 0; k < written.len; k++)
      som_strlist_push_copy(&with, written.items[k]);
    /* Insert after `last`: replace the empty range [last+1, last]. */
    SomStrList out;
    som_strlist_init(&out);
    for (size_t k = 0; k <= last; k++) som_strlist_push_copy(&out, lines.items[k]);
    for (size_t k = 0; k < with.len; k++) som_strlist_push_copy(&out, with.items[k]);
    for (size_t k = last + 1; k < lines.len; k++)
      som_strlist_push_copy(&out, lines.items[k]);
    som_strlist_free(&lines);
    lines = out;
    som_strlist_free(&with);
  }
  char *updated = som_strlist_join(&lines, "\n");
  set_value(r->doc, f.value.path, f.value.field, updated);
  free(updated);
  som_strlist_free(&written);
  som_strlist_free(&a);
  som_strlist_free(&lines);
  found_free(&f);
  return 1;
}

int spec_review_annotations_edit_comment(const SpecReviewAnnotations *r,
                                         const char *comment_id,
                                         const char *text,
                                         SpecReviewAnnotationError *err) {
  Found f;
  if (!find_comment(r, comment_id, &f, err)) return 0;
  const Comment *c = &f.parsed.comments[f.index];
  const Block *b = &f.parsed.blocks[f.block];
  SomStrList lines;
  split_lines(f.value.text, &lines);
  SomStrList t;
  split_lines(text, &t);
  SomStrList block;
  som_strlist_init(&block);
  char *head = fmt("%s%s", c->header_prefix, t.items[0]);
  som_strlist_push(&block, trim_right_dup(head));
  free(head);
  push_quoted(&block, &t, 1);
  replace_range(&lines, b->start, b->end, &block);
  char *updated = som_strlist_join(&lines, "\n");
  set_value(r->doc, f.value.path, f.value.field, updated);
  free(updated);
  som_strlist_free(&block);
  som_strlist_free(&t);
  som_strlist_free(&lines);
  found_free(&f);
  return 1;
}

int spec_review_annotations_resolve(const SpecReviewAnnotations *r,
                                    const char *id,
                                    SpecReviewAnnotationError *err) {
  const char *space = strrchr(id, ' ');
  const char *bare = space != NULL ? space + 1 : id;
  Found f;
  if (starts_with(bare, "C-")) {
    if (!find_comment(r, bare, &f, err)) return 0;
    const Block *b = &f.parsed.blocks[f.block];
    char *updated = remove_lines(f.value.text, b->start, b->end);
    set_value(r->doc, f.value.path, f.value.field, updated);
    free(updated);
    found_free(&f);
    return 1;
  }
  if (!find_question(r, bare, &f, err)) return 0;
  const Block *b = &f.parsed.blocks[f.block];
  const Question *q = &f.parsed.questions[f.index];
  char *updated;
  if (b->q_len == 1) {
    updated = remove_lines(f.value.text, b->start, b->end);
  } else {
    SomStrList lines;
    split_lines(f.value.text, &lines);
    SomStrList kept;
    som_strlist_init(&kept);
    for (size_t k = 0; k < lines.len; k++) {
      if (k >= q->header && k <= q->region_end) continue;
      som_strlist_push_copy(&kept, lines.items[k]);
    }
    /* A last question leaves the separator `>` lines of the one before it. */
    size_t end = b->end - (q->region_end - q->header + 1);
    while (end > b->start && is_blank(inner_of(kept.items[end]))) {
      som_strlist_remove_at(&kept, end);
      end--;
    }
    updated = som_strlist_join(&kept, "\n");
    som_strlist_free(&kept);
    som_strlist_free(&lines);
  }
  set_value(r->doc, f.value.path, f.value.field, updated);
  free(updated);
  found_free(&f);
  return 1;
}

int spec_review_annotations_apply_mark(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       long long index, int accept,
                                       SpecReviewAnnotationError *err) {
  char *value = som_strdup(get_value(r->doc, path, field));
  Parsed p;
  parse(value, &p);
  if (index < 0 || (unsigned long long)index >= p.marks_len) {
    set_error(err, "no inline mark %lld at %s%s%s", index, path,
          field == NULL ? "" : " / ", field == NULL ? "" : field);
    parsed_free(&p);
    free(value);
    return 0;
  }
  const Mark *m = &p.marks[index];
  char *updated = replace_mark(value, m, mark_replacement(m, accept));
  set_value(r->doc, path, field, updated);
  free(updated);
  parsed_free(&p);
  free(value);
  return 1;
}

SpecDocument *spec_review_annotations_stripped(const SpecReviewAnnotations *r) {
  SpecDocument *copy = malloc(sizeof(SpecDocument));
  spec_document_init(copy);
  DocumentJson j;
  spec_document_to_json(r->doc, &j);
  spec_document_load_json(copy, &j);
  document_json_free(&j);
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    char *clean = spec_strip_annotations_text(vals.items[i].text);
    if (strcmp(clean, vals.items[i].text) != 0) {
      set_value(copy, vals.items[i].path, vals.items[i].field, clean);
    }
    free(clean);
  }
  values_free(&vals);
  return copy;
}

static void push_error(SpecValidationErrors *errs, const char *path,
                       const char *code, char *message_owned) {
  SpecValidationError e;
  e.path = som_strdup(path);
  e.code = som_strdup(code);
  e.message = message_owned;
  PUSH(errs->items, errs->len, errs->cap, e);
}

void spec_review_annotations_validate(const SpecReviewAnnotations *r,
                                      SpecValidationErrors *out) {
  out->items = NULL;
  out->len = 0;
  out->cap = 0;
  SomStrList seen;
  som_strlist_init(&seen);
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    const Value *v = &vals.items[i];
    Parsed p;
    parse(v->text, &p);
    char *where = v->field == NULL ? som_strdup(v->path)
                                   : fmt("%s / %s", v->path, v->field);
    for (size_t m = 0; m < p.malformed.len; m++) {
      push_error(out, v->path, SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED,
                 fmt("%s, %s", where, p.malformed.items[m]));
    }
    if (v->field != NULL) {
      for (size_t bi = 0; bi < p.blocks_len; bi++) {
        push_error(
            out, v->path, SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED,
            fmt("%s, line %zu: a %s block sits in a form field value; it "
                "belongs in the form's preamble, above the first field "
                "(SOM \xC2\xA7"
                "11.9.4)",
                where, p.blocks[bi].start,
                spec_review_annotation_kind_name(p.blocks[bi].kind)));
      }
    }
    SomStrList ids;
    som_strlist_init(&ids);
    for (size_t ci = 0; ci < p.comments_len; ci++) {
      if (p.comments[ci].id != NULL)
        som_strlist_push_copy(&ids, p.comments[ci].id);
    }
    for (size_t bi = 0; bi < p.blocks_len; bi++) {
      const Block *b = &p.blocks[bi];
      if (b->kind != SPEC_REVIEW_ANNOTATION_QUESTION) continue;
      for (size_t qi = 0; qi < b->q_len; qi++)
        som_strlist_push_copy(&ids, p.questions[b->q_first + qi].id);
    }
    for (size_t k = 0; k < ids.len; k++) {
      if (som_strlist_contains(&seen, ids.items[k])) {
        push_error(out, v->path, SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID,
                   fmt("%s: %s is used more than once in the document", where,
                       ids.items[k]));
      } else {
        som_strlist_push_copy(&seen, ids.items[k]);
      }
    }
    som_strlist_free(&ids);
    free(where);
    parsed_free(&p);
  }
  values_free(&vals);
  som_strlist_free(&seen);
  /* Stable sort by path (insertion). */
  for (size_t i = 1; i < out->len; i++) {
    SpecValidationError moving = out->items[i];
    size_t j = i;
    while (j > 0 && strcmp(out->items[j - 1].path, moving.path) > 0) {
      out->items[j] = out->items[j - 1];
      j--;
    }
    out->items[j] = moving;
  }
}

/* ---- inline-mark review (SOM §11.9.3) ------------------------------------ */

const char *spec_mark_decision_name(SpecMarkDecision d) {
  switch (d) {
    case SPEC_MARK_DECISION_ACCEPT:
      return "accept";
    case SPEC_MARK_DECISION_REJECT:
      return "reject";
    case SPEC_MARK_DECISION_LEAVE:
      return "leave";
  }
  return "";
}

int spec_mark_decision_parse(const char *name, SpecMarkDecision *out) {
  if (name == NULL) return 0;
  if (strcmp(name, "accept") == 0) {
    *out = SPEC_MARK_DECISION_ACCEPT;
  } else if (strcmp(name, "reject") == 0) {
    *out = SPEC_MARK_DECISION_REJECT;
  } else if (strcmp(name, "leave") == 0) {
    *out = SPEC_MARK_DECISION_LEAVE;
  } else {
    return 0;
  }
  return 1;
}

void spec_mark_entry_free(SpecMarkEntry *e) {
  free(e->id);
  free(e->path);
  free(e->field);
  free(e->old_text);
  free(e->new_text);
  free(e->comment);
  free(e->markup);
  free(e->context);
  memset(e, 0, sizeof(*e));
}

char *spec_mark_entry_to_json(const SpecMarkEntry *e) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "id", e->id);
  put_str(&b, &first, "path", e->path);
  put_str(&b, &first, "field", e->field);
  put_int(&b, &first, "line", (long long)e->line);
  put_str(&b, &first, "markKind", spec_mark_kind_name(e->mark_kind));
  put_str(&b, &first, "oldText", e->old_text);
  put_str(&b, &first, "newText", e->new_text);
  put_str(&b, &first, "comment", e->comment);
  put_str(&b, &first, "markup", e->markup);
  put_str(&b, &first, "context", e->context);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_mark_entry_list_init(SpecMarkEntryList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_mark_entry_list_free(SpecMarkEntryList *l) {
  for (size_t i = 0; i < l->len; i++) spec_mark_entry_free(&l->items[i]);
  free(l->items);
  spec_mark_entry_list_init(l);
}

void spec_mark_report_init(SpecMarkReport *r) { memset(r, 0, sizeof(*r)); }

void spec_mark_report_free(SpecMarkReport *r) {
  for (size_t i = 0; i < r->applied_len; i++) {
    SpecMarkOutcome *o = &r->applied[i];
    free(o->id);
    free(o->path);
    free(o->field);
    free(o->markup);
    free(o->result);
  }
  free(r->applied);
  for (size_t i = 0; i < r->malformed_len; i++) {
    free(r->malformed[i].path);
    free(r->malformed[i].field);
    free(r->malformed[i].issue);
  }
  free(r->malformed);
  spec_mark_report_init(r);
}

char *spec_mark_report_to_json(const SpecMarkReport *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"applied\":[");
  for (size_t i = 0; i < r->applied_len; i++) {
    const SpecMarkOutcome *o = &r->applied[i];
    if (i > 0) som_buf_putc(&b, ',');
    int first = 1;
    som_buf_putc(&b, '{');
    put_str(&b, &first, "id", o->id);
    put_str(&b, &first, "path", o->path);
    put_str(&b, &first, "field", o->field);
    put_int(&b, &first, "line", (long long)o->line);
    put_str(&b, &first, "markKind", spec_mark_kind_name(o->mark_kind));
    put_str(&b, &first, "decision", spec_mark_decision_name(o->decision));
    put_str(&b, &first, "markup", o->markup);
    put_str(&b, &first, "result", o->result);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"malformed\":[");
  for (size_t i = 0; i < r->malformed_len; i++) {
    const SpecMarkIssue *m = &r->malformed[i];
    if (i > 0) som_buf_putc(&b, ',');
    int first = 1;
    som_buf_putc(&b, '{');
    put_str(&b, &first, "path", m->path);
    put_str(&b, &first, "field", m->field);
    put_int(&b, &first, "line", (long long)m->line);
    put_str(&b, &first, "issue", m->issue);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "]}");
  return som_buf_take(&b);
}

char *spec_review_annotations_revision(const SpecReviewAnnotations *r) {
  uint64_t h = 0xcbf29ce484222325ULL;
  const uint64_t prime = 0x100000001b3ULL;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    const char *parts[3] = {vals.items[i].path,
                            vals.items[i].field ? vals.items[i].field : "",
                            vals.items[i].text};
    for (int k = 0; k < 3; k++) {
      for (const unsigned char *s = (const unsigned char *)parts[k]; *s; s++) {
        h = (h ^ (uint64_t)*s) * prime;
      }
      h = (h ^ 0) * prime;
    }
  }
  values_free(&vals);
  return fmt("%016llx", (unsigned long long)h);
}

static int path_under(const char *path, const char *under) {
  if (under == NULL) return 1;
  size_t n = strlen(under);
  return strcmp(path, under) == 0 ||
         (strncmp(path, under, n) == 0 && path[n] == '/');
}

/* The paragraph (first, last line) holding `line`, or (line, line). */
static void paragraph_of(const Parsed *p, size_t line, size_t *from,
                         size_t *to) {
  *from = line;
  *to = line;
  size_t k = 0;
  const SomStrList *lines = &p->lines;
  while (k < lines->len) {
    if (is_blank(lines->items[k]) && !p->code[k]) {
      k++;
      continue;
    }
    size_t s = k;
    while (k + 1 < lines->len &&
           !(is_blank(lines->items[k + 1]) && !p->code[k + 1]))
      k++;
    if (s <= line && line <= k) {
      *from = s;
      *to = k;
      return;
    }
    k++;
  }
}

void spec_review_annotations_list_marks(const SpecReviewAnnotations *r,
                                        const char *path,
                                        SpecMarkEntryList *out) {
  spec_mark_entry_list_init(out);
  size_t n = 0;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    const Value *v = &vals.items[i];
    Parsed p;
    parse(v->text, &p);
    for (size_t mi = 0; mi < p.marks_len; mi++) {
      const Mark *m = &p.marks[mi];
      ++n;
      if (!path_under(v->path, path)) continue;
      size_t from, to;
      paragraph_of(&p, m->line, &from, &to);
      SpecMarkEntry e;
      e.id = fmt("M-%zu", n);
      e.path = som_strdup(v->path);
      e.field = dup_or_null(v->field);
      e.line = m->line;
      e.mark_kind = m->kind;
      e.old_text = som_strdup(mark_replacement(m, 0));
      e.new_text = som_strdup(mark_replacement(m, 1));
      e.comment = dup_or_null(m->comment);
      e.markup = som_strdup_n(v->text + m->start, m->end - m->start);
      e.context = join_from(LINE(&p, from), (const char *const *)p.lines.items,
                            (long long)from + 1, (long long)to);
      PUSH(out->items, out->len, out->cap, e);
    }
    parsed_free(&p);
  }
  values_free(&vals);
}

/* How `apply_marks` decides: from a list of decisions, or one for all. */
typedef struct {
  const SpecMarkDecisionItem *items; /* NULL: `all` applies to every mark */
  size_t len;
  SpecMarkDecision all;
} Decider;

/* The decision for mark `id`; 0 when none. A later item overrides. */
static int decide(const Decider *d, const char *id, SpecMarkDecision *out) {
  if (d->items == NULL) {
    *out = d->all;
    return 1;
  }
  int found = 0;
  for (size_t k = 0; k < d->len; k++) {
    if (strcmp(d->items[k].id, id) == 0) {
      *out = d->items[k].decision;
      found = 1;
    }
  }
  return found;
}

/* Applies `d` to every mark in the subtree `under` (NULL: the whole
 * document), one write per value. */
static void apply_marks(const SpecReviewAnnotations *r, const Decider *d,
                        const char *under, SpecMarkReport *out) {
  spec_mark_report_init(out);
  size_t n = 0;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    const Value *v = &vals.items[i];
    Parsed p;
    parse(v->text, &p);
    size_t first_id = n + 1;
    n += p.marks_len;
    if (!path_under(v->path, under)) {
      parsed_free(&p);
      continue;
    }
    for (size_t k = 0; k < p.mark_issues_len; k++) {
      SpecMarkIssue is;
      is.path = som_strdup(v->path);
      is.field = dup_or_null(v->field);
      is.line = p.mark_issues[k].line;
      is.issue = som_strdup(p.mark_issues[k].code);
      PUSH(out->malformed, out->malformed_len, out->malformed_cap, is);
    }
    char *text = som_strdup(v->text);
    size_t at = out->applied_len; /* this value's outcomes start here */
    for (size_t k = p.marks_len; k-- > 0;) {
      char *id = fmt("M-%zu", first_id + k);
      SpecMarkDecision dec;
      if (!decide(d, id, &dec) || dec == SPEC_MARK_DECISION_LEAVE) {
        free(id);
        continue;
      }
      const Mark *m = &p.marks[k];
      const char *repl = mark_replacement(m, dec == SPEC_MARK_DECISION_ACCEPT);
      SpecMarkOutcome o;
      o.id = id;
      o.path = som_strdup(v->path);
      o.field = dup_or_null(v->field);
      o.line = m->line;
      o.mark_kind = m->kind;
      o.decision = dec;
      o.markup = som_strdup_n(v->text + m->start, m->end - m->start);
      o.result = som_strdup(repl);
      PUSH(out->applied, out->applied_len, out->applied_cap, o);
      char *next = replace_mark(text, m, repl);
      free(text);
      text = next;
    }
    /* The outcomes were collected last to first: restore mark order. */
    for (size_t a = at, b = out->applied_len; a + 1 < b; a++, b--) {
      SpecMarkOutcome t = out->applied[a];
      out->applied[a] = out->applied[b - 1];
      out->applied[b - 1] = t;
    }
    if (strcmp(text, v->text) != 0) set_value(r->doc, v->path, v->field, text);
    free(text);
    parsed_free(&p);
  }
  values_free(&vals);
}

int spec_review_annotations_decide_marks(const SpecReviewAnnotations *r,
                                         const SpecMarkDecisionItem *decisions,
                                         size_t decisions_len,
                                         const char *revision,
                                         SpecMarkReport *out,
                                         SpecReviewAnnotationError *err) {
  spec_mark_report_init(out);
  char *current = spec_review_annotations_revision(r);
  if (revision == NULL || strcmp(revision, current) != 0) {
    set_error(err,
              "the document changed since revision %s (now %s); list the "
              "marks again",
              revision ? revision : "", current);
    free(current);
    return 0;
  }
  free(current);
  SpecMarkEntryList marks;
  spec_review_annotations_list_marks(r, NULL, &marks);
  for (size_t k = 0; k < decisions_len; k++) {
    int known = 0;
    for (size_t i = 0; i < marks.len && !known; i++) {
      known = strcmp(marks.items[i].id, decisions[k].id) == 0;
    }
    if (!known) {
      set_error(err, "no inline mark %s in the document", decisions[k].id);
      spec_mark_entry_list_free(&marks);
      return 0;
    }
  }
  spec_mark_entry_list_free(&marks);
  static const SpecMarkDecisionItem none[1] = {{"", SPEC_MARK_DECISION_LEAVE}};
  Decider d = {decisions_len ? decisions : none, decisions_len,
               SPEC_MARK_DECISION_LEAVE};
  apply_marks(r, &d, NULL, out);
  return 1;
}

void spec_review_annotations_accept_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out) {
  Decider d = {NULL, 0, SPEC_MARK_DECISION_ACCEPT};
  apply_marks(r, &d, path, out);
}

void spec_review_annotations_reject_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out) {
  Decider d = {NULL, 0, SPEC_MARK_DECISION_REJECT};
  apply_marks(r, &d, path, out);
}

void spec_review_annotations_remove_all_annotations(
    const SpecReviewAnnotations *r, SpecMarkReport *out) {
  spec_review_annotations_accept_all_marks(r, NULL, out);
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    char *v = som_strdup(vals.items[i].text);
    for (;;) {
      Parsed p;
      parse(v, &p);
      if (p.blocks_len == 0) {
        parsed_free(&p);
        break;
      }
      const Block *b = &p.blocks[p.blocks_len - 1];
      char *next = remove_lines(v, b->start, b->end);
      parsed_free(&p);
      free(v);
      v = next;
    }
    if (strcmp(v, vals.items[i].text) != 0) {
      set_value(r->doc, vals.items[i].path, vals.items[i].field, v);
    }
    free(v);
  }
  values_free(&vals);
}

/* ---- writing changes as inline marks (SOM §11.9.3, annot5) --------------- */

/* One token of a value: a run of whitespace, a word (a run of non-whitespace
 * with inline code spans kept whole) or a fenced code block (its lines). */
typedef struct {
  char *text; /* owned */
  size_t len;
  int space;
} Tok;

typedef struct {
  Tok *items;
  size_t len, cap;
} Toks;

static void toks_free(Toks *t) {
  for (size_t i = 0; i < t->len; i++) free(t->items[i].text);
  free(t->items);
  memset(t, 0, sizeof(*t));
}

static int is_mark_ws(char c) { return c == ' ' || c == '\t' || c == '\n'; }

static void tok_add(Toks *out, const char *s, size_t n, int space) {
  if (n == 0) return;
  if (space && out->len > 0 && out->items[out->len - 1].space) {
    Tok *last = &out->items[out->len - 1];
    last->text = realloc(last->text, last->len + n + 1);
    memcpy(last->text + last->len, s, n);
    last->len += n;
    last->text[last->len] = '\0';
    return;
  }
  Tok t = {som_strdup_n(s, n), n, space};
  PUSH(out->items, out->len, out->cap, t);
}

static void tok_words(Toks *out, const char *s, size_t len) {
  size_t i = 0;
  while (i < len) {
    if (is_mark_ws(s[i])) {
      size_t st = i;
      while (i < len && is_mark_ws(s[i])) i++;
      tok_add(out, s + st, i - st, 1);
      continue;
    }
    size_t st = i;
    while (i < len && !is_mark_ws(s[i])) {
      if (s[i] == '`') {
        size_t n = 0;
        while (i + n < len && s[i + n] == '`') n++;
        /* The matching run of exactly n backticks ends the span. */
        size_t j = i + n;
        long long close = -1;
        while (j < len) {
          if (s[j] == '`') {
            size_t m = 0;
            while (j + m < len && s[j + m] == '`') m++;
            if (m == n) {
              close = (long long)j;
              break;
            }
            j += m;
          } else {
            j++;
          }
        }
        i = close < 0 ? i + n : (size_t)close + n;
        continue;
      }
      i++;
    }
    tok_add(out, s + st, i - st, 0);
  }
}

static void tokens_of(const char *value, Toks *out) {
  memset(out, 0, sizeof(*out));
  SomStrList lines;
  split_lines(value, &lines);
  unsigned char *code = code_lines(&lines);
  size_t k = 0;
  while (k < lines.len) {
    if (k > 0) tok_add(out, "\n", 1, 1);
    size_t st = k;
    unsigned char is_code = code[k];
    while (k + 1 < lines.len && code[k + 1] == is_code) k++;
    SomBuf run;
    som_buf_init(&run);
    for (size_t q = st; q <= k; q++) {
      if (q > st) som_buf_putc(&run, '\n');
      som_buf_puts(&run, lines.items[q]);
    }
    if (is_code) {
      tok_add(out, run.data ? run.data : "", run.len, 0);
    } else {
      tok_words(out, run.data ? run.data : "", run.len);
    }
    som_buf_free(&run);
    k++;
  }
  free(code);
  som_strlist_free(&lines);
}

/* One diff op: 0 keep, 1 delete (old), 2 insert (new), with its token
 * (borrowed from the token lists). */
typedef struct {
  int kind;
  const Tok *tok;
} DiffOp;

typedef struct {
  DiffOp *items;
  size_t len, cap;
} DiffOps;

static int tok_eq(const Tok *a, const Tok *b) {
  return a->len == b->len && memcmp(a->text, b->text, a->len) == 0;
}

/* LCS over token text; ties prefer the deletion. */
static void diff_toks(const Toks *a, const Toks *b, DiffOps *out) {
  memset(out, 0, sizeof(*out));
  size_t n = a->len, m = b->len, w = m + 1;
  size_t *l = calloc((n + 1) * w, sizeof(size_t));
  for (size_t i = n; i-- > 0;) {
    for (size_t j = m; j-- > 0;) {
      size_t down = l[(i + 1) * w + j], right = l[i * w + j + 1];
      l[i * w + j] = tok_eq(&a->items[i], &b->items[j])
                         ? l[(i + 1) * w + j + 1] + 1
                         : (down >= right ? down : right);
    }
  }
  size_t i = 0, j = 0;
  while (i < n || j < m) {
    DiffOp op;
    if (i < n && j < m && tok_eq(&a->items[i], &b->items[j])) {
      op.kind = 0;
      op.tok = &a->items[i];
      i++;
      j++;
    } else if (j >= m || (i < n && l[(i + 1) * w + j] >= l[i * w + j + 1])) {
      op.kind = 1;
      op.tok = &a->items[i];
      i++;
    } else {
      op.kind = 2;
      op.tok = &b->items[j];
      j++;
    }
    PUSH(out->items, out->len, out->cap, op);
  }
  free(l);
}

/* `s[0, len)` with its leading and trailing whitespace (spaces, tabs,
 * newlines) removed. Owned. */
static char *trim_ws_n(const char *s, size_t len) {
  size_t a = 0, b = len;
  while (a < b && is_mark_ws(s[a])) a++;
  while (b > a && is_mark_ws(s[b - 1])) b--;
  return som_strdup_n(s + a, b - a);
}

/* The markup for one region whose old text is `o` and new text is `n` (both
 * trimmed, not both empty). Owned. */
static char *markup_of(const char *o, const char *n) {
  if (o[0] == '\0') return fmt("{++ %s ++}", n);
  if (n[0] == '\0') return fmt("{-- %s --}", o);
  return fmt("{~~ %s ~> %s ~~}", o, n);
}

static char *cat3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

/* Whether accepting `marked` gives `want_new` and rejecting `marked_old`
 * gives `want_old`. */
static int round_trips(const char *marked_new, const char *want_new,
                       const char *marked_old, const char *want_old) {
  char *acc = spec_apply_inline_marks_text(marked_new, 1);
  int ok = strcmp(acc, want_new) == 0;
  free(acc);
  if (!ok) return 0;
  char *rej = spec_apply_inline_marks_text(marked_old, 0);
  ok = strcmp(rej, want_old) == 0;
  free(rej);
  return ok;
}

/* The marked emission for the region [r0, r1) of `ops`, with the old and the
 * new text around it, or NULL when no mark round-trips there. Owned. */
static char *emit_region(const DiffOps *ops, size_t r0, size_t r1,
                         const char *old_before, const char *new_before,
                         const char *old_after, const char *new_after) {
  SomBuf ob, nb;
  som_buf_init(&ob);
  som_buf_init(&nb);
  som_buf_puts(&ob, "");
  som_buf_puts(&nb, "");
  for (size_t k = r0; k < r1; k++) {
    if (ops->items[k].kind != 2)
      som_buf_putn(&ob, ops->items[k].tok->text, ops->items[k].tok->len);
    if (ops->items[k].kind != 1)
      som_buf_putn(&nb, ops->items[k].tok->text, ops->items[k].tok->len);
  }
  size_t ol = ob.len, nl = nb.len;
  char *os = som_buf_take(&ob), *ns = som_buf_take(&nb);
  /* Whitespace the two sides share at the edges stays outside the mark. */
  size_t lead = 0;
  while (lead < ol && lead < nl && os[lead] == ns[lead] &&
         is_mark_ws(os[lead])) {
    lead++;
  }
  size_t trail = 0;
  while (trail < ol - lead && trail < nl - lead &&
         os[ol - 1 - trail] == ns[nl - 1 - trail] &&
         is_mark_ws(os[ol - 1 - trail])) {
    trail++;
  }
  const char *oi = os + lead, *ni = ns + lead;
  size_t oil = ol - lead - trail, nil = nl - lead - trail;
  char *ot = trim_ws_n(oi, oil), *nt = trim_ws_n(ni, nil);
  char *result = NULL;
  if (ot[0] != '\0' || nt[0] != '\0') {
    char *pre = som_strdup_n(os, lead);
    char *post = som_strdup_n(os + ol - trail, trail);
    char *markup = markup_of(ot, nt);
    /* leadWs / trailWs by Dart's trimLeft / trimRight. */
    size_t nb_, ne_, ob_, oe_;
    trim_bounds(ni, nil, &nb_, &ne_);
    trim_bounds(oi, oil, &ob_, &oe_);
    size_t ni_lead = nb_ == ne_ ? nil : nb_;
    size_t ni_trail = nb_ == ne_ ? 0 : ne_;
    size_t oi_lead = ob_ == oe_ ? oil : ob_;
    size_t oi_trail = ob_ == oe_ ? 0 : oe_;
    char *lw_n = som_strdup_n(ni, ni_lead);
    char *tw_n = som_strdup_n(ni + ni_trail, nil - ni_trail);
    char *lw_o = som_strdup_n(oi, oi_lead);
    char *tw_o = som_strdup_n(oi + oi_trail, oil - oi_trail);
    const char *cands[5][2] = {
        {lw_n, tw_n}, {lw_o, tw_o}, {"", ""}, {lw_n, ""}, {"", tw_n}};
    char *want_new = cat3(new_before, ns, new_after);
    char *want_old = cat3(old_before, os, old_after);
    for (int c = 0; c < 5 && result == NULL; c++) {
      SomBuf e;
      som_buf_init(&e);
      som_buf_puts(&e, pre);
      som_buf_puts(&e, cands[c][0]);
      som_buf_puts(&e, markup);
      som_buf_puts(&e, cands[c][1]);
      som_buf_puts(&e, post);
      char *emission = som_buf_take(&e);
      char *mn = cat3(new_before, emission, new_after);
      char *mo = cat3(old_before, emission, old_after);
      if (round_trips(mn, want_new, mo, want_old)) {
        result = emission;
      } else {
        free(emission);
      }
      free(mn);
      free(mo);
    }
    free(want_new);
    free(want_old);
    free(lw_n);
    free(tw_n);
    free(lw_o);
    free(tw_o);
    free(markup);
    free(pre);
    free(post);
  }
  free(ot);
  free(nt);
  free(os);
  free(ns);
  return result;
}

/* The text of ops [from, to) without the ops of kind `skip`. Owned. */
static char *ops_side(const DiffOps *ops, size_t from, size_t to, int skip) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "");
  for (size_t q = from; q < to; q++) {
    if (ops->items[q].kind != skip)
      som_buf_putn(&b, ops->items[q].tok->text, ops->items[q].tok->len);
  }
  return som_buf_take(&b);
}

typedef struct {
  size_t s, e;
} Run;

/* Marks the token-level differences of `o` → `n`, where the text before them
 * is `ob` (old) / `nb` (new) and after them `oa` / `na`. NULL when the marks
 * do not round-trip. Owned. */
static char *mark_tokens(const char *o, const char *n, const char *ob,
                         const char *nb, const char *oa, const char *na) {
  Toks to, tn;
  tokens_of(o, &to);
  tokens_of(n, &tn);
  DiffOps ops;
  diff_toks(&to, &tn, &ops);
  Run *runs = NULL;
  size_t runs_len = 0, runs_cap = 0;
  size_t k = 0;
  while (k < ops.len) {
    if (ops.items[k].kind == 0) {
      k++;
      continue;
    }
    size_t s = k;
    while (k < ops.len && ops.items[k].kind != 0) k++;
    /* Changes separated by at most two unchanged words are one mark. */
    if (runs_len > 0) {
      size_t words = 0;
      for (size_t q = runs[runs_len - 1].e; q < s; q++) {
        if (!ops.items[q].tok->space) words++;
      }
      if (words <= 2) {
        runs[runs_len - 1].e = k;
        continue;
      }
    }
    Run r = {s, k};
    PUSH(runs, runs_len, runs_cap, r);
  }

  /* Left to right; a region that does not round-trip grows by one token on
   * each side and is tried again. */
  SomBuf out;
  som_buf_init(&out);
  som_buf_puts(&out, "");
  size_t pos = 0, end = ops.len;
  int failed = 0;
  for (size_t ri = 0; ri < runs_len; ri++) {
    size_t r0 = runs[ri].s, r1 = runs[ri].e;
    if (r0 < pos) r0 = pos;
    char *emission = NULL;
    for (;;) {
      char *sb_o = ops_side(&ops, 0, r0, 2), *sb_n = ops_side(&ops, 0, r0, 1);
      char *sa_o = ops_side(&ops, r1, end, 2);
      char *sa_n = ops_side(&ops, r1, end, 1);
      char *c_ob = cat3(ob, sb_o, ""), *c_nb = cat3(nb, sb_n, "");
      char *c_oa = cat3(sa_o, oa, ""), *c_na = cat3(sa_n, na, "");
      emission = emit_region(&ops, r0, r1, c_ob, c_nb, c_oa, c_na);
      free(sb_o);
      free(sb_n);
      free(sa_o);
      free(sa_n);
      free(c_ob);
      free(c_nb);
      free(c_oa);
      free(c_na);
      if (emission != NULL || (r0 <= pos && r1 >= end)) break;
      if (r0 > pos) r0--;
      if (r1 < end) r1++;
    }
    if (emission == NULL) {
      failed = 1;
      break;
    }
    char *before = ops_side(&ops, pos, r0, 1);
    som_buf_puts(&out, before);
    som_buf_puts(&out, emission);
    free(before);
    free(emission);
    pos = r1;
    while (ri + 1 < runs_len && runs[ri + 1].e <= pos) ri++;
  }
  char *text = NULL;
  if (!failed) {
    char *rest = ops_side(&ops, pos, end, 1);
    som_buf_puts(&out, rest);
    free(rest);
    text = som_buf_take(&out);
    char *mn = cat3(nb, text, na), *wn = cat3(nb, n, na);
    char *mo = cat3(ob, text, oa), *wo = cat3(ob, o, oa);
    if (!round_trips(mn, wn, mo, wo)) {
      free(text);
      text = NULL;
    }
    free(mn);
    free(wn);
    free(mo);
    free(wo);
  }
  som_buf_free(&out);
  free(runs);
  free(ops.items);
  toks_free(&to);
  toks_free(&tn);
  return text;
}

/* A whole line marked as inserted (`++`) or deleted (`--`): its indentation
 * stays outside the mark; a blank line stays blank. Owned. */
static char *line_mark(const char *line, const char *d) {
  size_t len = strlen(line);
  size_t b, e;
  trim_bounds(line, len, &b, &e);
  if (b == e) return som_strdup(line);
  return fmt("%.*s{%s %.*s %s}", (int)b, line, d, (int)(e - b), line + b, d);
}

/* Joins up to three line ranges with `\n` between every two lines. Owned. */
static char *join_ranges(const char *const *a, size_t an,
                         const char *const *b, size_t bn,
                         const char *const *c, size_t cn) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, "");
  int first = 1;
  const char *const *parts[3] = {a, b, c};
  size_t lens[3] = {an, bn, cn};
  for (int p = 0; p < 3; p++) {
    for (size_t i = 0; i < lens[p]; i++) {
      if (!first) som_buf_putc(&buf, '\n');
      som_buf_puts(&buf, parts[p][i]);
      first = 0;
    }
  }
  return som_buf_take(&buf);
}

static void lines_to_toks(const SomStrList *l, Toks *out) {
  memset(out, 0, sizeof(*out));
  for (size_t i = 0; i < l->len; i++) {
    Tok t = {som_strdup(l->items[i]), strlen(l->items[i]), 0};
    PUSH(out->items, out->len, out->cap, t);
  }
}

/* `src` without its blank lines, as borrowed pointers. */
static void without_blank(const SomStrList *src, SomStrList *dst) {
  som_strlist_init(dst);
  for (size_t i = 0; i < src->len; i++) {
    if (!is_blank(src->items[i])) som_strlist_push_copy(dst, src->items[i]);
  }
}

static void concat_lists(const SomStrList *a, const SomStrList *b,
                         SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < a->len; i++) som_strlist_push_copy(out, a->items[i]);
  for (size_t i = 0; i < b->len; i++) som_strlist_push_copy(out, b->items[i]);
}

void spec_marked_change_free(SpecMarkedChange *c) {
  free(c->text);
  c->text = NULL;
}

char *spec_marked_change_to_json(const SpecMarkedChange *c) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "text", c->text);
  put_bool(&b, &first, "exact", c->exact);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

SpecMarkedChange spec_mark_change_text(const char *old_value,
                                       const char *new_value) {
  SpecMarkedChange res;
  if (strcmp(old_value, new_value) == 0) {
    res.text = som_strdup(new_value);
    res.exact = 1;
    return res;
  }
  SomStrList ol, nl;
  split_lines(old_value, &ol);
  split_lines(new_value, &nl);
  unsigned char *oc = code_lines(&ol), *nc = code_lines(&nl);
  Toks olt, nlt;
  lines_to_toks(&ol, &olt);
  lines_to_toks(&nl, &nlt);
  DiffOps lops;
  diff_toks(&olt, &nlt, &lops);
  const char *const *O = (const char *const *)ol.items;
  const char *const *N = (const char *const *)nl.items;
  SomStrList out;
  som_strlist_init(&out);
  int exact = 1;
  size_t oi = 0, ni = 0, k = 0;
  while (k < lops.len) {
    if (lops.items[k].kind == 0) {
      som_strlist_push_copy(&out, nl.items[ni]);
      oi++;
      ni++;
      k++;
      continue;
    }
    size_t d0 = oi, n0 = ni;
    while (k < lops.len && lops.items[k].kind != 0) {
      if (lops.items[k].kind == 1) {
        oi++;
      } else {
        ni++;
      }
      k++;
    }
    size_t deln = oi - d0, insn = ni - n0;
    int in_code = 0;
    for (size_t q = d0; q < oi; q++) in_code |= oc[q];
    for (size_t q = n0; q < ni; q++) in_code |= nc[q];
    SomStrList emitted;
    int have = 0;
    if (!in_code) {
      SomStrList cands[5];
      size_t cn = 0;
      if (deln > 0 && insn > 0) {
        char *jd = join_ranges(O + d0, deln, NULL, 0, NULL, 0);
        char *jn = join_ranges(N + n0, insn, NULL, 0, NULL, 0);
        char *job = join_ranges(O, d0, NULL, 0, NULL, 0);
        char *jnb = join_ranges(N, n0, NULL, 0, NULL, 0);
        char *joa = join_ranges(O + oi, ol.len - oi, NULL, 0, NULL, 0);
        char *jna = join_ranges(N + ni, nl.len - ni, NULL, 0, NULL, 0);
        char *cob = d0 == 0 ? som_strdup("") : cat3(job, "\n", "");
        char *cnb = n0 == 0 ? som_strdup("") : cat3(jnb, "\n", "");
        char *coa = oi == ol.len ? som_strdup("") : cat3("\n", joa, "");
        char *cna = ni == nl.len ? som_strdup("") : cat3("\n", jna, "");
        char *t = mark_tokens(jd, jn, cob, cnb, coa, cna);
        if (t != NULL) {
          split_lines(t, &cands[cn++]);
          free(t);
        }
        free(jd);
        free(jn);
        free(job);
        free(jnb);
        free(joa);
        free(jna);
        free(cob);
        free(cnb);
        free(coa);
        free(cna);
      }
      SomStrList dm, im, dmb, imb;
      som_strlist_init(&dm);
      som_strlist_init(&im);
      for (size_t q = d0; q < oi; q++)
        som_strlist_push(&dm, line_mark(ol.items[q], "--"));
      for (size_t q = n0; q < ni; q++)
        som_strlist_push(&im, line_mark(nl.items[q], "++"));
      without_blank(&dm, &dmb);
      without_blank(&im, &imb);
      concat_lists(&dm, &im, &cands[cn++]);
      concat_lists(&dmb, &im, &cands[cn++]);
      concat_lists(&dm, &imb, &cands[cn++]);
      concat_lists(&dmb, &imb, &cands[cn++]);
      som_strlist_free(&dm);
      som_strlist_free(&im);
      som_strlist_free(&dmb);
      som_strlist_free(&imb);
      for (size_t c = 0; c < cn; c++) {
        const char *const *E = (const char *const *)cands[c].items;
        if (!have) {
          char *mn = join_ranges(N, n0, E, cands[c].len, N + ni, nl.len - ni);
          char *mo = join_ranges(O, d0, E, cands[c].len, O + oi, ol.len - oi);
          if (round_trips(mn, new_value, mo, old_value)) {
            emitted = cands[c];
            have = 1;
            free(mn);
            free(mo);
            continue;
          }
          free(mn);
          free(mo);
        }
        som_strlist_free(&cands[c]);
      }
    }
    if (!have) {
      exact = 0;
      for (size_t q = n0; q < ni; q++) som_strlist_push_copy(&out, nl.items[q]);
    } else {
      for (size_t q = 0; q < emitted.len; q++)
        som_strlist_push_copy(&out, emitted.items[q]);
      som_strlist_free(&emitted);
    }
  }
  char *text = som_strlist_join(&out, "\n");
  som_strlist_free(&out);
  free(lops.items);
  toks_free(&olt);
  toks_free(&nlt);
  free(oc);
  free(nc);
  som_strlist_free(&ol);
  som_strlist_free(&nl);
  if (exact && !round_trips(text, new_value, text, old_value)) {
    free(text);
    res.text = som_strdup(new_value);
    res.exact = 0;
    return res;
  }
  res.text = text;
  res.exact = exact;
  return res;
}

SpecMarkedChange spec_review_annotations_set_marked(
    const SpecReviewAnnotations *r, const char *path, const char *field,
    const char *text) {
  char *base = spec_apply_inline_marks_text(get_value(r->doc, path, field), 0);
  SpecMarkedChange result = spec_mark_change_text(base, text);
  free(base);
  set_value(r->doc, path, field, result.text);
  return result;
}

SpecMarkedChange spec_review_annotations_mark_against(
    const SpecReviewAnnotations *r, const char *path, const char *field,
    const char *earlier) {
  char *current = som_strdup(get_value(r->doc, path, field));
  SpecMarkedChange result = spec_mark_change_text(earlier, current);
  free(current);
  set_value(r->doc, path, field, result.text);
  return result;
}
