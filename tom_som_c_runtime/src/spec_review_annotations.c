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
#include <time.h>

#define ARROW "\xE2\xAC\x86"         /* U+2B06 */
#define VS16 "\xEF\xB8\x8F"          /* U+FE0F */
#define QOPEN "**\xE2\x9D\x93"       /* `**❓` */
#define COMBINED_OPENER QOPEN " Open questions on these fields**"
#define ANSWER_LABEL "**Answer:**"
#define EM_SEP " \xE2\x80\x94 "      /* ` — ` */
#define STAR "\xE2\x98\x85"          /* U+2605 */
#define SCALES "\xE2\x9A\x96"        /* U+2696, a conflict block */
#define DECISION_LABEL "**Decision:**"
#define UNRESOLVED_PREFIX "open:"

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
    case SPEC_REVIEW_ANNOTATION_CONFLICT:
      return "conflict";
  }
  return "";
}

int spec_review_is_member_id(const char *s) {
  if (s == NULL || s[0] == '\0') return 0;
  for (; *s; s++) {
    if (!((*s >= 'a' && *s <= 'z') || (*s >= '0' && *s <= '9') || *s == '_')) {
      return 0;
    }
  }
  return 1;
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

/* ---- change times (SOM §11.9.10) ----------------------------------------- */

static int is_digit_char(char c) { return c >= '0' && c <= '9'; }

/* Whether `s[0, n)` are digits. */
static int digits_n(const char *s, size_t n) {
  for (size_t i = 0; i < n; i++) {
    if (!is_digit_char(s[i])) return 0;
  }
  return 1;
}

/* The length of the `YYYY-MM-DDTHH:MM` at the start of `s`: 16, or 0. */
static size_t time_minutes_len(const char *s) {
  if (strlen(s) < 16) return 0;
  if (!digits_n(s, 4) || s[4] != '-' || !digits_n(s + 5, 2) || s[7] != '-' ||
      !digits_n(s + 8, 2) || s[10] != 'T' || !digits_n(s + 11, 2) ||
      s[13] != ':' || !digits_n(s + 14, 2)) {
    return 0;
  }
  return 16;
}

/* Whether `s` is exactly an offset: `Z`, `+HH:MM` or `-HH:MM`. */
static int is_time_offset(const char *s) {
  if (strcmp(s, "Z") == 0) return 1;
  return (s[0] == '+' || s[0] == '-') && strlen(s) == 6 &&
         digits_n(s + 1, 2) && s[3] == ':' && digits_n(s + 4, 2);
}

int spec_review_is_time(const char *s) {
  if (s == NULL) return 0;
  size_t n = time_minutes_len(s);
  return n > 0 && is_time_offset(s + n);
}

char *spec_review_normalize_time(const char *at,
                                 SpecReviewAnnotationError *err) {
  char *t = trim_dup(at != NULL ? at : "");
  size_t n = time_minutes_len(t);
  const char *zone = NULL;
  if (n > 0) {
    const char *q = t + n;
    if (q[0] == ':' && digits_n(q + 1, 2)) {
      q += 3;
      if (q[0] == '.' && is_digit_char(q[1])) {
        q++;
        while (is_digit_char(*q)) q++;
      }
    }
    if (is_time_offset(q)) zone = q;
  }
  char *out = NULL;
  if (zone != NULL) {
    out = fmt("%.*s%s", (int)n, t, zone);
  } else {
    set_error(err,
              "\"%s\" is not an ISO 8601 time with an offset or Z "
              "(e.g. 2026-11-07T14:05+01:00)",
              at != NULL ? at : "");
  }
  free(t);
  return out;
}

char *spec_review_system_time(void) {
  time_t now = time(NULL);
  struct tm local = *localtime(&now);
  struct tm utc = *gmtime(&now);
  /* The offset, from the two broken-down times of the same instant: the day
   * apart (at most one), then hours, minutes and seconds. */
  long days = (long)local.tm_yday - (long)utc.tm_yday;
  if (local.tm_year != utc.tm_year) days = local.tm_year < utc.tm_year ? -1 : 1;
  long seconds = ((days * 24 + (local.tm_hour - utc.tm_hour)) * 60 +
                  (local.tm_min - utc.tm_min)) *
                     60 +
                 (local.tm_sec - utc.tm_sec);
  long minutes = seconds / 60; /* truncated toward zero, as Dart's inMinutes */
  char sign = minutes < 0 ? '-' : '+';
  if (minutes < 0) minutes = -minutes;
  char stamp[64];
  if (strftime(stamp, sizeof(stamp), "%Y-%m-%dT%H:%M", &local) == 0) {
    stamp[0] = '\0';
  }
  return fmt("%s%c%02ld:%02ld", stamp, sign, minutes / 60, minutes % 60);
}

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
  size_t conflict; /* index into conflicts, for a conflict block */
} Block;

/* One `**Answer (<ids>):**` entry of a question (SOM §11.9.8). */
typedef struct {
  size_t line; /* value line of the `**Answer (…):**` line */
  size_t end;  /* last value line of the entry with text (inclusive) */
  SomStrList members;
  char *answer;
  char *changed_at; /* the change time of SOM §11.9.10, or NULL */
} IndividualAnswer;

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
  IndividualAnswer *answers;
  size_t answers_len, answers_cap;
} Question;

/* One parsed conflict block (SOM §11.9.8). */
typedef struct {
  size_t block;
  char *id; /* NULL when the header is malformed: the block is then unlisted */
  char *topic;
  char *text;
  char *base; /* the `(base)` text; NULL when the block has none */
  SpecConflictAlternative *alternatives;
  size_t alternatives_len, alternatives_cap;
  char *decision;
} Conflict;

typedef struct {
  size_t block;
  char *id;
  char *author;
  char *text;
  char *context;
  char *header_prefix; /* the first line up to where the text starts */
  size_t marker_end;   /* where an id is inserted into the first line */
  /* The first line up to where the author's parentheses (or the text)
   * start. */
  char *before_author;
  char *changed_at; /* the change time of SOM §11.9.10, or NULL */
} Comment;

/* One parsed mark; start/end are byte offsets into the value (never
 * exported). `end` lies after the attribution token when the mark has one,
 * `body_end` always right after the mark itself, so the token can be
 * rewritten in place. */
typedef struct {
  size_t start;
  size_t end;
  size_t body_end;
  size_t line;
  SpecMarkKind kind;
  char *text;
  char *new_text;
  char *comment;
  SomStrList authors;
  SpecMarkVote *votes;
  size_t votes_len;
  /* The time in the mark's attribution token (SOM §11.9.10), or NULL. */
  char *changed_at;
  /* A comment mark's quote of a change (SOM §11.9.3): `has_quote` set, the
   * quoted kind and texts, the outcome (a static "accepted" / "rejected", or
   * NULL while open), `q_delim_end` right after the closing delimiter and
   * `q_end` right after the `]` (value offsets), and the comment after it. */
  int has_quote;
  SpecMarkKind q_kind;
  char *q_old;
  char *q_new;
  const char *q_outcome;
  size_t q_delim_end;
  size_t q_end;
  char *q_comment;
  /* The index (among the value's marks) of the change this change comment
   * is attached to, and of this change's attached comment; -1 for none. */
  long long change_index;
  long long comment_index;
  /* Whether whitespace was written inside the delimiters at the leading /
   * trailing edge of `text` and of `new_text` (SOM §11.9.3, edge spaces). */
  int text_lead, text_trail, new_lead, new_trail;
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
  Conflict *conflicts;
  size_t conflicts_len, conflicts_cap;
  Mark *marks;
  size_t marks_len, marks_cap;
  SomStrList malformed;
  /* Malformed inline marks: (value line, issue code) — `unclosed`, `nested`,
   * `noArrow`. The codes are static strings. */
  MarkIssue *mark_issues;
  size_t mark_issues_len, mark_issues_cap;
} Parsed;

#define LINE(p, k) ((p)->lines.items[(k)])

static void votes_free(SpecMarkVote *v, size_t len) {
  for (size_t i = 0; i < len; i++) free(v[i].member);
  free(v);
}

static SpecMarkVote *votes_copy(const SpecMarkVote *v, size_t len) {
  if (len == 0) return NULL;
  SpecMarkVote *out = malloc(len * sizeof(SpecMarkVote));
  for (size_t i = 0; i < len; i++) {
    out[i].member = som_strdup(v[i].member);
    out[i].accept = v[i].accept;
  }
  return out;
}

static void alternatives_free(SpecConflictAlternative *a, size_t len) {
  for (size_t i = 0; i < len; i++) {
    free(a[i].letter);
    som_strlist_free(&a[i].members);
    free(a[i].text);
  }
  free(a);
}

