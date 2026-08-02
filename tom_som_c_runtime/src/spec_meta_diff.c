/* spec_meta_diff — implementation. See spec_meta_diff.h; a faithful port of the
 * Go `spec_meta_diff.go`. */
#include "spec_meta_diff.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_json.h"
#include "som_util.h"

/* ---- small message helpers (forward-declared, defined below) ------------- */

/* stringListEq: element-wise equality of two owned string lists. */
static int strlist_eq(const SomStrList *a, const SomStrList *b);
/* Concatenates `at` + `suffix` into an owned message. */
static char *concat_at(const char *at, const char *suffix);
/* Concatenates three owned/borrowed strings into an owned message (position
 * chaining: `at` + `sep` + `name`). */
static char *concat3_at(const char *at, const char *sep, const char *name);

/* ---- MetaValue: the scalar interface{} values the generic diff compares ----
 *
 * The Go `diff` closure compares `interface{}` values that, across every call
 * site, are one of: a string (never nil — className/kind/…), nil-or-string
 * (contentTypeField), nil-or-int (optIntRepr), or a bool (unused/recursive).
 * This tagged union covers exactly those shapes. */
typedef enum { MV_NULL, MV_STR, MV_BOOL, MV_INT } MetaValueKind;

typedef struct {
  MetaValueKind kind;
  const char *str; /* borrowed; MV_STR only */
  int boolean;     /* MV_BOOL only */
  long long integer; /* MV_INT only */
} MetaValue;

static MetaValue mv_null(void) {
  MetaValue v = {MV_NULL, NULL, 0, 0};
  return v;
}
static MetaValue mv_str(const char *s) {
  MetaValue v = {MV_STR, s, 0, 0};
  return v;
}
static MetaValue mv_bool(int b) {
  MetaValue v = {MV_BOOL, NULL, b ? 1 : 0, 0};
  return v;
}
static MetaValue mv_int(long long n) {
  MetaValue v = {MV_INT, NULL, 0, n};
  return v;
}

/* optIntRepr: nil → MV_NULL, else the int value. */
static MetaValue opt_int_repr(int has, long long v) {
  return has ? mv_int(v) : mv_null();
}

/* contentTypeField: nil content type → MV_NULL, else the type/description
 * string (which, when present, is an owned non-NULL "" or value). */
static MetaValue content_type_field(const SomContentTypeMeta *ct,
                                    int want_type) {
  if (ct == NULL) {
    return mv_null();
  }
  return mv_str(want_type ? ct->type : ct->description);
}

/* metaValueEq for the scalar MetaValue shapes. Numbers compare by value (only
 * MV_INT appears here); across kinds nothing is equal except the matching
 * branch. Mirrors Go's metaValueEq for scalars (asFloat covers ints; the
 * final `a == b` covers strings/bools/nil). */
static int mv_eq(MetaValue a, MetaValue b) {
  if (a.kind == MV_INT || b.kind == MV_INT) {
    return a.kind == MV_INT && b.kind == MV_INT && a.integer == b.integer;
  }
  if (a.kind != b.kind) {
    return 0;
  }
  switch (a.kind) {
    case MV_NULL:
      return 1;
    case MV_STR:
      return strcmp(a.str, b.str) == 0;
    case MV_BOOL:
      return a.boolean == b.boolean;
    default:
      return 0;
  }
}

/* metaValueRepr: `null` for absent, the string verbatim, `true`/`false` for a
 * bool, the decimal for an int. */
static char *mv_repr(MetaValue v) {
  switch (v.kind) {
    case MV_NULL:
      return som_strdup("null");
    case MV_STR:
      return som_strdup(v.str);
    case MV_BOOL:
      return som_strdup(v.boolean ? "true" : "false");
    case MV_INT:
      return som_format_i64(v.integer);
  }
  return som_strdup("");
}

static int strlist_eq(const SomStrList *a, const SomStrList *b) {
  if (a->len != b->len) {
    return 0;
  }
  for (size_t i = 0; i < a->len; i++) {
    if (strcmp(a->items[i], b->items[i]) != 0) {
      return 0;
    }
  }
  return 1;
}

/* Element-wise equality of two `char **` + length string arrays — the shape the
   meta layer uses where SomStrList is not available. */
static int strarr_eq(char *const *a, size_t an, char *const *b, size_t bn) {
  if (an != bn) {
    return 0;
  }
  for (size_t i = 0; i < an; i++) {
    if (strcmp(a[i], b[i]) != 0) {
      return 0;
    }
  }
  return 1;
}

static char *concat_at(const char *at, const char *suffix) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, at);
  som_buf_puts(&b, suffix);
  return som_buf_take(&b);
}

