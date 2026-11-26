#include "spec_typed_values.h"

#include <float.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_review_annotations.h"
#include "yaml.h"

/* ---- SomValue ----------------------------------------------------------- */

static SomValue value_zero(SomValueKind kind) {
  SomValue v;
  v.kind = kind;
  v.str = NULL;
  v.integer = 0;
  v.real = 0.0;
  v.boolean = 0;
  return v;
}

SomValue som_value_none(void) { return value_zero(SOM_VALUE_NONE); }

SomValue som_value_str(const char *s) {
  if (s == NULL) {
    return som_value_none();
  }
  SomValue v = value_zero(SOM_VALUE_STR);
  v.str = som_strdup(s);
  return v;
}

SomValue som_value_int(long long x) {
  SomValue v = value_zero(SOM_VALUE_INT);
  v.integer = x;
  return v;
}

SomValue som_value_double(double x) {
  SomValue v = value_zero(SOM_VALUE_DOUBLE);
  v.real = x;
  return v;
}

SomValue som_value_bool(int x) {
  SomValue v = value_zero(SOM_VALUE_BOOL);
  v.boolean = x ? 1 : 0;
  return v;
}

void som_value_free(SomValue *v) {
  if (v == NULL) {
    return;
  }
  free(v->str);
  *v = som_value_none();
}

int som_value_equals(const SomValue *a, const SomValue *b) {
  if (a == NULL || b == NULL) {
    return a == b;
  }
  if (a->kind != b->kind) {
    return 0;
  }
  switch (a->kind) {
    case SOM_VALUE_NONE:
      return 1;
    case SOM_VALUE_STR:
      return strcmp(a->str != NULL ? a->str : "",
                    b->str != NULL ? b->str : "") == 0;
    case SOM_VALUE_INT:
      return a->integer == b->integer;
    case SOM_VALUE_DOUBLE:
      /* Bit-identical comparison is what a conformance replay wants: the
       * corpus pins exact values, not tolerances. */
      return a->real == b->real;
    case SOM_VALUE_BOOL:
      return (a->boolean != 0) == (b->boolean != 0);
  }
  return 0;
}

char *som_value_debug(const SomValue *v) {
  if (v == NULL) {
    return som_strdup("none");
  }
  char buf[128];
  switch (v->kind) {
    case SOM_VALUE_NONE:
      return som_strdup("none");
    case SOM_VALUE_STR: {
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "str \"");
      som_buf_puts(&b, v->str != NULL ? v->str : "");
      som_buf_puts(&b, "\"");
      return som_buf_take(&b);
    }
    case SOM_VALUE_INT:
      snprintf(buf, sizeof(buf), "int %lld", v->integer);
      return som_strdup(buf);
    case SOM_VALUE_DOUBLE: {
      char *text = som_format_double(v->real);
      snprintf(buf, sizeof(buf), "double %s", text);
      free(text);
      return som_strdup(buf);
    }
    case SOM_VALUE_BOOL:
      return som_strdup(v->boolean ? "bool true" : "bool false");
  }
  return som_strdup("none");
}

/* ---- the canonical number grammar -------------------------------------- */

/* The typed-value reading every runtime shares (decision tspubnondart20 (a),
 * the TypeScript `spec_typed_values.ts` canonical): the stored text is read
 * with its surrounding whitespace trimmed; an int is `^[+-]?[0-9]+$`, a double
 * `^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`. Everything
 * else — NaN, Infinity, hexadecimal, digit separators, the platform extensions
 * `strtod` would let through — is refused, because a spec value is finite. */

static int is_space(char ch) {
  return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' ||
         ch == '\v' || ch == '\f';
}

static int is_digit(char ch) { return ch >= '0' && ch <= '9'; }

/* An owned copy of `raw` without its surrounding whitespace, or NULL for NULL
 * or empty text. */
