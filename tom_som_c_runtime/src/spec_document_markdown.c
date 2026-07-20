/* spec_document_markdown — implementation. See spec_document_markdown.h; a
 * faithful 1:1 port of the Go `spec_document_markdown.go` (the DocSpecs
 * markdown codec). The Go regexps are reproduced as hand-rolled scanners so the
 * runtime stays zero-dependency C11.
 *
 * Every `List<T>` field maps to a two-level md hierarchy: a `<!--[FOO-LST]-->`
 * container heading (DR1 §1.2/§1.5) at the owner's child level, holding the
 * numbered item headings one level deeper, with item-element children one level
 * deeper again. The container carries no body of its own; item identity is
 * purely positional. */
#include "spec_document_markdown.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "spec_meta_bridge.h"
#include "spec_model.h"
#include "spec_paths.h"

/* ---- small helpers ------------------------------------------------------- */

static void set_err(char **err, char *owned) {
  if (err != NULL) {
    *err = owned;
  } else {
    free(owned);
  }
}

/* Concatenates three strings into a freshly-owned buffer (a small stand-in for
 * Go's `a + b + c`). */
static char *vcat3(const char *a, const char *b, const char *c) {
  SomBuf sb;
  som_buf_init(&sb);
  som_buf_puts(&sb, a);
  som_buf_puts(&sb, b);
  som_buf_puts(&sb, c);
  return som_buf_take(&sb);
}

/* Builds the unterminated-fence error message for a content path, matching the
 * Go text byte-for-byte. */
static char *vcat_path_fence_err(const char *path) {
  return vcat3("content at \"", path,
               "\" contains an unterminated fenced code block; it cannot be "
               "represented in the DocSpecs markdown format");
}

static int is_upper(char c) { return c >= 'A' && c <= 'Z'; }
static int is_lower(char c) { return c >= 'a' && c <= 'z'; }
static int is_digit(char c) { return c >= '0' && c <= '9'; }
static int is_alpha(char c) { return is_upper(c) || is_lower(c); }
static char to_lower_c(char c) { return is_upper(c) ? (char)(c - 'A' + 'a') : c; }
static char to_upper_c(char c) { return is_lower(c) ? (char)(c - 'a' + 'A') : c; }

/* Go's unicode.IsSpace for the ASCII bytes the regexps `\s` matches. */
static int is_ws(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' ||
         c == '\f';
}

static char *lower_dup(const char *s) {
  size_t n = strlen(s);
  char *out = (char *)malloc(n + 1);
  for (size_t i = 0; i < n; i++) {
    out[i] = to_lower_c(s[i]);
  }
  out[n] = '\0';
  return out;
}

static char *itoa_dup(long long v) { return som_format_i64(v); }

/* strings.TrimSpace on ASCII whitespace. Owned. */
static char *trim_space(const char *s) {
  size_t n = strlen(s);
  size_t start = 0;
  while (start < n && is_ws(s[start])) {
    start++;
  }
  while (n > start && is_ws(s[n - 1])) {
    n--;
  }
  return som_strdup_n(s + start, n - start);
}

/* ---- string list of owned lines ----------------------------------------- */

typedef struct {
  char **items;
  size_t len;
  size_t cap;
} LineVec;

static void lv_init(LineVec *v) {
  v->items = NULL;
  v->len = 0;
  v->cap = 0;
}
static void lv_push(LineVec *v, char *owned) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 8;
    v->items = (char **)realloc(v->items, v->cap * sizeof(char *));
  }
  v->items[v->len++] = owned;
}
static void lv_free(LineVec *v) {
  for (size_t i = 0; i < v->len; i++) {
    free(v->items[i]);
  }
  free(v->items);
  v->items = NULL;
  v->len = 0;
  v->cap = 0;
}

/* strings.Split(text, "\n") into owned line copies. */
static void split_lines(const char *text, LineVec *out) {
  lv_init(out);
  const char *start = text;
  for (const char *p = text;; p++) {
    if (*p == '\n' || *p == '\0') {
      lv_push(out, som_strdup_n(start, (size_t)(p - start)));
      if (*p == '\0') {
        break;
      }
      start = p + 1;
    }
  }
}

/* ======================================================================== */
/* Regex-equivalent scanners                                                 */
/* ======================================================================== */

/* mdTrailingWSRE = `\s+$` — strip trailing ASCII whitespace. Owned. */
static char *strip_trailing_ws(const char *s) {
  size_t n = strlen(s);
  while (n > 0 && is_ws(s[n - 1])) {
    n--;
  }
  return som_strdup_n(s, n);
}

/* mdDocspecCommentRE = `^<!--\s*docspec:.*-->\s*$`. */
static int is_docspec_comment(const char *s) {
  const char *p = s;
  if (strncmp(p, "<!--", 4) != 0) {
    return 0;
  }
  p += 4;
  while (is_ws(*p)) {
    p++;
  }
  if (strncmp(p, "docspec:", 8) != 0) {
    return 0;
  }
  /* `.*-->` with `.` not matching newline; a single line has no newline. Find
   * the last "-->" then require only trailing whitespace after it. */
  const char *last = NULL;
  for (const char *q = p; *q != '\0'; q++) {
    if (q[0] == '-' && q[1] == '-' && q[2] == '>') {
      last = q;
    }
  }
  if (last == NULL) {
    return 0;
  }
  const char *tail = last + 3;
  while (*tail != '\0') {
    if (!is_ws(*tail)) {
      return 0;
    }
    tail++;
  }
  return 1;
}

/* mdHeadingLineRE = `^(#+)\s+(.*)$`. On match writes the hash count to `*level`
 * and an owned rest (group 2) to `*rest`, returns 1. */
static int match_heading_line(const char *s, int *level, char **rest) {
  size_t hashes = 0;
  while (s[hashes] == '#') {
    hashes++;
  }
  if (hashes == 0) {
    return 0;
  }
  const char *p = s + hashes;
  /* `\s+` — at least one whitespace. */
  if (!is_ws(*p)) {
    return 0;
  }
  size_t ws = 0;
  while (is_ws(p[ws])) {
    ws++;
  }
  *level = (int)hashes;
  *rest = som_strdup(p + ws);
  return 1;
}

/* mdHeadlineCommentRE = `^<!--\[([^\]]+)\]([^>]*)-->\s*(.*)$`. On match writes
 * owned group 1 (id) to `*id`, owned group 2 (the raw key=value region between
 * the id bracket and the closing `-->`, "" when absent — §9.2 `codeSpec`) to
 * `*region`, and owned TrimSpace'd group 3 (the heading title, "" when absent —
 * YRD3) to `*title`, returns 1. `s` should already be TrimSpace'd. `region` /
 * `title` may each be NULL when the caller does not need it.
 *
 * The middle group is `[^>]*` — safe because the region's only values are
 * quoted code locations / identifiers, never a raw `>`; so the closing `-->`
 * is the first `>` at or after the id bracket. */
static int match_headline_comment(const char *s, char **id, char **region,
                                  char **title) {
  if (strncmp(s, "<!--[", 5) != 0) {
    return 0;
  }
  const char *p = s + 5;
  const char *close = strchr(p, ']');
  if (close == NULL || close == p) {
    return 0; /* [^\]]+ requires at least one char */
  }
  /* The middle `([^>]*)` region: from just past `]` up to the first `>` (the
   * `>` of `-->`); the region contains no `>`. Require the `>` to be preceded
   * by `--` (i.e. a real `-->` terminator). */
  const char *region_start = close + 1;
  const char *gt = strchr(region_start, '>');
  if (gt == NULL || gt < region_start + 2 || gt[-1] != '-' || gt[-2] != '-') {
    return 0;
  }
  *id = som_strdup_n(p, (size_t)(close - p));
  /* The region excludes the trailing `--` that belongs to `-->`. */
  const char *region_end = gt - 2;
  if (region != NULL) {
    *region = som_strdup_n(region_start, (size_t)(region_end - region_start));
  }
  if (title != NULL) {
    const char *t = gt + 1;
    while (is_ws(*t)) {
      t++;
    }
    /* TrimSpace the remainder (leading ws consumed above). */
    size_t len = strlen(t);
    while (len > 0 && is_ws(t[len - 1])) {
      len--;
    }
    *title = som_strdup_n(t, len);
  }
  return 1;
}

/* mdCodeSpecRE = `codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))` — extracts the
 * `codeSpec="…"` (or `'…'`, or bare) value from a heading-comment key=value
 * region (§9.2), mirroring the tom_doc_scanner key=value grammar. Returns an
 * owned trimmed value, or an owned "" when the region carries no `codeSpec`
 * key. */
