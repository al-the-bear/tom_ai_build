#include "spec_validator.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "spec_reflection.h"
#include "spec_section_id.h"

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

/* ---- shared small helpers ------------------------------------------------ */

static int cmp_str(const void *a, const void *b) {
  return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static void strlist_sort(SomStrList *l) {
  if (l->len > 1) {
    qsort(l->items, l->len, sizeof(char *), cmp_str);
  }
}

/* Pushes `s` unless already present (set semantics over an ordered list). */
static void set_add(SomStrList *l, const char *s) {
  if (!som_strlist_contains(l, s)) {
    som_strlist_push_copy(l, s);
  }
}

/* Returns a fresh owned copy of `s` with leading/trailing whitespace removed. */
static char *trim_dup(const char *s) {
  while (*s != '\0' && isspace((unsigned char)*s)) {
    s++;
  }
  size_t n = strlen(s);
  while (n > 0 && isspace((unsigned char)s[n - 1])) {
    n--;
  }
  return som_strdup_n(s, n);
}

static const SpecAnnotation *annotation_named(const SpecAnnotationList *anns,
                                              const char *name) {
  for (size_t i = 0; i < anns->len; i++) {
    if (strcmp(anns->items[i].name, name) == 0) {
      return &anns->items[i];
    }
  }
  return NULL;
}

/* The constant part of a qualified `EnumType.constant` `@Case` token (or the
 * whole string when it is not qualified). */
static const char *case_constant(const char *token) {
  const char *dot = strchr(token, '.');
  return dot != NULL ? dot + 1 : token;
}

/* ---- registry map (key → set of declared values) ------------------------- */

typedef struct {
  char *key;
  SomStrList values;
} RegEntry;

typedef struct {
  RegEntry *items;
  size_t len;
  size_t cap;
} RegMap;

static void reg_map_init(RegMap *m) {
  m->items = NULL;
  m->len = 0;
  m->cap = 0;
}

static void reg_map_add(RegMap *m, const char *key, const char *value) {
  for (size_t i = 0; i < m->len; i++) {
    if (strcmp(m->items[i].key, key) == 0) {
      set_add(&m->items[i].values, value);
      return;
    }
  }
  if (m->len == m->cap) {
    m->cap = m->cap ? m->cap * 2 : 8;
    m->items = (RegEntry *)realloc(m->items, m->cap * sizeof(RegEntry));
  }
  m->items[m->len].key = som_strdup(key);
  som_strlist_init(&m->items[m->len].values);
  som_strlist_push_copy(&m->items[m->len].values, value);
  m->len++;
}

static int reg_map_has(const RegMap *m, const char *key, const char *value) {
  for (size_t i = 0; i < m->len; i++) {
    if (strcmp(m->items[i].key, key) == 0) {
      return som_strlist_contains(&m->items[i].values, value);
    }
  }
  return 0;
}

static void reg_map_free(RegMap *m) {
  for (size_t i = 0; i < m->len; i++) {
    free(m->items[i].key);
    som_strlist_free(&m->items[i].values);
  }
  free(m->items);
  reg_map_init(m);
}

/* ---- phase 4: @OneOf/@Case instances (csmb6) ----------------------------- */

/* Adds `full` and every ancestor prefix of it to the section-path set. A
   container's own discriminator form lives at `<container>/<form>`, so the
   container path is always a prefix of a populated path. */
static void add_prefixes(SomStrList *set, const char *full) {
  SomBuf b;
  som_buf_init(&b);
  for (const char *p = full;; p++) {
    if (*p == '/' || *p == '\0') {
      char *prefix = som_strdup_n(b.data != NULL ? b.data : "", b.len);
      set_add(set, prefix);
      free(prefix);
      if (*p == '\0') {
        break;
      }
    }
    som_buf_putc(&b, *p);
  }
  som_buf_free(&b);
}

/* Every section-instance path present in `doc`: each stored value path plus all
   of its ancestor prefixes, sorted. */
static void document_section_paths(const SpecDocument *doc, SomStrList *out) {
  som_strlist_init(out);
  SomStrList groups[4];
  spec_document_content_paths(doc, &groups[0]);
  spec_document_form_paths(doc, &groups[1]);
  spec_document_list_paths(doc, &groups[2]);
  spec_document_headline_paths(doc, &groups[3]);
  for (size_t g = 0; g < 4; g++) {
    for (size_t i = 0; i < groups[g].len; i++) {
      add_prefixes(out, groups[g].items[i]);
    }
    som_strlist_free(&groups[g]);
  }
  strlist_sort(out);
}

/* Instance-tier `@OneOf`/`@Case` check (csmb6): for every `@OneOf` container
   instance present in `doc`, verify the populated case subsections match the
   chosen discriminator value. */
static void validate_one_of_instances(const SpecReflection *refl,
                                      const SpecDocument *doc,
                                      SpecValidationErrors *out) {
  SomStrList section_paths;
  document_section_paths(doc, &section_paths);

  for (size_t pi = 0; pi < section_paths.len; pi++) {
    const char *path = section_paths.items[pi];
    SpecResolution res;
    if (!spec_reflection_resolve(refl, path, &res)) {
      continue;
    }
    const SpecClass *cls = res.target_class;
    spec_resolution_free(&res);
    if (cls == NULL) {
      continue;
    }
    const SpecAnnotation *one_of = annotation_named(&cls->annotations, "OneOf");
    if (one_of == NULL) {
      continue;
    }
    const char *discriminator =
        som_json_as_str(spec_annotation_argument(one_of, "discriminator"));
    if (discriminator == NULL || discriminator[0] == '\0') {
      continue;
    }

    /* Read the chosen discriminator value from the container's own @Form. */
    const SpecField *form_holder = NULL;
    for (size_t i = 0; i < cls->fields_len && form_holder == NULL; i++) {
      const SpecField *f = &cls->fields[i];
      if (strcmp(f->kind, SPEC_FIELD_KIND_FORM) != 0) {
        continue;
      }
      for (size_t j = 0; j < f->form_fields_len; j++) {
        if (strcmp(f->form_fields[j].name, discriminator) == 0) {
          form_holder = f;
          break;
        }
      }
    }
    if (form_holder == NULL) {
      continue; /* static tier flagged the mismatch */
    }
    SomBuf fb;
    som_buf_init(&fb);
    som_buf_puts(&fb, path);
    som_buf_puts(&fb, "/");
    som_buf_puts(&fb, spec_reflection_field_segment(form_holder));
    char *form_path = som_buf_take(&fb);
    const char *chosen =
        spec_document_form_field(doc, form_path, discriminator);
    free(form_path);
    if (chosen == NULL || chosen[0] == '\0') {
      continue; /* no case chosen yet */
    }

    /* Inspect each case-bound subsection: present + not-selected → mismatch. */
    SomStrList present_for_chosen;
    som_strlist_init(&present_for_chosen);
    for (size_t i = 0; i < cls->fields_len; i++) {
      const SpecField *f = &cls->fields[i];
      SomStrList cases;
      som_strlist_init(&cases);
      for (size_t a = 0; a < f->annotations.len; a++) {
        const SpecAnnotation *ann = &f->annotations.items[a];
        if (strcmp(ann->name, "Case") != 0) {
          continue;
        }
        const char *value =
            som_json_as_str(spec_annotation_argument(ann, "value"));
        if (value != NULL) {
          set_add(&cases, case_constant(value));
        }
      }
      if (cases.len == 0) {
        som_strlist_free(&cases);
        continue; /* common subsection — always allowed */
      }
      som_buf_init(&fb);
      som_buf_puts(&fb, path);
      som_buf_puts(&fb, "/");
      som_buf_puts(&fb, spec_reflection_field_segment(f));
      char *child_path = som_buf_take(&fb);
      if (!spec_document_has_values_under(doc, child_path)) {
        free(child_path);
        som_strlist_free(&cases);
        continue;
      }
      if (som_strlist_contains(&cases, chosen)) {
        som_strlist_push_copy(&present_for_chosen, f->name);
      } else {
        strlist_sort(&cases);
        char *joined = som_strlist_join(&cases, ", ");
        SomBuf mb;
        som_buf_init(&mb);
        som_buf_puts(&mb, "subsection \"");
        som_buf_puts(&mb, f->name);
        som_buf_puts(&mb, "\" is present but the chosen ");
        som_buf_puts(&mb, discriminator);
        som_buf_puts(&mb, "=\"");
        som_buf_puts(&mb, chosen);
        som_buf_puts(&mb, "\" does not select it (cases: ");
        som_buf_puts(&mb, joined);
        som_buf_puts(&mb, ")");
        free(joined);
        errors_push(out, child_path, SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH,
                    som_buf_take(&mb));
      }
      free(child_path);
      som_strlist_free(&cases);
    }
    if (present_for_chosen.len > 1) {
      strlist_sort(&present_for_chosen);
      char *joined = som_strlist_join(&present_for_chosen, ", ");
      SomBuf mb;
      som_buf_init(&mb);
      som_buf_puts(&mb, "chosen ");
      som_buf_puts(&mb, discriminator);
      som_buf_puts(&mb, "=\"");
      som_buf_puts(&mb, chosen);
      som_buf_puts(&mb, "\" selects more than one populated subsection (");
      som_buf_puts(&mb, joined);
      som_buf_puts(&mb, ") — at most one case subsection may be present");
      free(joined);
      errors_push(out, path, SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH,
                  som_buf_take(&mb));
    }
    som_strlist_free(&present_for_chosen);
  }
  som_strlist_free(&section_paths);
}

/* ---- phase 5: refersTo instances (csrb3) --------------------------------- */

/* A resolved form section: its path, the class it sits on (which carries the
   `@SectionId` a registry key is written against) and the form field itself. */
typedef struct {
  char *path;
  const SpecClass *cls;
  const SpecField *field;
} FormInstance;

/* The section id part of a registry key written `<SECTIONID>.<slot>`. A key with
   no dot is malformed — the static tier reports it — and is treated whole here
   so it simply fails to match any section id. Owned result. */
static char *registry_section_id(const char *target) {
  const char *dot = strchr(target, '.');
  if (dot == NULL || dot == target) {
    return som_strdup(target);
  }
  return som_strdup_n(target, (size_t)(dot - target));
}

/* The registry section ids that are **in scope** for `doc` (csre2): the
   `@SectionId` of every class reachable from a document root the document
   actually uses. Anything outside this set is absent from the document by
   construction — precisely the case the dangling-reference check must not call
   an error. A document spanning several roots contributes the union. */
static void registry_scope(const SpecReflection *refl, const SpecDocument *doc,
                           SomStrList *out) {
  som_strlist_init(out);
  SomStrList root_types;
  som_strlist_init(&root_types);

  SomStrList groups[4];
  spec_document_content_paths(doc, &groups[0]);
  spec_document_form_paths(doc, &groups[1]);
  spec_document_list_paths(doc, &groups[2]);
  spec_document_headline_paths(doc, &groups[3]);
  for (size_t g = 0; g < 4; g++) {
    for (size_t i = 0; i < groups[g].len; i++) {
      const char *path = groups[g].items[i];
      const char *slash = strchr(path, '/');
      char *segment = slash == NULL ? som_strdup(path)
                                    : som_strdup_n(path, (size_t)(slash - path));
      const SpecRoot *root = spec_reflection_root_for_segment(refl, segment);
      free(segment);
      if (root != NULL) {
        set_add(&root_types, root->type);
      }
    }
    som_strlist_free(&groups[g]);
  }

  for (size_t i = 0; i < root_types.len; i++) {
    SomStrList names;
    spec_reflection_reachable_class_names(refl, root_types.items[i], &names);
    for (size_t j = 0; j < names.len; j++) {
      const SpecClass *cls = spec_model_class_named(refl->model, names.items[j]);
      if (cls != NULL && cls->section_id != NULL && cls->section_id[0] != '\0') {
        set_add(out, cls->section_id);
      }
    }
    som_strlist_free(&names);
  }
  som_strlist_free(&root_types);
}

/* Instance-tier cross-registry reference check (csrb3): every id written into a
   `refersTo` form field must be declared by some entry of one of its target
   registries *in this document*. Two sweeps over the document's form sections
   (declare, then resolve), so it costs one extra walk rather than a resolve per
   reference. An empty value is not a dangling reference — it means "not filled
   in yet", the schema-completeness concern this validator leaves to its
   caller. */
static void validate_reference_instances(const SpecReflection *refl,
                                         const SpecDocument *doc,
                                         SpecValidationErrors *out) {
  SomStrList scope;
  registry_scope(refl, doc, &scope);

  /* Resolve every form path once; both sweeps read the same resolutions. A form
     resolution names the form *field*, not a class — the section id a registry
     key is written against belongs to the class the form sits on, so the owner
     is resolved from the parent path. */
  SomStrList form_paths;
  spec_document_form_paths(doc, &form_paths);
  strlist_sort(&form_paths);
  FormInstance *forms =
      (FormInstance *)calloc(form_paths.len ? form_paths.len : 1,
                             sizeof(FormInstance));
  size_t forms_len = 0;
  for (size_t i = 0; i < form_paths.len; i++) {
    const char *path = form_paths.items[i];
    SpecResolution res;
    if (!spec_reflection_resolve(refl, path, &res)) {
      continue;
    }
    int usable = res.field != NULL && strcmp(res.kind, SPEC_NODE_KIND_FORM) == 0;
    const SpecField *field = res.field;
    spec_resolution_free(&res);
    if (!usable) {
      continue;
    }
    const char *slash = strrchr(path, '/');
    if (slash == NULL || slash == path) {
      continue;
    }
    char *parent = som_strdup_n(path, (size_t)(slash - path));
    SpecResolution pres;
    const SpecClass *cls = NULL;
    if (spec_reflection_resolve(refl, parent, &pres)) {
      cls = pres.target_class;
      spec_resolution_free(&pres);
    }
    free(parent);
    if (cls == NULL) {
      continue;
    }
    forms[forms_len].path = som_strdup(path);
    forms[forms_len].cls = cls;
    forms[forms_len].field = field;
    forms_len++;
  }
  som_strlist_free(&form_paths);

  RegMap declared;
  reg_map_init(&declared);

  /* 1. Declare: every form instance contributes `<SECTIONID>.<formField>`. */
  for (size_t i = 0; i < forms_len; i++) {
    const char *section_id = forms[i].cls->section_id;
    if (section_id == NULL || section_id[0] == '\0') {
      continue;
    }
    for (size_t j = 0; j < forms[i].field->form_fields_len; j++) {
      const FormFieldSpec *ff = &forms[i].field->form_fields[j];
      const char *raw = spec_document_form_field(doc, forms[i].path, ff->name);
      if (raw == NULL) {
        continue;
      }
      char *value = trim_dup(raw);
      if (value[0] != '\0') {
        SomBuf kb;
        som_buf_init(&kb);
        som_buf_puts(&kb, section_id);
        som_buf_puts(&kb, ".");
        som_buf_puts(&kb, ff->name);
        char *key = som_buf_take(&kb);
        reg_map_add(&declared, key, value);
        free(key);
      }
      free(value);
    }
  }

  /* 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
     The key is the *element class's* section id, not the `-LST` container's: a
     target names the entry, so `FRE.@sectionId` reads as "an id of some
     functional-requirement entry". That half is what makes a registry keeping
     its id nowhere but the section id referenceable at all. */
  SomStrList list_paths;
  spec_document_list_paths(doc, &list_paths);
  strlist_sort(&list_paths);
  for (size_t i = 0; i < list_paths.len; i++) {
    const char *list_path = list_paths.items[i];
    const char *pattern = "";
    const char *stem = NULL;
    SpecResolution lres;
    if (spec_reflection_resolve(refl, list_path, &lres)) {
      if (lres.field != NULL) {
        pattern = lres.field->section_id_pattern;
        stem = lres.field->name;
      }
      spec_resolution_free(&lres);
    }
    if (stem == NULL) {
      const char *slash = strrchr(list_path, '/');
      stem = slash != NULL ? slash + 1 : list_path;
    }
    const SomStrList *items = spec_document_list_items(doc, list_path);
    if (items == NULL) {
      continue;
    }
    for (size_t j = 0; j < items->len; j++) {
      const char *item_path = items->items[j];
      const SpecClass *element_class = NULL;
      SpecResolution ires;
      if (spec_reflection_resolve(refl, item_path, &ires)) {
        element_class = ires.target_class;
        spec_resolution_free(&ires);
      }
      if (element_class == NULL || element_class->section_id == NULL ||
          element_class->section_id[0] == '\0') {
        continue;
      }
      char *item_id = spec_effective_list_item_section_id(
          spec_document_item_section_id(doc, item_path), pattern,
          (long long)j + 1, stem);
      SomBuf kb;
      som_buf_init(&kb);
      som_buf_puts(&kb, element_class->section_id);
      som_buf_puts(&kb, "." SPEC_SECTION_ID_SLOT);
      char *key = som_buf_take(&kb);
      reg_map_add(&declared, key, item_id);
      free(key);
      free(item_id);
    }
  }
  som_strlist_free(&list_paths);

  /* 2. Resolve. */
  for (size_t i = 0; i < forms_len; i++) {
    for (size_t j = 0; j < forms[i].field->form_fields_len; j++) {
      const FormFieldSpec *ff = &forms[i].field->form_fields[j];
      if (ff->refers_to.len == 0) {
        continue;
      }
      const char *raw = spec_document_form_field(doc, forms[i].path, ff->name);
      if (raw == NULL) {
        continue;
      }
      char *value = trim_dup(raw);
      if (value[0] == '\0') {
        free(value);
        continue;
      }

      /* Every target must be in scope, not merely one of them: a disjunction
         says the id may come from any of the listed registries, so one absent
         registry is enough to make "no registry declares it" unsound — the id
         could legitimately be declared by the one this document cannot see. */
      int all_in_scope = 1;
      for (size_t t = 0; t < ff->refers_to.len; t++) {
        char *rid = registry_section_id(ff->refers_to.items[t]);
        int in_scope = som_strlist_contains(&scope, rid);
        free(rid);
        if (!in_scope) {
          all_in_scope = 0;
          break;
        }
      }
      if (!all_in_scope) {
        free(value);
        continue;
      }

      /* A value naming several ids writes them comma-separated, so each segment
         resolves independently. A value is valid when it resolves in **any**
         listed registry. */
      const char *seg = value;
      while (1) {
        const char *comma = strchr(seg, ',');
        char *piece = comma == NULL ? som_strdup(seg)
                                    : som_strdup_n(seg, (size_t)(comma - seg));
        char *id = trim_dup(piece);
        free(piece);
        if (id[0] != '\0') {
          int resolves = 0;
          for (size_t t = 0; t < ff->refers_to.len && !resolves; t++) {
            resolves = reg_map_has(&declared, ff->refers_to.items[t], id);
          }
          if (!resolves) {
            char *targets = som_strlist_join(&ff->refers_to, ", ");
            SomBuf mb;
            som_buf_init(&mb);
            som_buf_puts(&mb, "form field \"");
            som_buf_puts(&mb, ff->name);
            som_buf_puts(&mb, "\" references \"");
            som_buf_puts(&mb, id);
            som_buf_puts(&mb, "\", which no entry of ");
            som_buf_puts(&mb,
                         ff->refers_to.len == 1 ? "registry " : "registries ");
            som_buf_puts(&mb, targets);
            som_buf_puts(&mb, " declares");
            free(targets);
            errors_push(out, forms[i].path,
                        SPEC_VALIDATION_CODE_DANGLING_REFERENCE,
                        som_buf_take(&mb));
          }
        }
        free(id);
        if (comma == NULL) {
          break;
        }
        seg = comma + 1;
      }
      free(value);
    }
  }

  for (size_t i = 0; i < forms_len; i++) {
    free(forms[i].path);
  }
  free(forms);
  reg_map_free(&declared);
  som_strlist_free(&scope);
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

  /* 4. @OneOf/@Case instances: a populated subsection the chosen discriminator
     does not select. Only here can we see which case a document actually
     wrote — the static tier can only check the annotations are well formed. */
  validate_one_of_instances(&refl, doc, out);

  /* 5. `refersTo` references: an id no entry of its target registries declares
     in this document. The static tier has checked the targets are resolvable;
     only here can we see whether the id a document wrote is one it declares. */
  validate_reference_instances(&refl, doc, out);
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
