/* spec_meta_bridge — implementation. See spec_meta_bridge.h; a faithful port
 * of the Go `spec_meta_bridge.go`. */
#include "spec_meta_bridge.h"

#include <stdlib.h>
#include <string.h>

/* Annotation names that have a dedicated SomMetaNode slot; everything else is
 * captured losslessly into SomMetaNode.extra. */
static const char *const slotted_annotations[] = {
    "SectionId",  "SectionIdPattern", "SerializationOrder",
    "Min",        "Unused",           "ContentType",
    "ContentHelp", "Headline",         "Comment",
    "Form",       "Document",         "MapsTo",
    "DetailedIn",
};

static int is_slotted(const char *name) {
  size_t count = sizeof(slotted_annotations) / sizeof(slotted_annotations[0]);
  for (size_t i = 0; i < count; i++) {
    if (strcmp(slotted_annotations[i], name) == 0) {
      return 1;
    }
  }
  return 0;
}

static const SpecAnnotation *ann_named(const SpecAnnotationList *l,
                                       const char *name) {
  for (size_t i = 0; i < l->len; i++) {
    if (strcmp(l->items[i].name, name) == 0) {
      return &l->items[i];
    }
  }
  return NULL;
}

/* Copies `src` into the meta layer's owning `char **` + length pair. */
static void copy_strlist(const SomStrList *src, char ***items, size_t *len) {
  *len = src->len;
  if (src->len == 0) {
    *items = NULL;
    return;
  }
  *items = calloc(src->len, sizeof(char *));
  for (size_t i = 0; i < src->len; i++) {
    (*items)[i] = som_strdup(src->items[i]);
  }
}

/* Replaces the owned string at `*slot` with a copy of `v` ("" for NULL). */
static void set_str(char **slot, const char *v) {
  free(*slot);
  *slot = som_strdup(v);
}

/* Coerces an annotation argument value to its string form ("" for absent /
 * non-integral floats / other types, matching the other ports). Owned. */
static char *bridge_str(const SomJson *v) {
  if (v == NULL) {
    return som_strdup("");
  }
  switch (v->type) {
  case SOM_JSON_STR:
    return som_strdup(v->as.str);
  case SOM_JSON_INT:
    return som_format_i64(v->as.integer);
  case SOM_JSON_FLOAT:
    if (v->as.real == (double)(long long)v->as.real) {
      return som_format_i64((long long)v->as.real);
    }
    return som_strdup("");
  case SOM_JSON_BOOL:
    return som_strdup(v->as.boolean ? "true" : "false");
  default:
    return som_strdup("");
  }
}

static void bridge_extras(const SpecAnnotationList *annotations,
                          SomMetaNode *node) {
  for (size_t i = 0; i < annotations->len; i++) {
    const SpecAnnotation *a = &annotations->items[i];
    if (is_slotted(a->name)) {
      continue;
    }
    node->extra = realloc(node->extra, (node->extra_len + 1) * sizeof(SomMetaExtra));
    SomMetaExtra *extra = &node->extra[node->extra_len++];
    extra->annotation = som_strdup(a->name);
    extra->args = a->arguments; /* borrowed into the model source */
  }
}

static void bridge_based_on(const SpecClass *cls, SomDocMeta *doc) {
  som_strlist_init(&doc->based_on);
  if (cls == NULL) {
    return;
  }
  const SpecAnnotation *ann = ann_named(&cls->annotations, "Document");
  if (ann == NULL) {
    return;
  }
  const SomJson *raw = spec_annotation_argument(ann, "basedOn");
  if (raw == NULL || raw->type != SOM_JSON_ARRAY) {
    return;
  }
  for (size_t i = 0; i < raw->as.array.len; i++) {
    som_strlist_push(&doc->based_on, bridge_str(raw->as.array.items[i]));
  }
}

static SomMetaNode *bridge_field_node(const SpecModel *model,
                                      const SpecClass *owner,
                                      const SpecField *field,
                                      SomStrList *stack);

/* Emits `cls`'s fields as child nodes onto `node`, ordered by
 * @SerializationOrder (annotated members first, then declaration order). */