static char *md_code_spec_of(const char *region) {
  const char *p = strstr(region, "codeSpec=");
  if (p == NULL) {
    return som_strdup("");
  }
  p += 9; /* past "codeSpec=" */
  const char *start;
  const char *end;
  if (*p == '"') {
    start = p + 1;
    end = strchr(start, '"');
    if (end == NULL) {
      return som_strdup("");
    }
  } else if (*p == '\'') {
    start = p + 1;
    end = strchr(start, '\'');
    if (end == NULL) {
      return som_strdup("");
    }
  } else {
    /* bare: [^,\s>]+ */
    start = p;
    end = p;
    while (*end != '\0' && *end != ',' && !is_ws(*end) && *end != '>') {
      end++;
    }
  }
  /* trim */
  while (start < end && is_ws(*start)) {
    start++;
  }
  size_t len = (size_t)(end - start);
  while (len > 0 && is_ws(start[len - 1])) {
    len--;
  }
  return som_strdup_n(start, len);
}

/* mdFenceOpenRE = "^ {0,3}(`{3,}|~{3,})" — writes the run char and length. */
static int match_fence_open(const char *s, char *ch, size_t *run) {
  size_t i = 0;
  while (i < 3 && s[i] == ' ') {
    i++;
  }
  char c = s[i];
  if (c != '`' && c != '~') {
    return 0;
  }
  size_t n = 0;
  while (s[i + n] == c) {
    n++;
  }
  if (n < 3) {
    return 0;
  }
  *ch = c;
  *run = n;
  return 1;
}

/* mdEscapableRE = `^\\*#` — optional run of backslashes then `#` at col 0. */
static int match_escapable(const char *s) {
  size_t i = 0;
  while (s[i] == '\\') {
    i++;
  }
  return s[i] == '#';
}

/* mdEscapedHeadingRE = `^\\+#` — one-or-more backslashes then `#`. */
static int match_escaped_heading(const char *s) {
  if (s[0] != '\\') {
    return 0;
  }
  size_t i = 0;
  while (s[i] == '\\') {
    i++;
  }
  return s[i] == '#';
}

/* mdLabelShapedRE = `^ *[A-Za-z][A-Za-z0-9_]*:`. */
static int match_label_shaped(const char *s) {
  size_t i = 0;
  while (s[i] == ' ') {
    i++;
  }
  if (!is_alpha(s[i])) {
    return 0;
  }
  i++;
  while (is_alpha(s[i]) || is_digit(s[i]) || s[i] == '_') {
    i++;
  }
  return s[i] == ':';
}

/* mdContinuationLabelRE = `^ +[A-Za-z][A-Za-z0-9_]*:` — needs 1+ leading
 * space. */
static int match_continuation_label(const char *s) {
  if (s[0] != ' ') {
    return 0;
  }
  return match_label_shaped(s);
}

/* mdFieldLabelRE = `^([A-Za-z][A-Za-z0-9_]*): ?(.*)$`. On match writes owned
 * group 1 (label) to `*label` and owned group 2 (value) to `*value`. */
static int match_field_label(const char *s, char **label, char **value) {
  if (!is_alpha(s[0])) {
    return 0;
  }
  size_t i = 1;
  while (is_alpha(s[i]) || is_digit(s[i]) || s[i] == '_') {
    i++;
  }
  if (s[i] != ':') {
    return 0;
  }
  size_t name_end = i;
  i++; /* past ':' */
  if (s[i] == ' ') {
    i++; /* optional single space */
  }
  *label = som_strdup_n(s, name_end);
  *value = som_strdup(s + i);
  return 1;
}

/* mdBlankRunRE `\n{3,}`→`\n\n`, mdLeadingNLRE `^\n+`→``, mdTrailingNLRE
 * `\n+$`→``. Applied in that order, matching prepareValue. Owned. */
static char *collapse_blank_runs(const char *value) {
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0;
  while (value[i] != '\0') {
    if (value[i] == '\n') {
      size_t run = 0;
      while (value[i + run] == '\n') {
        run++;
      }
      size_t emit = run >= 3 ? 2 : run;
      for (size_t k = 0; k < emit; k++) {
        som_buf_putc(&b, '\n');
      }
      i += run;
    } else {
      som_buf_putc(&b, value[i]);
      i++;
    }
  }
  char *collapsed = som_buf_take(&b);
  /* strip leading + trailing newlines */
  size_t n = strlen(collapsed);
  size_t start = 0;
  while (start < n && collapsed[start] == '\n') {
    start++;
  }
  while (n > start && collapsed[n - 1] == '\n') {
    n--;
  }
  char *out = som_strdup_n(collapsed + start, n - start);
  free(collapsed);
  return out;
}

/* mdLeadingBlankLnRE `^([ \t]*\n)+` and mdTrailingBlankLnRE `(\n[ \t]*)+$`:
 * strip leading/trailing blank lines from `joined`. Owned. */
static char *strip_blank_lines(const char *joined) {
  size_t n = strlen(joined);
  size_t start = 0;
  /* leading: repeat of ([ \t]*\n). */
  for (;;) {
    size_t j = start;
    while (joined[j] == ' ' || joined[j] == '\t') {
      j++;
    }
    if (joined[j] == '\n') {
      start = j + 1;
    } else {
      break;
    }
  }
  /* trailing: repeat of (\n[ \t]*), anchored at end. Find the smallest `end`
   * such that joined[end..n) consists of one-or-more `\n[ \t]*` groups. Scan
   * backwards. */
  size_t end = n;
  for (;;) {
    size_t j = end;
    while (j > start && (joined[j - 1] == ' ' || joined[j - 1] == '\t')) {
      j--;
    }
    if (j > start && joined[j - 1] == '\n') {
      end = j - 1;
    } else {
      break;
    }
  }
  if (end < start) {
    end = start;
  }
  return som_strdup_n(joined + start, end - start);
}

/* ======================================================================== */
/* Fence tracker (public API)                                                */
/* ======================================================================== */

void spec_markdown_fence_init(SpecMarkdownFenceTracker *t) {
  t->ch = 0;
  t->size = 0;
}

int spec_markdown_fence_in_fence(const SpecMarkdownFenceTracker *t) {
  return t->ch != 0;
}

void spec_markdown_fence_feed(SpecMarkdownFenceTracker *t, const char *line) {
  char ch;
  size_t run;
  if (!match_fence_open(line, &ch, &run)) {
    return;
  }
  if (t->ch == 0) {
    t->ch = ch;
    t->size = run;
    return;
  }
  char *trimmed = trim_space(line);
  size_t tn = strlen(trimmed);
  int all_same = tn > 0;
  for (size_t i = 0; i < tn; i++) {
    if (trimmed[i] != t->ch) {
      all_same = 0;
      break;
    }
  }
  if (ch == t->ch && run >= t->size && all_same) {
    t->ch = 0;
    t->size = 0;
  }
  free(trimmed);
}

/* ======================================================================== */
/* Naming helpers (DR1 §1.2 / §1.5)                                          */
/* ======================================================================== */

char *spec_markdown_title_case(const char *name) {
  /* Split at each upper-case boundary (buf != "" then upper starts a word),
   * then upper-case each word's first char. */
  SomBuf out;
  som_buf_init(&out);
  size_t i = 0;
  int first_word = 1;
  while (name[i] != '\0') {
    /* start of a word: emit first char upper-cased */
    size_t start = i;
    /* the first char of the word */
    i++;
    /* consume until the next upper-case boundary (an upper char with a
     * non-empty buffer) */
    while (name[i] != '\0' && !is_upper(name[i])) {
      i++;
    }
    if (!first_word) {
      som_buf_putc(&out, ' ');
    }
    first_word = 0;
    som_buf_putc(&out, to_upper_c(name[start]));
    som_buf_putn(&out, name + start + 1, i - start - 1);
  }
  return som_buf_take(&out);
}

char *spec_markdown_kebab_case(const char *title) {
  char *trimmed = trim_space(title);
  /* mdKebabSpaceRE [\s_]+ → "-" */
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0;
  while (trimmed[i] != '\0') {
    if (is_ws(trimmed[i]) || trimmed[i] == '_') {
      while (is_ws(trimmed[i]) || trimmed[i] == '_') {
        i++;
      }
      som_buf_putc(&b, '-');
    } else {
      som_buf_putc(&b, trimmed[i]);
      i++;
    }
  }
  char *spaced = som_buf_take(&b);
  free(trimmed);
  /* mdKebabDropRE [^A-Za-z0-9-] → "" then ToLower */
  SomBuf o;
  som_buf_init(&o);
  for (size_t k = 0; spaced[k] != '\0'; k++) {
    char c = spaced[k];
    if (is_alpha(c) || is_digit(c) || c == '-') {
      som_buf_putc(&o, to_lower_c(c));
    }
  }
  free(spaced);
  return som_buf_take(&o);
}

char *spec_markdown_item_title_stem(const char *element_class_name) {
  size_t n = strlen(element_class_name);
  const char *stem = element_class_name;
  char *tmp = NULL;
  if (n > 5 && strcmp(element_class_name + n - 5, "Entry") == 0) {
    tmp = som_strdup_n(element_class_name, n - 5);
    stem = tmp;
  }
  char *out = spec_markdown_title_case(stem);
  free(tmp);
  return out;
}

