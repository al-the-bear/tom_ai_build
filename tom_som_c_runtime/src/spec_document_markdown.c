#include "spec_document_markdown.h"

#include <stdlib.h>
#include <string.h>

#include "som_util.h"
#include "spec_paths.h"
#include "spec_reflection.h"

/* ======================================================================== */
/* small string helpers                                                      */
/* ======================================================================== */

static int is_md_ws(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n' || c == '\f' ||
         c == '\v';
}

/* Trims trailing markdown whitespace; returns owned copy. */
static char *trim_end_dup(const char *s) {
  size_t n = strlen(s);
  while (n > 0 && is_md_ws(s[n - 1])) {
    n--;
  }
  return som_strdup_n(s, n);
}

static char *trim_dup_md(const char *s) {
  size_t n = strlen(s);
  size_t start = 0;
  while (start < n && is_md_ws(s[start])) {
    start++;
  }
  while (n > start && is_md_ws(s[n - 1])) {
    n--;
  }
  return som_strdup_n(s + start, n - start);
}

/* First whitespace-delimited token of `s`, or NULL. Owned. */
static char *first_token(const char *s) {
  size_t i = 0;
  while (s[i] != '\0' && is_md_ws(s[i])) {
    i++;
  }
  if (s[i] == '\0') {
    return NULL;
  }
  size_t start = i;
  while (s[i] != '\0' && !is_md_ws(s[i])) {
    i++;
  }
  return som_strdup_n(s + start, i - start);
}

static size_t token_count(const char *s) {
  size_t count = 0, i = 0;
  while (s[i] != '\0') {
    while (s[i] != '\0' && is_md_ws(s[i])) {
      i++;
    }
    if (s[i] == '\0') {
      break;
    }
    count++;
    while (s[i] != '\0' && !is_md_ws(s[i])) {
      i++;
    }
  }
  return count;
}

static char *to_lower_dup(const char *s) {
  size_t n = strlen(s);
  char *out = (char *)malloc(n + 1);
  for (size_t i = 0; i < n; i++) {
    char c = s[i];
    out[i] = (c >= 'A' && c <= 'Z') ? (char)(c - 'A' + 'a') : c;
  }
  out[n] = '\0';
  return out;
}