static void bridge_child_nodes(const SpecModel *model, const SpecClass *cls,
                               SomStrList *stack, SomMetaNode *node) {
  const long long fallback = 1LL << 30;
  size_t n = cls->fields_len;
  if (n == 0) {
    return;
  }
  size_t *order = malloc(n * sizeof(size_t));
  for (size_t i = 0; i < n; i++) {
    order[i] = i;
  }
  /* Stable insertion sort on (serialization order, declaration index). */
  for (size_t i = 1; i < n; i++) {
    size_t j = i;
    while (j > 0) {
      const SpecField *a = &cls->fields[order[j - 1]];
      const SpecField *b = &cls->fields[order[j]];
      long long oa = a->has_serialization_order ? a->serialization_order : fallback;
      long long ob = b->has_serialization_order ? b->serialization_order : fallback;
      if (oa > ob) {
        size_t tmp = order[j - 1];
        order[j - 1] = order[j];
        order[j] = tmp;
        j--;
      } else {
        break;
      }
    }
  }
  for (size_t i = 0; i < n; i++) {
    som_meta_node_add_child(
        node, bridge_field_node(model, cls, &cls->fields[order[i]], stack));
  }
  free(order);
}

static SomMetaNode *bridge_field_node(const SpecModel *model,
                                      const SpecClass *owner,
                                      const SpecField *field,
                                      SomStrList *stack) {
  SomMetaNode *node = som_meta_node_new();
  /* SPEC_FIELD_KIND_* values equal the SOM_META_KIND_* values; re-canonicalise
   * to point at the static literal. */
  node->kind = spec_parse_field_kind(field->kind);

  const SpecClass *target = NULL;
  if (strcmp(field->kind, SPEC_FIELD_KIND_COMPLEX) == 0 ||
      strcmp(field->kind, SPEC_FIELD_KIND_SECTION) == 0) {
    target = spec_model_class_named(model, field->type);
    if (target != NULL) {
      if (som_strlist_contains(stack, target->name)) {
        node->recursive = 1;
      } else {
        som_strlist_push_copy(stack, target->name);
        bridge_child_nodes(model, target, stack, node);
        som_strlist_remove_at(stack, stack->len - 1);
      }
    }
  } else if (strcmp(field->kind, SPEC_FIELD_KIND_LIST) == 0 &&
             field->element_is_complex) {
    const SpecClass *element = spec_model_class_named(model, field->element_type);
    if (element != NULL) {
      SomMetaNode *element_node = som_meta_node_new();
      element_node->kind = SOM_META_KIND_COMPLEX;
      set_str(&element_node->class_name, element->name);
      set_str(&element_node->class_section_id, element->section_id);
      set_str(&element_node->type_name, element->name);
      set_str(&element_node->headline, element->headline);
      set_str(&element_node->doc_comment, element->doc);
      set_str(&element_node->class_doc_comment, element->doc);
      set_str(&element_node->maps_to, element->maps_to);
      set_str(&element_node->detailed_in, element->detailed_in);
      if (som_strlist_contains(stack, element->name)) {
        element_node->recursive = 1;
      } else {
        som_strlist_push_copy(stack, element->name);
        bridge_child_nodes(model, element, stack, element_node);
        som_strlist_remove_at(stack, stack->len - 1);
      }
      node->element_node = element_node;
    }
  }

  if (field->content_type != NULL && field->content_type[0] != '\0') {
    node->content_type = calloc(1, sizeof(SomContentTypeMeta));
    node->content_type->type = som_strdup(field->content_type);
    const SpecAnnotation *ct_ann = ann_named(&field->annotations, "ContentType");
    node->content_type->description =
        ct_ann != NULL ? bridge_str(spec_annotation_argument(ct_ann, "description"))
                       : som_strdup("");
  }

  const SpecAnnotation *comment_ann = ann_named(&field->annotations, "Comment");
  if (comment_ann != NULL) {
    free(node->comment);
    node->comment = bridge_str(spec_annotation_argument(comment_ann, "text"));
  }

  if (strcmp(field->kind, SPEC_FIELD_KIND_FORM) == 0) {
    node->form = calloc(1, sizeof(SomFormMeta));
    node->form->fields_len = field->form_fields_len;
    if (field->form_fields_len > 0) {
      node->form->fields =
          calloc(field->form_fields_len, sizeof(SomFormFieldMeta));
      for (size_t i = 0; i < field->form_fields_len; i++) {
        const FormFieldSpec *ff = &field->form_fields[i];
        SomFormFieldMeta *out = &node->form->fields[i];
        out->name = som_strdup(ff->name);
        out->type_name = som_strdup(ff->type);
        out->description = som_strdup(ff->label);
        out->required = ff->required;
        out->hint = som_strdup(ff->hint);
        out->order = (long long)i;
        copy_strlist(&ff->enum_values, &out->enum_values,
                     &out->enum_values_len);
        copy_strlist(&ff->refers_to, &out->refers_to, &out->refers_to_len);
      }
    }
  }

  set_str(&node->class_name, owner->name);
  set_str(&node->doc_comment, field->doc);
  if (target != NULL) {
    set_str(&node->class_name, target->name);
    set_str(&node->class_section_id, target->section_id);
    if (node->doc_comment[0] == '\0') {
      set_str(&node->doc_comment, target->doc);
    }
    set_str(&node->class_doc_comment, target->doc);
    set_str(&node->maps_to, target->maps_to);
    set_str(&node->detailed_in, target->detailed_in);
  }
  const char *type_name = field->type;
  if (type_name == NULL || type_name[0] == '\0') {
    type_name = field->element_type;
  }
  if (type_name == NULL || type_name[0] == '\0') {
    type_name = field->enum_type;
  }
  if (type_name == NULL || type_name[0] == '\0') {
    type_name = "String";
  }
  set_str(&node->type_name, type_name);

  set_str(&node->member_name, field->name);
  set_str(&node->section_id, field->section_id);
  set_str(&node->section_id_pattern, field->section_id_pattern);
  node->has_serialization_order = field->has_serialization_order;
  node->serialization_order = field->serialization_order;
  node->has_min = field->has_min;
  node->min = field->min;
  node->unused = ann_named(&field->annotations, "Unused") != NULL;
  set_str(&node->content_help, field->help);
  /* Field-level @Headline wins over the target class's (YRD4). */
  set_str(&node->headline, field->headline[0] != '\0'
                               ? field->headline
                               : (target != NULL ? target->headline : ""));
  bridge_extras(&field->annotations, node);
  return node;
}

