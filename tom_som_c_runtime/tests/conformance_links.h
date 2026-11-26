/* The section-link part of the conformance suite (`tom_specs_model_rules.md`
 * §9.7), included by tests/conformance.c: the typed readers of the link
 * annotations and the place / filter grammar (`link_reader_cases.json` over
 * `links.meta.json`, with the LR and CO cases), and the link checks of one
 * document (`link_validation_cases.json`). The typed values and headlines
 * under review (the `typedCases` of `inline_mark_cases.json` /
 * `change_mark_cases.json`) run through `run_annotation_cases_in` with the
 * `validate` / `typedRead` ops. A port of the Go runner's
 * conformance_links_test.go.
 *
 * Uses the helpers of conformance.c (check, read_corpus, read_json,
 * json_canon, json_text_canon, byte_diff, load_model, doc_from_state). */

/* ---- small JSON writers -------------------------------------------------- */

static void lk_str(SomBuf *b, const char *s) {
  char *q = som_json_encode_str(s != NULL ? s : "");
  som_buf_puts(b, q);
  free(q);
}

static void lk_take_raw(SomBuf *b, char *json_owned) {
  som_buf_puts(b, json_owned);
  free(json_owned);
}

/* Compares JSON text `got` (owned) with the corpus JSON `want`. */
static void lk_check_json(Checker *c, const char *tag, char *got,
                          const SomJson *want) {
  char *g = json_text_canon(got);
  char *w = json_canon(want);
  char *d = byte_diff(tag, g, w);
  check(c, tag, strcmp(g, w) == 0, d);
  free(d);
  free(g);
  free(w);
  free(got);
}

/* ---- typed reads (the `typedRead` op) ------------------------------------- */

/* The typed reading of the value at `path` / `field`: an enum by its name,
 * `int`, `double`, `num` and `bool` as numbers and booleans, null when the
 * text reads as nothing — with any inline mark rejected (its old value). JSON
 * text, owned. */
static char *lk_typed_read(const SpecModel *model, const SpecDocument *doc,
                           const SomJson *op) {
  const char *path = som_json_str_or(op, "path");
  const char *field = som_json_as_str(som_json_get(op, "field"));
  SpecReflection refl = spec_reflection_make(model);
  SpecResolution res;
  int resolved = spec_reflection_resolve(&refl, path, &res);
  const FormFieldSpec *spec = NULL;
  if (field != NULL && resolved && res.field != NULL) {
    for (size_t i = 0; i < res.field->form_fields_len; i++) {
      if (strcmp(res.field->form_fields[i].name, field) == 0) {
        spec = &res.field->form_fields[i];
        break;
      }
    }
  }
  const char *raw = field != NULL ? spec_document_form_field(doc, path, field)
                                  : spec_document_content(doc, path);
  const char *type = NULL;
  const SomStrList *values = NULL;
  if (spec != NULL) {
    type = spec->type;
    values = &spec->enum_values;
  } else if (resolved && res.field != NULL) {
    type = res.field->type;
    values = &res.field->enum_values;
  }
  SomBuf b;
  som_buf_init(&b);
  char *base = som_scalar_base(type);
  if (values != NULL && values->len > 0) {
    char *name = NULL;
    if (som_parse_enum_name(raw, values, &name)) {
      lk_str(&b, name);
      free(name);
    } else {
      som_buf_puts(&b, "null");
    }
  } else if (base != NULL && strcmp(base, "int") == 0) {
    long long v;
    if (som_parse_int(raw, &v)) {
      som_buf_puti(&b, v);
    } else {
      som_buf_puts(&b, "null");
    }
  } else if (base != NULL && strcmp(base, "double") == 0) {
    double v;
    if (som_parse_double(raw, &v)) {
      lk_take_raw(&b, som_format_double(v));
    } else {
      som_buf_puts(&b, "null");
    }
  } else if (base != NULL && strcmp(base, "num") == 0) {
    SomValue v = som_value_none();
    if (som_parse_num(raw, &v)) {
      lk_take_raw(&b, som_format_num(&v));
    } else {
      som_buf_puts(&b, "null");
    }
    som_value_free(&v);
  } else if (base != NULL && strcmp(base, "bool") == 0) {
    int v;
    if (som_parse_bool(raw, &v)) {
      som_buf_puts(&b, v ? "true" : "false");
    } else {
      som_buf_puts(&b, "null");
    }
  } else if (raw == NULL) {
    som_buf_puts(&b, "null");
  } else {
    char *reading = som_typed_reading(raw);
    lk_str(&b, reading);
    free(reading);
  }
  free(base);
  if (resolved) spec_resolution_free(&res);
  return som_buf_take(&b);
}