/* Inserts `s` into a byte-sorted unique set. */
static void set_insert(SomStrList *set, const char *s) {
  size_t lo = 0, hi = set->len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(set->items[mid], s);
    if (cmp == 0) {
      return;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  /* grow + shift */
  if (set->len == set->cap) {
    set->cap = set->cap ? set->cap * 2 : 4;
    set->items = (char **)realloc(set->items, set->cap * sizeof(char *));
  }
  memmove(&set->items[lo + 1], &set->items[lo],
          (set->len - lo) * sizeof(char *));
  set->items[lo] = som_strdup(s);
  set->len++;
}

/* ======================================================================== */
/* line-pattern helpers (heading / field anchor / fence / item segment)      */
/* ======================================================================== */

/* Section path of a heading line (`#{1,6} <path> …`), or NULL. Owned. */
static char *heading_path(const char *line) {
  size_t hashes = 0;
  while (line[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0 || hashes > 6) {
    return NULL;
  }
  const char *rest = line + hashes;
  if (rest[0] == '\0' || !is_md_ws(rest[0])) {
    return NULL;
  }
  return first_token(rest);
}

/* Field name of a `<!-- field: name -->` anchor line, or NULL. Owned. */
static char *field_anchor(const char *line) {
  char *t = trim_dup_md(line);
  char *result = NULL;
  size_t tn = strlen(t);
  if (tn >= 7 && strncmp(t, "<!--", 4) == 0 &&
      strcmp(t + tn - 3, "-->") == 0) {
    char *inner = som_strdup_n(t + 4, tn - 4 - 3);
    char *inner_t = trim_dup_md(inner);
    free(inner);
    if (strncmp(inner_t, "field:", 6) == 0) {
      char *rest = trim_dup_md(inner_t + 6);
      if (token_count(rest) == 1) {
        char *tok = first_token(rest);
        if (tok != NULL && tok[0] != '\0') {
          result = tok;
        } else {
          free(tok);
        }
      }
      free(rest);
    }
    free(inner_t);
  }
  free(t);
  return result;
}

/* Fence length of a fence-opener line (3+ backticks), or 0. */
static size_t fence_open(const char *line) {
  size_t n = 0;
  while (line[n] == '`') {
    n++;
  }
  return n >= 3 ? n : 0;
}

/* Splits a list-item segment `<base>-<digits>` into base + number. Returns 1. */
static int item_seg(const char *seg, char **base, long long *num) {
  size_t n = strlen(seg);
  long dash = -1;
  for (size_t i = n; i > 0; i--) {
    if (seg[i - 1] == '-') {
      dash = (long)(i - 1);
      break;
    }
  }
  if (dash <= 0 || (size_t)dash == n - 1) {
    return 0;
  }
  const char *tail = seg + dash + 1;
  if (!som_is_all_digits(tail)) {
    return 0;
  }
  long long v;
  if (!som_parse_i64(tail, &v)) {
    return 0;
  }
  *base = som_strdup_n(seg, (size_t)dash);
  *num = v;
  return 1;
}

/* ======================================================================== */
/* fenced block rendering                                                    */
/* ======================================================================== */

/* Renders a fenced code block holding `value` verbatim (no trailing newline). */
static char *fence(const char *value, const char *info) {
  size_t max_run = 0, run = 0;
  for (size_t i = 0; value[i] != '\0'; i++) {
    if (value[i] == '`') {
      run++;
      if (run > max_run) {
        max_run = run;
      }
    } else {
      run = 0;
    }
  }
  size_t n = max_run + 1;
  if (n < 3) {
    n = 3;
  }
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < n; i++) {
    som_buf_putc(&b, '`');
  }
  som_buf_puts(&b, info != NULL ? info : "");
  som_buf_putc(&b, '\n');
  /* value.split('\n') each on its own line */
  size_t start = 0;
  size_t vlen = strlen(value);
  for (size_t i = 0;; i++) {
    if (i == vlen || value[i] == '\n') {
      som_buf_putn(&b, value + start, i - start);
      som_buf_putc(&b, '\n');
      if (i == vlen) {
        break;
      }
      start = i + 1;
    }
  }
  for (size_t i = 0; i < n; i++) {
    som_buf_putc(&b, '`');
  }
  return som_buf_take(&b);
}

static void writeln(SomBuf *b, const char *text) {
  som_buf_puts(b, text);
  som_buf_putc(b, '\n');
}

static void md_heading(SomBuf *b, size_t depth, const char *path,
                       const char *name) {
  size_t d = depth < 6 ? depth : 6;
  for (size_t i = 0; i < d; i++) {
    som_buf_putc(b, '#');
  }
  som_buf_putc(b, ' ');
  som_buf_puts(b, path);
  som_buf_puts(b, " \xE2\x80\x94 "); /* U+2014 em-dash */
  som_buf_puts(b, name);
  som_buf_putc(b, '\n');
}

/* ======================================================================== */
/* export                                                                    */
/* ======================================================================== */

static void export_class(SomBuf *b, const SpecModel *model,
                         const SpecDocument *doc, const SpecReflection *refl,
                         const SpecClass *cls, const char *base_path,
                         size_t depth, const SomStrList *seen_types);

char *spec_markdown_export_root(const SpecModel *model,
                                const SpecDocument *document,
                                const SpecRoot *root) {
  SpecReflection refl = spec_reflection_make(model);
  SomBuf b;
  som_buf_init(&b);
  const char *seg = spec_reflection_root_segment(root);
  char *seg_lower = to_lower_dup(seg);
  som_buf_puts(&b, "<!-- docspec: ");
  som_buf_puts(&b, seg_lower);
  som_buf_puts(&b, "/1 -->\n");
  free(seg_lower);
  som_buf_puts(&b, "# ");
  som_buf_puts(&b, seg);
  som_buf_puts(&b, " \xE2\x80\x94 ");
  som_buf_puts(&b, root->title != NULL ? root->title : "");
  som_buf_putc(&b, '\n');
  if (root->description != NULL) {
    char *desc = trim_dup_md(root->description);
    if (desc[0] != '\0') {
      writeln(&b, "");
      writeln(&b, desc);
    }
    free(desc);
  }
  const SpecClass *cls = spec_model_class_named(model, root->type);
  if (cls != NULL) {
    SomStrList seen;
    som_strlist_init(&seen);
    set_insert(&seen, root->type);
    export_class(&b, model, document, &refl, cls, seg, 2, &seen);
    som_strlist_free(&seen);
  }
  return som_buf_take(&b);
}

static void export_class(SomBuf *b, const SpecModel *model,
                         const SpecDocument *doc, const SpecReflection *refl,
                         const SpecClass *cls, const char *base_path,
                         size_t depth, const SomStrList *seen_types) {
  (void)refl;
  for (size_t fi = 0; fi < cls->fields_len; fi++) {
    const SpecField *field = &cls->fields[fi];
    char *path = spec_path_join(base_path, spec_reflection_field_segment(field));
    if (!spec_document_has_values_under(doc, path)) {
      free(path);
      continue;
    }
    const char *kind = field->kind;
    if (strcmp(kind, SPEC_FIELD_KIND_CONTENT) == 0 ||
        strcmp(kind, SPEC_FIELD_KIND_SCALAR) == 0 ||
        strcmp(kind, SPEC_FIELD_KIND_ENUM) == 0) {
      const char *value = spec_document_content(doc, path);
      if (value != NULL) {
        md_heading(b, depth, path, field->name);
        char *f = fence(value, field->content_type);
        writeln(b, f);
        free(f);
        writeln(b, "");
      }
    } else if (strcmp(kind, SPEC_FIELD_KIND_FORM) == 0) {
      md_heading(b, depth, path, field->name);
      for (size_t k = 0; k < field->form_fields_len; k++) {
        const char *value =
            spec_document_form_field(doc, path, field->form_fields[k].name);
        if (value == NULL) {
          continue;
        }
        som_buf_puts(b, "<!-- field: ");
        som_buf_puts(b, field->form_fields[k].name);
        som_buf_puts(b, " -->\n");
        char *f = fence(value, "");
        writeln(b, f);
        free(f);
        writeln(b, "");
      }
    } else if (strcmp(kind, SPEC_FIELD_KIND_LIST) == 0) {
      const SpecClass *elem = spec_model_class_named(model, field->element_type);
      int recursive = field->element_type != NULL &&
                      field->element_type[0] != '\0' &&
                      som_strlist_contains(seen_types, field->element_type);
      md_heading(b, depth, path, field->name);
      writeln(b, "");
      if (elem != NULL && !recursive) {
        SomStrList next_seen;
        som_strlist_copy(&next_seen, seen_types);
        set_insert(&next_seen, field->element_type);
        const SomStrList *items = spec_document_list_items(doc, path);
        if (items != NULL) {
          for (size_t it = 0; it < items->len; it++) {
            const char *item_path = items->items[it];
            const char *label = (field->element_type != NULL &&
                                 field->element_type[0] != '\0')
                                    ? field->element_type
                                    : "item";
            md_heading(b, depth + 1, item_path, label);
            writeln(b, "");
            export_class(b, model, doc, refl, elem, item_path, depth + 2,
                         &next_seen);
          }
        }
        som_strlist_free(&next_seen);
      }
    } else if (strcmp(kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
               strcmp(kind, SPEC_FIELD_KIND_SECTION) == 0) {
      const SpecClass *nested = spec_model_class_named(model, field->type);
      int recursive = field->type != NULL && field->type[0] != '\0' &&
                      som_strlist_contains(seen_types, field->type);
      if (nested != NULL && !recursive) {
        md_heading(b, depth, path, field->name);
        writeln(b, "");
        SomStrList next_seen;
        som_strlist_copy(&next_seen, seen_types);
        set_insert(&next_seen, field->type);
        export_class(b, model, doc, refl, nested, path, depth + 1, &next_seen);
        som_strlist_free(&next_seen);
      }
    }
    free(path);
  }
}

/* ======================================================================== */
/* import                                                                    */
/* ======================================================================== */

void spec_markdown_result_free(SpecMarkdownResult *r) {
  document_json_free(&r->staged);
  for (size_t i = 0; i < r->rejections_len; i++) {
    free(r->rejections[i].reason);
    free(r->rejections[i].message);
    free(r->rejections[i].anchor);
  }
  free(r->rejections);
  r->rejections = NULL;
  r->rejections_len = 0;
  r->rejections_cap = 0;
  som_strlist_free(&r->root_prefixes);
}

int spec_markdown_result_is_clean(const SpecMarkdownResult *r) {
  return r->rejections_len == 0;
}

const DocumentJson *spec_markdown_result_document(const SpecMarkdownResult *r) {
  return &r->staged;
}

char *spec_markdown_rejection_display(const SpecMarkdownRejection *rej) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "line ");
  som_buf_puti(&b, (long long)rej->line);
  som_buf_puts(&b, ": ");
  som_buf_puts(&b, rej->reason);
  if (rej->anchor != NULL && rej->anchor[0] != '\0') {
    som_buf_puts(&b, " (");
    som_buf_puts(&b, rej->anchor);
    som_buf_putc(&b, ')');
  }
  som_buf_puts(&b, " \xE2\x80\x94 ");
  som_buf_puts(&b, rej->message);
  return som_buf_take(&b);
}