static char *trimmed_copy(const char *raw) {
  if (raw == NULL || raw[0] == '\0') {
    return NULL;
  }
  const char *b = raw;
  while (*b != '\0' && is_space(*b)) {
    b++;
  }
  size_t n = strlen(b);
  while (n > 0 && is_space(b[n - 1])) {
    n--;
  }
  char *out = (char *)malloc(n + 1);
  memcpy(out, b, n);
  out[n] = '\0';
  return out;
}

/* Whether `s` (already trimmed) is a decimal integer literal. */
static int int_text(const char *s) {
  size_t i = (s[0] == '+' || s[0] == '-') ? 1 : 0;
  if (!is_digit(s[i])) {
    return 0;
  }
  for (; s[i] != '\0'; i++) {
    if (!is_digit(s[i])) {
      return 0;
    }
  }
  return 1;
}

/* Whether `s` (already trimmed) is a decimal or exponent literal. */
static int float_text(const char *s) {
  size_t i = (s[0] == '+' || s[0] == '-') ? 1 : 0;
  size_t whole = 0;
  size_t frac = 0;
  while (is_digit(s[i])) {
    i++;
    whole++;
  }
  if (s[i] == '.') {
    i++;
    while (is_digit(s[i])) {
      i++;
      frac++;
    }
  }
  if (whole == 0 && frac == 0) {
    return 0;
  }
  if (s[i] == 'e' || s[i] == 'E') {
    i++;
    if (s[i] == '+' || s[i] == '-') {
      i++;
    }
    if (!is_digit(s[i])) {
      return 0;
    }
    while (is_digit(s[i])) {
      i++;
    }
  }
  return s[i] == '\0';
}

/* ---- int ---------------------------------------------------------------- */

/* ---- typed values under review (SOM §11.9.3) ---------------------------- */

char *som_typed_reading(const char *raw) {
  if (raw == NULL) {
    return NULL;
  }
  if (strchr(raw, '{') == NULL) {
    return som_strdup(raw);
  }
  char *old = spec_apply_inline_marks_text(raw, 0);
  if (strcmp(old, raw) == 0) {
    return old;
  }
  /* Trimmed, as the reference trims the old value. */
  const char *s = old;
  while (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r' || *s == '\f' ||
         *s == '\v') {
    s++;
  }
  size_t n = strlen(s);
  while (n > 0 && (s[n - 1] == ' ' || s[n - 1] == '\t' || s[n - 1] == '\n' ||
                   s[n - 1] == '\r' || s[n - 1] == '\f' || s[n - 1] == '\v')) {
    n--;
  }
  char *out = som_strdup_n(s, n);
  free(old);
  return out;
}

int som_is_typed_field(const char *type_name, const SomStrList *enum_values) {
  if (enum_values != NULL && enum_values->len > 0) {
    return 1;
  }
  char *base = som_scalar_base(type_name);
  int typed = base != NULL &&
              (strcmp(base, "int") == 0 || strcmp(base, "double") == 0 ||
               strcmp(base, "num") == 0 || strcmp(base, "bool") == 0);
  free(base);
  return typed;
}


int som_parse_int(const char *raw, long long *out) {
  char *reading = som_typed_reading(raw);
  char *text = trimmed_copy(reading);
  free(reading);
  if (text == NULL) {
    return 0;
  }
  int ok = int_text(text) && som_parse_i64(text, out);
  free(text);
  return ok;
}

char *som_format_int(long long value) { return som_format_i64(value); }

/* ---- double ------------------------------------------------------------- */

int som_parse_double(const char *raw, double *out) {
  char *reading = som_typed_reading(raw);
  char *text = trimmed_copy(reading);
  free(reading);
  if (text == NULL) {
    return 0;
  }
  int ok = 0;
  if (float_text(text)) {
    /* A literal that overflows to infinity is no value either: a spec value
     * is finite (no libm: the comparison against DBL_MAX is the check). */
    double v = strtod(text, NULL);
    if (v >= -DBL_MAX && v <= DBL_MAX) {
      *out = v;
      ok = 1;
    }
  }
  free(text);
  return ok;
}