static char *concat3_at(const char *at, const char *sep, const char *name) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, at);
  som_buf_puts(&b, sep);
  som_buf_puts(&b, name);
  return som_buf_take(&b);
}

/* ---- compact JSON rendering (mirrors Go's json.Marshal) ------------------ */

/* Renders a SomJson value as compact JSON into `b` (object members and array
 * items keep source order, matching Go's map/slice marshalling for these
 * generated argument shapes which are already source-ordered). */
static void json_write(SomBuf *b, const SomJson *v) {
  if (v == NULL) {
    som_buf_puts(b, "null");
    return;
  }
  switch (v->type) {
    case SOM_JSON_NULL:
      som_buf_puts(b, "null");
      break;
    case SOM_JSON_BOOL:
      som_buf_puts(b, v->as.boolean ? "true" : "false");
      break;
    case SOM_JSON_INT:
      som_buf_puti(b, v->as.integer);
      break;
    case SOM_JSON_FLOAT: {
      /* Integral floats render without a decimal point (Go json.Marshal of a
       * float64 whole number emits no fraction, e.g. 3, not 3.0). */
      double r = v->as.real;
      long long as_int = (long long)r;
      if ((double)as_int == r) {
        som_buf_puti(b, as_int);
      } else {
        char tmp[64];
        int n = snprintf(tmp, sizeof(tmp), "%g", r);
        if (n > 0) {
          som_buf_putn(b, tmp, (size_t)n);
        }
      }
      break;
    }
    case SOM_JSON_STR: {
      char *lit = som_json_encode_str(v->as.str);
      som_buf_puts(b, lit);
      free(lit);
      break;
    }
    case SOM_JSON_ARRAY:
      som_buf_putc(b, '[');
      for (size_t i = 0; i < v->as.array.len; i++) {
        if (i > 0) {
          som_buf_putc(b, ',');
        }
        json_write(b, v->as.array.items[i]);
      }
      som_buf_putc(b, ']');
      break;
    case SOM_JSON_OBJECT:
      som_buf_putc(b, '{');
      for (size_t i = 0; i < v->as.object.len; i++) {
        if (i > 0) {
          som_buf_putc(b, ',');
        }
        char *k = som_json_encode_str(v->as.object.members[i].key);
        som_buf_puts(b, k);
        free(k);
        som_buf_putc(b, ':');
        json_write(b, v->as.object.members[i].value);
      }
      som_buf_putc(b, '}');
      break;
  }
}

/* jsonRepr for a SomJson args object (NULL renders as the empty object `{}`,
 * matching argsAsValue's nil→{} widening reused in the diff message). */
static char *json_repr_args(const SomJson *v) {
  SomBuf b;
  som_buf_init(&b);
  if (v == NULL) {
    som_buf_puts(&b, "{}");
  } else {
    json_write(&b, v);
  }
  return som_buf_take(&b);
}

/* jsonRepr for a string slice ([]string): `["a","b"]`. */
static char *json_repr_strlist(const SomStrList *l) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) {
      som_buf_putc(&b, ',');
    }
    char *lit = som_json_encode_str(l->items[i]);
    som_buf_puts(&b, lit);
    free(lit);
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

/* jsonRepr for a temporary list of borrowed C strings (memberNames /
 * annotationNames). */
