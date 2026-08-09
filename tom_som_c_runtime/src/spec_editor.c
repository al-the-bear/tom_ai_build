#include "spec_editor.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_section_id.h"

/* ---- diagnostics --------------------------------------------------------- */

/* Writes an owned formatted message to `*err` when `err` is non-NULL. */
static void set_err(char **err, const char *fmt, ...) {
  if (err == NULL) {
    return;
  }
  char buf[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  *err = som_strdup(buf);
}

/* ---- construction -------------------------------------------------------- */

SpecEditor spec_editor_make(SpecDocument *doc, SpecReflection reflection) {
  SpecEditor e;
  e.doc = doc;
  e.reflection = reflection;
  return e;
}

SpecEditor spec_editor_for_model(SpecDocument *doc, const SpecModel *model) {
  return spec_editor_make(doc, spec_reflection_make(model));
}

/* ---- resolution ---------------------------------------------------------- */

int spec_editor_resolve(const SpecEditor *e, const char *path,
                        SpecResolution *out, char **err) {
  if (!spec_reflection_resolve(&e->reflection, path, out)) {
    set_err(err, "path \"%s\" does not resolve against the model",
            path != NULL ? path : "");
    return 0;
  }
  return 1;
}

/* Resolves `path` and additionally requires it to be a value leaf. */
static int resolve_value_leaf(const SpecEditor *e, const char *path,
                              SpecResolution *out, char **err) {
  if (!spec_editor_resolve(e, path, out, err)) {
    return 0;
  }
  if (!spec_resolution_is_value_leaf(out)) {
    set_err(err, "path \"%s\" is a %s node, not a value leaf", path, out->kind);
    spec_resolution_free(out);
    return 0;
  }
  return 1;
}

/* Resolves `path` and requires it to be a `@Form` section. */
static int resolve_form(const SpecEditor *e, const char *path,
                        SpecResolution *out, char **err) {
  if (!spec_editor_resolve(e, path, out, err)) {
    return 0;
  }
  if (strcmp(out->kind, SPEC_NODE_KIND_FORM) != 0) {
    set_err(err, "path \"%s\" is a %s node, not a @Form section", path,
            out->kind);
    spec_resolution_free(out);
    return 0;
  }
  return 1;
}

/* Resolves the `@Form` section at `path` and returns its `field` spec
 * (borrowed), or NULL when the path or the field name does not name one. */
static const FormFieldSpec *resolve_form_field(const SpecEditor *e,
                                               const char *path,
                                               const char *field,
                                               char **err) {
  SpecResolution r;
  if (!resolve_form(e, path, &r, err)) {
    return NULL;
  }
  const FormFieldSpec *found = NULL;
  if (r.field != NULL) {
    for (size_t i = 0; i < r.field->form_fields_len && found == NULL; i++) {
      if (strcmp(r.field->form_fields[i].name, field) == 0) {
        found = &r.field->form_fields[i];
      }
    }
  }
  if (found == NULL) {
    set_err(err, "\"%s\" is not a form field of %s", field, path);
  }
  spec_resolution_free(&r); /* the spec is borrowed from the model, not from r */
  return found;
}

/* ---- conversion ---------------------------------------------------------- */

/* The declared type with a trailing `?` stripped ("" when undeclared). The
 * result points into `type_name` or at the static empty string. */
static const char *scalar_base(const char *type_name, char *scratch,
                               size_t scratch_len) {
  if (type_name == NULL || type_name[0] == '\0') {
    return "";
  }
  size_t n = strlen(type_name);
  if (type_name[n - 1] != '?') {
    return type_name;
  }
  if (n - 1 >= scratch_len) {
    return "";
  }
  memcpy(scratch, type_name, n - 1);
  scratch[n - 1] = '\0';
  return scratch;
}

/* Parses stored text per the declared scalar base type — the read side of the
 * boundary. Unparsable text yields SOM_VALUE_NONE (reads are forgiving). */
static SomValue parse_scalar(const char *raw, const char *base) {
  if (strcmp(base, "int") == 0) {
    long long i = 0;
    return som_parse_int(raw, &i) ? som_value_int(i) : som_value_none();
  }
  if (strcmp(base, "double") == 0) {
    double d = 0.0;
    return som_parse_double(raw, &d) ? som_value_double(d) : som_value_none();
  }
  if (strcmp(base, "num") == 0) {
    SomValue v;
    return som_parse_num(raw, &v) ? v : som_value_none();
  }
  if (strcmp(base, "bool") == 0) {
    int b = 0;
    return som_parse_bool(raw, &b) ? som_value_bool(b) : som_value_none();
  }
  return som_value_str(raw);
}

/* The string a value carries, or NULL for SOM_VALUE_NONE; fails for any other
 * kind (the enum and `@Form`-name positions are string-only). */
static int string_or_none(const SomValue *v, const char *path,
                          const char *where, const char **out, char **err) {
  if (v == NULL || v->kind == SOM_VALUE_NONE) {
    *out = NULL;
    return 1;
  }
  if (v->kind == SOM_VALUE_STR) {
    *out = v->str;
    return 1;
  }
  char *shown = som_value_debug(v);
  set_err(err, "%s: expected a string for this field of %s (got %s)", where,
          path, shown);
  free(shown);
  return 0;
}

/* Formats `v` for the store per the leaf's declared type; strings pass through
 * verbatim (the plain-text serialization is authoritative). Writes an owned
 * string to `*out` and returns 1; returns 0 on a wrong value kind or an
 * out-of-domain enum name. */
static int format_value(const SomValue *v, const char *kind,
                        const SpecField *field, const char *path,
                        const char *type_name, const char *where, char **out,
                        char **err) {
  if (v == NULL || v->kind == SOM_VALUE_NONE) {
    *out = som_strdup("");
    return 1;
  }
  if (kind != NULL && strcmp(kind, SPEC_NODE_KIND_ENUM_VALUE) == 0) {
    const char *name = NULL;
    if (!string_or_none(v, path, where != NULL ? where : path, &name, err)) {
      return 0;
    }
    char *stored = som_format_enum_name(
        name, field != NULL ? &field->enum_values : NULL, err);
    if (stored == NULL) {
      return 0;
    }
    *out = stored;
    return 1;
  }

  char scratch[128];
  const char *declared =
      type_name != NULL ? type_name : (field != NULL ? field->type : NULL);
  const char *base = scalar_base(declared, scratch, sizeof(scratch));

  if (strcmp(base, "int") == 0) {
    if (v->kind == SOM_VALUE_INT) {
      *out = som_format_int(v->integer);
      return 1;
    }
  } else if (strcmp(base, "double") == 0) {
    if (v->kind == SOM_VALUE_DOUBLE) {
      *out = som_format_double(v->real);
      return 1;
    }
    /* An int written into a double field widens — and must still store with a
     * decimal point, so `2` lands as "2.0". */
    if (v->kind == SOM_VALUE_INT) {
      *out = som_format_double((double)v->integer);
      return 1;
    }
  } else if (strcmp(base, "num") == 0) {
    if (v->kind == SOM_VALUE_INT || v->kind == SOM_VALUE_DOUBLE) {
      *out = som_format_num(v);
      return 1;
    }
  } else if (strcmp(base, "bool") == 0) {
    if (v->kind == SOM_VALUE_BOOL) {
      *out = som_format_bool(v->boolean);
      return 1;
    }
  }
  if (v->kind == SOM_VALUE_STR) {
    *out = som_strdup(v->str);
    return 1;
  }
  char *shown = som_value_debug(v);
  set_err(err, "%s at %s: wrong value type for a %s field", shown,
          where != NULL ? where : path, base[0] != '\0' ? base : "String");
  free(shown);
  return 0;
}

/* ---- value leaves -------------------------------------------------------- */

int spec_editor_value(const SpecEditor *e, const char *path, SomValue *out,
                      char **err) {
  SpecResolution r;
  if (!resolve_value_leaf(e, path, &r, err)) {
    return 0;
  }
  const char *raw = spec_document_content(e->doc, path);
  if (raw == NULL || raw[0] == '\0') {
    *out = som_value_none();
  } else if (strcmp(r.kind, SPEC_NODE_KIND_ENUM_VALUE) == 0) {
    char *name = NULL;
    *out = som_parse_enum_name(raw, r.field != NULL ? &r.field->enum_values
                                                    : NULL,
                               &name)
               ? som_value_str(name)
               : som_value_none();
    free(name);
  } else {
    char scratch[128];
    *out = parse_scalar(
        raw, scalar_base(r.field != NULL ? r.field->type : NULL, scratch,
                         sizeof(scratch)));
  }
  spec_resolution_free(&r);
  return 1;
}

int spec_editor_set_value(SpecEditor *e, const char *path, const SomValue *v,
                          char **err) {
  SpecResolution r;
  if (!resolve_value_leaf(e, path, &r, err)) {
    return 0;
  }
  char *stored = NULL;
  int ok = format_value(v, r.kind, r.field, path, NULL, NULL, &stored, err);
  spec_resolution_free(&r);
  if (!ok) {
    return 0;
  }
  spec_document_set_content(e->doc, path, stored);
  free(stored);
  return 1;
}

/* ---- headlines (YRD3) ---------------------------------------------------- */

int spec_editor_headline(const SpecEditor *e, const char *path,
                         const char **out, char **err) {
  SpecResolution r;
  if (!spec_editor_resolve(e, path, &r, err)) {
    return 0;
  }
  spec_resolution_free(&r);
  if (out != NULL) {
    *out = spec_document_headline(e->doc, path);
  }
  return 1;
}

int spec_editor_set_headline(SpecEditor *e, const char *path,
                             const char *value, char **err) {
  SpecResolution r;
  if (!spec_editor_resolve(e, path, &r, err)) {
    return 0;
  }
  spec_resolution_free(&r);
  spec_document_set_headline(e->doc, path, value != NULL ? value : "");
  return 1;
}

/* ---- typed form fields --------------------------------------------------- */

int spec_editor_form_value(const SpecEditor *e, const char *path,
                           const char *field, SomValue *out, char **err) {
  const FormFieldSpec *ff = resolve_form_field(e, path, field, err);
  if (ff == NULL) {
    return 0;
  }
  const char *raw = spec_document_form_field(e->doc, path, field);
  if (raw == NULL || raw[0] == '\0') {
    *out = som_value_none();
    return 1;
  }
  if (ff->enum_values.len > 0) {
    char *name = NULL;
    *out = som_parse_enum_name(raw, &ff->enum_values, &name)
               ? som_value_str(name)
               : som_value_none();
    free(name);
    return 1;
  }
  char scratch[128];
  *out = parse_scalar(raw, scalar_base(ff->type, scratch, sizeof(scratch)));
  return 1;
}

int spec_editor_set_form_value(SpecEditor *e, const char *path,
                               const char *field, const SomValue *v,
                               char **err) {
  const FormFieldSpec *ff = resolve_form_field(e, path, field, err);
  if (ff == NULL) {
    return 0;
  }
  char *stored = NULL;
  if (ff->enum_values.len > 0) {
    const char *name = NULL;
    if (!string_or_none(v, path, field, &name, err)) {
      return 0;
    }
    stored = som_format_enum_name(name, &ff->enum_values, err);
    if (stored == NULL) {
      return 0;
    }
  } else if (!format_value(v, SPEC_NODE_KIND_SCALAR, NULL, path, ff->type,
                           field, &stored, err)) {
    return 0;
  }
  spec_document_set_form_field(e->doc, path, field, stored);
  free(stored);
  return 1;
}

int spec_editor_form_fields(const SpecEditor *e, const char *path,
                            const FormFieldSpec **out, size_t *out_len,
                            char **err) {
  SpecResolution r;
  if (!resolve_form(e, path, &r, err)) {
    return 0;
  }
  if (out != NULL) {
    *out = r.field != NULL ? r.field->form_fields : NULL;
  }
  if (out_len != NULL) {
    *out_len = r.field != NULL ? r.field->form_fields_len : 0;
  }
  spec_resolution_free(&r);
  return 1;
}

/* ---- structural operations ----------------------------------------------- */

int spec_editor_add_list_item(SpecEditor *e, const char *list_path,
                              const char *section_id, long long month,
                              long long day, char **out_item_path,
                              SpecSectionIdError *id_err, char **err) {
  SpecResolution r;
  if (!spec_editor_resolve(e, list_path, &r, err)) {
    return 0;
  }
  if (strcmp(r.kind, SPEC_NODE_KIND_LIST) != 0) {
    set_err(err, "path \"%s\" is a %s node, not a list", list_path, r.kind);
    spec_resolution_free(&r);
    return 0;
  }
  const char *pattern =
      (r.field != NULL && r.field->section_id_pattern[0] != '\0')
          ? r.field->section_id_pattern
          : NULL;
  spec_resolution_free(&r);

  char *generated = NULL;
  const char *id = (section_id != NULL && section_id[0] != '\0') ? section_id
                                                                 : NULL;
  if (id == NULL && pattern != NULL) {
    long long m = month, d = day;
    if (m <= 0 || d <= 0) {
      long long today_m = 0, today_d = 0;
      spec_today_month_day(&today_m, &today_d);
      if (m <= 0) m = today_m;
      if (d <= 0) d = today_d;
    }
    SomStrList existing;
    spec_document_list_item_section_ids(e->doc, list_path, &existing);
    generated = spec_generate_list_item_section_id(pattern, m, d, &existing);
    som_strlist_free(&existing);
    id = generated;
  }

  char *item_path;
  if (id == NULL) {
    item_path = spec_document_add_list_item(e->doc, list_path);
  } else {
    item_path =
        spec_document_add_list_item_with_section_id(e->doc, list_path, id, id_err);
  }
  if (item_path == NULL) {
    set_err(err, "section id \"%s\" is already used within %s", id, list_path);
    free(generated);
    return 0;
  }
  free(generated);
  if (out_item_path != NULL) {
    *out_item_path = item_path;
  } else {
    free(item_path);
  }
  return 1;
}

int spec_editor_remove_list_item(SpecEditor *e, const char *item_path) {
  return spec_document_remove_list_item(e->doc, item_path);
}

int spec_editor_clear_section(SpecEditor *e, const char *path, char **err) {
  SpecResolution r;
  if (!spec_editor_resolve(e, path, &r, err)) {
    return 0;
  }
  spec_resolution_free(&r);
  spec_document_remove_values_under(e->doc, path);
  return 1;
}