char *spec_markdown_form_label(const char *field_name) {
  if (field_name[0] == '\0') {
    return som_strdup("");
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, to_upper_c(field_name[0]));
  som_buf_puts(&b, field_name + 1);
  return som_buf_take(&b);
}

/* ======================================================================== */
/* Codec object                                                              */
/* ======================================================================== */

/* One tree per root type, built lazily and cached. */
typedef struct {
  char *root_type; /* owned */
  SomMetaTree *tree;
} TreeEntry;

typedef struct {
  const SpecModel *model;
  const SpecDocument *document;
  TreeEntry *trees;
  size_t trees_len;
  size_t trees_cap;
} MdCodec;

static void codec_init(MdCodec *c, const SpecModel *model,
                       const SpecDocument *document) {
  c->model = model;
  c->document = document;
  c->trees = NULL;
  c->trees_len = 0;
  c->trees_cap = 0;
}

static void codec_free(MdCodec *c) {
  for (size_t i = 0; i < c->trees_len; i++) {
    free(c->trees[i].root_type);
    som_meta_tree_free(c->trees[i].tree);
  }
  free(c->trees);
}

/* Returns the cached / newly-built tree for `root_type`, or NULL writing `*err`. */
static SomMetaTree *codec_tree_for(MdCodec *c, const char *root_type,
                                   char **err) {
  for (size_t i = 0; i < c->trees_len; i++) {
    if (strcmp(c->trees[i].root_type, root_type) == 0) {
      return c->trees[i].tree;
    }
  }
  SomMetaTree *tree = som_build_meta_tree(c->model, root_type, err);
  if (tree == NULL) {
    return NULL;
  }
  if (c->trees_len == c->trees_cap) {
    c->trees_cap = c->trees_cap ? c->trees_cap * 2 : 4;
    c->trees = (TreeEntry *)realloc(c->trees, c->trees_cap * sizeof(TreeEntry));
  }
  c->trees[c->trees_len].root_type = som_strdup(root_type);
  c->trees[c->trees_len].tree = tree;
  c->trees_len++;
  return tree;
}

/* ---- transparency + heading id ------------------------------------------ */

static const SpecClass *class_named(MdCodec *c, const char *name) {
  return spec_model_class_named(c->model, name);
}

/* headingIdOf: field-level id, else target-class id for section/complex, else
 * the segment. Owned result. */
static char *heading_id_of(MdCodec *c, const SomMetaNode *node) {
  if (node->section_id[0] != '\0') {
    return som_strdup(node->section_id);
  }
  if (strcmp(node->kind, SOM_META_KIND_SECTION) == 0 ||
      strcmp(node->kind, SOM_META_KIND_COMPLEX) == 0) {
    const SpecClass *cls = class_named(c, node->class_name);
    if (cls != NULL && cls->section_id[0] != '\0') {
      return som_strdup(cls->section_id);
    }
  }
  return som_strdup(som_meta_node_segment(node));
}

static int is_transparent_section(MdCodec *c, const SomMetaNode *n) {
  if (strcmp(n->kind, SOM_META_KIND_SECTION) != 0 &&
      strcmp(n->kind, SOM_META_KIND_COMPLEX) != 0) {
    return 0;
  }
  if (n->section_id[0] != '\0') {
    return 0;
  }
  const SpecClass *cls = class_named(c, n->class_name);
  return cls == NULL || cls->section_id[0] == '\0';
}

static int is_transparent_value(const SomMetaNode *n) {
  return n->section_id[0] == '\0' &&
         (strcmp(n->kind, SOM_META_KIND_CONTENT) == 0 ||
          strcmp(n->kind, SOM_META_KIND_SCALAR) == 0 ||
          strcmp(n->kind, SOM_META_KIND_ENUM_VALUE) == 0 ||
          strcmp(n->kind, SOM_META_KIND_FORM) == 0);
}

static int is_value_leaf(const char *kind) {
  return strcmp(kind, SOM_META_KIND_CONTENT) == 0 ||
         strcmp(kind, SOM_META_KIND_SCALAR) == 0 ||
         strcmp(kind, SOM_META_KIND_ENUM_VALUE) == 0;
}

/* mdNodeRel: node + relative path. */
typedef struct {
  const SomMetaNode *node;
  char *rel; /* owned */
} NodeRel;

typedef struct {
  NodeRel *items;
  size_t len;
  size_t cap;
} NodeRelVec;

static void nrv_init(NodeRelVec *v) {
  v->items = NULL;
  v->len = 0;
  v->cap = 0;
}
static void nrv_push(NodeRelVec *v, const SomMetaNode *node, char *rel) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 4;
    v->items = (NodeRel *)realloc(v->items, v->cap * sizeof(NodeRel));
  }
  v->items[v->len].node = node;
  v->items[v->len].rel = rel;
  v->len++;
}
static void nrv_free(NodeRelVec *v) {
  for (size_t i = 0; i < v->len; i++) {
    free(v->items[i].rel);
  }
  free(v->items);
  v->items = NULL;
  v->len = 0;
  v->cap = 0;
}

/* bodySlots collect helper. */
static void body_slots_collect(MdCodec *c, const SomMetaNode *n,
                               const char *prefix, NodeRelVec *out) {
  for (size_t i = 0; i < n->children_len; i++) {
    const SomMetaNode *child = n->children[i];
    if (child->recursive) {
      continue;
    }
    const char *seg = som_meta_node_segment(child);
    char *rel = prefix[0] != '\0' ? spec_path_join(prefix, seg)
                                  : som_strdup(seg);
    if (is_transparent_value(child)) {
      nrv_push(out, child, rel);
    } else if (is_transparent_section(c, child)) {
      char *rel2 = som_strdup(rel);
      nrv_push(out, child, rel);
      body_slots_collect(c, child, rel2, out);
      free(rel2);
    } else {
      free(rel);
    }
  }
}

static void body_slots(MdCodec *c, const SomMetaNode *node, NodeRelVec *out) {
  nrv_init(out);
  body_slots_collect(c, node, "", out);
}

/* effectiveChildren collect helper. */
static void effective_children_collect(MdCodec *c, const SomMetaNode *n,
                                       const char *prefix, NodeRelVec *out) {
  for (size_t i = 0; i < n->children_len; i++) {
    const SomMetaNode *child = n->children[i];
    if (child->recursive) {
      continue;
    }
    const char *seg = som_meta_node_segment(child);
    char *rel = prefix[0] != '\0' ? spec_path_join(prefix, seg)
                                  : som_strdup(seg);
    if (is_transparent_value(child)) {
      free(rel);
      continue;
    }
    if (is_transparent_section(c, child)) {
      effective_children_collect(c, child, rel, out);
      free(rel);
    } else {
      nrv_push(out, child, rel);
    }
  }
}

static void effective_children(MdCodec *c, const SomMetaNode *node,
                               NodeRelVec *out) {
  nrv_init(out);
  effective_children_collect(c, node, "", out);
}

/* ======================================================================== */
/* Export                                                                    */
/* ======================================================================== */

/* The effective DEFAULT title of `node` (YRD4): the `@Headline` default when
   authored, else the name derivation. The stored headline (checked by callers
   first) always wins over this. Owned result. */
static char *md_title_of(const SomMetaNode *node) {
  if (node->headline[0] != '\0') {
    return som_strdup(node->headline);
  }
  const char *name =
      node->member_name[0] != '\0' ? node->member_name : node->class_name;
  return spec_markdown_title_case(name);
}

/* The effective default item-title stem of list `node` (YRD4): the element
   class's `@Headline` default when authored, else the DR1 §1.5 derivation
   (element class name with `Entry` dropped; member name for scalar lists).
   Owned result. */
static char *md_item_stem_of(const SomMetaNode *node) {
  const SomMetaNode *element = node->element_node;
  if (element != NULL) {
    if (element->headline[0] != '\0') {
      return som_strdup(element->headline);
    }
    return spec_markdown_item_title_stem(element->class_name);
  }
  const char *member = node->member_name[0] != '\0'
                           ? node->member_name
                           : som_meta_node_segment(node);
  return spec_markdown_title_case(member);
}

/* headingTitle: resolves the heading title for a node at `path` — the
 * document's STORED headline when present, else the derived title (YRD3).
 * Owned result. */
static char *heading_title(MdCodec *c, const char *path,
                           const SomMetaNode *node) {
  const char *h = spec_document_headline(c->document, path);
  if (h != NULL && h[0] != '\0') {
    return som_strdup(h);
  }
  return md_title_of(node);
}

/* Emits `#{depth} <!--[id]{ codeSpec="…"}--> title`. When `code_spec` is
 * non-NULL and non-empty it is written as a ` codeSpec="…"` key inside the
 * headline comment (§9.2); byte-identical to before when empty/NULL. */
