/* spec_place — places and filters of the link vocabulary
 * (`tom_specs_model_rules.md` §9.7). See include/spec_place.h. */
#include "spec_place.h"

#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"
#include "spec_section_id.h"

/* ---- small helpers ------------------------------------------------------- */

static int is_alpha(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
static int is_digit(char c) { return c >= '0' && c <= '9'; }
static int is_alnum(char c) { return is_alpha(c) || is_digit(c); }

/* `^[A-Za-z0-9][A-Za-z0-9-]*$` over `s[0..n)`. */
static int is_segment_n(const char *s, size_t n) {
  if (n == 0 || !is_alnum(s[0])) return 0;
  for (size_t i = 1; i < n; i++) {
    if (!is_alnum(s[i]) && s[i] != '-') return 0;
  }
  return 1;
}

/* `^[A-Za-z_][A-Za-z0-9_]*$` over `s[0..n)`. */
static int is_field_n(const char *s, size_t n) {
  if (n == 0 || !(is_alpha(s[0]) || s[0] == '_')) return 0;
  for (size_t i = 1; i < n; i++) {
    if (!is_alnum(s[i]) && s[i] != '_') return 0;
  }
  return 1;
}

/* `^@?[A-Za-z_][A-Za-z0-9_]*$` over `s[0..n)`. */
static int is_slot_n(const char *s, size_t n) {
  if (n > 0 && s[0] == '@') return is_field_n(s + 1, n - 1);
  return is_field_n(s, n);
}

static char *concat3(const char *a, const char *b, const char *c) {
  SomBuf buf;
  som_buf_init(&buf);
  som_buf_puts(&buf, a);
  som_buf_puts(&buf, b);
  som_buf_puts(&buf, c);
  return som_buf_take(&buf);
}

static int ends_with(const char *s, const char *suffix) {
  size_t n = strlen(s), m = strlen(suffix);
  return n >= m && strcmp(s + n - m, suffix) == 0;
}

static void put_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

static void put_list(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    put_str(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

static void set_error(SpecPlaceError *err, const char *problem,
                      const char *text, char *message_owned) {
  if (err == NULL) {
    free(message_owned);
    return;
  }
  spec_place_error_free(err);
  err->problem = problem;
  err->text = som_strdup(text);
  err->message = message_owned;
}

void spec_place_error_init(SpecPlaceError *e) {
  e->problem = NULL;
  e->text = NULL;
  e->message = NULL;
}

void spec_place_error_free(SpecPlaceError *e) {
  free(e->text);
  free(e->message);
  spec_place_error_init(e);
}

/* ---- SpecPlace -------------------------------------------------------------- */

int spec_place_try_parse(const char *text, SpecPlace *out) {
  int scoped = strncmp(text, "./", 2) == 0;
  const char *body = scoped ? text + 2 : text;
  if (body[0] == '\0') return 0;
  const char *last = strrchr(body, '/');
  const char *last_start = last == NULL ? body : last + 1;
  /* The prefix segments, each a section id. */
  SomStrList prefix;
  som_strlist_init(&prefix);
  const char *seg = body;
  while (last != NULL && seg <= last) {
    const char *slash = strchr(seg, '/');
    if (!is_segment_n(seg, (size_t)(slash - seg))) {
      som_strlist_free(&prefix);
      return 0;
    }
    som_strlist_push(&prefix, som_strdup_n(seg, (size_t)(slash - seg)));
    seg = slash + 1;
  }
  const char *dot = strchr(last_start, '.');
  size_t id_len = dot == NULL ? strlen(last_start) : (size_t)(dot - last_start);
  if (!is_segment_n(last_start, id_len) ||
      (dot != NULL && !is_slot_n(dot + 1, strlen(dot + 1)))) {
    som_strlist_free(&prefix);
    return 0;
  }
  out->text = som_strdup(text);
  out->scoped = scoped;
  out->prefix = prefix;
  out->section_id = som_strdup_n(last_start, id_len);
  out->slot = (dot != NULL && dot[1] != '\0') ? som_strdup(dot + 1) : NULL;
  return 1;
}

int spec_place_parse(const char *text, SpecPlace *out, SpecPlaceError *err) {
  if (spec_place_try_parse(text, out)) return 1;
  set_error(err, SPEC_PLACE_PROBLEM_MALFORMED, text,
            som_strdup("is not a place (`<SECTIONID>[.<field>|.@headline|"
                       ".@content|.@sectionId]`, optionally `./`-scoped or a "
                       "`/` path)"));
  return 0;
}

void spec_place_free(SpecPlace *p) {
  free(p->text);
  som_strlist_free(&p->prefix);
  free(p->section_id);
  free(p->slot);
  memset(p, 0, sizeof(*p));
}

char *spec_place_to_json(const SpecPlace *p) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"scoped\":");
  som_buf_puts(&b, p->scoped ? "true" : "false");
  som_buf_puts(&b, ",\"prefix\":");
  put_list(&b, &p->prefix);
  som_buf_puts(&b, ",\"sectionId\":");
  put_str(&b, p->section_id);
  if (p->slot != NULL) {
    som_buf_puts(&b, ",\"slot\":");
    put_str(&b, p->slot);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- resolutions ------------------------------------------------------------ */

void spec_place_resolution_init(SpecPlaceResolution *r) {
  memset(r, 0, sizeof(*r));
  som_strlist_init(&r->section_ids);
}

void spec_place_resolution_free(SpecPlaceResolution *r) {
  free(r->path);
  som_strlist_free(&r->section_ids);
  spec_place_resolution_init(r);
}

const char *spec_place_resolution_field(const SpecPlaceResolution *r) {
  return r->form_field != NULL ? r->form_field->name : NULL;
}

char *spec_place_resolution_to_json(const SpecPlaceResolution *r) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"kind\":");
  put_str(&b, r->kind);
  som_buf_puts(&b, ",\"path\":");
  put_str(&b, r->path);
  if (r->form_field != NULL) {
    som_buf_puts(&b, ",\"field\":");
    put_str(&b, r->form_field->name);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- the positions of a subtree ------------------------------------------ */

typedef struct {
  char *path; /* owned */
  const SpecClass *cls;
  int is_list_element;
} PlaceScope;

typedef struct {
  const char *id; /* borrowed from the model */
  char *path;     /* owned */
  const char *class_name;
  const char *shape; /* section | list | form | content */
  int own_node;
  const FormFieldSpec *form_fields;
  size_t form_fields_len;
  char *form_path;    /* owned, NULL when none */
  char *content_path; /* owned, NULL when none */
  int is_list_element;
  SomStrList ids;
  const SpecField *member;
} PlacePosition;

typedef struct {
  PlacePosition *items;
  size_t len, cap;
} PlacePositions;

static void positions_free(PlacePositions *p) {
  for (size_t i = 0; i < p->len; i++) {
    free(p->items[i].path);
    free(p->items[i].form_path);
    free(p->items[i].content_path);
    som_strlist_free(&p->items[i].ids);
  }
  free(p->items);
  memset(p, 0, sizeof(*p));
}

static PlacePosition *positions_push(PlacePositions *p) {
  if (p->len == p->cap) {
    p->cap = p->cap ? p->cap * 2 : 16;
    p->items =
        (PlacePosition *)realloc(p->items, p->cap * sizeof(PlacePosition));
  }
  PlacePosition *pos = &p->items[p->len++];
  memset(pos, 0, sizeof(*pos));
  return pos;
}

static void ids_with(SomStrList *out, const SomStrList *ids, const char *id) {
  som_strlist_copy(out, ids);
  som_strlist_push_copy(out, id);
}

/* The class a complex or section member reaches. */
static const SpecClass *member_class(const SpecReflection *refl,
                                     const SpecField *f) {
  if (f->type == NULL) return NULL;
  SomBuf b;
  som_buf_init(&b);
  for (const char *c = f->type; *c; c++) {
    if (*c != '?') som_buf_putc(&b, *c);
  }
  char *name = som_buf_take(&b);
  const SpecClass *cls = spec_reflection_class_named(refl, name);
  free(name);
  return cls;
}

static int has_text(const char *s) { return s != NULL && s[0] != '\0'; }

static void walk(const SpecReflection *refl, const SpecClass *cls,
                 const char *path, const SomStrList *ids, int is_item,
                 const SpecField *via, SomStrList *on_path,
                 PlacePositions *out) {
  if (som_strlist_contains(on_path, cls->name)) return;
  som_strlist_push_copy(on_path, cls->name);
  const SpecField *content = spec_class_field_named(cls, "content");
  SomStrList here;
  som_strlist_init(&here);
  if (has_text(cls->section_id)) {
    ids_with(&here, ids, cls->section_id);
    PlacePosition *pos = positions_push(out);
    pos->id = cls->section_id;
    pos->path = som_strdup(path);
    pos->class_name = cls->name;
    pos->shape = "section";
    pos->own_node = 1;
    pos->is_list_element = is_item;
    if (content != NULL) {
      char *seg = concat3(path, "/", spec_reflection_field_segment(content));
      if (strcmp(content->kind, SPEC_FIELD_KIND_FORM) == 0) {
        pos->form_fields = content->form_fields;
        pos->form_fields_len = content->form_fields_len;
        pos->form_path = seg;
      } else if (strcmp(content->kind, SPEC_FIELD_KIND_CONTENT) == 0) {
        pos->content_path = seg;
      } else {
        free(seg);
      }
    }
    som_strlist_copy(&pos->ids, &here);
    pos->member = via;
  } else {
    som_strlist_copy(&here, ids);
  }
  for (size_t i = 0; i < cls->fields_len; i++) {
    const SpecField *f = &cls->fields[i];
    char *member_path = concat3(path, "/", spec_reflection_field_segment(f));
    SomStrList below;
    if (strcmp(f->name, "content") != 0 && has_text(f->section_id)) {
      ids_with(&below, &here, f->section_id);
      const char *shape;
      if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0) {
        shape = "list";
      } else if (strcmp(f->kind, SPEC_FIELD_KIND_FORM) == 0) {
        shape = "form";
      } else if (strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
                 strcmp(f->kind, SPEC_FIELD_KIND_SECTION) == 0) {
        shape = "section";
      } else {
        shape = "content";
      }
      PlacePosition *pos = positions_push(out);
      pos->id = f->section_id;
      pos->path = som_strdup(member_path);
      pos->class_name = cls->name;
      pos->shape = shape;
      pos->own_node = 0;
      if (strcmp(f->kind, SPEC_FIELD_KIND_FORM) == 0) {
        pos->form_fields = f->form_fields;
        pos->form_fields_len = f->form_fields_len;
        pos->form_path = som_strdup(member_path);
      }
      if (strcmp(shape, "content") == 0) {
        pos->content_path = som_strdup(member_path);
      }
      som_strlist_copy(&pos->ids, &below);
      pos->member = f;
    } else {
      som_strlist_copy(&below, &here);
    }
    if (!spec_annotations_have(&f->annotations, "Reference")) {
      if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0 && f->element_is_complex) {
        const SpecClass *el = spec_reflection_class_named(refl, f->element_type);
        if (el != NULL) {
          char *item = concat3(member_path, "-*", "");
          walk(refl, el, item, &below, 1, f, on_path, out);
          free(item);
        }
      } else if (strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
                 strcmp(f->kind, SPEC_FIELD_KIND_SECTION) == 0) {
        const SpecClass *child = member_class(refl, f);
        if (child != NULL) {
          walk(refl, child, member_path, &below, 0, f, on_path, out);
        }
      }
    }
    som_strlist_free(&below);
    free(member_path);
  }
  som_strlist_free(&here);
  /* Leave the path: the class may be reached again on another branch. */
  for (size_t i = on_path->len; i > 0; i--) {
    if (strcmp(on_path->items[i - 1], cls->name) == 0) {
      som_strlist_remove_at(on_path, i - 1);
      break;
    }
  }
}

/* Every addressable position beneath (and including) `scope`, in model
 * order. */
static void place_positions(const SpecReflection *refl,
                            const PlaceScope *scope, PlacePositions *out) {
  memset(out, 0, sizeof(*out));
  SomStrList on_path, ids;
  som_strlist_init(&on_path);
  som_strlist_init(&ids);
  walk(refl, scope->cls, scope->path, &ids, scope->is_list_element, NULL,
       &on_path, out);
  som_strlist_free(&on_path);
  som_strlist_free(&ids);
}

/* Whether the `/` segments lead to a position whose ancestors are `path`
 * (its first `n` ids): they name every section on the way, leaving out only
 * `-LST` containers and the scope's own id. No segments: any position. */
static int path_matches_from(const SomStrList *path, size_t n,
                             const SomStrList *segments, size_t start) {
  size_t j = 0;
  for (size_t i = start; i < n; i++) {
    if (j < segments->len && strcmp(path->items[i], segments->items[j]) == 0) {
      j++;
    } else if (!ends_with(path->items[i], "-LST")) {
      return 0;
    }
  }
  return j == segments->len;
}

static int path_matches(const SomStrList *path, size_t n,
                        const SomStrList *segments) {
  if (segments->len == 0) return 1;
  return path_matches_from(path, n, segments, 0) ||
         (n > 0 && path_matches_from(path, n, segments, 1));
}

/* Whether `path` ends with exactly the ids of `tail`. */
static int ends_with_ids(const SomStrList *path, const SomStrList *tail) {
  if (path->len < tail->len) return 0;
  size_t off = path->len - tail->len;
  for (size_t i = 0; i < tail->len; i++) {
    if (strcmp(path->items[off + i], tail->items[i]) != 0) return 0;
  }
  return 1;
}

/* The scope a place is looked for in under `anchor`. */
static int scope_of(const SpecReflection *refl, const char *anchor, int scoped,
                    const char *text, PlaceScope *out, SpecPlaceError *err) {
  SomStrList segs;
  spec_path_segments(anchor, &segs);
  for (size_t n = segs.len; n > 0; n--) {
    SomBuf b;
    som_buf_init(&b);
    for (size_t i = 0; i < n; i++) {
      if (i > 0) som_buf_putc(&b, '/');
      som_buf_puts(&b, segs.items[i]);
    }
    char *path = som_buf_take(&b);
    SpecResolution r;
    int ok = spec_reflection_resolve(refl, path, &r);
    if (n == segs.len && (!ok || r.target_class == NULL)) {
      if (ok) spec_resolution_free(&r);
      free(path);
      som_strlist_free(&segs);
      set_error(err, SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED, text,
                concat3("has the anchor ", anchor,
                        ", which resolves to no section"));
      return 0;
    }
    int is_item = ok && strcmp(r.kind, SPEC_NODE_KIND_LIST_ITEM_COMPLEX) == 0;
    if (!scoped || is_item) {
      const SpecClass *cls = ok ? r.target_class : NULL;
      if (ok) spec_resolution_free(&r);
      som_strlist_free(&segs);
      if (cls == NULL) {
        /* An ancestor that resolves to no class cannot be a scope (the
         * reference fails on it with a null check, not a place problem). */
        set_error(err, NULL, text, concat3("no class at ", path, ""));
        free(path);
        return 0;
      }
      out->path = path;
      out->cls = cls;
      out->is_list_element = is_item;
      return 1;
    }
    if (ok) spec_resolution_free(&r);
    free(path);
  }
  som_strlist_free(&segs);
  set_error(err, SPEC_PLACE_PROBLEM_NOT_SCOPED, text,
            concat3("is `./`-scoped, but no list element lies at or above ",
                    anchor, ""));
  return 0;
}

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void fill_result(const PlacePosition *pos, const char *kind,
                        const char *path, const FormFieldSpec *ff,
                        SpecPlaceResolution *out) {
  spec_place_resolution_init(out);
  out->kind = kind;
  out->path = som_strdup(path);
  out->class_name = pos->class_name;
  som_strlist_copy(&out->section_ids, &pos->ids);
  out->form_field = ff;
}

static int with_slot(const SpecPlace *p, const PlacePosition *pos,
                     SpecPlaceResolution *out, SpecPlaceError *err) {
  const char *slot = p->slot;
  if (slot == NULL) {
    const char *kind = SPEC_PLACE_KIND_SECTION;
    if (strcmp(pos->shape, "list") == 0) {
      kind = SPEC_PLACE_KIND_LIST;
    } else if (strcmp(pos->shape, "form") == 0) {
      kind = SPEC_PLACE_KIND_FORM;
    } else if (strcmp(pos->shape, "content") == 0) {
      kind = SPEC_PLACE_KIND_CONTENT;
    }
    fill_result(pos, kind, pos->path, NULL, out);
    return 1;
  }
  if (strcmp(slot, "@headline") == 0) {
    fill_result(pos, SPEC_PLACE_KIND_HEADLINE, pos->path, NULL, out);
    return 1;
  }
  if (strcmp(slot, "@content") == 0) {
    if (pos->content_path == NULL) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "names @content of ");
      som_buf_puts(&b, p->section_id);
      som_buf_puts(&b, ", which holds no content value");
      set_error(err, SPEC_PLACE_PROBLEM_NO_CONTENT, p->text, som_buf_take(&b));
      return 0;
    }
    fill_result(pos, SPEC_PLACE_KIND_CONTENT, pos->content_path, NULL, out);
    return 1;
  }
  if (strcmp(slot, SPEC_SECTION_ID_SLOT) == 0) {
    if (!pos->is_list_element) {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "names @sectionId of ");
      som_buf_puts(&b, p->section_id);
      som_buf_puts(&b, ", which is no list element");
      set_error(err, SPEC_PLACE_PROBLEM_NOT_LIST_ELEMENT, p->text,
                som_buf_take(&b));
      return 0;
    }
    fill_result(pos, SPEC_PLACE_KIND_SECTION_ID, pos->path, NULL, out);
    return 1;
  }
  if (slot[0] == '@') {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "names the slot ");
    som_buf_puts(&b, slot);
    som_buf_puts(&b, " \xE2\x80\x94 \"@\" is reserved for @headline, "
                     "@content and @sectionId");
    set_error(err, SPEC_PLACE_PROBLEM_RESERVED_SLOT, p->text,
              som_buf_take(&b));
    return 0;
  }
  const FormFieldSpec *ff = NULL;
  for (size_t i = 0; i < pos->form_fields_len; i++) {
    if (strcmp(pos->form_fields[i].name, slot) == 0) {
      ff = &pos->form_fields[i];
      break;
    }
  }
  if (ff == NULL || pos->form_path == NULL) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "names ");
    som_buf_puts(&b, p->section_id);
    som_buf_putc(&b, '.');
    som_buf_puts(&b, slot);
    som_buf_puts(&b, ", which is no form field");
    set_error(err, SPEC_PLACE_PROBLEM_NO_SUCH_FIELD, p->text,
              som_buf_take(&b));
    return 0;
  }
  fill_result(pos, SPEC_PLACE_KIND_FORM_FIELD, pos->form_path, ff, out);
  return 1;
}

