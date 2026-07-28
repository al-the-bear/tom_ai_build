#include "spec_model.h"

#include <stdlib.h>
#include <string.h>

const char *spec_parse_field_kind(const char *raw) {
  if (raw == NULL) {
    return SPEC_FIELD_KIND_SCALAR;
  }
  const char *known[] = {SPEC_FIELD_KIND_LIST,    SPEC_FIELD_KIND_FORM,
                         SPEC_FIELD_KIND_SECTION, SPEC_FIELD_KIND_CONTENT,
                         SPEC_FIELD_KIND_ENUM,    SPEC_FIELD_KIND_COMPLEX,
                         SPEC_FIELD_KIND_SCALAR};
  for (size_t i = 0; i < sizeof(known) / sizeof(known[0]); i++) {
    if (strcmp(raw, known[i]) == 0) {
      return known[i];
    }
  }
  return SPEC_FIELD_KIND_SCALAR;
}

const SomJson *spec_annotation_argument(const SpecAnnotation *ann, const char *key) {
  return som_json_get(ann->arguments, key);
}

int spec_field_is_expandable(const SpecField *f) {
  return strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0 ||
         strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0;
}

const SpecField *spec_class_field_named(const SpecClass *cls, const char *name) {
  for (size_t i = 0; i < cls->fields_len; i++) {
    if (strcmp(cls->fields[i].name, name) == 0) {
      return &cls->fields[i];
    }
  }
  return NULL;
}

const SpecClass *spec_model_class_named(const SpecModel *m, const char *name) {
  if (name == NULL || name[0] == '\0') {
    return NULL;
  }
  size_t lo = 0, hi = m->classes_len;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    int cmp = strcmp(m->classes[mid].name, name);
    if (cmp == 0) {
      return m->classes[mid].cls;
    }
    if (cmp < 0) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return NULL;
}

const SpecRoot *spec_model_root_by_type(const SpecModel *m, const char *type,
                                        char **err) {
  if (m != NULL && type != NULL) {
    for (size_t i = 0; i < m->roots_len; i++) {
      if (strcmp(m->roots[i].type, type) == 0) {
        return &m->roots[i];
      }
    }
  }
  if (err != NULL) {
    /* Mirror the Dart ArgumentError message: name the missing type and the ones
     * that do exist. */
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "no document root with type '");
    som_buf_puts(&b, type != NULL ? type : "");
    som_buf_puts(&b, "' (have: ");
    for (size_t i = 0; m != NULL && i < m->roots_len; i++) {
      if (i > 0) {
        som_buf_puts(&b, ", ");
      }
      som_buf_puts(&b, m->roots[i].type);
    }
    som_buf_puts(&b, ")");
    *err = som_buf_take(&b);
    som_buf_free(&b);
  }
  return NULL;
}

/* ---- decoding ----------------------------------------------------------- */

static char *str_or_dup(const SomJson *v, const char *key) {
  return som_strdup(som_json_str_or(v, key));
}

static SpecAnnotationList annotations_from_json(const SomJson *v) {
  SpecAnnotationList out;
  out.items = NULL;
  out.len = 0;
  size_t n = som_json_array_len(v);
  if (n == 0) {
    return out;
  }
  out.items = (SpecAnnotation *)calloc(n, sizeof(SpecAnnotation));
  for (size_t i = 0; i < n; i++) {
    const SomJson *a = som_json_array_at(v, i);
    out.items[i].name = str_or_dup(a, "name");
    const SomJson *args = som_json_get(a, "arguments");
    out.items[i].arguments =
        (args != NULL && args->type == SOM_JSON_OBJECT) ? args : NULL;
  }
  out.len = n;
  return out;
}

