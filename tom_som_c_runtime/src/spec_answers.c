/* spec_answers — the answers of a review round for a step folder (SOM
 * §11.9.7), a faithful port of the Dart `spec_answers.dart`. See the header
 * for the contract. */
#include "spec_answers.h"

#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "som_util.h"
#include "spec_document_markdown.h"

/* ---- small helpers ------------------------------------------------------ */

static char *dup_or_null(const char *s) { return s ? som_strdup(s) : NULL; }

/* Decodes one UTF-8 code point at `*s` (never past `end`), advancing it.
 * Malformed bytes decode to themselves, one byte at a time. */
static unsigned long next_cp(const unsigned char **s,
                             const unsigned char *end) {
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

/* `s.trim()`, Dart semantics. Owned. */
static char *dart_trim(const char *s) {
  size_t len = strlen(s);
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
  return any ? som_strdup_n(s + first, last - first) : som_strdup("");
}

/* `s.split('\n')` into `out` (initialised by the callee). */
static void split_lines(const char *s, SomStrList *out) {
  som_strlist_init(out);
  const char *st = s;
  for (const char *p = s;; p++) {
    if (*p == '\n' || *p == '\0') {
      som_strlist_push(out, som_strdup_n(st, (size_t)(p - st)));
      if (*p == '\0') break;
      st = p + 1;
    }
  }
}

/* ---- kinds, entries, counts, extracts ----------------------------------- */

const char *spec_answer_kind_name(SpecAnswerKind kind) {
  switch (kind) {
    case SPEC_ANSWER_ANSWERED:
      return "answered";
    case SPEC_ANSWER_OPEN:
      return "open";
    case SPEC_ANSWER_COMMENT:
      return "comment";
    case SPEC_ANSWER_MARK:
      return "mark";
  }
  return "answered";
}

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

static void put_int(SomBuf *b, int *first, const char *key, long long v) {
  put_key(b, first, key);
  som_buf_puti(b, v);
}

char *spec_answer_entry_to_json(const SpecAnswerEntry *e) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "kind", spec_answer_kind_name(e->kind));
  put_str(&b, &first, "id", e->id);
  put_str(&b, &first, "section", e->section);
  put_int(&b, &first, "line", (long long)e->line);
  put_str(&b, &first, "path", e->path);
  put_str(&b, &first, "field", e->field);
  put_str(&b, &first, "topic", e->topic);
  put_key(&b, &first, "combined");
  som_buf_puts(&b, e->combined ? "true" : "false");
  put_str(&b, &first, "text", e->text);
  put_str(&b, &first, "answer", e->answer);
  put_str(&b, &first, "author", e->author);
  put_str(&b, &first, "markKind",
          e->has_mark_kind ? spec_mark_kind_name(e->mark_kind) : NULL);
  put_str(&b, &first, "oldText", e->old_text);
  put_str(&b, &first, "newText", e->new_text);
  put_str(&b, &first, "comment", e->comment);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

char *spec_answer_counts_to_json(const SpecAnswerCounts *c) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_int(&b, &first, "answered", (long long)c->answered);
  put_int(&b, &first, "open", (long long)c->open);
  put_int(&b, &first, "comments", (long long)c->comments);
  put_int(&b, &first, "marks", (long long)c->marks);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

static void entry_free(SpecAnswerEntry *e) {
  free(e->id);
  free(e->section);
  free(e->path);
  free(e->field);
  free(e->topic);
  free(e->text);
  free(e->answer);
  free(e->author);
  free(e->old_text);
  free(e->new_text);
  free(e->comment);
  memset(e, 0, sizeof(*e));
}

void spec_answer_extract_free(SpecAnswerExtract *x) {
  for (size_t i = 0; i < x->entries_len; i++) entry_free(&x->entries[i]);
  free(x->entries);
  free(x->label);
  free(x->qualifier);
  memset(x, 0, sizeof(*x));
}