int spec_place_resolve(const SpecPlace *place, const SpecReflection *refl,
                       const char *anchor, SpecPlaceResolution *out,
                       SpecPlaceError *err) {
  PlaceScope scope;
  if (!scope_of(refl, anchor, place->scoped, place->text, &scope, err)) {
    return 0;
  }
  PlacePositions all;
  place_positions(refl, &scope, &all);
  /* By path: a later position on the same path replaces an earlier one. */
  size_t *hits = (size_t *)calloc(all.len ? all.len : 1, sizeof(size_t));
  size_t hits_len = 0;
  for (size_t i = 0; i < all.len; i++) {
    const PlacePosition *pos = &all.items[i];
    if (strcmp(pos->id, place->section_id) != 0 ||
        !path_matches(&pos->ids, pos->ids.len - 1, &place->prefix)) {
      continue;
    }
    size_t k = 0;
    while (k < hits_len && strcmp(all.items[hits[k]].path, pos->path) != 0) k++;
    if (k < hits_len) {
      hits[k] = i;
    } else {
      hits[hits_len++] = i;
    }
  }
  int ok = 0;
  if (hits_len == 0) {
    set_error(err, SPEC_PLACE_PROBLEM_UNRESOLVED, place->text,
              concat3("resolves to no section beneath ", scope.path, ""));
  } else if (hits_len > 1) {
    const char **paths = (const char **)calloc(hits_len, sizeof(char *));
    for (size_t k = 0; k < hits_len; k++) paths[k] = all.items[hits[k]].path;
    qsort(paths, hits_len, sizeof(char *), cmp_str);
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "is ambiguous: ");
    som_buf_puts(&b, place->section_id);
    som_buf_puts(&b, " is reached at ");
    for (size_t k = 0; k < hits_len; k++) {
      if (k > 0) som_buf_puts(&b, ", ");
      som_buf_puts(&b, paths[k]);
    }
    som_buf_puts(&b, " \xE2\x80\x94 write it as a `/` path");
    free(paths);
    set_error(err, SPEC_PLACE_PROBLEM_AMBIGUOUS, place->text,
              som_buf_take(&b));
  } else {
    ok = with_slot(place, &all.items[hits[0]], out, err);
  }
  free(hits);
  positions_free(&all);
  free(scope.path);
  return ok;
}