static char *json_repr_names(const char *const *names, size_t len) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < len; i++) {
    if (i > 0) {
      som_buf_putc(&b, ',');
    }
    char *lit = som_json_encode_str(names[i]);
    som_buf_puts(&b, lit);
    free(lit);
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

/* ---- deep JSON equality for annotation args ------------------------------ */

/* asFloat: yields the numeric value of an Int/Float node. */
static int json_as_float(const SomJson *v, double *out) {
  if (v == NULL) {
    return 0;
  }
  if (v->type == SOM_JSON_INT) {
    *out = (double)v->as.integer;
    return 1;
  }
  if (v->type == SOM_JSON_FLOAT) {
    *out = v->as.real;
    return 1;
  }
  return 0;
}

/* metaValueEq over JSON-shaped values: numbers by value across int/float,
 * arrays element-wise, objects key-wise (order-independent), scalars by value.
 * NULL is treated as an empty object (argsAsValue: nil map == empty map), so a
 * NULL args node equals an empty `{}` node. */
static int json_value_eq(const SomJson *a, const SomJson *b);

/* Reports whether a (possibly NULL) node is an empty object / NULL. */
static int json_is_empty_object(const SomJson *v) {
  if (v == NULL) {
    return 1;
  }
  return v->type == SOM_JSON_OBJECT && v->as.object.len == 0;
}

static int json_value_eq(const SomJson *a, const SomJson *b) {
  double an, bn;
  if (json_as_float(a, &an)) {
    return json_as_float(b, &bn) && an == bn;
  }
  /* nil map == empty map: a NULL (or empty-object) args value equals another
   * empty-object/NULL value. */
  if (a == NULL || b == NULL) {
    return json_is_empty_object(a) && json_is_empty_object(b);
  }
  if (a->type == SOM_JSON_ARRAY) {
    if (b->type != SOM_JSON_ARRAY || a->as.array.len != b->as.array.len) {
      return 0;
    }
    for (size_t i = 0; i < a->as.array.len; i++) {
      if (!json_value_eq(a->as.array.items[i], b->as.array.items[i])) {
        return 0;
      }
    }
    return 1;
  }
  if (a->type == SOM_JSON_OBJECT) {
    if (b->type != SOM_JSON_OBJECT || a->as.object.len != b->as.object.len) {
      return 0;
    }
    for (size_t i = 0; i < a->as.object.len; i++) {
      const char *key = a->as.object.members[i].key;
      /* Require the key present in b (a missing key is not equal, even if
       * json_object_get would also return NULL for a present null member). */
      int has = 0;
      const SomJson *bv = NULL;
      for (size_t j = 0; j < b->as.object.len; j++) {
        if (strcmp(b->as.object.members[j].key, key) == 0) {
          has = 1;
          bv = b->as.object.members[j].value;
          break;
        }
      }
      if (!has || !json_value_eq(a->as.object.members[i].value, bv)) {
        return 0;
      }
    }
    return 1;
  }
  /* remaining scalars: null / bool / string */
  if (a->type != b->type) {
    return 0;
  }
  switch (a->type) {
    case SOM_JSON_NULL:
      return 1;
    case SOM_JSON_BOOL:
      return a->as.boolean == b->as.boolean;
    case SOM_JSON_STR:
      return strcmp(a->as.str, b->as.str) == 0;
    default:
      return 0;
  }
}

/* ---- message builders ---------------------------------------------------- */

/* Returns 1 when `s` is the empty "no difference" marker. */
static int is_no_diff(const char *s) { return s[0] == '\0'; }

/* diff(field, va, vb): "" when equal, else `at: field differs — repr != repr`. */
static char *diff_field(const char *at, const char *field, MetaValue va,
                        MetaValue vb) {
  if (mv_eq(va, vb)) {
    return som_strdup("");
  }
  char *ra = mv_repr(va);
  char *rb = mv_repr(vb);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, at);
  som_buf_puts(&b, ": ");
  som_buf_puts(&b, field);
  som_buf_puts(&b, " differs \xE2\x80\x94 ");
  som_buf_puts(&b, ra);
  som_buf_puts(&b, " != ");
  som_buf_puts(&b, rb);
  free(ra);
  free(rb);
  return som_buf_take(&b);
}

/* ---- sub-diffs ----------------------------------------------------------- */

static char *meta_form_diff(const char *at, const SomFormMeta *a,
                            const SomFormMeta *b) {
  int a_set = a != NULL;
  int b_set = b != NULL;
  if (a_set != b_set) {
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": form presence differs \xE2\x80\x94 ");
    som_buf_puts(&buf, a_set ? "true" : "false");
    som_buf_puts(&buf, " != ");
    som_buf_puts(&buf, b_set ? "true" : "false");
    return som_buf_take(&buf);
  }
  if (!a_set) {
    return som_strdup("");
  }
  if (a->fields_len != b->fields_len) {
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": form field count differs \xE2\x80\x94 ");
    som_buf_puti(&buf, (long long)a->fields_len);
    som_buf_puts(&buf, " != ");
    som_buf_puti(&buf, (long long)b->fields_len);
    return som_buf_take(&buf);
  }
  for (size_t i = 0; i < a->fields_len; i++) {
    const SomFormFieldMeta *fa = &a->fields[i];
    const SomFormFieldMeta *fb = &b->fields[i];
    if (strcmp(fa->name, fb->name) != 0 ||
        strcmp(fa->type_name, fb->type_name) != 0 ||
        strcmp(fa->description, fb->description) != 0 ||
        fa->required != fb->required || strcmp(fa->hint, fb->hint) != 0 ||
        fa->order != fb->order ||
        !strarr_eq(fa->enum_values, fa->enum_values_len, fb->enum_values,
                   fb->enum_values_len) ||
        !strarr_eq(fa->refers_to, fa->refers_to_len, fb->refers_to,
                   fb->refers_to_len)) {
      SomBuf buf;
      som_buf_init(&buf);
      som_buf_puts(&buf, at);
      som_buf_puts(&buf, ": form field ");
      som_buf_puts(&buf, fa->name);
      som_buf_puts(&buf, " differs");
      return som_buf_take(&buf);
    }
  }
  return som_strdup("");
}

