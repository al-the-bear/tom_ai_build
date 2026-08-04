#include "spec_reflection.h"

#include <stdlib.h>
#include <string.h>

#include "spec_paths.h"

void spec_resolution_free(SpecResolution *r) {
  if (r == NULL) {
    return;
  }
  free(r->path);
  r->path = NULL;
}

static int kind_is_value_leaf(const char *kind) {
  return strcmp(kind, SPEC_NODE_KIND_CONTENT) == 0 ||
         strcmp(kind, SPEC_NODE_KIND_ENUM_VALUE) == 0 ||
         strcmp(kind, SPEC_NODE_KIND_SCALAR) == 0 ||
         strcmp(kind, SPEC_NODE_KIND_LIST_ITEM_SCALAR) == 0;
}

int spec_resolution_is_value_leaf(const SpecResolution *r) {
  return kind_is_value_leaf(r->kind);
}

/* Maps a leaf field kind to its node kind, or NULL for non-leaf kinds. */
static const char *leaf_kind(const char *field_kind) {
  if (strcmp(field_kind, SPEC_FIELD_KIND_FORM) == 0) {
    return SPEC_NODE_KIND_FORM;
  }
  if (strcmp(field_kind, SPEC_FIELD_KIND_CONTENT) == 0) {
    return SPEC_NODE_KIND_CONTENT;
  }
  if (strcmp(field_kind, SPEC_FIELD_KIND_ENUM) == 0) {
    return SPEC_NODE_KIND_ENUM_VALUE;
  }
  if (strcmp(field_kind, SPEC_FIELD_KIND_SCALAR) == 0) {
    return SPEC_NODE_KIND_SCALAR;
  }
  return NULL;
}

SpecReflection spec_reflection_make(const SpecModel *model) {
  SpecReflection r;
  r.model = model;
  return r;
}

const char *spec_reflection_root_segment(const SpecRoot *root) {
  if (root->section_id != NULL && root->section_id[0] != '\0') {
    return root->section_id;
  }
  return root->type;
}

const char *spec_reflection_field_segment(const SpecField *field) {
  if (field->section_id != NULL && field->section_id[0] != '\0') {
    return field->section_id;
  }
  return field->name;
}

const SpecRoot *spec_reflection_root_for_segment(const SpecReflection *r,
                                                 const char *segment) {
  for (size_t i = 0; i < r->model->roots_len; i++) {
    const SpecRoot *root = &r->model->roots[i];
    if (strcmp(spec_reflection_root_segment(root), segment) == 0) {
      return root;
    }
  }
  return NULL;
}

void spec_reflection_reachable_class_names(const SpecReflection *r,
                                           const char *type_name,
                                           SomStrList *out) {
  som_strlist_init(out);
  SomStrList stack;
  som_strlist_init(&stack);
  som_strlist_push_copy(&stack, type_name);
  while (stack.len > 0) {
    char *current = stack.items[stack.len - 1];
    stack.len--; /* ownership moves to `current` */
    if (som_strlist_contains(out, current)) {
      free(current);
      continue;
    }
    const SpecClass *cls = spec_model_class_named(r->model, current);
    if (cls == NULL) {
      free(current);
      continue;
    }
    som_strlist_push(out, current); /* takes ownership */
    for (size_t i = 0; i < cls->fields_len; i++) {
      const SpecField *f = &cls->fields[i];
      const char *child = NULL;
      if (strcmp(f->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
          strcmp(f->kind, SPEC_FIELD_KIND_SECTION) == 0) {
        child = f->type;
      } else if (strcmp(f->kind, SPEC_FIELD_KIND_LIST) == 0 &&
                 f->element_is_complex) {
        child = f->element_type;
      }
      if (child != NULL && child[0] != '\0') {
        som_strlist_push_copy(&stack, child);
      }
    }
  }
  som_strlist_free(&stack);
}

static const SpecField *match_field(const SpecClass *cls, const char *segment) {
  for (size_t i = 0; i < cls->fields_len; i++) {
    if (strcmp(spec_reflection_field_segment(&cls->fields[i]), segment) == 0) {
      return &cls->fields[i];
    }
  }
  return NULL;
}

static int fill(SpecResolution *out, const char *path, const char *kind,
                const SpecRoot *root, const SpecField *field,
                const SpecClass *target) {
  out->path = som_strdup(path);
  out->kind = kind;
  out->root = root;
  out->field = field;
  out->target_class = target;
  return 1;
}

int spec_reflection_resolve(const SpecReflection *r, const char *path,
                            SpecResolution *out) {
  SomStrList segs;
  spec_path_segments(path, &segs);
  int ok = 0;

  if (segs.len == 0 || segs.items[0][0] == '\0') {
    som_strlist_free(&segs);
    return 0;
  }

  const SpecRoot *root = spec_reflection_root_for_segment(r, segs.items[0]);
  if (root == NULL) {
    som_strlist_free(&segs);
    return 0;
  }
  const SpecClass *cur_class = spec_model_class_named(r->model, root->type);

  if (segs.len == 1) {
    ok = fill(out, path, SPEC_NODE_KIND_ROOT, root, NULL, cur_class);
    som_strlist_free(&segs);
    return ok;
  }

  for (size_t i = 1; i < segs.len; i++) {
    if (cur_class == NULL) {
      break; /* cannot descend into a non-class */
    }
    const SpecClass *cls = cur_class;
    const char *seg = segs.items[i];
    int last = (i == segs.len - 1);

    /* Prefer an exact field-segment match; only then try a list-item suffix,
     * so a hyphenated @SectionId is never mis-read as an item. */
    const SpecField *field = match_field(cls, seg);
    if (field != NULL) {
      if (strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
          strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0) {
        cur_class = spec_model_class_named(r->model, field->type);
        if (last) {
          const char *kind = strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0
                                 ? SPEC_NODE_KIND_SECTION
                                 : SPEC_NODE_KIND_COMPLEX;
          ok = fill(out, path, kind, root, field, cur_class);
          break;
        }
        continue; /* descend into the collapsed class */
      }
      if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0) {
        if (last) {
          ok = fill(out, path, SPEC_NODE_KIND_LIST, root, field, NULL);
        }
        break; /* a non-final list path needs a -<seq> item suffix */
      }
      /* form / content / enum / scalar leaves */
      if (last) {
        const char *kind = leaf_kind(field->kind);
        if (kind != NULL) {
          ok = fill(out, path, kind, root, field, NULL);
        }
      }
      break; /* a leaf cannot have further segments */
    }

    char *base = NULL;
    long long seq = 0;
    if (!spec_split_list_item_segment(seg, &base, &seq)) {
      break;
    }
    const SpecField *list_field = match_field(cls, base);
    free(base);
    if (list_field == NULL ||
        strcmp(list_field->kind, SPEC_FIELD_KIND_LIST) != 0) {
      break;
    }
    if (list_field->element_is_complex) {
      cur_class = spec_model_class_named(r->model, list_field->element_type);
      if (last) {
        ok = fill(out, path, SPEC_NODE_KIND_LIST_ITEM_COMPLEX, root, list_field,
                  cur_class);
        break;
      }
      continue;
    }
    /* Scalar list item: a value leaf, so it must be the final segment. */
    if (last) {
      ok = fill(out, path, SPEC_NODE_KIND_LIST_ITEM_SCALAR, root, list_field,
                NULL);
    }
    break;
  }

  som_strlist_free(&segs);
  return ok;
}