/* ---- SpecPlaceFilter -------------------------------------------------------- */

int spec_place_filter_try_parse(const char *text, SpecPlaceFilter *out) {
  int scoped = strncmp(text, "./", 2) == 0;
  const char *body = scoped ? text + 2 : text;
  const char *dot = strchr(body, '.');
  size_t id_len = dot == NULL ? strlen(body) : (size_t)(dot - body);
  if (!is_segment_n(body, id_len)) return 0;
  if (dot == NULL) {
    out->text = som_strdup(text);
    out->scoped = scoped;
    out->section_id = som_strdup(body);
    out->field = NULL;
    som_strlist_init(&out->values);
    return 1;
  }
  const char *eq = strchr(dot, '=');
  if (eq == NULL) return 0;
  if (!is_field_n(dot + 1, (size_t)(eq - dot - 1))) return 0;
  SomStrList values;
  som_strlist_init(&values);
  const char *v = eq + 1;
  for (;;) {
    const char *bar = strchr(v, '|');
    size_t n = bar == NULL ? strlen(v) : (size_t)(bar - v);
    if (n == 0) {
      som_strlist_free(&values);
      return 0;
    }
    som_strlist_push(&values, som_strdup_n(v, n));
    if (bar == NULL) break;
    v = bar + 1;
  }
  out->text = som_strdup(text);
  out->scoped = scoped;
  out->section_id = som_strdup_n(body, id_len);
  out->field = som_strdup_n(dot + 1, (size_t)(eq - dot - 1));
  out->values = values;
  return 1;
}