static SpecConflictAlternative *alternatives_copy(
    const SpecConflictAlternative *a, size_t len) {
  if (len == 0) return NULL;
  SpecConflictAlternative *out = malloc(len * sizeof(*out));
  for (size_t i = 0; i < len; i++) {
    out[i].letter = som_strdup(a[i].letter);
    som_strlist_copy(&out[i].members, &a[i].members);
    out[i].text = som_strdup(a[i].text);
  }
  return out;
}

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
    free(c->before_author);
    free(c->changed_at);
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
    for (size_t a = 0; a < q->answers_len; a++) {
      som_strlist_free(&q->answers[a].members);
      free(q->answers[a].answer);
      free(q->answers[a].changed_at);
    }
    free(q->answers);
  }
  free(p->questions);
  for (size_t i = 0; i < p->conflicts_len; i++) {
    Conflict *c = &p->conflicts[i];
    free(c->id);
    free(c->topic);
    free(c->text);
    free(c->base);
    alternatives_free(c->alternatives, c->alternatives_len);
    free(c->decision);
  }
  free(p->conflicts);
  for (size_t i = 0; i < p->marks_len; i++) {
    free(p->marks[i].text);
    free(p->marks[i].new_text);
    free(p->marks[i].comment);
    free(p->marks[i].q_old);
    free(p->marks[i].q_new);
    free(p->marks[i].q_comment);
    som_strlist_free(&p->marks[i].authors);
    votes_free(p->marks[i].votes, p->marks[i].votes_len);
    free(p->marks[i].changed_at);
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
  const char *t = lstrip(line);
  if (*t != '\0') t++;
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

/* The length of the label of an individual answer line,
 * `**Answer (alice, bob):**`, with the text between the brackets in `*inside`
 * (owned, when non-NULL); 0 for any other line. */
static size_t individual_answer_label(const char *line, char **inside) {
  const char *open = "**Answer (";
  if (!starts_with(line, open)) return 0;
  const char *close = strchr(line + strlen(open), ')');
  if (close == NULL || strncmp(close, "):**", 4) != 0) return 0;
  if (inside != NULL) {
    *inside = som_strdup_n(line + strlen(open),
                           (size_t)(close - line) - strlen(open));
  }
  return (size_t)(close - line) + 4;
}

/* `s` split on `sep` into `out` (initialised here), each piece trimmed; empty
 * pieces are kept unless `skip_empty`. */
static void split_trimmed(const char *s, char sep, int skip_empty,
                          SomStrList *out) {
  som_strlist_init(out);
  const char *from = s;
  for (;;) {
    const char *at = strchr(from, sep);
    size_t n = at == NULL ? strlen(from) : (size_t)(at - from);
    char *piece = trim_n(from, n);
    if (skip_empty && piece[0] == '\0') {
      free(piece);
    } else {
      som_strlist_push(out, piece);
    }
    if (at == NULL) return;
    from = at + 1;
  }
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
  char *changed_at = NULL;
  char *before_author = som_strdup_n(raw0, (size_t)(rest - raw0));
  if (rest[0] == '(') {
    const char *close = strchr(rest, ')');
    if (close != NULL && close > rest) {
      /* `(<author>, <time>)`: a last comma-separated part that is a change
       * time is the time (SOM §11.9.10), the rest the author. */
      const char *inside = rest + 1;
      size_t inside_len = (size_t)(close - rest - 1);
      const char *comma = NULL;
      for (const char *q = inside; q < close; q++) {
        if (*q == ',') comma = q;
      }
      const char *last = comma != NULL ? comma + 1 : inside;
      char *tail = trim_n(last, (size_t)(close - last));
      if (spec_review_is_time(tail)) {
        changed_at = tail;
        char *a = comma != NULL ? trim_n(inside, (size_t)(comma - inside))
                                : som_strdup("");
        if (a[0] == '\0') {
          free(a);
        } else {
          author = a;
        }
      } else {
        free(tail);
        author = som_strdup_n(inside, inside_len);
      }
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
    if (starts_with(t, QOPEN) || starts_with(t, ANSWER_LABEL) ||
        individual_answer_label(t, NULL) > 0) {
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
  c.before_author = before_author;
  c.changed_at = changed_at;
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

static int is_unresolved_answer(const char *answer) {
  return starts_with(answer, UNRESOLVED_PREFIX);
}

/* `s` without its leading whitespace (Dart's `trimLeft`); borrowed. */
static const char *trim_left(const char *s) {
  size_t b, e;
  trim_bounds(s, strlen(s), &b, &e);
  return b == e ? s + strlen(s) : s + b;
}

/* A conflict decision's letter: `a`…, `base` (owned), or NULL (rewritten
 * text or none). */
static char *decision_letter_of(const char *decision) {
  const char *t = trim_left(decision);
  if (starts_with(t, "(base)") || starts_with(t, "**(base)**")) {
    return som_strdup("base");
  }
  return is_unresolved_answer(t) ? NULL : leading_letter(t);
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
    /* Every `**Answer` line of the region: the individual ones and the
     * team's. */
    size_t *answer_lines = malloc((region_end - k + 1) * sizeof(size_t));
    size_t answer_count = 0;
    for (size_t m = k + 1; m <= region_end; m++) {
      if (starts_with(in[m], ANSWER_LABEL) ||
          individual_answer_label(in[m], NULL) > 0) {
        answer_lines[answer_count++] = m;
      }
    }
    /* The question's text ends before its first answer line of either kind. */
    long long text_end = answer_count == 0 ? (long long)region_end
                                           : (long long)answer_lines[0] - 1;
    char *joined = join_from(hs[q].rest, in, (long long)k + 1, text_end);
    Question qq;
    memset(&qq, 0, sizeof(qq));
    parse_options(in, (long long)k + 1, text_end, &qq);
    qq.text = trim_dup(joined);
    free(joined);
    long long answer = -1;
    SomStrList answered;
    som_strlist_init(&answered);
    for (size_t a = 0; a < answer_count; a++) {
      size_t m = answer_lines[a];
      /* An answer runs to the next `**Answer` line or the end of the region. */
      size_t a_end =
          a + 1 < answer_count ? answer_lines[a + 1] - 1 : region_end;
      if (starts_with(in[m], ANSWER_LABEL)) {
        if (answer < 0) {
          answer = (long long)m;
          char *aj = join_from(in[m] + strlen(ANSWER_LABEL), in,
                               (long long)m + 1, (long long)a_end);
          qq.answer = trim_dup(aj);
          free(aj);
        }
        continue;
      }
      char *inside = NULL;
      size_t label = individual_answer_label(in[m], &inside);
      IndividualAnswer entry;
      split_trimmed(inside, ',', 0, &entry.members);
      free(inside);
      /* A last part that is a change time is the time (SOM §11.9.10). */
      entry.changed_at = NULL;
      if (entry.members.len > 0 &&
          spec_review_is_time(entry.members.items[entry.members.len - 1])) {
        entry.changed_at =
            som_strdup(entry.members.items[entry.members.len - 1]);
        som_strlist_remove_at(&entry.members, entry.members.len - 1);
      }
      for (size_t i = 0; i < entry.members.len; i++) {
        if (som_strlist_contains(&answered, entry.members.items[i])) {
          som_strlist_push(&p->malformed,
                           fmt("line %zu: %s already answered %s; a member "
                               "answers a question at most once (SOM \xC2\xA7"
                               "11.9.8)",
                               b->start + m, entry.members.items[i], hs[q].id));
        } else {
          som_strlist_push_copy(&answered, entry.members.items[i]);
        }
      }
      size_t last = a_end;
      while (last > m && is_blank(in[last])) last--;
      entry.line = b->start + m;
      entry.end = b->start + last;
      char *aj =
          join_from(in[m] + label, in, (long long)m + 1, (long long)a_end);
      entry.answer = trim_dup(aj);
      free(aj);
      PUSH(qq.answers, qq.answers_len, qq.answers_cap, entry);
    }
    som_strlist_free(&answered);
    free(answer_lines);
    if (answer < 0) qq.answer = som_strdup("");
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

/* `- (base) …`: the base line of a conflict block; its text (borrowed), or
 * NULL for any other line. */
static const char *conflict_base_line(const char *l) {
  const char *head = "- (base)";
  if (!starts_with(l, head)) return NULL;
  const char *r = l + strlen(head);
  if (*r == '\0') return r;
  return *r == ' ' ? r + 1 : NULL;
}

/* `- (a) **alice, bob:** …`: a lettered alternative of a conflict block. Its
 * letter, its member label (the text between `**` and `:**`, owned; "" without
 * one) and its text (borrowed); 0 for any other line. */
static int conflict_alternative_line(const char *l, char *letter,
                                     char **members, const char **text) {
  if (!starts_with(l, "- (") || !is_letter(l[3]) || l[4] != ')') return 0;
  *letter = l[3];
  const char *r = l + 5;
  /* ` **<members>:**`: the members hold no `*`, so the label ends at the
   * first `*` after the opening `**`. */
  if (starts_with(r, " **")) {
    const char *star = strchr(r + 3, '*');
    if (star != NULL && star > r + 3 && star[-1] == ':' && star[1] == '*' &&
        (star[2] == '\0' || star[2] == ' ')) {
      *members = som_strdup_n(r + 3, (size_t)(star - 1 - (r + 3)));
      *text = star[2] == '\0' ? star + 2 : star + 3;
      return 1;
    }
  }
  if (*r != '\0' && *r != ' ') return 0;
  *members = som_strdup("");
  *text = *r == '\0' ? r : r + 1;
  return 1;
}

/* The header after the marker, `**X-<n> — <topic>:** <text>`, into owned
 * `*id`, `*topic` and `*text`; 0 when malformed. The topic is the shortest
 * that a `:**` ends at the end of the line or before a space. */
static int conflict_header(const char *h, char **id, char **topic,
                           char **text) {
  if (!starts_with(h, "**X-")) return 0;
  size_t i = 4;
  if (h[i] < '1' || h[i] > '9') return 0;
  while (h[i] >= '0' && h[i] <= '9') i++;
  if (!starts_with(h + i, EM_SEP)) return 0;
  size_t topic_start = i + strlen(EM_SEP);
  size_t len = strlen(h);
  for (size_t q = topic_start + 1; q + 3 <= len; q++) {
    if (strncmp(h + q, ":**", 3) != 0) continue;
    const char *after = h + q + 3;
    if (*after != '\0' && *after != ' ') continue;
    *id = som_strdup_n(h + 2, i - 2);
    *topic = som_strdup_n(h + topic_start, q - topic_start);
    *text = trim_dup(*after == '\0' ? after : after + 1);
    return 1;
  }
  return 0;
}

/* Closes the open entry of a conflict block being read: the base (letter 0)
 * or an alternative. */
static void close_conflict_entry(Conflict *c, int *open, char letter,
                                 SomStrList *members, SomStrList *lines) {
  if (!*open) return;
  char *joined = som_strlist_join(lines, "\n");
  char *text = trim_dup(joined);
  free(joined);
  if (letter == 0) {
    free(c->base);
    c->base = text;
    som_strlist_free(members);
  } else {
    SpecConflictAlternative a;
    a.letter = som_strdup_n(&letter, 1);
    a.members = *members;
    a.text = text;
    PUSH(c->alternatives, c->alternatives_len, c->alternatives_cap, a);
  }
  som_strlist_init(members);
  som_strlist_free(lines);
  *open = 0;
}

/* A conflict block (SOM §11.9.8): the header, the `(base)` line and the
 * lettered alternatives — each continuing on lines indented under it, its line
 * breaks kept — then `**Decision:**`. A malformed header leaves the block
 * unlisted; a missing base line or alternative is a finding. */
static void parse_conflict(Parsed *p, size_t bi) {
  const Block *b = &p->blocks[bi];
  size_t cnt = b->end - b->start + 1;
  const char **in = malloc(cnt * sizeof(char *));
  for (size_t k = 0; k < cnt; k++) in[k] = inner_of(LINE(p, b->start + k));
  const char *rest = in[0] + strlen(SCALES);
  if (starts_with(rest, VS16)) rest += strlen(VS16);
  Conflict c;
  memset(&c, 0, sizeof(c));
  c.block = bi;
  int header = conflict_header(trim_left(rest), &c.id, &c.topic, &c.text);
  if (!header) {
    c.topic = som_strdup("");
    c.text = som_strdup("");
    som_strlist_push(
        &p->malformed,
        fmt("line %zu: conflict header is not \"\xE2\x9A\x96\xEF\xB8\x8F "
            "**X-<n> \xE2\x80\x94 <topic>:**\" (SOM \xC2\xA7"
            "11.9.8)",
            b->start));
  }
  size_t decision_line = cnt;
  for (size_t k = 1; k < cnt; k++) {
    if (starts_with(in[k], DECISION_LABEL)) {
      decision_line = k;
      break;
    }
  }
  int open = 0;
  char letter = 0;
  SomStrList members, lines;
  som_strlist_init(&members);
  som_strlist_init(&lines);
  for (size_t k = 1; k < decision_line; k++) {
    const char *l = in[k];
    const char *base = conflict_base_line(l);
    char alt_letter = 0;
    char *alt_members = NULL;
    const char *alt_text = NULL;
    if (base != NULL) {
      close_conflict_entry(&c, &open, letter, &members, &lines);
      open = 1;
      letter = 0;
      som_strlist_push_copy(&lines, base);
    } else if (conflict_alternative_line(l, &alt_letter, &alt_members,
                                         &alt_text)) {
      close_conflict_entry(&c, &open, letter, &members, &lines);
      open = 1;
      letter = alt_letter;
      som_strlist_free(&members);
      split_trimmed(alt_members, ',', 1, &members);
      free(alt_members);
      som_strlist_push_copy(&lines, alt_text);
    } else if (open && l[0] == ' ') {
      som_strlist_push_copy(&lines, starts_with(l, "  ") ? l + 2 : lstrip(l));
    } else {
      close_conflict_entry(&c, &open, letter, &members, &lines);
    }
  }
  close_conflict_entry(&c, &open, letter, &members, &lines);
  som_strlist_free(&members);
  som_strlist_free(&lines);
  if (decision_line < cnt) {
    char *dj = join_from(in[decision_line] + strlen(DECISION_LABEL), in,
                         (long long)decision_line + 1, (long long)cnt - 1);
    c.decision = trim_dup(dj);
    free(dj);
  } else {
    c.decision = som_strdup("");
  }
  if (header && c.base == NULL) {
    som_strlist_push(
        &p->malformed,
        fmt("line %zu: conflict %s has no \"(base)\" line (SOM \xC2\xA7"
            "11.9.8)",
            b->start, c.id));
  }
  if (header && c.alternatives_len == 0) {
    som_strlist_push(&p->malformed,
                     fmt("line %zu: conflict %s has no lettered alternative "
                         "(SOM \xC2\xA7"
                         "11.9.8)",
                         b->start, c.id));
  }
  p->blocks[bi].conflict = p->conflicts_len;
  PUSH(p->conflicts, p->conflicts_len, p->conflicts_cap, c);
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
  Mark m;
  memset(&m, 0, sizeof(m));
  m.start = start;
  m.end = end;
  m.body_end = end;
  m.line = line;
  m.kind = kind;
  m.text = text;
  m.new_text = new_text;
  m.comment = comment;
  m.change_index = -1;
  m.comment_index = -1;
  som_strlist_init(&m.authors);
  PUSH(p->marks, p->marks_len, p->marks_cap, m);
}

/* Whether `c` is whitespace for the edge-space rule (SOM §11.9.3). */
static int is_edge_ws(char c) { return c == ' ' || c == '\t' || c == '\n'; }

/* Records whether `raw[0, len)`, a mark's text as written between its
 * delimiters, begins / ends with whitespace: into the mark's text edges, or
 * (`is_new`) its new-text edges. */
static void set_edges(Mark *m, const char *raw, size_t len, int is_new) {
  int lead = len > 0 && is_edge_ws(raw[0]);
  int trail = len > 0 && is_edge_ws(raw[len - 1]);
  if (is_new) {
    m->new_lead = lead;
    m->new_trail = trail;
  } else {
    m->text_lead = lead;
    m->text_trail = trail;
  }
}

/* Whether a code point is whitespace as JavaScript's `\s` reads it. */
static int js_is_space(unsigned long c) {
  return c != 0x85 && dart_is_space(c);
}

/* `s[0, len)` split into its runs of non-whitespace, into `out` (initialised
 * here). */
static void split_words(const char *s, size_t len, SomStrList *out) {
  som_strlist_init(out);
  const unsigned char *q = (const unsigned char *)s, *end = q + len;
  const unsigned char *word = NULL;
  while (q < end) {
    const unsigned char *st = q;
    if (js_is_space(next_cp(&q, end))) {
      if (word != NULL)
        som_strlist_push(out,
                         som_strdup_n((const char *)word, (size_t)(st - word)));
      word = NULL;
    } else if (word == NULL) {
      word = st;
    }
  }
  if (word != NULL)
    som_strlist_push(out,
                     som_strdup_n((const char *)word, (size_t)(end - word)));
}

/* Whether a mark kind is a change, which alone takes votes (SOM §11.9.8). */
static int is_change_mark(SpecMarkKind kind) {
  return kind == SPEC_MARK_INSERTION || kind == SPEC_MARK_DELETION ||
         kind == SPEC_MARK_SUBSTITUTION;
}

/* Reads a token's inside `s[0, len)`, `[<authors>][ <votes>][ <time>]`, into
 * `m`; or returns the reason (owned) it breaks the grammar of SOM §11.9.8,
 * leaving `m`'s authors and votes alone. A last word that is a change time is
 * `m`'s time (SOM §11.9.10) either way. */
static char *read_token(const char *s, size_t len, Mark *m) {
  /* A space after a comma is allowed: `,` and the whitespace after it is one
   * separator. */
  SomBuf joined;
  som_buf_init(&joined);
  const unsigned char *q = (const unsigned char *)s, *end = q + len;
  while (q < end) {
    char c = (char)*q++;
    som_buf_putc(&joined, c);
    if (c != ',') continue;
    for (;;) {
      const unsigned char *st = q;
      if (q >= end || !js_is_space(next_cp(&q, end))) {
        q = st;
        break;
      }
    }
  }
  SomStrList words;
  split_words(joined.data ? joined.data : "", joined.len, &words);
  som_buf_free(&joined);
  char *why = NULL;
  SomStrList authors;
  som_strlist_init(&authors);
  SpecMarkVote *votes = NULL;
  size_t votes_len = 0, votes_cap = 0;
  if (words.len == 0) {
    why = som_strdup("is empty");
  } else if (spec_review_is_time(words.items[words.len - 1])) {
    free(m->changed_at);
    m->changed_at = som_strdup(words.items[words.len - 1]);
    som_strlist_remove_at(&words, words.len - 1);
  }
  size_t k = 0;
  if (why == NULL && words.len > 0 && words.items[0][0] != '+' &&
      words.items[0][0] != '-') {
    split_trimmed(words.items[0], ',', 0, &authors);
    k = 1;
  }
  for (; why == NULL && k < words.len; k++) {
    const char *w = words.items[k];
    if (w[0] != '+' && w[0] != '-') {
      why = fmt("has \"%s\" where a vote belongs", w);
      break;
    }
    SpecMarkVote v = {som_strdup(w + 1), w[0] == '+'};
    PUSH(votes, votes_len, votes_cap, v);
  }
  SomStrList seen;
  som_strlist_init(&seen);
  for (size_t i = 0; why == NULL && i < authors.len + votes_len; i++) {
    const char *id =
        i < authors.len ? authors.items[i] : votes[i - authors.len].member;
    if (!spec_review_is_member_id(id)) {
      why = fmt("names \"%s\", which is not a member id", id);
    } else if (som_strlist_contains(&seen, id)) {
      why = fmt("names %s twice, or as author and voter", id);
    } else {
      som_strlist_push_copy(&seen, id);
    }
  }
  som_strlist_free(&seen);
  if (why == NULL && votes_len > 0 && !is_change_mark(m->kind)) {
    why = fmt("carries votes on a %s mark, which takes authors only",
              spec_mark_kind_name(m->kind));
  }
  som_strlist_free(&words);
  if (why != NULL) {
    som_strlist_free(&authors);
    votes_free(votes, votes_len);
    return why;
  }
  som_strlist_free(&m->authors);
  m->authors = authors;
  votes_free(m->votes, m->votes_len);
  m->votes = votes;
  m->votes_len = votes_len;
  return NULL;
}

/* Reads the attribution token `{@…}` at segment offset `at` (SOM §11.9.8)
 * into `m`, which it directly follows, and returns the segment offset after
 * it. The token is part of the mark — its markup, its decision — so `m->end`
 * moves past it. A token that breaks the grammar is still part of the mark
 * (it goes with the mark on a decision) and is a finding; its members are
 * then not listed. */
static size_t attach_token(Parsed *p, const char *seg, size_t len, size_t at,
                           size_t base, Mark *m) {
  long long line_end = find(seg, len, at, "\n");
  long long close = find(seg, len, at + 2, "}");
  if (close < 0 || (line_end >= 0 && close > line_end)) {
    som_strlist_push(&p->malformed,
                     fmt("line %zu: attribution token \"{@\" is not closed "
                         "(SOM \xC2\xA7"
                         "11.9.8)",
                         m->line));
    return at;
  }
  char *why = read_token(seg + at + 2, (size_t)close - at - 2, m);
  if (why != NULL) {
    som_strlist_push(&p->malformed,
                     fmt("line %zu: attribution token %s (SOM \xC2\xA7"
                         "11.9.8)",
                         m->line, why));
    free(why);
  }
  m->end = base + (size_t)close + 1;
  return (size_t)close + 1;
}

static void add_issue(Parsed *p, size_t line, const char *code) {
  MarkIssue m = {line, code};
  PUSH(p->mark_issues, p->mark_issues_len, p->mark_issues_cap, m);
}

static int is_blank_char(char c) { return c == ' ' || c == '\t'; }

/* What `read_quote` found. */
enum { QUOTE_NONE = 0, QUOTE_OK = 1, QUOTE_UNCLOSED = 2, QUOTE_NO_ARROW = 3 };

/* Reads the quote at the start of a comment mark's inner text `s[0, len)`,
 * whose first byte is at value offset `at`, into `m` (SOM §11.9.3).
 * Returns QUOTE_OK, QUOTE_NONE when `s` opens no quote, or the issue of one
 * that is malformed (QUOTE_UNCLOSED, QUOTE_NO_ARROW); `m` is set only for
 * QUOTE_OK. */
static int read_quote(const char *s, size_t len, size_t at, Mark *m) {
  size_t a = 0;
  while (a < len && strchr(" \t\r\n", s[a]) != NULL) a++;
  if (a + 3 > len || s[a] != '[') return QUOTE_NONE;
  SpecMarkKind kind;
  if (memcmp(s + a + 1, "++", 2) == 0) {
    kind = SPEC_MARK_INSERTION;
  } else if (memcmp(s + a + 1, "--", 2) == 0) {
    kind = SPEC_MARK_DELETION;
  } else if (memcmp(s + a + 1, "~~", 2) == 0) {
    kind = SPEC_MARK_SUBSTITUTION;
  } else {
    return QUOTE_NONE;
  }
  char d[3] = {s[a + 1], s[a + 2], '\0'};
  long long j = find(s, len, a + 3, d);
  while (j >= 0) {
    size_t t = (size_t)j + 2;
    while (t < len && is_blank_char(s[t])) t++;
    const char *outcome = NULL;
    long long close = -1;
    if (t < len && s[t] == ']') {
      close = (long long)t;
    } else if (t < len && s[t] == '|') {
      t++;
      while (t < len && is_blank_char(s[t])) t++;
      static const char *const words[2] = {"accepted", "rejected"};
      for (int w = 0; w < 2; w++) {
        size_t wl = strlen(words[w]);
        if (t + wl > len || memcmp(s + t, words[w], wl) != 0) continue;
        size_t u = t + wl;
        while (u < len && is_blank_char(s[u])) u++;
        if (u < len && s[u] == ']') {
          outcome = words[w];
          close = (long long)u;
        }
        break;
      }
    }
    if (close >= 0) {
      const char *body = s + a + 3;
      size_t body_len = (size_t)j - a - 3;
      char *old_text, *new_text;
      if (kind == SPEC_MARK_INSERTION) {
        old_text = som_strdup("");
        new_text = trim_n(body, body_len);
      } else if (kind == SPEC_MARK_DELETION) {
        old_text = trim_n(body, body_len);
        new_text = som_strdup("");
      } else {
        long long arrow = find(body, body_len, 0, "~>");
        if (arrow < 0) return QUOTE_NO_ARROW;
        old_text = trim_n(body, (size_t)arrow);
        new_text = trim_n(body + arrow + 2, body_len - (size_t)arrow - 2);
      }
      m->has_quote = 1;
      m->q_kind = kind;
      m->q_old = old_text;
      m->q_new = new_text;
      m->q_outcome = outcome;
      m->q_delim_end = at + (size_t)j + 2;
      m->q_end = at + (size_t)close + 1;
      m->q_comment = trim_n(s + close + 1, len - (size_t)close - 1);
      return QUOTE_OK;
    }
    j = find(s, len, (size_t)j + 1, d);
  }
  return QUOTE_UNCLOSED;
}

static const char *mark_replacement(const Mark *m, int accept);

/* Links each change comment to the change written directly before it whose
 * kind and texts it quotes (SOM §11.9.3). */
static void attach_change_comments(Parsed *p) {
  for (size_t k = 1; k < p->marks_len; k++) {
    Mark *q = &p->marks[k];
    Mark *c = &p->marks[k - 1];
    if (!q->has_quote || q->q_outcome != NULL || !is_change_mark(c->kind))
      continue;
    if (c->end != q->start || c->kind != q->q_kind) continue;
    if (strcmp(mark_replacement(c, 0), q->q_old) != 0 ||
        strcmp(mark_replacement(c, 1), q->q_new) != 0)
      continue;
    q->change_index = (long long)k - 1;
    c->comment_index = (long long)k;
  }
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
    if (c == '{' && i + 1 < len && seg[i + 1] == '@') {
      /* A token that no mark precedes directly (a mark's own token is read
       * with the mark, below). */
      som_strlist_push(&p->malformed,
                       fmt("line %zu: an attribution token \"{@\" does not "
                           "follow a mark directly (SOM \xC2\xA7"
                           "11.9.8)",
                           line_of(line_start, p->lines.len, base + i)));
      long long close = find(seg, len, i + 2, "}");
      i = close < 0 ? i + 2 : (size_t)close + 1;
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
    size_t before = p->marks_len;
    switch (oi) {
      case 0: {
        add_mark(p, base + i, base + end, line, SPEC_MARK_COMMENT,
                 som_strdup(""), NULL, trim_n(inner, inner_len));
        int q = read_quote(inner, inner_len, base + i + 3,
                           &p->marks[p->marks_len - 1]);
        if (q == QUOTE_UNCLOSED) {
          som_strlist_push(&p->malformed,
                           fmt("line %zu: the quote of a change comment is "
                               "not closed; it is read as a plain comment "
                               "(SOM \xC2\xA7"
                               "11.9.3)",
                               line));
        } else if (q == QUOTE_NO_ARROW) {
          som_strlist_push(&p->malformed,
                           fmt("line %zu: the quote of a change comment has "
                               "no \"~>\"; it is read as a plain comment "
                               "(SOM \xC2\xA7"
                               "11.9.3)",
                               line));
        }
        break;
      }
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
        set_edges(&p->marks[p->marks_len - 1], inner, inner_len, 0);
        break;
      case 3:
        add_mark(p, base + i, base + end, line, SPEC_MARK_DELETION,
                 trim_n(inner, inner_len), NULL, NULL);
        set_edges(&p->marks[p->marks_len - 1], inner, inner_len, 0);
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
        set_edges(&p->marks[p->marks_len - 1], inner, (size_t)arrow, 0);
        set_edges(&p->marks[p->marks_len - 1], inner + arrow + 2,
                  inner_len - (size_t)arrow - 2, 1);
        break;
      }
    }
    if (p->marks_len > before && end + 1 < len && seg[end] == '{' &&
        seg[end + 1] == '@') {
      end = attach_token(p, seg, len, end, base, &p->marks[p->marks_len - 1]);
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
  attach_change_comments(p);
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
      Block b = {s, e, SPEC_REVIEW_ANNOTATION_COMMENT, p->comments_len, 0, 0,
                 0, 0};
      PUSH(p->blocks, p->blocks_len, p->blocks_cap, b);
      parse_comment(p, p->blocks_len - 1);
    } else if (starts_with(first, QOPEN)) {
      Block b = {s, e, SPEC_REVIEW_ANNOTATION_QUESTION, 0, 0, 0, 0, 0};
      PUSH(p->blocks, p->blocks_len, p->blocks_cap, b);
      parse_questions(p, p->blocks_len - 1);
    } else if (starts_with(first, SCALES)) {
      Block b = {s, e, SPEC_REVIEW_ANNOTATION_CONFLICT, 0, 0, 0, 0, 0};
      PUSH(p->blocks, p->blocks_len, p->blocks_cap, b);
      parse_conflict(p, p->blocks_len - 1);
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
  som_strlist_free(&a->authors);
  votes_free(a->votes, a->votes_len);
  for (size_t i = 0; i < a->answers_len; i++) {
    som_strlist_free(&a->answers[i].members);
    free(a->answers[i].answer);
    free(a->answers[i].changed_at);
  }
  free(a->answers);
  free(a->base);
  alternatives_free(a->alternatives, a->alternatives_len);
  free(a->changed_at);
  memset(a, 0, sizeof(*a));
}

int spec_review_annotation_is_open(const SpecReviewAnnotation *a) {
  return (a->kind == SPEC_REVIEW_ANNOTATION_QUESTION ||
          a->kind == SPEC_REVIEW_ANNOTATION_CONFLICT) &&
         (a->answer == NULL || a->answer[0] == '\0');
}

int spec_review_annotation_is_unresolved(const SpecReviewAnnotation *a) {
  return a->answer != NULL && is_unresolved_answer(a->answer);
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
  if (a->kind != SPEC_REVIEW_ANNOTATION_QUESTION ||
      spec_review_annotation_is_unresolved(a)) {
    return NULL;
  }
  return leading_letter(a->answer ? a->answer : "");
}

char *spec_review_annotation_decision_letter(const SpecReviewAnnotation *a) {
  if (a->kind != SPEC_REVIEW_ANNOTATION_CONFLICT) return NULL;
  return decision_letter_of(a->answer ? a->answer : "");
}

static void put_str_list(SomBuf *b, int *first, const char *key,
                         const SomStrList *l) {
  put_key(b, first, key);
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i) som_buf_putc(b, ',');
    char *e = som_json_encode_str(l->items[i]);
    som_buf_puts(b, e);
    free(e);
  }
  som_buf_putc(b, ']');
}

static void put_votes(SomBuf *b, int *first, const char *key,
                      const SpecMarkVote *v, size_t len) {
  put_key(b, first, key);
  som_buf_putc(b, '[');
  for (size_t i = 0; i < len; i++) {
    if (i) som_buf_putc(b, ',');
    int f = 1;
    som_buf_putc(b, '{');
    put_str(b, &f, "member", v[i].member);
    put_str(b, &f, "vote", v[i].accept ? "accept" : "reject");
    som_buf_putc(b, '}');
  }
  som_buf_putc(b, ']');
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

/* The JSON form of `a`; `team` adds the members of SOM §11.9.8. */
static char *annotation_json(const SpecReviewAnnotation *a, int team) {
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
      if (a->changed_at != NULL) {
        put_str(&b, &first, "changedAt", a->changed_at);
      }
      break;
    case SPEC_REVIEW_ANNOTATION_QUESTION:
      put_str(&b, &first, "id", a->id);
      put_str(&b, &first, "topic", a->topic);
      put_bool(&b, &first, "starred", a->starred);
      put_bool(&b, &first, "combined", a->combined);
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "answer", a->answer);
      put_bool(&b, &first, "open", spec_review_annotation_is_open(a));
      if (team) {
        put_bool(&b, &first, "unresolved",
                 spec_review_annotation_is_unresolved(a));
      }
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
      if (team) {
        put_key(&b, &first, "answers");
        som_buf_putc(&b, '[');
        for (size_t i = 0; i < a->answers_len; i++) {
          if (i) som_buf_putc(&b, ',');
          int f = 1;
          som_buf_putc(&b, '{');
          put_str_list(&b, &f, "members", &a->answers[i].members);
          put_str(&b, &f, "answer", a->answers[i].answer);
          char *al = leading_letter(a->answers[i].answer);
          put_str(&b, &f, "answerLetter", al);
          free(al);
          if (a->answers[i].changed_at != NULL) {
            put_str(&b, &f, "changedAt", a->answers[i].changed_at);
          }
          som_buf_putc(&b, '}');
        }
        som_buf_putc(&b, ']');
      }
      break;
    case SPEC_REVIEW_ANNOTATION_CONFLICT: {
      put_str(&b, &first, "id", a->id);
      put_str(&b, &first, "qualifiedId", a->qualified_id);
      put_str(&b, &first, "topic", a->topic);
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "base", a->base ? a->base : "");
      put_key(&b, &first, "alternatives");
      som_buf_putc(&b, '[');
      for (size_t i = 0; i < a->alternatives_len; i++) {
        if (i) som_buf_putc(&b, ',');
        int f = 1;
        som_buf_putc(&b, '{');
        put_str(&b, &f, "letter", a->alternatives[i].letter);
        put_str_list(&b, &f, "members", &a->alternatives[i].members);
        put_str(&b, &f, "text", a->alternatives[i].text);
        som_buf_putc(&b, '}');
      }
      som_buf_putc(&b, ']');
      put_str(&b, &first, "decision", a->answer);
      char *dl = spec_review_annotation_decision_letter(a);
      put_str(&b, &first, "decisionLetter", dl);
      free(dl);
      put_bool(&b, &first, "open", spec_review_annotation_is_open(a));
      put_bool(&b, &first, "unresolved",
               spec_review_annotation_is_unresolved(a));
      break;
    }
    case SPEC_REVIEW_ANNOTATION_MARK:
      put_str(&b, &first, "markKind", spec_mark_kind_name(a->mark_kind));
      put_str(&b, &first, "text", a->text);
      put_str(&b, &first, "newText", a->new_text);
      put_str(&b, &first, "comment", a->comment);
      if (a->changed_at != NULL) {
        put_str(&b, &first, "changedAt", a->changed_at);
      }
      if (team) {
        put_str_list(&b, &first, "authors", &a->authors);
        put_votes(&b, &first, "votes", a->votes, a->votes_len);
      }
      break;
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_review_annotation_to_json(const SpecReviewAnnotation *a) {
  return annotation_json(a, 0);
}

char *spec_review_annotation_to_team_json(const SpecReviewAnnotation *a) {
  return annotation_json(a, 1);
}

static char *counts_json(const SpecReviewAnnotationCounts *c, int team) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_int(&b, &first, "questions", (long long)c->questions);
  put_int(&b, &first, "openQuestions", (long long)c->open_questions);
  put_int(&b, &first, "answeredQuestions", (long long)c->answered_questions);
  put_int(&b, &first, "comments", (long long)c->comments);
  put_int(&b, &first, "marks", (long long)c->marks);
  if (team) {
    put_int(&b, &first, "unresolvedQuestions",
            (long long)c->unresolved_questions);
    put_int(&b, &first, "conflicts", (long long)c->conflicts);
    put_int(&b, &first, "openConflicts", (long long)c->open_conflicts);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_review_annotation_counts_to_json(
    const SpecReviewAnnotationCounts *c) {
  return counts_json(c, 0);
}

char *spec_review_annotation_counts_to_team_json(
    const SpecReviewAnnotationCounts *c) {
  return counts_json(c, 1);
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
  som_strlist_init(&a.authors);
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
      e.a.changed_at = dup_or_null(c->changed_at);
      PUSH(o, len, cap, e);
    } else if (b->kind == SPEC_REVIEW_ANNOTATION_CONFLICT) {
      const Conflict *c = &p->conflicts[b->conflict];
      if (c->id == NULL) continue;
      Ordered e;
      e.line = b->start;
      e.rank = 0;
      e.seq = seq++;
      e.a = blank_annotation(SPEC_REVIEW_ANNOTATION_CONFLICT, path, field,
                             b->start);
      e.a.id = som_strdup(c->id);
      e.a.qualified_id =
          qualifier != NULL ? fmt("%s %s", qualifier, c->id) : NULL;
      e.a.topic = som_strdup(c->topic);
      e.a.text = som_strdup(c->text);
      e.a.context = som_strdup("");
      e.a.base = som_strdup(c->base ? c->base : "");
      e.a.alternatives =
          alternatives_copy(c->alternatives, c->alternatives_len);
      e.a.alternatives_len = c->alternatives_len;
      e.a.answer = som_strdup(c->decision);
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
        e.a.answers_len = q->answers_len;
        e.a.answers =
            q->answers_len
                ? malloc(q->answers_len * sizeof(SpecIndividualAnswer))
                : NULL;
        for (size_t ai = 0; ai < q->answers_len; ai++) {
          som_strlist_copy(&e.a.answers[ai].members, &q->answers[ai].members);
          e.a.answers[ai].answer = som_strdup(q->answers[ai].answer);
          e.a.answers[ai].changed_at = dup_or_null(q->answers[ai].changed_at);
        }
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
    som_strlist_copy(&e.a.authors, &m->authors);
    e.a.votes = votes_copy(m->votes, m->votes_len);
    e.a.votes_len = m->votes_len;
    e.a.changed_at = dup_or_null(m->changed_at);
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
static size_t paragraph_bounds(const SomStrList *lines,
                               const unsigned char *code, size_t **starts,
                               size_t **ends) {
  size_t *out = NULL, *outs = NULL;
  size_t len = 0, cap = 0, slen = 0, scap = 0;
  size_t k = 0;
  while (k < lines->len) {
    if (is_blank(lines->items[k]) && !code[k]) {
      k++;
      continue;
    }
    size_t s = k;
    while (k + 1 < lines->len &&
           !(is_blank(lines->items[k + 1]) && !code[k + 1]))
      k++;
    if (starts != NULL) PUSH(outs, slen, scap, s);
    PUSH(out, len, cap, k);
    k++;
  }
  if (starts != NULL) *starts = outs;
  *ends = out;
  return len;
}

static size_t paragraph_ends(const SomStrList *lines, const unsigned char *code,
                             size_t **ends) {
  return paragraph_bounds(lines, code, NULL, ends);
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

/* A comment header's parentheses: the author and the change time, either
 * alone, or NULL when there is neither (SOM §11.9.10). Owned. */
static char *author_and_time(const char *author, const char *changed_at) {
  const char *a = author != NULL && author[0] != '\0' ? author : NULL;
  if (a == NULL) return dup_or_null(changed_at);
  return changed_at == NULL ? som_strdup(a) : fmt("%s, %s", a, changed_at);
}

void spec_format_comment_block(const char *id, const char *text,
                               const char *author, const char *changed_at,
                               SomStrList *out) {
  SomStrList t;
  split_lines(text, &t);
  SomBuf head;
  som_buf_init(&head);
  som_buf_puts(&head, "> " ARROW VS16 " **");
  som_buf_puts(&head, id);
  som_buf_puts(&head, "**");
  char *who = author_and_time(author, changed_at);
  if (who != NULL) {
    som_buf_puts(&head, " (");
    som_buf_puts(&head, who);
    som_buf_puts(&head, "):");
    free(who);
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

char *spec_review_format_attribution_token(const SomStrList *authors,
                                           const SpecMarkVote *votes,
                                           size_t votes_len,
                                           const char *changed_at) {
  SomStrList parts;
  som_strlist_init(&parts);
  if (authors != NULL && authors->len > 0) {
    som_strlist_push(&parts, som_strlist_join(authors, ","));
  }
  for (size_t i = 0; i < votes_len; i++) {
    som_strlist_push(&parts,
                     fmt("%c%s", votes[i].accept ? '+' : '-', votes[i].member));
  }
  if (changed_at != NULL) som_strlist_push_copy(&parts, changed_at);
  char *out;
  if (parts.len == 0) {
    out = som_strdup("");
  } else {
    char *joined = som_strlist_join(&parts, " ");
    out = fmt("{@%s}", joined);
    free(joined);
  }
  som_strlist_free(&parts);
  return out;
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

/* The punctuation no space is left before, and after which an edge space is
 * kept (SOM §11.9.3). */
static const char CLOSING_PUNCTUATION[] = ".,;:!?)]}";

/* The edge spaces written beside the text decision `accept` keeps of `m`:
 * into `lead` and `trail`. */
static void kept_edges(const Mark *m, int accept, int *lead, int *trail) {
  *lead = *trail = 0;
  if ((m->kind == SPEC_MARK_INSERTION && accept) ||
      (m->kind == SPEC_MARK_DELETION && !accept) ||
      (m->kind == SPEC_MARK_SUBSTITUTION && !accept)) {
    *lead = m->text_lead;
    *trail = m->text_trail;
  } else if (m->kind == SPEC_MARK_SUBSTITUTION) {
    *lead = m->new_lead;
    *trail = m->new_trail;
  }
}

/* Applies a mark's replacement with the whitespace rules of SOM §11.9.3:
 * never join two words, keep an edge space written inside a change mark
 * after punctuation and before a word, never leave a double space or a space
 * before punctuation, and a mark that was a whole line leaves no blank line.
 * `decision` names the decision the replacement comes from (1 accept,
 * 0 reject); -1 when the mark is removed rather than decided. Owned. */
static char *replace_mark(const char *value, const Mark *m,
                          const char *replacement, int decision) {
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
                 strchr(CLOSING_PUNCTUATION, after[0]) != NULL) {
        while (blen > 0 && is_sp(value[blen - 1])) blen--;
      }
    } else if ((blen == 0 || value[blen - 1] == '\n') && is_sp(after[0])) {
      while (is_sp(after[0])) after++;
    }
  } else {
    size_t alen = strlen(after);
    /* Never join two words: a mark written flush against a word keeps a
     * space on that side. An edge space written inside a change mark, beside
     * the text the decision keeps, is kept after punctuation and before a
     * word or an opening bracket. */
    int lead = 0, trail = 0;
    if (decision >= 0) kept_edges(m, decision, &lead, &trail);
    pre = (word_char_last(value, blen) && word_char_first(replacement, rlen)) ||
          (lead && blen > 0 &&
           strchr(CLOSING_PUNCTUATION, value[blen - 1]) != NULL);
    post = alen > 0 &&
           ((word_char_last(replacement, rlen) &&
             word_char_first(after, alen)) ||
            (trail && (word_char_first(after, alen) || after[0] == '(' ||
                       after[0] == '[')));
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
    char *next = replace_mark(v, m, mark_replacement(m, accept),
                              accept != 0);
    free(v);
    v = next;
  }
  parsed_free(&p);
  return v;
}

/* `value` with the outcome written into the quote of change comment `q`:
 * everything from its closing delimiter to its `]` becomes ` | accepted]` or
 * ` | rejected]`. Owned. */
static char *record_outcome(const char *value, const Mark *q, int accept) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, value, q->q_delim_end);
  som_buf_puts(&b, accept ? " | accepted]" : " | rejected]");
  som_buf_puts(&b, value + q->q_end);
  return som_buf_take(&b);
}

/* `value` with mark `k` of `p` decided; a change's attached comment records
 * the outcome (SOM §11.9.3). Owned. */
static char *decide_mark(const char *value, const Parsed *p, size_t k,
                         int accept) {
  const Mark *m = &p->marks[k];
  char *v = som_strdup(value);
  if (m->comment_index >= 0) {
    char *next = record_outcome(v, &p->marks[m->comment_index], accept);
    free(v);
    v = next;
  }
  char *out = replace_mark(v, m, mark_replacement(m, accept), accept != 0);
  free(v);
  return out;
}

char *spec_decide_all_marks_text(const char *value, int accept) {
  Parsed p;
  parse(value, &p);
  char *v = som_strdup(value);
  for (size_t k = p.marks_len; k-- > 0;) {
    if (p.marks[k].has_quote) continue;
    char *next = decide_mark(v, &p, k, accept);
    free(v);
    v = next;
  }
  parsed_free(&p);
  return v;
}

/* The trimmed `text` of an inline comment (owned), or NULL with `*err`
 * filled when it is empty or holds a mark delimiter or a blank line. */
static char *check_inline_comment(const char *text,
                                  SpecReviewAnnotationError *err) {
  char *t = trim_dup(text);
  size_t len = strlen(t);
  if (len == 0) {
    set_error(err, "a comment needs text");
    free(t);
    return NULL;
  }
  int bad = contains_opener(t, len) || find(t, len, 0, "<<}") >= 0;
  for (size_t i = 0; !bad && i < len; i++) {
    if (t[i] != '\n') continue;
    size_t j = i + 1;
    while (j < len && (t[j] == ' ' || t[j] == '\t' || t[j] == '\r')) j++;
    bad = j < len && t[j] == '\n';
  }
  if (bad) {
    set_error(err, "a comment cannot hold a mark delimiter or a blank line");
    free(t);
    return NULL;
  }
  return t;
}

/* The whitespace of the change-comment anchors (SOM §11.9.3). */
static int is_anchor_space(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

static size_t non_space_count(const char *s, size_t len) {
  size_t n = 0;
  for (size_t i = 0; i < len; i++) {
    if (!is_anchor_space(s[i])) n++;
  }
  return n;
}

/* Where change-comment anchor `k` falls in `r` (whose marks are `rm`): after
 * the k-th non-whitespace character, or at the end of a mark that brings the
 * count to k (deletions and substitutions count their text, insertions
 * nothing); the end of `r` when it is never reached. */
static size_t anchor_place(const char *r, const Parsed *rm, size_t k) {
  if (k == 0) return 0;
  size_t len = strlen(r);
  size_t n = 0, i = 0, mi = 0;
  while (i < len) {
    if (mi < rm->marks_len && rm->marks[mi].start == i) {
      const Mark *m = &rm->marks[mi++];
      n += m->kind == SPEC_MARK_INSERTION
               ? 0
               : non_space_count(m->text, strlen(m->text));
      i = m->end;
      if (n >= k) return i;
      continue;
    }
    if (!is_anchor_space(r[i])) n++;
    i++;
    if (n >= k) return i;
  }
  return len;
}

/* `after` (a value just written as marks) with an attribution token on every
 * change mark it lacks one on (SOM §11.9.10): the token of the same change in
 * `before` (same kind, old and new text; each used once, in order) when
 * `before` held it, else a new one with `author` and `time`. Owned. */
static char *stamp_marks(const char *before, const char *after,
                         const char *author, const char *time) {
  Parsed bp;
  parse(before, &bp);
  size_t *old = calloc(bp.marks_len ? bp.marks_len : 1, sizeof(size_t));
  unsigned char *used = calloc(bp.marks_len ? bp.marks_len : 1, 1);
  size_t old_len = 0;
  for (size_t k = 0; k < bp.marks_len; k++) {
    if (is_change_mark(bp.marks[k].kind)) old[old_len++] = k;
  }
  SomStrList who;
  som_strlist_init(&who);
  if (author != NULL) som_strlist_push_copy(&who, author);
  char *fresh = spec_review_format_attribution_token(&who, NULL, 0, time);
  som_strlist_free(&who);
  Parsed ap;
  parse(after, &ap);
  SomBuf b;
  som_buf_init(&b);
  size_t from = 0;
  for (size_t k = 0; k < ap.marks_len; k++) {
    const Mark *m = &ap.marks[k];
    if (!is_change_mark(m->kind) || m->end > m->body_end) continue;
    const char *token = fresh;
    size_t token_len = strlen(fresh);
    for (size_t i = 0; i < old_len; i++) {
      const Mark *o = &bp.marks[old[i]];
      if (used[i] || o->kind != m->kind ||
          strcmp(mark_replacement(o, 0), mark_replacement(m, 0)) != 0 ||
          strcmp(mark_replacement(o, 1), mark_replacement(m, 1)) != 0) {
        continue;
      }
      used[i] = 1;
      token = before + o->body_end;
      token_len = o->end - o->body_end;
      break;
    }
    if (token_len == 0) continue;
    som_buf_putn(&b, after + from, m->body_end - from);
    som_buf_putn(&b, token, token_len);
    from = m->body_end;
  }
  som_buf_puts(&b, after + from);
  parsed_free(&ap);
  parsed_free(&bp);
  free(fresh);
  free(used);
  free(old);
  return som_buf_take(&b);
}

/* `spec_review_annotations_set_marked` with the value's change comments kept
 * (SOM §11.9.3): taken out of the original, then written back where their
 * anchor falls. */
static SpecMarkedChange mark_keeping_change_comments(const char *current,
                                                     const char *text) {
  /* 1. The original: every mark rejected except the change comments. */
  char *original = som_strdup(current);
  {
    Parsed p;
    parse(current, &p);
    for (size_t k = p.marks_len; k-- > 0;) {
      if (p.marks[k].has_quote) continue;
      char *next = replace_mark(original, &p.marks[k],
                                mark_replacement(&p.marks[k], 0), 0);
      free(original);
      original = next;
    }
    parsed_free(&p);
  }
  /* 2. Each change comment's markup, anchor and leading space. */
  Parsed op;
  parse(original, &op);
  size_t kept = 0;
  for (size_t k = 0; k < op.marks_len; k++) kept += op.marks[k].has_quote;
  char **markups = calloc(kept ? kept : 1, sizeof(char *));
  size_t *anchors = calloc(kept ? kept : 1, sizeof(size_t));
  int *spaces = calloc(kept ? kept : 1, sizeof(int));
  size_t counted = 0, from = 0, a = 0;
  for (size_t k = 0; k < op.marks_len; k++) {
    const Mark *m = &op.marks[k];
    if (!m->has_quote) continue;
    counted += non_space_count(original + from, m->start - from);
    from = m->end;
    markups[a] = som_strdup_n(original + m->start, m->end - m->start);
    anchors[a] = counted;
    spaces[a] = m->start > 0 && is_blank_char(original[m->start - 1]);
    a++;
  }
  /* 3. Removed, compared. */
  char *base = som_strdup(original);
  for (size_t k = op.marks_len; k-- > 0;) {
    if (!op.marks[k].has_quote) continue;
    char *next = replace_mark(base, &op.marks[k], "", -1);
    free(base);
    base = next;
  }
  parsed_free(&op);
  free(original);
  SpecMarkedChange result = spec_mark_change_text(base, text);
  free(base);
  if (kept > 0) {
    /* 4. Written back where k non-whitespace characters have passed. */
    Parsed rm;
    parse(result.text, &rm);
    size_t *at = calloc(kept, sizeof(size_t));
    for (size_t j = 0; j < kept; j++)
      at[j] = anchor_place(result.text, &rm, anchors[j]);
    parsed_free(&rm);
    char *out = som_strdup(result.text);
    for (size_t j = kept; j-- > 0;) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_putn(&b, out, at[j]);
      if (spaces[j]) som_buf_putc(&b, ' ');
      som_buf_puts(&b, markups[j]);
      som_buf_puts(&b, out + at[j]);
      free(out);
      out = som_buf_take(&b);
    }
    free(at);
    free(result.text);
    result.text = out;
  }
  for (size_t j = 0; j < kept; j++) free(markups[j]);
  free(markups);
  free(anchors);
  free(spaces);
  return result;
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
    char *next = replace_mark(v, m, mark_replacement(m, 1), 1);
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
  return spec_review_annotations_make_with_clock(doc, qualifier, NULL, NULL);
}

SpecReviewAnnotations spec_review_annotations_make_with_clock(
    SpecDocument *doc, const char *qualifier, SpecReviewClock clock,
    void *clock_context) {
  SpecReviewAnnotations r;
  r.doc = doc;
  r.qualifier = qualifier;
  r.clock = clock;
  r.clock_context = clock_context;
  return r;
}

/* The change time a write records (SOM §11.9.10): `at` normalized, else the
 * clock's, else the system clock's. Owned; NULL (filling `*err`) when `at` is
 * not a time. */
static char *review_time(const SpecReviewAnnotations *r, const char *at,
                         SpecReviewAnnotationError *err) {
  if (at != NULL) return spec_review_normalize_time(at, err);
  if (r->clock != NULL) {
    char *t = r->clock(r->clock_context);
    if (t != NULL) return t;
  }
  return spec_review_system_time();
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
  SpecReviewAnnotationCounts c;
  memset(&c, 0, sizeof(c));
  SpecReviewAnnotationList l;
  spec_review_annotations_list(r, &l);
  for (size_t i = 0; i < l.len; i++) {
    switch (l.items[i].kind) {
      case SPEC_REVIEW_ANNOTATION_QUESTION:
        c.questions++;
        if (spec_review_annotation_is_open(&l.items[i])) c.open_questions++;
        if (spec_review_annotation_is_unresolved(&l.items[i])) {
          c.unresolved_questions++;
        }
        break;
      case SPEC_REVIEW_ANNOTATION_CONFLICT:
        c.conflicts++;
        if (spec_review_annotation_is_open(&l.items[i])) c.open_conflicts++;
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

char *spec_paragraph_to_json(const SpecParagraph *p) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_int(&b, &first, "index", (long long)p->index);
  put_int(&b, &first, "startLine", (long long)p->start_line);
  put_int(&b, &first, "endLine", (long long)p->end_line);
  put_str(&b, &first, "text", p->text);
  put_str(&b, &first, "annotation", p->annotation);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

void spec_paragraph_list_init(SpecParagraphList *l) {
  l->items = NULL;
  l->len = 0;
  l->cap = 0;
}

void spec_paragraph_list_free(SpecParagraphList *l) {
  for (size_t i = 0; i < l->len; i++) free(l->items[i].text);
  free(l->items);
  spec_paragraph_list_init(l);
}

int spec_review_annotations_paragraphs(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       SpecParagraphList *out,
                                       SpecReviewAnnotationError *err) {
  spec_paragraph_list_init(out);
  const char *value = field == NULL
                          ? spec_document_content(r->doc, path)
                          : spec_document_form_field(r->doc, path, field);
  if (value == NULL) {
    if (field == NULL) {
      set_error(err, "no value at %s", path);
    } else {
      set_error(err, "no value at %s / %s", path, field);
    }
    return 0;
  }
  Parsed p;
  parse(value, &p);
  size_t *starts = NULL, *ends = NULL;
  size_t n = paragraph_bounds(&p.lines, p.code, &starts, &ends);
  for (size_t i = 0; i < n; i++) {
    SpecParagraph para;
    para.index = i;
    para.start_line = starts[i];
    para.end_line = ends[i];
    SomBuf t;
    som_buf_init(&t);
    for (size_t k = starts[i]; k <= ends[i]; k++) {
      if (k > starts[i]) som_buf_putc(&t, '\n');
      som_buf_puts(&t, LINE(&p, k));
    }
    para.text = som_buf_take(&t);
    para.annotation = NULL;
    for (size_t bi = 0; bi < p.blocks_len; bi++) {
      if (p.blocks[bi].start == starts[i]) {
        para.annotation = spec_review_annotation_kind_name(p.blocks[bi].kind);
        break;
      }
    }
    PUSH(out->items, out->len, out->cap, para);
  }
  free(starts);
  free(ends);
  parsed_free(&p);
  return 1;
}

char *spec_review_annotations_insert_comment(const SpecReviewAnnotations *r,
                                             const char *path,
                                             const char *field,
                                             long long after_paragraph,
                                             const char *text,
                                             const char *author,
                                             const char *id, const char *at,
                                             SpecReviewAnnotationError *err) {
  char *time = review_time(r, at, err);
  if (time == NULL) return NULL;
  char *cid = id != NULL ? som_strdup(id)
                         : spec_review_annotations_next_comment_id(r, 0);
  char *value = som_strdup(get_value(r->doc, path, field));
  long long end;
  if (!paragraph_last_line(value, after_paragraph, &end, err)) {
    free(value);
    free(cid);
    free(time);
    return NULL;
  }
  SomStrList block;
  spec_format_comment_block(cid, text, author, time, &block);
  char *updated = insert_after_line(value, end, &block);
  set_value(r->doc, path, field, updated);
  free(updated);
  som_strlist_free(&block);
  free(value);
  free(time);
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

/* ---- team reviews (SOM §11.9.8): individual answers, applying conflicts -- */

/* Whether an answer carries anything beyond an option letter (SOM §11.9.8):
 * `(a)` or `**(a)**`, optionally followed by exactly that option's text, is
 * not; an answer that starts with no letter is. */
static int is_commented_answer(const char *answer, const Question *q) {
  char *letter = leading_letter(answer);
  if (letter == NULL) return 1;
  const char *t = trim_left(answer);
  size_t tl = strlen(t);
  int bold = starts_with(t, "**(") && tl >= 7 && strncmp(t + 4, ")**", 3) == 0;
  size_t skip = bold ? 7 : starts_with(t, "**") ? 5 : 3;
  char *rest = trim_dup(skip < tl ? t + skip : "");
  int commented = 0;
  if (rest[0] != '\0') {
    commented = 1;
    for (size_t i = 0; i < q->options_len; i++) {
      if (strcmp(q->options[i].letter, letter) == 0) {
        commented = strcmp(rest, q->options[i].text) != 0;
        break;
      }
    }
  }
  free(rest);
  free(letter);
  return commented;
}

/* Pushes the lines of one individual-answer entry onto `out`. */
static void push_individual_answer_lines(SomStrList *out,
                                         const SomStrList *members,
                                         const char *answer,
                                         const char *changed_at) {
  SomStrList a;
  split_lines(answer, &a);
  SomStrList who;
  som_strlist_copy(&who, members);
  if (changed_at != NULL) som_strlist_push_copy(&who, changed_at);
  char *names = som_strlist_join(&who, ", ");
  som_strlist_free(&who);
  char *head = fmt("> **Answer (%s):** %s", names, a.items[0]);
  som_strlist_push(out, trim_right_dup(head));
  free(head);
  free(names);
  push_quoted(out, &a, 1);
  som_strlist_free(&a);
}

/* One entry of the individual-answer run being rewritten. */
typedef struct {
  SomStrList members;
  char *answer;           /* borrowed */
  const char *changed_at; /* borrowed; NULL without a change time */
  int rewrite; /* 0: keep the entry's lines `[line, end]` of the value */
  size_t line, end;
} AnswerEntry;

/* `value` with member `member`'s individual answer to question `q` set to
 * `answer` (SOM §11.9.8): the member leaves the line it was on (a line left
 * empty goes); a non-empty answer that is not commented joins the line whose
 * answer is identical and not commented, at its end, and otherwise gets a new
 * line after the last individual answer. The first individual answer opens the
 * run before the team's `**Answer:**`, with a `>` line between run and team
 * answer, and a run left empty takes that line with it. Entries left alone
 * keep their bytes. Owned. */
static char *set_individual_answer(const char *value, const Question *q,
                                   const char *member, const char *answer,
                                   const char *changed_at) {
  SomStrList lines;
  split_lines(value, &lines);
  AnswerEntry *kept = malloc((q->answers_len + 1) * sizeof(AnswerEntry));
  size_t kept_len = 0;
  for (size_t i = 0; i < q->answers_len; i++) {
    AnswerEntry e;
    som_strlist_copy(&e.members, &q->answers[i].members);
    e.answer = q->answers[i].answer;
    e.changed_at = q->answers[i].changed_at;
    e.rewrite = 0;
    e.line = q->answers[i].line;
    e.end = q->answers[i].end;
    for (size_t m = 0; m < e.members.len; m++) {
      if (strcmp(e.members.items[m], member) == 0) {
        som_strlist_remove_at(&e.members, m);
        e.rewrite = 1;
        break;
      }
    }
    if (e.members.len > 0) {
      kept[kept_len++] = e;
    } else {
      som_strlist_free(&e.members);
    }
  }
  char *text = trim_dup(answer);
  if (text[0] != '\0') {
    AnswerEntry *join = NULL;
    if (!is_commented_answer(text, q)) {
      for (size_t i = 0; i < kept_len && join == NULL; i++) {
        int same_time =
            kept[i].changed_at == NULL
                ? changed_at == NULL
                : changed_at != NULL &&
                      strcmp(kept[i].changed_at, changed_at) == 0;
        if (strcmp(kept[i].answer, text) == 0 && same_time &&
            !is_commented_answer(kept[i].answer, q)) {
          join = &kept[i];
        }
      }
    }
    if (join != NULL) {
      som_strlist_push_copy(&join->members, member);
      join->rewrite = 1;
    } else {
      AnswerEntry e;
      som_strlist_init(&e.members);
      som_strlist_push_copy(&e.members, member);
      e.answer = text;
      e.changed_at = changed_at;
      e.rewrite = 1;
      e.line = e.end = 0;
      kept[kept_len++] = e;
    }
  }
  SomStrList run;
  som_strlist_init(&run);
  for (size_t i = 0; i < kept_len; i++) {
    if (kept[i].rewrite) {
      push_individual_answer_lines(&run, &kept[i].members, kept[i].answer,
                                   kept[i].changed_at);
    } else {
      for (size_t k = kept[i].line; k <= kept[i].end; k++) {
        som_strlist_push_copy(&run, lines.items[k]);
      }
    }
    som_strlist_free(&kept[i].members);
  }
  free(kept);
  if (q->answers_len > 0) {
    size_t from = q->answers[0].line;
    size_t to = q->answers[q->answers_len - 1].end;
    /* A run left empty takes its separating `>` line with it. */
    if (run.len == 0 && to + 1 < lines.len &&
        is_blank(inner_of(lines.items[to + 1]))) {
      to++;
    }
    replace_range(&lines, from, to, &run);
  } else if (run.len > 0) {
    SomStrList with;
    som_strlist_init(&with);
    size_t at;
    if (q->answer_line >= 0) {
      at = (size_t)q->answer_line;
      for (size_t k = 0; k < run.len; k++)
        som_strlist_push_copy(&with, run.items[k]);
      som_strlist_push_copy(&with, ">");
    } else {
      size_t last = q->region_end;
      while (last > q->header && is_blank(inner_of(lines.items[last]))) last--;
      at = last + 1;
      som_strlist_push_copy(&with, ">");
      for (size_t k = 0; k < run.len; k++)
        som_strlist_push_copy(&with, run.items[k]);
    }
    /* Insert at `at`: replace the empty range [at, at - 1]. */
    SomStrList out;
    som_strlist_init(&out);
    for (size_t k = 0; k < at; k++) som_strlist_push_copy(&out, lines.items[k]);
    for (size_t k = 0; k < with.len; k++)
      som_strlist_push_copy(&out, with.items[k]);
    for (size_t k = at; k < lines.len; k++)
      som_strlist_push_copy(&out, lines.items[k]);
    som_strlist_free(&lines);
    lines = out;
    som_strlist_free(&with);
  }
  free(text);
  som_strlist_free(&run);
  char *joined = som_strlist_join(&lines, "\n");
  som_strlist_free(&lines);
  return joined;
}

int spec_review_annotations_set_member_answer(const SpecReviewAnnotations *r,
                                              const char *question_id,
                                              const char *author,
                                              const char *answer,
                                              const char *at,
                                              SpecReviewAnnotationError *err) {
  if (!spec_review_is_member_id(author)) {
    set_error(err,
              "\"%s\" is not a member id (lowercase letters, digits and _)",
              author ? author : "");
    return 0;
  }
  Found f;
  if (!find_question(r, question_id, &f, err)) return 0;
  char *time = NULL;
  if (!is_blank(answer)) {
    time = review_time(r, at, err);
    if (time == NULL) {
      found_free(&f);
      return 0;
    }
  }
  char *updated = set_individual_answer(
      f.value.text, &f.parsed.questions[f.index], author, answer, time);
  set_value(r->doc, f.value.path, f.value.field, updated);
  free(updated);
  free(time);
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
                                         const char *text, const char *at,
                                         SpecReviewAnnotationError *err) {
  char *time = review_time(r, at, err);
  if (time == NULL) return 0;
  Found f;
  if (!find_comment(r, comment_id, &f, err)) {
    free(time);
    return 0;
  }
  const Comment *c = &f.parsed.comments[f.index];
  const Block *b = &f.parsed.blocks[f.block];
  SomStrList lines;
  split_lines(f.value.text, &lines);
  SomStrList t;
  split_lines(text, &t);
  SomStrList block;
  som_strlist_init(&block);
  /* The header rebuilt: the author stays, the time moves (SOM §11.9.10). */
  char *before = trim_right_dup(c->before_author);
  char *who = author_and_time(c->author, time);
  char *head = fmt("%s (%s): %s", before, who, t.items[0]);
  som_strlist_push(&block, trim_right_dup(head));
  free(head);
  free(who);
  free(before);
  free(time);
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
  char *updated = decide_mark(value, &p, (size_t)index, accept);
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
      if (b->kind == SPEC_REVIEW_ANNOTATION_CONFLICT) {
        const char *cid = p.conflicts[b->conflict].id;
        if (cid != NULL) som_strlist_push_copy(&ids, cid);
        continue;
      }
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
  som_strlist_free(&e->authors);
  votes_free(e->votes, e->votes_len);
  if (e->quoted_change != NULL) {
    free(e->quoted_change->old_text);
    free(e->quoted_change->new_text);
    free(e->quoted_change->outcome);
    free(e->quoted_change);
  }
  free(e->comment_id);
  free(e->change_id);
  free(e->changed_at);
  memset(e, 0, sizeof(*e));
}

static char *mark_entry_json(const SpecMarkEntry *e, int team) {
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
  if (e->quoted_change != NULL) {
    const SpecQuotedChange *q = e->quoted_change;
    put_key(&b, &first, "quotedChange");
    int qfirst = 1;
    som_buf_putc(&b, '{');
    put_str(&b, &qfirst, "kind", spec_mark_kind_name(q->kind));
    put_str(&b, &qfirst, "oldText", q->old_text);
    put_str(&b, &qfirst, "newText", q->new_text);
    put_str(&b, &qfirst, "outcome", q->outcome);
    som_buf_putc(&b, '}');
  }
  if (e->comment_id != NULL) put_str(&b, &first, "commentId", e->comment_id);
  if (e->change_id != NULL) put_str(&b, &first, "changeId", e->change_id);
  if (e->changed_at != NULL) put_str(&b, &first, "changedAt", e->changed_at);
  if (team) {
    put_str_list(&b, &first, "authors", &e->authors);
    put_votes(&b, &first, "votes", e->votes, e->votes_len);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_mark_entry_to_json(const SpecMarkEntry *e) {
  return mark_entry_json(e, 0);
}

char *spec_mark_entry_to_team_json(const SpecMarkEntry *e) {
  return mark_entry_json(e, 1);
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
  for (size_t i = 0; i < r->conflicts_len; i++) {
    SpecConflictOutcome *c = &r->conflicts[i];
    free(c->id);
    free(c->path);
    free(c->field);
    free(c->decision);
    free(c->result);
  }
  free(r->conflicts);
  spec_mark_report_init(r);
}

static char *mark_report_json(const SpecMarkReport *r, int team) {
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
  som_buf_putc(&b, ']');
  if (team && r->has_conflicts) {
    som_buf_puts(&b, ",\"conflicts\":[");
    for (size_t i = 0; i < r->conflicts_len; i++) {
      const SpecConflictOutcome *c = &r->conflicts[i];
      if (i > 0) som_buf_putc(&b, ',');
      int first = 1;
      som_buf_putc(&b, '{');
      put_str(&b, &first, "id", c->id);
      put_str(&b, &first, "path", c->path);
      put_str(&b, &first, "field", c->field);
      put_int(&b, &first, "line", (long long)c->line);
      put_str(&b, &first, "decision", c->decision);
      put_str(&b, &first, "result", c->result);
      som_buf_putc(&b, '}');
    }
    som_buf_putc(&b, ']');
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_mark_report_to_json(const SpecMarkReport *r) {
  return mark_report_json(r, 0);
}

char *spec_mark_report_to_team_json(const SpecMarkReport *r) {
  return mark_report_json(r, 1);
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
    size_t first = n + 1;
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
      e.comment = dup_or_null(m->has_quote ? m->q_comment : m->comment);
      e.markup = som_strdup_n(v->text + m->start, m->end - m->start);
      e.context = join_from(LINE(&p, from), (const char *const *)p.lines.items,
                            (long long)from + 1, (long long)to);
      som_strlist_copy(&e.authors, &m->authors);
      e.votes = votes_copy(m->votes, m->votes_len);
      e.votes_len = m->votes_len;
      e.quoted_change = NULL;
      if (m->has_quote) {
        e.quoted_change = malloc(sizeof(SpecQuotedChange));
        e.quoted_change->kind = m->q_kind;
        e.quoted_change->old_text = som_strdup(m->q_old);
        e.quoted_change->new_text = som_strdup(m->q_new);
        e.quoted_change->outcome = dup_or_null(m->q_outcome);
      }
      e.comment_id = m->comment_index < 0
                         ? NULL
                         : fmt("M-%zu", first + (size_t)m->comment_index);
      e.change_id = m->change_index < 0
                        ? NULL
                        : fmt("M-%zu", first + (size_t)m->change_index);
      e.changed_at = dup_or_null(m->changed_at);
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
  /* With `all`: change comments are left (accept all / reject all). */
  int skip_quoted;
} Decider;

/* The decision for mark `id` (`m`); 0 when none. A later item overrides. */
static int decide(const Decider *d, const char *id, const Mark *m,
                  SpecMarkDecision *out) {
  if (d->items == NULL) {
    if (d->skip_quoted && m->has_quote) return 0;
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
    /* -1: not decided (none, or leave); else the decision. */
    int *decided = malloc((p.marks_len ? p.marks_len : 1) * sizeof(int));
    for (size_t k = 0; k < p.marks_len; k++) {
      char *id = fmt("M-%zu", first_id + k);
      SpecMarkDecision dec;
      decided[k] = decide(d, id, &p.marks[k], &dec) &&
                           dec != SPEC_MARK_DECISION_LEAVE
                       ? (int)dec
                       : -1;
      free(id);
    }
    for (size_t k = p.marks_len; k-- > 0;) {
      if (decided[k] < 0) continue;
      SpecMarkDecision dec = (SpecMarkDecision)decided[k];
      char *id = fmt("M-%zu", first_id + k);
      const Mark *m = &p.marks[k];
      const char *repl = mark_replacement(m, dec == SPEC_MARK_DECISION_ACCEPT);
      if (m->comment_index >= 0 && decided[m->comment_index] < 0) {
        char *next = record_outcome(text, &p.marks[m->comment_index],
                                    dec == SPEC_MARK_DECISION_ACCEPT);
        free(text);
        text = next;
      }
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
      char *next =
          replace_mark(text, m, repl, dec == SPEC_MARK_DECISION_ACCEPT);
      free(text);
      text = next;
    }
    free(decided);
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
               SPEC_MARK_DECISION_LEAVE, 0};
  apply_marks(r, &d, NULL, out);
  return 1;
}

void spec_review_annotations_accept_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out) {
  Decider d = {NULL, 0, SPEC_MARK_DECISION_ACCEPT, 1};
  apply_marks(r, &d, path, out);
}

void spec_review_annotations_reject_all_marks(const SpecReviewAnnotations *r,
                                              const char *path,
                                              SpecMarkReport *out) {
  Decider d = {NULL, 0, SPEC_MARK_DECISION_REJECT, 1};
  apply_marks(r, &d, path, out);
}

/* The mark `M-<n>` `mark_id`: its value (taken into `*value`) and parse, and
 * its index there. 0 with `*err` filled when the document is no longer at
 * `revision` (when non-NULL) or holds no such mark. */
static int find_mark(const SpecReviewAnnotations *r, const char *mark_id,
                     const char *revision, Value *value, Parsed *parsed,
                     size_t *index, SpecReviewAnnotationError *err) {
  if (revision != NULL) {
    char *current = spec_review_annotations_revision(r);
    if (strcmp(revision, current) != 0) {
      set_error(err,
                "the document changed since revision %s (now %s); list the "
                "marks again",
                revision, current);
      free(current);
      return 0;
    }
    free(current);
  }
  size_t n = 0;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    Parsed p;
    parse(vals.items[i].text, &p);
    for (size_t k = 0; k < p.marks_len; k++) {
      char *id = fmt("M-%zu", ++n);
      int hit = strcmp(id, mark_id) == 0;
      free(id);
      if (!hit) continue;
      take_value(&vals, i, value);
      *parsed = p;
      *index = k;
      values_free(&vals);
      return 1;
    }
    parsed_free(&p);
  }
  values_free(&vals);
  set_error(err, "no inline mark %s in the document", mark_id);
  return 0;
}

char *spec_review_annotations_comment_change(const SpecReviewAnnotations *r,
                                             const char *mark_id,
                                             const char *text,
                                             const char *author,
                                             const char *revision,
                                             const char *at,
                                             SpecReviewAnnotationError *err) {
  char *time = review_time(r, at, err);
  if (time == NULL) return NULL;
  Value v;
  Parsed p;
  size_t k;
  if (!find_mark(r, mark_id, revision, &v, &p, &k, err)) {
    free(time);
    return NULL;
  }
  const Mark *m = &p.marks[k];
  char *result = NULL;
  char *comment = NULL;
  char *body = NULL;
  if (!is_change_mark(m->kind)) {
    set_error(err, "%s is a %s mark, not a change", mark_id,
              spec_mark_kind_name(m->kind));
    goto done;
  }
  if (m->comment_index >= 0) {
    set_error(err, "%s already has a comment; edit it instead", mark_id);
    goto done;
  }
  comment = check_inline_comment(text, err);
  if (comment == NULL) goto done;
  if (author != NULL && !spec_review_is_member_id(author)) {
    set_error(err, "\"%s\" is not a member id", author);
    goto done;
  }
  const char *d = m->kind == SPEC_MARK_INSERTION  ? "++"
                  : m->kind == SPEC_MARK_DELETION ? "--"
                                                  : "~~";
  body = m->kind == SPEC_MARK_SUBSTITUTION
             ? fmt("%s ~> %s", m->text, m->new_text)
             : som_strdup(m->text);
  char *dclose = fmt("%s]", d);
  int unfit = strstr(body, dclose) != NULL || strstr(body, "<<}") != NULL;
  free(dclose);
  if (unfit) {
    set_error(err, "%s holds \"%s]\" or \"<<}\", which its quote cannot hold",
              mark_id, d);
    goto done;
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, v.text, m->end);
  som_buf_puts(&b, "{>> [");
  som_buf_puts(&b, d);
  som_buf_putc(&b, ' ');
  som_buf_puts(&b, body);
  som_buf_putc(&b, ' ');
  som_buf_puts(&b, d);
  som_buf_puts(&b, "] ");
  som_buf_puts(&b, comment);
  som_buf_puts(&b, " <<}");
  {
    SomStrList who;
    som_strlist_init(&who);
    if (author != NULL) som_strlist_push_copy(&who, author);
    char *token = spec_review_format_attribution_token(&who, NULL, 0, time);
    som_buf_puts(&b, token);
    free(token);
    som_strlist_free(&who);
  }
  som_buf_puts(&b, v.text + m->end);
  char *updated = som_buf_take(&b);
  set_value(r->doc, v.path, v.field, updated);
  free(updated);
  result = fmt("M-%lld", strtoll(mark_id + 2, NULL, 10) + 1);
done:
  free(time);
  free(body);
  free(comment);
  parsed_free(&p);
  free(v.path);
  free(v.field);
  free(v.text);
  return result;
}

int spec_review_annotations_edit_mark_comment(const SpecReviewAnnotations *r,
                                              const char *mark_id,
                                              const char *text,
                                              const char *revision,
                                              const char *at,
                                              SpecReviewAnnotationError *err) {
  char *time = review_time(r, at, err);
  if (time == NULL) return 0;
  Value v;
  Parsed p;
  size_t k;
  if (!find_mark(r, mark_id, revision, &v, &p, &k, err)) {
    free(time);
    return 0;
  }
  const Mark *m = &p.marks[k];
  int ok = 0;
  char *comment = check_inline_comment(text, err);
  if (comment != NULL) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_putn(&b, v.text, m->start);
    if (m->kind == SPEC_MARK_COMMENT) {
      som_buf_puts(&b, "{>> ");
      if (m->has_quote) {
        /* The quote as written, from its `[` to its `]`. */
        size_t open = m->start + 3;
        while (open < m->q_end && is_anchor_space(v.text[open])) open++;
        som_buf_putn(&b, v.text + open, m->q_end - open);
        som_buf_putc(&b, ' ');
      }
      ok = 1;
    } else if (m->kind == SPEC_MARK_HIGHLIGHT && m->comment != NULL) {
      som_buf_puts(&b, "{== ");
      som_buf_puts(&b, m->text);
      som_buf_puts(&b, " ==}{>> ");
      ok = 1;
    }
    if (ok) {
      som_buf_puts(&b, comment);
      som_buf_puts(&b, " <<}");
      /* The token keeps its authors and votes and records the time (SOM
       * §11.9.10). */
      char *token = spec_review_format_attribution_token(
          &m->authors, m->votes, m->votes_len, time);
      som_buf_puts(&b, token);
      free(token);
      som_buf_puts(&b, v.text + m->end);
      char *updated = som_buf_take(&b);
      set_value(r->doc, v.path, v.field, updated);
      free(updated);
    } else {
      som_buf_free(&b);
      set_error(err, "%s holds no comment", mark_id);
    }
  }
  free(comment);
  free(time);
  parsed_free(&p);
  free(v.path);
  free(v.field);
  free(v.text);
  return ok;
}

/* Whether a conflict's topic names a structural conflict the merge writes
 * (SOM §11.9.9): its decision is not a text. */
static int is_structural_topic(const char *topic) {
  return strcmp(topic, "Item removed") == 0 ||
         strcmp(topic, "Item moved") == 0 ||
         strcmp(topic, "Headline changed") == 0;
}

/* The text a conflict's decision chooses: the base, an alternative, or the
 * rewritten text. Borrowed from `c`. */
static const char *chosen_text(const Conflict *c) {
  char *letter = decision_letter_of(c->decision);
  const char *out = c->decision;
  if (letter != NULL && strcmp(letter, "base") == 0) {
    out = c->base ? c->base : "";
  } else if (letter != NULL) {
    for (size_t i = 0; i < c->alternatives_len; i++) {
      if (strcmp(c->alternatives[i].letter, letter) == 0) {
        out = c->alternatives[i].text;
        break;
      }
    }
  }
  free(letter);
  return out;
}

/* Whether a paragraph starting at `start` opens an annotation block. */
static int opens_block(const Parsed *p, size_t start) {
  for (size_t i = 0; i < p->blocks_len; i++) {
    if (p->blocks[i].start == start) return 1;
  }
  return 0;
}

/* `value` with the lines `[s, e]` replaced by `text`. Owned. */
static char *replace_lines(const char *value, size_t s, size_t e,
                           const char *text) {
  SomStrList lines, t;
  split_lines(value, &lines);
  split_lines(text, &t);
  replace_range(&lines, s, e, &t);
  char *out = som_strlist_join(&lines, "\n");
  som_strlist_free(&t);
  som_strlist_free(&lines);
  return out;
}

/* `value` with `text` inserted before value line `block_start`, one blank
 * line on each side. Owned. */
static char *insert_before_block(const char *value, size_t block_start,
                                 const char *text) {
  SomStrList t;
  split_lines(text, &t);
  char *out = insert_after_line(value, (long long)block_start - 1, &t);
  som_strlist_free(&t);
  return out;
}

/* `value` with the text paragraph directly before the block at `block_start`
 * (annotation blocks between them skipped) replaced by `text`; with none,
 * `text` goes before the block. Owned. */
static char *replace_paragraph_before(const char *value, size_t block_start,
                                      const char *text) {
  Parsed p;
  parse(value, &p);
  size_t *starts = NULL, *ends = NULL;
  size_t n = paragraph_bounds(&p.lines, p.code, &starts, &ends);
  long long last = -1;
  for (size_t i = 0; i < n; i++) {
    if (ends[i] < block_start && !opens_block(&p, starts[i]))
      last = (long long)i;
  }
  char *out = last < 0 ? insert_before_block(value, block_start, text)
                       : replace_lines(value, starts[last], ends[last], text);
  free(starts);
  free(ends);
  parsed_free(&p);
  return out;
}

/* `value` with the run of text paragraphs directly before the block at
 * `block_start` — a whole-value unit (SOM §11.9.9) — replaced by `text`.
 * Owned. */
static char *replace_text_run(const char *value, size_t block_start,
                              const char *text) {
  Parsed p;
  parse(value, &p);
  size_t *starts = NULL, *ends = NULL;
  size_t n = paragraph_bounds(&p.lines, p.code, &starts, &ends);
  size_t before = 0;
  while (before < n && ends[before] < block_start) before++;
  size_t k = before;
  while (k > 0 && !opens_block(&p, starts[k - 1])) k--;
  char *out = k == before
                  ? insert_before_block(value, block_start, text)
                  : replace_lines(value, starts[k], ends[before - 1], text);
  free(starts);
  free(ends);
  parsed_free(&p);
  return out;
}

/* Whether `s` is two runs of non-whitespace separated by one space,
 * `<path> <field>`; the runs into `*a` and `*b` (owned) when it is. */
static int split_path_field(const char *s, char **a, char **b) {
  SomStrList words;
  split_words(s, strlen(s), &words);
  int ok = words.len == 2;
  if (ok) {
    char *joined = fmt("%s %s", words.items[0], words.items[1]);
    ok = strcmp(joined, s) == 0;
    free(joined);
  }
  if (ok) {
    *a = som_strdup(words.items[0]);
    *b = som_strdup(words.items[1]);
  }
  som_strlist_free(&words);
  return ok;
}

/* Whether `s` reads as a document path: no whitespace, no comma, and a `/`
 * with text on both sides. */
static int looks_like_path(const char *s) {
  if (strchr(s, ',') != NULL || s[0] == '\0') return 0;
  SomStrList words;
  split_words(s, strlen(s), &words);
  int one = words.len == 1 && strcmp(words.items[0], s) == 0;
  som_strlist_free(&words);
  if (!one) return 0;
  const char *slash = strchr(s + 1, '/');
  return slash != NULL && slash[1] != '\0';
}

/* A decided conflict, as `remove_all_annotations` found it before any
 * change. `path` and `field` are borrowed from the values list it was read
 * from; `decision` is owned. */
typedef struct {
  const char *path;
  const char *field; /* NULL for content */
  size_t index; /* the block's position among the value's conflict blocks */
  size_t line;
  char *decision;
} DecidedConflict;

static void decided_free(DecidedConflict *d, size_t len) {
  for (size_t i = 0; i < len; i++) free(d[i].decision);
  free(d);
}

/* Whether a decided conflict lies in the value at `path` / `field`. */
static int decided_in(const DecidedConflict *d, const char *path,
                      const char *field) {
  return strcmp(d->path, path) == 0 &&
         (d->field == NULL ? field == NULL
                           : field != NULL && strcmp(d->field, field) == 0);
}

/* Collects every conflict block of `vals` with the line it opens on, in
 * document order; 0 (filling `*err`) when one of them cannot be applied. */
static int decided_conflicts(const Values *vals, DecidedConflict **out,
                             size_t *out_len, SpecReviewAnnotationError *err) {
  size_t len = 0, cap = 0;
  DecidedConflict *items = NULL;
  int ok = 1;
  for (size_t i = 0; ok && i < vals->len; i++) {
    const Value *v = &vals->items[i];
    Parsed p;
    parse(v->text, &p);
    size_t index = 0;
    for (size_t bi = 0; ok && bi < p.blocks_len; bi++) {
      const Block *b = &p.blocks[bi];
      if (b->kind != SPEC_REVIEW_ANNOTATION_CONFLICT) continue;
      const Conflict *c = &p.conflicts[b->conflict];
      char *where = v->field == NULL
                        ? fmt("%s, line %zu", v->path, b->start)
                        : fmt("%s / %s, line %zu", v->path, v->field, b->start);
      char *letter = decision_letter_of(c->decision);
      if (c->id == NULL || c->base == NULL || c->alternatives_len == 0) {
        set_error(err, "%s: a malformed conflict block cannot be applied",
                  where);
        ok = 0;
      } else if (c->decision[0] == '\0' || is_unresolved_answer(c->decision)) {
        set_error(err,
                  "%s: conflict %s is %s; decide it before removing the "
                  "annotations",
                  where, c->id, c->decision[0] == '\0' ? "open" : "unresolved");
        ok = 0;
      } else if (letter != NULL && strcmp(letter, "base") != 0) {
        int known = 0;
        for (size_t a = 0; a < c->alternatives_len; a++) {
          known = known || strcmp(c->alternatives[a].letter, letter) == 0;
        }
        if (!known) {
          set_error(err, "%s: conflict %s has no alternative (%s)", where,
                    c->id, letter);
          ok = 0;
        }
      }
      free(letter);
      free(where);
      if (ok) {
        DecidedConflict d = {v->path, v->field, index++, b->start,
                             som_strdup(c->decision)};
        PUSH(items, len, cap, d);
      }
    }
    parsed_free(&p);
  }
  if (!ok) {
    decided_free(items, len);
    items = NULL;
    len = 0;
  }
  *out = items;
  *out_len = len;
  return ok;
}

/* Applies the decided conflicts of value `v` (marks already accepted) to its
 * text, from the last block up so earlier line numbers stay valid, and
 * records each in `out`. Where the chosen text goes follows the conflict's
 * text (SOM §11.9.8, "Applying"): a form field, another value, this value's
 * text paragraphs, or — the default — the text paragraph directly before the
 * block. Owned result. */
static char *apply_conflicts(const SpecReviewAnnotations *r, const Value *v,
                             const DecidedConflict *decided, size_t decided_len,
                             SpecMarkReport *out) {
  char *text = som_strdup(v->text);
  Parsed p;
  parse(v->text, &p);
  size_t first = out->conflicts_len;
  for (size_t k = p.conflicts_len; k-- > 0;) {
    const DecidedConflict *d = NULL;
    for (size_t i = 0; i < decided_len; i++) {
      if (decided_in(&decided[i], v->path, v->field) && decided[i].index == k) {
        d = &decided[i];
      }
    }
    const Conflict *c = &p.conflicts[k];
    const char *result = chosen_text(c);
    SpecConflictOutcome o;
    o.id = som_strdup(c->id);
    o.path = som_strdup(v->path);
    o.field = dup_or_null(v->field);
    o.line = d->line;
    o.decision = som_strdup(d->decision);
    o.result = som_strdup(result);
    PUSH(out->conflicts, out->conflicts_len, out->conflicts_cap, o);
    if (is_structural_topic(c->topic)) continue;
    size_t block_start = p.blocks[c->block].start;
    char *tp = NULL, *tf = NULL;
    char *next = NULL;
    if (split_path_field(c->text, &tp, &tf) &&
        spec_document_form_field(r->doc, tp, tf) != NULL) {
      spec_document_set_form_field(r->doc, tp, tf, result);
    } else if (v->field == NULL && strcmp(c->text, v->path) == 0) {
      next = replace_text_run(text, block_start, result);
    } else if (looks_like_path(c->text) && strcmp(c->text, v->path) != 0) {
      spec_document_set_content(r->doc, c->text, result);
    } else {
      next = replace_paragraph_before(text, block_start, result);
    }
    free(tp);
    free(tf);
    if (next != NULL) {
      free(text);
      text = next;
    }
  }
  /* Recorded last to first: restore block order. */
  for (size_t a = first, b = out->conflicts_len; a + 1 < b; a++, b--) {
    SpecConflictOutcome t = out->conflicts[a];
    out->conflicts[a] = out->conflicts[b - 1];
    out->conflicts[b - 1] = t;
  }
  parsed_free(&p);
  return text;
}

int spec_review_annotations_remove_all_annotations(
    const SpecReviewAnnotations *r, SpecMarkReport *out,
    SpecReviewAnnotationError *err) {
  spec_mark_report_init(out);
  Values before;
  values_of(r->doc, &before);
  DecidedConflict *decided = NULL;
  size_t decided_len = 0;
  if (!decided_conflicts(&before, &decided, &decided_len, err)) {
    values_free(&before);
    return 0;
  }
  /* Every mark accepted, change comments included (which go). */
  Decider all = {NULL, 0, SPEC_MARK_DECISION_ACCEPT, 0};
  apply_marks(r, &all, NULL, out);
  out->has_conflicts = 1;
  Values vals;
  values_of(r->doc, &vals);
  for (size_t i = 0; i < vals.len; i++) {
    const Value *v = &vals.items[i];
    char *t;
    int here = 0;
    for (size_t d = 0; d < decided_len; d++) {
      here = here || decided_in(&decided[d], v->path, v->field);
    }
    t = here ? apply_conflicts(r, v, decided, decided_len, out)
             : som_strdup(v->text);
    for (;;) {
      Parsed p;
      parse(t, &p);
      if (p.blocks_len == 0) {
        parsed_free(&p);
        break;
      }
      const Block *b = &p.blocks[p.blocks_len - 1];
      char *next = remove_lines(t, b->start, b->end);
      parsed_free(&p);
      free(t);
      t = next;
    }
    if (strcmp(t, v->text) != 0) set_value(r->doc, v->path, v->field, t);
    free(t);
  }
  values_free(&vals);
  decided_free(decided, decided_len);
  values_free(&before);
  return 1;
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

/* The change time of a marked write, once `author` is checked; NULL
 * (filling `*err`) when either is refused. Owned. */
static char *marked_write_time(const SpecReviewAnnotations *r,
                               const char *author, const char *at,
                               SpecReviewAnnotationError *err) {
  if (author != NULL && !spec_review_is_member_id(author)) {
    set_error(err,
              "\"%s\" is not a member id (lowercase letters, digits and _)",
              author);
    return NULL;
  }
  return review_time(r, at, err);
}

/* Writes `result` at `path` / `field` with its change marks stamped against
 * `current`, the value before (SOM §11.9.10), into `*out`. */
static void write_stamped(const SpecReviewAnnotations *r, const char *path,
                          const char *field, const char *current,
                          SpecMarkedChange result, const char *author,
                          const char *time, SpecMarkedChange *out) {
  out->text = stamp_marks(current, result.text, author, time);
  out->exact = result.exact;
  spec_marked_change_free(&result);
  set_value(r->doc, path, field, out->text);
}

int spec_review_annotations_set_marked(const SpecReviewAnnotations *r,
                                       const char *path, const char *field,
                                       const char *text, const char *author,
                                       const char *at, SpecMarkedChange *out,
                                       SpecReviewAnnotationError *err) {
  out->text = NULL;
  out->exact = 0;
  char *time = marked_write_time(r, author, at, err);
  if (time == NULL) return 0;
  char *current = som_strdup(get_value(r->doc, path, field));
  write_stamped(r, path, field, current,
                mark_keeping_change_comments(current, text), author, time,
                out);
  free(current);
  free(time);
  return 1;
}

int spec_review_annotations_mark_against(const SpecReviewAnnotations *r,
                                         const char *path, const char *field,
                                         const char *earlier,
                                         const char *author, const char *at,
                                         SpecMarkedChange *out,
                                         SpecReviewAnnotationError *err) {
  out->text = NULL;
  out->exact = 0;
  char *time = marked_write_time(r, author, at, err);
  if (time == NULL) return 0;
  char *current = som_strdup(get_value(r->doc, path, field));
  write_stamped(r, path, field, current,
                spec_mark_change_text(earlier, current), author, time, out);
  free(current);
  free(time);
  return 1;
}

/* ---- text-level building blocks of the merge (SOM §11.9.9) --------------- */

void spec_review_pieces(const char *value, SpecReviewPieces *out) {
  memset(out, 0, sizeof(*out));
  if (value[0] == '\0') return;
  Parsed p;
  parse(value, &p);
  size_t *starts = NULL, *ends = NULL;
  size_t n = paragraph_bounds(&p.lines, p.code, &starts, &ends);
  for (size_t i = 0; i < n; i++) {
    SpecReviewPiece piece;
    memset(&piece, 0, sizeof(piece));
    piece.is_text = 1;
    som_strlist_init(&piece.question_ids);
    piece.text =
        join_from(LINE(&p, starts[i]), (const char *const *)p.lines.items,
                  (long long)starts[i] + 1, (long long)ends[i]);
    for (size_t bi = 0; bi < p.blocks_len; bi++) {
      const Block *b = &p.blocks[bi];
      if (b->start != starts[i]) continue;
      piece.is_text = 0;
      piece.kind = b->kind;
      if (b->kind == SPEC_REVIEW_ANNOTATION_COMMENT) {
        const Comment *c = &p.comments[b->comment];
        piece.id = dup_or_null(c->id);
        piece.author = dup_or_null(c->author);
        piece.comment_text = som_strdup(c->text);
        piece.changed_at = dup_or_null(c->changed_at);
      } else if (b->kind == SPEC_REVIEW_ANNOTATION_CONFLICT) {
        piece.id = dup_or_null(p.conflicts[b->conflict].id);
      } else {
        for (size_t qi = 0; qi < b->q_len; qi++) {
          som_strlist_push_copy(&piece.question_ids,
                                p.questions[b->q_first + qi].id);
        }
      }
      break;
    }
    if (piece.comment_text == NULL) piece.comment_text = som_strdup("");
    PUSH(out->items, out->len, out->cap, piece);
  }
  free(starts);
  free(ends);
  parsed_free(&p);
}

void spec_review_pieces_free(SpecReviewPieces *ps) {
  for (size_t i = 0; i < ps->len; i++) {
    SpecReviewPiece *p = &ps->items[i];
    free(p->text);
    free(p->id);
    free(p->author);
    free(p->comment_text);
    som_strlist_free(&p->question_ids);
    free(p->changed_at);
  }
  free(ps->items);
  memset(ps, 0, sizeof(*ps));
}

void spec_review_marks(const char *value, SpecReviewMarks *out) {
  memset(out, 0, sizeof(*out));
  Parsed p;
  parse(value, &p);
  for (size_t k = 0; k < p.marks_len; k++) {
    const Mark *m = &p.marks[k];
    SpecReviewMark rm;
    rm.start = m->start;
    rm.end = m->end;
    rm.body_end = m->body_end;
    rm.kind = m->kind;
    rm.markup = som_strdup_n(value + m->start, m->end - m->start);
    som_strlist_copy(&rm.authors, &m->authors);
    rm.votes = votes_copy(m->votes, m->votes_len);
    rm.votes_len = m->votes_len;
    rm.accepted = som_strdup(mark_replacement(m, 1));
    rm.rejected = som_strdup(mark_replacement(m, 0));
    rm.changed_at = dup_or_null(m->changed_at);
    PUSH(out->items, out->len, out->cap, rm);
  }
  parsed_free(&p);
}

void spec_review_marks_free(SpecReviewMarks *ms) {
  for (size_t i = 0; i < ms->len; i++) {
    SpecReviewMark *m = &ms->items[i];
    free(m->markup);
    som_strlist_free(&m->authors);
    votes_free(m->votes, m->votes_len);
    free(m->accepted);
    free(m->rejected);
    free(m->changed_at);
  }
  free(ms->items);
  memset(ms, 0, sizeof(*ms));
}

char *spec_review_decide_marks_text(const char *value, const int *decisions,
                                    size_t len) {
  Parsed p;
  parse(value, &p);
  char *v = som_strdup(value);
  for (size_t k = p.marks_len; k-- > 0;) {
    if (k >= len || decisions[k] < 0) continue;
    char *next = replace_mark(v, &p.marks[k],
                              mark_replacement(&p.marks[k], decisions[k]),
                              decisions[k] != 0);
    free(v);
    v = next;
  }
  parsed_free(&p);
  return v;
}

char *spec_review_with_attribution(const char *value, const SpecReviewMark *m,
                                   const SomStrList *authors,
                                   const SpecMarkVote *votes,
                                   size_t votes_len) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, value, m->body_end);
  char *token = spec_review_format_attribution_token(authors, votes, votes_len,
                                                     m->changed_at);
  som_buf_puts(&b, token);
  free(token);
  som_buf_puts(&b, value + m->end);
  return som_buf_take(&b);
}

void spec_review_team_answers(const char *value, SomStrList *ids,
                              SomStrList *answers) {
  som_strlist_init(ids);
  som_strlist_init(answers);
  Parsed p;
  parse(value, &p);
  for (size_t i = 0; i < p.questions_len; i++) {
    if (som_strlist_contains(ids, p.questions[i].id)) continue;
    som_strlist_push_copy(ids, p.questions[i].id);
    som_strlist_push_copy(answers, p.questions[i].answer);
  }
  parsed_free(&p);
}

char *spec_review_set_individual_answer_text(const char *value,
                                             const char *question_id,
                                             const char *member,
                                             const char *answer,
                                             const char *changed_at) {
  Parsed p;
  parse(value, &p);
  char *out = NULL;
  for (size_t i = 0; i < p.questions_len && out == NULL; i++) {
    if (strcmp(p.questions[i].id, question_id) == 0) {
      out = set_individual_answer(value, &p.questions[i], member, answer,
                                  changed_at);
    }
  }
  parsed_free(&p);
  return out;
}

/* Pushes the lines of a conflict's text: the first after its prefix, the rest
 * indented under it. */
static void push_alternative_lines(SomStrList *out, const char *prefix,
                                   const char *text) {
  SomStrList t;
  split_lines(text, &t);
  char *head = fmt("> - %s %s", prefix, t.items[0]);
  som_strlist_push(out, trim_right_dup(head));
  free(head);
  for (size_t k = 1; k < t.len; k++)
    som_strlist_push(out, fmt(">   %s", t.items[k]));
  som_strlist_free(&t);
}

void spec_review_format_conflict_block(
    const char *id, const char *topic, const char *text, const char *base,
    const SpecConflictAlternative *alternatives, size_t alternatives_len,
    SomStrList *out) {
  som_strlist_init(out);
  char *head = fmt("> " SCALES VS16 " **%s" EM_SEP "%s:** %s", id, topic, text);
  som_strlist_push(out, trim_right_dup(head));
  free(head);
  push_alternative_lines(out, "(base)", base);
  for (size_t i = 0; i < alternatives_len; i++) {
    char *names = som_strlist_join(&alternatives[i].members, ", ");
    char *prefix = fmt("(%s) **%s:**", alternatives[i].letter, names);
    push_alternative_lines(out, prefix, alternatives[i].text);
    free(prefix);
    free(names);
  }
  som_strlist_push_copy(out, ">");
  som_strlist_push_copy(out, "> " DECISION_LABEL);
}

/* The b-token range `[*from, *to)` an x-token range `[x0, x1)` lands on; 0
 * when it is not one.
 *
 * A replaced range lands where its tokens are in b, which must be contiguous
 * there; its neighbours are not consulted, because the token diff may align a
 * neighbouring space with another space of b (beside a decided mark) without
 * the range touching that mark. A pure insertion (`x0 == x1`) has no tokens of
 * its own, so both neighbours must sit next to each other in b. */
static int landing(const long long *to_b, size_t n, size_t x0, size_t x1,
                   size_t b_len, size_t *from, size_t *to) {
  for (size_t k = x0; k < x1; k++) {
    if (to_b[k] < 0 || (k > x0 && to_b[k] != to_b[k - 1] + 1)) return 0;
  }
  if (x1 > x0) {
    *from = (size_t)to_b[x0];
    *to = (size_t)to_b[x1 - 1] + 1;
    return 1;
  }
  long long left = x0 == 0 ? -1 : to_b[x0 - 1];
  long long right = x1 == n ? (long long)b_len : to_b[x1];
  if ((x0 > 0 && left < 0) || (x1 < n && right < 0)) return 0;
  if (right != left + 1) return 0;
  *from = *to = (size_t)(left + 1);
  return 1;
}

/* One edit x → y: x tokens `[x0, x1)` replaced by `inserted` (owned). */
typedef struct {
  size_t x0, x1;
  SomBuf inserted;
} Hunk;

char *spec_review_transplant_edits(const char *x, const char *y,
                                   const char *b) {
  Toks xt, bt, yt;
  tokens_of(x, &xt);
  tokens_of(b, &bt);
  tokens_of(y, &yt);
  /* Where each token of x is in b (-1: x and b differ there). */
  long long *to_b = malloc((xt.len ? xt.len : 1) * sizeof(long long));
  for (size_t k = 0; k < xt.len; k++) to_b[k] = -1;
  DiffOps ops;
  diff_toks(&xt, &bt, &ops);
  size_t i = 0;
  long long j = 0;
  for (size_t k = 0; k < ops.len; k++) {
    if (ops.items[k].kind == 0) {
      to_b[i++] = j++;
    } else if (ops.items[k].kind == 1) {
      i++;
    } else {
      j++;
    }
  }
  free(ops.items);
  /* The edits x → y. */
  Hunk *hunks = NULL;
  size_t hunks_len = 0, hunks_cap = 0;
  int open = 0;
  Hunk cur;
  diff_toks(&xt, &yt, &ops);
  i = 0;
  for (size_t k = 0; k < ops.len; k++) {
    if (ops.items[k].kind == 0) {
      if (open) PUSH(hunks, hunks_len, hunks_cap, cur);
      open = 0;
      i++;
      continue;
    }
    if (!open) {
      cur.x0 = cur.x1 = i;
      som_buf_init(&cur.inserted);
      open = 1;
    }
    if (ops.items[k].kind == 1) {
      cur.x1 = ++i;
    } else {
      som_buf_putn(&cur.inserted, ops.items[k].tok->text,
                   ops.items[k].tok->len);
    }
  }
  if (open) PUSH(hunks, hunks_len, hunks_cap, cur);
  free(ops.items);
  /* The output as b's token texts, each edit replacing the tokens it lands
   * on: `gone[k]` drops token k, `before[k]` is inserted in front of it
   * (index n: at the end). The edits never overlap, so this is the same as
   * splicing them in from the last one up. */
  size_t n = bt.len;
  char **before = calloc(n + 1, sizeof(char *));
  unsigned char *gone = calloc(n + 1, 1);
  int ok = 1;
  for (size_t h = hunks_len; ok && h-- > 0;) {
    size_t from, to;
    if (!landing(to_b, xt.len, hunks[h].x0, hunks[h].x1, n, &from, &to)) {
      ok = 0;
      break;
    }
    const char *ins = hunks[h].inserted.data ? hunks[h].inserted.data : "";
    /* Splice: the landed tokens go, `ins` takes their place. */
    for (size_t k = from; k < to; k++) gone[k] = 1;
    char *prev = before[from];
    before[from] = fmt("%s%s", ins, prev ? prev : "");
    free(prev);
  }
  char *result = NULL;
  if (ok) {
    SomBuf out;
    som_buf_init(&out);
    for (size_t k = 0; k <= n; k++) {
      if (before[k]) som_buf_puts(&out, before[k]);
      if (k < n && !gone[k])
        som_buf_putn(&out, bt.items[k].text, bt.items[k].len);
    }
    result = out.data ? som_buf_take(&out) : som_strdup("");
    som_buf_free(&out);
  }
  for (size_t k = 0; k <= n; k++) free(before[k]);
  free(before);
  free(gone);
  for (size_t h = 0; h < hunks_len; h++) som_buf_free(&hunks[h].inserted);
  free(hunks);
  free(to_b);
  toks_free(&xt);
  toks_free(&bt);
  toks_free(&yt);
  return result;
}