/* The findings as `[{path, code}]`. JSON text, owned. */
static char *lk_finding_pairs(const SpecValidationErrors *errs) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_putc(&b, '[');
  for (size_t i = 0; i < errs->len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_puts(&b, "{\"path\":");
    lk_str(&b, errs->items[i].path);
    som_buf_puts(&b, ",\"code\":");
    lk_str(&b, errs->items[i].code);
    som_buf_putc(&b, '}');
  }
  som_buf_putc(&b, ']');
  return som_buf_take(&b);
}

/* The instance tier's findings as `[{path, code}]` (the `validate` op). */
static char *lk_validate_pairs(const SpecModel *model, const SpecDocument *doc) {
  SpecValidationErrors errs;
  validate_document(model, doc, &errs);
  char *out = lk_finding_pairs(&errs);
  spec_validation_errors_free(&errs);
  return out;
}

/* ---- the section-link readers ----------------------------------------------- */

static int lk_cmp_class(const void *a, const void *b) {
  return strcmp((*(const SpecClassEntry *const *)a)->name,
                (*(const SpecClassEntry *const *)b)->name);
}

/* What the readers return for `model`, as JSON text: every class sync, every
 * member link, every form-field qualifier, and the `@SameAs` bindings per
 * root. Classes by name, fields and form fields in declaration order. */