static void push_rejection(SpecMarkdownResult *r, size_t line,
                           const char *reason, const char *message,
                           const char *anchor) {
  if (r->rejections_len == r->rejections_cap) {
    r->rejections_cap = r->rejections_cap ? r->rejections_cap * 2 : 4;
    r->rejections = (SpecMarkdownRejection *)realloc(
        r->rejections, r->rejections_cap * sizeof(SpecMarkdownRejection));
  }
  SpecMarkdownRejection *rej = &r->rejections[r->rejections_len++];
  rej->line = line;
  rej->reason = som_strdup(reason);
  rej->message = som_strdup(message);
  rej->anchor = som_strdup(anchor != NULL ? anchor : "");
}

/* A pending value target between an anchor and its fenced block. */
typedef struct {
  int active;
  size_t line;
  char *path;
  char *field;
  int has_fld;
  int filled;
} Pending;

static void pending_clear(Pending *p) {
  free(p->path);
  free(p->field);
  p->path = NULL;
  p->field = NULL;
  p->active = 0;
  p->has_fld = 0;
  p->filled = 0;
}

static char *pending_anchor(const Pending *p) {
  if (p->has_fld) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, p->path);
    som_buf_puts(&b, " :: ");
    som_buf_puts(&b, p->field);
    return som_buf_take(&b);
  }
  return som_strdup(p->path);
}

