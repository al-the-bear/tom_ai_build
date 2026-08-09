#include "spec_typed_values.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

/* ---- int ---------------------------------------------------------------- */

int som_parse_int(const char *raw, long long *out) {
  if (raw == NULL || raw[0] == '\0') {
    return 0;
  }
  return som_parse_i64(raw, out);
}

char *som_format_int(long long value) { return som_format_i64(value); }

/* ---- double ------------------------------------------------------------- */

/* Dart's `double.tryParse` grammar minus the platform extensions `strtod`
 * would otherwise let through: no leading/trailing whitespace and no hex
 * literal, so every runtime accepts the same set of strings. */
static int parse_finite_double(const char *raw, double *out) {
  if (raw == NULL || raw[0] == '\0') {
    return 0;
  }
  size_t i = (raw[0] == '+' || raw[0] == '-') ? 1 : 0;
  if (raw[i] == '0' && (raw[i + 1] == 'x' || raw[i + 1] == 'X')) {
    return 0;
  }
  char *end = NULL;
  double v = strtod(raw, &end);
  if (end == raw || end == NULL || *end != '\0') {
    return 0;
  }
  *out = v;
  return 1;
}

int som_parse_double(const char *raw, double *out) {
  if (raw == NULL || raw[0] == '\0') {
    return 0;
  }
  /* The three named literals Dart spells with capitals; `strtod` would accept
   * `inf`/`nan` in any case, which the other ports do not. */
  const char *s = (raw[0] == '+' || raw[0] == '-') ? raw + 1 : raw;
  double sign = (raw[0] == '-') ? -1.0 : 1.0;
  if (strcmp(s, "Infinity") == 0) {
    *out = sign * HUGE_VAL;
    return 1;
  }
  if (strcmp(s, "NaN") == 0) {
    *out = (double)NAN;
    return 1;
  }
  return parse_finite_double(raw, out);
}

char *som_format_double(double value) {
  if (isnan(value)) {
    return som_strdup("NaN");
  }
  if (isinf(value)) {
    return som_strdup(value > 0 ? "Infinity" : "-Infinity");
  }
  /* Shortest representation that still round-trips, matching Dart's
   * `double.toString` (and Python's `repr`). */
  char buf[64];
  for (int prec = 1; prec <= 17; prec++) {
    snprintf(buf, sizeof(buf), "%.*g", prec, value);
    if (strtod(buf, NULL) == value) {
      break;
    }
  }
  /* An integral double must stay distinguishable from an int in the store:
   * `%g` renders 2.0 as "2", so give it back its decimal point. */
  if (strpbrk(buf, ".eE") == NULL) {
    size_t n = strlen(buf);
    if (n + 3 <= sizeof(buf)) {
      buf[n] = '.';
      buf[n + 1] = '0';
      buf[n + 2] = '\0';
    }
  }
  return som_strdup(buf);
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
  if (raw == NULL) {
    return 0;
  }
  if (strcmp(raw, "true") == 0) {
    *out = 1;
    return 1;
  }
  if (strcmp(raw, "false") == 0) {
    *out = 0;
    return 1;
  }
  return 0;
}

char *som_format_bool(int value) {
  return som_strdup(value ? "true" : "false");
}

/* ---- enum constant names ------------------------------------------------ */

int som_parse_enum_name(const char *raw, const SomStrList *values, char **out) {
  if (raw == NULL || raw[0] == '\0' || values == NULL) {
    return 0;
  }
  if (!som_strlist_contains(values, raw)) {
    return 0;
  }
  if (out != NULL) {
    *out = som_strdup(raw);
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