static char *lk_read_back(const SpecModel *model) {
  /* `classes` is sorted by name already (binary-searchable). */
  const SpecClassEntry **names = (const SpecClassEntry **)calloc(
      model->classes_len ? model->classes_len : 1, sizeof(*names));
  for (size_t i = 0; i < model->classes_len; i++) names[i] = &model->classes[i];
  if (model->classes_len > 1) {
    qsort(names, model->classes_len, sizeof(*names), lk_cmp_class);
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"classes\":[");
  int first = 1;
  for (size_t i = 0; i < model->classes_len; i++) {
    SpecSync sync;
    if (!spec_annotations_synced_with(&names[i]->cls->annotations, &sync)) {
      continue;
    }
    if (!first) som_buf_putc(&b, ',');
    first = 0;
    som_buf_puts(&b, "{\"class\":");
    lk_str(&b, names[i]->name);
    som_buf_puts(&b, ",\"syncedWith\":");
    lk_take_raw(&b, spec_sync_to_json(&sync));
    som_buf_putc(&b, '}');
    spec_sync_free(&sync);
  }
  som_buf_puts(&b, "],\"fields\":[");
  first = 1;
  for (size_t i = 0; i < model->classes_len; i++) {
    const SpecClass *cls = names[i]->cls;
    for (size_t k = 0; k < cls->fields_len; k++) {
      const SpecAnnotationList *anns = &cls->fields[k].annotations;
      SpecSync sync;
      SpecSummaryOf summary;
      SpecDerivation derived;
      SpecExtractsLinksList extracts;
      SpecSameAs same_as;
      int has_sync = spec_annotations_synced_with(anns, &sync);
      int has_summary = spec_annotations_summary_of(anns, &summary);
      int has_derived = spec_annotations_derived_from(anns, &derived);
      spec_annotations_extracts_links(anns, &extracts);
      int has_same = spec_annotations_same_as(anns, &same_as);
      if (has_sync || has_summary || has_derived || extracts.len > 0 ||
          has_same) {
        if (!first) som_buf_putc(&b, ',');
        first = 0;
        som_buf_puts(&b, "{\"class\":");
        lk_str(&b, names[i]->name);
        som_buf_puts(&b, ",\"field\":");
        lk_str(&b, cls->fields[k].name);
        if (has_sync) {
          som_buf_puts(&b, ",\"syncedWith\":");
          lk_take_raw(&b, spec_sync_to_json(&sync));
        }
        if (has_summary) {
          som_buf_puts(&b, ",\"summaryOf\":");
          lk_take_raw(&b, spec_summary_of_to_json(&summary));
        }
        if (has_derived) {
          som_buf_puts(&b, ",\"derivedFrom\":");
          lk_take_raw(&b, spec_derivation_to_json(&derived));
        }
        if (extracts.len > 0) {
          som_buf_puts(&b, ",\"extractsLinks\":[");
          for (size_t e = 0; e < extracts.len; e++) {
            if (e > 0) som_buf_putc(&b, ',');
            lk_take_raw(&b, spec_extracts_links_to_json(&extracts.items[e]));
          }
          som_buf_putc(&b, ']');
        }
        if (has_same) {
          som_buf_puts(&b, ",\"sameAs\":");
          lk_take_raw(&b, spec_same_as_to_json(&same_as));
        }
        som_buf_putc(&b, '}');
      }
      if (has_sync) spec_sync_free(&sync);
      if (has_summary) spec_summary_of_free(&summary);
      if (has_derived) spec_derivation_free(&derived);
      spec_extracts_links_list_free(&extracts);
      if (has_same) spec_same_as_free(&same_as);
    }
  }
  som_buf_puts(&b, "],\"formFields\":[");
  first = 1;
  for (size_t i = 0; i < model->classes_len; i++) {
    const SpecClass *cls = names[i]->cls;
    for (size_t k = 0; k < cls->fields_len; k++) {
      const SpecField *f = &cls->fields[k];
      for (size_t m = 0; m < f->form_fields_len; m++) {
        const FormFieldSpec *ff = &f->form_fields[m];
        if (ff->derived_from == NULL && ff->inverse_of == NULL &&
            ff->summary_of == NULL) {
          continue;
        }
        if (!first) som_buf_putc(&b, ',');
        first = 0;
        som_buf_puts(&b, "{\"class\":");
        lk_str(&b, names[i]->name);
        som_buf_puts(&b, ",\"field\":");
        lk_str(&b, f->name);
        som_buf_puts(&b, ",\"formField\":");
        lk_str(&b, ff->name);
        if (ff->derived_from != NULL) {
          som_buf_puts(&b, ",\"derivedFrom\":");
          lk_take_raw(&b, spec_derivation_to_json(ff->derived_from));
        }
        if (ff->inverse_of != NULL) {
          som_buf_puts(&b, ",\"inverseOf\":");
          lk_take_raw(&b, spec_inverse_of_to_json(ff->inverse_of));
        }
        if (ff->summary_of != NULL) {
          som_buf_puts(&b, ",\"summaryOf\":");
          lk_take_raw(&b, spec_summary_of_to_json(ff->summary_of));
        }
        som_buf_putc(&b, '}');
      }
    }
  }
  som_buf_puts(&b, "],\"sameAsBindings\":[");
  first = 1;
  SpecReflection refl = spec_reflection_make(model);
  for (size_t r = 0; r < model->roots_len; r++) {
    SpecSameAsBindingList bindings;
    spec_same_as_bindings(&refl, model->roots[r].type, &bindings);
    for (size_t k = 0; k < bindings.len; k++) {
      if (!first) som_buf_putc(&b, ',');
      first = 0;
      lk_take_raw(&b, spec_same_as_binding_to_json(&bindings.items[k]));
    }
    spec_same_as_binding_list_free(&bindings);
  }
  som_buf_puts(&b, "],\"classCount\":");
  som_buf_puti(&b, (long long)model->classes_len);
  som_buf_putc(&b, '}');
  free(names);
  return som_buf_take(&b);
}

static size_t lk_len(const SomJson *e, const char *key) {
  return som_json_array_len(som_json_get(e, key));
}

/* Whether any row of the list `key` has member `member`. */
static int lk_has(const SomJson *e, const char *key, const char *member) {
  const SomJson *l = som_json_get(e, key);
  for (size_t i = 0; i < som_json_array_len(l); i++) {
    if (som_json_get(som_json_array_at(l, i), member) != NULL) return 1;
  }
  return 0;
}

/* Whether the reader-case intent token holds in the expectation `e`;
 * `*known` 0 for an unknown token. */
