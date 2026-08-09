#include "spec_node_creation.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"
#include "spec_section_id.h"

const SpecCreationCode SPEC_CREATION_ALL_CODES[SPEC_CREATION_ALL_CODES_COUNT] = {
    SPEC_CREATION_NOT_A_CONTAINER, SPEC_CREATION_UNKNOWN_CHILD,
    SPEC_CREATION_PATTERN_MISMATCH, SPEC_CREATION_DUPLICATE_SECTION_ID,
    SPEC_CREATION_CARDINALITY_EXCEEDED,
};

const char *spec_creation_code_name(SpecCreationCode code) {
  switch (code) {
    case SPEC_CREATION_NOT_A_CONTAINER:
      return "notAContainer";
    case SPEC_CREATION_UNKNOWN_CHILD:
      return "unknownChild";
    case SPEC_CREATION_PATTERN_MISMATCH:
      return "patternMismatch";
    case SPEC_CREATION_DUPLICATE_SECTION_ID:
      return "duplicateSectionId";
    case SPEC_CREATION_CARDINALITY_EXCEEDED:
      return "cardinalityExceeded";
    case SPEC_CREATION_OK:
      break;
  }
  return "";
}

void spec_creation_error_init(SpecCreationError *e) {
  e->code = SPEC_CREATION_OK;
  e->parent_path = NULL;
  e->child_segment = NULL;
  e->message = NULL;
}

void spec_creation_error_free(SpecCreationError *e) {
  free(e->parent_path);
  free(e->child_segment);
  free(e->message);
  spec_creation_error_init(e);
}

int spec_creation_error_is_ok(const SpecCreationError *e) {
  return e->code == SPEC_CREATION_OK;
}

char *spec_creation_error_string(const SpecCreationError *e) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "SpecCreationError(");
  som_buf_puts(&b, spec_creation_code_name(e->code));
  som_buf_puts(&b, ") under \"");
  som_buf_puts(&b, e->parent_path == NULL ? "" : e->parent_path);
  som_buf_puts(&b, "\" → \"");
  som_buf_puts(&b, e->child_segment == NULL ? "" : e->child_segment);
  som_buf_puts(&b, "\": ");
  som_buf_puts(&b, e->message == NULL ? "" : e->message);
  return som_buf_take(&b);
}

/* Fills `*out` with a rejection, standing in for the Dart `err(...)` closure. */
static void reject(SpecCreationError *out, const char *parent_path,
                   const char *child_segment, SpecCreationCode code,
                   const char *fmt, ...) {
  char buf[1024];
  va_list ap;
  va_start(ap, fmt);
  vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  out->code = code;
  out->parent_path = som_strdup(parent_path);
  out->child_segment = som_strdup(child_segment);
  out->message = som_strdup(buf);
}

/* The name the other ports give this field kind — the runtime stores the raw
 * meta-data spelling `enum`, the ports' enum constant is `enumValue`. Only
 * message text depends on it. */
static const char *field_kind_name(const char *kind) {
  return strcmp(kind, SPEC_FIELD_KIND_ENUM) == 0 ? "enumValue" : kind;
}

/* The field of `cls` whose section segment (`@SectionId` ?? name) is `segment`,
 * or NULL when the class declares no such child. */
static const SpecField *field_for_segment(const SpecClass *cls,
                                          const char *segment) {
  size_t i;
  for (i = 0; i < cls->fields_len; i++) {
    if (strcmp(spec_reflection_field_segment(&cls->fields[i]), segment) == 0) {
      return &cls->fields[i];
    }
  }
  return NULL;
}