static void md_write_heading(SomBuf *b, int depth, const char *id,
                             const char *title, const char *code_spec) {
  for (int i = 0; i < depth; i++) {
    som_buf_putc(b, '#');
  }
  som_buf_puts(b, " <!--[");
  som_buf_puts(b, id);
  som_buf_putc(b, ']');
  if (code_spec != NULL && code_spec[0] != '\0') {
    som_buf_puts(b, " codeSpec=\"");
    som_buf_puts(b, code_spec);
    som_buf_putc(b, '"');
  }
  som_buf_puts(b, "--> ");
  som_buf_puts(b, title);
  som_buf_putc(b, '\n');
  som_buf_putc(b, '\n');
}

/* prepareValue: collapse blank runs, escape heading-like lines outside fences.
 * Returns 1 writing owned `*out`; on an unterminated fence returns 0 writing
 * `*err`. */
static int prepare_value(const char *value, const char *path, char **out,
                         char **err) {
  char *collapsed = collapse_blank_runs(value);
  LineVec lines;
  split_lines(collapsed, &lines);
  free(collapsed);
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < lines.len; i++) {
    const char *line = lines.items[i];
    if (i > 0) {
      som_buf_putc(&b, '\n');
    }
    if (spec_markdown_fence_in_fence(&fence)) {
      som_buf_puts(&b, line);
    } else if (match_escapable(line)) {
      som_buf_putc(&b, '\\');
      som_buf_puts(&b, line);
    } else {
      som_buf_puts(&b, line);
    }
    spec_markdown_fence_feed(&fence, line);
  }
  int in_fence = spec_markdown_fence_in_fence(&fence);
  lv_free(&lines);
  char *joined = som_buf_take(&b);
  if (in_fence) {
    free(joined);
    set_err(err,
            vcat_path_fence_err(path));
    return 0;
  }
  *out = joined;
  return 1;
}

/* Forward decls. */
static int write_children(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                          const char *base_path, int depth, char **err);
static int write_section_body(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                              const char *path, char **err);

/* writeBody: prepared value + blank line, no-op when blank. */
static int write_body(MdCodec *c, SomBuf *b, const char *value,
                      const char *path, char **err) {
  (void)c;
  char *prepared = NULL;
  if (!prepare_value(value, path, &prepared, err)) {
    return 0;
  }
  if (prepared[0] == '\0') {
    free(prepared);
    return 1;
  }
  som_buf_puts(b, prepared);
  som_buf_putc(b, '\n');
  som_buf_putc(b, '\n');
  free(prepared);
  return 1;
}

static int form_has_values(MdCodec *c, const SomMetaNode *node,
                           const char *path) {
  if (node->form == NULL) {
    return 0;
  }
  for (size_t i = 0; i < node->form->fields_len; i++) {
    if (spec_document_form_field(c->document, path,
                                 node->form->fields[i].name) != NULL) {
      return 1;
    }
  }
  return 0;
}

static int write_form(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                      const char *path, char **err) {
  size_t nfields = node->form != NULL ? node->form->fields_len : 0;
  for (size_t fi = 0; fi < nfields; fi++) {
    const SomFormFieldMeta *f = &node->form->fields[fi];
    const char *value = spec_document_form_field(c->document, path, f->name);
    if (value == NULL) {
      continue;
    }
    char *prepared = NULL;
    if (!prepare_value(value, path, &prepared, err)) {
      return 0;
    }
    LineVec plines;
    split_lines(prepared, &plines);
    free(prepared);
    char *label = spec_markdown_form_label(f->name);
    som_buf_puts(b, label);
    som_buf_puts(b, ": ");
    som_buf_puts(b, plines.len > 0 ? plines.items[0] : "");
    som_buf_putc(b, '\n');
    free(label);
    for (size_t li = 1; li < plines.len; li++) {
      const char *line = plines.items[li];
      if (match_label_shaped(line)) {
        som_buf_putc(b, ' ');
        som_buf_puts(b, line);
      } else {
        som_buf_puts(b, line);
      }
      som_buf_putc(b, '\n');
    }
    lv_free(&plines);
  }
  som_buf_putc(b, '\n');
  return 1;
}

static int write_section_body(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                              const char *path, char **err) {
  const char *value = spec_document_content(c->document, path);
  if (value != NULL) {
    if (!write_body(c, b, value, path, err)) {
      return 0;
    }
  }
  NodeRelVec slots;
  body_slots(c, node, &slots);
  for (size_t i = 0; i < slots.len; i++) {
    char *slot_path = spec_path_join(path, slots.items[i].rel);
    const SomMetaNode *sn = slots.items[i].node;
    if (strcmp(sn->kind, SOM_META_KIND_FORM) == 0) {
      if (form_has_values(c, sn, slot_path)) {
        if (!write_form(c, b, sn, slot_path, err)) {
          free(slot_path);
          nrv_free(&slots);
          return 0;
        }
      }
    } else {
      const char *v = spec_document_content(c->document, slot_path);
      if (v != NULL) {
        if (!write_body(c, b, v, slot_path, err)) {
          free(slot_path);
          nrv_free(&slots);
          return 0;
        }
      }
    }
    free(slot_path);
  }
  nrv_free(&slots);
  return 1;
}

/* Emits list `node` as its `-LST` container heading (DR1 §1.2/§1.5) at `depth`,
   wrapping the numbered item headings one level deeper. The container is a real
   section — the id the DR3 schema keys its container type by — but carries no
   content of its own (schema content min/max-text-length 0). Item identity is
   purely positional. */
static int write_list_items(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                            const char *list_path, int depth, char **err) {
  const SomStrList *items = spec_document_list_items(c->document, list_path);
  size_t n = items != NULL ? items->len : 0;
  if (n == 0) {
    return 1;
  }
  /* The container heading: its id is the list's `-LST` @SectionId (else the
     member segment for a pattern-less list); its title is the member name
     (or the stored headline, YRD3). */
  {
    char *chid = heading_id_of(c, node);
    char *ctitle = heading_title(c, list_path, node);
    md_write_heading(b, depth, chid, ctitle,
                     spec_document_code_spec(c->document, list_path));
    free(chid);
    free(ctitle);
  }
  /* Item heading stem. Complex lists derive it from the element class name
     (DR1 §1.5, `Entry` dropped). A scalar list (shape 6) has no element class —
     its element type_name is literally `String`, which would render
     "String 1", "String 2". Derive the stem from the list FIELD instead (its
     member name, Title-Cased like the container heading) so a populated scalar
     list gets meaningful per-item headings (YRC5). An element-class @Headline
     default wins over both derivations (YRD4). Owned buffer freed once below. */
  const SomMetaNode *element = node->element_node;
  char *stem = md_item_stem_of(node);
  const char *pattern = node->section_id_pattern;
  if (pattern[0] == '\0' && element != NULL) {
    pattern = element->section_id_pattern;
  }
  for (size_t i = 0; i < n; i++) {
    const char *item_path = items->items[i];
    long long pos = (long long)i + 1;
    char *item_id = NULL;
    /* YRD3 (supersedes DRC5): a stored @SectionId IS the item's md heading
       id; the positional derivation is only the fallback. */
    const char *stored_id = spec_document_item_section_id(c->document,
                                                          item_path);
    if (stored_id != NULL) {
      item_id = som_strdup(stored_id);
    } else if (pattern[0] != '\0') {
      /* pattern with "xxx" → pos */
      SomBuf ib;
      som_buf_init(&ib);
      char *num = itoa_dup(pos);
      const char *p = pattern;
      const char *xxx;
      while ((xxx = strstr(p, "xxx")) != NULL) {
        som_buf_putn(&ib, p, (size_t)(xxx - p));
        som_buf_puts(&ib, num);
        p = xxx + 3;
      }
      som_buf_puts(&ib, p);
      free(num);
      item_id = som_buf_take(&ib);
    } else {
      const char *member =
          node->member_name[0] != '\0' ? node->member_name
                                       : som_meta_node_segment(node);
      char *num = itoa_dup(pos);
      item_id = vcat3(member, "-", num);
      free(num);
    }
    /* YRD3: a stored per-item headline overrides the derived "stem pos"
       title. */
    const char *item_headline = spec_document_headline(c->document, item_path);
    char *title;
    if (item_headline != NULL && item_headline[0] != '\0') {
      title = som_strdup(item_headline);
    } else {
      char *pos_str = itoa_dup(pos);
      title = vcat3(stem, " ", pos_str);
      free(pos_str);
    }
    /* Items sit one level below the container heading. */
    md_write_heading(b, depth + 1, item_id, title,
                     spec_document_code_spec(c->document, item_path));
    free(title);
    free(item_id);
    if (element == NULL) {
      const char *v = spec_document_content(c->document, item_path);
      if (!write_body(c, b, v != NULL ? v : "", item_path, err)) {
        free(stem);
        return 0;
      }
    } else {
      if (!write_section_body(c, b, element, item_path, err)) {
        free(stem);
        return 0;
      }
      if (!element->recursive) {
        /* Item-element children go one level deeper again. */
        if (!write_children(c, b, element, item_path, depth + 2, err)) {
          free(stem);
          return 0;
        }
      }
    }
  }
  free(stem);
  return 1;
}