static int lk_reader_intent(const char *token, const SomJson *e, int *known) {
  *known = 1;
  if (strcmp(token, "syncedWith") == 0) return lk_len(e, "classes") > 0;
  if (strcmp(token, "syncRelationWhere") == 0) {
    const SomJson *l = som_json_get(e, "classes");
    for (size_t i = 0; i < som_json_array_len(l); i++) {
      const SomJson *rels =
          som_json_get(som_json_get(som_json_array_at(l, i), "syncedWith"),
                       "relations");
      for (size_t k = 0; k < som_json_array_len(rels); k++) {
        if (som_json_get(som_json_array_at(rels, k), "where") != NULL) return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "summaryOf") == 0) return lk_has(e, "fields", "summaryOf");
  if (strcmp(token, "summaryOfDocument") == 0) {
    const SomJson *l = som_json_get(e, "fields");
    for (size_t i = 0; i < som_json_array_len(l); i++) {
      const SomJson *s = som_json_get(som_json_array_at(l, i), "summaryOf");
      if (s != NULL && som_json_get(s, "document") != NULL) return 1;
    }
    return 0;
  }
  if (strcmp(token, "derivedFrom") == 0) return lk_has(e, "fields", "derivedFrom");
  if (strcmp(token, "extractsLinksRepeated") == 0) {
    const SomJson *l = som_json_get(e, "fields");
    for (size_t i = 0; i < som_json_array_len(l); i++) {
      if (lk_len(som_json_array_at(l, i), "extractsLinks") > 1) return 1;
    }
    return 0;
  }
  if (strcmp(token, "sameAs") == 0) return lk_has(e, "fields", "sameAs");
  if (strcmp(token, "formDerivedFrom") == 0) {
    return lk_has(e, "formFields", "derivedFrom");
  }
  if (strcmp(token, "formInverseOf") == 0) {
    return lk_has(e, "formFields", "inverseOf");
  }
  if (strcmp(token, "formSymmetric") == 0) {
    const SomJson *l = som_json_get(e, "formFields");
    for (size_t i = 0; i < som_json_array_len(l); i++) {
      const SomJson *fs = som_json_get(
          som_json_get(som_json_array_at(l, i), "inverseOf"), "fields");
      for (size_t k = 0; k < som_json_array_len(fs); k++) {
        const char *s = som_json_as_str(som_json_array_at(fs, k));
        if (s != NULL && strcmp(s, "@self") == 0) return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "formSummaryOf") == 0) {
    return lk_has(e, "formFields", "summaryOf");
  }
  if (strcmp(token, "sameAsHolder") == 0) {
    return lk_has(e, "sameAsBindings", "holder");
  }
  if (strcmp(token, "loadsUnchanged") == 0) {
    long long count = 0;
    som_json_as_i64(som_json_get(e, "classCount"), &count);
    return count > 0 && lk_len(e, "classes") == 0 && lk_len(e, "fields") == 0 &&
           lk_len(e, "formFields") == 0 && lk_len(e, "sameAsBindings") == 0;
  }
  *known = 0;
  return 0;
}

/* Every string a text case's expectation shows: kinds, problems, and
 * `matches` / `noMatch`. */
static void lk_tokens(const SomJson *v, const char *key, SomStrList *out) {
  if (v == NULL) return;
  switch (v->type) {
    case SOM_JSON_ARRAY:
      for (size_t i = 0; i < v->as.array.len; i++) {
        lk_tokens(v->as.array.items[i], "", out);
      }
      break;
    case SOM_JSON_OBJECT:
      for (size_t i = 0; i < v->as.object.len; i++) {
        lk_tokens(v->as.object.members[i].value, v->as.object.members[i].key,
                  out);
      }
      break;
    case SOM_JSON_BOOL:
      if (strcmp(key, "matches") == 0) {
        som_strlist_push_copy(out, v->as.boolean ? "matches" : "noMatch");
      }
      break;
    case SOM_JSON_STR:
      if (strcmp(key, "kind") == 0 || strcmp(key, "problem") == 0) {
        som_strlist_push_copy(out, v->as.str);
      }
      break;
    default:
      break;
  }
}

/* One place case: the text parsed, then resolved under `anchor` when given.
 * JSON text, owned; NULL when it failed with no place problem. */
static char *lk_place_case(const SpecReflection *refl, const SomJson *cc) {
  const char *text = som_json_str_or(cc, "text");
  const char *anchor = som_json_as_str(som_json_get(cc, "anchor"));
  SpecPlace place;
  if (!spec_place_try_parse(text, &place)) {
    return som_strdup("{\"problem\":\"" SPEC_PLACE_PROBLEM_MALFORMED "\"}");
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"parsed\":");
  lk_take_raw(&b, spec_place_to_json(&place));
  char *out = NULL;
  int failed = 0;
  if (anchor != NULL) {
    SpecPlaceResolution r;
    SpecPlaceError err;
    spec_place_error_init(&err);
    if (spec_place_resolve(&place, refl, anchor, &r, &err)) {
      som_buf_puts(&b, ",\"resolved\":");
      lk_take_raw(&b, spec_place_resolution_to_json(&r));
      spec_place_resolution_free(&r);
    } else if (err.problem != NULL) {
      som_buf_puts(&b, ",\"problem\":");
      lk_str(&b, err.problem);
    } else {
      failed = 1;
    }
    spec_place_error_free(&err);
  }
  som_buf_putc(&b, '}');
  out = som_buf_take(&b);
  spec_place_free(&place);
  if (failed) {
    free(out);
    return NULL;
  }
  return out;
}

/* One filter case: parsed, resolved under `anchor` when given, matched
 * against `stored` when given. */
static char *lk_filter_case(const SpecReflection *refl, const SomJson *cc) {
  const char *text = som_json_str_or(cc, "text");
  const char *anchor = som_json_as_str(som_json_get(cc, "anchor"));
  const SomJson *stored = som_json_get(cc, "stored");
  SpecPlaceFilter f;
  if (!spec_place_filter_try_parse(text, &f)) {
    return som_strdup("{\"problem\":\"" SPEC_PLACE_PROBLEM_MALFORMED "\"}");
  }
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"parsed\":");
  lk_take_raw(&b, spec_place_filter_to_json(&f));
  int failed = 0;
  if (stored != NULL && stored->type == SOM_JSON_ARRAY) {
    SomStrList values;
    som_strlist_init(&values);
    for (size_t i = 0; i < stored->as.array.len; i++) {
      som_strlist_push(&values, spec_link_json_text(stored->as.array.items[i]));
    }
    som_buf_puts(&b, ",\"matches\":");
    som_buf_puts(&b, spec_place_filter_matches_list(&f, &values) ? "true"
                                                                 : "false");
    som_strlist_free(&values);
  }
  if (anchor != NULL) {
    SpecPlaceResolution r;
    SpecPlaceError err;
    spec_place_error_init(&err);
    if (spec_place_filter_resolve(&f, refl, anchor, &r, &err)) {
      som_buf_puts(&b, ",\"resolved\":");
      lk_take_raw(&b, spec_place_resolution_to_json(&r));
      spec_place_resolution_free(&r);
    } else if (err.problem != NULL) {
      som_buf_puts(&b, ",\"problem\":");
      lk_str(&b, err.problem);
    } else {
      failed = 1;
    }
    spec_place_error_free(&err);
  }
  som_buf_putc(&b, '}');
  spec_place_filter_free(&f);
  char *out = som_buf_take(&b);
  if (failed) {
    free(out);
    return NULL;
  }
  return out;
}

static void lk_run_text_cases(Checker *c, const SpecReflection *refl,
                              const char *kind, const SomJson *cases,
                              int filters) {
  char tag[512];
  snprintf(tag, sizeof(tag), "links.%s.cases", kind);
  check(c, tag, som_json_array_len(cases) > 0, "no cases");
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    const SomJson *want = som_json_get(cc, "expect");
    snprintf(tag, sizeof(tag), "links.%s[%s]", kind, name);
    char *got = filters ? lk_filter_case(refl, cc) : lk_place_case(refl, cc);
    if (got == NULL) {
      check(c, tag, 0, "failed with no place problem");
    } else {
      lk_check_json(c, tag, got, want);
    }
    SomStrList shown;
    som_strlist_init(&shown);
    lk_tokens(want, "", &shown);
    const SomJson *intent = som_json_get(cc, "intent");
    for (size_t k = 0; k < som_json_array_len(intent); k++) {
      const char *token = som_json_as_str(som_json_array_at(intent, k));
      snprintf(tag, sizeof(tag), "links.%s.intent[%s: %s]", kind, name,
               token ? token : "");
      check(c, tag, token != NULL && som_strlist_contains(&shown, token), "");
    }
    som_strlist_free(&shown);
  }
}