SomMetaTree *som_build_meta_tree(const SpecModel *model, const char *root_type,
                                 char **err) {
  const SpecRoot *root = NULL;
  if (root_type == NULL || root_type[0] == '\0') {
    if (model->roots_len > 0) {
      root = &model->roots[0];
    } else {
      root = spec_model_root_by_type(model, "", err);
      if (root == NULL) {
        return NULL;
      }
    }
  } else {
    root = spec_model_root_by_type(model, root_type, err);
    if (root == NULL) {
      return NULL;
    }
  }
  const SpecClass *cls = spec_model_class_named(model, root->type);

  SomMetaNode *node = som_meta_node_new();
  node->kind = SOM_META_KIND_SECTION;
  set_str(&node->class_name, root->type);
  set_str(&node->type_name, root->type);
  if (cls != NULL) {
    set_str(&node->headline, cls->headline);
  }
  set_str(&node->section_id, root->section_id);
  set_str(&node->doc_comment, root->doc);
  node->document = calloc(1, sizeof(SomDocMeta));
  node->document->name = som_strdup(root->title);
  node->document->description = som_strdup(root->description);
  bridge_based_on(cls, node->document);
  if (cls != NULL) {
    if (node->section_id[0] == '\0') {
      set_str(&node->section_id, cls->section_id);
    }
    set_str(&node->class_section_id, cls->section_id);
    if (node->doc_comment[0] == '\0') {
      set_str(&node->doc_comment, cls->doc);
    }
    set_str(&node->class_doc_comment, cls->doc);
    set_str(&node->maps_to, cls->maps_to);
    set_str(&node->detailed_in, cls->detailed_in);
    bridge_extras(&cls->annotations, node);
    SomStrList stack;
    som_strlist_init(&stack);
    som_strlist_push_copy(&stack, root->type);
    bridge_child_nodes(model, cls, &stack, node);
    som_strlist_free(&stack);
  }
  SomMetaTree *tree = som_meta_tree_new(node, err);
  if (tree == NULL) {
    som_meta_node_free(node);
    return NULL;
  }
  return tree;
}