SpecAnswerCounts spec_answer_extract_counts(const SpecAnswerExtract *x) {
  SpecAnswerCounts c = {0, 0, 0, 0};
  for (size_t i = 0; i < x->entries_len; i++) {
    switch (x->entries[i].kind) {
      case SPEC_ANSWER_ANSWERED:
        c.answered++;
        break;
      case SPEC_ANSWER_OPEN:
        c.open++;
        break;
      case SPEC_ANSWER_COMMENT:
        c.comments++;
        break;
      case SPEC_ANSWER_MARK:
        c.marks++;
        break;
    }
  }
  return c;
}

char *spec_answer_extract_to_json(const SpecAnswerExtract *x) {
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  som_buf_putc(&b, '{');
  put_str(&b, &first, "label", x->label);
  put_str(&b, &first, "qualifier", x->qualifier);
  put_key(&b, &first, "entries");
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < x->entries_len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *e = spec_answer_entry_to_json(&x->entries[i]);
    som_buf_puts(&b, e);
    free(e);
  }
  som_buf_putc(&b, ']');
  put_key(&b, &first, "counts");
  SpecAnswerCounts c = spec_answer_extract_counts(x);
  char *cj = spec_answer_counts_to_json(&c);
  som_buf_puts(&b, cj);
  free(cj);
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- extraction ---------------------------------------------------------- */

/* The rendition the extraction locates annotations in. */
typedef struct {
  SpecMarkdownRendition rendition;
  SomStrList lines;
  char **chains; /* per 1-based line: the heading's chain, or NULL */
  const char *qualifier;
  unsigned char *claimed; /* per 1-based line */
} Locator;

/* `^(#+) <!--\[([^\]]+)\]-->`: writes the level and the id bounds. */
static int match_heading(const char *s, size_t *level, const char **id,
                         size_t *id_len) {
  size_t n = 0;
  while (s[n] == '#') n++;
  if (n == 0) return 0;
  const char *p = s + n;
  if (strncmp(p, " <!--[", 6) != 0) return 0;
  p += 6;
  const char *st = p;
  while (*p != '\0' && *p != ']') p++;
  if (p == st || strncmp(p, "]-->", 4) != 0) return 0;
  *level = n;
  *id = st;
  *id_len = (size_t)(p - st);
  return 1;
}

static void build_chains(Locator *lc) {
  size_t n = lc->lines.len;
  lc->chains = (char **)calloc(n + 2, sizeof(char *));
  size_t *levels = (size_t *)malloc((n + 1) * sizeof(size_t));
  SomStrList ids;
  som_strlist_init(&ids);
  for (size_t i = 0; i < n; i++) {
    size_t level, id_len;
    const char *id;
    if (!match_heading(lc->lines.items[i], &level, &id, &id_len)) continue;
    while (ids.len > 0 && levels[ids.len - 1] >= level) {
      som_strlist_remove_at(&ids, ids.len - 1);
    }
    levels[ids.len] = level;
    som_strlist_push(&ids, som_strdup_n(id, id_len));
    lc->chains[i + 1] = som_strlist_join(&ids, " > ");
  }
  som_strlist_free(&ids);
  free(levels);
}

/* The heading line of a value: the heading whose path is the longest prefix
 * of the value's path (on equal length, the first); 0 when none. */
static size_t heading_line(const Locator *lc, const char *value_path) {
  size_t best = 0;
  long long best_len = -1;
  size_t vlen = strlen(value_path);
  for (size_t i = 0; i < lc->rendition.headings_len; i++) {
    const char *hp = lc->rendition.headings[i].path;
    size_t hl = strlen(hp);
    int match = strcmp(value_path, hp) == 0 ||
                (vlen > hl && strncmp(value_path, hp, hl) == 0 &&
                 value_path[hl] == '/');
    if (match && (long long)hl > best_len) {
      best = (size_t)lc->rendition.headings[i].line;
      best_len = (long long)hl;
    }
  }
  return best;
}

static const char *chain_at(const Locator *lc, size_t line) {
  for (size_t l = line; l >= 1; l--) {
    if (l <= lc->lines.len && lc->chains[l] != NULL) return lc->chains[l];
  }
  return lc->qualifier;
}