char *som_format_double(double value) {
  /* Shortest round-trip digits, laid out like Dart's `double.toString` and
   * JavaScript's Number.prototype.toString, always with a fraction or an
   * exponent (`1.0`, `1000.0`, `1e+21`). */
  return yaml_format_double(value);
}

/* ---- num ---------------------------------------------------------------- */

int som_parse_num(const char *raw, SomValue *out) {
  long long i = 0;
  if (som_parse_int(raw, &i)) {
    *out = som_value_int(i);
    return 1;
  }
  double d = 0.0;
  if (som_parse_double(raw, &d)) {
    *out = som_value_double(d);
    return 1;
  }
  return 0;
}

char *som_format_num(const SomValue *value) {
  if (value == NULL) {
    return som_strdup("");
  }
  if (value->kind == SOM_VALUE_INT) {
    return som_format_int(value->integer);
  }
  if (value->kind == SOM_VALUE_DOUBLE) {
    return som_format_double(value->real);
  }
  return som_strdup("");
}

/* ---- bool --------------------------------------------------------------- */

int som_parse_bool(const char *raw, int *out) {
  char *reading = som_typed_reading(raw);
  if (reading == NULL) {
    return 0;
  }
  int ok = 0;
  if (strcmp(reading, "true") == 0) {
    *out = 1;
    ok = 1;
  } else if (strcmp(reading, "false") == 0) {
    *out = 0;
    ok = 1;
  }
  free(reading);
  return ok;
}

char *som_format_bool(int value) {
  return som_strdup(value ? "true" : "false");
}

/* ---- enum constant names ------------------------------------------------ */

int som_parse_enum_name(const char *raw, const SomStrList *values, char **out) {
  char *reading = som_typed_reading(raw);
  if (reading == NULL || reading[0] == '\0' || values == NULL ||
      !som_strlist_contains(values, reading)) {
    free(reading);
    return 0;
  }
  if (out != NULL) {
    *out = reading;
  } else {
    free(reading);
  }
  return 1;
}

char *som_format_enum_name(const char *name, const SomStrList *values,
                           char **err) {
  if (name == NULL || name[0] == '\0') {
    return som_strdup("");
  }
  if (values != NULL && som_strlist_contains(values, name)) {
    return som_strdup(name);
  }
  if (err != NULL) {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "\"");
    som_buf_puts(&b, name);
    som_buf_puts(&b, "\" is not one of the enum values ");
    char *joined = values != NULL ? som_strlist_join(values, ", ")
                                  : som_strdup("");
    som_buf_puts(&b, joined);
    free(joined);
    *err = som_buf_take(&b);
  }
  return NULL;
}

/* ---- typed-text readability (valueTypeMismatch) ------------------------ */

char *som_scalar_base(const char *type_name) {
  if (type_name == NULL) {
    return NULL;
  }
  size_t n = strlen(type_name);
  if (n > 0 && type_name[n - 1] == '?') {
    n--;
  }
  char *out = (char *)malloc(n + 1);
  memcpy(out, type_name, n);
  out[n] = '\0';
  return out;
}

int som_typed_text_readable(const char *type_name, const char *raw) {
  char *reading = som_typed_reading(raw);
  int empty = reading == NULL || reading[0] == '\0';
  free(reading);
  if (empty) {
    return 1;
  }
  char *base = som_scalar_base(type_name);
  int ok = 1;
  if (base != NULL) {
    if (strcmp(base, "int") == 0) {
      long long i;
      ok = som_parse_int(raw, &i);
    } else if (strcmp(base, "double") == 0) {
      double d;
      ok = som_parse_double(raw, &d);
    } else if (strcmp(base, "num") == 0) {
      SomValue v = som_value_none();
      ok = som_parse_num(raw, &v);
      som_value_free(&v);
    } else if (strcmp(base, "bool") == 0) {
      int b;
      ok = som_parse_bool(raw, &b);
    }
  }
  free(base);
  return ok;
}