int spec_place_filter_parse(const char *text, SpecPlaceFilter *out,
                            SpecPlaceError *err) {
  if (spec_place_filter_try_parse(text, out)) return 1;
  set_error(err, SPEC_PLACE_PROBLEM_MALFORMED, text,
            som_strdup("is not a filter (`<SECTIONID>[.<field>=<value>[|"
                       "<value>\xE2\x80\xA6]]`, optionally `./`-scoped)"));
  return 0;
}

void spec_place_filter_free(SpecPlaceFilter *f) {
  free(f->text);
  free(f->section_id);
  free(f->field);
  som_strlist_free(&f->values);
  memset(f, 0, sizeof(*f));
}

static int is_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

int spec_place_filter_matches(const SpecPlaceFilter *f,
                              const char *const *stored, size_t stored_len) {
  if (f->field == NULL) return 1;
  for (size_t i = 0; i < stored_len; i++) {
    const char *s = stored[i];
    while (is_space(*s)) s++;
    size_t n = strlen(s);
    while (n > 0 && is_space(s[n - 1])) n--;
    for (size_t k = 0; k < f->values.len; k++) {
      if (strlen(f->values.items[k]) == n &&
          strncmp(f->values.items[k], s, n) == 0) {
        return 1;
      }
    }
  }
  return 0;
}

