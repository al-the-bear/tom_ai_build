#include "spec_validator.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_reflection.h"
#include "spec_section_id.h"
#include "spec_typed_values.h"

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

/* Every form instance in `doc` with its field and the class it sits on, in path
   order — the shape both the reference and the count check sweep. A form
   resolution names the form *field*, not a class — the section id a registry key
   is written against belongs to the class the form sits on, so the owner is
   resolved from the parent path. `*out` is owned; release with
   `form_instances_free`. */
static void resolved_forms(const SpecReflection *refl, const SpecDocument *doc,
                           FormInstance **out, size_t *out_len) {
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
  *out = forms;
  *out_len = forms_len;
}

static void form_instances_free(FormInstance *forms, size_t len) {
  for (size_t i = 0; i < len; i++) {
    free(forms[i].path);
  }
  free(forms);
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

  /* Resolve every form path once; both sweeps read the same resolutions. */
  FormInstance *forms = NULL;
  size_t forms_len = 0;
  resolved_forms(refl, doc, &forms, &forms_len);

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

      /* One id, unless the field says it holds several. Decidable without the
         registries, so it is checked before the scope test below. */
      if (!ff->multiple) {
        SomStrList ids;
        som_strlist_init(&ids);
        const char *mseg = value;
        while (1) {
          const char *comma = strchr(mseg, ',');
          char *piece = comma == NULL
                            ? som_strdup(mseg)
                            : som_strdup_n(mseg, (size_t)(comma - mseg));
          char *id = trim_dup(piece);
          free(piece);
          if (id[0] != '\0') {
            som_strlist_push(&ids, id);
          } else {
            free(id);
          }
          if (comma == NULL) {
            break;
          }
          mseg = comma + 1;
        }
        if (ids.len > 1) {
          char *joined = som_strlist_join(&ids, ", ");
          char num[32];
          snprintf(num, sizeof num, "%zu", ids.len);
          SomBuf mb;
          som_buf_init(&mb);
          som_buf_puts(&mb, "form field \"");
          som_buf_puts(&mb, ff->name);
          som_buf_puts(&mb, "\" holds ");
          som_buf_puts(&mb, num);
          som_buf_puts(&mb, " references (");
          som_buf_puts(&mb, joined);
          som_buf_puts(&mb, ") but takes one");
          free(joined);
          errors_push(out, forms[i].path,
                      SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES,
                      som_buf_take(&mb));
        }
        som_strlist_free(&ids);
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

  form_instances_free(forms, forms_len);
  reg_map_free(&declared);
  som_strlist_free(&scope);
}

/* ---- phase 6: stated counts (vsctsa43) ----------------------------------- */

/* An entry: a list item whose element class carries a `@SectionId`. Both
   pointers borrow (the id from the model, the item path from the document). */
typedef struct {
  const char *section_id;
  const char *item_path;
} CountEntry;

/* The section id of a `countOf` target — the part before any `.field=value`,
   without the `./` scope prefix. Owned result. */
static char *count_target_id(const char *target) {
  if (strncmp(target, "./", 2) == 0) {
    target += 2;
  }
  const char *dot = strchr(target, '.');
  return dot == NULL ? som_strdup(target)
                     : som_strdup_n(target, (size_t)(dot - target));
}

/* Whether some form member of `item_path` — a form at `<item>/<member>` —
   declares form field `field` and holds trimmed `value` in it. */
static int item_holds(const SpecReflection *refl, const SpecDocument *doc,
                      const SomStrList *form_paths, const char *item_path,
                      const char *field, const char *value) {
  size_t item_len = strlen(item_path);
  for (size_t i = 0; i < form_paths->len; i++) {
    const char *path = form_paths->items[i];
    const char *slash = strrchr(path, '/');
    if (slash == NULL || slash == path || (size_t)(slash - path) != item_len ||
        strncmp(path, item_path, item_len) != 0) {
      continue;
    }
    SpecResolution res;
    if (!spec_reflection_resolve(refl, path, &res)) {
      continue;
    }
    const SpecField *spec = res.field;
    spec_resolution_free(&res);
    if (spec == NULL) {
      continue;
    }
    for (size_t k = 0; k < spec->form_fields_len; k++) {
      if (strcmp(spec->form_fields[k].name, field) != 0) {
        continue;
      }
      const char *raw = spec_document_form_field(doc, path, field);
      if (raw == NULL) {
        continue;
      }
      char *v = trim_dup(raw);
      int match = v[0] != '\0' && strcmp(v, value) == 0;
      free(v);
      if (match) {
        return 1;
      }
    }
  }
  return 0;
}

/* Whether `item_path` lies beneath `owner` (`<owner>/...`). */
static int item_in_scope(const char *item_path, const char *owner) {
  size_t n = strlen(owner);
  return strncmp(item_path, owner, n) == 0 && item_path[n] == '/';
}

/* How many entries `target` counts: every entry of section id `X` for target
   `X`, only those holding `v` in form field `f` for `X.f=v`. A target written
   `./...` counts only the entries beneath `owner`, the section holding the
   form; any other target counts the whole document. */
static long long count_target(const SpecReflection *refl,
                              const SpecDocument *doc,
                              const SomStrList *form_paths,
                              const CountEntry *entries, size_t entries_len,
                              const char *target, const char *owner) {
  int scoped = strncmp(target, "./", 2) == 0;
  if (scoped) {
    target += 2;
  }
  const char *dot = strchr(target, '.');
  long long n = 0;
  if (dot == NULL) {
    for (size_t i = 0; i < entries_len; i++) {
      if (strcmp(entries[i].section_id, target) == 0 &&
          (!scoped || item_in_scope(entries[i].item_path, owner))) {
        n++;
      }
    }
    return n;
  }
  char *id = som_strdup_n(target, (size_t)(dot - target));
  const char *eq = strchr(dot, '=');
  char *field = eq == NULL ? som_strdup(dot + 1)
                           : som_strdup_n(dot + 1, (size_t)(eq - dot - 1));
  const char *value = eq == NULL ? "" : eq + 1;
  /* An empty value never matches: empty form values are not recorded. */
  if (value[0] != '\0') {
    for (size_t i = 0; i < entries_len; i++) {
      if (strcmp(entries[i].section_id, id) == 0 &&
          (!scoped || item_in_scope(entries[i].item_path, owner)) &&
          item_holds(refl, doc, form_paths, entries[i].item_path, field,
                     value)) {
        n++;
      }
    }
  }
  free(id);
  free(field);
  return n;
}

/* Whether `s` is a non-empty run of ASCII digits (`^[0-9]+$`). */
static int all_digits(const char *s) {
  if (s[0] == '\0') {
    return 0;
  }
  for (; *s != '\0'; s++) {
    if (*s < '0' || *s > '9') {
      return 0;
    }
  }
  return 1;
}

/* Whether the digit string `digits` names the number `n`. Compared as decimal
   text (leading zeros stripped), so a stated value too large for any integer
   type is simply unequal rather than overflowing. */
static int digits_equal(const char *digits, long long n) {
  while (digits[0] == '0' && digits[1] != '\0') {
    digits++;
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puti(&b, n);
  char *text = som_buf_take(&b);
  int eq = strcmp(digits, text) == 0;
  free(text);
  return eq;
}

/* Instance-tier stated-count check (vsctsa43): every non-empty value of a
   `countOf` form field must be a whole number equal to the number of entries
   the document holds.

   An **entry** is a list item whose element class carries `@SectionId(X)`. A
   target `X` counts every such entry; `X.f=v` counts only the entries one of
   whose own forms — a form member of the entry, at `<item>/<member>` — holds
   `v` in form field `f`. The count is the sum over the targets. As with the
   reference check, a target whose section id the document's root cannot reach
   makes the field undecidable here, so it is skipped rather than reported, and
   an empty value is completeness, not a count. */
static void validate_count_instances(const SpecReflection *refl,
                                     const SpecDocument *doc,
                                     SpecValidationErrors *out) {
  FormInstance *forms = NULL;
  size_t forms_len = 0;
  resolved_forms(refl, doc, &forms, &forms_len);
  int any = 0;
  for (size_t i = 0; i < forms_len && !any; i++) {
    for (size_t j = 0; j < forms[i].field->form_fields_len && !any; j++) {
      any = forms[i].field->form_fields[j].count_of.len > 0;
    }
  }
  if (!any) {
    form_instances_free(forms, forms_len);
    return;
  }
  SomStrList scope;
  registry_scope(refl, doc, &scope);

  /* Every entry, by its class's section id. */
  CountEntry *entries = NULL;
  size_t entries_len = 0;
  size_t entries_cap = 0;
  SomStrList list_paths;
  spec_document_list_paths(doc, &list_paths);
  strlist_sort(&list_paths);
  for (size_t i = 0; i < list_paths.len; i++) {
    const SomStrList *items = spec_document_list_items(doc, list_paths.items[i]);
    if (items == NULL) {
      continue;
    }
    for (size_t j = 0; j < items->len; j++) {
      const SpecClass *cls = NULL;
      SpecResolution ires;
      if (spec_reflection_resolve(refl, items->items[j], &ires)) {
        cls = ires.target_class;
        spec_resolution_free(&ires);
      }
      if (cls == NULL || cls->section_id == NULL || cls->section_id[0] == '\0') {
        continue;
      }
      if (entries_len == entries_cap) {
        entries_cap = entries_cap ? entries_cap * 2 : 8;
        entries = (CountEntry *)realloc(entries,
                                        entries_cap * sizeof(CountEntry));
      }
      entries[entries_len].section_id = cls->section_id;
      entries[entries_len].item_path = items->items[j];
      entries_len++;
    }
  }

  SomStrList form_paths;
  spec_document_form_paths(doc, &form_paths);

  for (size_t i = 0; i < forms_len; i++) {
    for (size_t j = 0; j < forms[i].field->form_fields_len; j++) {
      const FormFieldSpec *ff = &forms[i].field->form_fields[j];
      if (ff->count_of.len == 0) {
        continue;
      }
      const char *raw = spec_document_form_field(doc, forms[i].path, ff->name);
      if (raw == NULL) {
        continue;
      }
      char *stated = trim_dup(raw);
      if (stated[0] == '\0') {
        free(stated);
        continue;
      }
      int all_in_scope = 1;
      for (size_t t = 0; t < ff->count_of.len && all_in_scope; t++) {
        char *tid = count_target_id(ff->count_of.items[t]);
        char *rid = registry_section_id(tid);
        all_in_scope = som_strlist_contains(&scope, rid);
        free(rid);
        free(tid);
      }
      if (!all_in_scope) {
        free(stated);
        continue;
      }
      const char *last_slash = strrchr(forms[i].path, '/');
      char *owner = last_slash == NULL
                        ? som_strdup("")
                        : som_strdup_n(forms[i].path,
                                       (size_t)(last_slash - forms[i].path));
      long long counted = 0;
      for (size_t t = 0; t < ff->count_of.len; t++) {
        counted += count_target(refl, doc, &form_paths, entries, entries_len,
                                ff->count_of.items[t], owner);
      }
      free(owner);
      if (!all_digits(stated)) {
        char *targets = som_strlist_join(&ff->count_of, " + ");
        SomBuf mb;
        som_buf_init(&mb);
        som_buf_puts(&mb, "form field \"");
        som_buf_puts(&mb, ff->name);
        som_buf_puts(&mb, "\" states \"");
        som_buf_puts(&mb, stated);
        som_buf_puts(&mb, "\", which is not a whole number \xE2\x80\x94 it counts ");
        som_buf_puts(&mb, targets);
        som_buf_puts(&mb, ", of which the document holds ");
        som_buf_puti(&mb, counted);
        free(targets);
        errors_push(out, forms[i].path, SPEC_VALIDATION_CODE_COUNT_MISMATCH,
                    som_buf_take(&mb));
      } else if (!digits_equal(stated, counted)) {
        char *targets = som_strlist_join(&ff->count_of, " + ");
        SomBuf mb;
        som_buf_init(&mb);
        som_buf_puts(&mb, "form field \"");
        som_buf_puts(&mb, ff->name);
        som_buf_puts(&mb, "\" states ");
        som_buf_puts(&mb, stated);
        som_buf_puts(&mb, ", but the document holds ");
        som_buf_puti(&mb, counted);
        som_buf_puts(&mb, " (counting ");
        som_buf_puts(&mb, targets);
        som_buf_puts(&mb, ")");
        free(targets);
        errors_push(out, forms[i].path, SPEC_VALIDATION_CODE_COUNT_MISMATCH,
                    som_buf_take(&mb));
      }
      free(stated);
    }
  }

  som_strlist_free(&form_paths);
  som_strlist_free(&list_paths);
  free(entries);
  som_strlist_free(&scope);
  form_instances_free(forms, forms_len);
}

/* ---- phase 7: derived values (uamtc10) ----------------------------------- */

/* Whether `s` reads as `^-?[0-9]+(\.[0-9]+)?$`. */
static int is_number_text(const char *s) {
  if (*s == '-') {
    s++;
  }
  if (*s < '0' || *s > '9') {
    return 0;
  }
  while (*s >= '0' && *s <= '9') {
    s++;
  }
  if (*s == '.') {
    s++;
    if (*s < '0' || *s > '9') {
      return 0;
    }
    while (*s >= '0' && *s <= '9') {
      s++;
    }
  }
  return *s == '\0';
}

static double pow10_int(int exponent) {
  double v = 1.0;
  int n = exponent < 0 ? -exponent : exponent;
  for (int i = 0; i < n; i++) {
    v *= 10.0;
  }
  return exponent < 0 ? 1.0 / v : v;
}

/* Appends `v` to `b`: as a whole number when it is one, else with up to 17
   significant digits. */
static void buf_put_number(SomBuf *b, double v) {
  char text[64];
  if (v > -9e18 && v < 9e18 && (double)(long long)v == v) {
    som_buf_puti(b, (long long)v);
    return;
  }
  snprintf(text, sizeof(text), "%.17g", v);
  /* Prefer the shortest text that reads back as the same double. */
  for (int prec = 1; prec <= 17; prec++) {
    char shorter[64];
    snprintf(shorter, sizeof(shorter), "%.*g", prec, v);
    if (strtod(shorter, NULL) == v) {
      som_buf_puts(b, shorter);
      return;
    }
  }
  som_buf_puts(b, text);
}

/* The spec of form field `name` of the form at `path`, or NULL when `path` is
   no form or the form declares no such field. */
static const FormFieldSpec *form_field_spec_at(const SpecReflection *refl,
                                               const char *path,
                                               const char *name) {
  SpecResolution res;
  if (!spec_reflection_resolve(refl, path, &res)) {
    return NULL;
  }
  const FormFieldSpec *found = NULL;
  if (strcmp(res.kind, SPEC_NODE_KIND_FORM) == 0 && res.field != NULL) {
    for (size_t k = 0; k < res.field->form_fields_len; k++) {
      if (strcmp(res.field->form_fields[k].name, name) == 0) {
        found = &res.field->form_fields[k];
        break;
      }
    }
  }
  spec_resolution_free(&res);
  return found;
}

/* The number the filled form field `spec` of the form at `path` contributes:
   an enum value its 1-based position among the enum's values, any other a
   number written `^-?[0-9]+(\.[0-9]+)?$`. Returns 0 when it is empty or
   unreadable (undecidable). */
static int number_of(const SpecDocument *doc, const char *path,
                     const FormFieldSpec *spec, double *out) {
  const char *raw = spec_document_form_field(doc, path, spec->name);
  if (raw == NULL) {
    return 0;
  }
  char *v = trim_dup(raw);
  int ok = 0;
  if (v[0] != '\0') {
    if (spec->enum_values.len > 0) {
      for (size_t k = 0; k < spec->enum_values.len; k++) {
        if (strcmp(spec->enum_values.items[k], v) == 0) {
          *out = (double)(k + 1);
          ok = 1;
          break;
        }
      }
    } else if (is_number_text(v)) {
      *out = strtod(v, NULL);
      ok = 1;
    }
  }
  free(v);
  return ok;
}

/* One ranked instance. `path` borrows from the form instances, `name` from
   the model; `stated` is owned. */
typedef struct {
  const char *path;
  const char *name;
  char *stated;
  double score;
  int has_rank;
  long long rank;
} RankEntry;

typedef struct {
  char *key; /* owned: class#field#rankField */
  RankEntry *items;
  size_t len;
  size_t cap;
} RankGroup;

/* Instance-tier derived-value check (uamtc10): a `productOf` field must hold
   the product of its operands, and a `rankOf` field must rank the instances of
   its form by their score, highest first.

   **Operands.** A plain operand is a field of the same form; `F.x` is field
   `x` of the form `F` beside it, at `<owner>/F` where `<owner>` is the section
   holding this form. A numeric operand contributes its number, an enum operand
   its 1-based position among the enum's values. When the value or any operand
   is empty — or an operand is unreadable, which other checks report — the
   product is undecidable and is skipped; a stated value that is no number is
   reported regardless.

   **Precision.** The stated number is held to the precision it is written in:
   `2.8` matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.

   **Ranks.** Over every instance of the same form whose rank and score are
   both filled, the ranks must be the whole numbers 1 to n, each once, and an
   instance may not rank below one that scores lower. Equal scores take their
   ranks in any order. Each offending instance is reported once.

   The phase's findings, products and ranks together, are stable-sorted by
   form path. */
static void validate_derived_values(const SpecReflection *refl,
                                    const SpecDocument *doc,
                                    SpecValidationErrors *out) {
  FormInstance *forms = NULL;
  size_t forms_len = 0;
  resolved_forms(refl, doc, &forms, &forms_len);
  int any = 0;
  for (size_t i = 0; i < forms_len && !any; i++) {
    for (size_t j = 0; j < forms[i].field->form_fields_len && !any; j++) {
      const FormFieldSpec *ff = &forms[i].field->form_fields[j];
      any = ff->product_of.len > 0 || ff->rank_of != NULL;
    }
  }
  if (!any) {
    form_instances_free(forms, forms_len);
    return;
  }

  /* This phase's findings start here; they are ordered by path at the end. */
  size_t first = out->len;
  RankGroup *groups = NULL;
  size_t groups_len = 0;
  size_t groups_cap = 0;

  for (size_t i = 0; i < forms_len; i++) {
    const char *path = forms[i].path;
    const char *last_slash = strrchr(path, '/');
    char *owner = last_slash == NULL
                      ? som_strdup("")
                      : som_strdup_n(path, (size_t)(last_slash - path));
    for (size_t j = 0; j < forms[i].field->form_fields_len; j++) {
      const FormFieldSpec *ff = &forms[i].field->form_fields[j];
      if (ff->product_of.len > 0) {
        const char *raw = spec_document_form_field(doc, path, ff->name);
        char *stated = raw == NULL ? NULL : trim_dup(raw);
        if (stated != NULL && stated[0] != '\0') {
          double product = 1.0;
          int decidable = 1;
          for (size_t t = 0; t < ff->product_of.len && decidable; t++) {
            const char *operand = ff->product_of.items[t];
            const char *dot = strchr(operand, '.');
            char *opath;
            const char *oname;
            if (dot == NULL) {
              opath = som_strdup(path);
              oname = operand;
            } else {
              SomBuf pb;
              som_buf_init(&pb);
              som_buf_puts(&pb, owner);
              som_buf_putc(&pb, '/');
              som_buf_putn(&pb, operand, (size_t)(dot - operand));
              opath = som_buf_take(&pb);
              oname = dot + 1;
            }
            const FormFieldSpec *ospec = form_field_spec_at(refl, opath, oname);
            double n = 0.0;
            if (ospec == NULL || !number_of(doc, opath, ospec, &n)) {
              decidable = 0;
            } else {
              product *= n;
            }
            free(opath);
          }
          if (!is_number_text(stated)) {
            char *operands = som_strlist_join(&ff->product_of, " \xC3\x97 ");
            SomBuf mb;
            som_buf_init(&mb);
            som_buf_puts(&mb, "form field \"");
            som_buf_puts(&mb, ff->name);
            som_buf_puts(&mb, "\" states \"");
            som_buf_puts(&mb, stated);
            som_buf_puts(&mb, "\", which is not a number \xE2\x80\x94 it is the product ");
            som_buf_puts(&mb, operands);
            free(operands);
            errors_push(out, path, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                        som_buf_take(&mb));
          } else if (decidable) {
            const char *sdot = strchr(stated, '.');
            int decimals = sdot == NULL ? 0 : (int)strlen(sdot + 1);
            double tolerance = 0.5 * pow10_int(-decimals) + 1e-9;
            double diff = strtod(stated, NULL) - product;
            if (diff < 0) {
              diff = -diff;
            }
            if (diff > tolerance) {
              char *operands = som_strlist_join(&ff->product_of, " \xC3\x97 ");
              SomBuf mb;
              som_buf_init(&mb);
              som_buf_puts(&mb, "form field \"");
              som_buf_puts(&mb, ff->name);
              som_buf_puts(&mb, "\" states ");
              som_buf_puts(&mb, stated);
              som_buf_puts(&mb, ", but ");
              som_buf_puts(&mb, operands);
              som_buf_puts(&mb, " gives ");
              buf_put_number(&mb, product);
              free(operands);
              errors_push(out, path,
                          SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                          som_buf_take(&mb));
            }
          }
        }
        free(stated);
      }
      if (ff->rank_of != NULL) {
        const char *raw = spec_document_form_field(doc, path, ff->name);
        char *stated = raw == NULL ? NULL : trim_dup(raw);
        const FormFieldSpec *sspec = form_field_spec_at(refl, path, ff->rank_of);
        double score = 0.0;
        if (stated != NULL && stated[0] != '\0' && sspec != NULL &&
            number_of(doc, path, sspec, &score)) {
          SomBuf kb;
          som_buf_init(&kb);
          som_buf_puts(&kb, forms[i].cls != NULL ? forms[i].cls->name : "");
          som_buf_putc(&kb, '#');
          som_buf_puts(&kb, forms[i].field->name);
          som_buf_putc(&kb, '#');
          som_buf_puts(&kb, ff->name);
          char *key = som_buf_take(&kb);
          RankGroup *g = NULL;
          for (size_t k = 0; k < groups_len; k++) {
            if (strcmp(groups[k].key, key) == 0) {
              g = &groups[k];
              break;
            }
          }
          if (g == NULL) {
            if (groups_len == groups_cap) {
              groups_cap = groups_cap ? groups_cap * 2 : 4;
              groups = (RankGroup *)realloc(groups,
                                            groups_cap * sizeof(RankGroup));
            }
            g = &groups[groups_len++];
            g->key = key;
            g->items = NULL;
            g->len = 0;
            g->cap = 0;
          } else {
            free(key);
          }
          if (g->len == g->cap) {
            g->cap = g->cap ? g->cap * 2 : 4;
            g->items = (RankEntry *)realloc(g->items,
                                            g->cap * sizeof(RankEntry));
          }
          RankEntry *e = &g->items[g->len++];
          e->path = path;
          e->name = ff->name;
          e->stated = stated;
          e->score = score;
          e->has_rank = 0;
          e->rank = 0;
          stated = NULL;
        }
        free(stated);
      }
    }
    free(owner);
  }

  for (size_t gi = 0; gi < groups_len; gi++) {
    RankGroup *g = &groups[gi];
    long long n = (long long)g->len;
    for (size_t k = 0; k < g->len; k++) {
      RankEntry *e = &g->items[k];
      /* A rank too long for any integer type is out of 1..n anyway. */
      if (all_digits(e->stated)) {
        e->has_rank = 1;
        e->rank = strlen(e->stated) > 18 ? n + 1 : strtoll(e->stated, NULL, 10);
      }
    }
    for (size_t k = 0; k < g->len; k++) {
      RankEntry *e = &g->items[k];
      SomBuf mb;
      som_buf_init(&mb);
      int problem = 0;
      if (!e->has_rank) {
        som_buf_puts(&mb, "states \"");
        som_buf_puts(&mb, e->stated);
        som_buf_puts(&mb, "\", which is not a whole number");
        problem = 1;
      } else {
        size_t uses = 0;
        for (size_t o = 0; o < g->len; o++) {
          if (g->items[o].has_rank && g->items[o].rank == e->rank) {
            uses++;
          }
        }
        if (e->rank < 1 || e->rank > n || uses > 1) {
          som_buf_puts(&mb, "states rank ");
          som_buf_puti(&mb, e->rank);
          som_buf_puts(&mb, ", but the ");
          som_buf_puti(&mb, n);
          som_buf_puts(&mb, " ranked entries take the ranks 1 to ");
          som_buf_puti(&mb, n);
          som_buf_puts(&mb, ", each once");
          problem = 1;
        } else {
          for (size_t o = 0; o < g->len; o++) {
            const RankEntry *other = &g->items[o];
            if (other->has_rank && other->score < e->score &&
                other->rank < e->rank) {
              som_buf_puts(&mb, "ranks ");
              som_buf_puti(&mb, e->rank);
              som_buf_puts(&mb, " with score ");
              buf_put_number(&mb, e->score);
              som_buf_puts(&mb, ", below an entry ranked ");
              som_buf_puti(&mb, other->rank);
              som_buf_puts(&mb, " with the lower score ");
              buf_put_number(&mb, other->score);
              problem = 1;
              break;
            }
          }
        }
      }
      char *problem_text = som_buf_take(&mb);
      if (problem) {
        SomBuf eb;
        som_buf_init(&eb);
        som_buf_puts(&eb, "form field \"");
        som_buf_puts(&eb, e->name);
        som_buf_puts(&eb, "\" ");
        som_buf_puts(&eb, problem_text);
        errors_push(out, e->path, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                    som_buf_take(&eb));
      }
      free(problem_text);
    }
  }

  for (size_t gi = 0; gi < groups_len; gi++) {
    for (size_t k = 0; k < groups[gi].len; k++) {
      free(groups[gi].items[k].stated);
    }
    free(groups[gi].items);
    free(groups[gi].key);
  }
  free(groups);
  form_instances_free(forms, forms_len);

  /* Like every phase's group, the findings are ordered by path; the sort is
     stable (insertion), so a path's own findings keep the order they were
     found in — product findings before rank findings. */
  for (size_t i = first + 1; i < out->len; i++) {
    SpecValidationError moving = out->items[i];
    size_t j = i;
    while (j > first && strcmp(out->items[j - 1].path, moving.path) > 0) {
      out->items[j] = out->items[j - 1];
      j--;
    }
    out->items[j] = moving;
  }
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
    /* A form node is the one non-leaf that legitimately carries content: it is
     * the form's preamble, the free text before the first field line (SOM §11.4
     * rule 7), in the same slot a plain section's body uses. */
    /* A wrapper section (TextSection, ...) is the other: its class is not
     * exported, so it resolves to no class and its text is stored at its own
     * path, the way the YAML codec writes it. */
    int is_wrapper_section =
        strcmp(res.kind, SPEC_NODE_KIND_SECTION) == 0 && res.target_class == NULL;
    if (!spec_resolution_is_value_leaf(&res) &&
        strcmp(res.kind, SPEC_NODE_KIND_FORM) != 0 && !is_wrapper_section) {
      errors_push(out, path, SPEC_VALIDATION_CODE_KIND_MISMATCH,
                  fmt_kind("expected a value leaf but path resolves to ",
                           res.kind));
    } else if (strcmp(res.kind, SPEC_NODE_KIND_SCALAR) == 0) {
      const char *type = res.field != NULL ? res.field->type : NULL;
      const char *value = spec_document_content(doc, path);
      if (!som_typed_text_readable(type, value)) {
        char *base = som_scalar_base(type);
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "holds \"");
        som_buf_puts(&b, value);
        som_buf_puts(&b, "\", which is not readable as ");
        som_buf_puts(&b, base != NULL ? base : "null");
        free(base);
        errors_push(out, path, SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH,
                    som_buf_take(&b));
      }
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
      const FormFieldSpec *spec = NULL;
      for (size_t k = 0; k < field->form_fields_len; k++) {
        if (strcmp(field->form_fields[k].name, names.items[j]) == 0) {
          spec = &field->form_fields[k];
          break;
        }
      }
      if (spec == NULL) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "form field \"");
        som_buf_puts(&b, names.items[j]);
        som_buf_puts(&b, "\" is not declared on ");
        som_buf_puts(&b, field->name);
        errors_push(out, path, SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD,
                    som_buf_take(&b));
        continue;
      }
      if (spec->enum_values.len == 0) {
        const char *text = spec_document_form_field(doc, path, names.items[j]);
        /* A stated count (`countOf`) is checked by countMismatch, a derived
           value (`productOf` / `rankOf`) by derivedValueMismatch, which already
           report text that is no number; one finding is enough. */
        if (spec->count_of.len == 0 && spec->product_of.len == 0 &&
            spec->rank_of == NULL &&
            !som_typed_text_readable(spec->type, text)) {
          char *base = som_scalar_base(spec->type);
          SomBuf b;
          som_buf_init(&b);
          som_buf_puts(&b, "form field \"");
          som_buf_puts(&b, names.items[j]);
          som_buf_puts(&b, "\" holds \"");
          som_buf_puts(&b, text);
          som_buf_puts(&b, "\", which is not readable as ");
          som_buf_puts(&b, base != NULL ? base : "null");
          free(base);
          errors_push(out, path, SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH,
                      som_buf_take(&b));
        }
        continue;
      }
      const char *value = spec_document_form_field(doc, path, names.items[j]);
      /* Absence is not a bad value. */
      if (value == NULL || value[0] == '\0') {
        continue;
      }
      int known = 0;
      for (size_t k = 0; k < spec->enum_values.len; k++) {
        if (strcmp(spec->enum_values.items[k], value) == 0) {
          known = 1;
          break;
        }
      }
      if (!known) {
        SomBuf b;
        som_buf_init(&b);
        som_buf_puts(&b, "form field \"");
        som_buf_puts(&b, names.items[j]);
        som_buf_puts(&b, "\" holds \"");
        som_buf_puts(&b, value);
        som_buf_puts(&b, "\", which ");
        som_buf_puts(&b, spec->type);
        som_buf_puts(&b, " does not declare (");
        for (size_t k = 0; k < spec->enum_values.len; k++) {
          if (k > 0) {
            som_buf_puts(&b, ", ");
          }
          som_buf_puts(&b, spec->enum_values.items[k]);
        }
        som_buf_puts(&b, ")");
        errors_push(out, path, SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN,
                    som_buf_take(&b));
      }
    }
    som_strlist_free(&names);
    /* A form the document holds must fill its required fields; the declared
       order makes the findings for one form stable. */
    const char *owner = NULL;
    SpecResolution owner_res;
    int have_owner = 0;
    const char *slash = strrchr(path, '/');
    if (slash != NULL && slash > path) {
      char *parent = som_strdup_n(path, (size_t)(slash - path));
      if (spec_reflection_resolve(&refl, parent, &owner_res)) {
        have_owner = 1;
        if (owner_res.target_class != NULL) {
          owner = owner_res.target_class->name;
        }
      }
      free(parent);
    }
    for (size_t k = 0; k < field->form_fields_len; k++) {
      const FormFieldSpec *ff = &field->form_fields[k];
      if (!ff->required) {
        continue;
      }
      const char *raw = spec_document_form_field(doc, path, ff->name);
      int empty = 1;
      if (raw != NULL) {
        char *t = trim_dup(raw);
        empty = t[0] == '\0';
        free(t);
      }
      if (!empty) {
        continue;
      }
      SomBuf b;
      som_buf_init(&b);
      som_buf_puts(&b, "form field \"");
      som_buf_puts(&b, ff->name);
      som_buf_puts(&b, "\" is required on ");
      if (owner != NULL) {
        som_buf_puts(&b, owner);
        som_buf_puts(&b, ".");
      }
      som_buf_puts(&b, field->name);
      som_buf_puts(&b, " but empty");
      errors_push(out, path, SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD,
                  som_buf_take(&b));
    }
    if (have_owner) {
      spec_resolution_free(&owner_res);
    }
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

  /* 6. Stated counts: a `countOf` form field states how many entries the
     document holds; only the instance tier can count them. */
  validate_count_instances(&refl, doc, out);

  /* 7. Derived values: a `productOf` field holds the product of its operands,
     a `rankOf` field ranks the instances of its form by their score. */
  validate_derived_values(&refl, doc, out);
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