static SpecModel *lk_load_meta(const char *name) {
  char *text = read_corpus(name);
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(text, &err);
  free(text);
  if (m == NULL) {
    fprintf(stderr, "load %s: %s\n", name, err ? err : "(null)");
    exit(2);
  }
  return m;
}

static const FormFieldSpec *lk_form_field(const SpecModel *m, const char *cls,
                                          const char *field, const char *name) {
  const SpecClass *c = spec_model_class_named(m, cls);
  const SpecField *f = c != NULL ? spec_class_field_named(c, field) : NULL;
  for (size_t i = 0; f != NULL && i < f->form_fields_len; i++) {
    if (strcmp(f->form_fields[i].name, name) == 0) return &f->form_fields[i];
  }
  fprintf(stderr, "no form field %s.%s.%s\n", cls, field, name);
  exit(2);
}

/* The countMismatch paths of a CO document. */
static void lk_count_paths(const SpecModel *m, const char *settled,
                           const char *total, SomStrList *out) {
  const char *base = "BLU/requirements";
  SpecDocument d;
  spec_document_init(&d);
  static const char *const statuses[3] = {"approved", "done", "draft"};
  char list[128];
  snprintf(list, sizeof(list), "%s/REQ-ITEM-LST", base);
  for (size_t i = 0; i < 3; i++) {
    char *item = spec_document_add_list_item(&d, list);
    char form[256];
    snprintf(form, sizeof(form), "%s/content", item);
    spec_document_set_form_field(&d, form, "status", statuses[i]);
    free(item);
  }
  char sum[128];
  snprintf(sum, sizeof(sum), "%s/REQS-SUM", base);
  spec_document_set_form_field(&d, sum, "total", total);
  spec_document_set_form_field(&d, sum, "settled", settled);
  SpecValidationErrors errs;
  validate_document(m, &d, &errs);
  som_strlist_init(out);
  for (size_t i = 0; i < errs.len; i++) {
    if (strcmp(errs.items[i].code, SPEC_VALIDATION_CODE_COUNT_MISMATCH) == 0) {
      som_strlist_push_copy(out, errs.items[i].path);
    }
  }
  spec_validation_errors_free(&errs);
  spec_document_free(&d);
}