int spec_place_filter_matches_list(const SpecPlaceFilter *f,
                                   const SomStrList *stored) {
  return spec_place_filter_matches(
      f, (const char *const *)(stored != NULL ? stored->items : NULL),
      stored != NULL ? stored->len : 0);
}

void spec_place_filter_place(const SpecPlaceFilter *f, SpecPlace *out) {
  out->text = f->scoped ? concat3("./", f->section_id, "")
                        : som_strdup(f->section_id);
  out->scoped = f->scoped;
  som_strlist_init(&out->prefix);
  out->section_id = som_strdup(f->section_id);
  out->slot = NULL;
}

int spec_place_filter_resolve(const SpecPlaceFilter *f,
                              const SpecReflection *refl, const char *anchor,
                              SpecPlaceResolution *out, SpecPlaceError *err) {
  SpecPlace place;
  spec_place_filter_place(f, &place);
  SpecPlaceError inner;
  spec_place_error_init(&inner);
  int ok = spec_place_resolve(&place, refl, anchor, out, &inner);
  spec_place_free(&place);
  if (!ok) {
    set_error(err, inner.problem, f->text, inner.message);
    inner.message = NULL;
    spec_place_error_free(&inner);
    return 0;
  }
  spec_place_error_free(&inner);
  if (f->field != NULL) {
    const SpecClass *cls = spec_reflection_class_named(refl, out->class_name);
    int found = 0;
    if (strcmp(out->kind, SPEC_PLACE_KIND_SECTION) == 0 && cls != NULL) {
      for (size_t i = 0; i < cls->fields_len && !found; i++) {
        const SpecField *field = &cls->fields[i];
        if (strcmp(field->kind, SPEC_FIELD_KIND_FORM) != 0) continue;
        for (size_t k = 0; k < field->form_fields_len; k++) {
          if (strcmp(field->form_fields[k].name, f->field) == 0) found = 1;
        }
      }
    }
    if (!found) {
      spec_place_resolution_free(out);
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "names ");
      som_buf_puts(&b, f->section_id);
      som_buf_putc(&b, '.');
      som_buf_puts(&b, f->field);
      som_buf_puts(&b, ", which no form of ");
      som_buf_puts(&b, f->section_id);
      som_buf_puts(&b, " holds");
      set_error(err, SPEC_PLACE_PROBLEM_NO_SUCH_FIELD, f->text,
                som_buf_take(&b));
      return 0;
    }
  }
  return 1;
}