static int write_children(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                          const char *base_path, int depth, char **err) {
  NodeRelVec eff;
  effective_children(c, node, &eff);
  int ok = 1;
  for (size_t i = 0; i < eff.len && ok; i++) {
    const SomMetaNode *child = eff.items[i].node;
    char *path = spec_path_join(base_path, eff.items[i].rel);
    if (!spec_document_has_values_under(c->document, path)) {
      free(path);
      continue;
    }
    const char *kind = child->kind;
    if (strcmp(kind, SOM_META_KIND_CONTENT) == 0 ||
        strcmp(kind, SOM_META_KIND_SCALAR) == 0 ||
        strcmp(kind, SOM_META_KIND_ENUM_VALUE) == 0) {
      const char *value = spec_document_content(c->document, path);
      if (value == NULL) {
        free(path);
        continue;
      }
      char *hid = heading_id_of(c, child);
      char *title = heading_title(c, path, child);
      md_write_heading(b, depth, hid, title,
                       spec_document_code_spec(c->document, path));
      free(hid);
      free(title);
      ok = write_body(c, b, value, path, err);
    } else if (strcmp(kind, SOM_META_KIND_FORM) == 0) {
      if (!form_has_values(c, child, path)) {
        free(path);
        continue;
      }
      char *hid = heading_id_of(c, child);
      char *title = heading_title(c, path, child);
      md_write_heading(b, depth, hid, title,
                       spec_document_code_spec(c->document, path));
      free(hid);
      free(title);
      ok = write_form(c, b, child, path, err);
    } else if (strcmp(kind, SOM_META_KIND_SECTION) == 0 ||
               strcmp(kind, SOM_META_KIND_COMPLEX) == 0) {
      char *hid = heading_id_of(c, child);
      char *title = heading_title(c, path, child);
      md_write_heading(b, depth, hid, title,
                       spec_document_code_spec(c->document, path));
      free(hid);
      free(title);
      ok = write_section_body(c, b, child, path, err);
      if (ok) {
        ok = write_children(c, b, child, path, depth + 1, err);
      }
    } else if (strcmp(kind, SOM_META_KIND_LIST) == 0) {
      ok = write_list_items(c, b, child, path, depth, err);
    }
    free(path);
  }
  nrv_free(&eff);
  return ok;
}

static char *export_root_impl(MdCodec *c, const SpecRoot *root, char **err) {
  SomMetaTree *tree = codec_tree_for(c, root->type, err);
  if (tree == NULL) {
    return NULL;
  }
  const SomMetaNode *node = tree->root;
  SomBuf b;
  som_buf_init(&b);
  char *kebab = spec_markdown_kebab_case(root->title);
  char *version =
      som_model_version_string(c->model->model_version,
                               c->model->model_version_label);
  som_buf_puts(&b, "<!-- docspec: ");
  som_buf_puts(&b, kebab);
  som_buf_putc(&b, '/');
  som_buf_puts(&b, version);
  som_buf_puts(&b, " -->\n");
  free(kebab);
  free(version);
  const char *root_seg = som_meta_node_segment(node);
  /* YRD3: a stored headline at the root path overrides the root title; the
     root class's @Headline default (YRD4) sits between the two. */
  const char *root_headline = spec_document_headline(c->document, root_seg);
  md_write_heading(&b, 1, root_seg,
                   (root_headline != NULL && root_headline[0] != '\0')
                       ? root_headline
                       : (node->headline[0] != '\0' ? node->headline
                                                    : root->title),
                   spec_document_code_spec(c->document, root_seg));
  if (!write_section_body(c, &b, node, root_seg, err)) {
    som_buf_free(&b);
    return NULL;
  }
  if (!write_children(c, &b, node, root_seg, 2, err)) {
    som_buf_free(&b);
    return NULL;
  }
  return som_buf_take(&b);
}

char *spec_markdown_export_root(const SpecModel *model,
                                const SpecDocument *document,
                                const SpecRoot *root, char **err) {
  MdCodec c;
  codec_init(&c, model, document);
  char *out = export_root_impl(&c, root, err);
  codec_free(&c);
  return out;
}

/* ======================================================================== */
/* Result accessors                                                          */
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

size_t spec_markdown_result_applied_count(const SpecMarkdownResult *r) {
  size_t n = r->staged.content.len;
  for (size_t i = 0; i < r->staged.forms_len; i++) {
    n += r->staged.forms[i].fields.len;
  }
  return n;
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
  som_buf_puts(&b, " \xE2\x80\x94 "); /* U+2014 em-dash */
  som_buf_puts(&b, rej->message);
  return som_buf_take(&b);
}

/* ======================================================================== */
/* Import (parse)                                                            */
/* ======================================================================== */

/* mdListState: per-list bookkeeping while parsing. */
typedef struct {
  char *list_path;    /* owned */
  SomStrList items;   /* item paths, insertion order */
  SomMap ids;         /* item path → stored id */
  long long max_n;
} MdListState;

/* mdFrame: one open section. */
typedef struct {
  int level;
  const SomMetaNode *node; /* NULL for ignored / unresolvable */
  char *path;              /* owned, "" when ignored */
  size_t line;
  int ignored;
  LineVec body;
} MdFrame;

typedef struct {
  MdCodec *codec;
  DocumentJson staged; /* content/forms/lists */
  SpecMarkdownRejection *rejections;
  size_t rejections_len;
  size_t rejections_cap;
  SomStrList root_prefixes;

  /* live lists, in first-seen order (drives listsJson output order) */
  MdListState *lists;
  size_t lists_len;
  size_t lists_cap;

  /* frame stack */
  MdFrame *stack;
  size_t stack_len;
  size_t stack_cap;

  SpecMarkdownFenceTracker fence;
  int current_form_idx;
} MdParser;

static void parser_push_rejection(MdParser *p, size_t line, const char *reason,
                                  const char *message, const char *anchor) {
  if (p->rejections_len == p->rejections_cap) {
    p->rejections_cap = p->rejections_cap ? p->rejections_cap * 2 : 4;
    p->rejections = (SpecMarkdownRejection *)realloc(
        p->rejections, p->rejections_cap * sizeof(SpecMarkdownRejection));
  }
  SpecMarkdownRejection *rej = &p->rejections[p->rejections_len++];
  rej->line = line;
  rej->reason = som_strdup(reason);
  rej->message = som_strdup(message);
  rej->anchor = som_strdup(anchor != NULL ? anchor : "");
}

/* byte-sorted set insert (matches the Go map-keyed RootPrefixes → sorted). */
static void root_prefix_insert(MdParser *p, const char *s) {
  size_t lo = 0, hi = p->root_prefixes.len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(p->root_prefixes.items[mid], s);
    if (cmp == 0) {
      return;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  SomStrList *l = &p->root_prefixes;
  if (l->len == l->cap) {
    l->cap = l->cap ? l->cap * 2 : 4;
    l->items = (char **)realloc(l->items, l->cap * sizeof(char *));
  }
  memmove(&l->items[lo + 1], &l->items[lo], (l->len - lo) * sizeof(char *));
  l->items[lo] = som_strdup(s);
  l->len++;
}

static MdListState *parser_list_state(MdParser *p, const char *list_path) {
  for (size_t i = 0; i < p->lists_len; i++) {
    if (strcmp(p->lists[i].list_path, list_path) == 0) {
      return &p->lists[i];
    }
  }
  if (p->lists_len == p->lists_cap) {
    p->lists_cap = p->lists_cap ? p->lists_cap * 2 : 4;
    p->lists = (MdListState *)realloc(p->lists,
                                      p->lists_cap * sizeof(MdListState));
  }
  MdListState *s = &p->lists[p->lists_len++];
  s->list_path = som_strdup(list_path);
  som_strlist_init(&s->items);
  som_map_init(&s->ids);
  s->max_n = 0;
  return s;
}

/* ---- restore value (parse-side) ----------------------------------------- */

static char *restore_value(char *const *body, size_t body_len) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < body_len; i++) {
    const char *line = body[i];
    if (i > 0) {
      som_buf_putc(&b, '\n');
    }
    if (!spec_markdown_fence_in_fence(&fence) && match_escaped_heading(line)) {
      som_buf_puts(&b, line + 1);
    } else {
      som_buf_puts(&b, line);
    }
    spec_markdown_fence_feed(&fence, line);
  }
  char *joined = som_buf_take(&b);
  char *out = strip_blank_lines(joined);
  free(joined);
  return out;
}

/* ---- form-field lookup (case-insensitive) ------------------------------- */

/* Returns the model form field matching `label` (case-insensitive) in node's
 * form, or NULL. */
static const SomFormFieldMeta *form_field_ci(const SomMetaNode *node,
                                             const char *label) {
  if (node->form == NULL) {
    return NULL;
  }
  char *lower = lower_dup(label);
  const SomFormFieldMeta *found = NULL;
  for (size_t i = 0; i < node->form->fields_len; i++) {
    char *fl = lower_dup(node->form->fields[i].name);
    int hit = strcmp(fl, lower) == 0;
    free(fl);
    if (hit) {
      found = &node->form->fields[i];
      break;
    }
  }
  free(lower);
  return found;
}