static void lk_check_paths(Checker *c, const char *tag, const SomStrList *got,
                           const char *want) {
  int ok = want == NULL ? got->len == 0
                        : got->len == 1 && strcmp(got->items[0], want) == 0;
  char *joined = som_strlist_join(got, ", ");
  char detail[512];
  snprintf(detail, sizeof(detail), "got [%s] want [%s]", joined,
           want ? want : "");
  check(c, tag, ok, detail);
  free(joined);
}

static void test_link_readers(Checker *c) {
  SomJson *table = read_json("link_reader_cases.json");
  const char *meta_name = som_json_str_or(table, "model");
  if (meta_name[0] == '\0') meta_name = "links.meta.json";
  const SomJson *cases = som_json_get(table, "cases");
  check(c, "links.reader.cases", som_json_array_len(cases) > 0,
        "no cases in link_reader_cases.json");
  char tag[512];
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    const char *model_name = som_json_as_str(som_json_get(cc, "model"));
    SpecModel *m = NULL;
    char *err = NULL;
    if (model_name != NULL && strcmp(model_name, "links.meta.json") == 0) {
      m = lk_load_meta(model_name);
    } else {
      /* Keys in source order: the readers keep the meta's order. */
      char *meta = json_text(som_json_get(cc, "meta"));
      m = spec_model_from_json_str(meta, &err);
      free(meta);
    }
    const SomJson *want = som_json_get(cc, "expect");
    snprintf(tag, sizeof(tag), "links.reader[%s]", name);
    if (m == NULL) {
      check(c, tag, 0, err ? err : "threw");
    } else {
      lk_check_json(c, tag, lk_read_back(m), want);
      spec_model_free(m);
    }
    free(err);
    const SomJson *intent = som_json_get(cc, "intent");
    for (size_t k = 0; k < som_json_array_len(intent); k++) {
      const char *token = som_json_as_str(som_json_array_at(intent, k));
      int known = 0;
      int holds = token != NULL && lk_reader_intent(token, want, &known);
      snprintf(tag, sizeof(tag), "links.reader.intent[%s: %s]", name,
               token ? token : "");
      check(c, tag, known && holds,
            known ? "does not hold" : "unknown intent token");
    }
  }
  SpecModel *model = lk_load_meta(meta_name);
  SpecReflection refl = spec_reflection_make(model);
  const SomJson *text_cases = som_json_get(table, "textCases");
  lk_run_text_cases(c, &refl, "place", som_json_get(text_cases, "places"), 0);
  lk_run_text_cases(c, &refl, "filter", som_json_get(text_cases, "filters"), 1);

  /* LR1: the class sync is read with its relations. */
  SpecSync sync;
  int ok = spec_annotations_synced_with(
      &spec_model_class_named(model, "Requirements")->annotations, &sync);
  check(c, "links.LR1.sync",
        ok && strcmp(sync.document, "Detail") == 0 &&
            sync.detail_only.len == 1 &&
            strcmp(sync.detail_only.items[0], "REQX") == 0 &&
            sync.held_here.len == 1 &&
            strcmp(sync.held_here.items[0], "REQ.owner") == 0 &&
            sync.relations_len == 1 &&
            strcmp(sync.relations[0].relation, "subset") == 0,
        "");
  if (ok) spec_sync_free(&sync);
  ok = spec_annotations_synced_with(
      &spec_model_class_named(model, "Criteria")->annotations, &sync);
  check(c, "links.LR1.where",
        ok && sync.relations_len == 1 && sync.relations[0].where != NULL &&
            strcmp(sync.relations[0].where, "CRITE.kind=functional|quality") ==
                0,
        "");
  if (ok) spec_sync_free(&sync);
  ok = spec_annotations_synced_with(
      &spec_model_class_named(model, "Blueprint")->annotations, &sync);
  check(c, "links.LR1.none", !ok, "");
  if (ok) spec_sync_free(&sync);

  /* LR2: member links and the repeated @ExtractsLinks. */
  const SpecClass *req = spec_model_class_named(model, "Requirement");
  SpecExtractsLinksList links;
  spec_annotations_extracts_links(
      &spec_class_field_named(req, "links")->annotations, &links);
  check(c, "links.LR2.modes",
        links.len == 2 && strcmp(links.items[0].mode, "generate") == 0 &&
            strcmp(links.items[1].mode, "warn") == 0,
        "");
  check(c, "links.LR2.set",
        links.len > 0 && links.items[0].set.len == 1 &&
            strcmp(links.items[0].set.items[0].key, "LNK.linkType") == 0 &&
            strcmp(links.items[0].set.items[0].value, "namedInText") == 0,
        "");
  spec_extracts_links_list_free(&links);
  SpecDerivation d;
  ok = spec_annotations_derived_from(
      &spec_class_field_named(req, "abstract")->annotations, &d);
  check(c, "links.LR2.copy", ok && strcmp(d.kind, "copy") == 0, "");
  if (ok) spec_derivation_free(&d);
  ok = spec_annotations_derived_from(
      &spec_class_field_named(req, "prerequisites")->annotations, &d);
  check(c, "links.LR2.map",
        ok && d.map.len == 1 && strcmp(d.map.items[0].key, "PRE.ref") == 0 &&
            strcmp(d.map.items[0].value, "LNK-REF.ref") == 0,
        "");
  if (ok) spec_derivation_free(&d);
  SpecSummaryOf s;
  ok = spec_annotations_summary_of(
      &spec_class_field_named(req, "links")->annotations, &s);
  check(c, "links.LR2.noSummary", !ok, "");
  if (ok) spec_summary_of_free(&s);

  /* LR3: the form-field qualifiers. */
  const SpecDerivation *conflicts =
      lk_form_field(model, "Requirement", "constraints", "conflictsWith")
          ->derived_from;
  check(c, "links.LR3.where",
        conflicts != NULL && conflicts->where != NULL &&
            strcmp(conflicts->where, "LNK.linkType=conflict") == 0,
        "");
  const SpecInverseOf *sym = lk_form_field(model, "Link", "ref", "ref")->inverse_of;
  check(c, "links.LR3.symmetric", sym != NULL && spec_inverse_of_symmetric(sym),
        "");
  const SpecInverseOf *nsym =
      lk_form_field(model, "Requirement", "trace", "relatedScreens")->inverse_of;
  check(c, "links.LR3.notSymmetric",
        nsym != NULL && !spec_inverse_of_symmetric(nsym), "");
  const SpecSummaryOf *focus =
      lk_form_field(model, "Blueprint", "focus", "focusScreens")->summary_of;
  check(c, "links.LR3.summaryDocument",
        focus != NULL && focus->document != NULL &&
            strcmp(focus->document, "Screens") == 0,
        "");

  /* LR4: the real model — S1 has one holder in each document. */
  SpecModel *real = lk_load_meta("../../tom_som_dart_v0/meta/spec_model.meta.json");
  SpecReflection real_refl = spec_reflection_make(real);
  static const char *const roots[2] = {"D00SolutionBlueprint",
                                       "D10QualityAcceptancePlan"};
  for (size_t r = 0; r < 2; r++) {
    SpecSameAsBindingList bindings;
    spec_same_as_bindings(&real_refl, roots[r], &bindings);
    snprintf(tag, sizeof(tag), "links.LR4[%s]", roots[r]);
    size_t n = strlen("/detailedCriteria");
    check(c, tag,
          bindings.len == 1 &&
              strcmp(bindings.items[0].class_name, "AcceptanceCriteriaList") ==
                  0 &&
              bindings.items[0].problem == NULL &&
              strlen(bindings.items[0].copy_path) >= n &&
              strcmp(bindings.items[0].copy_path +
                         strlen(bindings.items[0].copy_path) - n,
                     "/detailedCriteria") == 0,
          "");
    spec_same_as_binding_list_free(&bindings);
  }
  spec_model_free(real);

  /* CO1–CO2: countOf reads the filter, `|` included. */
  SomStrList paths;
  lk_count_paths(model, "2", "3", &paths);
  lk_check_paths(c, "links.CO1", &paths, NULL);
  som_strlist_free(&paths);
  lk_count_paths(model, "3", "3", &paths);
  lk_check_paths(c, "links.CO2.settled", &paths, "BLU/requirements/REQS-SUM");
  som_strlist_free(&paths);
  lk_count_paths(model, "2", "2", &paths);
  lk_check_paths(c, "links.CO2.total", &paths, "BLU/requirements/REQS-SUM");
  som_strlist_free(&paths);

  spec_model_free(model);
  som_json_free(table);
}