char *spec_place_filter_to_json(const SpecPlaceFilter *f) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"scoped\":");
  som_buf_puts(&b, f->scoped ? "true" : "false");
  som_buf_puts(&b, ",\"sectionId\":");
  put_str(&b, f->section_id);
  if (f->field != NULL) {
    som_buf_puts(&b, ",\"field\":");
    put_str(&b, f->field);
    som_buf_puts(&b, ",\"values\":");
    put_list(&b, &f->values);
  }
  som_buf_putc(&b, '}');
  return som_buf_take(&b);
}

/* ---- @SameAs bindings and section positions ------------------------------ */

/* The scope of the whole document root `root_type`; 0 when the model has no
 * such root or class. */
static int root_scope(const SpecReflection *refl, const char *root_type,
                      PlaceScope *out) {
  const SpecRoot *root = NULL;
  for (size_t i = 0; i < refl->model->roots_len; i++) {
    if (strcmp(refl->model->roots[i].type, root_type) == 0) {
      root = &refl->model->roots[i];
      break;
    }
  }
  const SpecClass *cls = spec_reflection_class_named(refl, root_type);
  if (root == NULL || cls == NULL) return 0;
  out->path = som_strdup(spec_reflection_root_segment(root));
  out->cls = cls;
  out->is_list_element = 0;
  return 1;
}