static void flush_missing(Pending *pend, SpecMarkdownResult *result) {
  if (pend->active) {
    if (!pend->filled) {
      char *anchor = pending_anchor(pend);
      push_rejection(result, pend->line, SPEC_MARKDOWN_REJECT_MISSING_VALUE,
                     "no fenced value followed this anchor", anchor);
      free(anchor);
    }
    pending_clear(pend);
  }
}

static void reconstruct_lists(const SpecModel *model,
                              SpecMarkdownResult *result);

void spec_markdown_parse(const SpecModel *model, const char *text,
                         SpecMarkdownResult *out) {
  document_json_init(&out->staged);
  out->rejections = NULL;
  out->rejections_len = 0;
  out->rejections_cap = 0;
  som_strlist_init(&out->root_prefixes);

  SpecReflection refl = spec_reflection_make(model);

  /* split into lines */
  SomStrList lines;
  som_strlist_init(&lines);
  {
    const char *start = text;
    for (const char *p = text;; p++) {
      if (*p == '\n' || *p == '\0') {
        som_strlist_push(&lines, som_strdup_n(start, (size_t)(p - start)));
        if (*p == '\0') {
          break;
        }
        start = p + 1;
      }
    }
  }

  Pending pend = {0, 0, NULL, NULL, 0, 0};
  char *current_kind = som_strdup("");
  char *current_path = som_strdup("");

  size_t i = 0;
  while (i < lines.len) {
    const char *raw = lines.items[i];
    size_t line_no = i + 1;
    char *trimmed = trim_end_dup(raw);

    /* Heading. */
    char *hpath = heading_path(trimmed);
    if (hpath != NULL) {
      flush_missing(&pend, out);
      SpecResolution res;
      if (!spec_reflection_resolve(&refl, hpath, &res)) {
        push_rejection(out, line_no, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                       "section path does not resolve against the model", hpath);
        free(current_kind);
        free(current_path);
        current_kind = som_strdup("");
        current_path = som_strdup("");
      } else {
        free(current_kind);
        current_kind = som_strdup(res.kind);
        free(current_path);
        current_path = som_strdup(hpath);
        /* first '/'-delimited segment → root prefix set */
        const char *slash = strchr(hpath, '/');
        char *prefix = slash != NULL ? som_strdup_n(hpath, (size_t)(slash - hpath))
                                     : som_strdup(hpath);
        set_insert(&out->root_prefixes, prefix);
        free(prefix);
        if (spec_resolution_is_value_leaf(&res)) {
          pend.active = 1;
          pend.line = line_no;
          pend.path = som_strdup(hpath);
          pend.field = som_strdup("");
          pend.has_fld = 0;
          pend.filled = 0;
        }
        spec_resolution_free(&res);
      }
      free(hpath);
      free(trimmed);
      i++;
      continue;
    }

    /* Form-field anchor. */
    char *fname = field_anchor(trimmed);
    if (fname != NULL) {
      flush_missing(&pend, out);
      if (current_path[0] == '\0' ||
          strcmp(current_kind, SPEC_NODE_KIND_FORM) != 0) {
        push_rejection(out, line_no, SPEC_MARKDOWN_REJECT_KIND_MISMATCH,
                       "form-field anchor outside a `@Form` section", fname);
      } else {
        pend.active = 1;
        pend.line = line_no;
        pend.path = som_strdup(current_path);
        pend.field = som_strdup(fname);
        pend.has_fld = 1;
        pend.filled = 0;
      }
      free(fname);
      free(trimmed);
      i++;
      continue;
    }

    /* Fence opener. */
    size_t fence_len = fence_open(trimmed);
    if (fence_len > 0) {
      SomBuf body;
      som_buf_init(&body);
      size_t j = i + 1;
      int body_first = 1;
      while (j < lines.len) {
        char *cl = trim_end_dup(lines.items[j]);
        int is_closer = 1;
        if (strlen(cl) != fence_len) {
          is_closer = 0;
        } else {
          for (size_t k = 0; k < fence_len; k++) {
            if (cl[k] != '`') {
              is_closer = 0;
              break;
            }
          }
        }
        free(cl);
        if (is_closer) {
          break;
        }
        if (!body_first) {
          som_buf_putc(&body, '\n');
        }
        body_first = 0;
        som_buf_puts(&body, lines.items[j]);
        j++;
      }
      char *value = som_buf_take(&body);
      if (!pend.active) {
        push_rejection(out, line_no, SPEC_MARKDOWN_REJECT_ORPHAN_BLOCK,
                       "fenced value with no owning section or field", "");
      } else {
        if (pend.has_fld) {
          SomMap *fields = document_json_form_fields(&out->staged, pend.path);
          som_map_set(fields, pend.field, value);
        } else {
          som_map_set(&out->staged.content, pend.path, value);
        }
        pend.filled = 1;
        pending_clear(&pend);
      }
      free(value);
      free(trimmed);
      i = (j < lines.len) ? j + 1 : j;
      continue;
    }

    free(trimmed);
    i++;
  }
  flush_missing(&pend, out);

  free(current_kind);
  free(current_path);
  som_strlist_free(&lines);

  reconstruct_lists(model, out);
}