/* ---- the link checks of one document ----------------------------------------- */

static void test_link_validation(Checker *c) {
  SomJson *table = read_json("link_validation_cases.json");
  const char *meta_name = som_json_str_or(table, "model");
  if (meta_name[0] == '\0') meta_name = "links.meta.json";
  SpecModel *model = lk_load_meta(meta_name);
  const SomJson *cases = som_json_get(table, "cases");
  check(c, "links.validate.cases", som_json_array_len(cases) > 0,
        "no cases in link_validation_cases.json");
  SomStrList provoked;
  som_strlist_init(&provoked);
  char tag[512];
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    const SomJson *want = som_json_get(cc, "errors");
    const SomJson *want_instance = som_json_get(cc, "instanceErrors");
    SomStrList codes;
    som_strlist_init(&codes);
    for (int k = 0; k < 2; k++) {
      const SomJson *l = k == 0 ? want : want_instance;
      for (size_t e = 0; e < som_json_array_len(l); e++) {
        const char *code =
            som_json_as_str(som_json_get(som_json_array_at(l, e), "code"));
        if (code == NULL) continue;
        if (!som_strlist_contains(&codes, code)) som_strlist_push_copy(&codes, code);
        if (k == 0 && !som_strlist_contains(&provoked, code)) {
          som_strlist_push_copy(&provoked, code);
        }
      }
    }
    DocumentJson state;
    document_json_from_json(som_json_get(cc, "state"), &state);
    SpecDocument d;
    doc_from_state(&d, &state);
    document_json_free(&state);
    SpecValidationErrors errs;
    spec_validate_links(model, &d, &errs);
    snprintf(tag, sizeof(tag), "links.validate[%s].errors", name);
    char *got = lk_finding_pairs(&errs);
    if (want == NULL) {
      char *g = json_text_canon(got);
      check(c, tag, strcmp(g, "[]") == 0, g);
      free(g);
      free(got);
    } else {
      lk_check_json(c, tag, got, want);
    }
    spec_validation_errors_free(&errs);
    snprintf(tag, sizeof(tag), "links.validate[%s].instanceErrors", name);
    char *instance = lk_validate_pairs(model, &d);
    if (want_instance == NULL) {
      char *g = json_text_canon(instance);
      check(c, tag, strcmp(g, "[]") == 0, g);
      free(g);
      free(instance);
    } else {
      lk_check_json(c, tag, instance, want_instance);
    }
    const SomJson *intent = som_json_get(cc, "intent");
    for (size_t k = 0; k < som_json_array_len(intent); k++) {
      const char *token = som_json_as_str(som_json_array_at(intent, k));
      if (token == NULL) continue;
      int holds = strcmp(token, "clean") == 0 ? codes.len == 0
                                              : som_strlist_contains(&codes, token);
      snprintf(tag, sizeof(tag), "links.validate.intent[%s: %s]", name, token);
      check(c, tag, holds, "");
    }
    som_strlist_free(&codes);
    spec_document_free(&d);
  }
  static const char *const all[11] = {
      SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
      SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS,
      SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW,
      SPEC_VALIDATION_CODE_INVERSE_MISSING,
      SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING,
      SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE,
      SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
      SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
      SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE,
      SPEC_VALIDATION_CODE_SAME_AS_MISMATCH,
      SPEC_VALIDATION_CODE_LINK_VALUE_PENDING,
  };
  for (size_t k = 0; k < 11; k++) {
    snprintf(tag, sizeof(tag), "links.validate.provoked[%s]", all[k]);
    check(c, tag, som_strlist_contains(&provoked, all[k]), "");
  }
  som_strlist_free(&provoked);
  spec_model_free(model);
  som_json_free(table);
}