/* ---- staged setters ----------------------------------------------------- */

static void staged_set_content(MdParser *p, const char *path,
                               const char *value) {
  som_map_set(&p->staged.content, path, value);
}

static void staged_set_form(MdParser *p, const char *form_path,
                            const char *field, const char *value) {
  SomMap *fields = document_json_form_fields(&p->staged, form_path);
  som_map_set(fields, field, value);
}

/* ---- finalize form ------------------------------------------------------ */

static void finalize_form(MdParser *p, MdFrame *frame, const SomMetaNode *node,
                          const char *path) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  const char *current_field = NULL;
  int have_field = 0;
  LineVec current;
  lv_init(&current);

  /* flush closure body */
#define FORM_FLUSH(lineNo)                                                    \
  do {                                                                        \
    if (have_field) {                                                         \
      char *value = restore_value(current.items, current.len);               \
      if (value[0] != '\0') {                                                 \
        staged_set_form(p, path, current_field, value);                      \
      }                                                                       \
      free(value);                                                           \
    } else {                                                                  \
      for (size_t _k = 0; _k < current.len; _k++) {                          \
        char *_ts = trim_space(current.items[_k]);                           \
        int _nonblank = _ts[0] != '\0';                                      \
        free(_ts);                                                            \
        if (_nonblank) {                                                      \
          parser_push_rejection(                                             \
              p, (lineNo), SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT,              \
              "text in a @Form section before the first field label",        \
              path);                                                          \
          break;                                                             \
        }                                                                     \
      }                                                                       \
    }                                                                         \
    lv_free(&current);                                                        \
    lv_init(&current);                                                        \
  } while (0)

  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      char *label = NULL;
      char *value = NULL;
      if (match_field_label(line, &label, &value)) {
        const SomFormFieldMeta *field = form_field_ci(node, label);
        if (field != NULL) {
          FORM_FLUSH(frame->line + i);
          have_field = 1;
          current_field = field->name;
          lv_push(&current, value);
          value = NULL;
          spec_markdown_fence_feed(&fence, line);
          free(label);
          continue;
        }
        free(label);
        free(value);
      }
    }
    /* continuation: strip one escape space of a label-shaped line */
    if (!spec_markdown_fence_in_fence(&fence) &&
        match_continuation_label(line)) {
      lv_push(&current, som_strdup(line + 1));
    } else {
      lv_push(&current, som_strdup(line));
    }
    spec_markdown_fence_feed(&fence, line);
  }
  FORM_FLUSH(frame->line + frame->body.len);
#undef FORM_FLUSH
  lv_free(&current);
}

/* ---- finalize body slots ------------------------------------------------ */

static void finalize_body_slots(MdParser *p, MdFrame *frame, NodeRelVec *slots) {
  /* partition into form slots and content slots (preserving order) */
  NodeRelVec forms;
  NodeRelVec contents;
  nrv_init(&forms);
  nrv_init(&contents);
  for (size_t i = 0; i < slots->len; i++) {
    if (strcmp(slots->items[i].node->kind, SOM_META_KIND_FORM) == 0) {
      nrv_push(&forms, slots->items[i].node, som_strdup(slots->items[i].rel));
    } else {
      nrv_push(&contents, slots->items[i].node,
               som_strdup(slots->items[i].rel));
    }
  }
  char *content_path;
  if (contents.len > 0) {
    content_path = spec_path_join(frame->path, contents.items[0].rel);
  } else {
    content_path = som_strdup(frame->path);
  }

  if (forms.len == 0) {
    char *value = restore_value(frame->body.items, frame->body.len);
    if (value[0] != '\0') {
      staged_set_content(p, content_path, value);
    }
    free(value);
    free(content_path);
    nrv_free(&forms);
    nrv_free(&contents);
    return;
  }

  /* findField(label): scan formSlots from currentFormIdx, wrapping. */
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  const char *current_field = NULL;
  char *current_form_path = NULL;
  int have_field = 0;
  LineVec current;
  LineVec content_lines;
  lv_init(&current);
  lv_init(&content_lines);

  p->current_form_idx = 0;

  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      char *label = NULL;
      char *value = NULL;
      if (match_field_label(line, &label, &value)) {
        /* find field across form slots, wrapping from current_form_idx */
        int found_idx = -1;
        const SomFormFieldMeta *found_field = NULL;
        char *lower = lower_dup(label);
        for (size_t k = 0; k < forms.len; k++) {
          size_t idx = ((size_t)p->current_form_idx + k) % forms.len;
          const SomMetaNode *fn = forms.items[idx].node;
          if (fn->form == NULL) {
            continue;
          }
          for (size_t fi = 0; fi < fn->form->fields_len; fi++) {
            char *fl = lower_dup(fn->form->fields[fi].name);
            int hit = strcmp(fl, lower) == 0;
            free(fl);
            if (hit) {
              found_idx = (int)idx;
              found_field = &fn->form->fields[fi];
              break;
            }
          }
          if (found_idx >= 0) {
            break;
          }
        }
        free(lower);
        if (found_idx >= 0) {
          /* flush current field */
          if (have_field) {
            char *v = restore_value(current.items, current.len);
            if (v[0] != '\0') {
              staged_set_form(p, current_form_path, current_field, v);
            }
            free(v);
          }
          lv_free(&current);
          lv_init(&current);
          p->current_form_idx = found_idx;
          have_field = 1;
          current_field = found_field->name;
          free(current_form_path);
          current_form_path =
              spec_path_join(frame->path, forms.items[found_idx].rel);
          lv_push(&current, value);
          value = NULL;
          spec_markdown_fence_feed(&fence, line);
          free(label);
          continue;
        }
        free(label);
        free(value);
      }
    }
    /* continuation */
    const char *text = line;
    char *stripped = NULL;
    if (!spec_markdown_fence_in_fence(&fence) && have_field &&
        match_continuation_label(line)) {
      stripped = som_strdup(line + 1);
      text = stripped;
    }
    if (have_field) {
      lv_push(&current, som_strdup(text));
    } else {
      lv_push(&content_lines, som_strdup(text));
    }
    free(stripped);
    spec_markdown_fence_feed(&fence, line);
  }
  /* final flush */
  if (have_field) {
    char *v = restore_value(current.items, current.len);
    if (v[0] != '\0') {
      staged_set_form(p, current_form_path, current_field, v);
    }
    free(v);
  }
  {
    char *cv = restore_value(content_lines.items, content_lines.len);
    if (cv[0] != '\0') {
      staged_set_content(p, content_path, cv);
    }
    free(cv);
  }
  lv_free(&current);
  lv_free(&content_lines);
  free(current_form_path);
  free(content_path);
  nrv_free(&forms);
  nrv_free(&contents);
}

/* ---- finalize frame ----------------------------------------------------- */

static void finalize_frame(MdParser *p, MdFrame *frame) {
  if (frame->ignored) {
    return;
  }
  const SomMetaNode *node = frame->node;
  if (node != NULL && strcmp(node->kind, SOM_META_KIND_FORM) == 0) {
    finalize_form(p, frame, node, frame->path);
    return;
  }
  NodeRelVec slots;
  nrv_init(&slots);
  if (node != NULL) {
    body_slots(p->codec, node, &slots);
  }
  if (slots.len == 0) {
    char *value = restore_value(frame->body.items, frame->body.len);
    if (value[0] != '\0') {
      staged_set_content(p, frame->path, value);
    } else if (node != NULL && is_value_leaf(node->kind)) {
      parser_push_rejection(p, frame->line, SPEC_MARKDOWN_REJECT_MISSING_VALUE,
                            "no value text under this section heading",
                            frame->path);
    }
    free(value);
    nrv_free(&slots);
    return;
  }
  finalize_body_slots(p, frame, &slots);
  nrv_free(&slots);
}

/* ---- stack management --------------------------------------------------- */

static void frame_free(MdFrame *f) {
  free(f->path);
  lv_free(&f->body);
}

static void parser_push_frame(MdParser *p, int level, const SomMetaNode *node,
                              char *path, size_t line, int ignored) {
  if (p->stack_len == p->stack_cap) {
    p->stack_cap = p->stack_cap ? p->stack_cap * 2 : 8;
    p->stack = (MdFrame *)realloc(p->stack, p->stack_cap * sizeof(MdFrame));
  }
  MdFrame *f = &p->stack[p->stack_len++];
  f->level = level;
  f->node = node;
  f->path = path;
  f->line = line;
  f->ignored = ignored;
  lv_init(&f->body);
}

static void parser_finalize_top(MdParser *p) {
  MdFrame *top = &p->stack[p->stack_len - 1];
  finalize_frame(p, top);
  frame_free(top);
  p->stack_len--;
}

static void parser_close_to(MdParser *p, int level) {
  while (p->stack_len > 0 && p->stack[p->stack_len - 1].level >= level) {
    parser_finalize_top(p);
  }
}

