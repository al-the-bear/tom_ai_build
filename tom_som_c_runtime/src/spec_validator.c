#include "spec_validator.h"

#include <stdlib.h>
#include <string.h>

#include "spec_reflection.h"

static void errors_push(SpecValidationErrors *errs, const char *path,
                        const char *code, char *message_owned) {
  if (errs->len == errs->cap) {
    errs->cap = errs->cap ? errs->cap * 2 : 4;
    errs->items = (SpecValidationError *)realloc(
        errs->items, errs->cap * sizeof(SpecValidationError));
  }
  errs->items[errs->len].path = som_strdup(path);
  errs->items[errs->len].code = som_strdup(code);
  errs->items[errs->len].message = message_owned;
  errs->len++;
}

static char *fmt_kind(const char *prefix, const char *kind) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, prefix);
  som_buf_puts(&b, kind);
  return som_buf_take(&b);
}

void validate_document(const SpecModel *model, const SpecDocument *doc,
                       SpecValidationErrors *out) {
  out->items = NULL;
  out->len = 0;
  out->cap = 0;

  SpecReflection refl = spec_reflection_make(model);

  /* 1. Content/scalar/enum leaves (content_paths already sorted). */
  SomStrList content_paths;
  spec_document_content_paths(doc, &content_paths);
  for (size_t i = 0; i < content_paths.len; i++) {
    const char *path = content_paths.items[i];
    SpecResolution res;
    if (!spec_reflection_resolve(&refl, path, &res)) {
      errors_push(out, path, SPEC_VALIDATION_CODE_DANGLING_PATH,
                  som_strdup("path does not resolve to any model node"));
      continue;
    }
    if (!spec_resolution_is_value_leaf(&res)) {
      errors_push(out, path, SPEC_VALIDATION_CODE_KIND_MISMATCH,
                  fmt_kind("expected a value leaf but path resolves to ",
                           res.kind));
    }
    spec_resolution_free(&res);
  }
  som_strlist_free(&content_paths);

  /* 2. Form sections. */
  SomStrList form_paths;
  spec_document_form_paths(doc, &form_paths);
  for (size_t i = 0; i < form_paths.len; i++) {
    const char *path = form_paths.items[i];
    SpecResolution res;
    if (!spec_reflection_resolve(&refl, path, &res)) {
      errors_push(out, path, SPEC_VALIDATION_CODE_DANGLING_PATH,
                  som_strdup("path does not resolve to any model node"));
      continue;
    }
    if (res.field == NULL || strcmp(res.kind, SPEC_NODE_KIND_FORM) != 0) {
      errors_push(out, path, SPEC_VALIDATION_CODE_KIND_MISMATCH,
                  fmt_kind("expected a form section but path resolves to ",
                           res.kind));
      spec_resolution_free(&res);
      continue;
    }
    const SpecField *field = res.field;
    SomStrList names;
    spec_document_form_field_names(doc, path, &names);
    for (size_t j = 0; j < names.len; j++) {
      int declared = 0;
      for (size_t k = 0; k < field->form_fields_len; k++) {
        if (strcmp(field->form_fields[k].name, names.items[j]) == 0) {
          declared = 1;
          break;
        }
      }
      if (!declared) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "form field \"");
        som_buf_puts(&b, names.items[j]);
        som_buf_puts(&b, "\" is not declared on ");
        som_buf_puts(&b, field->name);
        errors_push(out, path, SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD,
                    som_buf_take(&b));
      }
    }
    som_strlist_free(&names);
    spec_resolution_free(&res);
  }
  som_strlist_free(&form_paths);

  /* 3. Lists (container kind + @Min count on populated lists). */
  SomStrList list_paths;
  spec_document_list_paths(doc, &list_paths);
  for (size_t i = 0; i < list_paths.len; i++) {
    const char *path = list_paths.items[i];
    SpecResolution res;
    if (!spec_reflection_resolve(&refl, path, &res)) {
      errors_push(out, path, SPEC_VALIDATION_CODE_DANGLING_PATH,
                  som_strdup("path does not resolve to any model node"));
      continue;
    }
    if (res.field == NULL || strcmp(res.kind, SPEC_NODE_KIND_LIST) != 0) {
      errors_push(out, path, SPEC_VALIDATION_CODE_KIND_MISMATCH,
                  fmt_kind("expected a list but path resolves to ", res.kind));
      spec_resolution_free(&res);
      continue;
    }
    const SpecField *field = res.field;
    if (field->has_min) {
      long long count = (long long)spec_document_list_item_count(doc, path);
      if (count < field->min) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "list holds ");
        som_buf_puti(&b, count);
        som_buf_puts(&b, " item(s) but requires at least ");
        som_buf_puti(&b, field->min);
        errors_push(out, path, SPEC_VALIDATION_CODE_MIN_ITEMS,
                    som_buf_take(&b));
      }
    }
    spec_resolution_free(&res);
  }
  som_strlist_free(&list_paths);
}

void spec_validation_errors_free(SpecValidationErrors *errs) {
  for (size_t i = 0; i < errs->len; i++) {
    free(errs->items[i].path);
    free(errs->items[i].code);
    free(errs->items[i].message);
  }
  free(errs->items);
  errs->items = NULL;
  errs->len = 0;
  errs->cap = 0;
}
