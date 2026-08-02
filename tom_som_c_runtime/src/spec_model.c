#include "spec_model.h"

#include <stdio.h>
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

/* Fills `out` with the string elements of `parent[key]`; leaves it empty when
   the key is absent, so a meta file predating the key still loads. */
static void strlist_from_json(const SomJson *parent, const char *key,
                              SomStrList *out) {
  som_strlist_init(out);
  const SomJson *arr = som_json_get(parent, key);
  size_t n = som_json_array_len(arr);
  for (size_t i = 0; i < n; i++) {
    const char *s = som_json_as_str(som_json_array_at(arr, i));
    if (s != NULL) {
      som_strlist_push_copy(out, s);
    }
  }
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

  strlist_from_json(f, "enumValues", &out->enum_values);

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
      strlist_from_json(ff, "enumValues", &out->form_fields[i].enum_values);
      strlist_from_json(ff, "refersTo", &out->form_fields[i].refers_to);
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

/* ---- generation stamp ---------------------------------------------------- */

/* The length of `month` in `year`, Gregorian. Used to reject a day that does not
 * exist rather than letting it roll into the next month: some SOM runtimes' date
 * types would turn 31 February into 3 March while others reject it outright — so
 * the grammar rejects it everywhere. */
static long long days_in_month(long long year, long long month) {
  static const long long lengths[] = {31, 28, 31, 30, 31, 30,
                                      31, 31, 30, 31, 30, 31};
  if (month != 2) {
    return lengths[month - 1];
  }
  if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) {
    return 29;
  }
  return 28;
}

/* Days since 1970-01-01 for a proleptic-Gregorian civil date (Howard Hinnant's
 * `days_from_civil`) — the same arithmetic the Rust, Java and C++ ports use. */
static long long epoch_day(long long year, long long month, long long day) {
  long long y = year - (month <= 2 ? 1 : 0);
  long long era = (y >= 0 ? y : y - 399) / 400;
  long long yoe = y - era * 400;
  long long doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1;
  long long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + doe - 719468;
}

static int is_digit(char c) { return c >= '0' && c <= '9'; }

/* Reads `count` decimal digits at `at`, or returns 0 when any is not a digit. */
static int digits_at(const char *b, size_t len, size_t at, size_t count,
                     long long *out) {
  if (at + count > len) {
    return 0;
  }
  long long value = 0;
  for (size_t i = 0; i < count; i++) {
    char c = b[at + i];
    if (!is_digit(c)) {
      return 0;
    }
    value = value * 10 + (c - '0');
  }
  *out = value;
  return 1;
}

int spec_parse_stamp_timestamp(const char *raw, long long *out) {
  if (raw == NULL) {
    return 0;
  }
  /* Trim ASCII whitespace at both ends without copying. */
  size_t start = 0;
  size_t end = strlen(raw);
  while (start < end && (raw[start] == ' ' || raw[start] == '\t' ||
                         raw[start] == '\n' || raw[start] == '\r')) {
    start++;
  }
  while (end > start && (raw[end - 1] == ' ' || raw[end - 1] == '\t' ||
                         raw[end - 1] == '\n' || raw[end - 1] == '\r')) {
    end--;
  }
  const char *b = raw + start;
  size_t len = end - start;

  if (len < 19 || b[4] != '-' || b[7] != '-' || b[13] != ':' || b[16] != ':') {
    return 0;
  }
  if (b[10] != 'T' && b[10] != 't' && b[10] != ' ') {
    return 0;
  }
  long long year, month, day, hour, minute, second;
  if (!digits_at(b, len, 0, 4, &year) || !digits_at(b, len, 5, 2, &month) ||
      !digits_at(b, len, 8, 2, &day) || !digits_at(b, len, 11, 2, &hour) ||
      !digits_at(b, len, 14, 2, &minute) || !digits_at(b, len, 17, 2, &second)) {
    return 0;
  }
  if (month < 1 || month > 12 || day < 1 || day > days_in_month(year, month)) {
    return 0;
  }
  if (hour > 23 || minute > 59 || second > 59) {
    return 0;
  }

  size_t idx = 19;
  if (idx < len && b[idx] == '.') {
    idx++;
    size_t frac_start = idx;
    while (idx < len && is_digit(b[idx])) {
      idx++;
    }
    if (idx == frac_start) {
      return 0; /* a `.` with no digits is not the grammar */
    }
  }

  long long epoch = epoch_day(year, month, day) * SPEC_SECONDS_PER_DAY +
                    hour * 3600 + minute * 60 + second;
  if (idx < len) {
    char sign = b[idx];
    if (sign == 'Z' || sign == 'z') {
      if (idx + 1 != len) {
        return 0;
      }
    } else if (sign == '+' || sign == '-') {
      const char *rest = b + idx + 1;
      size_t rest_len = len - idx - 1;
      long long oh, om;
      if (rest_len == 4) {
        if (!digits_at(rest, rest_len, 0, 2, &oh) ||
            !digits_at(rest, rest_len, 2, 2, &om)) {
          return 0;
        }
      } else if (rest_len == 5 && rest[2] == ':') {
        if (!digits_at(rest, rest_len, 0, 2, &oh) ||
            !digits_at(rest, rest_len, 3, 2, &om)) {
          return 0;
        }
      } else {
        return 0;
      }
      long long offset = (oh * 60 + om) * 60;
      epoch += (sign == '-') ? offset : -offset;
    } else {
      return 0;
    }
  }
  *out = epoch;
  return 1;
}