void spec_same_as_binding_list_free(SpecSameAsBindingList *l) {
  for (size_t i = 0; i < l->len; i++) {
    SpecSameAsBinding *b = &l->items[i];
    free(b->root);
    free(b->copy_path);
    som_strlist_free(&b->copy_section_ids);
    free(b->holder_path);
    som_strlist_free(&b->holder_section_ids);
  }
  free(l->items);
  l->items = NULL;
  l->len = 0;
}

char *spec_same_as_binding_to_json(const SpecSameAsBinding *b) {
  SomBuf o;
  som_buf_init(&o);
  som_buf_puts(&o, "{\"root\":");
  put_str(&o, b->root);
  som_buf_puts(&o, ",\"className\":");
  put_str(&o, b->class_name);
  som_buf_puts(&o, ",\"copy\":");
  put_str(&o, b->copy_path);
  if (b->holder_path != NULL) {
    som_buf_puts(&o, ",\"holder\":");
    put_str(&o, b->holder_path);
  }
  if (b->problem != NULL) {
    som_buf_puts(&o, ",\"problem\":");
    put_str(&o, b->problem);
  }
  som_buf_putc(&o, '}');
  return som_buf_take(&o);
}

static int is_copy(const PlacePosition *p) {
  return p->member != NULL && spec_annotations_has_same_as(&p->member->annotations);
}