/* ---- open item ---------------------------------------------------------- */

static void parser_open_item(MdParser *p, int level, const char *list_path,
                             const SomMetaNode *list_node, long long n,
                             const char *stored_id, int has_n,
                             const char *title, const char *code_spec,
                             size_t line) {
  MdListState *state = parser_list_state(p, list_path);
  long long number = n;
  if (!has_n) {
    number = state->max_n + 1;
  }
  if (number > state->max_n) {
    state->max_n = number;
  }
  char *num = itoa_dup(number);
  char *item_path = vcat3(list_path, "-", num);
  som_strlist_push_copy(&state->items, item_path);
  if (!has_n) {
    som_map_set(&state->ids, item_path, stored_id != NULL ? stored_id : "");
  }
  /* YRD3 §8.7: stage the heading title as a stored headline only when it
     differs from the effective default "<stem> <n>". */
  if (title != NULL && title[0] != '\0') {
    char *stem = md_item_stem_of(list_node);
    char *deflt = vcat3(stem, " ", num);
    if (strcmp(title, deflt) != 0) {
      som_map_set(&p->staged.headlines, item_path, title);
    }
    free(deflt);
    free(stem);
  }
  /* §9.2: stage the item codeSpec mapping whenever present (no default). */
  if (code_spec != NULL && code_spec[0] != '\0') {
    som_map_set(&p->staged.code_specs, item_path, code_spec);
  }
  free(num);
  parser_push_frame(p, level, list_node->element_node, item_path, line, 0);
}

/* mdPatternMatches: pattern with "xxx" wildcard → `.+`. */
static int pattern_matches(const char *pattern, const char *id) {
  /* Split pattern on "xxx"; each literal part must appear in order, with `.+`
   * (at least one char) between consecutive parts, anchored at both ends. */
  const char *pp = pattern;
  const char *ip = id;
  const char *xxx = strstr(pp, "xxx");
  if (xxx == NULL) {
    return strcmp(pattern, id) == 0;
  }
  /* first literal part must be a prefix of id */
  size_t first_len = (size_t)(xxx - pp);
  if (strncmp(ip, pp, first_len) != 0) {
    return 0;
  }
  ip += first_len;
  pp = xxx + 3;
  /* middle parts */
  for (;;) {
    const char *next = strstr(pp, "xxx");
    if (next == NULL) {
      break;
    }
    size_t plen = (size_t)(next - pp);
    /* need `.+` before this literal: at least one char, then the literal */
    /* find the literal in ip starting from ip+1 */
    if (plen == 0) {
      /* empty literal between two xxx: need at least one char consumed */
      if (*ip == '\0') {
        return 0;
      }
      ip += 1;
      pp = next + 3;
      continue;
    }
    const char *hit = NULL;
    for (const char *q = ip + 1; *q != '\0'; q++) {
      if (strncmp(q, pp, plen) == 0) {
        hit = q;
        break;
      }
    }
    if (hit == NULL) {
      return 0;
    }
    ip = hit + plen;
    pp = next + 3;
  }
  /* final literal part must be a suffix, preceded by `.+` */
  size_t last_len = strlen(pp);
  size_t rem = strlen(ip);
  if (last_len == 0) {
    return rem >= 1; /* `.+$` */
  }
  if (rem < last_len + 1) {
    return 0; /* need at least one char for `.+` plus the suffix */
  }
  return strcmp(ip + (rem - last_len), pp) == 0;
}

/* Anonymous member id: `^<member>-([0-9]+)$`. Writes `*num` on match. */
static int anon_member_match(const char *member, const char *id,
                             long long *num) {
  size_t ml = strlen(member);
  if (strncmp(id, member, ml) != 0 || id[ml] != '-') {
    return 0;
  }
  const char *tail = id + ml + 1;
  if (!som_is_all_digits(tail)) {
    return 0;
  }
  return som_parse_i64(tail, num);
}

/* Numbered pattern id: parts[0] <digits> parts[1] → item n. */
static int numbered_pattern_match(const char *pattern, const char *id,
                                  long long *num) {
  const char *xxx = strstr(pattern, "xxx");
  if (xxx == NULL) {
    return 0;
  }
  /* require exactly one "xxx" (strings.Split len == 2) */
  if (strstr(xxx + 3, "xxx") != NULL) {
    return 0;
  }
  size_t pre_len = (size_t)(xxx - pattern);
  const char *post = xxx + 3;
  size_t post_len = strlen(post);
  if (strncmp(id, pattern, pre_len) != 0) {
    return 0;
  }
  size_t idn = strlen(id);
  if (idn < pre_len + post_len) {
    return 0;
  }
  if (strcmp(id + (idn - post_len), post) != 0) {
    return 0;
  }
  const char *digits_start = id + pre_len;
  size_t digits_len = idn - pre_len - post_len;
  if (digits_len == 0) {
    return 0;
  }
  for (size_t i = 0; i < digits_len; i++) {
    if (!is_digit(digits_start[i])) {
      return 0;
    }
  }
  char *ds = som_strdup_n(digits_start, digits_len);
  int ok = som_parse_i64(ds, num);
  free(ds);
  return ok;
}

/* ---- open heading ------------------------------------------------------- */

static void parser_open_root(MdParser *p, int level, const char *id,
                             const char *title, const char *code_spec,
                             size_t line);

/* Opens a list-item frame under a `-LST` container frame (DR1 §1.2). The
   heading `id` is matched positionally against the container's list: the
   `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a number
   (`GOAL-ITEM-3`, parses back as item <n>), a pattern-shaped stored id, or —
   for any other id — an anonymous next item carrying the stored id. */
static void parser_open_item_heading(MdParser *p, int level,
                                     const char *list_path,
                                     const SomMetaNode *list_node,
                                     const char *id, const char *title,
                                     const char *code_spec, size_t line) {
  const char *member = list_node->member_name[0] != '\0'
                           ? list_node->member_name
                           : som_meta_node_segment(list_node);
  long long n = 0;
  if (anon_member_match(member, id, &n)) {
    parser_open_item(p, level, list_path, list_node, n, "", 1, title, code_spec,
                     line);
    return;
  }
  const SomMetaNode *element = list_node->element_node;
  const char *pattern = list_node->section_id_pattern;
  if (pattern[0] == '\0' && element != NULL) {
    pattern = element->section_id_pattern;
  }
  if (pattern[0] != '\0') {
    long long num = 0;
    if (numbered_pattern_match(pattern, id, &num)) {
      parser_open_item(p, level, list_path, list_node, num, "", 1, title,
                       code_spec, line);
      return;
    }
    if (pattern_matches(pattern, id)) {
      parser_open_item(p, level, list_path, list_node, 0, id, 0, title,
                       code_spec, line);
      return;
    }
  }
  /* Any other id under the container is an anonymous next item; a genuine
     stored id is kept (it survives only through the yaml format, DR1 §2). */
  parser_open_item(p, level, list_path, list_node, 0, id, 0, title, code_spec,
                   line);
}

static void parser_open_heading(MdParser *p, int level, const char *rest,
                                size_t line) {
  char *trimmed = trim_space(rest);
  char *id = NULL;
  char *region = NULL;
  char *title = NULL;
  int matched = match_headline_comment(trimmed, &id, &region, &title);
  if (!matched) {
    parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_MALFORMED_HEADING,
                          "heading carries no <!--[SECTION-ID]--> headline "
                          "comment",
                          trimmed);
    parser_push_frame(p, level, NULL, som_strdup(""), line, 1);
    free(trimmed);
    return;
  }
  free(trimmed);
  /* §9.2: the optional key=value region (group 2) carries the codeSpec. */
  char *code_spec = md_code_spec_of(region);
  free(region);

  if (p->stack_len == 0) {
    parser_open_root(p, level, id, title, code_spec, line);
    free(id);
    free(title);
    free(code_spec);
    return;
  }

  MdFrame *parent = &p->stack[p->stack_len - 1];
  if (parent->ignored) {
    parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                          "section nested under an unresolvable parent", id);
    parser_push_frame(p, level, NULL, som_strdup(""), line, 1);
    free(id);
    free(title);
    free(code_spec);
    return;
  }
  const SomMetaNode *p_node = parent->node;
  if (p_node == NULL || is_value_leaf(p_node->kind)) {
    parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_KIND_MISMATCH,
                          "child heading under a value-leaf or form section",
                          id);
    parser_push_frame(p, level, NULL, som_strdup(""), line, 1);
    free(id);
    free(title);
    free(code_spec);
    return;
  }

  char *parent_path = som_strdup(parent->path); /* stable across pushes */

  /* 1. Under a `-LST` container frame (DR1 §1.2), every child heading is one of
     that list's items — resolved positionally, not by the schema tree. */
  if (strcmp(p_node->kind, SOM_META_KIND_LIST) == 0) {
    parser_open_item_heading(p, level, parent_path, p_node, id, title,
                             code_spec, line);
    free(parent_path);
    free(id);
    free(title);
    free(code_spec);
    return;
  }

  /* 2. A regular (non-list) or list-**container** effective child whose heading
     id matches. A list heads its `-LST` container here; its items are resolved
     above once the container frame is open. */
  NodeRelVec eff;
  effective_children(p->codec, p_node, &eff);
  int handled = 0;
  for (size_t i = 0; i < eff.len; i++) {
    const SomMetaNode *en = eff.items[i].node;
    char *hid = heading_id_of(p->codec, en);
    int hit = strcmp(hid, id) == 0;
    free(hid);
    if (hit) {
      char *path = spec_path_join(parent_path, eff.items[i].rel);
      /* YRD3 §8.7: stage the heading title as a stored headline only when it
         differs from the derived default title of this node. */
      if (title[0] != '\0') {
        char *deflt = md_title_of(en);
        if (strcmp(title, deflt) != 0) {
          som_map_set(&p->staged.headlines, path, title);
        }
        free(deflt);
      }
      /* §9.2: stage the codeSpec mapping whenever present (no default). */
      if (code_spec[0] != '\0') {
        som_map_set(&p->staged.code_specs, path, code_spec);
      }
      parser_push_frame(p, level, en, path, line, 0);
      handled = 1;
      break;
    }
  }
  if (handled) {
    nrv_free(&eff);
    free(parent_path);
    free(id);
    free(title);
    free(code_spec);
    return;
  }

  if (!handled) {
    char *msg = vcat3("section id does not resolve against the schema tree at "
                      "this position (under \"",
                      parent_path, "\")");
    parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION, msg,
                          id);
    free(msg);
    parser_push_frame(p, level, NULL, som_strdup(""), line, 1);
  }
  nrv_free(&eff);
  free(parent_path);
  free(id);
  free(title);
  free(code_spec);
}