int spec_stamp_check_is_aged(const SpecModelStampCheck *c) {
  return c->has_age && c->age_seconds > c->max_age_seconds;
}

int spec_stamp_check_class_count_disagrees(const SpecModelStampCheck *c) {
  return c->has_declared_class_count &&
         c->declared_class_count != c->actual_class_count;
}

int spec_stamp_check_root_count_disagrees(const SpecModelStampCheck *c) {
  return c->has_declared_root_count &&
         c->declared_root_count != c->actual_root_count;
}

int spec_stamp_check_counts_disagree(const SpecModelStampCheck *c) {
  return spec_stamp_check_class_count_disagrees(c) ||
         spec_stamp_check_root_count_disagrees(c);
}

int spec_stamp_check_is_stale(const SpecModelStampCheck *c) {
  return spec_stamp_check_is_aged(c) || spec_stamp_check_counts_disagree(c);
}

/* Formats `fmt` with two `long long` arguments into an owned string. The
 * warning sentences are short and bounded, so a fixed buffer is sound. */
static char *format_two(const char *fmt, long long a, long long b) {
  char buf[256];
  snprintf(buf, sizeof(buf), fmt, a, b);
  return som_strdup(buf);
}

void spec_stamp_check_warnings(const SpecModelStampCheck *c, SomStrList *out) {
  som_strlist_init(out);
  if (spec_stamp_check_is_aged(c)) {
    som_strlist_push(
        out, format_two("Snapshot is %lld days old (threshold %lld days) — the "
                        "model may have moved on since it was exported.",
                        c->age_seconds / SPEC_SECONDS_PER_DAY,
                        c->max_age_seconds / SPEC_SECONDS_PER_DAY));
  }
  if (spec_stamp_check_class_count_disagrees(c)) {
    som_strlist_push(
        out, format_two("Stamp declares %lld classes but the snapshot carries "
                        "%lld — it was edited after export.",
                        c->declared_class_count, c->actual_class_count));
  }
  if (spec_stamp_check_root_count_disagrees(c)) {
    som_strlist_push(
        out, format_two("Stamp declares %lld document roots but the snapshot "
                        "carries %lld — it was edited after export.",
                        c->declared_root_count, c->actual_root_count));
  }
}

SpecModelStampCheck spec_model_check_stamp(const SpecModel *m,
                                           long long max_age_seconds,
                                           long long now_epoch_seconds) {
  SpecModelStampCheck c;
  memset(&c, 0, sizeof(c));
  c.max_age_seconds = max_age_seconds;
  if (m->has_generated_at) {
    c.has_age = 1;
    c.age_seconds = now_epoch_seconds - m->generated_at;
  }
  c.has_declared_class_count = m->has_class_count;
  c.declared_class_count = m->class_count;
  c.actual_class_count = (long long)m->classes_len;
  c.has_declared_root_count = m->has_root_count;
  c.declared_root_count = m->root_count;
  c.actual_root_count = (long long)m->roots_len;
  return c;
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

  /* Generation stamp — every key optional. An absent count stays absent rather
   * than defaulting to zero: reading absent as 0 would make every pre-stamp
   * snapshot look like it had been edited down to nothing. */
  m->has_generated_at =
      spec_parse_stamp_timestamp(som_json_str_or(root, "generatedAt"),
                                 &m->generated_at);
  m->has_meta_schema_version = som_json_as_i64(
      som_json_get(root, "metaSchemaVersion"), &m->meta_schema_version);
  m->has_class_count =
      som_json_as_i64(som_json_get(root, "classCount"), &m->class_count);
  m->has_root_count =
      som_json_as_i64(som_json_get(root, "rootCount"), &m->root_count);
  m->container_root = str_or_dup(root, "containerRoot");
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
    som_strlist_free(&f->form_fields[i].enum_values);
    som_strlist_free(&f->form_fields[i].refers_to);
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
  free(m->container_root);
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