static void field_from_json(const SomJson *f, SpecField *out) {
  memset(out, 0, sizeof(*out));
  som_strlist_init(&out->enum_values);

  out->name = str_or_dup(f, "name");
  out->kind = som_strdup(spec_parse_field_kind(som_json_str_or(f, "kind")));
  out->doc = str_or_dup(f, "doc");
  out->help = str_or_dup(f, "help");
  out->headline = str_or_dup(f, "headline");
  out->section_id = str_or_dup(f, "sectionId");
  out->section_id_pattern = str_or_dup(f, "sectionIdPattern");
  out->element_type = str_or_dup(f, "elementType");
  out->element_is_complex = som_json_bool_or(f, "elementIsComplex");

  long long min;
  if (som_json_as_i64(som_json_get(f, "min"), &min)) {
    out->has_min = 1;
    out->min = min;
  }
  long long so;
  if (som_json_as_i64(som_json_get(f, "serializationOrder"), &so)) {
    out->has_serialization_order = 1;
    out->serialization_order = so;
  }
  out->content_type = str_or_dup(f, "contentType");
  out->section_type = str_or_dup(f, "sectionType");
  out->enum_type = str_or_dup(f, "enumType");

  const SomJson *evs = som_json_get(f, "enumValues");
  size_t en = som_json_array_len(evs);
  for (size_t i = 0; i < en; i++) {
    const char *s = som_json_as_str(som_json_array_at(evs, i));
    if (s != NULL) {
      som_strlist_push_copy(&out->enum_values, s);
    }
  }

  out->type = str_or_dup(f, "type");

  const SomJson *ffs = som_json_get(f, "formFields");
  size_t fn = som_json_array_len(ffs);
  if (fn > 0) {
    out->form_fields = (FormFieldSpec *)calloc(fn, sizeof(FormFieldSpec));
    for (size_t i = 0; i < fn; i++) {
      const SomJson *ff = som_json_array_at(ffs, i);
      const char *type = som_json_str_or(ff, "type");
      out->form_fields[i].type = som_strdup(type[0] != '\0' ? type : "String");
      const char *fname = som_json_str_or(ff, "name");
      const char *label = som_json_str_or(ff, "label");
      out->form_fields[i].name = som_strdup(fname);
      out->form_fields[i].label = som_strdup(label[0] != '\0' ? label : fname);
      out->form_fields[i].hint = str_or_dup(ff, "hint");
      out->form_fields[i].required = som_json_bool_or(ff, "required");
    }
    out->form_fields_len = fn;
  }

  out->annotations = annotations_from_json(som_json_get(f, "annotations"));
}

static void class_from_json(const char *name, const SomJson *cls, SpecClass *out) {
  memset(out, 0, sizeof(*out));
  const char *cname = som_json_str_or(cls, "name");
  out->name = som_strdup(cname[0] != '\0' ? cname : name);
  out->section_id = str_or_dup(cls, "sectionId");
  out->doc = str_or_dup(cls, "doc");
  out->help = str_or_dup(cls, "help");
  out->headline = str_or_dup(cls, "headline");
  out->maps_to = str_or_dup(cls, "mapsTo");
  out->detailed_in = str_or_dup(cls, "detailedIn");

  const SomJson *fields = som_json_get(cls, "fields");
  size_t n = som_json_array_len(fields);
  if (n > 0) {
    out->fields = (SpecField *)calloc(n, sizeof(SpecField));
    for (size_t i = 0; i < n; i++) {
      field_from_json(som_json_array_at(fields, i), &out->fields[i]);
    }
    out->fields_len = n;
  }
  out->annotations = annotations_from_json(som_json_get(cls, "annotations"));
}

static int class_entry_cmp(const void *a, const void *b) {
  const SpecClassEntry *ea = (const SpecClassEntry *)a;
  const SpecClassEntry *eb = (const SpecClassEntry *)b;
  return strcmp(ea->name, eb->name);
}

/* Builds the roots/classes/version of `m` from an already-parsed meta-data
 * node. `m->source` (ownership of `root`) is set by the caller. */
static void populate_model(SpecModel *m, const SomJson *root) {
  const SomJson *roots = som_json_get(root, "roots");
  size_t rn = som_json_array_len(roots);
  if (rn > 0) {
    m->roots = (SpecRoot *)calloc(rn, sizeof(SpecRoot));
    for (size_t i = 0; i < rn; i++) {
      const SomJson *r = som_json_array_at(roots, i);
      m->roots[i].type = str_or_dup(r, "type");
      m->roots[i].title = str_or_dup(r, "title");
      m->roots[i].section_id = str_or_dup(r, "sectionId");
      m->roots[i].description = str_or_dup(r, "description");
      m->roots[i].doc = str_or_dup(r, "doc");
    }
    m->roots_len = rn;
  }

  const SomJson *classes = som_json_get(root, "classes");
  if (classes != NULL && classes->type == SOM_JSON_OBJECT) {
    size_t cn = classes->as.object.len;
    if (cn > 0) {
      m->classes = (SpecClassEntry *)calloc(cn, sizeof(SpecClassEntry));
      for (size_t i = 0; i < cn; i++) {
        const SomJsonMember *mem = &classes->as.object.members[i];
        SpecClass *cls = (SpecClass *)calloc(1, sizeof(SpecClass));
        class_from_json(mem->key, mem->value, cls);
        m->classes[i].name = som_strdup(mem->key);
        m->classes[i].cls = cls;
      }
      m->classes_len = cn;
      qsort(m->classes, cn, sizeof(SpecClassEntry), class_entry_cmp);
    }
  }

  long long mv = 0;
  som_json_as_i64(som_json_get(root, "modelVersion"), &mv);
  m->model_version = mv;
  m->model_version_label = str_or_dup(root, "modelVersionLabel");
}

SpecModel *spec_model_from_json(const SomJson *root) {
  SpecModel *m = (SpecModel *)calloc(1, sizeof(SpecModel));
  m->source = NULL; /* borrowed node — not owned */
  populate_model(m, root);
  return m;
}

