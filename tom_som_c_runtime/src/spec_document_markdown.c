/* spec_document_markdown — implementation. See spec_document_markdown.h; a
 * faithful 1:1 port of the Go `spec_document_markdown.go` (the DocSpecs
 * markdown codec). The Go regexps are reproduced as hand-rolled scanners so the
 * runtime stays zero-dependency C11.
 *
 * Every `List<T>` field maps to a two-level md hierarchy: a `<!--[FOO-LST]-->`
 * container heading (SOM §11.2/§11.5) at the owner's child level, holding the
 * numbered item headings one level deeper, with item-element children one level
 * deeper again. The container carries no body of its own; item identity is
 * purely positional. */
#include "spec_document_markdown.h"

#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "spec_meta_bridge.h"
#include "spec_model.h"
#include "spec_paths.h"
#include "spec_section_id.h"

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
 * the id bracket and the closing `-->`, "" when absent — codespecs_mapping.md
 * §9.2 `codeSpec`) to `*region`, and owned TrimSpace'd group 3 (the heading
 * title, "" when absent — YRD3) to `*title`, returns 1. `s` should already be
 * TrimSpace'd. `region` / `title` may each be NULL when the caller does not
 * need it.
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

/* The value of `key` in a heading-comment key=value region, read as the
 * pattern `key(?:"([^"]*)"|'([^']*)'|([^,\s>]+))` reads it: a double-quoted,
 * single-quoted or bare value, trimmed. A quote that is never closed is no
 * quoted value, so the bare form reads it; an occurrence whose value matches
 * none of the three forms is passed over and the search goes on, as a regular
 * expression's first match would. With `at_boundary` the key must start the
 * region or follow whitespace. Returns an owned value, or an owned "" when no
 * occurrence matches. */
static char *md_key_value_of(const char *region, const char *key,
                             bool at_boundary) {
  size_t key_len = strlen(key);
  for (const char *p = strstr(region, key); p != NULL;
       p = strstr(p + 1, key)) {
    if (at_boundary && p != region && !is_ws(p[-1])) {
      continue;
    }
    const char *v = p + key_len;
    const char *start = NULL;
    const char *end = NULL;
    if (*v == '"' && strchr(v + 1, '"') != NULL) {
      start = v + 1;
      end = strchr(start, '"');
    } else if (*v == '\'' && strchr(v + 1, '\'') != NULL) {
      start = v + 1;
      end = strchr(start, '\'');
    } else {
      /* bare: [^,\s>]+ (at least one character) */
      start = v;
      end = v;
      while (*end != '\0' && *end != ',' && !is_ws(*end) && *end != '>') {
        end++;
      }
      if (end == start) {
        continue;
      }
    }
    while (start < end && is_ws(*start)) {
      start++;
    }
    size_t len = (size_t)(end - start);
    while (len > 0 && is_ws(start[len - 1])) {
      len--;
    }
    return som_strdup_n(start, len);
  }
  return som_strdup("");
}

/* mdCodeSpecRE = `codeSpec=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))` — the
 * `codeSpec` value of a heading-comment key=value region
 * (codespecs_mapping.md §9.2), mirroring the tom_doc_scanner key=value
 * grammar. */
char *spec_markdown_code_spec_of(const char *region) {
  return md_key_value_of(region, "codeSpec=", false);
}

/* mdUnitsRE = `(?:^|\s)units=(?:"([^"]*)"|'([^']*)'|([^,\s>]+))` — the
 * `units` value of a heading-comment key=value region (SOM §11.2). The key
 * must start the region or follow whitespace, so a `units=` inside a quoted
 * codeSpec value is not read as the key. */