static char *meta_document_diff(const char *at, const SomDocMeta *a,
                                const SomDocMeta *b) {
  int a_set = a != NULL;
  int b_set = b != NULL;
  if (a_set != b_set) {
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": document presence differs \xE2\x80\x94 ");
    som_buf_puts(&buf, a_set ? "true" : "false");
    som_buf_puts(&buf, " != ");
    som_buf_puts(&buf, b_set ? "true" : "false");
    return som_buf_take(&buf);
  }
  if (!a_set) {
    return som_strdup("");
  }
  if (strcmp(a->name, b->name) != 0) {
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": document.name differs \xE2\x80\x94 ");
    som_buf_puts(&buf, a->name);
    som_buf_puts(&buf, " != ");
    som_buf_puts(&buf, b->name);
    return som_buf_take(&buf);
  }
  if (strcmp(a->description, b->description) != 0) {
    return concat_at(at, ": document.description differs");
  }
  if (!strlist_eq(&a->based_on, &b->based_on)) {
    char *ra = json_repr_strlist(&a->based_on);
    char *rb = json_repr_strlist(&b->based_on);
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": document.basedOn differs \xE2\x80\x94 ");
    som_buf_puts(&buf, ra);
    som_buf_puts(&buf, " != ");
    som_buf_puts(&buf, rb);
    free(ra);
    free(rb);
    return som_buf_take(&buf);
  }
  return som_strdup("");
}

static char *meta_extra_diff(const char *at, const SomMetaExtra *a,
                             size_t a_len, const SomMetaExtra *b,
                             size_t b_len) {
  if (a_len != b_len) {
    const char **an = malloc(a_len * sizeof(char *));
    const char **bn = malloc(b_len * sizeof(char *));
    for (size_t i = 0; i < a_len; i++) an[i] = a[i].annotation;
    for (size_t i = 0; i < b_len; i++) bn[i] = b[i].annotation;
    char *ra = json_repr_names(an, a_len);
    char *rb = json_repr_names(bn, b_len);
    free(an);
    free(bn);
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": extra annotation count differs \xE2\x80\x94 ");
    som_buf_puti(&buf, (long long)a_len);
    som_buf_puts(&buf, " != ");
    som_buf_puti(&buf, (long long)b_len);
    som_buf_puts(&buf, " (");
    som_buf_puts(&buf, ra);
    som_buf_puts(&buf, " vs ");
    som_buf_puts(&buf, rb);
    som_buf_puts(&buf, ")");
    free(ra);
    free(rb);
    return som_buf_take(&buf);
  }
  for (size_t i = 0; i < a_len; i++) {
    if (strcmp(a[i].annotation, b[i].annotation) != 0 ||
        !json_value_eq(a[i].args, b[i].args)) {
      char *ra = json_repr_args(a[i].args);
      char *rb = json_repr_args(b[i].args);
      SomBuf buf;
      som_buf_init(&buf);
      som_buf_puts(&buf, at);
      som_buf_puts(&buf, ": extra annotation ");
      som_buf_puts(&buf, a[i].annotation);
      som_buf_puts(&buf, " differs \xE2\x80\x94 ");
      som_buf_puts(&buf, ra);
      som_buf_puts(&buf, " != ");
      som_buf_puts(&buf, rb);
      free(ra);
      free(rb);
      return som_buf_take(&buf);
    }
  }
  return som_strdup("");
}

/* ---- core recursion ------------------------------------------------------ */

static char *diff_at(const SomMetaNode *a, const SomMetaNode *b,
                     const char *at);

/* Runs one field check, freeing an "" result and returning NULL to continue, or
 * returning the owned non-empty diff to stop. */
#define CHECK(expr)                    \
  do {                                 \
    char *d = (expr);                  \
    if (!is_no_diff(d)) return d;      \
    free(d);                           \
  } while (0)