/* The rendition line of an annotation: the first unclaimed line after the
 * value's heading whose trimmed text is the annotation's first line. A form
 * field's first line renders behind its label (`Owner: …`). */
static size_t locate(Locator *lc, const char *value_path, const char *field,
                     size_t value_line, const char *first_line) {
  size_t h = heading_line(lc, value_path);
  char *want = dart_trim(first_line);
  char *labelled = NULL;
  if (field != NULL && field[0] != '\0' && value_line == 0) {
    SomBuf b;
    som_buf_init(&b);
    char c0 = field[0];
    if (c0 >= 'a' && c0 <= 'z') c0 = (char)(c0 - 'a' + 'A');
    som_buf_putc(&b, c0);
    som_buf_puts(&b, field + 1);
    som_buf_puts(&b, ": ");
    som_buf_puts(&b, want);
    char *raw = som_buf_take(&b);
    labelled = dart_trim(raw);
    free(raw);
  }
  size_t found = 0;
  for (size_t i = h; i < lc->lines.len; i++) {
    size_t l = i + 1;
    if (l <= h || lc->claimed[l]) continue;
    char *t = dart_trim(lc->lines.items[i]);
    int hit = strcmp(t, want) == 0 ||
              (labelled != NULL && strcmp(t, labelled) == 0);
    free(t);
    if (hit) {
      lc->claimed[l] = 1;
      found = l;
      break;
    }
  }
  free(want);
  free(labelled);
  if (found != 0) return found;
  return h == 0 ? 1 : h;
}

static int in_scope(const char *path, const char *p) {
  if (path == NULL) return 1;
  size_t n = strlen(path);
  return strcmp(p, path) == 0 || (strncmp(p, path, n) == 0 && p[n] == '/');
}

typedef struct {
  SpecAnswerEntry *items;
  size_t len, cap;
} EntryVec;

static SpecAnswerEntry *entry_push(EntryVec *v) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 8;
    v->items = (SpecAnswerEntry *)realloc(v->items,
                                          v->cap * sizeof(SpecAnswerEntry));
  }
  SpecAnswerEntry *e = &v->items[v->len++];
  memset(e, 0, sizeof(*e));
  return e;
}