SpecModel *spec_model_from_json_str(const char *data, char **err) {
  SomJson *root = som_json_parse(data, err);
  if (root == NULL) {
    return NULL;
  }
  SpecModel *m = (SpecModel *)calloc(1, sizeof(SpecModel));
  m->source = root; /* owned parsed tree */
  populate_model(m, root);
  return m;
}

/* ---- teardown ----------------------------------------------------------- */

static void annotations_free(SpecAnnotationList *a) {
  for (size_t i = 0; i < a->len; i++) {
    free(a->items[i].name);
  }
  free(a->items);
}

static void field_free(SpecField *f) {
  free(f->name);
  free(f->kind);
  free(f->doc);
  free(f->help);
  free(f->headline);
  free(f->section_id);
  free(f->section_id_pattern);
  free(f->element_type);
  free(f->content_type);
  free(f->section_type);
  free(f->enum_type);
  som_strlist_free(&f->enum_values);
  free(f->type);
  for (size_t i = 0; i < f->form_fields_len; i++) {
    free(f->form_fields[i].name);
    free(f->form_fields[i].label);
    free(f->form_fields[i].type);
    free(f->form_fields[i].hint);
  }
  free(f->form_fields);
  annotations_free(&f->annotations);
}

static void class_free(SpecClass *c) {
  free(c->name);
  free(c->section_id);
  free(c->doc);
  free(c->help);
  free(c->headline);
  free(c->maps_to);
  free(c->detailed_in);
  for (size_t i = 0; i < c->fields_len; i++) {
    field_free(&c->fields[i]);
  }
  free(c->fields);
  annotations_free(&c->annotations);
  free(c);
}

void spec_model_free(SpecModel *m) {
  if (m == NULL) {
    return;
  }
  for (size_t i = 0; i < m->roots_len; i++) {
    free(m->roots[i].type);
    free(m->roots[i].title);
    free(m->roots[i].section_id);
    free(m->roots[i].description);
    free(m->roots[i].doc);
  }
  free(m->roots);
  for (size_t i = 0; i < m->classes_len; i++) {
    free(m->classes[i].name);
    class_free(m->classes[i].cls);
  }
  free(m->classes);
  free(m->model_version_label);
  if (m->source != NULL) {
    som_json_free(m->source); /* NULL when built from a borrowed node */
  }
  free(m);
}

/* ---- model version string (Dart / Python parity) ------------------------- */

/* Reports whether `s` (the first `n` bytes) matches /^[+-]?[0-9]+$/. */
static int version_is_signed_digits(const char *s, size_t n) {
  size_t i = 0;
  if (n > 0 && (s[0] == '+' || s[0] == '-')) {
    i = 1;
  }
  if (i >= n) {
    return 0;
  }
  for (; i < n; i++) {
    if (s[i] < '0' || s[i] > '9') {
      return 0;
    }
  }
  return 1;
}

static int version_is_space(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

/* Trims ASCII whitespace off both ends of [*s, *s + *n). */
static void version_trim(const char **s, size_t *n) {
  while (*n > 0 && version_is_space((*s)[0])) {
    (*s)++;
    (*n)--;
  }
  while (*n > 0 && version_is_space((*s)[*n - 1])) {
    (*n)--;
  }
}

char *som_model_version_string(long long major, const char *label) {
  if (label != NULL && label[0] != '\0') {
    /* core = the `+`-stripped, trimmed prefix of the label */
    const char *core = label;
    const char *plus = strchr(label, '+');
    size_t core_len = plus != NULL ? (size_t)(plus - label) : strlen(label);
    version_trim(&core, &core_len);
    /* at least two dot-separated components → major.minor */
    const char *dot = memchr(core, '.', core_len);
    if (dot != NULL) {
      const char *maj = core;
      size_t maj_len = (size_t)(dot - core);
      const char *minor = dot + 1;
      size_t minor_len = core_len - maj_len - 1;
      const char *dot2 = memchr(minor, '.', minor_len);
      if (dot2 != NULL) {
        minor_len = (size_t)(dot2 - minor);
      }
      version_trim(&maj, &maj_len);
      version_trim(&minor, &minor_len);
      if (version_is_signed_digits(maj, maj_len) &&
          version_is_signed_digits(minor, minor_len)) {
        char *maj_s = som_strdup_n(maj, maj_len);
        char *minor_s = som_strdup_n(minor, minor_len);
        long long maj_v = 0;
        long long minor_v = 0;
        som_parse_i64(maj_s, &maj_v);
        som_parse_i64(minor_s, &minor_v);
        free(maj_s);
        free(minor_s);
        SomBuf b;
        som_buf_init(&b);
        som_buf_puti(&b, maj_v);
        som_buf_putc(&b, '.');
        som_buf_puti(&b, minor_v);
        return som_buf_take(&b);
      }
    }
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puti(&b, major);
  som_buf_puts(&b, ".0");
  return som_buf_take(&b);
}