void spec_same_as_bindings(const SpecReflection *refl, const char *root_type,
                           SpecSameAsBindingList *out) {
  out->items = NULL;
  out->len = 0;
  PlaceScope scope;
  if (!root_scope(refl, root_type, &scope)) return;
  PlacePositions all;
  place_positions(refl, &scope, &all);
  size_t cap = 0;
  for (size_t c = 0; c < all.len; c++) {
    const PlacePosition *copy = &all.items[c];
    if (strcmp(copy->shape, "section") != 0 || !copy->own_node) continue;
    if (copy->member == NULL) continue;
    SpecSameAs same_as;
    if (!spec_annotations_same_as(&copy->member->annotations, &same_as)) {
      continue;
    }
    const char *type = copy->class_name;
    /* The holder's last section ids, `/`-separated. */
    SomStrList tail;
    som_strlist_init(&tail);
    int with_tail = same_as.holder != NULL;
    if (with_tail) {
      som_strlist_free(&tail);
      spec_path_segments(same_as.holder, &tail);
    }
    size_t holders = 0;
    const PlacePosition *holder = NULL;
    for (size_t h = 0; h < all.len; h++) {
      const PlacePosition *p = &all.items[h];
      if (strcmp(p->shape, "section") != 0 || !p->own_node) continue;
      if (strcmp(p->class_name, type) != 0) continue;
      if (is_copy(p)) continue;
      if (with_tail && !ends_with_ids(&p->ids, &tail)) continue;
      if (holders == 0) holder = p;
      holders++;
    }
    if (out->len == cap) {
      cap = cap ? cap * 2 : 4;
      out->items = (SpecSameAsBinding *)realloc(
          out->items, cap * sizeof(SpecSameAsBinding));
    }
    SpecSameAsBinding *b = &out->items[out->len++];
    memset(b, 0, sizeof(*b));
    b->root = som_strdup(root_type);
    b->class_name = type;
    b->copy_path = som_strdup(copy->path);
    som_strlist_copy(&b->copy_section_ids, &copy->ids);
    som_strlist_init(&b->holder_section_ids);
    if (holders == 0) {
      b->problem = SPEC_PLACE_PROBLEM_UNRESOLVED;
    } else if (holders > 1) {
      b->problem = SPEC_PLACE_PROBLEM_AMBIGUOUS;
    } else {
      b->holder_path = som_strdup(holder->path);
      som_strlist_free(&b->holder_section_ids);
      som_strlist_copy(&b->holder_section_ids, &holder->ids);
    }
    som_strlist_free(&tail);
    spec_same_as_free(&same_as);
  }
  positions_free(&all);
  free(scope.path);
}

void spec_section_position_list_free(SpecSectionPositionList *l) {
  for (size_t i = 0; i < l->len; i++) {
    free(l->items[i].path);
    som_strlist_free(&l->items[i].section_ids);
  }
  free(l->items);
  l->items = NULL;
  l->len = 0;
}

void spec_section_positions(const SpecReflection *refl, const char *root_type,
                            SpecSectionPositionList *out) {
  out->items = NULL;
  out->len = 0;
  PlaceScope scope;
  if (!root_scope(refl, root_type, &scope)) return;
  PlacePositions all;
  place_positions(refl, &scope, &all);
  if (all.len > 0) {
    out->items = (SpecSectionPosition *)calloc(all.len,
                                               sizeof(SpecSectionPosition));
  }
  for (size_t i = 0; i < all.len; i++) {
    SpecSectionPosition *p = &out->items[out->len++];
    p->path = som_strdup(all.items[i].path);
    p->class_name = all.items[i].class_name;
    som_strlist_copy(&p->section_ids, &all.items[i].ids);
    p->member = all.items[i].member;
    p->is_member = !all.items[i].own_node;
  }
  positions_free(&all);
  free(scope.path);
}