int spec_extract_answers(const SpecModel *model, SpecDocument *doc,
                         const char *label, const char *path,
                         SpecAnswerExtract *out, char **err) {
  memset(out, 0, sizeof(*out));
  if (err) *err = NULL;
  if (model->roots_len == 0) {
    if (err) *err = som_strdup("the model has no roots");
    return 0;
  }
  const SpecRoot *root = &model->roots[0];
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *r = &model->roots[i];
    const char *seg = (r->section_id != NULL && r->section_id[0] != '\0')
                          ? r->section_id
                          : r->type;
    if (spec_document_has_values_under(doc, seg)) {
      root = r;
      break;
    }
  }
  const char *qualifier =
      (root->section_id != NULL && root->section_id[0] != '\0')
          ? root->section_id
          : root->type;

  Locator lc;
  memset(&lc, 0, sizeof(lc));
  if (!spec_markdown_export_root_with_map(model, doc, root, &lc.rendition,
                                          err)) {
    spec_markdown_rendition_free(&lc.rendition);
    return 0;
  }
  lc.qualifier = qualifier;
  split_lines(lc.rendition.markdown, &lc.lines);
  build_chains(&lc);
  lc.claimed = (unsigned char *)calloc(lc.lines.len + 2, 1);

  SpecReviewAnnotations api = spec_review_annotations_make(doc, NULL);
  /* `list` and `list_marks` give the marks in the same order. */
  SpecMarkEntryList marks;
  spec_review_annotations_list_marks(&api, NULL, &marks);
  size_t mark_index = 0;
  SpecReviewAnnotationList list;
  spec_review_annotations_list(&api, &list);

  EntryVec ev = {NULL, 0, 0};
  for (size_t k = 0; k < list.len; k++) {
    const SpecReviewAnnotation *a = &list.items[k];
    /* Every mark consumes its listing entry before the scope check, so marks
     * in a subtree keep their document-wide `M-<n>` ids. */
    const SpecMarkEntry *m = NULL;
    if (a->kind == SPEC_REVIEW_ANNOTATION_MARK) {
      m = mark_index < marks.len ? &marks.items[mark_index] : NULL;
      mark_index++;
    }
    if (!in_scope(path, a->path)) continue;
    const char *value = a->field == NULL
                            ? spec_document_content(doc, a->path)
                            : spec_document_form_field(doc, a->path, a->field);
    if (value == NULL) value = "";
    SomStrList vlines;
    split_lines(value, &vlines);
    const char *first = a->line < vlines.len ? vlines.items[a->line] : "";
    switch (a->kind) {
      case SPEC_REVIEW_ANNOTATION_QUESTION: {
        size_t line = locate(&lc, a->path, a->field, a->line, first);
        SpecAnswerEntry *e = entry_push(&ev);
        e->kind = spec_review_annotation_is_open(a) ? SPEC_ANSWER_OPEN
                                                    : SPEC_ANSWER_ANSWERED;
        e->id = dup_or_null(a->id);
        e->section = som_strdup(chain_at(&lc, line));
        e->line = line;
        e->path = som_strdup(a->path);
        e->field = dup_or_null(a->field);
        e->topic = dup_or_null(a->topic);
        e->combined = a->combined != 0;
        e->text = som_strdup(a->text ? a->text : "");
        e->answer = som_strdup(a->answer ? a->answer : "");
        break;
      }
      case SPEC_REVIEW_ANNOTATION_COMMENT: {
        size_t line = locate(&lc, a->path, a->field, a->line, first);
        SpecAnswerEntry *e = entry_push(&ev);
        e->kind = SPEC_ANSWER_COMMENT;
        e->id = dup_or_null(a->id);
        e->section = som_strdup(chain_at(&lc, line));
        e->line = line;
        e->path = som_strdup(a->path);
        e->field = dup_or_null(a->field);
        e->text = som_strdup(a->text ? a->text : "");
        e->answer = som_strdup("");
        e->author = dup_or_null(a->author);
        break;
      }
      case SPEC_REVIEW_ANNOTATION_MARK: {
        size_t line = locate(&lc, a->path, a->field, a->line, first);
        /* A line holding several marks is found once; later marks on it
         * share the line. */
        lc.claimed[line] = 0;
        SpecAnswerEntry *e = entry_push(&ev);
        e->kind = SPEC_ANSWER_MARK;
        e->id = dup_or_null(m ? m->id : NULL);
        e->section = som_strdup(chain_at(&lc, line));
        e->line = line;
        e->path = som_strdup(a->path);
        e->field = dup_or_null(a->field);
        e->text = som_strdup(m && m->markup ? m->markup : "");
        e->answer = som_strdup("");
        e->has_mark_kind = 1;
        e->mark_kind = a->mark_kind;
        e->old_text = dup_or_null(m ? m->old_text : NULL);
        e->new_text = dup_or_null(m ? m->new_text : NULL);
        e->comment = dup_or_null(a->comment);
        break;
      }
    }
    som_strlist_free(&vlines);
  }

  /* Rendition order: by line; entries on one line keep their order (a
   * stable insertion sort). */
  for (size_t i = 1; i < ev.len; i++) {
    SpecAnswerEntry tmp = ev.items[i];
    size_t j = i;
    while (j > 0 && ev.items[j - 1].line > tmp.line) {
      ev.items[j] = ev.items[j - 1];
      j--;
    }
    ev.items[j] = tmp;
  }

  out->label = som_strdup(label ? label : "");
  out->qualifier = som_strdup(qualifier);
  out->entries = ev.items;
  out->entries_len = ev.len;

  spec_review_annotation_list_free(&list);
  spec_mark_entry_list_free(&marks);
  for (size_t i = 0; i <= lc.lines.len + 1; i++) free(lc.chains[i]);
  free(lc.chains);
  free(lc.claimed);
  som_strlist_free(&lc.lines);
  spec_markdown_rendition_free(&lc.rendition);
  return 1;
}

