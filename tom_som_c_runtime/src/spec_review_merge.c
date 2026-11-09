/* spec_review_merge — merging reviewed copies (SOM §11.9.9), a port of the
 * TypeScript `spec_review_merge.ts`. See the header for the contract.
 *
 * Every helper here returns owned results and frees what it allocates; the
 * text of a value is never held across a write to the document it came
 * from. */
#include "spec_review_merge.h"

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "spec_document_markdown.h"
#include "spec_paths.h"
#include "spec_reflection.h"
#include "spec_section_id.h"

#define PUSH(arr, len, cap, val)                      \
  do {                                                \
    if ((len) == (cap)) {                             \
      (cap) = (cap) ? (cap) * 2 : 4;                  \
      (arr) = realloc((arr), (cap) * sizeof(*(arr))); \
    }                                                 \
    (arr)[(len)++] = (val);                           \
  } while (0)

/* Ids the merge writes before it can number them: `\x01<kind><n>\x01`,
 * renumbered in merged document order at the end. */
#define PLACEHOLDER_MARK '\x01'
/* Separates the parts of a SOM value key; never part of a path. */
#define KEY_SEP '\x1f'
/* The most base marks a unit may have that a copy no longer holds as written:
 * the combinations of step 2 grow as 2^n. Beyond it the copy's unit is read as
 * an edit (step 4), so every runtime gives up at the same point. */
#define MAX_DECIDED_MARKS 16

/* ---- small helpers --------------------------------------------------------
 */

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

static char *dup_or_null(const char *s) { return s ? som_strdup(s) : NULL; }

static int starts_with(const char *s, const char *p) {
  return strncmp(s, p, strlen(p)) == 0;
}

/* Whether `path` is `item` or lies under it. */
static int under(const char *path, const char *item) {
  size_t n = strlen(item);
  return strncmp(path, item, n) == 0 && (path[n] == '\0' || path[n] == '/');
}

static int is_space_byte(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' ||
         c == '\f';
}

/* `s` trimmed of ASCII whitespace. Owned. */
static char *trim_text(const char *s) {
  size_t a = 0, b = strlen(s);
  while (a < b && is_space_byte(s[a])) a++;
  while (b > a && is_space_byte(s[b - 1])) b--;
  return som_strdup_n(s + a, b - a);
}

static int is_blank_text(const char *s) {
  for (; *s; s++) {
    if (!is_space_byte(*s)) return 0;
  }
  return 1;
}

/* `s` split on `sep` into `out` (initialised here; "" is one empty piece). */
static void split_on(const char *s, char sep, SomStrList *out) {
  som_strlist_init(out);
  const char *from = s;
  for (;;) {
    const char *at = strchr(from, sep);
    if (at == NULL) {
      som_strlist_push_copy(out, from);
      return;
    }
    som_strlist_push(out, som_strdup_n(from, (size_t)(at - from)));
    from = at + 1;
  }
}

/* `l[from, to)` joined with `sep`. Owned. */
static char *join_range(const SomStrList *l, const char *sep, size_t from,
                        size_t to) {
  SomBuf b;
  som_buf_init(&b);
  if (to > l->len) to = l->len;
  for (size_t k = from; k < to; k++) {
    if (k > from) som_buf_puts(&b, sep);
    som_buf_puts(&b, l->items[k]);
  }
  return som_buf_take(&b);
}

static long long index_of(const SomStrList *l, const char *s) {
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i], s) == 0) return (long long)i;
  }
  return -1;
}

static void push_json_str(SomBuf *b, const char *s) {
  if (s == NULL) {
    som_buf_puts(b, "null");
    return;
  }
  char *e = som_json_encode_str(s);
  som_buf_puts(b, e);
  free(e);
}