static void reconstruct_lists(const SpecModel *model,
                              SpecMarkdownResult *result) {
  SpecReflection refl = spec_reflection_make(model);

  /* Gather the keys to scan: content paths then form paths. */
  SomStrList keys;
  som_strlist_init(&keys);
  for (size_t i = 0; i < result->staged.content.len; i++) {
    som_strlist_push_copy(&keys, result->staged.content.entries[i].key);
  }
  for (size_t i = 0; i < result->staged.forms_len; i++) {
    som_strlist_push_copy(&keys, result->staged.forms[i].key);
  }

  for (size_t ki = 0; ki < keys.len; ki++) {
    const char *path = keys.items[ki];
    SomStrList segs;
    spec_path_segments(path, &segs);
    if (segs.len == 0) {
      som_strlist_free(&segs);
      continue;
    }
    char *prefix = som_strdup(segs.items[0]);
    for (size_t si = 1; si < segs.len; si++) {
      const char *seg = segs.items[si];
      char *base = NULL;
      long long n = 0;
      if (item_seg(seg, &base, &n)) {
        char *list_path = spec_path_join(prefix, base);
        char *item_path = spec_path_join(prefix, seg);
        SpecResolution res;
        if (spec_reflection_resolve(&refl, list_path, &res)) {
          if (strcmp(res.kind, SPEC_NODE_KIND_LIST) == 0) {
            DocListEntry *e =
                document_json_list_entry(&result->staged, list_path);
            if (!som_strlist_contains(&e->items, item_path)) {
              som_strlist_push_copy(&e->items, item_path);
            }
            if (n > e->seq) {
              e->seq = n;
            }
          }
          spec_resolution_free(&res);
        }
        free(list_path);
        free(item_path);
        free(base);
      }
      char *next = spec_path_join(prefix, seg);
      free(prefix);
      prefix = next;
    }
    free(prefix);
    som_strlist_free(&segs);
  }
  som_strlist_free(&keys);
}