/* ---- rendering ----------------------------------------------------------- */

SpecAnswerRenderOptions spec_answer_render_options_default(void) {
  SpecAnswerRenderOptions o = {0, 0, "Answers"};
  return o;
}

/* A labelled value: `- **Label:** first line`, further lines indented two
 * spaces. Pushed as one item of `out`. */
static void put_item(SomStrList *out, const char *label, const char *value) {
  SomStrList ls;
  split_lines(value, &ls);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "- **");
  som_buf_puts(&b, label);
  som_buf_puts(&b, ":**");
  if (ls.items[0][0] != '\0') {
    som_buf_putc(&b, ' ');
    som_buf_puts(&b, ls.items[0]);
  }
  for (size_t i = 1; i < ls.len; i++) {
    if (ls.items[i][0] == '\0') {
      som_buf_putc(&b, '\n');
    } else {
      som_buf_puts(&b, "\n  ");
      som_buf_puts(&b, ls.items[i]);
    }
  }
  som_strlist_free(&ls);
  som_strlist_push(out, som_buf_take(&b));
}

/* `prefix` + `value` + `suffix`, as an item. */
static void put_item_wrapped(SomStrList *out, const char *label,
                             const char *prefix, const char *value,
                             const char *suffix) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, prefix);
  som_buf_puts(&b, value);
  som_buf_puts(&b, suffix);
  char *v = som_buf_take(&b);
  put_item(out, label, v);
  free(v);
}

static void count_part(SomBuf *b, size_t n, const char *noun) {
  som_buf_puti(b, (long long)n);
  som_buf_putc(b, ' ');
  som_buf_puts(b, noun);
  if (n != 1) som_buf_putc(b, 's');
}

static char *count_line(const SpecAnswerCounts *c,
                        const SpecAnswerRenderOptions *o) {
  SomBuf b;
  som_buf_init(&b);
  count_part(&b, c->answered, "answered question");
  som_buf_puts(&b, ", ");
  count_part(&b, c->open, "open question");
  som_buf_puts(&b, ", ");
  count_part(&b, c->comments, "comment");
  if (o->include_marks) {
    som_buf_puts(&b, ", ");
    count_part(&b, c->marks, "inline mark");
  }
  som_buf_putc(&b, '.');
  return som_buf_take(&b);
}

static const char *str_or_null(const char *s) { return s ? s : "null"; }

static char *entry_heading(const SpecAnswerExtract *x,
                           const SpecAnswerEntry *e) {
  SomBuf b;
  som_buf_init(&b);
  switch (e->kind) {
    case SPEC_ANSWER_ANSWERED:
    case SPEC_ANSWER_OPEN:
      som_buf_puts(&b, str_or_null(e->id));
      som_buf_puts(&b, " \xE2\x80\x94 ");
      som_buf_puts(&b, str_or_null(e->topic));
      break;
    case SPEC_ANSWER_COMMENT:
      if (e->id == NULL) {
        som_buf_puts(&b, "Comment without id (line ");
        som_buf_puti(&b, (long long)e->line);
        som_buf_putc(&b, ')');
      } else {
        som_buf_puts(&b, x->qualifier);
        som_buf_putc(&b, ' ');
        som_buf_puts(&b, e->id);
      }
      break;
    case SPEC_ANSWER_MARK:
      som_buf_puts(&b, str_or_null(e->id));
      som_buf_puts(&b, " \xE2\x80\x94 ");
      som_buf_puts(&b, e->has_mark_kind ? spec_mark_kind_name(e->mark_kind)
                                        : "null");
      break;
  }
  return som_buf_take(&b);
}