static void push_json_list(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    push_json_str(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

static void votes_free(SpecMarkVote *v, size_t len) {
  for (size_t i = 0; i < len; i++) free(v[i].member);
  free(v);
}

/* ---- errors and the report ------------------------------------------------
 */

void spec_review_merge_error_init(SpecReviewMergeError *err) {
  err->message = NULL;
}

void spec_review_merge_error_free(SpecReviewMergeError *err) {
  free(err->message);
  err->message = NULL;
}

static void set_error(SpecReviewMergeError *err, char *owned) {
  if (err == NULL) {
    free(owned);
    return;
  }
  free(err->message);
  err->message = owned;
}

void spec_review_merge_report_init(SpecReviewMergeReport *r) {
  memset(r, 0, sizeof(*r));
}

static void merge_conflict_free(SpecMergeConflict *c) {
  free(c->id);
  free(c->path);
  free(c->field);
  som_strlist_free(&c->members);
}

static void merge_comment_free(SpecMergeComment *c) {
  free(c->id);
  free(c->author);
  free(c->path);
  free(c->field);
}

void spec_review_merge_report_free(SpecReviewMergeReport *r) {
  for (size_t i = 0; i < r->reviewers_len; i++) {
    free(r->reviewers[i].member_id);
    free(r->reviewers[i].display_name);
    free(r->reviewers[i].role);
  }
  free(r->reviewers);
  for (size_t i = 0; i < r->conflicts_len; i++)
    merge_conflict_free(&r->conflicts[i]);
  free(r->conflicts);
  for (size_t i = 0; i < r->votes_len; i++) {
    free(r->votes[i].path);
    free(r->votes[i].field);
    free(r->votes[i].markup);
    votes_free(r->votes[i].votes, r->votes[i].votes_len);
  }
  free(r->votes);
  for (size_t i = 0; i < r->unanimous_len; i++) {
    free(r->unanimous[i].path);
    free(r->unanimous[i].field);
    free(r->unanimous[i].markup);
    free(r->unanimous[i].result);
  }
  free(r->unanimous);
  for (size_t i = 0; i < r->answers_len; i++) {
    free(r->answers[i].question_id);
    som_strlist_free(&r->answers[i].members);
  }
  free(r->answers);
  for (size_t i = 0; i < r->comments_len; i++)
    merge_comment_free(&r->comments[i]);
  free(r->comments);
  for (size_t i = 0; i < r->additions_len; i++) {
    free(r->additions[i].path);
    som_strlist_free(&r->additions[i].members);
  }
  free(r->additions);
  for (size_t i = 0; i < r->guest_questions_len; i++) {
    free(r->guest_questions[i].id);
    free(r->guest_questions[i].member_id);
    free(r->guest_questions[i].path);
  }
  free(r->guest_questions);
  free(r->revision_path);
  free(r->revision_version);
  spec_review_merge_report_init(r);
}

char *spec_review_merge_report_to_json(const SpecReviewMergeReport *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"reviewers\":[");
  for (size_t i = 0; i < r->reviewers_len; i++) {
    const SpecMergeReviewer *x = &r->reviewers[i];
    som_buf_puts(&b, i ? ",{\"memberId\":" : "{\"memberId\":");
    push_json_str(&b, x->member_id);
    som_buf_puts(&b, ",\"displayName\":");
    push_json_str(&b, x->display_name);
    som_buf_puts(&b, ",\"role\":");
    push_json_str(&b, x->role);
    som_buf_puts(&b, x->guest ? ",\"guest\":true}" : ",\"guest\":false}");
  }
  som_buf_puts(&b, "],\"conflicts\":[");
  for (size_t i = 0; i < r->conflicts_len; i++) {
    const SpecMergeConflict *x = &r->conflicts[i];
    som_buf_puts(&b, i ? ",{\"id\":" : "{\"id\":");
    push_json_str(&b, x->id);
    som_buf_puts(&b, ",\"path\":");
    push_json_str(&b, x->path);
    som_buf_puts(&b, ",\"field\":");
    push_json_str(&b, x->field);
    som_buf_puts(&b, ",\"paragraph\":");
    if (x->paragraph < 0) {
      som_buf_puts(&b, "null");
    } else {
      som_buf_puti(&b, x->paragraph);
    }
    som_buf_puts(&b, ",\"members\":");
    push_json_list(&b, &x->members);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"votes\":[");
  for (size_t i = 0; i < r->votes_len; i++) {
    const SpecMergeVotes *x = &r->votes[i];
    som_buf_puts(&b, i ? ",{\"path\":" : "{\"path\":");
    push_json_str(&b, x->path);
    som_buf_puts(&b, ",\"field\":");
    push_json_str(&b, x->field);
    som_buf_puts(&b, ",\"markup\":");
    push_json_str(&b, x->markup);
    som_buf_puts(&b, ",\"votes\":[");
    for (size_t k = 0; k < x->votes_len; k++) {
      som_buf_puts(&b, k ? ",{\"member\":" : "{\"member\":");
      push_json_str(&b, x->votes[k].member);
      som_buf_puts(&b, x->votes[k].accept ? ",\"vote\":\"accept\"}"
                                          : ",\"vote\":\"reject\"}");
    }
    som_buf_puts(&b, "]}");
  }
  som_buf_puts(&b, "],\"unanimous\":[");
  for (size_t i = 0; i < r->unanimous_len; i++) {
    const SpecMergeUnanimous *x = &r->unanimous[i];
    som_buf_puts(&b, i ? ",{\"path\":" : "{\"path\":");
    push_json_str(&b, x->path);
    som_buf_puts(&b, ",\"field\":");
    push_json_str(&b, x->field);
    som_buf_puts(&b, ",\"markup\":");
    push_json_str(&b, x->markup);
    som_buf_puts(&b, x->accept ? ",\"decision\":\"accept\""
                               : ",\"decision\":\"reject\"");
    som_buf_puts(&b, ",\"result\":");
    push_json_str(&b, x->result);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"answers\":[");
  for (size_t i = 0; i < r->answers_len; i++) {
    som_buf_puts(&b, i ? ",{\"questionId\":" : "{\"questionId\":");
    push_json_str(&b, r->answers[i].question_id);
    som_buf_puts(&b, ",\"members\":");
    push_json_list(&b, &r->answers[i].members);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"comments\":[");
  for (size_t i = 0; i < r->comments_len; i++) {
    const SpecMergeComment *x = &r->comments[i];
    som_buf_puts(&b, i ? ",{\"id\":" : "{\"id\":");
    push_json_str(&b, x->id);
    som_buf_puts(&b, ",\"author\":");
    push_json_str(&b, x->author);
    som_buf_puts(&b, ",\"path\":");
    push_json_str(&b, x->path);
    som_buf_puts(&b, ",\"field\":");
    push_json_str(&b, x->field);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"additions\":[");
  for (size_t i = 0; i < r->additions_len; i++) {
    som_buf_puts(&b, i ? ",{\"path\":" : "{\"path\":");
    push_json_str(&b, r->additions[i].path);
    som_buf_puts(&b, ",\"members\":");
    push_json_list(&b, &r->additions[i].members);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"guestQuestions\":[");
  for (size_t i = 0; i < r->guest_questions_len; i++) {
    const SpecMergeGuestQuestion *x = &r->guest_questions[i];
    som_buf_puts(&b, i ? ",{\"id\":" : "{\"id\":");
    push_json_str(&b, x->id);
    som_buf_puts(&b, ",\"memberId\":");
    push_json_str(&b, x->member_id);
    som_buf_puts(&b, ",\"path\":");
    push_json_str(&b, x->path);
    som_buf_putc(&b, '}');
  }
  som_buf_puts(&b, "],\"revision\":");
  if (r->revision_path == NULL) {
    som_buf_puts(&b, "null");
  } else {
    som_buf_puts(&b, "{\"path\":");
    push_json_str(&b, r->revision_path);
    som_buf_puts(&b, ",\"version\":");
    push_json_str(&b, r->revision_version);
    som_buf_putc(&b, '}');
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the engine: one value at a time ------------------------------------- */

/* One value to merge, located in the merged document. Owned strings. */
typedef struct {
  char *path;
  char *field; /* NULL for content */
  char *base;
  /* Per copy, in round order; NULL when the copy holds no such value (it
   * removed the item). */
  char **copies;
  size_t copies_len;
  /* A typed leaf (number, bool, enum, code): never marked, any change is a
   * conflict. */
  int typed;
  /* Where a conflict about a form field or a typed leaf goes (a value key);
   * NULL for a content value. */
  char *conflict_home;
} MergeValue;

static void merge_value_free(MergeValue *v) {
  free(v->path);
  free(v->field);
  free(v->base);
  for (size_t i = 0; i < v->copies_len; i++) free(v->copies[i]);
  free(v->copies);
  free(v->conflict_home);
}

/* What one copy did to one unit (SOM §11.9.9, steps 1–4). */
typedef struct {
  int present; /* 0: the copy holds no such unit */
  int changed;
  char *t;       /* the reviewer's text */
  char *written; /* the change as it is written into the merged document */
  /* The copy's vote on each base mark: 1 accept, 0 reject, -1 none. */
  int *votes;
  size_t votes_len;
} UnitReading;

static void reading_free(UnitReading *r) {
  free(r->t);
  free(r->written);
  free(r->votes);
}

static size_t votes_cast(const UnitReading *r) {
  size_t n = 0;
  for (size_t i = 0; i < r->votes_len; i++) n += r->votes[i] >= 0;
  return n;
}

/* The changed readings grouped by their text, in order of first appearance.
 * `text` owned; `first` indexes the readings (SIZE_MAX for none). */
typedef struct {
  char *text;
  SomStrList members;
  size_t first;
} ChangeGroup;

typedef struct {
  ChangeGroup *items;
  size_t len, cap;
} ChangeGroups;

static void groups_free(ChangeGroups *g) {
  for (size_t i = 0; i < g->len; i++) {
    free(g->items[i].text);
    som_strlist_free(&g->items[i].members);
  }
  free(g->items);
  memset(g, 0, sizeof(*g));
}

/* Adds `member` to the group of `text`, opening it when it is new. */
static void groups_add(ChangeGroups *g, const char *text, const char *member,
                       size_t first) {
  for (size_t i = 0; i < g->len; i++) {
    if (strcmp(g->items[i].text, text) == 0) {
      som_strlist_push_copy(&g->items[i].members, member);
      return;
    }
  }
  ChangeGroup x;
  x.text = som_strdup(text);
  som_strlist_init(&x.members);
  som_strlist_push_copy(&x.members, member);
  x.first = first;
  PUSH(g->items, g->len, g->cap, x);
}

/* The state one merge carries from value to value. */
typedef struct {
  SpecReviewMergeReport *report;
  /* Blocks to append to the end of a value: `append_blocks[k]` for the value
   * keyed `append_keys.items[k]`. */
  SomStrList append_keys;
  SomStrList *append_blocks;
  size_t append_cap;
  const SpecReviewMember *copies;
  size_t members_len;
  size_t next_placeholder;
  /* Placeholder → report entry, filled in when the ids are numbered. */
  SpecMergeConflict *pending_conflicts;
  size_t pending_conflicts_len, pending_conflicts_cap;
  SpecMergeComment *pending_comments;
  size_t pending_comments_len, pending_comments_cap;
  SomStrList base_comment_ids;
  SomStrList base_question_ids;
} MergeContext;

static const char *member_at(const MergeContext *ctx, size_t i) {
  return ctx->copies[i].member_id;
}

static void ctx_free(MergeContext *ctx) {
  for (size_t i = 0; i < ctx->append_keys.len; i++) {
    som_strlist_free(&ctx->append_blocks[i]);
  }
  free(ctx->append_blocks);
  som_strlist_free(&ctx->append_keys);
  for (size_t i = 0; i < ctx->pending_conflicts_len; i++) {
    merge_conflict_free(&ctx->pending_conflicts[i]);
  }
  free(ctx->pending_conflicts);
  for (size_t i = 0; i < ctx->pending_comments_len; i++) {
    merge_comment_free(&ctx->pending_comments[i]);
  }
  free(ctx->pending_comments);
  som_strlist_free(&ctx->base_comment_ids);
  som_strlist_free(&ctx->base_question_ids);
}

static char *ctx_placeholder(MergeContext *ctx, char kind) {
  return fmt("%c%c%zu%c", PLACEHOLDER_MARK, kind, ++ctx->next_placeholder,
             PLACEHOLDER_MARK);
}

static void ctx_append(MergeContext *ctx, const char *key, const char *block) {
  long long at = index_of(&ctx->append_keys, key);
  if (at < 0) {
    if (ctx->append_keys.len == ctx->append_cap) {
      ctx->append_cap = ctx->append_cap ? ctx->append_cap * 2 : 4;
      ctx->append_blocks =
          realloc(ctx->append_blocks, ctx->append_cap * sizeof(SomStrList));
    }
    som_strlist_init(&ctx->append_blocks[ctx->append_keys.len]);
    at = (long long)ctx->append_keys.len;
    som_strlist_push_copy(&ctx->append_keys, key);
  }
  som_strlist_push_copy(&ctx->append_blocks[at], block);
}

/* Writes a conflict block with a placeholder id, records it for the report and
 * returns the block (owned). */
static char *ctx_conflict(MergeContext *ctx, const char *topic,
                          const char *text, const char *base,
                          const ChangeGroups *groups, const char *path,
                          const char *field, long long paragraph) {
  char *id = ctx_placeholder(ctx, 'X');
  SpecMergeConflict entry;
  entry.id = som_strdup(id);
  entry.path = som_strdup(path);
  entry.field = dup_or_null(field);
  entry.paragraph = paragraph;
  som_strlist_init(&entry.members);
  SpecConflictAlternative *alts =
      malloc((groups->len ? groups->len : 1) * sizeof(*alts));
  char letters[27][2];
  for (size_t k = 0; k < groups->len; k++) {
    for (size_t m = 0; m < groups->items[k].members.len; m++) {
      som_strlist_push_copy(&entry.members, groups->items[k].members.items[m]);
    }
    letters[k % 26][0] = (char)('a' + (k % 26));
    letters[k % 26][1] = '\0';
    alts[k].letter = letters[k % 26];
    alts[k].members = groups->items[k].members;
    alts[k].text = groups->items[k].text;
  }
  PUSH(ctx->pending_conflicts, ctx->pending_conflicts_len,
       ctx->pending_conflicts_cap, entry);
  SomStrList lines;
  spec_review_format_conflict_block(id, topic, text, base, alts, groups->len,
                                    &lines);
  free(alts);
  free(id);
  char *block = som_strlist_join(&lines, "\n");
  som_strlist_free(&lines);
  return block;
}

static void groups_of(const UnitReading *readings, size_t n,
                      const MergeContext *ctx, ChangeGroups *out) {
  memset(out, 0, sizeof(*out));
  for (size_t k = 0; k < n; k++) {
    if (!readings[k].present || !readings[k].changed) continue;
    groups_add(out, readings[k].t, member_at(ctx, k), k);
  }
}

/* Aligns two mark lists by their markup (longest common subsequence): for
 * each mark of `a`, its index in `b`, SIZE_MAX for none. Owned. */
static size_t *align_marks(const SpecReviewMarks *a, const SpecReviewMarks *b) {
  size_t n = a->len, m = b->len, w = m + 1;
  size_t *l = calloc((n + 1) * w, sizeof(size_t));
  for (size_t i = n; i-- > 0;) {
    for (size_t j = m; j-- > 0;) {
      size_t down = l[(i + 1) * w + j], right = l[i * w + j + 1];
      l[i * w + j] = strcmp(a->items[i].markup, b->items[j].markup) == 0
                         ? l[(i + 1) * w + j + 1] + 1
                         : (down >= right ? down : right);
    }
  }
  size_t *out = malloc((n ? n : 1) * sizeof(size_t));
  for (size_t i = 0; i < n; i++) out[i] = SIZE_MAX;
  size_t i = 0, j = 0;
  while (i < n && j < m) {
    if (strcmp(a->items[i].markup, b->items[j].markup) == 0) {
      out[i++] = j++;
    } else if (l[(i + 1) * w + j] >= l[i * w + j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  free(l);
  return out;
}

/* The first combination of decisions on `b`'s `count` marks (step 2) whose
 * result is `target`, as a decision array (1 accept, 0 reject, -1 left; owned),
 * or NULL. Each mark takes leave, accept, reject in that order, the first mark
 * varying slowest. A mark the copy still holds as written (`left[i]`) can only
 * have been left, and a mark it no longer holds cannot have been, so only the
 * others vary — the same first combination, found without trying the rest. */
static int *find_votes(const char *b, size_t count, const unsigned char *left,
                       const char *target) {
  size_t *free_marks = malloc((count ? count : 1) * sizeof(size_t));
  size_t nf = 0;
  for (size_t i = 0; i < count; i++) {
    if (!left[i]) free_marks[nf++] = i;
  }
  int *decisions = NULL;
  if (nf <= MAX_DECIDED_MARKS) {
    decisions = malloc((count ? count : 1) * sizeof(int));
    int found = 0;
    for (unsigned long combo = 0; !found && combo < (1UL << nf); combo++) {
      for (size_t i = 0; i < count; i++) decisions[i] = -1;
      for (size_t k = 0; k < nf; k++) {
        /* Bit set: reject; the first mark is the most significant bit. */
        decisions[free_marks[k]] = ((combo >> (nf - 1 - k)) & 1UL) == 0;
      }
      char *result = spec_review_decide_marks_text(b, decisions, count);
      found = strcmp(result, target) == 0;
      free(result);
    }
    if (!found) {
      free(decisions);
      decisions = NULL;
    }
  }
  free(free_marks);
  return decisions;
}

/* Step 4: the copy edited text that holds base marks; it casts no votes. */
static UnitReading read_as_edit(const char *b, const char *c) {
  UnitReading r;
  memset(&r, 0, sizeof(r));
  r.present = 1;
  r.t = spec_apply_inline_marks_text(c, 1);
  r.changed = strcmp(r.t, b) != 0;
  char *base = spec_apply_inline_marks_text(b, 0);
  SpecMarkedChange mc = spec_mark_change_text(base, r.t);
  r.written = mc.text;
  free(base);
  return r;
}

static UnitReading unchanged_reading(const char *b, int *votes, size_t len) {
  UnitReading r;
  r.present = 1;
  r.changed = 0;
  r.t = som_strdup(b);
  r.written = som_strdup(b);
  r.votes = votes;
  r.votes_len = len;
  return r;
}

/* What copy unit `c` did to base unit `b` (SOM §11.9.9, steps 1–4). */
static UnitReading read_unit(const char *b, const char *c) {
  if (strcmp(c, b) == 0) return unchanged_reading(b, NULL, 0);
  SpecReviewMarks base_marks, copy_marks;
  spec_review_marks(b, &base_marks);
  spec_review_marks(c, &copy_marks);
  size_t *kept = align_marks(&copy_marks, &base_marks);
  /* 1. Own marks: the copy's marks that are not the base's. */
  size_t nc = copy_marks.len, nb = base_marks.len;
  int *reject = malloc((nc ? nc : 1) * sizeof(int));
  int *accept = malloc((nc ? nc : 1) * sizeof(int));
  unsigned char *left = calloc(nb ? nb : 1, 1);
  size_t own = 0;
  for (size_t i = 0; i < nc; i++) {
    int is_own = kept[i] == SIZE_MAX;
    reject[i] = is_own ? 0 : -1;
    accept[i] = is_own ? 1 : -1;
    own += is_own;
    if (!is_own) left[kept[i]] = 1;
  }
  /* 2. Votes: the decisions on the base marks that give c with its own marks
   * rejected. */
  char *c_prime = spec_review_decide_marks_text(c, reject, nc);
  int *votes = find_votes(b, nb, left, c_prime);
  UnitReading r;
  if (votes == NULL) {
    r = read_as_edit(b, c);
  } else if (own == 0) {
    r = unchanged_reading(b, votes, nb);
    votes = NULL;
  } else {
    /* 3. Change: the own marks, carried over to the base text where marks
     * were voted on. */
    char *own_accepted = spec_review_decide_marks_text(c, accept, nc);
    UnitReading tmp = unchanged_reading(b, votes, nb);
    votes = NULL;
    int any = votes_cast(&tmp) > 0;
    char *written =
        any ? spec_review_transplant_edits(c_prime, c, b) : som_strdup(c);
    char *t = any ? spec_review_transplant_edits(c_prime, own_accepted, b)
                  : som_strdup(own_accepted);
    if (written == NULL || t == NULL) {
      reading_free(&tmp);
      r = read_as_edit(b, c);
    } else {
      free(tmp.t);
      free(tmp.written);
      r = tmp;
      r.changed = strcmp(t, b) != 0;
      r.t = t;
      r.written = written;
      t = written = NULL;
    }
    free(written);
    free(t);
    free(own_accepted);
  }
  free(votes);
  free(c_prime);
  free(left);
  free(accept);
  free(reject);
  free(kept);
  spec_review_marks_free(&copy_marks);
  spec_review_marks_free(&base_marks);
  return r;
}

/* `written` with every mark that is not one of the base's attributed to
 * `members`. Owned. */
static char *attribute(const char *written, const SpecReviewMarks *base_marks,
                       const SomStrList *members) {
  SpecReviewMarks marks;
  spec_review_marks(written, &marks);
  size_t *base = align_marks(&marks, base_marks);
  char *out = som_strdup(written);
  for (size_t k = marks.len; k-- > 0;) {
    if (base[k] != SIZE_MAX) continue;
    char *next = spec_review_with_attribution(out, &marks.items[k], members,
                                              marks.items[k].votes,
                                              marks.items[k].votes_len);
    free(out);
    out = next;
  }
  free(base);
  spec_review_marks_free(&marks);
  return out;
}

static int is_change(SpecMarkKind k) {
  return k == SPEC_MARK_INSERTION || k == SPEC_MARK_DELETION ||
         k == SPEC_MARK_SUBSTITUTION;
}

/* `text` with the copies' votes on the base marks it holds: a base mark every
 * copy decided the same way is applied (accept) or dropped (reject); any other
 * voted change mark gets the votes in its token, `agent` as author when it had
 * no token. A highlight or comment mark takes no votes and stays. Owned. */
static char *apply_votes(const char *text, const SpecReviewMarks *base_marks,
                         const UnitReading *readings, size_t n,
                         const MergeValue *v, MergeContext *ctx) {
  SpecReviewMarks marks;
  spec_review_marks(text, &marks);
  size_t *base = align_marks(&marks, base_marks);
  size_t taking = 0;
  for (size_t i = 0; i < n; i++) taking += readings[i].present;
  SpecReviewMergeReport *rep = ctx->report;
  size_t votes_at = rep->votes_len, unanimous_at = rep->unanimous_len;
  char *out = som_strdup(text);
  for (size_t k = marks.len; k-- > 0;) {
    size_t b = base[k];
    if (b == SIZE_MAX) continue;
    SpecMarkVote *cast = malloc((n ? n : 1) * sizeof(SpecMarkVote));
    size_t cast_len = 0;
    for (size_t i = 0; i < n; i++) {
      if (!readings[i].present || b >= readings[i].votes_len) continue;
      int d = readings[i].votes[b];
      if (d < 0) continue;
      cast[cast_len].member = som_strdup(member_at(ctx, i));
      cast[cast_len++].accept = d;
    }
    if (cast_len == 0) {
      free(cast);
      continue;
    }
    const SpecReviewMark *m = &marks.items[k];
    int same = 1;
    for (size_t i = 1; i < cast_len; i++)
      same = same && cast[i].accept == cast[0].accept;
    if (cast_len == taking && same) {
      int accept = cast[0].accept;
      int *decisions = malloc(marks.len * sizeof(int));
      for (size_t i = 0; i < marks.len; i++)
        decisions[i] = i == k ? accept : -1;
      char *next = spec_review_decide_marks_text(out, decisions, marks.len);
      free(decisions);
      free(out);
      out = next;
      const SpecReviewMark *bm = &base_marks->items[b];
      SpecMergeUnanimous u = {som_strdup(v->path), dup_or_null(v->field),
                              som_strdup(bm->markup), accept,
                              som_strdup(accept ? bm->accepted : bm->rejected)};
      PUSH(rep->unanimous, rep->unanimous_len, rep->unanimous_cap, u);
      votes_free(cast, cast_len);
      continue;
    }
    if (!is_change(m->kind)) {
      votes_free(cast, cast_len);
      continue;
    }
    SomStrList agent;
    som_strlist_init(&agent);
    som_strlist_push_copy(&agent, "agent");
    const SomStrList *authors = m->end > m->body_end ? &m->authors : &agent;
    SpecMarkVote *merged =
        malloc((m->votes_len + cast_len + 1) * sizeof(SpecMarkVote));
    size_t merged_len = 0;
    for (size_t i = 0; i < m->votes_len; i++) {
      int recast = 0;
      for (size_t j = 0; j < cast_len; j++) {
        recast = recast || strcmp(cast[j].member, m->votes[i].member) == 0;
      }
      if (recast) continue;
      merged[merged_len].member = som_strdup(m->votes[i].member);
      merged[merged_len++].accept = m->votes[i].accept;
    }
    for (size_t j = 0; j < cast_len; j++) merged[merged_len++] = cast[j];
    free(cast);
    char *next =
        spec_review_with_attribution(out, m, authors, merged, merged_len);
    free(out);
    out = next;
    som_strlist_free(&agent);
    SpecReviewMarks now;
    spec_review_marks(out, &now);
    SpecMergeVotes entry = {som_strdup(v->path), dup_or_null(v->field),
                            som_strdup(now.items[k].markup), merged,
                            merged_len};
    spec_review_marks_free(&now);
    PUSH(rep->votes, rep->votes_len, rep->votes_cap, entry);
  }
  /* Collected last to first: restore mark order. */
  for (size_t a = votes_at, z = rep->votes_len; a + 1 < z; a++, z--) {
    SpecMergeVotes t = rep->votes[a];
    rep->votes[a] = rep->votes[z - 1];
    rep->votes[z - 1] = t;
  }
  for (size_t a = unanimous_at, z = rep->unanimous_len; a + 1 < z; a++, z--) {
    SpecMergeUnanimous t = rep->unanimous[a];
    rep->unanimous[a] = rep->unanimous[z - 1];
    rep->unanimous[z - 1] = t;
  }
  free(base);
  spec_review_marks_free(&marks);
  return out;
}

static char *where_of(const MergeValue *v) {
  return v->field == NULL ? som_strdup(v->path)
                          : fmt("%s %s", v->path, v->field);
}

/* One unit merged: the base text with votes when no copy changed it, the one
 * change attributed to every member who made it, or the base text and a
 * conflict block (`*conflict`, owned; NULL for none) when the copies changed
 * it differently. Owned. */
static char *merge_unit(const char *b, char *const *units, size_t n,
                        long long paragraph, const MergeValue *v,
                        MergeContext *ctx, char **conflict) {
  UnitReading *readings = calloc(n ? n : 1, sizeof(UnitReading));
  for (size_t i = 0; i < n; i++) {
    if (units[i] != NULL) readings[i] = read_unit(b, units[i]);
  }
  ChangeGroups groups;
  groups_of(readings, n, ctx, &groups);
  SpecReviewMarks base_marks;
  spec_review_marks(b, &base_marks);
  char *text = groups.len == 1
                   ? attribute(readings[groups.items[0].first].written,
                               &base_marks, &groups.items[0].members)
                   : som_strdup(b);
  char *voted = apply_votes(text, &base_marks, readings, n, v, ctx);
  free(text);
  *conflict = NULL;
  if (groups.len >= 2) {
    char *where = where_of(v);
    char *topic_text = paragraph < 0
                           ? som_strdup(where)
                           : fmt("%s, paragraph %lld", where, paragraph);
    *conflict = ctx_conflict(ctx, "Conflicting changes", topic_text, b, &groups,
                             v->path, v->field, paragraph);
    free(topic_text);
    free(where);
  }
  spec_review_marks_free(&base_marks);
  groups_free(&groups);
  for (size_t i = 0; i < n; i++) reading_free(&readings[i]);
  free(readings);
  return voted;
}

/* A typed leaf: it cannot hold a mark, so a change by any copy is a `Value
 * changed` conflict at the leaf's home, the base value kept. Owned. */
static char *merge_typed(const MergeValue *v, MergeContext *ctx) {
  ChangeGroups groups;
  memset(&groups, 0, sizeof(groups));
  for (size_t i = 0; i < v->copies_len; i++) {
    const char *c = v->copies[i];
    if (c != NULL && strcmp(c, v->base) != 0)
      groups_add(&groups, c, member_at(ctx, i), i);
  }
  if (groups.len > 0 && v->conflict_home != NULL) {
    char *where = where_of(v);
    char *block = ctx_conflict(ctx, "Value changed", where, v->base, &groups,
                               v->path, v->field, -1);
    ctx_append(ctx, v->conflict_home, block);
    free(block);
    free(where);
  }
  groups_free(&groups);
  return som_strdup(v->base);
}

/* A form-field value: always one unit; its conflict goes to the end of the
 * form's preamble. Owned. */
static char *merge_field(const MergeValue *v, MergeContext *ctx) {
  char *conflict = NULL;
  char *text =
      merge_unit(v->base, v->copies, v->copies_len, -1, v, ctx, &conflict);
  if (conflict != NULL && v->conflict_home != NULL) {
    ctx_append(ctx, v->conflict_home, conflict);
  }
  free(conflict);
  return text;
}

/* Whether a copy's block is new: a comment whose id the base lacks, a question
 * block with no base question. */
static int is_new_block(const SpecReviewPiece *p, const MergeContext *ctx) {
  if (p->kind == SPEC_REVIEW_ANNOTATION_COMMENT) {
    return p->id == NULL ||
           !som_strlist_contains(&ctx->base_comment_ids, p->id);
  }
  if (p->kind == SPEC_REVIEW_ANNOTATION_QUESTION) {
    if (p->question_ids.len == 0) return 0;
    for (size_t i = 0; i < p->question_ids.len; i++) {
      if (som_strlist_contains(&ctx->base_question_ids,
                               p->question_ids.items[i])) {
        return 0;
      }
    }
    return 1;
  }
  return 0;
}

/* The anchor of block `k` of a value: the index of the text paragraph it
 * follows (-1: before every one). In whole-value mode every block that follows
 * text follows the one unit. */
static long long anchor_of(const SpecReviewPieces *ps, size_t k, int whole) {
  long long texts = -1;
  for (size_t i = 0; i < k; i++) texts += ps->items[i].is_text;
  if (ps->items[k].is_text) return texts + 1;
  return whole && texts > 0 ? 0 : texts;
}

/* The text paragraphs of `ps` into `out` (initialised here). */
static void texts_of(const SpecReviewPieces *ps, SomStrList *out) {
  som_strlist_init(out);
  for (size_t i = 0; i < ps->len; i++) {
    if (ps->items[i].is_text) som_strlist_push_copy(out, ps->items[i].text);
  }
}

/* The units of `ps` into `out`: its text paragraphs, or in whole-value mode
 * their one join. */
static void units_of(const SpecReviewPieces *ps, int whole, SomStrList *out) {
  texts_of(ps, out);
  if (!whole) return;
  char *joined = som_strlist_join(out, "\n\n");
  som_strlist_free(out);
  som_strlist_init(out);
  som_strlist_push(out, joined);
}

/* A copy's new block as merged: a comment renumbered and attributed, a
 * question as written. Owned. */
static char *new_block(const SpecReviewPiece *p, const char *member,
                       const MergeValue *v, MergeContext *ctx) {
  if (p->kind != SPEC_REVIEW_ANNOTATION_COMMENT) return som_strdup(p->text);
  char *id = ctx_placeholder(ctx, 'C');
  const char *author = p->author != NULL ? p->author : member;
  SpecMergeComment entry = {som_strdup(id), som_strdup(author),
                            som_strdup(v->path), dup_or_null(v->field)};
  PUSH(ctx->pending_comments, ctx->pending_comments_len,
       ctx->pending_comments_cap, entry);
  SomStrList lines;
  spec_format_comment_block(id, p->comment_text, author, p->changed_at,
                            &lines);
  char *block = som_strlist_join(&lines, "\n");
  som_strlist_free(&lines);
  free(id);
  return block;
}

/* A block placed after a unit: its anchor and text. */
typedef struct {
  long long anchor;
  char *text;
} PlacedBlock;

/* A content value: split into text paragraphs and annotation blocks, merged
 * unit by unit, the copies' new comments and questions placed after the unit
 * they followed. A copy whose text-paragraph count differs from the base's
 * makes the whole text one unit, for every copy. Owned. */
static char *merge_content(const MergeValue *v, MergeContext *ctx) {
  size_t n = v->copies_len;
  SpecReviewPieces base_pieces;
  spec_review_pieces(v->base, &base_pieces);
  SpecReviewPieces *copy_pieces = calloc(n ? n : 1, sizeof(SpecReviewPieces));
  for (size_t i = 0; i < n; i++) {
    if (v->copies[i] != NULL) spec_review_pieces(v->copies[i], &copy_pieces[i]);
  }
  SomStrList base_texts;
  texts_of(&base_pieces, &base_texts);
  int whole = 0;
  for (size_t i = 0; i < n; i++) {
    if (v->copies[i] == NULL) continue;
    SomStrList t;
    texts_of(&copy_pieces[i], &t);
    whole = whole || t.len != base_texts.len;
    som_strlist_free(&t);
  }
  som_strlist_free(&base_texts);
  SomStrList base_units;
  units_of(&base_pieces, whole, &base_units);
  SomStrList *copy_units = calloc(n ? n : 1, sizeof(SomStrList));
  for (size_t i = 0; i < n; i++) {
    if (v->copies[i] != NULL) units_of(&copy_pieces[i], whole, &copy_units[i]);
  }

  /* Blocks by anchor: the base's first, then each copy's new ones in round
   * order. */
  PlacedBlock *placed = NULL;
  size_t placed_len = 0, placed_cap = 0;
  for (size_t k = 0; k < base_pieces.len; k++) {
    if (base_pieces.items[k].is_text) continue;
    PlacedBlock pb = {anchor_of(&base_pieces, k, whole),
                      som_strdup(base_pieces.items[k].text)};
    PUSH(placed, placed_len, placed_cap, pb);
  }
  for (size_t i = 0; i < n; i++) {
    if (v->copies[i] == NULL) continue;
    const SpecReviewPieces *ps = &copy_pieces[i];
    for (size_t k = 0; k < ps->len; k++) {
      if (ps->items[k].is_text || !is_new_block(&ps->items[k], ctx)) continue;
      long long anchor =
          whole ? (long long)base_units.len - 1 : anchor_of(ps, k, 0);
      PlacedBlock pb = {anchor,
                        new_block(&ps->items[k], member_at(ctx, i), v, ctx)};
      PUSH(placed, placed_len, placed_cap, pb);
    }
  }

  SomStrList out;
  som_strlist_init(&out);
  for (size_t k = 0; k < placed_len; k++) {
    if (placed[k].anchor == -1) som_strlist_push_copy(&out, placed[k].text);
  }
  char **units = calloc(n ? n : 1, sizeof(char *));
  for (size_t u = 0; u < base_units.len; u++) {
    for (size_t i = 0; i < n; i++) {
      units[i] = v->copies[i] != NULL ? copy_units[i].items[u] : NULL;
    }
    char *conflict = NULL;
    char *text = merge_unit(base_units.items[u], units, n,
                            whole ? -1 : (long long)u, v, ctx, &conflict);
    if (text[0] != '\0') {
      som_strlist_push(&out, text);
    } else {
      free(text);
    }
    if (conflict != NULL) som_strlist_push(&out, conflict);
    for (size_t k = 0; k < placed_len; k++) {
      if (placed[k].anchor == (long long)u)
        som_strlist_push_copy(&out, placed[k].text);
    }
  }
  free(units);
  char *joined = som_strlist_join(&out, "\n\n");
  som_strlist_free(&out);
  for (size_t k = 0; k < placed_len; k++) free(placed[k].text);
  free(placed);
  for (size_t i = 0; i < n; i++) {
    if (v->copies[i] == NULL) continue;
    som_strlist_free(&copy_units[i]);
    spec_review_pieces_free(&copy_pieces[i]);
  }
  free(copy_units);
  free(copy_pieces);
  som_strlist_free(&base_units);
  spec_review_pieces_free(&base_pieces);
  return joined;
}

/* One value merged; the base text when no copy differs from it. Owned. */
static char *merge_value(const MergeValue *v, MergeContext *ctx) {
  int unchanged = 1;
  for (size_t i = 0; i < v->copies_len; i++) {
    unchanged = unchanged &&
                (v->copies[i] == NULL || strcmp(v->copies[i], v->base) == 0);
  }
  if (unchanged) return som_strdup(v->base);
  if (v->typed) return merge_typed(v, ctx);
  if (v->field != NULL) return merge_field(v, ctx);
  return merge_content(v, ctx);
}

/* ---- shared phases over the merged texts --------------------------------- */

/* The merged document's values, by key, in merged document order. */
typedef struct MergeTexts {
  /* Every key, in order, into `out` (initialised by the callee). */
  void (*keys)(const struct MergeTexts *t, SomStrList *out);
  /* The value at `key` (owned; "" when there is none). */
  char *(*get)(const struct MergeTexts *t, const char *key);
  void (*set)(struct MergeTexts *t, const char *key, const char *value);
  void *self;
} MergeTexts;

/* `value` with `block` appended, one blank line between them. Owned. */
static char *append_block(const char *value, const char *block) {
  return value[0] == '\0' ? som_strdup(block) : fmt("%s\n\n%s", value, block);
}

/* Appends the collected blocks (field and structural conflicts) to the end of
 * their values. */
static void apply_appends(MergeTexts *texts, const MergeContext *ctx) {
  for (size_t k = 0; k < ctx->append_keys.len; k++) {
    char *value = texts->get(texts, ctx->append_keys.items[k]);
    for (size_t b = 0; b < ctx->append_blocks[k].len; b++) {
      char *next = append_block(value, ctx->append_blocks[k].items[b]);
      free(value);
      value = next;
    }
    texts->set(texts, ctx->append_keys.items[k], value);
    free(value);
  }
}

/* The highest `<prefix>-<n>` of the texts' annotations of one kind. */
static long long highest_id(const SomStrList *texts, const char *prefix,
                            SpecReviewAnnotationKind kind) {
  long long high = 0;
  size_t pl = strlen(prefix);
  for (size_t t = 0; t < texts->len; t++) {
    SpecReviewPieces ps;
    spec_review_pieces(texts->items[t], &ps);
    for (size_t i = 0; i < ps.len; i++) {
      const SpecReviewPiece *p = &ps.items[i];
      if (p->is_text || p->kind != kind) continue;
      size_t count = kind == SPEC_REVIEW_ANNOTATION_QUESTION
                         ? p->question_ids.len
                         : p->id != NULL;
      for (size_t q = 0; q < count; q++) {
        const char *id = kind == SPEC_REVIEW_ANNOTATION_QUESTION
                             ? p->question_ids.items[q]
                             : p->id;
        if (strncmp(id, prefix, pl) != 0 || id[pl] != '-') continue;
        if (id[pl + 1] < '0' || id[pl + 1] > '9') continue;
        long long n = strtoll(id + pl + 1, NULL, 10);
        if (n > high) high = n;
      }
    }
    spec_review_pieces_free(&ps);
  }
  return high;
}

/* Takes the pending entry for `placeholder` out of `ctx`. */
static long long find_pending_conflict(const MergeContext *ctx,
                                       const char *ph) {
  for (size_t i = 0; i < ctx->pending_conflicts_len; i++) {
    if (strcmp(ctx->pending_conflicts[i].id, ph) == 0) return (long long)i;
  }
  return -1;
}

static long long find_pending_comment(const MergeContext *ctx, const char *ph) {
  for (size_t i = 0; i < ctx->pending_comments_len; i++) {
    if (strcmp(ctx->pending_comments[i].id, ph) == 0) return (long long)i;
  }
  return -1;
}

/* Numbers the new comments and conflicts in merged document order, above the
 * base's highest `C-<n>` and `X-<n>`, and fills their report entries in. */
static void number_ids(MergeTexts *texts, const SomStrList *base_texts,
                       MergeContext *ctx) {
  long long next_c =
      highest_id(base_texts, "C", SPEC_REVIEW_ANNOTATION_COMMENT);
  long long next_x =
      highest_id(base_texts, "X", SPEC_REVIEW_ANNOTATION_CONFLICT);
  SpecReviewMergeReport *rep = ctx->report;
  SomStrList keys;
  texts->keys(texts, &keys);
  for (size_t k = 0; k < keys.len; k++) {
    char *value = texts->get(texts, keys.items[k]);
    if (strchr(value, PLACEHOLDER_MARK) == NULL) {
      free(value);
      continue;
    }
    SomBuf out;
    som_buf_init(&out);
    const char *s = value;
    for (;;) {
      const char *at = strchr(s, PLACEHOLDER_MARK);
      const char *close = at == NULL ? NULL : strchr(at + 1, PLACEHOLDER_MARK);
      if (close == NULL) {
        som_buf_puts(&out, s);
        break;
      }
      som_buf_putn(&out, s, (size_t)(at - s));
      char *ph = som_strdup_n(at, (size_t)(close - at) + 1);
      if (at[1] == 'C') {
        char *id = fmt("C-%lld", ++next_c);
        long long i = find_pending_comment(ctx, ph);
        const SpecMergeComment *p = &ctx->pending_comments[i];
        SpecMergeComment e = {som_strdup(id), som_strdup(p->author),
                              som_strdup(p->path), dup_or_null(p->field)};
        PUSH(rep->comments, rep->comments_len, rep->comments_cap, e);
        som_buf_puts(&out, id);
        free(id);
      } else {
        char *id = fmt("X-%lld", ++next_x);
        long long i = find_pending_conflict(ctx, ph);
        const SpecMergeConflict *p = &ctx->pending_conflicts[i];
        SpecMergeConflict e;
        e.id = som_strdup(id);
        e.path = som_strdup(p->path);
        e.field = dup_or_null(p->field);
        e.paragraph = p->paragraph;
        som_strlist_copy(&e.members, &p->members);
        PUSH(rep->conflicts, rep->conflicts_len, rep->conflicts_cap, e);
        som_buf_puts(&out, id);
        free(id);
      }
      free(ph);
      s = close + 1;
    }
    char *numbered = som_buf_take(&out);
    texts->set(texts, keys.items[k], numbered);
    free(numbered);
    free(value);
  }
  som_strlist_free(&keys);
}

/* The team answers of `texts`' questions: `ids[k]` answered `answers[k]`, the
 * first occurrence of an id winning. Both lists initialised here. */
static void team_answers(const SomStrList *texts, SomStrList *ids,
                         SomStrList *answers) {
  som_strlist_init(ids);
  som_strlist_init(answers);
  for (size_t t = 0; t < texts->len; t++) {
    SomStrList vi, va;
    spec_review_team_answers(texts->items[t], &vi, &va);
    for (size_t k = 0; k < vi.len; k++) {
      if (som_strlist_contains(ids, vi.items[k])) continue;
      som_strlist_push_copy(ids, vi.items[k]);
      som_strlist_push_copy(answers, va.items[k]);
    }
    som_strlist_free(&vi);
    som_strlist_free(&va);
  }
}

/* Writes each copy's team answer to a base question, where it differs from
 * the base's, as that member's individual answer (copies in round order). */
static void merge_answers(MergeTexts *texts, const SomStrList *base_texts,
                          const SomStrList *copy_texts, size_t n,
                          MergeContext *ctx) {
  SomStrList base_ids, base_answers;
  team_answers(base_texts, &base_ids, &base_answers);
  SomStrList *copy_ids = calloc(n ? n : 1, sizeof(SomStrList));
  SomStrList *copy_answers = calloc(n ? n : 1, sizeof(SomStrList));
  for (size_t i = 0; i < n; i++)
    team_answers(&copy_texts[i], &copy_ids[i], &copy_answers[i]);
  for (size_t q = 0; q < base_ids.len; q++) {
    const char *id = base_ids.items[q];
    SomStrList members;
    som_strlist_init(&members);
    for (size_t i = 0; i < n; i++) {
      long long at = index_of(&copy_ids[i], id);
      if (at < 0) continue;
      const char *a = copy_answers[i].items[at];
      if (strcmp(a, base_answers.items[q]) == 0 || a[0] == '\0') continue;
      SomStrList keys;
      texts->keys(texts, &keys);
      for (size_t k = 0; k < keys.len; k++) {
        char *value = texts->get(texts, keys.items[k]);
        char *written = spec_review_set_individual_answer_text(
            value, id, member_at(ctx, i), a, NULL);
        free(value);
        if (written == NULL) continue;
        texts->set(texts, keys.items[k], written);
        free(written);
        som_strlist_push_copy(&members, member_at(ctx, i));
        break;
      }
      som_strlist_free(&keys);
    }
    if (members.len > 0) {
      SpecMergeAnswers e = {som_strdup(id), members};
      PUSH(ctx->report->answers, ctx->report->answers_len,
           ctx->report->answers_cap, e);
    } else {
      som_strlist_free(&members);
    }
  }
  for (size_t i = 0; i < n; i++) {
    som_strlist_free(&copy_ids[i]);
    som_strlist_free(&copy_answers[i]);
  }
  free(copy_ids);
  free(copy_answers);
  som_strlist_free(&base_ids);
  som_strlist_free(&base_answers);
}

/* The question proposing guest `g` for the next round's team. Owned. */
static char *guest_question(const char *id, const SpecReviewMember *g) {
  const char *role = g->role ? g->role : "";
  char *who = role[0] == '\0' ? som_strdup(g->display_name)
                              : fmt("%s, %s", g->display_name, role);
  char *topic = fmt("Guest %s", g->member_id);
  char *text = fmt("add %s (%s) to the review team?", g->member_id, who);
  const char *const options[2] = {"(a) yes, from the next round on",
                                  "(b) no, this round only"};
  SpecQuestionDraft q;
  memset(&q, 0, sizeof(q));
  q.id = id;
  q.topic = topic;
  q.text = text;
  q.options = options;
  q.options_len = 2;
  q.recommended = "a";
  SomStrList lines;
  spec_format_question_block(&q, &lines);
  char *block = som_strlist_join(&lines, "\n");
  som_strlist_free(&lines);
  free(text);
  free(topic);
  free(who);
  return block;
}

/* Lists the reviewers and writes one question per guest to the end of the
 * value keyed `home_key` (NULL: the report only), numbered above the base's
 * highest question id with the prefix. */
static void add_guests(MergeTexts *texts, const SomStrList *base_texts,
                       const SpecReviewMergeOptions *options,
                       const char *home_key, const char *home_path,
                       MergeContext *ctx) {
  const char *prefix =
      options->question_prefix ? options->question_prefix : "RQ";
  long long n = highest_id(base_texts, prefix, SPEC_REVIEW_ANNOTATION_QUESTION);
  SpecReviewMergeReport *rep = ctx->report;
  for (size_t i = 0; i < ctx->members_len; i++) {
    const SpecReviewMember *c = &ctx->copies[i];
    int guest = 1;
    for (size_t t = 0; t < options->team_len && guest; t++) {
      guest = strcmp(options->team[t].member_id, c->member_id) != 0;
    }
    SpecMergeReviewer r = {som_strdup(c->member_id),
                           som_strdup(c->display_name),
                           som_strdup(c->role ? c->role : ""), guest};
    PUSH(rep->reviewers, rep->reviewers_len, rep->reviewers_cap, r);
    if (!guest) continue;
    char *id = fmt("%s-%lld", prefix, ++n);
    SpecMergeGuestQuestion g = {som_strdup(id), som_strdup(c->member_id),
                                dup_or_null(home_key ? home_path : NULL)};
    PUSH(rep->guest_questions, rep->guest_questions_len,
         rep->guest_questions_cap, g);
    if (home_key != NULL) {
      char *value = texts->get(texts, home_key);
      char *block = guest_question(id, c);
      char *next = append_block(value, block);
      texts->set(texts, home_key, next);
      free(next);
      free(block);
      free(value);
    }
    free(id);
  }
}

/* The ids of the comments and questions of `texts`. Both lists initialised
 * here. */
static void block_ids(const SomStrList *texts, SomStrList *comments,
                      SomStrList *questions) {
  som_strlist_init(comments);
  som_strlist_init(questions);
  for (size_t t = 0; t < texts->len; t++) {
    SpecReviewPieces ps;
    spec_review_pieces(texts->items[t], &ps);
    for (size_t i = 0; i < ps.len; i++) {
      const SpecReviewPiece *p = &ps.items[i];
      if (!p->is_text && p->kind == SPEC_REVIEW_ANNOTATION_COMMENT &&
          p->id != NULL && !som_strlist_contains(comments, p->id)) {
        som_strlist_push_copy(comments, p->id);
      }
      for (size_t q = 0; q < p->question_ids.len; q++) {
        if (!som_strlist_contains(questions, p->question_ids.items[q])) {
          som_strlist_push_copy(questions, p->question_ids.items[q]);
        }
      }
    }
    spec_review_pieces_free(&ps);
  }
}

static void ctx_init(MergeContext *ctx, SpecReviewMergeReport *report,
                     const SpecReviewMember *copies, size_t n,
                     const SomStrList *base_texts) {
  memset(ctx, 0, sizeof(*ctx));
  ctx->report = report;
  ctx->copies = copies;
  ctx->members_len = n;
  som_strlist_init(&ctx->append_keys);
  block_ids(base_texts, &ctx->base_comment_ids, &ctx->base_question_ids);
}

/* The phases after the structure, shared by both formats: `keys[k]` is the
 * key of `values[k]`. */
static void merge_texts(const MergeValue *values, const SomStrList *keys,
                        MergeTexts *texts, const SomStrList *base_texts,
                        const SomStrList *copy_texts,
                        const SpecReviewMergeOptions *options,
                        const char *home_key, const char *home_path,
                        MergeContext *ctx) {
  for (size_t k = 0; k < keys->len; k++) {
    char *merged = merge_value(&values[k], ctx);
    if (strcmp(merged, values[k].base) != 0)
      texts->set(texts, keys->items[k], merged);
    free(merged);
  }
  apply_appends(texts, ctx);
  number_ids(texts, base_texts, ctx);
  merge_answers(texts, base_texts, copy_texts, ctx->members_len, ctx);
  add_guests(texts, base_texts, options, home_key, home_path, ctx);
}

/* ---- plain Markdown: values by heading path ------------------------------ */

/* A Markdown file cut at its headings: body `i` follows heading `i - 1` (body
 * 0 precedes them all). `paths[i]` is the heading path of body `i`, its
 * heading texts joined by ` > ` (body 0: ``). */
typedef struct {
  SomStrList headings;
  SomStrList paths;
  SomStrList *bodies;
  size_t bodies_len, bodies_cap;
} MarkdownSplit;

static void markdown_split_free(MarkdownSplit *m) {
  som_strlist_free(&m->headings);
  som_strlist_free(&m->paths);
  for (size_t i = 0; i < m->bodies_len; i++) som_strlist_free(&m->bodies[i]);
  free(m->bodies);
}

static void markdown_new_body(MarkdownSplit *m) {
  SomStrList body;
  som_strlist_init(&body);
  PUSH(m->bodies, m->bodies_len, m->bodies_cap, body);
}

/* An ATX heading's level (0: not a heading) and its text (owned). */
static size_t atx_heading(const char *line, char **text) {
  size_t level = 0;
  while (line[level] == '#') level++;
  if (level == 0 || level > 6) return 0;
  const char *rest = line + level;
  if (rest[0] != '\0' && rest[0] != ' ' && rest[0] != '\t') return 0;
  size_t a = 0, b = strlen(rest);
  while (a < b && (rest[a] == ' ' || rest[a] == '\t')) a++;
  while (b > a && (rest[b - 1] == ' ' || rest[b - 1] == '\t')) b--;
  *text = som_strdup_n(rest + a, b - a);
  return level;
}

static void split_markdown(const char *text, MarkdownSplit *out) {
  memset(out, 0, sizeof(*out));
  som_strlist_init(&out->headings);
  som_strlist_init(&out->paths);
  som_strlist_push_copy(&out->paths, "");
  markdown_new_body(out);
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  SomStrList stack_names;
  som_strlist_init(&stack_names);
  size_t *stack_levels = NULL;
  size_t stack_len = 0, stack_cap = 0;
  SomStrList lines;
  split_on(text, '\n', &lines);
  for (size_t k = 0; k < lines.len; k++) {
    const char *line = lines.items[k];
    int was_fenced = spec_markdown_fence_in_fence(&fence);
    spec_markdown_fence_feed(&fence, line);
    char *name = NULL;
    size_t level = was_fenced || spec_markdown_fence_in_fence(&fence)
                       ? 0
                       : atx_heading(line, &name);
    if (level == 0) {
      som_strlist_push_copy(&out->bodies[out->bodies_len - 1], line);
      continue;
    }
    while (stack_len > 0 && stack_levels[stack_len - 1] >= level) {
      stack_len--;
      som_strlist_remove_at(&stack_names, stack_names.len - 1);
    }
    PUSH(stack_levels, stack_len, stack_cap, level);
    som_strlist_push(&stack_names, name);
    som_strlist_push_copy(&out->headings, line);
    som_strlist_push(&out->paths, som_strlist_join(&stack_names, " > "));
    markdown_new_body(out);
  }
  som_strlist_free(&lines);
  som_strlist_free(&stack_names);
  free(stack_levels);
}

/* A body's blank lines before (`*lead`) and after (`*trail`) its value, and
 * the value (owned). */
static char *body_parts(const SomStrList *lines, size_t *lead, size_t *trail) {
  *lead = 0;
  *trail = 0;
  while (*lead < lines->len && is_blank_text(lines->items[*lead])) (*lead)++;
  if (*lead == lines->len) return som_strdup("");
  while (is_blank_text(lines->items[lines->len - 1 - *trail])) (*trail)++;
  return join_range(lines, "\n", *lead, lines->len - *trail);
}

/* Pushes the body lines for a new value onto `out`, keeping the body's blank
 * lines around it. */
static void body_lines(const SomStrList *lines, const char *value,
                       int after_heading, SomStrList *out) {
  size_t lead, trail;
  char *current = body_parts(lines, &lead, &trail);
  if (strcmp(value, current) == 0) {
    for (size_t k = 0; k < lines->len; k++)
      som_strlist_push_copy(out, lines->items[k]);
  } else if (value[0] == '\0') {
    for (size_t k = 0; k < lead; k++)
      som_strlist_push_copy(out, lines->items[k]);
  } else {
    SomStrList v;
    split_on(value, '\n', &v);
    if (current[0] == '\0') {
      if (after_heading) som_strlist_push_copy(out, "");
      for (size_t k = 0; k < v.len; k++) som_strlist_push_copy(out, v.items[k]);
      if (lines->len > 0) som_strlist_push_copy(out, "");
    } else {
      for (size_t k = 0; k < lead; k++)
        som_strlist_push_copy(out, lines->items[k]);
      for (size_t k = 0; k < v.len; k++) som_strlist_push_copy(out, v.items[k]);
      for (size_t k = lines->len - trail; k < lines->len; k++) {
        som_strlist_push_copy(out, lines->items[k]);
      }
    }
    som_strlist_free(&v);
  }
  free(current);
}

/* The values of a Markdown merge: one per body, keyed by its index. */
static void md_keys(const MergeTexts *t, SomStrList *out) {
  const SomStrList *values = t->self;
  som_strlist_init(out);
  for (size_t k = 0; k < values->len; k++) som_strlist_push(out, fmt("%zu", k));
}

static char *md_get(const MergeTexts *t, const char *key) {
  const SomStrList *values = t->self;
  return som_strdup(values->items[strtoul(key, NULL, 10)]);
}

static void md_set(MergeTexts *t, const char *key, const char *value) {
  SomStrList *values = t->self;
  size_t k = strtoul(key, NULL, 10);
  free(values->items[k]);
  values->items[k] = som_strdup(value);
}

/* The member records of `copies` (borrowed strings). Owned array. */
static SpecReviewMember *markdown_members(const SpecReviewedMarkdown *copies,
                                          size_t n) {
  SpecReviewMember *out = malloc((n ? n : 1) * sizeof(*out));
  for (size_t i = 0; i < n; i++) out[i] = copies[i].member;
  return out;
}

char *spec_review_merge_markdown(const char *base,
                                 const SpecReviewedMarkdown *copies,
                                 size_t copies_len,
                                 const SpecReviewMergeOptions *options,
                                 SpecReviewMergeReport *report,
                                 SpecReviewMergeError *err) {
  spec_review_merge_report_init(report);
  MarkdownSplit b;
  split_markdown(base, &b);
  MarkdownSplit *cs =
      calloc(copies_len ? copies_len : 1, sizeof(MarkdownSplit));
  for (size_t i = 0; i < copies_len; i++) {
    split_markdown(copies[i].document, &cs[i]);
    int same = cs[i].headings.len == b.headings.len;
    for (size_t k = 0; same && k < b.headings.len; k++) {
      char *x = trim_text(cs[i].headings.items[k]);
      char *y = trim_text(b.headings.items[k]);
      same = strcmp(x, y) == 0;
      free(x);
      free(y);
    }
    if (!same) {
      set_error(err, fmt("the copy of %s has other headings than the base",
                         copies[i].member.member_id));
      for (size_t j = 0; j <= i; j++) markdown_split_free(&cs[j]);
      free(cs);
      markdown_split_free(&b);
      return NULL;
    }
  }
  size_t lead, trail;
  SomStrList base_texts;
  som_strlist_init(&base_texts);
  for (size_t k = 0; k < b.bodies_len; k++) {
    som_strlist_push(&base_texts, body_parts(&b.bodies[k], &lead, &trail));
  }
  SomStrList *copy_texts =
      calloc(copies_len ? copies_len : 1, sizeof(SomStrList));
  for (size_t i = 0; i < copies_len; i++) {
    som_strlist_init(&copy_texts[i]);
    for (size_t k = 0; k < cs[i].bodies_len; k++) {
      som_strlist_push(&copy_texts[i],
                       body_parts(&cs[i].bodies[k], &lead, &trail));
    }
  }
  SomStrList merged;
  som_strlist_copy(&merged, &base_texts);
  MergeTexts texts = {md_keys, md_get, md_set, &merged};
  SpecReviewMember *members = markdown_members(copies, copies_len);
  MergeContext ctx;
  ctx_init(&ctx, report, members, copies_len, &base_texts);
  MergeValue *values =
      calloc(base_texts.len ? base_texts.len : 1, sizeof(MergeValue));
  SomStrList keys;
  som_strlist_init(&keys);
  for (size_t k = 0; k < base_texts.len; k++) {
    values[k].path = som_strdup(b.paths.items[k]);
    values[k].base = som_strdup(base_texts.items[k]);
    values[k].copies_len = copies_len;
    values[k].copies = calloc(copies_len ? copies_len : 1, sizeof(char *));
    for (size_t i = 0; i < copies_len; i++) {
      values[k].copies[i] = som_strdup(copy_texts[i].items[k]);
    }
    som_strlist_push(&keys, fmt("%zu", k));
  }
  size_t first = b.headings.len > 0 ? 1 : 0;
  char *home_key = fmt("%zu", first);
  merge_texts(values, &keys, &texts, &base_texts, copy_texts, options, home_key,
              b.paths.items[first], &ctx);
  free(home_key);
  SomStrList lines;
  som_strlist_init(&lines);
  for (size_t k = 0; k < b.bodies_len; k++) {
    if (k > 0) som_strlist_push_copy(&lines, b.headings.items[k - 1]);
    body_lines(&b.bodies[k], merged.items[k], k > 0, &lines);
  }
  char *out = som_strlist_join(&lines, "\n");
  som_strlist_free(&lines);
  for (size_t k = 0; k < base_texts.len; k++) merge_value_free(&values[k]);
  free(values);
  som_strlist_free(&keys);
  ctx_free(&ctx);
  free(members);
  som_strlist_free(&merged);
  for (size_t i = 0; i < copies_len; i++) {
    som_strlist_free(&copy_texts[i]);
    markdown_split_free(&cs[i]);
  }
  free(copy_texts);
  free(cs);
  som_strlist_free(&base_texts);
  markdown_split_free(&b);
  return out;
}

/* ---- SOM documents: values by model path, list items by section id ------- */

/* A document's paths with every list item named by its section id instead of
 * its position (`DEMO/CARD-LST#CARD-BETA/content`), so the same item has the
 * same name in the base, in every copy and in the merged document. */
typedef struct {
  const SpecDocument *doc;
  SomMap list_of;      /* item → its list */
  SomMap ids;          /* item → the section id it is matched by */
  SomMap by_canonical; /* canonical item path → item */
  SomMap memo;         /* path → canonical path */
} CanonicalPaths;

static char *canonical_of(CanonicalPaths *cp, const char *path);

static void canonical_init(CanonicalPaths *cp, const SpecDocument *doc,
                           const SpecReflection *refl) {
  cp->doc = doc;
  som_map_init(&cp->list_of);
  som_map_init(&cp->ids);
  som_map_init(&cp->by_canonical);
  som_map_init(&cp->memo);
  SomStrList lists;
  spec_document_list_paths(doc, &lists);
  for (size_t l = 0; l < lists.len; l++) {
    SpecResolution res;
    const SpecField *field = NULL;
    if (spec_reflection_resolve(refl, lists.items[l], &res)) {
      field = res.field;
      spec_resolution_free(&res);
    }
    const SomStrList *items = spec_document_list_items(doc, lists.items[l]);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      som_map_set(&cp->list_of, items->items[k], lists.items[l]);
      char *id = spec_effective_list_item_section_id(
          spec_document_item_section_id(doc, items->items[k]),
          field ? field->section_id_pattern : NULL, (long long)k + 1,
          field ? field->name : lists.items[l]);
      som_map_set(&cp->ids, items->items[k], id);
      free(id);
    }
  }
  som_strlist_free(&lists);
  for (size_t i = 0; i < cp->list_of.len; i++) {
    char *c = canonical_of(cp, cp->list_of.entries[i].key);
    som_map_set(&cp->by_canonical, c, cp->list_of.entries[i].key);
    free(c);
  }
}

static void canonical_free(CanonicalPaths *cp) {
  som_map_free(&cp->list_of);
  som_map_free(&cp->ids);
  som_map_free(&cp->by_canonical);
  som_map_free(&cp->memo);
}

/* The section id an item is matched by (borrowed). */
static const char *canonical_id(const CanonicalPaths *cp, const char *item) {
  return som_map_get(&cp->ids, item);
}

/* The canonical form of `path`. Owned. */
static char *canonical_of(CanonicalPaths *cp, const char *path) {
  const char *memo = som_map_get(&cp->memo, path);
  if (memo != NULL) return som_strdup(memo);
  SomStrList segs;
  split_on(path, '/', &segs);
  char *out = NULL;
  for (size_t k = segs.len; k > 0 && out == NULL; k--) {
    char *prefix = join_range(&segs, "/", 0, k);
    const char *list = som_map_get(&cp->list_of, prefix);
    if (list != NULL) {
      char *list_canon = canonical_of(cp, list);
      char *rest = join_range(&segs, "/", k, segs.len);
      out = rest[0] == '\0'
                ? fmt("%s#%s", list_canon, canonical_id(cp, prefix))
                : fmt("%s#%s/%s", list_canon, canonical_id(cp, prefix), rest);
      free(rest);
      free(list_canon);
    }
    free(prefix);
  }
  som_strlist_free(&segs);
  if (out == NULL) out = som_strdup(path);
  som_map_set(&cp->memo, path, out);
  return out;
}

/* The document's path for a canonical path (owned), or NULL when the document
 * lacks one of its items. */
static char *canonical_path_of(const CanonicalPaths *cp,
                               const char *canonical) {
  SomStrList segs;
  split_on(canonical, '/', &segs);
  char *out = NULL;
  int found = 0;
  for (size_t k = segs.len; k > 0 && !found; k--) {
    char *prefix = join_range(&segs, "/", 0, k);
    const char *item = som_map_get(&cp->by_canonical, prefix);
    if (item != NULL) {
      char *rest = join_range(&segs, "/", k, segs.len);
      out = rest[0] == '\0' ? som_strdup(item) : fmt("%s/%s", item, rest);
      free(rest);
      found = 1;
    }
    free(prefix);
  }
  som_strlist_free(&segs);
  if (!found && strchr(canonical, '#') == NULL) out = som_strdup(canonical);
  return out;
}

/* The section ids of the items of the list at `list`, in order, into `out`
 * (initialised here). */
static void canonical_item_ids(const CanonicalPaths *cp, const char *list,
                               SomStrList *out) {
  som_strlist_init(out);
  const SomStrList *items = spec_document_list_items(cp->doc, list);
  for (size_t k = 0; items != NULL && k < items->len; k++) {
    som_strlist_push_copy(out, canonical_id(cp, items->items[k]));
  }
}

/* A copy whose paths the model does not resolve does not fit the base. */
static int check_structure(const SpecDocument *doc, const char *what,
                           const SpecReflection *refl,
                           SpecReviewMergeError *err) {
  DocumentJson json;
  spec_document_to_json(doc, &json);
  SomStrList paths;
  som_strlist_init(&paths);
  for (size_t i = 0; i < json.content.len; i++)
    som_strlist_push_copy(&paths, json.content.entries[i].key);
  for (size_t i = 0; i < json.forms_len; i++)
    som_strlist_push_copy(&paths, json.forms[i].key);
  for (size_t i = 0; i < json.headlines.len; i++)
    som_strlist_push_copy(&paths, json.headlines.entries[i].key);
  for (size_t i = 0; i < json.code_specs.len; i++)
    som_strlist_push_copy(&paths, json.code_specs.entries[i].key);
  for (size_t i = 0; i < json.lists_len; i++) {
    som_strlist_push_copy(&paths, json.lists[i].key);
    for (size_t k = 0; k < json.lists[i].items.len; k++) {
      som_strlist_push_copy(&paths, json.lists[i].items.items[k]);
    }
  }
  document_json_free(&json);
  int ok = 1;
  for (size_t i = 0; ok && i < paths.len; i++) {
    SpecResolution res;
    if (spec_reflection_resolve(refl, paths.items[i], &res)) {
      spec_resolution_free(&res);
    } else {
      set_error(err, fmt("%s holds %s, a path the base model does not resolve",
                         what, paths.items[i]));
      ok = 0;
    }
  }
  som_strlist_free(&paths);
  return ok;
}

/* The resolution of `path`'s model field (borrowed from the model), or
 * NULL. `*kind` gets the node kind (static) when non-NULL. */
static const SpecField *resolve_field(const SpecReflection *refl,
                                      const char *path, const char **kind,
                                      const SpecClass **target) {
  SpecResolution res;
  if (!spec_reflection_resolve(refl, path, &res)) return NULL;
  const SpecField *f = res.field;
  if (kind != NULL) *kind = res.kind;
  if (target != NULL) *target = res.target_class;
  spec_resolution_free(&res);
  return f;
}

/* The form field `field` of the form at `path`, or NULL. */
static const FormFieldSpec *form_field_spec(const SpecReflection *refl,
                                            const char *path,
                                            const char *field) {
  const SpecField *f = resolve_field(refl, path, NULL, NULL);
  for (size_t i = 0; f != NULL && i < f->form_fields_len; i++) {
    if (strcmp(f->form_fields[i].name, field) == 0) return &f->form_fields[i];
  }
  return NULL;
}

/* Whether the value at `path` / `field` is text, which can hold marks: a
 * content value (a form's preamble included) or a String form field that is
 * not code. Scalar and enum leaves, and typed or code fields, are not. */
static int is_text_value(const SpecReflection *refl, const char *path,
                         const char *field) {
  if (field != NULL) {
    const FormFieldSpec *spec = form_field_spec(refl, path, field);
    return spec == NULL || (strcmp(spec->type, "String") == 0 && !spec->code);
  }
  SpecResolution res;
  if (!spec_reflection_resolve(refl, path, &res)) return 1;
  int text;
  if (strcmp(res.kind, SPEC_NODE_KIND_SCALAR) == 0 ||
      strcmp(res.kind, SPEC_NODE_KIND_ENUM_VALUE) == 0) {
    text = 0;
  } else {
    text = strcmp(res.kind, SPEC_NODE_KIND_LIST_ITEM_SCALAR) != 0 ||
           (res.field != NULL && res.field->element_type != NULL &&
            strcmp(res.field->element_type, "String") == 0);
  }
  spec_resolution_free(&res);
  return text;
}

/* The first node at or below `path` that holds content (a content leaf or a
 * form's preamble), in model order. Owned, or NULL. */
static char *first_content_slot(const SpecReflection *refl, const char *path,
                                int deep) {
  SpecResolution res;
  if (!spec_reflection_resolve(refl, path, &res)) return NULL;
  int here = strcmp(res.kind, SPEC_NODE_KIND_CONTENT) == 0 ||
             strcmp(res.kind, SPEC_NODE_KIND_FORM) == 0;
  const SpecClass *cls = res.target_class;
  spec_resolution_free(&res);
  if (here) return som_strdup(path);
  for (size_t i = 0; cls != NULL && i < cls->fields_len; i++) {
    const SpecField *f = &cls->fields[i];
    char *child = fmt("%s/%s", path, spec_reflection_field_segment(f));
    if (strcmp(f->kind, SPEC_FIELD_KIND_CONTENT) == 0 ||
        strcmp(f->kind, SPEC_FIELD_KIND_FORM) == 0) {
      return child;
    }
    if (deep && (strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
                 strcmp(f->kind, SPEC_FIELD_KIND_SECTION) == 0)) {
      char *found = first_content_slot(refl, child, 1);
      if (found != NULL) {
        free(child);
        return found;
      }
    }
    free(child);
  }
  return NULL;
}

/* Where a block about the node at `path` goes (SOM §11.9.9, "Structure"): the
 * first content value at or below it in document order; else the first node
 * at or below it that can hold content; else its nearest ancestor's own.
 * Owned, or NULL. */
static char *block_home(const SpecDocument *doc, const SpecReflection *refl,
                        const char *path, int own_first) {
  if (own_first) {
    SomStrList contents;
    spec_document_content_paths(doc, &contents);
    char *best = NULL;
    for (size_t i = 0; i < contents.len; i++) {
      if (under(contents.items[i], path) &&
          (best == NULL || strcmp(contents.items[i], best) < 0)) {
        best = contents.items[i];
      }
    }
    char *home = dup_or_null(best);
    som_strlist_free(&contents);
    if (home != NULL) return home;
    home = first_content_slot(refl, path, 1);
    if (home != NULL) return home;
  }
  char *a = spec_parent_path(path);
  char *home = NULL;
  while (a[0] != '\0' && home == NULL) {
    if (spec_document_content(doc, a) != NULL) {
      home = som_strdup(a);
      break;
    }
    home = first_content_slot(refl, a, 0);
    if (home != NULL) break;
    char *parent = spec_parent_path(a);
    if (strcmp(parent, a) == 0) {
      free(parent);
      break;
    }
    free(a);
    a = parent;
  }
  free(a);
  return home;
}

/* One structural change the copies disagree with the base on. */
typedef struct {
  char *node;        /* the canonical path of the item (or section) concerned */
  const char *topic; /* `Item removed`, `Item moved` or `Headline changed` */
  char *base;
  ChangeGroups groups;
} Structural;

typedef struct {
  Structural *items;
  size_t len, cap;
} Structurals;

static void structurals_free(Structurals *s) {
  for (size_t i = 0; i < s->len; i++) {
    free(s->items[i].node);
    free(s->items[i].base);
    groups_free(&s->items[i].groups);
  }
  free(s->items);
}

static void add_structural(Structurals *all, const char *node,
                           const char *topic, const char *base,
                           const char *text, const char *member) {
  Structural *s = NULL;
  for (size_t i = 0; i < all->len && s == NULL; i++) {
    if (strcmp(all->items[i].node, node) == 0 &&
        strcmp(all->items[i].topic, topic) == 0) {
      s = &all->items[i];
    }
  }
  if (s == NULL) {
    Structural x;
    x.node = som_strdup(node);
    x.topic = topic;
    x.base = som_strdup(base);
    memset(&x.groups, 0, sizeof(x.groups));
    PUSH(all->items, all->len, all->cap, x);
    s = &all->items[all->len - 1];
  }
  groups_add(&s->groups, text, member, SIZE_MAX);
}

/* Flags (`out[j]`, owned) the ids of `ids` that are not in their longest
 * common subsequence with `order`. */
static unsigned char *moved_flags(const SomStrList *order,
                                  const SomStrList *ids) {
  size_t n = order->len, m = ids->len, w = m + 1;
  size_t *l = calloc((n + 1) * w, sizeof(size_t));
  for (size_t i = n; i-- > 0;) {
    for (size_t j = m; j-- > 0;) {
      size_t down = l[(i + 1) * w + j], right = l[i * w + j + 1];
      l[i * w + j] = strcmp(order->items[i], ids->items[j]) == 0
                         ? l[(i + 1) * w + j + 1] + 1
                         : (down >= right ? down : right);
    }
  }
  unsigned char *out = malloc(m ? m : 1);
  memset(out, 1, m ? m : 1);
  size_t i = 0, j = 0;
  while (i < n && j < m) {
    if (strcmp(order->items[i], ids->items[j]) == 0) {
      out[j] = 0;
      i++;
      j++;
    } else if (l[(i + 1) * w + j] >= l[i * w + j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  free(l);
  return out;
}

/* Whether a paragraph opens a fenced code block. */
static int opens_fence(const char *text) {
  while (is_space_byte(*text)) text++;
  return starts_with(text, "```") || starts_with(text, "~~~");
}

/* `value` written as attributed insertions, one per text paragraph (an added
 * item's text). Owned. */
static char *as_insertion(const char *value, const SomStrList *members) {
  char *names = som_strlist_join(members, ",");
  SpecReviewPieces ps;
  spec_review_pieces(value, &ps);
  SomStrList out;
  som_strlist_init(&out);
  for (size_t i = 0; i < ps.len; i++) {
    const SpecReviewPiece *p = &ps.items[i];
    if (!p->is_text || opens_fence(p->text)) {
      som_strlist_push_copy(&out, p->text);
    } else {
      char *t = trim_text(p->text);
      som_strlist_push(&out, fmt("{++ %s ++}{@%s}", t, names));
      free(t);
    }
  }
  char *joined = som_strlist_join(&out, "\n\n");
  som_strlist_free(&out);
  spec_review_pieces_free(&ps);
  free(names);
  return joined;
}

/* `p` with the longest prefix `moved` maps (from → to) replaced. Owned. */
static char *remap_path(const SomMap *moved, const char *p) {
  SomStrList segs;
  split_on(p, '/', &segs);
  char *out = NULL;
  for (size_t k = segs.len; k > 0 && out == NULL; k--) {
    char *prefix = join_range(&segs, "/", 0, k);
    const char *target = som_map_get(moved, prefix);
    if (target != NULL) {
      char *rest = join_range(&segs, "/", k, segs.len);
      out = rest[0] == '\0' ? som_strdup(target) : fmt("%s/%s", target, rest);
      free(rest);
    }
    free(prefix);
  }
  som_strlist_free(&segs);
  return out != NULL ? out : som_strdup(p);
}

static size_t slashes(const char *s) {
  size_t n = 0;
  for (; *s; s++) n += *s == '/';
  return n;
}

/* Copies item `from` of `src`, with everything under it, to item `to` of
 * `dst`. */
static void copy_item(const SpecDocument *src, const char *from,
                      SpecDocument *dst, const char *to,
                      const SomStrList *members, const SpecReflection *refl) {
  SomMap moved;
  som_map_init(&moved);
  som_map_set(&moved, from, to);
  SomStrList all, lists;
  spec_document_list_paths(src, &all);
  som_strlist_init(&lists);
  for (size_t i = 0; i < all.len; i++) {
    if (under(all.items[i], from)) som_strlist_push_copy(&lists, all.items[i]);
  }
  som_strlist_free(&all);
  /* By depth, stably. */
  for (size_t i = 1; i < lists.len; i++) {
    char *x = lists.items[i];
    size_t j = i;
    while (j > 0 && slashes(lists.items[j - 1]) > slashes(x)) {
      lists.items[j] = lists.items[j - 1];
      j--;
    }
    lists.items[j] = x;
  }
  CanonicalPaths canonical;
  canonical_init(&canonical, src, refl);
  for (size_t l = 0; l < lists.len; l++) {
    const SomStrList *items = spec_document_list_items(src, lists.items[l]);
    for (size_t k = 0; items != NULL && k < items->len; k++) {
      char *target = remap_path(&moved, lists.items[l]);
      char *item = spec_document_add_list_item_with_section_id(
          dst, target, canonical_id(&canonical, items->items[k]), NULL);
      if (item != NULL) som_map_set(&moved, items->items[k], item);
      free(item);
      free(target);
    }
  }
  canonical_free(&canonical);
  som_strlist_free(&lists);
  SomStrList paths;
  spec_document_content_paths(src, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (!under(paths.items[i], from)) continue;
    const char *value = spec_document_content(src, paths.items[i]);
    char *target = remap_path(&moved, paths.items[i]);
    char *text = is_text_value(refl, paths.items[i], NULL)
                     ? as_insertion(value, members)
                     : som_strdup(value);
    spec_document_set_content(dst, target, text);
    free(text);
    free(target);
  }
  som_strlist_free(&paths);
  spec_document_form_paths(src, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (!under(paths.items[i], from)) continue;
    SomStrList fields;
    spec_document_form_field_names(src, paths.items[i], &fields);
    char *target = remap_path(&moved, paths.items[i]);
    for (size_t f = 0; f < fields.len; f++) {
      const char *value =
          spec_document_form_field(src, paths.items[i], fields.items[f]);
      char *text = is_text_value(refl, paths.items[i], fields.items[f])
                       ? as_insertion(value, members)
                       : som_strdup(value);
      spec_document_set_form_field(dst, target, fields.items[f], text);
      free(text);
    }
    free(target);
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
  spec_document_headline_paths(src, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (!under(paths.items[i], from)) continue;
    char *target = remap_path(&moved, paths.items[i]);
    spec_document_set_headline(dst, target,
                               spec_document_headline(src, paths.items[i]));
    free(target);
  }
  som_strlist_free(&paths);
  spec_document_code_spec_paths(src, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    if (!under(paths.items[i], from)) continue;
    char *target = remap_path(&moved, paths.items[i]);
    spec_document_set_code_spec(dst, target,
                                spec_document_code_spec(src, paths.items[i]));
    free(target);
  }
  som_strlist_free(&paths);
  som_map_free(&moved);
}

/* Everything under an item, as one comparable value, its own path cut from
 * every path in it: copies adding the same item alike add it once. Owned. */
static char *item_signature(const SpecDocument *doc, const char *item) {
  DocumentJson json;
  spec_document_to_json(doc, &json);
  size_t il = strlen(item);
  SomBuf b;
  som_buf_init(&b);
#define REL(p) (strncmp((p), item, il) == 0 ? (p) + il : (p))
#define ADD(s)              \
  do {                      \
    push_json_str(&b, (s)); \
    som_buf_putc(&b, ',');  \
  } while (0)
  for (size_t i = 0; i < json.content.len; i++) {
    const char *k = json.content.entries[i].key;
    if (!under(k, item)) continue;
    som_buf_putc(&b, 'c');
    ADD(REL(k));
    ADD(json.content.entries[i].val);
  }
  for (size_t i = 0; i < json.forms_len; i++) {
    const char *k = json.forms[i].key;
    if (!under(k, item)) continue;
    som_buf_putc(&b, 'f');
    ADD(REL(k));
    for (size_t f = 0; f < json.forms[i].fields.len; f++) {
      ADD(json.forms[i].fields.entries[f].key);
      ADD(json.forms[i].fields.entries[f].val);
    }
  }
  for (size_t i = 0; i < json.headlines.len; i++) {
    const char *k = json.headlines.entries[i].key;
    if (!under(k, item)) continue;
    som_buf_putc(&b, 'h');
    ADD(REL(k));
    ADD(json.headlines.entries[i].val);
  }
  for (size_t i = 0; i < json.lists_len; i++) {
    const DocListEntry *e = &json.lists[i];
    if (!under(e->key, item)) continue;
    som_buf_putc(&b, 'l');
    ADD(REL(e->key));
    som_buf_puti(&b, e->seq);
    for (size_t k = 0; k < e->items.len; k++) ADD(REL(e->items.items[k]));
    for (size_t k = 0; k < e->ids.len; k++) {
      ADD(REL(e->ids.entries[k].key));
      ADD(e->ids.entries[k].val);
    }
  }
#undef ADD
#undef REL
  document_json_free(&json);
  return som_buf_take(&b);
}

/* The keys of the SOM texts: `c<SEP><path>` for content,
 * `f<SEP><path><SEP><field>` for a form field. Owned. */
static char *content_key(const char *path) {
  return fmt("c%c%s", KEY_SEP, path);
}

static char *field_key(const char *path, const char *field) {
  return fmt("f%c%s%c%s", KEY_SEP, path, KEY_SEP, field);
}

static char *value_key(const MergeValue *v) {
  return v->field == NULL ? content_key(v->path) : field_key(v->path, v->field);
}

/* Splits a SOM value key into its path and field (NULL for content), owned. */
static void split_key(const char *key, char **path, char **field) {
  const char *p = key + 2;
  const char *sep = key[0] == 'f' ? strchr(p, KEY_SEP) : NULL;
  *path = sep ? som_strdup_n(p, (size_t)(sep - p)) : som_strdup(p);
  *field = sep ? som_strdup(sep + 1) : NULL;
}

static void cmp_sort(SomStrList *l) {
  for (size_t i = 1; i < l->len; i++) {
    char *x = l->items[i];
    size_t j = i;
    while (j > 0 && strcmp(l->items[j - 1], x) > 0) {
      l->items[j] = l->items[j - 1];
      j--;
    }
    l->items[j] = x;
  }
}

/* A SOM document's values as MergeTexts, in document order (content sorted,
 * then forms and fields sorted). */
static void som_keys(const MergeTexts *t, SomStrList *out) {
  const SpecDocument *doc = t->self;
  som_strlist_init(out);
  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  cmp_sort(&paths);
  for (size_t i = 0; i < paths.len; i++)
    som_strlist_push(out, content_key(paths.items[i]));
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  cmp_sort(&paths);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList fields;
    spec_document_form_field_names(doc, paths.items[i], &fields);
    cmp_sort(&fields);
    for (size_t f = 0; f < fields.len; f++) {
      som_strlist_push(out, field_key(paths.items[i], fields.items[f]));
    }
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
}

static char *som_get(const MergeTexts *t, const char *key) {
  const SpecDocument *doc = t->self;
  char *path, *field;
  split_key(key, &path, &field);
  const char *v = field == NULL ? spec_document_content(doc, path)
                                : spec_document_form_field(doc, path, field);
  char *out = som_strdup(v ? v : "");
  free(path);
  free(field);
  return out;
}

static void som_set(MergeTexts *t, const char *key, const char *value) {
  SpecDocument *doc = t->self;
  char *path, *field;
  split_key(key, &path, &field);
  if (field == NULL) {
    spec_document_set_content(doc, path, value);
  } else {
    spec_document_set_form_field(doc, path, field, value);
  }
  free(path);
  free(field);
}

/* Every value of `doc`, in document order, into `out` (initialised here). */
static void som_value_texts(const SpecDocument *doc, SomStrList *out) {
  MergeTexts t = {som_keys, som_get, som_set, (void *)doc};
  SomStrList keys;
  som_keys(&t, &keys);
  som_strlist_init(out);
  for (size_t i = 0; i < keys.len; i++)
    som_strlist_push(out, som_get(&t, keys.items[i]));
  som_strlist_free(&keys);
}

/* Whether `node` lies under one of the `added` items. */
static int under_added(const char *node, const SomStrList *added) {
  for (size_t i = 0; i < added->len; i++) {
    if (under(node, added->items[i])) return 1;
  }
  return 0;
}

/* Every headline a copy changed (items it added aside) is a structural
 * conflict. */
static void headline_changes(const SpecDocument *base,
                             CanonicalPaths *base_canon,
                             const SpecReviewedDocument *copies, size_t n,
                             CanonicalPaths *copy_canon,
                             const SomStrList *added, Structurals *structural) {
  SomStrList nodes, paths;
  som_strlist_init(&nodes);
  spec_document_headline_paths(base, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    char *c = canonical_of(base_canon, paths.items[i]);
    if (!som_strlist_contains(&nodes, c)) {
      som_strlist_push(&nodes, c);
    } else {
      free(c);
    }
  }
  som_strlist_free(&paths);
  for (size_t i = 0; i < n; i++) {
    spec_document_headline_paths(copies[i].document, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      char *c = canonical_of(&copy_canon[i], paths.items[k]);
      if (!som_strlist_contains(&nodes, c)) {
        som_strlist_push(&nodes, c);
      } else {
        free(c);
      }
    }
    som_strlist_free(&paths);
  }
  cmp_sort(&nodes);
  for (size_t k = 0; k < nodes.len; k++) {
    const char *node = nodes.items[k];
    if (under_added(node, added)) continue;
    char *base_path = canonical_path_of(base_canon, node);
    if (base_path == NULL) continue;
    const char *was = spec_document_headline(base, base_path);
    if (was == NULL) was = "";
    for (size_t i = 0; i < n; i++) {
      char *path = canonical_path_of(&copy_canon[i], node);
      if (path == NULL) continue;
      const char *now = spec_document_headline(copies[i].document, path);
      if (now == NULL) now = "";
      if (strcmp(now, was) != 0) {
        add_structural(structural, node, "Headline changed", was, now,
                       copies[i].member.member_id);
      }
      free(path);
    }
    free(base_path);
  }
  som_strlist_free(&nodes);
}

/* An item a copy added, as the structure phase collects it. */
typedef struct {
  char *id;
  size_t copy;
  char *anchor; /* the base item it follows in the copy; NULL for none */
  SomStrList members;
  char *signature;
} Addition;

/* The structure phase: items the copies added are added (attributed to every
 * copy that added them alike); items removed or moved, and changed headlines,
 * become structural conflicts. The canonical paths of the added items go into
 * `added` (initialised here). */
static void merge_structure(SpecDocument *merged, const SpecDocument *base,
                            const SpecReviewedDocument *copies, size_t n,
                            const SpecReflection *refl, const SpecModel *model,
                            MergeContext *ctx, SomStrList *added) {
  som_strlist_init(added);
  CanonicalPaths base_canon;
  canonical_init(&base_canon, base, refl);
  CanonicalPaths *copy_canon = calloc(n ? n : 1, sizeof(CanonicalPaths));
  for (size_t i = 0; i < n; i++)
    canonical_init(&copy_canon[i], copies[i].document, refl);
  Structurals structural;
  memset(&structural, 0, sizeof(structural));
  SomStrList addition_nodes;
  som_strlist_init(&addition_nodes);
  SomStrList *addition_members = NULL;
  size_t addition_cap = 0;
  /* Every list, canonical, by depth and then byte order. */
  SomStrList lists, paths;
  som_strlist_init(&lists);
  spec_document_list_paths(base, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    char *c = canonical_of(&base_canon, paths.items[i]);
    if (!som_strlist_contains(&lists, c))
      som_strlist_push(&lists, c);
    else
      free(c);
  }
  som_strlist_free(&paths);
  for (size_t i = 0; i < n; i++) {
    spec_document_list_paths(copies[i].document, &paths);
    for (size_t k = 0; k < paths.len; k++) {
      char *c = canonical_of(&copy_canon[i], paths.items[k]);
      if (!som_strlist_contains(&lists, c))
        som_strlist_push(&lists, c);
      else
        free(c);
    }
    som_strlist_free(&paths);
  }
  cmp_sort(&lists);
  for (size_t i = 1; i < lists.len; i++) {
    char *x = lists.items[i];
    size_t j = i;
    size_t hx = 0;
    for (const char *s = x; *s; s++) hx += *s == '#';
    for (;;) {
      if (j == 0) break;
      size_t hy = 0;
      for (const char *s = lists.items[j - 1]; *s; s++) hy += *s == '#';
      if (hy <= hx) break;
      lists.items[j] = lists.items[j - 1];
      j--;
    }
    lists.items[j] = x;
  }
  for (size_t li = 0; li < lists.len; li++) {
    const char *list = lists.items[li];
    if (under_added(list, added)) continue;
    char *base_path = canonical_path_of(&base_canon, list);
    if (base_path == NULL) continue;
    SomStrList base_ids;
    canonical_item_ids(&base_canon, base_path, &base_ids);
    Addition *groups = NULL;
    size_t groups_len = 0, groups_cap = 0;
    for (size_t i = 0; i < n; i++) {
      char *copy_path = canonical_path_of(&copy_canon[i], list);
      if (copy_path == NULL) continue;
      const SomStrList *items =
          spec_document_list_items(copies[i].document, copy_path);
      SomStrList ids;
      canonical_item_ids(&copy_canon[i], copy_path, &ids);
      const char *member = copies[i].member.member_id;
      for (size_t k = 0; k < ids.len; k++) {
        if (som_strlist_contains(&base_ids, ids.items[k])) continue;
        char *signature = item_signature(copies[i].document, items->items[k]);
        Addition *g = NULL;
        for (size_t x = 0; x < groups_len && g == NULL; x++) {
          if (strcmp(groups[x].id, ids.items[k]) == 0) g = &groups[x];
        }
        if (g == NULL) {
          Addition a;
          a.id = som_strdup(ids.items[k]);
          a.copy = i;
          a.anchor = NULL;
          for (size_t q = k; q-- > 0;) {
            if (som_strlist_contains(&base_ids, ids.items[q])) {
              a.anchor = som_strdup(ids.items[q]);
              break;
            }
          }
          som_strlist_init(&a.members);
          som_strlist_push_copy(&a.members, member);
          a.signature = signature;
          signature = NULL;
          PUSH(groups, groups_len, groups_cap, a);
        } else if (strcmp(g->signature, signature) == 0) {
          som_strlist_push_copy(&g->members, member);
        }
        free(signature);
      }
      for (size_t k = 0; k < base_ids.len; k++) {
        if (som_strlist_contains(&ids, base_ids.items[k])) continue;
        char *node = fmt("%s#%s", list, base_ids.items[k]);
        add_structural(&structural, node, "Item removed", "kept", "removed",
                       member);
        free(node);
      }
      SomStrList kept_order, kept_ids;
      som_strlist_init(&kept_order);
      som_strlist_init(&kept_ids);
      for (size_t k = 0; k < base_ids.len; k++) {
        if (som_strlist_contains(&ids, base_ids.items[k]))
          som_strlist_push_copy(&kept_order, base_ids.items[k]);
      }
      for (size_t k = 0; k < ids.len; k++) {
        if (som_strlist_contains(&base_ids, ids.items[k]))
          som_strlist_push_copy(&kept_ids, ids.items[k]);
      }
      unsigned char *moved = moved_flags(&kept_order, &kept_ids);
      for (size_t k = 0; k < kept_ids.len; k++) {
        if (!moved[k]) continue;
        const char *id = kept_ids.items[k];
        char *node = fmt("%s#%s", list, id);
        char *was = fmt("position %lld", index_of(&base_ids, id) + 1);
        char *now = fmt("moved to position %lld", index_of(&ids, id) + 1);
        add_structural(&structural, node, "Item moved", was, now, member);
        free(now);
        free(was);
        free(node);
      }
      free(moved);
      som_strlist_free(&kept_order);
      som_strlist_free(&kept_ids);
      som_strlist_free(&ids);
      free(copy_path);
    }
    for (size_t gi = 0; gi < groups_len; gi++) {
      const Addition *g = &groups[gi];
      CanonicalPaths merged_canon;
      canonical_init(&merged_canon, merged, refl);
      char *list_path = canonical_path_of(&merged_canon, list);
      SomStrList merged_ids;
      canonical_item_ids(&merged_canon, list_path, &merged_ids);
      canonical_free(&merged_canon);
      size_t at =
          g->anchor ? (size_t)(index_of(&merged_ids, g->anchor) + 1) : 0;
      while (at < merged_ids.len &&
             !som_strlist_contains(&base_ids, merged_ids.items[at]))
        at++;
      char *item = spec_document_add_list_item_with_section_id(
          merged, list_path, g->id, NULL);
      if (at < merged_ids.len) {
        SpecListItemMove mv;
        if (spec_document_move_list_item(merged, model, item, (long long)at,
                                         NULL, &mv, NULL)) {
          free(item);
          item = som_strdup(mv.path);
        }
        spec_list_item_move_free(&mv);
      }
      char *node = fmt("%s#%s", list, g->id);
      char *src_path = canonical_path_of(&copy_canon[g->copy], node);
      copy_item(copies[g->copy].document, src_path, merged, item, &g->members,
                refl);
      free(src_path);
      som_strlist_push_copy(added, node);
      if (addition_nodes.len == addition_cap) {
        addition_cap = addition_cap ? addition_cap * 2 : 4;
        addition_members =
            realloc(addition_members, addition_cap * sizeof(SomStrList));
      }
      som_strlist_copy(&addition_members[addition_nodes.len], &g->members);
      som_strlist_push(&addition_nodes, node);
      free(item);
      som_strlist_free(&merged_ids);
      free(list_path);
    }
    for (size_t gi = 0; gi < groups_len; gi++) {
      free(groups[gi].id);
      free(groups[gi].anchor);
      som_strlist_free(&groups[gi].members);
      free(groups[gi].signature);
    }
    free(groups);
    som_strlist_free(&base_ids);
    free(base_path);
  }
  headline_changes(base, &base_canon, copies, n, copy_canon, added,
                   &structural);
  CanonicalPaths merged_canon;
  canonical_init(&merged_canon, merged, refl);
  SpecReviewMergeReport *rep = ctx->report;
  for (size_t i = 0; i < addition_nodes.len; i++) {
    SpecMergeAddition a = {
        canonical_path_of(&merged_canon, addition_nodes.items[i]),
        addition_members[i]};
    PUSH(rep->additions, rep->additions_len, rep->additions_cap, a);
  }
  for (size_t i = 0; i < structural.len; i++) {
    const Structural *s = &structural.items[i];
    char *node = canonical_path_of(&merged_canon, s->node);
    char *home = block_home(merged, refl, node, 1);
    char *block =
        ctx_conflict(ctx, s->topic, node, s->base, &s->groups, node, NULL, -1);
    if (home != NULL) {
      char *key = content_key(home);
      ctx_append(ctx, key, block);
      free(key);
    }
    free(block);
    free(home);
    free(node);
  }
  canonical_free(&merged_canon);
  free(addition_members);
  som_strlist_free(&addition_nodes);
  structurals_free(&structural);
  som_strlist_free(&lists);
  for (size_t i = 0; i < n; i++) canonical_free(&copy_canon[i]);
  free(copy_canon);
  canonical_free(&base_canon);
}

/* One value node to merge: (content 0 / field 1, canonical path, field). */
typedef struct {
  int is_field;
  char *node;
  char *field;
} ValueNode;

static int value_node_cmp(const ValueNode *a, const ValueNode *b) {
  if (a->is_field != b->is_field) return a->is_field - b->is_field;
  int c = strcmp(a->node, b->node);
  if (c != 0) return c;
  return strcmp(a->field ? a->field : "", b->field ? b->field : "");
}

typedef struct {
  ValueNode *items;
  size_t len, cap;
} ValueNodes;

static void nodes_add(ValueNodes *ns, int is_field, char *node,
                      const char *field) {
  ValueNode x = {is_field, node, dup_or_null(field)};
  for (size_t i = 0; i < ns->len; i++) {
    if (value_node_cmp(&ns->items[i], &x) == 0) {
      free(x.node);
      free(x.field);
      return;
    }
  }
  PUSH(ns->items, ns->len, ns->cap, x);
}

static void nodes_collect(ValueNodes *ns, const SpecDocument *doc,
                          CanonicalPaths *canon) {
  SomStrList paths;
  spec_document_content_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++)
    nodes_add(ns, 0, canonical_of(canon, paths.items[i]), NULL);
  som_strlist_free(&paths);
  spec_document_form_paths(doc, &paths);
  for (size_t i = 0; i < paths.len; i++) {
    SomStrList fields;
    spec_document_form_field_names(doc, paths.items[i], &fields);
    for (size_t f = 0; f < fields.len; f++) {
      nodes_add(ns, 1, canonical_of(canon, paths.items[i]), fields.items[f]);
    }
    som_strlist_free(&fields);
  }
  som_strlist_free(&paths);
}

static const char *read_value(const SpecDocument *doc, const char *path,
                              const char *field) {
  const char *v = field == NULL ? spec_document_content(doc, path)
                                : spec_document_form_field(doc, path, field);
  return v ? v : "";
}

/* The values to merge into `*out` (owned array, `*out_len` entries): every
 * value of the base and of the copies, items the copies added aside, located
 * in the merged document; in its document order (content first, then form
 * fields, each by path). */
static void som_values(const SpecDocument *merged, const SpecDocument *base,
                       const SpecReviewedDocument *copies, size_t n,
                       const SomStrList *added, const SpecReflection *refl,
                       MergeValue **out, size_t *out_len) {
  CanonicalPaths base_canon, merged_canon;
  canonical_init(&base_canon, base, refl);
  canonical_init(&merged_canon, merged, refl);
  CanonicalPaths *copy_canon = calloc(n ? n : 1, sizeof(CanonicalPaths));
  for (size_t i = 0; i < n; i++)
    canonical_init(&copy_canon[i], copies[i].document, refl);
  ValueNodes nodes;
  memset(&nodes, 0, sizeof(nodes));
  nodes_collect(&nodes, base, &base_canon);
  for (size_t i = 0; i < n; i++)
    nodes_collect(&nodes, copies[i].document, &copy_canon[i]);
  MergeValue *values = NULL;
  size_t len = 0, cap = 0;
  for (size_t k = 0; k < nodes.len; k++) {
    const ValueNode *nd = &nodes.items[k];
    if (under_added(nd->node, added)) continue;
    char *base_path = canonical_path_of(&base_canon, nd->node);
    if (base_path == NULL) continue;
    MergeValue v;
    memset(&v, 0, sizeof(v));
    v.path = canonical_path_of(&merged_canon, nd->node);
    v.field = dup_or_null(nd->field);
    v.base = som_strdup(read_value(base, base_path, nd->field));
    v.copies_len = n;
    v.copies = calloc(n ? n : 1, sizeof(char *));
    for (size_t i = 0; i < n; i++) {
      char *p = canonical_path_of(&copy_canon[i], nd->node);
      if (p != NULL)
        v.copies[i] = som_strdup(read_value(copies[i].document, p, nd->field));
      free(p);
    }
    int text = is_text_value(refl, v.path, v.field);
    v.typed = !text;
    if (v.field != NULL) {
      v.conflict_home = content_key(v.path);
    } else if (!text) {
      char *home = block_home(merged, refl, v.path, 0);
      if (home != NULL) v.conflict_home = content_key(home);
      free(home);
    }
    free(base_path);
    PUSH(values, len, cap, v);
  }
  /* The merged path decides the order (a stable insertion sort). */
  for (size_t i = 1; i < len; i++) {
    MergeValue x = values[i];
    size_t j = i;
    while (j > 0) {
      const MergeValue *y = &values[j - 1];
      int c = (y->field != NULL) - (x.field != NULL);
      if (c == 0) c = strcmp(y->path, x.path);
      if (c == 0) c = strcmp(y->field ? y->field : "", x.field ? x.field : "");
      if (c <= 0) break;
      values[j] = values[j - 1];
      j--;
    }
    values[j] = x;
  }
  for (size_t k = 0; k < nodes.len; k++) {
    free(nodes.items[k].node);
    free(nodes.items[k].field);
  }
  free(nodes.items);
  for (size_t i = 0; i < n; i++) canonical_free(&copy_canon[i]);
  free(copy_canon);
  canonical_free(&merged_canon);
  canonical_free(&base_canon);
  *out = values;
  *out_len = len;
}

/* The class field of `cls` named `name` with kind `kind`, or NULL. */
static const SpecField *class_field(const SpecClass *cls, const char *name,
                                    const char *kind) {
  const SpecField *f = cls == NULL ? NULL : spec_class_field_named(cls, name);
  return f != NULL && strcmp(f->kind, kind) == 0 ? f : NULL;
}

/* The model classes the revision entry is written with (`tom_specs_model`'s
 * document front matter). */
#define REVISION_ENTRY "RevisionEntry"
#define DOCUMENT_HEADER "DocumentHeader"

static int all_digits_n(const char *s, size_t n) {
  if (n == 0) return 0;
  for (size_t i = 0; i < n; i++) {
    if (s[i] < '0' || s[i] > '9') return 0;
  }
  return 1;
}

/* The next minor of a `major.minor[.patch]` version; `0.1.0` for anything
 * else. Owned. */
static char *next_minor(const char *version) {
  char *t = trim_text(version ? version : "");
  SomStrList parts;
  split_on(t, '.', &parts);
  free(t);
  int ok = parts.len == 2 || parts.len == 3;
  for (size_t i = 0; ok && i < parts.len; i++) {
    ok = all_digits_n(parts.items[i], strlen(parts.items[i]));
  }
  char *out = !ok ? som_strdup("0.1.0")
                  : fmt("%s.%lld%s", parts.items[0],
                        strtoll(parts.items[1], NULL, 10) + 1,
                        parts.len == 3 ? ".0" : "");
  som_strlist_free(&parts);
  return out;
}

/* The month and day of an ISO 8601 date; 0 when it is not one. */
static int month_day(const char *date, long long *month, long long *day) {
  if (date == NULL || strlen(date) < 10 || !all_digits_n(date, 4) ||
      date[4] != '-' || !all_digits_n(date + 5, 2) || date[7] != '-' ||
      !all_digits_n(date + 8, 2)) {
    return 0;
  }
  *month = (date[5] - '0') * 10 + (date[6] - '0');
  *day = (date[8] - '0') * 10 + (date[9] - '0');
  return 1;
}

/* Adds an item with a generated id to the list `field` at `list`, and returns
 * its path (owned). */
static char *add_generated_item(SpecDocument *doc, const char *list,
                                const SpecField *field, long long month,
                                long long day) {
  char *pattern = field->section_id_pattern && field->section_id_pattern[0]
                      ? som_strdup(field->section_id_pattern)
                      : fmt("%s-xxx", field->name);
  SomStrList existing;
  spec_document_list_item_section_ids(doc, list, &existing);
  char *id = spec_generate_list_item_section_id(pattern, month, day, &existing);
  char *item = spec_document_add_list_item_with_section_id(doc, list, id, NULL);
  free(id);
  som_strlist_free(&existing);
  free(pattern);
  return item;
}

/* Writes one reviewer record into the list `field` at `list`. */
static void add_reviewer_record(SpecDocument *doc, const SpecModel *model,
                                const char *list, const SpecField *field,
                                const SpecReviewMember *member, int guest,
                                long long month, long long day) {
  char *item = add_generated_item(doc, list, field, month, day);
  const SpecField *form =
      class_field(spec_model_class_named(model, field->element_type), "content",
                  SPEC_FIELD_KIND_FORM);
  if (form != NULL && item != NULL) {
    char *path = fmt("%s/%s", item, spec_reflection_field_segment(form));
    spec_document_set_form_field(doc, path, "memberId", member->member_id);
    spec_document_set_form_field(doc, path, "displayName",
                                 member->display_name);
    spec_document_set_form_field(doc, path, "role",
                                 member->role ? member->role : "");
    if (guest) spec_document_set_form_field(doc, path, "guest", "true");
    free(path);
  }
  free(item);
}

/* Appends the draft revision entry when the root has a revision history: the
 * next minor version, the date and author, the team the round started with and
 * every reviewer who returned a copy, guests marked. 0 (filling `*err`) when
 * the date is not an ISO 8601 date. */
static int add_revision_entry(SpecDocument *merged, const char *root,
                              const SpecReviewMember *copies, size_t n,
                              const SpecReviewMergeOptions *options,
                              const SpecReflection *refl,
                              const SpecModel *model, MergeContext *ctx,
                              SpecReviewMergeError *err) {
  const SpecRoot *root_spec = spec_reflection_root_for_segment(refl, root);
  const SpecClass *root_class =
      root_spec == NULL ? NULL : spec_model_class_named(model, root_spec->type);
  if (root_class == NULL) return 1;
  const SpecField *history = NULL, *header = NULL;
  for (size_t i = 0; i < root_class->fields_len; i++) {
    const SpecField *f = &root_class->fields[i];
    if (history == NULL && strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0 &&
        f->element_type != NULL &&
        strcmp(f->element_type, REVISION_ENTRY) == 0) {
      history = f;
    }
    if (header == NULL && f->type != NULL &&
        strcmp(f->type, DOCUMENT_HEADER) == 0) {
      header = f;
    }
  }
  if (history == NULL) return 1;
  long long month, day;
  if (!month_day(options->date, &month, &day)) {
    set_error(err, fmt("options.date \"%s\" is not an ISO 8601 date",
                       options->date ? options->date : ""));
    return 0;
  }
  const SpecField *header_form =
      header ? class_field(spec_model_class_named(model, DOCUMENT_HEADER),
                           "content", SPEC_FIELD_KIND_FORM)
             : NULL;
  const char *current = NULL;
  if (header && header_form) {
    char *path = fmt("%s/%s/%s", root, spec_reflection_field_segment(header),
                     spec_reflection_field_segment(header_form));
    current = spec_document_form_field(merged, path, "version");
    free(path);
  }
  char *version = next_minor(current);
  char *list = fmt("%s/%s", root, spec_reflection_field_segment(history));
  char *item = add_generated_item(merged, list, history, month, day);
  free(list);
  const SpecClass *entry = spec_model_class_named(model, REVISION_ENTRY);
  const SpecField *form = class_field(entry, "content", SPEC_FIELD_KIND_FORM);
  if (form != NULL) {
    char *path = fmt("%s/%s", item, spec_reflection_field_segment(form));
    spec_document_set_form_field(merged, path, "version", version);
    spec_document_set_form_field(merged, path, "date", options->date);
    spec_document_set_form_field(merged, path, "author",
                                 options->author ? options->author : "");
    free(path);
  }
  const char *names[2] = {"reviewTeam", "reviewers"};
  for (int r = 0; r < 2; r++) {
    const SpecField *rl = class_field(entry, names[r], SPEC_FIELD_KIND_LIST);
    if (rl == NULL) continue;
    const SpecReviewMember *members = r == 0 ? options->team : copies;
    size_t count = r == 0 ? options->team_len : n;
    char *path = fmt("%s/%s", item, spec_reflection_field_segment(rl));
    for (size_t i = 0; i < count; i++) {
      int guest = 0;
      if (r == 1) {
        guest = 1;
        for (size_t t = 0; t < options->team_len && guest; t++) {
          guest = strcmp(options->team[t].member_id, members[i].member_id) != 0;
        }
      }
      add_reviewer_record(merged, model, path, rl, &members[i], guest, month,
                          day);
    }
    free(path);
  }
  ctx->report->revision_path = item;
  ctx->report->revision_version = version;
  return 1;
}

/* The root segment of a document: the first segment of its paths. Owned, or
 * NULL. */
static char *root_of(const SpecDocument *doc, const SpecModel *model) {
  DocumentJson json;
  spec_document_to_json(doc, &json);
  const char *any = json.content.len     ? json.content.entries[0].key
                    : json.forms_len     ? json.forms[0].key
                    : json.lists_len     ? json.lists[0].key
                    : json.headlines.len ? json.headlines.entries[0].key
                                         : NULL;
  char *out = NULL;
  if (any != NULL) {
    const char *slash = strchr(any, '/');
    out = slash ? som_strdup_n(any, (size_t)(slash - any)) : som_strdup(any);
  } else if (model->roots_len > 0) {
    out = som_strdup(spec_reflection_root_segment(&model->roots[0]));
  }
  document_json_free(&json);
  return out;
}

int spec_review_merge_documents(
    const SpecModel *model, const SpecDocument *base,
    const SpecReviewedDocument *copies, size_t copies_len,
    const SpecReviewMergeOptions *options, SpecDocument *merged,
    SpecReviewMergeReport *report, SpecReviewMergeError *err) {
  spec_document_init(merged);
  spec_review_merge_report_init(report);
  SpecReflection refl = spec_reflection_make(model);
  if (!check_structure(base, "the base", &refl, err)) return 0;
  for (size_t i = 0; i < copies_len; i++) {
    char *what = fmt("the copy of %s", copies[i].member.member_id);
    int ok = check_structure(copies[i].document, what, &refl, err);
    free(what);
    if (!ok) return 0;
  }
  SomStrList base_values;
  som_value_texts(base, &base_values);
  SomStrList *copy_values =
      calloc(copies_len ? copies_len : 1, sizeof(SomStrList));
  SpecReviewMember *members =
      malloc((copies_len ? copies_len : 1) * sizeof(*members));
  for (size_t i = 0; i < copies_len; i++) {
    som_value_texts(copies[i].document, &copy_values[i]);
    members[i] = copies[i].member;
  }
  MergeContext ctx;
  ctx_init(&ctx, report, members, copies_len, &base_values);
  DocumentJson json;
  spec_document_to_json(base, &json);
  spec_document_load_json(merged, &json);
  document_json_free(&json);
  SomStrList added;
  merge_structure(merged, base, copies, copies_len, &refl, model, &ctx, &added);
  MergeValue *values = NULL;
  size_t values_len = 0;
  som_values(merged, base, copies, copies_len, &added, &refl, &values,
             &values_len);
  SomStrList keys;
  som_strlist_init(&keys);
  for (size_t k = 0; k < values_len; k++)
    som_strlist_push(&keys, value_key(&values[k]));
  char *root = root_of(base, model);
  char *home_key = NULL, *home_path = NULL;
  if (root != NULL) {
    const SpecRoot *root_spec = spec_reflection_root_for_segment(&refl, root);
    const SpecClass *root_class =
        root_spec == NULL ? NULL
                          : spec_model_class_named(model, root_spec->type);
    const SpecField *content =
        class_field(root_class, "content", SPEC_FIELD_KIND_CONTENT);
    if (content != NULL) {
      home_path = fmt("%s/%s", root, spec_reflection_field_segment(content));
      home_key = content_key(home_path);
    }
  }
  MergeTexts texts = {som_keys, som_get, som_set, merged};
  merge_texts(values, &keys, &texts, &base_values, copy_values, options,
              home_key, home_path, &ctx);
  int ok = root == NULL || add_revision_entry(merged, root, members, copies_len,
                                              options, &refl, model, &ctx, err);
  free(home_key);
  free(home_path);
  free(root);
  som_strlist_free(&keys);
  for (size_t k = 0; k < values_len; k++) merge_value_free(&values[k]);
  free(values);
  som_strlist_free(&added);
  ctx_free(&ctx);
  for (size_t i = 0; i < copies_len; i++) som_strlist_free(&copy_values[i]);
  free(copy_values);
  free(members);
  som_strlist_free(&base_values);
  if (!ok) {
    spec_document_free(merged);
    spec_document_init(merged);
    spec_review_merge_report_free(report);
    return 0;
  }
  return 1;
}