void spec_check_add_node(const SpecModel *model, const SpecDocument *document,
                         const char *parent_path, const char *child_segment,
                         const char *item_id, SpecCreationError *out) {
  spec_creation_error_init(out);
  SpecReflection refl = spec_reflection_make(model);

  /* 1. The parent must resolve to a class-bearing node (root / complex /
   *    section / complex list item). Leaves, lists and dangling paths cannot
   *    own named children. */
  SpecResolution parent;
  int resolved = spec_reflection_resolve(&refl, parent_path, &parent);
  if (!resolved || parent.target_class == NULL) {
    char what[128];
    if (!resolved) {
      snprintf(what, sizeof(what), "does not resolve");
    } else {
      snprintf(what, sizeof(what), "is a %s", parent.kind);
    }
    reject(out, parent_path, child_segment, SPEC_CREATION_NOT_A_CONTAINER,
           "parent path %s and cannot own child nodes", what);
    if (resolved) {
      spec_resolution_free(&parent);
    }
    return;
  }
  const SpecClass *parent_class = parent.target_class;

  /* 2. The child segment must name a declared field of the parent's class. */
  const SpecField *field = field_for_segment(parent_class, child_segment);
  if (field == NULL) {
    reject(out, parent_path, child_segment, SPEC_CREATION_UNKNOWN_CHILD,
           "\"%s\" is not a child of %s", child_segment, parent_class->name);
    spec_resolution_free(&parent);
    return;
  }

  char *child_path = spec_path_join(parent_path, child_segment);

  if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0) {
    /* 3. List item: validate a caller-proposed id. Lists have no upper bound,
     *    so there is no cardinality check. A missing id is generated later
     *    (criterion 3); an explicit override must keep the pattern prefix
     *    (criterion 3) and stay unique within the list (criterion 5). */
    const char *pattern = field->section_id_pattern;
    if (item_id != NULL && pattern != NULL && pattern[0] != '\0') {
      char *prefix = spec_section_id_pattern_prefix(pattern);
      if (strncmp(item_id, prefix, strlen(prefix)) != 0) {
        reject(out, parent_path, child_segment, SPEC_CREATION_PATTERN_MISMATCH,
               "item id \"%s\" does not keep the pattern prefix \"%s\"",
               item_id, prefix);
        free(prefix);
        free(child_path);
        spec_resolution_free(&parent);
        return;
      }
      free(prefix);
      SomStrList ids;
      spec_document_list_item_section_ids(document, child_path, &ids);
      int duplicate = som_strlist_contains(&ids, item_id);
      som_strlist_free(&ids);
      if (duplicate) {
        reject(out, parent_path, child_segment,
               SPEC_CREATION_DUPLICATE_SECTION_ID,
               "item id \"%s\" is already used in list \"%s\"", item_id,
               child_path);
        free(child_path);
        spec_resolution_free(&parent);
        return;
      }
    }
    free(child_path);
    spec_resolution_free(&parent);
    return;
  }

  /* 4. Single-valued child (complex / section / form / content / enum /
   *    scalar): cardinality is exactly one, so reject if a value already exists
   *    at or beneath the child path. */
  if (spec_document_has_values_under(document, child_path)) {
    reject(out, parent_path, child_segment, SPEC_CREATION_CARDINALITY_EXCEEDED,
           "a %s child already exists at \"%s\"", field_kind_name(field->kind),
           child_path);
  }
  free(child_path);
  spec_resolution_free(&parent);
}

SpecNodeCreator spec_node_creator_make(const SpecModel *model,
                                       SpecDocument *document) {
  SpecNodeCreator c;
  c.model = model;
  c.document = document;
  return c;
}

int spec_node_creator_add(SpecNodeCreator *c, const char *parent_path,
                          const char *child_segment, const char *item_id,
                          long long month, long long day, char **out_path,
                          SpecCreationError *err) {
  SpecCreationError gate;
  spec_check_add_node(c->model, c->document, parent_path, child_segment,
                      item_id, &gate);
  if (!spec_creation_error_is_ok(&gate)) {
    if (err != NULL) {
      *err = gate; /* ownership of the strings moves to the caller */
    } else {
      spec_creation_error_free(&gate);
    }
    return 0;
  }
  spec_creation_error_free(&gate);

  SpecReflection refl = spec_reflection_make(c->model);
  SpecResolution parent;
  /* The gate already proved this resolves to a class-bearing node. */
  spec_reflection_resolve(&refl, parent_path, &parent);
  const SpecField *field = field_for_segment(parent.target_class, child_segment);
  spec_resolution_free(&parent);

  char *child_path = spec_path_join(parent_path, child_segment);
  if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) != 0) {
    *out_path = child_path;
    return 1;
  }

  const char *pattern = field->section_id_pattern;
  if (pattern == NULL || pattern[0] == '\0') {
    *out_path = spec_document_add_list_item(c->document, child_path);
    free(child_path);
    return 1;
  }

  char *generated = NULL;
  const char *id = item_id;
  if (id == NULL) {
    long long m = month;
    long long d = day;
    if (m <= 0 || d <= 0) {
      spec_today_month_day(&m, &d);
    }
    SomStrList existing;
    spec_document_list_item_section_ids(c->document, child_path, &existing);
    generated = spec_generate_list_item_section_id(pattern, m, d, &existing);
    som_strlist_free(&existing);
    id = generated;
  }

  SpecSectionIdError id_err;
  spec_section_id_error_init(&id_err);
  char *item_path = spec_document_add_list_item_with_section_id(
      c->document, child_path, id, &id_err);
  free(generated);
  if (item_path == NULL) {
    /* The gate checks the same uniqueness rule, so this is only reachable when
     * a generated id collides — reported under the same code an explicit
     * duplicate would get. */
    if (err != NULL) {
      spec_creation_error_init(err);
      reject(err, parent_path, child_segment,
             SPEC_CREATION_DUPLICATE_SECTION_ID,
             "item id \"%s\" is already used in list \"%s\"",
             id_err.id == NULL ? "" : id_err.id, child_path);
    }
    spec_section_id_error_free(&id_err);
    free(child_path);
    return 0;
  }
  spec_section_id_error_free(&id_err);
  free(child_path);
  *out_path = item_path;
  return 1;
}