static void render_section(SomStrList *out, const SpecAnswerExtract *x,
                           const char *heading, SpecAnswerKind kind) {
  som_strlist_push_copy(out, "");
  SomBuf hb;
  som_buf_init(&hb);
  som_buf_puts(&hb, "### ");
  som_buf_puts(&hb, heading);
  som_strlist_push(out, som_buf_take(&hb));
  size_t count = 0;
  for (size_t i = 0; i < x->entries_len; i++) {
    const SpecAnswerEntry *e = &x->entries[i];
    if (e->kind != kind) continue;
    count++;
    som_strlist_push_copy(out, "");
    char *eh = entry_heading(x, e);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "#### ");
    som_buf_puts(&b, eh);
    free(eh);
    som_strlist_push(out, som_buf_take(&b));
    som_strlist_push_copy(out, "");
    put_item_wrapped(out, "Section", "`", e->section, "`");
    char *ln = som_format_i64((long long)e->line);
    put_item(out, "Line", ln);
    free(ln);
    if (e->field != NULL) put_item_wrapped(out, "Field", "`", e->field, "`");
    switch (kind) {
      case SPEC_ANSWER_ANSWERED:
      case SPEC_ANSWER_OPEN:
        put_item(out, "Question", e->text);
        if (kind == SPEC_ANSWER_ANSWERED) put_item(out, "Answer", e->answer);
        break;
      case SPEC_ANSWER_COMMENT:
        if (e->author != NULL) put_item(out, "Author", e->author);
        put_item(out, "Comment", e->text);
        break;
      case SPEC_ANSWER_MARK:
        put_item_wrapped(out, "Markup", "`", e->text, "`");
        put_item(out, "Old", e->old_text ? e->old_text : "");
        put_item(out, "New", e->new_text ? e->new_text : "");
        if (e->comment != NULL) put_item(out, "Note", e->comment);
        break;
    }
  }
  if (count == 0) {
    som_strlist_push_copy(out, "");
    som_strlist_push_copy(out, "None.");
  }
}

char *spec_render_answers(const SpecAnswerExtract *extracts, size_t len,
                          const SpecAnswerRenderOptions *options) {
  SpecAnswerRenderOptions o =
      options ? *options : spec_answer_render_options_default();
  if (o.title == NULL) o.title = "Answers";
  SpecAnswerCounts total = {0, 0, 0, 0};
  for (size_t i = 0; i < len; i++) {
    SpecAnswerCounts c = spec_answer_extract_counts(&extracts[i]);
    total.answered += c.answered;
    total.open += c.open;
    total.comments += c.comments;
    total.marks += c.marks;
  }
  SomStrList out;
  som_strlist_init(&out);
  SomBuf tb;
  som_buf_init(&tb);
  som_buf_puts(&tb, "# ");
  som_buf_puts(&tb, o.title);
  som_strlist_push(&out, som_buf_take(&tb));
  som_strlist_push_copy(&out, "");
  som_strlist_push(&out, count_line(&total, &o));
  for (size_t i = 0; i < len; i++) {
    const SpecAnswerExtract *x = &extracts[i];
    som_strlist_push_copy(&out, "");
    SomBuf lb;
    som_buf_init(&lb);
    som_buf_puts(&lb, "## ");
    som_buf_puts(&lb, x->label);
    som_strlist_push(&out, som_buf_take(&lb));
    som_strlist_push_copy(&out, "");
    SpecAnswerCounts c = spec_answer_extract_counts(x);
    som_strlist_push(&out, count_line(&c, &o));
    render_section(&out, x, "Answered questions", SPEC_ANSWER_ANSWERED);
    render_section(&out, x, "Comments", SPEC_ANSWER_COMMENT);
    if (o.include_open) {
      render_section(&out, x, "Open questions", SPEC_ANSWER_OPEN);
    }
    if (o.include_marks) {
      render_section(&out, x, "Inline marks", SPEC_ANSWER_MARK);
    }
  }
  char *joined = som_strlist_join(&out, "\n");
  som_strlist_free(&out);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, joined);
  som_buf_putc(&b, '\n');
  free(joined);
  return som_buf_take(&b);
}