static char *diff_at(const SomMetaNode *a, const SomMetaNode *b,
                     const char *at) {
  CHECK(diff_field(at, "className", mv_str(a->class_name),
                   mv_str(b->class_name)));
  CHECK(diff_field(at, "memberName", mv_str(a->member_name),
                   mv_str(b->member_name)));
  CHECK(diff_field(at, "sectionId", mv_str(a->section_id),
                   mv_str(b->section_id)));
  CHECK(diff_field(at, "sectionIdPattern", mv_str(a->section_id_pattern),
                   mv_str(b->section_id_pattern)));
  CHECK(diff_field(at, "kind", mv_str(a->kind), mv_str(b->kind)));
  CHECK(diff_field(at, "typeName", mv_str(a->type_name),
                   mv_str(b->type_name)));
  CHECK(diff_field(at, "serializationOrder",
                   opt_int_repr(a->has_serialization_order,
                                a->serialization_order),
                   opt_int_repr(b->has_serialization_order,
                                b->serialization_order)));
  CHECK(diff_field(at, "min", opt_int_repr(a->has_min, a->min),
                   opt_int_repr(b->has_min, b->min)));
  CHECK(diff_field(at, "unused", mv_bool(a->unused), mv_bool(b->unused)));
  CHECK(diff_field(at, "contentType.type",
                   content_type_field(a->content_type, 1),
                   content_type_field(b->content_type, 1)));
  CHECK(diff_field(at, "contentType.description",
                   content_type_field(a->content_type, 0),
                   content_type_field(b->content_type, 0)));
  CHECK(diff_field(at, "contentHelp", mv_str(a->content_help),
                   mv_str(b->content_help)));
  CHECK(diff_field(at, "headline", mv_str(a->headline), mv_str(b->headline)));
  CHECK(diff_field(at, "comment", mv_str(a->comment), mv_str(b->comment)));
  CHECK(diff_field(at, "docComment", mv_str(a->doc_comment),
                   mv_str(b->doc_comment)));
  CHECK(diff_field(at, "classDocComment", mv_str(a->class_doc_comment),
                   mv_str(b->class_doc_comment)));
  CHECK(diff_field(at, "mapsTo", mv_str(a->maps_to), mv_str(b->maps_to)));
  CHECK(diff_field(at, "detailedIn", mv_str(a->detailed_in),
                   mv_str(b->detailed_in)));
  CHECK(diff_field(at, "recursive", mv_bool(a->recursive),
                   mv_bool(b->recursive)));
  CHECK(meta_form_diff(at, a->form, b->form));
  CHECK(meta_document_diff(at, a->document, b->document));
  CHECK(meta_extra_diff(at, a->extra, a->extra_len, b->extra, b->extra_len));

  if (a->children_len != b->children_len) {
    const char **an = malloc(a->children_len * sizeof(char *));
    const char **bn = malloc(b->children_len * sizeof(char *));
    for (size_t i = 0; i < a->children_len; i++)
      an[i] = a->children[i]->member_name;
    for (size_t i = 0; i < b->children_len; i++)
      bn[i] = b->children[i]->member_name;
    char *ra = json_repr_names(an, a->children_len);
    char *rb = json_repr_names(bn, b->children_len);
    free(an);
    free(bn);
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": children count differs \xE2\x80\x94 ");
    som_buf_puti(&buf, (long long)a->children_len);
    som_buf_puts(&buf, " != ");
    som_buf_puti(&buf, (long long)b->children_len);
    som_buf_puts(&buf, " (");
    som_buf_puts(&buf, ra);
    som_buf_puts(&buf, " vs ");
    som_buf_puts(&buf, rb);
    som_buf_puts(&buf, ")");
    free(ra);
    free(rb);
    return som_buf_take(&buf);
  }
  for (size_t i = 0; i < a->children_len; i++) {
    const SomMetaNode *ca = a->children[i];
    const char *name = ca->member_name;
    if (name[0] == '\0') {
      name = ca->class_name;
    }
    char *child_at = concat3_at(at, "/", name);
    char *d = diff_at(ca, b->children[i], child_at);
    free(child_at);
    if (!is_no_diff(d)) {
      return d;
    }
    free(d);
  }

  int a_elem = a->element_node != NULL;
  int b_elem = b->element_node != NULL;
  if (a_elem != b_elem) {
    SomBuf buf;
    som_buf_init(&buf);
    som_buf_puts(&buf, at);
    som_buf_puts(&buf, ": elementNode presence differs \xE2\x80\x94 ");
    som_buf_puts(&buf, a_elem ? "true" : "false");
    som_buf_puts(&buf, " != ");
    som_buf_puts(&buf, b_elem ? "true" : "false");
    return som_buf_take(&buf);
  }
  if (a_elem) {
    char *child_at = concat3_at(at, "/", "\xC2\xA7" "element");
    char *d = diff_at(a->element_node, b->element_node, child_at);
    free(child_at);
    return d;
  }
  return som_strdup("");
}

#undef CHECK

char *som_meta_node_diff(const SomMetaNode *a, const SomMetaNode *b) {
  return diff_at(a, b, "<root>");
}