char *spec_markdown_units_of(const char *region) {
  return md_key_value_of(region, "units=", true);
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

/* mdLeadingNLRE `^\n+`→`` and mdTrailingNLRE `\n+$`→``, matching
 * prepareValue. Blank lines inside the value are kept (SOM §11.3). Owned. */
static char *strip_outer_newlines(const char *value) {
  size_t n = strlen(value);
  size_t start = 0;
  while (start < n && value[start] == '\n') {
    start++;
  }
  while (n > start && value[n - 1] == '\n') {
    n--;
  }
  return som_strdup_n(value + start, n - start);
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
/* Naming helpers (SOM §11.2 / §11.5)                                          */
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
  /* When non-NULL, the document path of every heading written, in emission
   * order (`spec_markdown_export_root_with_map`). Borrowed. */
  SomStrList *heading_paths;
} MdCodec;

static void codec_init(MdCodec *c, const SpecModel *model,
                       const SpecDocument *document) {
  c->model = model;
  c->document = document;
  c->trees = NULL;
  c->trees_len = 0;
  c->trees_cap = 0;
  c->heading_paths = NULL;
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

/* headingIdOf: field-level id, else target-class id for section/complex, else
 * the segment. Owned result. */
static char *heading_id_of(MdCodec *c, const SomMetaNode *node) {
  (void)c;
  if (node->section_id[0] != '\0') {
    return som_strdup(node->section_id);
  }
  if (strcmp(node->kind, SOM_META_KIND_SECTION) == 0 ||
      strcmp(node->kind, SOM_META_KIND_COMPLEX) == 0) {
    /* The class id is the node's class_section_id, as the YAML key uses —
     * never class_named(node->class_name): a wrapper section (TextSection,
     * ...) carries its OWNER's class name, and that lookup returned the
     * owner's id. */
    if (node->class_section_id != NULL && node->class_section_id[0] != '\0') {
      return som_strdup(node->class_section_id);
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
  /* class_section_id, not class_named(n->class_name): see heading_id_of. A
   * wrapper section (TextSection, ...) has neither id, so it is transparent
   * (SOM §11.6). */
  (void)c;
  return n->class_section_id == NULL || n->class_section_id[0] == '\0';
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
   class's `@Headline` default when authored, else the SOM §11.5 derivation
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

/* Emits `#{depth} <!--[id]{ codeSpec="…"}{ units="…"}--> title`, recording `path` (the
 * document path the heading renders) when the codec keeps a heading map. When `code_spec` is
 * non-NULL and non-empty it is written as a ` codeSpec="…"` key inside the
 * headline comment (codespecs_mapping.md §9.2); byte-identical to before when empty/NULL.
 * A non-empty `units` follows as a second key, ` units="…"` (SOM §11.2). */
static void md_write_heading(MdCodec *c, SomBuf *b, int depth, const char *id,
                             const char *title, const char *path,
                             const char *code_spec, const char *units) {
  if (c->heading_paths != NULL) {
    som_strlist_push_copy(c->heading_paths, path);
  }
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
  if (units != NULL && units[0] != '\0') {
    som_buf_puts(b, " units=\"");
    som_buf_puts(b, units);
    som_buf_putc(b, '"');
  }
  som_buf_puts(b, "--> ");
  /* A heading is one line: a stored headline's line breaks travel as `<br>`. */
  for (const char *q = title; *q != '\0'; q++) {
    if (*q == '\n') {
      som_buf_puts(b, "<br>");
    } else {
      som_buf_putc(b, *q);
    }
  }
  som_buf_putc(b, '\n');
  som_buf_putc(b, '\n');
}

/* prepareValue: trim leading/trailing blank lines, escape heading-like lines
 * outside fences.
 * Returns 1 writing owned `*out`; on an unterminated fence returns 0 writing
 * `*err`. */
/* `^ *\|\s*(?:Section\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$` (any case):
 * a value line shaped like a layout table header (SOM §11.4), which the
 * emitter escapes with one space and the parser unescapes. Defined with the
 * parser's layout matchers below. */
static int match_layout_header_shaped(const char *line);

static int prepare_value(const char *value, const char *path, char **out,
                         char **err) {
  char *trimmed = strip_outer_newlines(value);
  LineVec lines;
  split_lines(trimmed, &lines);
  free(trimmed);
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
    } else if (match_layout_header_shaped(line)) {
      /* DI-2 (SOM §11.4): a value line is never a layout table. */
      som_buf_putc(&b, ' ');
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

/* isInlineCode: whether a code field's `value` is written as an inline code
 * span (SOM §11.4 rule 8): it is non-empty and on one line. A multi-line value
 * keeps the prose rendering — a code span cannot cross a line break without
 * markdown joining the lines. */
static int is_inline_code(const char *value) {
  return value[0] != '\0' && strchr(value, '\n') == NULL;
}

/* encodeCodeSpan: `value` as a CommonMark inline code span — delimited by one
 * backtick more than the longest backtick run inside it, and padded with one
 * space on each side when it begins or ends with a backtick or a space (the
 * padding CommonMark strips again, so the span's content is exactly `value`).
 * Returns an owned string. */
static char *encode_code_span(const char *value) {
  size_t longest = 0;
  size_t run = 0;
  for (const char *q = value; *q != '\0'; q++) {
    if (*q == '`') {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 0;
    }
  }
  size_t n = strlen(value);
  int pad = n > 0 && (value[0] == '`' || value[0] == ' ' ||
                      value[n - 1] == '`' || value[n - 1] == ' ');
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i <= longest; i++) {
    som_buf_putc(&b, '`');
  }
  if (pad) {
    som_buf_putc(&b, ' ');
  }
  som_buf_puts(&b, value);
  if (pad) {
    som_buf_putc(&b, ' ');
  }
  for (size_t i = 0; i <= longest; i++) {
    som_buf_putc(&b, '`');
  }
  return som_buf_take(&b);
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

/* undeclaredFormFields: the first stored field name at form `path` that `node`
 * does not declare, in sorted order (SOM §9, "Form-field order"); NULL when
 * every stored field is declared. Owned result.
 *
 * The emit walk is meta-driven — it iterates the model's declared fields — so a
 * stored field the model does not know is invisible to it and cannot be dropped
 * *loudly*. Seeing it at all needs this deliberate reverse check: store keys
 * minus meta keys, which is the check the yaml codec already has (SOM §12.8).
 * `spec_document_form_field_names` is byte-sorted, so the first hit is the
 * sorted-first one — the same field the other eight ports report. */
static char *first_undeclared_form_field(MdCodec *c, const SomMetaNode *node,
                                         const char *path) {
  SomStrList names;
  spec_document_form_field_names(c->document, path, &names);
  char *found = NULL;
  for (size_t i = 0; i < names.len && found == NULL; i++) {
    int declared = 0;
    if (node->form != NULL) {
      for (size_t fi = 0; fi < node->form->fields_len && !declared; fi++) {
        if (strcmp(node->form->fields[fi].name, names.items[i]) == 0) {
          declared = 1;
        }
      }
    }
    if (!declared) {
      found = som_strdup(names.items[i]);
    }
  }
  som_strlist_free(&names);
  return found;
}

/* checkFormDeclared: 0 (writing `*err`) when the form at `path` holds a field
 * the model does not declare (SOM §9, "Form-field order" — md refuses, matching
 * yaml).
 *
 * Emitting it is impossible: the DocSpecs markdown grammar has no spelling for a
 * field outside the model, and omitting it would lose a stored value in a file
 * that looks complete. On import a partial document is normal and the codec
 * reports-and-skips (SOM §11.7); on export the document is complete and a lossy
 * rendering is a trap, so the codec refuses instead. */
static int check_form_declared(MdCodec *c, const SomMetaNode *node,
                               const char *path, char **err) {
  char *name = first_undeclared_form_field(c, node, path);
  if (name == NULL) {
    return 1;
  }
  if (err != NULL) {
    char *head = vcat3("form at \"", path, "\" holds a field \"");
    *err = vcat3(head, name,
                 "\" unknown to the model; it cannot be represented in the "
                 "DocSpecs markdown format");
    free(head);
  }
  free(name);
  return 0;
}

/* formHasValues: whether the `@Form` node at `path` has anything to emit — its
 * preamble content (SOM §11.4 rule 7 — the DocSpecs `${text[]}` region), or any
 * populated field.
 *
 * An undeclared stored field counts too — not because it can be emitted, but so
 * the section is still *visited* and `write_form` refuses. Without it a form
 * holding nothing but undeclared fields would vanish unseen, which is the silent
 * drop this check exists to prevent. */
static int form_has_values(MdCodec *c, const SomMetaNode *node,
                           const char *path) {
  if (spec_document_content(c->document, path) != NULL) {
    return 1;
  }
  if (node->form != NULL) {
    for (size_t i = 0; i < node->form->fields_len; i++) {
      if (spec_document_form_field(c->document, path,
                                   node->form->fields[i].name) != NULL) {
        return 1;
      }
    }
  }
  char *undeclared = first_undeclared_form_field(c, node, path);
  if (undeclared == NULL) {
    return 0;
  }
  free(undeclared);
  return 1;
}

/* writeForm: a `@Form` section body — the preamble content (when set) followed
 * by one `FieldName: value` group per populated field (SOM §11.4), consecutive
 * groups separated by one blank line. The field
 * groups are buffered first so the preamble can be emitted above them with the
 * blank-line separator only when there actually are field lines. Returns 0
 * (writing `*err`) when the form holds a field the model does not declare. */
static int write_form(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                      const char *path, char **err) {
  if (!check_form_declared(c, node, path, err)) {
    return 0;
  }
  size_t nfields = node->form != NULL ? node->form->fields_len : 0;
  SomBuf fieldbuf;
  som_buf_init(&fieldbuf);
  for (size_t fi = 0; fi < nfields; fi++) {
    const SomFormFieldMeta *f = &node->form->fields[fi];
    const char *value = spec_document_form_field(c->document, path, f->name);
    if (value == NULL) {
      continue;
    }
    /* SOM §11.4 rule 2: one blank line between consecutive field groups, so a
     * markdown viewer renders each field as its own paragraph (and a list
     * ending a value cannot swallow the next label as a lazy continuation).
     * Parse trims each value's trailing blank lines, so it is lossless. */
    if (fieldbuf.len > 0) {
      som_buf_putc(&fieldbuf, '\n');
    }
    /* SOM §11.4 rule 8: a single-line code value is written as an inline code
     * span, so markdown leaves it literal (`](` is not a link). */
    char *prepared = NULL;
    if (f->code && is_inline_code(value)) {
      prepared = encode_code_span(value);
    } else if (!prepare_value(value, path, &prepared, err)) {
      som_buf_free(&fieldbuf);
      return 0;
    }
    LineVec plines;
    split_lines(prepared, &plines);
    free(prepared);
    char *label = spec_markdown_form_label(f->name);
    som_buf_puts(&fieldbuf, label);
    som_buf_puts(&fieldbuf, ": ");
    som_buf_puts(&fieldbuf, plines.len > 0 ? plines.items[0] : "");
    som_buf_putc(&fieldbuf, '\n');
    free(label);
    for (size_t li = 1; li < plines.len; li++) {
      const char *line = plines.items[li];
      if (match_label_shaped(line)) {
        som_buf_putc(&fieldbuf, ' ');
        som_buf_puts(&fieldbuf, line);
      } else {
        som_buf_puts(&fieldbuf, line);
      }
      som_buf_putc(&fieldbuf, '\n');
    }
    lv_free(&plines);
  }
  char *fields_text = som_buf_take(&fieldbuf);

  const char *preamble = spec_document_content(c->document, path);
  if (preamble != NULL) {
    char *prepared = NULL;
    if (!prepare_value(preamble, path, &prepared, err)) {
      free(fields_text);
      return 0;
    }
    if (prepared[0] != '\0') {
      /* Every preamble line gets the same label-shaped escape a continuation
       * line gets: the parser reaches a field label before it knows which text
       * is preamble, so a `Word:` line at column 0 would mis-split. */
      LineVec plines;
      split_lines(prepared, &plines);
      for (size_t li = 0; li < plines.len; li++) {
        const char *line = plines.items[li];
        if (match_label_shaped(line)) {
          som_buf_putc(b, ' ');
        }
        som_buf_puts(b, line);
        som_buf_putc(b, '\n');
      }
      lv_free(&plines);
      if (fields_text[0] != '\0') {
        som_buf_putc(b, '\n');
      }
    }
    free(prepared);
  }
  som_buf_puts(b, fields_text);
  free(fields_text);
  som_buf_putc(b, '\n');
  return 1;
}

/* The body slot unmarked body text binds to on import (SOM §11.6): the first
 * non-form slot; with none, the form on the `content` member, else the first
 * form; with no slot at all the owner itself (`.`). Borrowed from `slots` (or
 * a string literal). */
static const char *default_body_rel(const NodeRelVec *slots) {
  for (size_t i = 0; i < slots->len; i++) {
    if (strcmp(slots->items[i].node->kind, SOM_META_KIND_FORM) != 0) {
      return slots->items[i].rel;
    }
  }
  for (size_t i = 0; i < slots->len; i++) {
    if (strcmp(slots->items[i].rel, "content") == 0) {
      return slots->items[i].rel;
    }
  }
  return slots->len == 0 ? "." : slots->items[0].rel;
}

/* Whether form slot `slots->items[k]` declares a field name (case-insensitive)
 * that another form slot of the region also declares. */
static int form_slot_collides(const NodeRelVec *slots, size_t k) {
  const SomMetaNode *own = slots->items[k].node;
  if (own->form == NULL) {
    return 0;
  }
  for (size_t o = 0; o < slots->len; o++) {
    const SomMetaNode *other = slots->items[o].node;
    if (strcmp(other->kind, SOM_META_KIND_FORM) != 0 || other->form == NULL ||
        strcmp(slots->items[o].rel, slots->items[k].rel) == 0) {
      continue;
    }
    for (size_t fi = 0; fi < own->form->fields_len; fi++) {
      char *a = lower_dup(own->form->fields[fi].name);
      int hit = 0;
      for (size_t gi = 0; gi < other->form->fields_len && !hit; gi++) {
        char *bl = lower_dup(other->form->fields[gi].name);
        hit = strcmp(a, bl) == 0;
        free(bl);
      }
      free(a);
      if (hit) {
        return 1;
      }
    }
  }
  return 0;
}

static void write_slot_marker(SomBuf *b, const char *rel) {
  som_buf_puts(b, "<!-- slot: ");
  som_buf_puts(b, rel);
  som_buf_puts(b, " -->\n\n");
}

/* One text unit of a body region (the owner's own content, or a content
 * slot): skipped when absent or blank; preceded by a slot marker after
 * anything already written or when `rel` is not the region's default target;
 * label-shaped lines gain one escape space when the region has a form. */
static int write_region_text(SomBuf *b, const char *rel, const char *value,
                             const char *value_path, const char *default_rel,
                             int has_forms, int *written, char **err) {
  if (value == NULL) {
    return 1;
  }
  char *prepared = NULL;
  if (!prepare_value(value, value_path, &prepared, err)) {
    return 0;
  }
  if (prepared[0] == '\0') {
    free(prepared);
    return 1;
  }
  if (*written || strcmp(rel, default_rel) != 0) {
    write_slot_marker(b, rel);
  }
  LineVec lines;
  split_lines(prepared, &lines);
  free(prepared);
  for (size_t li = 0; li < lines.len; li++) {
    if (has_forms && match_label_shaped(lines.items[li])) {
      som_buf_putc(b, ' ');
    }
    som_buf_puts(b, lines.items[li]);
    som_buf_putc(b, '\n');
  }
  lv_free(&lines);
  som_buf_putc(b, '\n');
  *written = 1;
  return 1;
}

/* writeSectionBody: the body region of a section heading — the section path's
 * own content value plus every transparent body slot (id-less content text and
 * form blocks, hoisted through transparent sections) in model order.
 *
 * A slot whose text the parser would otherwise bind elsewhere is preceded by a
 * slot marker (SOM §11.6): text after anything already written, a form
 * preamble that is not the region's default target, and a form whose labels
 * another form of the region shares. A body the parser reads correctly without
 * markers gets none. */
static int write_section_body(MdCodec *c, SomBuf *b, const SomMetaNode *node,
                              const char *path, char **err) {
  NodeRelVec slots;
  body_slots(c, node, &slots);
  if (slots.len == 0) {
    nrv_free(&slots);
    const char *value = spec_document_content(c->document, path);
    return value == NULL || write_body(c, b, value, path, err);
  }
  int has_forms = 0;
  const char *first_form_rel = NULL;
  for (size_t i = 0; i < slots.len; i++) {
    if (strcmp(slots.items[i].node->kind, SOM_META_KIND_FORM) == 0) {
      if (first_form_rel == NULL) {
        first_form_rel = slots.items[i].rel;
      }
      has_forms = 1;
    }
  }
  const char *default_rel = default_body_rel(&slots);
  int written = 0;
  int ok = write_region_text(b, ".", spec_document_content(c->document, path),
                             path, default_rel, has_forms, &written, err);
  for (size_t i = 0; ok && i < slots.len; i++) {
    const char *rel = slots.items[i].rel;
    const SomMetaNode *sn = slots.items[i].node;
    char *slot_path = spec_path_join(path, rel);
    if (strcmp(sn->kind, SOM_META_KIND_FORM) != 0) {
      ok = write_region_text(b, rel,
                             spec_document_content(c->document, slot_path),
                             slot_path, default_rel, has_forms, &written, err);
    } else if (form_has_values(c, sn, slot_path)) {
      const char *preamble = spec_document_content(c->document, slot_path);
      int has_preamble = 0;
      if (preamble != NULL) {
        char *prepared = NULL;
        if (prepare_value(preamble, slot_path, &prepared, err)) {
          has_preamble = prepared[0] != '\0';
          free(prepared);
        } else {
          ok = 0;
        }
      }
      if (ok) {
        int needs_marker;
        if (has_preamble) {
          needs_marker = written || strcmp(rel, default_rel) != 0;
        } else {
          needs_marker = form_slot_collides(&slots, i) &&
                         (written || strcmp(first_form_rel, rel) != 0);
        }
        if (needs_marker) {
          write_slot_marker(b, rel);
        }
        ok = write_form(c, b, sn, slot_path, err);
        written = 1;
      }
    }
    free(slot_path);
  }
  nrv_free(&slots);
  return ok;
}

/* Emits list `node` as its `-LST` container heading (SOM §11.2/§11.5) at `depth`,
   wrapping the numbered item headings one level deeper. The container is a real
   section — the id the generated schema keys its container type by — but carries no
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
    md_write_heading(c, b, depth, chid, ctitle, list_path,
                     spec_document_code_spec(c->document, list_path),
                     spec_document_units(c->document, list_path));
    free(chid);
    free(ctitle);
  }
  /* Item heading stem. Complex lists derive it from the element class name
     (SOM §11.5, `Entry` dropped). A scalar list (shape 6) has no element class —
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
  const char *member_stem = node->member_name[0] != '\0'
                                ? node->member_name
                                : som_meta_node_segment(node);
  for (size_t i = 0; i < n; i++) {
    const char *item_path = items->items[i];
    long long pos = (long long)i + 1;
    /* YRD3: a stored @SectionId IS the item's md heading
       id; the positional derivation is only the fallback. Shared with the
       instance-tier reference check, which must resolve `@sectionId`
       references against exactly this id. */
    const char *stored_id = spec_document_item_section_id(c->document,
                                                          item_path);
    char *item_id = spec_effective_list_item_section_id(stored_id, pattern, pos,
                                                        member_stem);
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
    md_write_heading(c, b, depth + 1, item_id, title, item_path,
                     spec_document_code_spec(c->document, item_path),
                     spec_document_units(c->document, item_path));
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
      md_write_heading(c, b, depth, hid, title, path,
                       spec_document_code_spec(c->document, path),
                     spec_document_units(c->document, path));
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
      md_write_heading(c, b, depth, hid, title, path,
                       spec_document_code_spec(c->document, path),
                     spec_document_units(c->document, path));
      free(hid);
      free(title);
      ok = write_form(c, b, child, path, err);
    } else if (strcmp(kind, SOM_META_KIND_SECTION) == 0 ||
               strcmp(kind, SOM_META_KIND_COMPLEX) == 0) {
      char *hid = heading_id_of(c, child);
      char *title = heading_title(c, path, child);
      md_write_heading(c, b, depth, hid, title, path,
                       spec_document_code_spec(c->document, path),
                     spec_document_units(c->document, path));
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
  md_write_heading(c, &b, 1, root_seg,
                   (root_headline != NULL && root_headline[0] != '\0')
                       ? root_headline
                       : (node->headline[0] != '\0' ? node->headline
                                                    : root->title),
                   root_seg, spec_document_code_spec(c->document, root_seg),
                   spec_document_units(c->document, root_seg));
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

/* A heading line as `md_write_heading` writes it: `^#+ <!--\[`. Body text never
 * matches outside a fence — heading-like body lines are escaped (SOM §11.3). */
static int is_emitted_heading(const char *line, size_t len) {
  size_t i = 0;
  while (i < len && line[i] == '#') i++;
  if (i == 0) return 0;
  return len - i >= 6 && memcmp(line + i, " <!--[", 6) == 0;
}

int spec_markdown_export_root_with_map(const SpecModel *model,
                                       const SpecDocument *document,
                                       const SpecRoot *root,
                                       SpecMarkdownRendition *out,
                                       char **err) {
  out->markdown = NULL;
  out->headings = NULL;
  out->headings_len = 0;
  SomStrList paths;
  som_strlist_init(&paths);
  MdCodec c;
  codec_init(&c, model, document);
  c.heading_paths = &paths;
  char *markdown = export_root_impl(&c, root, err);
  codec_free(&c);
  if (markdown == NULL) {
    som_strlist_free(&paths);
    return 0;
  }
  /* Pair the recorded paths, in order, with the heading lines of the finished
   * text — fenced lines are body, never a heading. */
  out->markdown = markdown;
  if (paths.len > 0) {
    out->headings = (SpecMarkdownHeadingPath *)malloc(
        paths.len * sizeof(SpecMarkdownHeadingPath));
  }
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  size_t next = 0;
  int line_no = 1;
  const char *p = markdown;
  while (*p != '\0' && next < paths.len) {
    const char *nl = strchr(p, '\n');
    size_t len = nl != NULL ? (size_t)(nl - p) : strlen(p);
    char *line = som_strdup_n(p, len);
    if (!spec_markdown_fence_in_fence(&fence) && is_emitted_heading(line, len)) {
      out->headings[out->headings_len].line = line_no;
      out->headings[out->headings_len].path = paths.items[next];
      paths.items[next] = NULL; /* ownership moved into the rendition */
      out->headings_len++;
      next++;
    }
    spec_markdown_fence_feed(&fence, line);
    free(line);
    if (nl == NULL) break;
    p = nl + 1;
    line_no++;
  }
  som_strlist_free(&paths);
  return 1;
}

const char *spec_markdown_rendition_path_at_line(
    const SpecMarkdownRendition *r, int line) {
  /* Headings are stored in ascending line order: the last one at or above
   * `line` is the section the line belongs to. */
  const char *found = NULL;
  for (size_t i = 0; i < r->headings_len; i++) {
    if (r->headings[i].line > line) break;
    found = r->headings[i].path;
  }
  return found;
}

void spec_markdown_rendition_free(SpecMarkdownRendition *r) {
  free(r->markdown);
  for (size_t i = 0; i < r->headings_len; i++) {
    free(r->headings[i].path);
  }
  free(r->headings);
  r->markdown = NULL;
  r->headings = NULL;
  r->headings_len = 0;
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
  /* The qualified-anchor scope (SOM §11.2): the ids joined by '/' a heading
   * below this one prefixes its anchor with, NULL for none; and the section
   * id a copy's anchor is qualified by. Both owned, NULL when unset. */
  char *anchor_scope;
  char *anchor_section;
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
  /* The `units` value (SOM §11.2) of the heading being opened, borrowed from
   * `parser_open_heading` for the duration of that call; NULL otherwise. It is
   * staged wherever that heading's codeSpec is staged. */
  const char *heading_units;
  /* The fields given so far per form ("<form path>\x1f<field>"), for the
   * given-twice rule (SOM §11.4). */
  SomMap given;
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

static int match_layout_header_escaped(const char *line);

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
    } else if (!spec_markdown_fence_in_fence(&fence) &&
               match_layout_header_escaped(line)) {
      som_buf_puts(&b, line + 1); /* DI-2: the emitter's one escape space. */
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

/* decodeCodeSpan: the inverse of the emitter's code span (SOM §11.4 rule 8).
 * A single-line `value` delimited by equal backtick runs loses them, and one
 * padding space on each side when both are present. Anything else — a value
 * written by hand without a span — is kept as written. Takes ownership of
 * `value` and returns an owned string. */
static char *decode_code_span(char *value) {
  if (strchr(value, '\n') != NULL) {
    return value;
  }
  size_t n = strlen(value);
  size_t lead = 0;
  while (lead < n && value[lead] == '`') {
    lead++;
  }
  if (lead == 0 || lead == n) {
    return value;
  }
  size_t trail = 0;
  while (trail < n - lead && value[n - 1 - trail] == '`') {
    trail++;
  }
  if (trail != lead) {
    return value;
  }
  size_t start = lead;
  size_t len = n - lead - trail;
  if (len >= 2 && value[start] == ' ' && value[start + len - 1] == ' ') {
    int all_spaces = 1;
    for (size_t i = 0; i < len; i++) {
      if (value[start + i] != ' ') {
        all_spaces = 0;
        break;
      }
    }
    if (!all_spaces) {
      start++;
      len -= 2;
    }
  }
  char *out = (char *)malloc(len + 1);
  memcpy(out, value + start, len);
  out[len] = '\0';
  free(value);
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

/* ---- reading view: layout tables (SOM §11.4, §11.5) --------------------- */

static int anon_member_match(const char *member, const char *id,
                             long long *num);
static int numbered_pattern_match(const char *pattern, const char *id,
                                  long long *num);
static char *parser_open_item(MdParser *p, int level, const char *list_path,
                              const SomMetaNode *list_node, long long n,
                              const char *stored_id, int has_n,
                              const char *title, const char *code_spec,
                              size_t line, int push);

/* `^\|\s*(?:(Section)\s*\|\s*)?TomSpecField\s*\|\s*Value\s*\|?\s*$` (any
 * case) after the leading spaces `mode` allows: 0 none (the layout table
 * header, column 0), 1 any number (a value line shaped like one), 2 at least
 * one (a value line the emitter escaped). Writes whether the header names a
 * `Section` column. */
static int ci_word_at(const char *s, size_t *i, const char *word) {
  size_t k = 0;
  while (word[k] != '\0') {
    if (to_lower_c(s[*i + k]) != to_lower_c(word[k])) return 0;
    k++;
  }
  *i += k;
  return 1;
}

static void skip_ws(const char *s, size_t *i) {
  while (s[*i] != '\0' && is_ws(s[*i])) (*i)++;
}

static int header_rest(const char *s, size_t i, int with_section) {
  skip_ws(s, &i);
  if (with_section) {
    if (!ci_word_at(s, &i, "Section")) return 0;
    skip_ws(s, &i);
    if (s[i] != '|') return 0;
    i++;
    skip_ws(s, &i);
  }
  if (!ci_word_at(s, &i, "TomSpecField")) return 0;
  skip_ws(s, &i);
  if (s[i] != '|') return 0;
  i++;
  skip_ws(s, &i);
  if (!ci_word_at(s, &i, "Value")) return 0;
  skip_ws(s, &i);
  if (s[i] == '|') i++;
  skip_ws(s, &i);
  return s[i] == '\0';
}

static int match_layout_header(const char *line, int mode, int *is_section) {
  size_t i = 0;
  while (line[i] == ' ') i++;
  if (mode == 0 && i != 0) return 0;
  if (mode == 2 && i == 0) return 0;
  if (line[i] != '|') return 0;
  i++;
  if (header_rest(line, i, 1)) {
    if (is_section) *is_section = 1;
    return 1;
  }
  if (header_rest(line, i, 0)) {
    if (is_section) *is_section = 0;
    return 1;
  }
  return 0;
}

/* `^ {0,3}\|`: a line that continues a table. */
static int match_table_line(const char *line) {
  size_t i = 0;
  while (i < 3 && line[i] == ' ') i++;
  return line[i] == '|';
}

/* `^:?-+:?$`. */
static int is_delimiter_cell(const char *c) {
  size_t n = strlen(c), i = 0;
  if (n > 0 && c[0] == ':') i++;
  size_t e = n;
  if (e > i && c[e - 1] == ':') e--;
  if (e <= i) return 0;
  for (size_t k = i; k < e; k++) {
    if (c[k] != '-') return 0;
  }
  return 1;
}

/* The cells of a table row: split on every `|` not preceded by a backslash,
 * the outer pipes dropped, each cell trimmed; `\|` stays in the cell. */
static void row_cells(const char *line, SomStrList *out) {
  som_strlist_init(out);
  char *t = trim_space(line);
  size_t n = strlen(t);
  size_t a = 0;
  if (n > 0 && t[0] == '|') a = 1;
  if (n > a && t[n - 1] == '|' && !(n >= 2 && t[n - 2] == '\\')) n--;
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = a; i < n; i++) {
    char c = t[i];
    if (c == '\\' && i + 1 < n && t[i + 1] == '|') {
      som_buf_puts(&b, "\\|");
      i++;
    } else if (c == '|') {
      char *cell = som_buf_take(&b);
      som_strlist_push(out, trim_space(cell));
      free(cell);
    } else {
      som_buf_putc(&b, c);
    }
  }
  char *cell = som_buf_take(&b);
  som_strlist_push(out, trim_space(cell));
  free(cell);
  free(t);
}

/* One body row of a table: its line index and its cells. */
typedef struct {
  size_t index;
  SomStrList cells;
} MdRow;

typedef struct {
  SomStrList header;
  MdRow *rows;
  size_t rows_len;
  size_t end; /* the index after the table */
} MdTable;

static void md_table_free(MdTable *t) {
  som_strlist_free(&t->header);
  for (size_t i = 0; i < t->rows_len; i++) som_strlist_free(&t->rows[i].cells);
  free(t->rows);
  t->rows = NULL;
  t->rows_len = 0;
}

/* Reads the table whose header is `lines[start]`: the header cells, the body
 * rows with their line indexes, and the index after the table; a broken
 * delimiter row or a row of another cell count is a `malformedBlock`. Line
 * `k` of `lines` is source line `line_base + k`. */
static void read_table(MdParser *p, char *const *lines, size_t len,
                       size_t start, size_t line_base, const char *anchor,
                       MdTable *out) {
  size_t end = start + 1;
  while (end < len && match_table_line(lines[end])) end++;
  out->end = end;
  out->rows = NULL;
  out->rows_len = 0;
  row_cells(lines[start], &out->header);
  int is_delimiter = 0;
  size_t delimiter_len = 0;
  if (start + 1 < end) {
    SomStrList d;
    row_cells(lines[start + 1], &d);
    is_delimiter = 1;
    for (size_t i = 0; i < d.len; i++) {
      if (!is_delimiter_cell(d.items[i])) is_delimiter = 0;
    }
    delimiter_len = d.len;
    som_strlist_free(&d);
  }
  if (!is_delimiter || delimiter_len != out->header.len) {
    parser_push_rejection(p, line_base + start,
                          SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                          !is_delimiter
                              ? "table without its delimiter row"
                              : "table whose delimiter row does not match its "
                                "header",
                          anchor);
    return;
  }
  if (end > start + 2) out->rows = calloc(end - start - 2, sizeof(MdRow));
  for (size_t i = start + 2; i < end; i++) {
    SomStrList cells;
    row_cells(lines[i], &cells);
    if (cells.len != out->header.len) {
      SomBuf msg;
      som_buf_init(&msg);
      som_buf_puts(&msg, "table row with ");
      som_buf_puti(&msg, (long long)cells.len);
      som_buf_puts(&msg, " cells, the header has ");
      som_buf_puti(&msg, (long long)out->header.len);
      char *m = som_buf_take(&msg);
      parser_push_rejection(p, line_base + i,
                            SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK, m, anchor);
      free(m);
      som_strlist_free(&cells);
      continue;
    }
    out->rows[out->rows_len].index = i;
    out->rows[out->rows_len].cells = cells;
    out->rows_len++;
  }
}

/* `s` with every `from` replaced by `to`. Owned result. */
static char *replace_all(const char *s, const char *from, const char *to) {
  SomBuf b;
  som_buf_init(&b);
  size_t fl = strlen(from);
  const char *q = s;
  const char *hit;
  while ((hit = strstr(q, from)) != NULL) {
    som_buf_putn(&b, q, (size_t)(hit - q));
    som_buf_puts(&b, to);
    q = hit + fl;
  }
  som_buf_puts(&b, q);
  return som_buf_take(&b);
}

/* `\[[^\]]+\]\([^)]*\)` at s[*i]: writes the link text's range and advances
 * past the link. */
static int link_at(const char *s, size_t *i, size_t *ta, size_t *tb) {
  size_t k = *i;
  if (s[k] != '[') return 0;
  k++;
  size_t a = k;
  while (s[k] != '\0' && s[k] != ']') k++;
  if (s[k] != ']' || k == a) return 0;
  size_t b = k;
  k++;
  if (s[k] != '(') return 0;
  k++;
  while (s[k] != '\0' && s[k] != ')') k++;
  if (s[k] != ')') return 0;
  *ta = a;
  *tb = b;
  *i = k + 1;
  return 1;
}

/* `^\[[^\]]+\]\([^)]*\)(, \[[^\]]+\]\([^)]*\))*$`: on a match writes the link
 * texts joined by ", " to `*texts`. */
static int link_cell(const char *s, char **texts) {
  SomBuf b;
  som_buf_init(&b);
  size_t i = 0, ta, tb;
  for (;;) {
    if (!link_at(s, &i, &ta, &tb)) {
      som_buf_free(&b);
      return 0;
    }
    if (b.len > 0) som_buf_puts(&b, ", ");
    som_buf_putn(&b, s + ta, tb - ta);
    if (s[i] == '\0') break;
    if (s[i] != ',' || s[i + 1] != ' ') {
      som_buf_free(&b);
      return 0;
    }
    i += 2;
  }
  *texts = som_buf_take(&b);
  return 1;
}

/* A cell's value for field `f`: `\|` unescaped, a reference field's links
 * read as their link texts, a `code` field's code span decoded. Owned. */
static char *cell_value(const char *cell, const SomFormFieldMeta *f) {
  char *text = replace_all(cell, "\\|", "|");
  char *texts = NULL;
  if (f->refers_to_len > 0 && !f->code && link_cell(text, &texts)) {
    free(text);
    return texts;
  }
  return f->code ? decode_code_span(text) : text;
}

/* A cell's id with the renderer's anchor (`<a id="X"></a>X`) removed and a
 * link the cell is read as its text (`[X](<file>#X)`, SOM §11.5). Owned. */
static char *cell_id(const char *cell) {
  const char *r = cell;
  if (strncmp(cell, "<a id=\"", 7) == 0) {
    const char *q = strchr(cell + 7, '"');
    if (q != NULL && strncmp(q, "\"></a>", 6) == 0) {
      r = q + 6;
      while (*r != '\0' && is_ws(*r)) r++;
    }
  }
  /* `^\[([^\]]+)\]\([^)\s]*\)$` */
  if (r[0] == '[') {
    const char *close = strchr(r + 1, ']');
    if (close != NULL && close > r + 1 && close[1] == '(') {
      const char *e = close + 2;
      while (*e != '\0' && *e != ')' && !is_ws(*e)) e++;
      if (*e == ')' && e[1] == '\0') return som_strdup_n(r + 1, (size_t)(close - r - 1));
    }
  }
  return som_strdup(r);
}

/* Whether `field` of the form at `form_path` was given before; reports the
 * repeat (`malformedBlock`, the first occurrence kept) when it was. */
static int given_twice(MdParser *p, const char *form_path, const char *field,
                       size_t line) {
  SomBuf key;
  som_buf_init(&key);
  som_buf_puts(&key, form_path);
  som_buf_putc(&key, '\x1f');
  som_buf_puts(&key, field);
  char *k = som_buf_take(&key);
  int seen = som_map_get(&p->given, k) != NULL;
  if (!seen) {
    som_map_set(&p->given, k, "1");
    free(k);
    return 0;
  }
  free(k);
  char *msg = vcat3("field \"", field, "\" given twice");
  parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK, msg,
                        form_path);
  free(msg);
  return 1;
}

/* Stages one row of a form table (or a section table): `label` names one of
 * `fields` (any case). */
static void stage_row(MdParser *p, const char *form_path,
                      const SomFormFieldMeta *const *fields, size_t fields_len,
                      const char *label, const char *cell, size_t line) {
  const SomFormFieldMeta *f = NULL;
  char *lower = lower_dup(label);
  for (size_t i = 0; i < fields_len && f == NULL; i++) {
    char *fl = lower_dup(fields[i]->name);
    if (strcmp(fl, lower) == 0) f = fields[i];
    free(fl);
  }
  free(lower);
  if (f == NULL) {
    char *msg = vcat3("row \"", label, "\" names no field of this form");
    parser_push_rejection(p, line, SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD, msg,
                          form_path);
    free(msg);
    return;
  }
  char *value = cell_value(cell, f);
  if (value[0] != '\0' && !given_twice(p, form_path, f->name, line)) {
    staged_set_form(p, form_path, f->name, value);
  }
  free(value);
}

/* The fields of a form node as a pointer array (owned array, borrowed
 * fields). */
static const SomFormFieldMeta **form_fields_of(const SomMetaNode *node,
                                               size_t *len) {
  *len = node != NULL && node->form != NULL ? node->form->fields_len : 0;
  if (*len == 0) return NULL;
  const SomFormFieldMeta **out = malloc(*len * sizeof(*out));
  for (size_t i = 0; i < *len; i++) out[i] = &node->form->fields[i];
  return out;
}

/* The item class's own form (its class-level `@Form`, a transparent body
 * slot), or NULL when the class carries none or more than one. Writes the
 * slot's rel (owned). */
static const SomMetaNode *item_form(MdCodec *c, const SomMetaNode *element,
                                    char **rel) {
  NodeRelVec slots;
  nrv_init(&slots);
  body_slots(c, element, &slots);
  const SomMetaNode *found = NULL;
  size_t count = 0;
  for (size_t i = 0; i < slots.len; i++) {
    if (strcmp(slots.items[i].node->kind, SOM_META_KIND_FORM) == 0) {
      count++;
      if (count == 1) {
        found = slots.items[i].node;
        *rel = som_strdup(slots.items[i].rel);
      }
    }
  }
  nrv_free(&slots);
  if (count != 1) {
    if (count > 1) free(*rel);
    *rel = NULL;
    return NULL;
  }
  return found;
}

/* How an item `id` of `list_node` is read, as a heading's, a records row's or
 * a section-table row's: the item number it names (`*has_n`; else the next
 * free one) and the id it stores (`*stored`, borrowed from `id`, or ""). The
 * `<member>-<n>` fallback id is positional and stores nothing; the
 * `@SectionIdPattern` resolved with a number names item `<n>` and is stored
 * (SOM §11.6); any other id is the next item, carrying it (YRD3). */
static void item_identity(const SomMetaNode *list_node, const char *id,
                          long long *n, int *has_n, const char **stored) {
  const char *member = list_node->member_name[0] != '\0'
                           ? list_node->member_name
                           : som_meta_node_segment(list_node);
  *n = 0;
  if (anon_member_match(member, id, n)) {
    *has_n = 1;
    *stored = "";
    return;
  }
  const SomMetaNode *element = list_node->element_node;
  const char *pattern = list_node->section_id_pattern;
  if (pattern[0] == '\0' && element != NULL) {
    pattern = element->section_id_pattern;
  }
  if (pattern[0] != '\0' && numbered_pattern_match(pattern, id, n)) {
    *has_n = 1;
    *stored = id;
    return;
  }
  *n = 0;
  *has_n = 0;
  *stored = id;
}

static MdListState *parser_find_list_state(MdParser *p, const char *list_path) {
  for (size_t i = 0; i < p->lists_len; i++) {
    if (strcmp(p->lists[i].list_path, list_path) == 0) return &p->lists[i];
  }
  return NULL;
}

/* Sets body line `k` of `frame` to "". */
static void blank_body_line(MdFrame *frame, size_t k) {
  free(frame->body.items[k]);
  frame->body.items[k] = som_strdup("");
}

/* The form a section-table `Section` cell names under `node`: writes the form
 * path (owned) and its fields (owned array); 0 when it names none. */
static int section_table_target(MdParser *p, MdFrame *frame,
                                const SomMetaNode *node, const char *section,
                                char **form_path,
                                const SomFormFieldMeta ***fields,
                                size_t *fields_len) {
  /* `section.split(/\s*\/\s*\/)` */
  SomStrList parts;
  som_strlist_init(&parts);
  {
    const char *q = section;
    for (;;) {
      const char *slash = strchr(q, '/');
      size_t len = slash != NULL ? (size_t)(slash - q) : strlen(q);
      char *raw = som_strdup_n(q, len);
      size_t a = 0, b = strlen(raw);
      if (parts.len > 0) {
        while (a < b && is_ws(raw[a])) a++;
      }
      if (slash != NULL) {
        while (b > a && is_ws(raw[b - 1])) b--;
      }
      som_strlist_push(&parts, som_strdup_n(raw + a, b - a));
      free(raw);
      if (slash == NULL) break;
      q = slash + 1;
    }
  }
  int found = 0;
  NodeRelVec eff;
  effective_children(p->codec, node, &eff);
  for (size_t i = 0; i < eff.len && !found; i++) {
    const SomMetaNode *child = eff.items[i].node;
    char *child_id = heading_id_of(p->codec, child);
    if (parts.len == 1 && strcmp(child->kind, SOM_META_KIND_FORM) == 0 &&
        strcmp(child_id, section) == 0) {
      *form_path = spec_path_join(frame->path, eff.items[i].rel);
      *fields = form_fields_of(child, fields_len);
      found = 1;
    } else if (parts.len == 2 && strcmp(child->kind, SOM_META_KIND_LIST) == 0 &&
               strcmp(child_id, parts.items[0]) == 0) {
      const SomMetaNode *element = child->element_node;
      char *form_rel = NULL;
      const SomMetaNode *form =
          element != NULL ? item_form(p->codec, element, &form_rel) : NULL;
      if (form == NULL) {
        free(child_id);
        break; /* `return null` */
      }
      long long n = 0;
      int has_n = 0;
      const char *stored = "";
      item_identity(child, parts.items[1], &n, &has_n, &stored);
      char *list_path = spec_path_join(frame->path, eff.items[i].rel);
      char *item_path = NULL;
      MdListState *state = parser_find_list_state(p, list_path);
      if (state != NULL) {
        size_t lp = strlen(list_path);
        for (size_t k = 0; k < state->items.len && item_path == NULL; k++) {
          const char *ip = state->items.items[k];
          const char *sid = som_map_get(&state->ids, ip);
          const char *have = sid != NULL ? sid
                             : strlen(ip) > lp ? ip + lp + 1
                                               : "";
          if (strcmp(have, parts.items[1]) == 0) item_path = som_strdup(ip);
        }
      }
      if (item_path == NULL) {
        item_path = parser_open_item(p, 0, list_path, child, n, stored, has_n,
                                     "", "", frame->line, 0);
      }
      *form_path = vcat3(item_path, "/", form_rel);
      *fields = form_fields_of(form, fields_len);
      found = 1;
      free(item_path);
      free(list_path);
      free(form_rel);
    }
    free(child_id);
  }
  nrv_free(&eff);
  som_strlist_free(&parts);
  return found;
}

/* Reads and removes every section table of `frame`'s body (SOM §11.5). */
static void extract_section_tables(MdParser *p, MdFrame *frame,
                                   const SomMetaNode *node) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  size_t base = frame->line + 1;
  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    int is_section = 0;
    if (spec_markdown_fence_in_fence(&fence) ||
        !match_layout_header(line, 0, &is_section) || !is_section) {
      spec_markdown_fence_feed(&fence, line);
      continue;
    }
    MdTable table;
    read_table(p, frame->body.items, frame->body.len, i, base, frame->path,
               &table);
    char *form_path = NULL;
    const SomFormFieldMeta **fields = NULL;
    size_t fields_len = 0;
    int skip = 0;
    for (size_t r = 0; r < table.rows_len; r++) {
      const MdRow *row = &table.rows[r];
      char *section = cell_id(row->cells.items[0]);
      size_t line_no = base + row->index;
      if (section[0] == '\0' && skip) {
        free(section);
        continue;
      }
      if (section[0] != '\0') {
        free(form_path);
        form_path = NULL;
        free((void *)fields);
        fields = NULL;
        fields_len = 0;
        int ok = section_table_target(p, frame, node, section, &form_path,
                                      &fields, &fields_len);
        skip = !ok;
        if (!ok) {
          char *msg = vcat3("section-table row names no child section of \"",
                            frame->path, "\"");
          parser_push_rejection(p, line_no,
                                SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION, msg,
                                section);
          free(msg);
          free(section);
          continue;
        }
      } else if (form_path == NULL) {
        parser_push_rejection(p, line_no, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                              "section-table row names no section",
                              frame->path);
        free(section);
        continue;
      }
      free(section);
      if (skip) continue;
      stage_row(p, form_path, fields, fields_len, row->cells.items[1],
                row->cells.items[2], line_no);
    }
    free(form_path);
    free((void *)fields);
    for (size_t k = i; k < table.end; k++) blank_body_line(frame, k);
    i = table.end - 1;
    md_table_free(&table);
  }
}

/* ---- reading view: list bodies, `refs` and `records` (SOM §11.5) -------- */

/* `^:{3,}\s*(?:\{\.(refs|records)\}|(refs|records))\s*$`: writes the kind. */
static int match_list_div_open(const char *line, const char **kind) {
  size_t i = 0;
  while (line[i] == ':') i++;
  if (i < 3) return 0;
  skip_ws(line, &i);
  int braced = 0;
  if (line[i] == '{' && line[i + 1] == '.') {
    braced = 1;
    i += 2;
  }
  if (strncmp(line + i, "refs", 4) == 0) {
    *kind = "refs";
    i += 4;
  } else if (strncmp(line + i, "records", 7) == 0) {
    *kind = "records";
    i += 7;
  } else {
    return 0;
  }
  if (braced) {
    if (line[i] != '}') return 0;
    i++;
  }
  skip_ws(line, &i);
  return line[i] == '\0';
}

/* `^:{3,}\s*$`. */
static int match_list_div_close(const char *line) {
  size_t i = 0;
  while (line[i] == ':') i++;
  if (i < 3) return 0;
  skip_ws(line, &i);
  return line[i] == '\0';
}

static int has_extra(const SomMetaNode *n, const char *annotation) {
  for (size_t i = 0; i < n->extra_len; i++) {
    if (strcmp(n->extra[i].annotation, annotation) == 0) return 1;
  }
  return 0;
}

static int is_reference_form(const SomMetaNode *n) {
  return strcmp(n->kind, SOM_META_KIND_FORM) == 0 && n->form != NULL &&
         n->form->fields_len == 1 && n->form->fields[0].refers_to_len > 0 &&
         has_extra(n, "Reference");
}

/* The reference field of `element`'s items, with the rel of its form
 * (owned); NULL when its items are no references. */
static const SomFormFieldMeta *reference_field(MdCodec *c,
                                               const SomMetaNode *element,
                                               char **rel) {
  const SomFormFieldMeta *found = NULL;
  NodeRelVec slots;
  nrv_init(&slots);
  body_slots(c, element, &slots);
  for (size_t i = 0; i < slots.len && found == NULL; i++) {
    if (is_reference_form(slots.items[i].node)) {
      found = &slots.items[i].node->form->fields[0];
      *rel = som_strdup(slots.items[i].rel);
    }
  }
  nrv_free(&slots);
  if (found != NULL) return found;
  NodeRelVec eff;
  effective_children(c, element, &eff);
  for (size_t i = 0; i < eff.len && found == NULL; i++) {
    if (is_reference_form(eff.items[i].node)) {
      found = &eff.items[i].node->form->fields[0];
      *rel = som_strdup(eff.items[i].rel);
    }
  }
  nrv_free(&eff);
  return found;
}

/* A `refs` div: ids split on commas and whitespace, links read as their
 * texts. `inner` is the div's body; `at` the body index of its opening. */
static void stage_reference_line(MdParser *p, MdFrame *frame,
                                 const SomMetaNode *list_node,
                                 char *const *inner, size_t inner_len,
                                 size_t at) {
  size_t line_no = frame->line + 1 + at;
  const SomMetaNode *element = list_node->element_node;
  char *ref_rel = NULL;
  const SomFormFieldMeta *ref =
      element != NULL ? reference_field(p->codec, element, &ref_rel) : NULL;
  if (ref == NULL) {
    parser_push_rejection(p, line_no, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                          "a refs div in a list whose items are not "
                          "references",
                          frame->path);
    return;
  }
  SomBuf joined;
  som_buf_init(&joined);
  for (size_t k = 0; k < inner_len; k++) {
    if (k > 0) som_buf_putc(&joined, ' ');
    som_buf_puts(&joined, inner[k]);
  }
  char *all = som_buf_take(&joined);
  SomStrList ids;
  som_strlist_init(&ids);
  size_t i = 0;
  while (all[i] != '\0') {
    while (all[i] != '\0' && (all[i] == ',' || is_ws(all[i]))) i++;
    size_t a = i;
    while (all[i] != '\0' && all[i] != ',' && !is_ws(all[i])) i++;
    if (i > a) {
      char *token = som_strdup_n(all + a, i - a);
      /* `_LINK_TEXT.exec(token)`: the first link anywhere in the token. */
      char *id = NULL;
      for (size_t k = 0; token[k] != '\0' && id == NULL; k++) {
        size_t at_k = k, ta, tb;
        if (link_at(token, &at_k, &ta, &tb)) id = som_strdup_n(token + ta, tb - ta);
      }
      som_strlist_push(&ids, id != NULL ? id : som_strdup(token));
      free(token);
    }
  }
  free(all);
  if (ids.len == 0) {
    parser_push_rejection(p, line_no, SPEC_MARKDOWN_REJECT_MISSING_VALUE,
                          "an empty refs div", frame->path);
    som_strlist_free(&ids);
    free(ref_rel);
    return;
  }
  const char *pattern = list_node->section_id_pattern;
  if (pattern[0] == '\0' && element != NULL) pattern = element->section_id_pattern;
  const char *member = list_node->member_name[0] != '\0'
                           ? list_node->member_name
                           : som_meta_node_segment(list_node);
  for (size_t n = 1; n <= ids.len; n++) {
    char *positional = spec_effective_list_item_section_id(
        NULL, pattern[0] != '\0' ? pattern : NULL, (long long)n, member);
    long long num = 0;
    int has_n = 0;
    const char *stored = "";
    item_identity(list_node, positional, &num, &has_n, &stored);
    char *item_path = parser_open_item(p, 0, frame->path, list_node, num,
                                       stored, has_n, "", "", frame->line, 0);
    char *form_path = strcmp(ref_rel, ".") == 0
                          ? som_strdup(item_path)
                          : vcat3(item_path, "/", ref_rel);
    staged_set_form(p, form_path, ref->name, ids.items[n - 1]);
    free(form_path);
    free(item_path);
    free(positional);
  }
  som_strlist_free(&ids);
  free(ref_rel);
}

/* A `records` div: one table, `Id` first, `Title` optionally second. */
static void stage_record_table(MdParser *p, MdFrame *frame,
                               const SomMetaNode *list_node,
                               char *const *inner, size_t inner_len,
                               size_t at) {
  size_t open_line = frame->line + 1 + at;
  size_t base = open_line + 1; /* inner line k is source line base + k */
  size_t start = 0;
  while (start < inner_len) {
    char *t = trim_space(inner[start]);
    int empty = t[0] == '\0';
    free(t);
    if (!empty) break;
    start++;
  }
  if (start >= inner_len || !match_table_line(inner[start])) {
    parser_push_rejection(p, open_line, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                          "a records div holding no table", frame->path);
    return;
  }
  SomStrList header;
  row_cells(inner[start], &header);
  if (strcmp(header.items[0], "Id") != 0) {
    parser_push_rejection(p, open_line, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                          "a records table whose first column is not Id",
                          frame->path);
    som_strlist_free(&header);
    return;
  }
  const SomMetaNode *element = list_node->element_node;
  char *form_rel = NULL;
  const SomMetaNode *form =
      element != NULL ? item_form(p->codec, element, &form_rel) : NULL;
  if (form == NULL) {
    parser_push_rejection(p, open_line, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                          "a records div in a list whose items have no single "
                          "form",
                          frame->path);
    som_strlist_free(&header);
    return;
  }
  int with_title = header.len > 1 && strcmp(header.items[1], "Title") == 0;
  size_t first_column = with_title ? 2 : 1;
  size_t columns_len = header.len > first_column ? header.len - first_column : 0;
  const SomFormFieldMeta **columns =
      columns_len ? malloc(columns_len * sizeof(*columns)) : NULL;
  for (size_t c = 0; c < columns_len; c++) {
    const SomFormFieldMeta *f = form_field_ci(form, header.items[first_column + c]);
    if (f == NULL) {
      char *msg = vcat3("records column \"", header.items[first_column + c],
                        "\" names no field of the items");
      parser_push_rejection(p, base + start, SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
                            msg, frame->path);
      free(msg);
      free((void *)columns);
      free(form_rel);
      som_strlist_free(&header);
      return;
    }
    columns[c] = f;
  }
  som_strlist_free(&header);
  MdTable table;
  read_table(p, inner, inner_len, start, base, frame->path, &table);
  char *stem = md_item_stem_of(list_node);
  for (size_t r = 0; r < table.rows_len; r++) {
    const MdRow *row = &table.rows[r];
    char *id = cell_id(row->cells.items[0]);
    long long n = 0;
    int has_n = 0;
    const char *stored = "";
    item_identity(list_node, id, &n, &has_n, &stored);
    char *item_path = parser_open_item(p, 0, frame->path, list_node, n, stored,
                                       has_n, "", "", base + row->index, 0);
    if (with_title) {
      char *unescaped = replace_all(row->cells.items[1], "\\|", "|");
      char *title = replace_all(unescaped, "<br>", "\n");
      free(unescaped);
      const char *number = item_path + strlen(frame->path) + 1;
      char *deflt = vcat3(stem, " ", number);
      if (title[0] != '\0' && strcmp(title, deflt) != 0) {
        som_map_set(&p->staged.headlines, item_path, title);
      }
      free(deflt);
      free(title);
    }
    char *form_path = vcat3(item_path, "/", form_rel);
    for (size_t c = 0; c < columns_len; c++) {
      char *value = cell_value(row->cells.items[first_column + c], columns[c]);
      if (value[0] != '\0') staged_set_form(p, form_path, columns[c]->name, value);
      free(value);
    }
    free(form_path);
    free(item_path);
    free(id);
  }
  free(stem);
  md_table_free(&table);
  free((void *)columns);
  free(form_rel);
}

/* A list container's body: one `refs` or `records` div stands for its items. */
static void finalize_list_body(MdParser *p, MdFrame *frame,
                               const SomMetaNode *list_node) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    const char *kind = NULL;
    if (spec_markdown_fence_in_fence(&fence) || !match_list_div_open(line, &kind)) {
      spec_markdown_fence_feed(&fence, line);
      continue;
    }
    size_t line_no = frame->line + 1 + i;
    size_t close = frame->body.len;
    for (size_t k = i + 1; k < frame->body.len; k++) {
      if (match_list_div_close(frame->body.items[k])) {
        close = k;
        break;
      }
    }
    if (close == frame->body.len) {
      char *msg = vcat3("unclosed ", kind, " fence");
      parser_push_rejection(p, line_no, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK,
                            msg, frame->path);
      free(msg);
      return;
    }
    int beside_text = 0;
    for (size_t k = 0; k < frame->body.len; k++) {
      if (k >= i && k <= close) continue;
      char *t = trim_space(frame->body.items[k]);
      if (t[0] != '\0') beside_text = 1;
      free(t);
    }
    MdListState *state = parser_find_list_state(p, frame->path);
    int has_items = state != NULL && state->items.len > 0;
    if (beside_text || has_items) {
      SomBuf msg;
      som_buf_init(&msg);
      som_buf_puts(&msg, "a ");
      som_buf_puts(&msg, kind);
      som_buf_puts(&msg, " div beside ");
      som_buf_puts(&msg, has_items ? "item headings" : "other text");
      som_buf_puts(&msg, " in a list container");
      char *m = som_buf_take(&msg);
      parser_push_rejection(p, line_no, SPEC_MARKDOWN_REJECT_MALFORMED_BLOCK, m,
                            frame->path);
      free(m);
      for (size_t k = i; k <= close; k++) blank_body_line(frame, k);
      return;
    }
    char *const *inner = frame->body.items + i + 1;
    size_t inner_len = close - i - 1;
    if (strcmp(kind, "refs") == 0) {
      stage_reference_line(p, frame, list_node, inner, inner_len, i);
    } else {
      stage_record_table(p, frame, list_node, inner, inner_len, i);
    }
    for (size_t k = i; k <= close; k++) blank_body_line(frame, k);
    return;
  }
}

static int match_layout_header_shaped(const char *line) {
  return match_layout_header(line, 1, NULL);
}

static int match_layout_header_escaped(const char *line) {
  return match_layout_header(line, 2, NULL);
}

/* ---- finalize form ------------------------------------------------------ */

/* finalizeForm: parses an id-bearing `@Form` section's body — `FieldName:`
 * paragraphs and form-table rows bind to the named fields wherever they stand
 * (SOM §11.4); the text that belongs to no field — before the first field, or
 * after a table — is the form's preamble, its own content (rule 7), its parts
 * joined by one blank line. A field given twice keeps its first value. */
static void finalize_form(MdParser *p, MdFrame *frame, const SomMetaNode *node,
                          const char *path) {
  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  const SomFormFieldMeta *current_field = NULL;
  int discard = 0;
  LineVec current;
  lv_init(&current);
  size_t declared_len = 0;
  const SomFormFieldMeta **declared = form_fields_of(node, &declared_len);
  /* The preamble's parts: the text before the first field, and text a table
   * interrupts. */
  LineVec *parts = malloc(sizeof(LineVec));
  size_t parts_len = 1;
  lv_init(&parts[0]);
  size_t base = frame->line + 1;

#define FORM_FLUSH()                                                          \
  do {                                                                        \
    if (current_field != NULL && !discard) {                                  \
      char *value = restore_value(current.items, current.len);               \
      if (current_field->code) {                                              \
        value = decode_code_span(value);                                      \
      }                                                                       \
      if (value[0] != '\0') {                                                 \
        staged_set_form(p, path, current_field->name, value);                \
      }                                                                       \
      free(value);                                                            \
    }                                                                         \
    lv_free(&current);                                                        \
    lv_init(&current);                                                        \
    discard = 0;                                                              \
  } while (0)

  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      int is_section = 0;
      if (match_layout_header(line, 0, &is_section) && !is_section) {
        FORM_FLUSH();
        current_field = NULL;
        parts = realloc(parts, (parts_len + 1) * sizeof(LineVec));
        lv_init(&parts[parts_len++]);
        MdTable table;
        read_table(p, frame->body.items, frame->body.len, i, base, path, &table);
        for (size_t r = 0; r < table.rows_len; r++) {
          stage_row(p, path, declared, declared_len,
                    table.rows[r].cells.items[0], table.rows[r].cells.items[1],
                    base + table.rows[r].index);
        }
        i = table.end - 1;
        md_table_free(&table);
        continue;
      }
      char *label = NULL;
      char *value = NULL;
      if (match_field_label(line, &label, &value)) {
        const SomFormFieldMeta *field = form_field_ci(node, label);
        if (field != NULL) {
          FORM_FLUSH();
          current_field = field;
          discard = given_twice(p, path, field->name, base + i);
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
    LineVec *target = current_field == NULL ? &parts[parts_len - 1] : &current;
    if (!spec_markdown_fence_in_fence(&fence) &&
        match_continuation_label(line)) {
      lv_push(target, som_strdup(line + 1));
    } else {
      lv_push(target, som_strdup(line));
    }
    spec_markdown_fence_feed(&fence, line);
  }
  FORM_FLUSH();
#undef FORM_FLUSH
  lv_free(&current);
  SomBuf b;
  som_buf_init(&b);
  for (size_t k = 0; k < parts_len; k++) {
    char *v = restore_value(parts[k].items, parts[k].len);
    if (v[0] != '\0') {
      if (b.len > 0) som_buf_puts(&b, "\n\n");
      som_buf_puts(&b, v);
    }
    free(v);
    lv_free(&parts[k]);
  }
  free(parts);
  char *preamble = som_buf_take(&b);
  if (preamble[0] != '\0') staged_set_content(p, path, preamble);
  free(preamble);
  free((void *)declared);
}

/* ---- finalize body slots ------------------------------------------------ */

/* mdSlotMarkerRE = `^<!-- slot: (\S+) -->$` (SOM §11.6). On match returns an
 * owned copy of the rel (a body slot's path relative to its owner, or `.`). */
static char *match_slot_marker(const char *line) {
  static const char prefix[] = "<!-- slot: ";
  static const char suffix[] = " -->";
  size_t plen = sizeof(prefix) - 1;
  if (strncmp(line, prefix, plen) != 0) {
    return NULL;
  }
  const char *rel = line + plen;
  size_t n = 0;
  while (rel[n] != '\0' && !is_ws(rel[n])) {
    n++;
  }
  if (n == 0 || strcmp(rel + n, suffix) != 0) {
    return NULL;
  }
  return som_strdup_n(rel, n);
}

/* One run of unlabelled body text and the path it binds to. */
typedef struct {
  char *path; /* owned */
  LineVec lines;
} MdTextPart;

typedef struct {
  MdTextPart *items;
  size_t len;
  size_t cap;
} MdTextParts;

/* Opens a new text part targeting `path` (taken over); returns its index. */
static size_t text_parts_open(MdTextParts *v, char *path) {
  if (v->len == v->cap) {
    v->cap = v->cap ? v->cap * 2 : 4;
    v->items = (MdTextPart *)realloc(v->items, v->cap * sizeof(MdTextPart));
  }
  v->items[v->len].path = path;
  lv_init(&v->items[v->len].lines);
  return v->len++;
}

static void text_parts_free(MdTextParts *v) {
  for (size_t i = 0; i < v->len; i++) {
    free(v->items[i].path);
    lv_free(&v->items[i].lines);
  }
  free(v->items);
  v->items = NULL;
  v->len = 0;
  v->cap = 0;
}

/* The field `label` (any case) names in the form slots, searched from the
 * current form on and wrapping; writes the slot's index. NULL when none. */
static const SomFormFieldMeta *find_slot_field(MdParser *p,
                                               const NodeRelVec *forms,
                                               const char *label, int *idx) {
  const SomFormFieldMeta *found = NULL;
  char *lower = lower_dup(label);
  for (size_t k = 0; k < forms->len && found == NULL; k++) {
    size_t at = ((size_t)p->current_form_idx + k) % forms->len;
    const SomMetaNode *fn = forms->items[at].node;
    if (fn->form == NULL) continue;
    for (size_t fi = 0; fi < fn->form->fields_len; fi++) {
      char *fl = lower_dup(fn->form->fields[fi].name);
      int hit = strcmp(fl, lower) == 0;
      free(fl);
      if (hit) {
        found = &fn->form->fields[fi];
        *idx = (int)at;
        break;
      }
    }
  }
  free(lower);
  return found;
}

/* Binds a heading's body region against the owner's transparent body slots
 * (SOM §11.6): `FieldName:` lines matching a transparent form's fields route
 * to that form (nearest form in slot order, wrapping); a slot marker
 * (`<!-- slot: <rel> -->`) sends the text after it to the named slot — a
 * content slot, a form's preamble, or the owner itself (`.`) — and ends any
 * open field. Unmarked text binds to the first content slot; with no content
 * slot it is a form's preamble (SOM §11.4 rule 7) — the form slot named
 * `content`, else the first form slot. Only an owner with no slot at all takes
 * the text on its own path. In a region with any form, a label-shaped text
 * line has its one escape space stripped. A target opened more than once gets
 * its parts joined by one blank line. */
static void finalize_body_slots(MdParser *p, MdFrame *frame, NodeRelVec *slots) {
  /* form slots (borrowed nodes, copied rels), in slot order */
  NodeRelVec forms;
  nrv_init(&forms);
  for (size_t i = 0; i < slots->len; i++) {
    if (strcmp(slots->items[i].node->kind, SOM_META_KIND_FORM) == 0) {
      nrv_push(&forms, slots->items[i].node, som_strdup(slots->items[i].rel));
    }
  }
  const char *default_rel = default_body_rel(slots);

  SpecMarkdownFenceTracker fence;
  spec_markdown_fence_init(&fence);
  const char *current_field = NULL;
  char *current_form_path = NULL;
  int current_code = 0;
  int have_field = 0;
  int discard = 0;
  LineVec current;
  lv_init(&current);
  MdTextParts parts = {NULL, 0, 0};
  size_t content_part = text_parts_open(
      &parts, strcmp(default_rel, ".") == 0
                  ? som_strdup(frame->path)
                  : spec_path_join(frame->path, default_rel));

  p->current_form_idx = 0;

#define SLOTS_FLUSH()                                                         \
  do {                                                                        \
    if (have_field && !discard) {                                             \
      char *v = restore_value(current.items, current.len);                   \
      if (current_code) {                                                     \
        v = decode_code_span(v);                                              \
      }                                                                       \
      if (v[0] != '\0') {                                                     \
        staged_set_form(p, current_form_path, current_field, v);             \
      }                                                                       \
      free(v);                                                                \
    }                                                                         \
    lv_free(&current);                                                        \
    lv_init(&current);                                                        \
    discard = 0;                                                              \
  } while (0)

  for (size_t i = 0; i < frame->body.len; i++) {
    const char *line = frame->body.items[i];
    if (!spec_markdown_fence_in_fence(&fence)) {
      char *rel = match_slot_marker(line);
      if (rel != NULL) {
        int is_owner = strcmp(rel, ".") == 0;
        size_t slot_idx = slots->len;
        for (size_t k = 0; !is_owner && k < slots->len; k++) {
          if (strcmp(slots->items[k].rel, rel) == 0) {
            slot_idx = k;
            break;
          }
        }
        if (is_owner || slot_idx < slots->len) {
          SLOTS_FLUSH();
          have_field = 0;
          current_field = NULL;
          free(current_form_path);
          current_form_path = NULL;
          if (!is_owner && strcmp(slots->items[slot_idx].node->kind,
                                  SOM_META_KIND_FORM) == 0) {
            for (size_t k = 0; k < forms.len; k++) {
              if (strcmp(forms.items[k].rel, rel) == 0) {
                p->current_form_idx = (int)k;
                break;
              }
            }
          }
          content_part = text_parts_open(
              &parts, is_owner ? som_strdup(frame->path)
                               : spec_path_join(frame->path, rel));
          free(rel);
          continue;
        }
        free(rel);
      }
      int is_section = 0;
      if (forms.len > 0 && match_layout_header(line, 0, &is_section) &&
          !is_section) {
        /* A form table ends the open field (SOM §11.4); its rows bind like
         * `Field:` labels, each to the nearest form declaring it. */
        SLOTS_FLUSH();
        have_field = 0;
        current_field = NULL;
        free(current_form_path);
        current_form_path = NULL;
        size_t base = frame->line + 1;
        MdTable table;
        read_table(p, frame->body.items, frame->body.len, i, base, frame->path,
                   &table);
        for (size_t r = 0; r < table.rows_len; r++) {
          const char *row_label = table.rows[r].cells.items[0];
          int hit_idx = -1;
          const SomFormFieldMeta *hit =
              find_slot_field(p, &forms, row_label, &hit_idx);
          size_t row_line = base + table.rows[r].index;
          if (hit == NULL) {
            char *msg =
                vcat3("row \"", row_label, "\" names no field of this form");
            parser_push_rejection(p, row_line, SPEC_MARKDOWN_REJECT_UNKNOWN_FIELD,
                                  msg, frame->path);
            free(msg);
            continue;
          }
          p->current_form_idx = hit_idx;
          char *form_path =
              spec_path_join(frame->path, forms.items[hit_idx].rel);
          stage_row(p, form_path, &hit, 1, row_label,
                    table.rows[r].cells.items[1], row_line);
          free(form_path);
        }
        i = table.end - 1;
        md_table_free(&table);
        continue;
      }
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
          SLOTS_FLUSH();
          p->current_form_idx = found_idx;
          have_field = 1;
          current_field = found_field->name;
          current_code = found_field->code;
          free(current_form_path);
          current_form_path =
              spec_path_join(frame->path, forms.items[found_idx].rel);
          discard = given_twice(p, current_form_path, current_field,
                                frame->line + 1 + i);
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
    /* In a region with forms every label-shaped text line carries the one
     * escape space the emitter adds (SOM §11.4 rule 3); strip it. */
    const char *text = line;
    if (!spec_markdown_fence_in_fence(&fence) && forms.len > 0 &&
        match_continuation_label(line)) {
      text = line + 1;
    }
    if (have_field) {
      lv_push(&current, som_strdup(text));
    } else {
      lv_push(&parts.items[content_part].lines, som_strdup(text));
    }
    spec_markdown_fence_feed(&fence, line);
  }
  SLOTS_FLUSH();
#undef SLOTS_FLUSH

  /* one value per target path, in the order the targets were first opened */
  for (size_t i = 0; i < parts.len; i++) {
    int seen = 0;
    for (size_t k = 0; k < i && !seen; k++) {
      seen = strcmp(parts.items[k].path, parts.items[i].path) == 0;
    }
    if (seen) {
      continue;
    }
    SomBuf b;
    som_buf_init(&b);
    for (size_t k = i; k < parts.len; k++) {
      if (strcmp(parts.items[k].path, parts.items[i].path) != 0) {
        continue;
      }
      char *v = restore_value(parts.items[k].lines.items,
                              parts.items[k].lines.len);
      if (v[0] != '\0') {
        if (b.len > 0) {
          som_buf_puts(&b, "\n\n");
        }
        som_buf_puts(&b, v);
      }
      free(v);
    }
    char *value = som_buf_take(&b);
    if (value[0] != '\0') {
      staged_set_content(p, parts.items[i].path, value);
    }
    free(value);
  }
  lv_free(&current);
  text_parts_free(&parts);
  free(current_form_path);
  nrv_free(&forms);
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
  /* The reading view (SOM §11.5): a list container's refs / records div, a
   * section's section tables. */
  if (node != NULL && strcmp(node->kind, SOM_META_KIND_LIST) == 0) {
    finalize_list_body(p, frame, node);
  } else if (node != NULL && (strcmp(node->kind, SOM_META_KIND_SECTION) == 0 ||
                              strcmp(node->kind, SOM_META_KIND_COMPLEX) == 0)) {
    extract_section_tables(p, frame, node);
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
  free(f->anchor_scope);
  free(f->anchor_section);
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
  f->anchor_scope = NULL;
  f->anchor_section = NULL;
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

/* Opens item `n` (or, without `has_n`, the next free one) of the list at
 * `list_path`, staging its stored id, title and codeSpec; pushes its frame
 * when `push` (a heading's item) and returns its path (owned). */
static char *parser_open_item(MdParser *p, int level, const char *list_path,
                              const SomMetaNode *list_node, long long n,
                              const char *stored_id, int has_n,
                              const char *title, const char *code_spec,
                              size_t line, int push) {
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
  /* A stored id is staged for an anonymous next item and for a numbered
     `@SectionIdPattern` id (copied — the map owns its strings); the
     `<member>-<n>` fallback passes "" and stores nothing. */
  if (!has_n || (stored_id != NULL && stored_id[0] != '\0')) {
    som_map_set(&state->ids, item_path, stored_id != NULL ? stored_id : "");
  }
  /* SOM §11.7: stage the heading title as a stored headline only when it
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
  /* codespecs_mapping.md §9.2: stage the item codeSpec mapping whenever present (no default). */
  if (code_spec != NULL && code_spec[0] != '\0') {
    som_map_set(&p->staged.code_specs, item_path, code_spec);
  }
  /* SOM §11.2: `units` is staged exactly like codeSpec. */
  if (p->heading_units != NULL && p->heading_units[0] != '\0') {
    som_map_set(&p->staged.units, item_path, p->heading_units);
  }
  free(num);
  if (push) {
    parser_push_frame(p, level, list_node->element_node, som_strdup(item_path),
                      line, 0);
  }
  return item_path;
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

/* Opens a list-item frame under a `-LST` container frame (SOM §11.2). The
   heading `id` is matched positionally against the container's list: the
   `<member>-<n>` fallback id (positional, nothing stored), the
   `@SectionIdPattern` resolved with a number (`GOAL-ITEM-3`, parses back as
   item <n> carrying that id), a pattern-shaped stored id, or — for any other
   id — an anonymous next item carrying the stored id. */
static void parser_open_item_heading(MdParser *p, int level,
                                     const char *list_path,
                                     const SomMetaNode *list_node,
                                     const char *id, const char *title,
                                     const char *code_spec, size_t line) {
  long long n = 0;
  int has_n = 0;
  const char *stored = "";
  item_identity(list_node, id, &n, &has_n, &stored);
  free(parser_open_item(p, level, list_path, list_node, n, stored, has_n,
                        title, code_spec, line, 1));
}

/* The anchor of heading `id` below a frame with anchor `scope` and section
 * `section`, and the scope its own frame carries (`_qualifyAnchor`, SOM
 * §11.2): a list container keeps the scope, a list item adds its id to it, a
 * `@SameAs` copy starts one from the section, anything else adds its id when
 * there is a scope. Both owned; `*new_scope` may be NULL. */
static char *join_scope(const char *scope, const char *id) {
  if (scope == NULL || scope[0] == '\0') return som_strdup(id);
  return vcat3(scope, "/", id);
}

static void qualify_anchor(const char *scope, const char *section,
                           const char *id, int container, int item, int copy,
                           char **anchor, char **new_scope) {
  if (container) {
    *anchor = join_scope(scope, id);
    *new_scope = scope != NULL ? som_strdup(scope) : NULL;
    return;
  }
  if (item) {
    *anchor = join_scope(scope, id);
    *new_scope = join_scope(scope, id);
    return;
  }
  if (copy) {
    const char *from = scope != NULL ? scope : section;
    *anchor = join_scope(from, id);
    *new_scope = join_scope(from, id);
    return;
  }
  *anchor = join_scope(scope, id);
  *new_scope = scope != NULL ? join_scope(scope, id) : NULL;
}

/* Whether `n` is a `@SameAs` copy: its member carries the annotation. */
static int is_copy_node(const MdCodec *c, const SomMetaNode *n) {
  if (n->member_name[0] == '\0' || n->parent == NULL) return 0;
  const SpecClass *cls = spec_model_class_named(c->model, n->parent->class_name);
  if (cls == NULL) return 0;
  const SpecField *f = spec_class_field_named(cls, n->member_name);
  return f != NULL && spec_annotations_named(&f->annotations, "SameAs") != NULL;
}

/* A heading's title read from its `rest` with the renderer's anchor removed:
 * `<a id="ID"></a>` for its section id `id` or for its qualified `anchor`
 * (DI-3, SOM §11.2), then `<br>` read as a line break. Owned. */
static char *heading_title_with(const char *rest, const char *id,
                                const char *anchor) {
  char *trimmed = trim_space(rest);
  char *hid = NULL, *region = NULL, *title = NULL;
  if (!match_headline_comment(trimmed, &hid, &region, &title)) {
    free(trimmed);
    return som_strdup("");
  }
  free(trimmed);
  free(hid);
  free(region);
  const char *t = title;
  const char *ids[2] = {id, anchor};
  for (int k = 0; k < 2; k++) {
    if (ids[k] == NULL) continue;
    char *a = vcat3("<a id=\"", ids[k], "\"></a>");
    size_t al = strlen(a);
    int hit = strncmp(t, a, al) == 0;
    free(a);
    if (hit) {
      t += al;
      while (*t != '\0' && is_ws(*t)) t++;
      break;
    }
  }
  char *out = replace_all(t, "<br>", "\n");
  free(title);
  return out;
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
  /* Reading view (DI-3): an anchor equal to the section id after the id
   * comment is the renderer's, not part of the title. */
  {
    char *anchor = vcat3("<a id=\"", id, "\"></a>");
    size_t al = strlen(anchor);
    if (strncmp(title, anchor, al) == 0) {
      const char *rest_title = title + al;
      while (*rest_title != '\0' && is_ws(*rest_title)) rest_title++;
      char *t = som_strdup(rest_title);
      free(title);
      title = t;
    }
    free(anchor);
  }
  /* A heading is one line: `<br>` in its title is a stored line break. */
  {
    char *t = title;
    char *w = title;
    while (*t != '\0') {
      if (strncmp(t, "<br>", 4) == 0) {
        *w++ = '\n';
        t += 4;
      } else {
        *w++ = *t++;
      }
    }
    *w = '\0';
  }
  /* codespecs_mapping.md §9.2: the optional key=value region (group 2) carries the codeSpec. */
  char *code_spec = spec_markdown_code_spec_of(region);
  /* SOM §11.2: the same region may carry the section's `units`. */
  char *units = spec_markdown_units_of(region);
  free(region);
  p->heading_units = units;

  if (p->stack_len == 0) {
    parser_open_root(p, level, id, title, code_spec, line);
    free(id);
    free(title);
    free(code_spec);
    p->heading_units = NULL;
    free(units);
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
    p->heading_units = NULL;
    free(units);
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
    p->heading_units = NULL;
    free(units);
    return;
  }

  char *parent_path = som_strdup(parent->path); /* stable across pushes */

  /* 1. Under a `-LST` container frame (SOM §11.2), every child heading is one of
     that list's items — resolved positionally, not by the schema tree. */
  if (strcmp(p_node->kind, SOM_META_KIND_LIST) == 0) {
    char *anchor = NULL, *scope = NULL;
    qualify_anchor(parent->anchor_scope, parent->anchor_section, id, 0, 1, 0,
                   &anchor, &scope);
    char *item_title = heading_title_with(rest, id, anchor);
    parser_open_item_heading(p, level, parent_path, p_node, id, item_title,
                             code_spec, line);
    MdFrame *last = &p->stack[p->stack_len - 1];
    last->anchor_scope = scope;
    last->anchor_section = som_strdup(id);
    free(item_title);
    free(anchor);
    free(parent_path);
    free(id);
    free(title);
    free(code_spec);
    p->heading_units = NULL;
    free(units);
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
      int container = strcmp(en->kind, SOM_META_KIND_LIST) == 0;
      char *anchor = NULL, *scope = NULL;
      qualify_anchor(parent->anchor_scope, parent->anchor_section, id,
                     container, 0, !container && is_copy_node(p->codec, en),
                     &anchor, &scope);
      char *child_title = heading_title_with(rest, id, anchor);
      char *section = container
                          ? (parent->anchor_section != NULL
                                 ? som_strdup(parent->anchor_section)
                                 : NULL)
                          : som_strdup(id);
      /* SOM §11.7: stage the heading title as a stored headline only when it
         differs from the derived default title of this node. */
      if (child_title[0] != '\0') {
        char *deflt = md_title_of(en);
        if (strcmp(child_title, deflt) != 0) {
          som_map_set(&p->staged.headlines, path, child_title);
        }
        free(deflt);
      }
      free(child_title);
      free(anchor);
      /* codespecs_mapping.md §9.2: stage the codeSpec mapping whenever present (no default). */
      if (code_spec[0] != '\0') {
        som_map_set(&p->staged.code_specs, path, code_spec);
      }
      /* SOM §11.2: `units` is staged exactly like codeSpec. */
      if (p->heading_units != NULL && p->heading_units[0] != '\0') {
        som_map_set(&p->staged.units, path, p->heading_units);
      }
      parser_push_frame(p, level, en, path, line, 0);
      p->stack[p->stack_len - 1].anchor_scope = scope;
      p->stack[p->stack_len - 1].anchor_section = section;
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
    p->heading_units = NULL;
    free(units);
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
  p->heading_units = NULL;
  free(units);
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
      /* SOM §11.7: stage the root heading title as a stored headline only
         when it differs from the effective default (YRD4: `@Headline`
         default, else the root's declared title). */
      const char *root_default = tree->root->headline[0] != '\0'
                                     ? tree->root->headline
                                     : root->title;
      if (title != NULL && title[0] != '\0' &&
          strcmp(title, root_default) != 0) {
        som_map_set(&p->staged.headlines, seg, title);
      }
      /* codespecs_mapping.md §9.2: stage the root codeSpec mapping whenever present. */
      if (code_spec != NULL && code_spec[0] != '\0') {
        som_map_set(&p->staged.code_specs, seg, code_spec);
      }
      /* SOM §11.2: `units` is staged exactly like codeSpec. */
      if (p->heading_units != NULL && p->heading_units[0] != '\0') {
        som_map_set(&p->staged.units, seg, p->heading_units);
      }
      parser_push_frame(p, level, tree->root, som_strdup(seg), line, 0);
      p->stack[p->stack_len - 1].anchor_section = som_strdup(seg);
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
  p.heading_units = NULL;
  som_map_init(&p.given);

  LineVec lines;
  split_lines(text, &lines);

  for (size_t i = 0; i < lines.len; i++) {
    const char *raw = lines.items[i];
    size_t line_no = i + 1;
    char *trimmed = strip_trailing_ws(raw);

    if (!spec_markdown_fence_in_fence(&p.fence)) {
      if (p.stack_len == 0 && is_docspec_comment(trimmed)) {
        free(trimmed);
        continue; /* SOM §11.1 header */
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
  som_map_free(&p.given);
  codec_free(&codec);
}

/* ======================================================================== */
/* SpecDocument.ToMarkdown (one-line export, SOM §21)                        */
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

int spec_document_to_markdown_with_map(const SpecDocument *document,
                                       const SpecModel *model,
                                       const char *root_type,
                                       SpecMarkdownRendition *out,
                                       char **err) {
  out->markdown = NULL;
  out->headings = NULL;
  out->headings_len = 0;
  const SpecRoot *root;
  if (root_type != NULL && root_type[0] != '\0') {
    root = spec_model_root_by_type(model, root_type, err);
  } else {
    root = single_populated_root(model, document, err);
  }
  if (root == NULL) {
    return 0;
  }
  return spec_markdown_export_root_with_map(model, document, root, out, err);
}

/* ---- apply / one-call import (SOM §11.7) --------------------------------- */

/* Copies every entry of `src` into `dst`, overwriting same-key values. */
static void map_merge(SomMap *dst, const SomMap *src) {
  for (size_t i = 0; i < src->len; i++) {
    som_map_set(dst, src->entries[i].key, src->entries[i].val);
  }
}

int spec_document_apply_markdown_result(SpecDocument *doc,
                                        const SpecMarkdownResult *result,
                                        int allow_rejections,
                                        char **error_out) {
  if (!allow_rejections && result->rejections_len > 0) {
    const SpecMarkdownRejection *first = &result->rejections[0];
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "markdown import has ");
    som_buf_puti(&b, (long long)result->rejections_len);
    som_buf_puts(&b, " rejected block(s); first at line ");
    som_buf_puti(&b, (long long)first->line);
    som_buf_puts(&b, ": ");
    som_buf_puts(&b, first->message);
    set_err(error_out, som_buf_take(&b));
    return 1;
  }
  if (result->root_prefixes.len == 0) {
    return 0;
  }
  for (size_t i = 0; i < result->root_prefixes.len; i++) {
    spec_document_remove_values_under(doc, result->root_prefixes.items[i]);
  }

  /* Carry the surviving stores over, overlay the staged values (a staged
   * form or list replaces the held entry wholesale), then reload. */
  DocumentJson held;
  spec_document_to_json(doc, &held);
  const DocumentJson *staged = &result->staged;
  map_merge(&held.content, &staged->content);
  for (size_t i = 0; i < staged->forms_len; i++) {
    SomMap *fields = document_json_form_fields(&held, staged->forms[i].key);
    som_map_clear(fields);
    map_merge(fields, &staged->forms[i].fields);
  }
  for (size_t i = 0; i < staged->lists_len; i++) {
    const DocListEntry *src = &staged->lists[i];
    DocListEntry *dst = document_json_list_entry(&held, src->key);
    dst->seq = src->seq;
    som_strlist_free(&dst->items);
    som_strlist_copy(&dst->items, &src->items);
    som_map_clear(&dst->ids);
    map_merge(&dst->ids, &src->ids);
  }
  map_merge(&held.headlines, &staged->headlines);
  map_merge(&held.code_specs, &staged->code_specs);
  map_merge(&held.units, &staged->units);
  spec_document_load_json(doc, &held);
  document_json_free(&held);
  return 0;
}

void spec_markdown_import_free(SpecMarkdownImport *imp) {
  if (imp->document != NULL) {
    spec_document_free(imp->document);
    free(imp->document);
    imp->document = NULL;
  }
  spec_markdown_result_free(&imp->result);
}

void spec_document_from_markdown(const char *text, const SpecModel *model,
                                 SpecMarkdownImport *out) {
  out->document = (SpecDocument *)malloc(sizeof(SpecDocument));
  spec_document_init(out->document);
  spec_markdown_parse(model, text, &out->result);
  (void)spec_document_apply_markdown_result(out->document, &out->result, 1,
                                            NULL);
}