static void parser_open_root(MdParser *p, int level, const char *id,
                             const char *title, const char *code_spec,
                             size_t line) {
  const SpecModel *model = p->codec->model;
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *root = &model->roots[i];
    const char *seg = root->section_id[0] != '\0' ? root->section_id
                                                   : root->type;
    if (strcmp(seg, id) == 0) {
      char *err = NULL;
      SomMetaTree *tree = codec_tree_for(p->codec, root->type, &err);
      if (tree == NULL) {
        free(err);
        break;
      }
      root_prefix_insert(p, seg);
      /* YRD3 §8.7: stage the root heading title as a stored headline only
         when it differs from the effective default (YRD4: `@Headline`
         default, else the root's declared title). */
      const char *root_default = tree->root->headline[0] != '\0'
                                     ? tree->root->headline
                                     : root->title;
      if (title != NULL && title[0] != '\0' &&
          strcmp(title, root_default) != 0) {
        som_map_set(&p->staged.headlines, seg, title);
      }
      /* §9.2: stage the root codeSpec mapping whenever present. */
      if (code_spec != NULL && code_spec[0] != '\0') {
        som_map_set(&p->staged.code_specs, seg, code_spec);
      }
      parser_push_frame(p, level, tree->root, som_strdup(seg), line, 0);
      return;
    }
  }
  /* unknown root */
  SomBuf known;
  som_buf_init(&known);
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *r = &model->roots[i];
    const char *seg = r->section_id[0] != '\0' ? r->section_id : r->type;
    if (i > 0) {
      som_buf_puts(&known, ", ");
    }
    som_buf_puts(&known, seg);
  }
  char *known_str = som_buf_take(&known);
  char *msg = vcat3("no document root with this section id (known: ",
                    known_str, ")");
  parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION, msg, id);
  free(msg);
  free(known_str);
  parser_push_frame(p, level, NULL, som_strdup(""), line, 1);
}

/* ---- lists → DocumentJson ----------------------------------------------- */

static void parser_emit_lists(MdParser *p) {
  for (size_t i = 0; i < p->lists_len; i++) {
    MdListState *s = &p->lists[i];
    DocListEntry *e = document_json_list_entry(&p->staged, s->list_path);
    e->seq = s->max_n;
    som_strlist_copy(&e->items, &s->items);
    if (s->ids.len > 0) {
      for (size_t j = 0; j < s->ids.len; j++) {
        som_map_set(&e->ids, s->ids.entries[j].key, s->ids.entries[j].val);
      }
    }
  }
}

/* ---- run ---------------------------------------------------------------- */

void spec_markdown_parse(const SpecModel *model, const char *text,
                         SpecMarkdownResult *out) {
  document_json_init(&out->staged);
  out->rejections = NULL;
  out->rejections_len = 0;
  out->rejections_cap = 0;
  som_strlist_init(&out->root_prefixes);

  MdCodec codec;
  codec_init(&codec, model, NULL);

  MdParser p;
  p.codec = &codec;
  document_json_init(&p.staged);
  p.rejections = NULL;
  p.rejections_len = 0;
  p.rejections_cap = 0;
  som_strlist_init(&p.root_prefixes);
  p.lists = NULL;
  p.lists_len = 0;
  p.lists_cap = 0;
  p.stack = NULL;
  p.stack_len = 0;
  p.stack_cap = 0;
  spec_markdown_fence_init(&p.fence);
  p.current_form_idx = 0;

  LineVec lines;
  split_lines(text, &lines);

  for (size_t i = 0; i < lines.len; i++) {
    const char *raw = lines.items[i];
    size_t line_no = i + 1;
    char *trimmed = strip_trailing_ws(raw);

    if (!spec_markdown_fence_in_fence(&p.fence)) {
      if (p.stack_len == 0 && is_docspec_comment(trimmed)) {
        free(trimmed);
        continue; /* §1.1 header */
      }
      int level = 0;
      char *rest = NULL;
      if (match_heading_line(trimmed, &level, &rest)) {
        parser_close_to(&p, level);
        parser_open_heading(&p, level, rest, line_no);
        free(rest);
        free(trimmed);
        continue;
      }
    }
    if (p.stack_len > 0) {
      MdFrame *top = &p.stack[p.stack_len - 1];
      lv_push(&top->body, som_strdup(raw));
    } else if (trimmed[0] != '\0') {
      parser_push_rejection(&p, line_no, SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT,
                            "text before the document root heading", "");
    }
    spec_markdown_fence_feed(&p.fence, raw);
    free(trimmed);
  }
  parser_close_to(&p, 1);
  if (p.stack_len > 0) {
    parser_finalize_top(&p);
  }

  lv_free(&lines);

  parser_emit_lists(&p);

  /* move accumulated state into `out` */
  out->staged = p.staged;
  out->rejections = p.rejections;
  out->rejections_len = p.rejections_len;
  out->rejections_cap = p.rejections_cap;
  out->root_prefixes = p.root_prefixes;

  /* free per-list scratch */
  for (size_t i = 0; i < p.lists_len; i++) {
    free(p.lists[i].list_path);
    som_strlist_free(&p.lists[i].items);
    som_map_free(&p.lists[i].ids);
  }
  free(p.lists);
  free(p.stack);
  codec_free(&codec);
}

/* ======================================================================== */
/* SpecDocument.ToMarkdown (item 12)                                         */
/* ======================================================================== */

static const SpecRoot *single_populated_root(const SpecModel *model,
                                             const SpecDocument *document,
                                             char **err) {
  const SpecRoot *found = NULL;
  size_t count = 0;
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *r = &model->roots[i];
    const char *seg =
        (r->section_id != NULL && r->section_id[0] != '\0') ? r->section_id
                                                            : r->type;
    if (spec_document_has_values_under(document, seg)) {
      count++;
      if (found == NULL) {
        found = r;
      }
    }
  }
  if (count == 1) {
    return found;
  }
  if (err != NULL) {
    SomBuf b;
    som_buf_init(&b);
    if (count == 0) {
      som_buf_puts(&b,
                   "document has no populated root to export; pass root_type "
                   "to choose one");
    } else {
      som_buf_puts(&b, "document has ");
      som_buf_puti(&b, (long long)count);
      som_buf_puts(&b, " populated roots (");
      int first = 1;
      for (size_t i = 0; i < model->roots_len; i++) {
        const SpecRoot *r = &model->roots[i];
        const char *seg =
            (r->section_id != NULL && r->section_id[0] != '\0') ? r->section_id
                                                                : r->type;
        if (spec_document_has_values_under(document, seg)) {
          if (!first) {
            som_buf_puts(&b, ", ");
          }
          som_buf_puts(&b, r->type);
          first = 0;
        }
      }
      som_buf_puts(&b, "); pass root_type to choose one");
    }
    *err = som_buf_take(&b);
  }
  return NULL;
}

char *spec_document_to_markdown(const SpecDocument *document,
                                const SpecModel *model, const char *root_type,
                                char **err) {
  const SpecRoot *root;
  if (root_type != NULL && root_type[0] != '\0') {
    root = spec_model_root_by_type(model, root_type, err);
  } else {
    root = single_populated_root(model, document, err);
  }
  if (root == NULL) {
    return NULL;
  }
  return spec_markdown_export_root(model, document, root, err);
}
