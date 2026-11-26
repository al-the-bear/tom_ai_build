/* The document-set part of the conformance suite (`tom_specs_model_rules.md`
 * §9.7), included by tests/conformance.c after conformance_links.h: the set,
 * its report and the global rename (`document_set_cases.json`),
 * `spec_derive_fields` (`derive_cases.json`), `spec_prefill` and
 * `spec_backfill` (`prefill_cases.json`, `backfill_cases.json`). A port of the
 * Rust runner's `conformance_document_set/mod.rs` (and the Go runner's
 * `conformance_document_set_test.go`).
 *
 * Uses the helpers of conformance.c and conformance_links.h (check,
 * read_json, json_canon, json_text_canon, lk_check_json, lk_load_meta,
 * lk_finding_pairs, doc_from_state). */

/* ---- reading the tables ---------------------------------------------------------- */

/* The real model (11 MB), loaded once across the tables; freed at the end. */
static SpecModel *g_ds_real_model = NULL;

static const SpecModel *ds_real_model(void) {
  if (g_ds_real_model == NULL) {
    g_ds_real_model = lk_load_meta("../../tom_som_dart_v0/meta/spec_model.meta.json");
  }
  return g_ds_real_model;
}

static void ds_release_real_model(void) {
  if (g_ds_real_model != NULL) spec_model_free(g_ds_real_model);
  g_ds_real_model = NULL;
}

/* The fixture model a table names (`links.meta.json` by default). */
static SpecModel *ds_table_model(const SomJson *table) {
  const char *name = som_json_as_str(som_json_get(table, "model"));
  return lk_load_meta(name != NULL ? name : "links.meta.json");
}

/* A model given inline as JSON, or NULL. */
static SpecModel *ds_model_from(const SomJson *v) {
  if (v == NULL || v->type != SOM_JSON_OBJECT) return NULL;
  return spec_model_from_json(v);
}

/* The model a case runs against: an inline one, the real one for a case
 * marked `som`, or the fixture. */
static const SpecModel *ds_model_of(const SpecModel *fixture,
                                    const SpecModel *inline_model,
                                    const SomJson *cc) {
  if (inline_model != NULL) return inline_model;
  if (strcmp(som_json_str_or(cc, "model"), "som") == 0) return ds_real_model();
  return fixture;
}

/* The documents of a case, `[[name, state], ...]`. */
typedef struct {
  SpecDocument *docs;
  SpecNamedDocument *named;
  size_t len;
} DsDocs;

static void ds_docs_read(const SomJson *entries, DsDocs *out) {
  size_t n = som_json_array_len(entries);
  out->docs = (SpecDocument *)calloc(n ? n : 1, sizeof(SpecDocument));
  out->named = (SpecNamedDocument *)calloc(n ? n : 1, sizeof(SpecNamedDocument));
  out->len = 0;
  for (size_t i = 0; i < n; i++) {
    const SomJson *pair = som_json_array_at(entries, i);
    const char *name = som_json_as_str(som_json_array_at(pair, 0));
    if (name == NULL) continue;
    DocumentJson state;
    document_json_from_json(som_json_array_at(pair, 1), &state);
    doc_from_state(&out->docs[out->len], &state);
    document_json_free(&state);
    out->named[out->len].name = name;
    out->named[out->len].document = &out->docs[out->len];
    out->len++;
  }
}

static void ds_docs_free(DsDocs *d) {
  for (size_t i = 0; i < d->len; i++) spec_document_free(&d->docs[i]);
  free(d->docs);
  free(d->named);
}

/* The set of a case's documents: 1, or 0 with `*why` (owned). */
static int ds_must_set(const SpecModel *model, const SomJson *cc,
                       SpecDocumentSet *out, char **why) {
  DsDocs docs;
  ds_docs_read(som_json_get(cc, "documents"), &docs);
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  int ok = spec_document_set_new(model, docs.named, docs.len, out, &err);
  if (!ok) *why = spec_document_set_error_display(&err);
  spec_document_set_error_free(&err);
  ds_docs_free(&docs);
  return ok;
}

/* The case's `pairs` list: 1 and `*out`, or 0 when it has none. */
static int ds_case_pairs(const SomJson *cc, SomStrList *out) {
  const SomJson *p = som_json_get(cc, "pairs");
  if (p == NULL || p->type != SOM_JSON_ARRAY) return 0;
  som_strlist_init(out);
  for (size_t i = 0; i < som_json_array_len(p); i++) {
    const SomJson *x = som_json_array_at(p, i);
    const char *s = som_json_as_str(x);
    if (s != NULL) {
      som_strlist_push_copy(out, s);
    } else {
      som_strlist_push(out, json_text(x));
    }
  }
  return 1;
}

static size_t ds_len(const SomJson *v) {
  return v != NULL && v->type == SOM_JSON_ARRAY ? som_json_array_len(v) : 0;
}

static int ds_json_eq(const SomJson *a, const SomJson *b) {
  char *x = json_canon(a);
  char *y = json_canon(b);
  int eq = strcmp(x, y) == 0;
  free(x);
  free(y);
  return eq;
}

/* Compares one case's output (JSON text, owned) with its expectation. */
static void ds_check_case(Checker *c, const char *tag, char *got,
                          const SomJson *want) {
  if (want == NULL) {
    char *g = json_text_canon(got);
    check(c, tag, strcmp(g, "null") == 0, g);
    free(g);
    free(got);
    return;
  }
  lk_check_json(c, tag, got, want);
}

static void ds_put_str(SomBuf *b, const char *s) { lk_str(b, s); }

static void ds_put_strs(SomBuf *b, const SomStrList *l) {
  som_buf_putc(b, '[');
  for (size_t i = 0; i < l->len; i++) {
    if (i > 0) som_buf_putc(b, ',');
    ds_put_str(b, l->items[i]);
  }
  som_buf_putc(b, ']');
}

/* `{"threw": why}`, taking `why`: a case whose set cannot be built. */
static char *ds_threw(char *why) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"threw\":");
  ds_put_str(&b, why);
  som_buf_putc(&b, '}');
  free(why);
  return som_buf_take(&b);
}

/* ---- the set ------------------------------------------------------------------- */

static char *ds_construction_case(const SpecModel *model, const SomJson *cc) {
  DsDocs docs;
  ds_docs_read(som_json_get(cc, "documents"), &docs);
  SpecDocumentSet s;
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  int ok = som_json_bool_or(cc, "fragments")
               ? spec_document_set_from_fragments(model, docs.named, docs.len, &s, &err)
               : spec_document_set_new(model, docs.named, docs.len, &s, &err);
  ds_docs_free(&docs);
  SomBuf b;
  som_buf_init(&b);
  if (!ok) {
    som_buf_puts(&b, "{\"refused\":");
    lk_take_raw(&b, spec_document_set_error_to_json(&err));
    som_buf_putc(&b, '}');
  } else {
    som_buf_puts(&b, "{\"blueprintRoot\":");
    if (s.blueprint_root[0] == '\0') {
      som_buf_puts(&b, "null");
    } else {
      ds_put_str(&b, s.blueprint_root);
    }
    SomStrList l;
    spec_document_set_names(&s, &l);
    som_buf_puts(&b, ",\"names\":");
    ds_put_strs(&b, &l);
    som_strlist_free(&l);
    spec_document_set_roots(&s, &l);
    som_buf_puts(&b, ",\"roots\":");
    ds_put_strs(&b, &l);
    som_strlist_free(&l);
    spec_document_set_missing_roots(&s, &l);
    som_buf_puts(&b, ",\"missingRoots\":");
    ds_put_strs(&b, &l);
    som_strlist_free(&l);
    som_buf_puts(&b, ",\"pairs\":[");
    for (size_t i = 0; i < s.pairs_len; i++) {
      if (i > 0) som_buf_putc(&b, ',');
      lk_take_raw(&b, spec_sync_pair_to_json(&s.pairs[i]));
    }
    som_buf_puts(&b, "]}");
    spec_document_set_free(&s);
  }
  spec_document_set_error_free(&err);
  return som_buf_take(&b);
}

static char *ds_report_case(const SpecModel *model, const SomJson *cc) {
  SpecDocumentSet s;
  char *why = NULL;
  if (!ds_must_set(model, cc, &s, &why)) return ds_threw(why);
  SomStrList pairs;
  int scoped = ds_case_pairs(cc, &pairs);
  SpecSyncReport r;
  spec_sync_report(&s, scoped ? &pairs : NULL, &r);
  char *out = spec_sync_report_to_json(&r);
  spec_sync_report_free(&r);
  if (scoped) som_strlist_free(&pairs);
  spec_document_set_free(&s);
  return out;
}

static char *ds_rename_case(const SpecModel *model, const SomJson *cc) {
  SpecDocumentSet s;
  char *why = NULL;
  if (!ds_must_set(model, cc, &s, &why)) return ds_threw(why);
  SpecRenameChanges changes;
  SpecRenameError err;
  spec_rename_error_init(&err);
  SomBuf b;
  som_buf_init(&b);
  if (!spec_rename_id(&s, som_json_str_or(cc, "from"), som_json_str_or(cc, "to"),
                      &changes, &err)) {
    som_buf_puts(&b, "{\"refused\":");
    ds_put_strs(&b, &err.documents);
    som_buf_putc(&b, '}');
  } else {
    SpecSyncReport after;
    spec_sync_report(&s, NULL, &after);
    size_t n = 0;
    for (size_t i = 0; i < after.findings_len; i++) {
      if (!spec_sync_finding_is_info(&after.findings[i])) n++;
    }
    som_buf_puts(&b, "{\"changes\":[");
    for (size_t i = 0; i < changes.len; i++) {
      if (i > 0) som_buf_putc(&b, ',');
      lk_take_raw(&b, spec_rename_change_to_json(&changes.items[i]));
    }
    som_buf_puts(&b, "],\"cleanAfter\":");
    som_buf_puts(&b, spec_sync_report_clean(&after) ? "true" : "false");
    som_buf_puts(&b, ",\"findingsAfter\":");
    som_buf_puti(&b, (long long)n);
    som_buf_putc(&b, '}');
    spec_sync_report_free(&after);
  }
  spec_rename_changes_free(&changes);
  spec_rename_error_free(&err);
  spec_document_set_free(&s);
  return som_buf_take(&b);
}

static void ds_add_token(SomStrList *out, const char *t) {
  if (t != NULL && !som_strlist_contains(out, t)) som_strlist_push_copy(out, t);
}

/* Every token a document-set expectation shows (the Dart test's
 * `_setTokens`). */
static void ds_set_tokens(const SomJson *e, SomStrList *out) {
  som_strlist_init(out);
  if (e == NULL) return;
  const SomJson *refused = som_json_get(e, "refused");
  if (refused != NULL && refused->type == SOM_JSON_OBJECT) {
    ds_add_token(out, som_json_str_or(refused, "refusal"));
  }
  if (refused != NULL && refused->type == SOM_JSON_ARRAY) ds_add_token(out, "refused");
  const SomJson *pairs = som_json_get(e, "pairs");
  if (pairs != NULL && pairs->type != SOM_JSON_NULL && refused == NULL) {
    ds_add_token(out, "built");
    if (ds_len(som_json_get(e, "missingRoots")) > 0) ds_add_token(out, "missingRoots");
  }
  const SomJson *findings = som_json_get(e, "findings");
  if (findings != NULL && findings->type == SOM_JSON_ARRAY) {
    const SomJson *clean = som_json_get(e, "clean");
    if (clean != NULL && clean->type == SOM_JSON_BOOL && clean->as.boolean) {
      ds_add_token(out, "clean");
    }
    if (ds_len(som_json_get(e, "notStarted")) > 0) ds_add_token(out, "notStarted");
    if (ds_len(som_json_get(e, "notStartedPairs")) > 0) {
      ds_add_token(out, "notStartedPairs");
    }
    for (size_t i = 0; i < som_json_array_len(findings); i++) {
      const SomJson *f = som_json_array_at(findings, i);
      ds_add_token(out, som_json_str_or(f, "code"));
      ds_add_token(out, som_json_str_or(f, "resolution"));
    }
    const SomJson *docs = som_json_get(e, "documentFindings");
    for (size_t i = 0; i < ds_len(docs); i++) {
      const SomJson *errors = som_json_array_at(som_json_array_at(docs, i), 1);
      for (size_t k = 0; k < ds_len(errors); k++) {
        ds_add_token(out, som_json_str_or(som_json_array_at(errors, k), "code"));
      }
    }
  }
  if (ds_len(som_json_get(e, "changes")) > 0) ds_add_token(out, "renamed");
}

static void test_document_set(Checker *c) {
  SomJson *table = read_json("document_set_cases.json");
  SpecModel *fixture = ds_table_model(table);
  static const char *const groups[3] = {"construction", "reports", "renames"};
  char tag[640];
  for (int g = 0; g < 3; g++) {
    const char *group = groups[g];
    const SomJson *cases = som_json_get(table, group);
    for (size_t i = 0; i < som_json_array_len(cases); i++) {
      const SomJson *cc = som_json_array_at(cases, i);
      const char *name = som_json_str_or(cc, "name");
      SpecModel *inline_model = NULL;
      const SpecModel *model = fixture;
      char *got;
      if (g == 0) {
        inline_model = ds_model_from(som_json_get(cc, "meta"));
        if (inline_model != NULL) model = inline_model;
        got = ds_construction_case(model, cc);
      } else if (g == 1) {
        inline_model = ds_model_from(som_json_get(cc, "inline"));
        model = ds_model_of(fixture, inline_model, cc);
        got = ds_report_case(model, cc);
      } else {
        got = ds_rename_case(model, cc);
      }
      snprintf(tag, sizeof(tag), "set.%s[%s]", group, name);
      ds_check_case(c, tag, got, som_json_get(cc, "expect"));
      SomStrList shown;
      ds_set_tokens(som_json_get(cc, "expect"), &shown);
      const SomJson *intent = som_json_get(cc, "intent");
      for (size_t k = 0; k < ds_len(intent); k++) {
        const char *token = som_json_as_str(som_json_array_at(intent, k));
        snprintf(tag, sizeof(tag), "set.%s.intent[%s: %s]", group, name,
                 token != NULL ? token : "");
        check(c, tag, token != NULL && som_strlist_contains(&shown, token), "");
      }
      som_strlist_free(&shown);
      if (inline_model != NULL) spec_model_free(inline_model);
    }
  }

  /* DSC4: the real model pairs every synced class. */
  SpecDocumentSet real;
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  if (!spec_document_set_new(ds_real_model(), NULL, 0, &real, &err)) {
    char *why = spec_document_set_error_display(&err);
    check(c, "set.DSC4.blueprintRoot", 0, why);
    check(c, "set.DSC4.pairs", 0, why);
    free(why);
  } else {
    check(c, "set.DSC4.blueprintRoot",
          strcmp(real.blueprint_root, "D00SolutionBlueprint") == 0,
          real.blueprint_root);
    char count[32];
    snprintf(count, sizeof(count), "%zu", real.pairs_len);
    check(c, "set.DSC4.pairs", real.pairs_len == 132, count);
    spec_document_set_free(&real);
  }
  spec_document_set_error_free(&err);
  spec_model_free(fixture);
  som_json_free(table);
}

/* ---- derive fields ---------------------------------------------------------------- */

static char *ds_derive_case(const SpecModel *model, const SomJson *cc) {
  DocumentJson state;
  document_json_from_json(som_json_get(cc, "state"), &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  document_json_free(&state);
  SpecDeriveOptions options;
  memset(&options, 0, sizeof(options));
  int marked = 1;
  som_json_as_bool(som_json_get(cc, "marked"), &marked);
  options.marked = marked;
  options.author = som_json_str_or(cc, "author");
  options.at = som_json_str_or(cc, "at");
  options.dry_run = som_json_bool_or(cc, "dryRun");
  SpecDeriveResult first, second;
  spec_derive_fields(model, &doc, &options, &first);
  spec_derive_fields(model, &doc, &options, &second);
  /* The first run's result is read after the second, as the reference runners
   * read it (the same document unless it is a dry run). */
  char *first_json = spec_derive_result_to_json(&first, &doc);
  const SpecDocument *written = spec_derive_result_written(&second, &doc);
  SpecValidationErrors after, instance;
  spec_validate_links(model, written, &after);
  validate_document(model, written, &instance);
  for (size_t i = 0; i < instance.len; i++) {
    spec_validation_errors_push(&after, instance.items[i].path,
                                instance.items[i].code, instance.items[i].message);
  }
  spec_validation_errors_free(&instance);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"first\":");
  lk_take_raw(&b, first_json);
  som_buf_puts(&b, ",\"second\":");
  lk_take_raw(&b, spec_derive_result_to_json(&second, &doc));
  som_buf_puts(&b, ",\"findingsAfter\":");
  lk_take_raw(&b, lk_finding_pairs(&after));
  som_buf_puts(&b, ",\"given\":");
  lk_take_raw(&b, spec_document_stores_json(&doc));
  som_buf_putc(&b, '}');
  spec_validation_errors_free(&after);
  spec_derive_result_free(&first);
  spec_derive_result_free(&second);
  spec_document_free(&doc);
  return som_buf_take(&b);
}

static int ds_num_is(const SomJson *v, long long want) {
  long long n;
  if (som_json_as_i64(v, &n)) return n == want;
  return v != NULL && v->type == SOM_JSON_FLOAT && v->as.real == (double)want;
}

/* Whether the intent `token` holds for the case's expectation; -1 for an
 * unknown token. */
static int ds_derive_intent_holds(const char *token, const SomJson *cc) {
  const SomJson *e = som_json_get(cc, "expect");
  const SomJson *first = som_json_get(e, "first");
  if (e == NULL || first == NULL) return 0;
  const SomJson *changes = som_json_get(first, "changes");
  size_t n = ds_len(changes);
  if (strcmp(token, "nothing") == 0) return n == 0;
  if (strcmp(token, "step1") == 0 || strcmp(token, "step2") == 0 ||
      strcmp(token, "step3") == 0) {
    for (size_t i = 0; i < n; i++) {
      if (ds_num_is(som_json_get(som_json_array_at(changes, i), "step"),
                    token[4] - '0')) {
        return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "rowAdded") == 0 || strcmp(token, "rowRemoved") == 0) {
    for (size_t i = 0; i < n; i++) {
      if (strcmp(som_json_str_or(som_json_array_at(changes, i), "kind"), token) == 0) {
        return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "marked") == 0) {
    for (size_t i = 0; i < n; i++) {
      if (strchr(som_json_str_or(som_json_array_at(changes, i), "new"), '{') != NULL) {
        return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "clean") == 0) return ds_len(som_json_get(e, "findingsAfter")) == 0;
  if (strcmp(token, "idempotent") == 0) {
    const SomJson *second = som_json_get(e, "second");
    if (second == NULL) return 0;
    return ds_len(som_json_get(second, "changes")) == 0 &&
           ds_json_eq(som_json_get(second, "document"), som_json_get(first, "document"));
  }
  if (strcmp(token, "unchanged") == 0) {
    return ds_json_eq(som_json_get(e, "given"), som_json_get(cc, "state"));
  }
  if (strcmp(token, "unmarkable") == 0 || strcmp(token, "derivedLookupMiss") == 0) {
    const SomJson *u = som_json_get(first, "unresolved");
    for (size_t i = 0; i < ds_len(u); i++) {
      if (strcmp(som_json_str_or(som_json_array_at(u, i), "code"), token) == 0) return 1;
    }
    return 0;
  }
  return -1;
}

static const char *ds_intent_detail(int holds) {
  return holds < 0 ? "unknown intent token" : "does not hold";
}

static void test_derive_fields(Checker *c) {
  SomJson *table = read_json("derive_cases.json");
  SpecModel *model = ds_table_model(table);
  const SomJson *cases = som_json_get(table, "cases");
  char tag[640];
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    snprintf(tag, sizeof(tag), "derive[%s]", name);
    ds_check_case(c, tag, ds_derive_case(model, cc), som_json_get(cc, "expect"));
    const SomJson *intent = som_json_get(cc, "intent");
    for (size_t k = 0; k < ds_len(intent); k++) {
      const char *token = som_json_as_str(som_json_array_at(intent, k));
      if (token == NULL) continue;
      int holds = ds_derive_intent_holds(token, cc);
      snprintf(tag, sizeof(tag), "derive.intent[%s: %s]", name, token);
      check(c, tag, holds == 1, ds_intent_detail(holds));
    }
  }
  spec_model_free(model);
  som_json_free(table);
}

/* ---- prefill and backfill ------------------------------------------------------------ */

static char *ds_prefill_run(SpecDocumentSet *s, const SomJson *cc,
                            const SpecPrefillOptions *options) {
  SpecPrefillResult r;
  SpecPrefillError err;
  spec_prefill_error_init(&err);
  char *out;
  if (spec_prefill(s, som_json_str_or(cc, "root"), options, &r, &err)) {
    out = spec_prefill_result_to_json(&r);
  } else {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "{\"refused\":");
    ds_put_str(&b, spec_prefill_error_code_name(err.code));
    som_buf_putc(&b, '}');
    out = som_buf_take(&b);
  }
  spec_prefill_result_free(&r);
  spec_prefill_error_free(&err);
  return out;
}

static char *ds_prefill_case(const SpecModel *model, const SomJson *cc) {
  SpecDocumentSet s;
  char *why = NULL;
  if (!ds_must_set(model, cc, &s, &why)) return ds_threw(why);
  SomStrList pairs;
  int scoped = ds_case_pairs(cc, &pairs);
  SpecPrefillOptions options;
  memset(&options, 0, sizeof(options));
  options.name = som_json_str_or(cc, "name_");
  options.pairs = scoped ? &pairs : NULL;
  char *first = ds_prefill_run(&s, cc, &options);
  char *second = ds_prefill_run(&s, cc, &options);
  SpecSyncReport after;
  spec_sync_report(&s, NULL, &after);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"first\":");
  lk_take_raw(&b, first);
  som_buf_puts(&b, ",\"second\":");
  lk_take_raw(&b, second);
  som_buf_puts(&b, ",\"reportAfter\":{\"countsByCode\":");
  lk_take_raw(&b, spec_sync_report_counts_by_code_json(&after));
  som_buf_puts(&b, ",\"notStartedPairs\":");
  ds_put_strs(&b, &after.not_started_pairs);
  som_buf_puts(&b, "}}");
  spec_sync_report_free(&after);
  if (scoped) som_strlist_free(&pairs);
  spec_document_set_free(&s);
  return som_buf_take(&b);
}

static int ds_prefill_intent_holds(const char *token, const SomJson *cc) {
  const SomJson *e = som_json_get(cc, "expect");
  const SomJson *first = som_json_get(e, "first");
  const SomJson *second = som_json_get(e, "second");
  if (e == NULL || first == NULL || second == NULL) return 0;
  if (strcmp(token, "created") == 0) {
    int v = 0;
    return som_json_as_bool(som_json_get(first, "created"), &v) && v;
  }
  if (strcmp(token, "filled") == 0) return ds_len(som_json_get(first, "filledPairs")) > 0;
  if (strcmp(token, "skipped") == 0) return ds_len(som_json_get(first, "skippedPairs")) > 0;
  if (strcmp(token, "derived") == 0) {
    return ds_len(som_json_get(som_json_get(first, "derived"), "changes")) > 0;
  }
  if (strcmp(token, "idempotent") == 0) {
    return ds_len(som_json_get(second, "filledPairs")) == 0 &&
           ds_len(som_json_get(som_json_get(second, "derived"), "changes")) == 0 &&
           ds_json_eq(som_json_get(second, "document"), som_json_get(first, "document"));
  }
  if (strcmp(token, "agrees") == 0) {
    const SomJson *counts =
        som_json_get(som_json_get(e, "reportAfter"), "countsByCode");
    for (size_t i = 0; i < ds_len(counts); i++) {
      const char *k = som_json_as_str(som_json_array_at(som_json_array_at(counts, i), 0));
      if (k != NULL && strncmp(k, "shared", 6) == 0) return 0;
    }
    return 1;
  }
  if (strcmp(token, "noBlueprint") == 0 || strcmp(token, "unknownRoot") == 0) {
    const char *r = som_json_as_str(som_json_get(first, "refused"));
    return r != NULL && strcmp(r, token) == 0;
  }
  return -1;
}

static char *ds_backfill_run(SpecDocumentSet *s, const SpecBackfillOptions *options) {
  SpecBackfillResult r;
  SpecBackfillError err;
  spec_backfill_error_init(&err);
  char *out;
  if (spec_backfill(s, options, &r, &err)) {
    out = spec_backfill_result_to_json(&r);
  } else {
    SomBuf b;
    som_buf_init(&b);
    som_buf_puts(&b, "{\"refused\":");
    lk_take_raw(&b, spec_backfill_error_to_json(&err));
    som_buf_putc(&b, '}');
    out = som_buf_take(&b);
  }
  spec_backfill_result_free(&r);
  spec_backfill_error_free(&err);
  return out;
}

static char *ds_backfill_case(const SpecModel *model, const SomJson *cc) {
  SpecDocumentSet s;
  char *why = NULL;
  if (!ds_must_set(model, cc, &s, &why)) return ds_threw(why);
  SomStrList pairs;
  int scoped = ds_case_pairs(cc, &pairs);
  SpecBackfillOptions options;
  memset(&options, 0, sizeof(options));
  options.pairs = scoped ? &pairs : NULL;
  options.path = som_json_str_or(cc, "path");
  options.dry_run = som_json_bool_or(cc, "dryRun");
  options.author = som_json_str_or(cc, "author");
  options.date = som_json_str_or(cc, "date");
  char *first = ds_backfill_run(&s, &options);
  char *second = ds_backfill_run(&s, &options);
  SpecSyncReport after;
  spec_sync_report(&s, NULL, &after);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"first\":");
  lk_take_raw(&b, first);
  som_buf_puts(&b, ",\"second\":");
  lk_take_raw(&b, second);
  som_buf_puts(&b, ",\"reportAfter\":{\"countsByCode\":");
  lk_take_raw(&b, spec_sync_report_counts_by_code_json(&after));
  som_buf_puts(&b, ",\"clean\":");
  som_buf_puts(&b, spec_sync_report_clean(&after) ? "true" : "false");
  som_buf_puts(&b, "},\"given\":[");
  SomStrList names;
  spec_document_set_names(&s, &names);
  for (size_t i = 0; i < names.len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    som_buf_putc(&b, '[');
    ds_put_str(&b, names.items[i]);
    som_buf_putc(&b, ',');
    const SpecDocument *d = spec_document_set_get(&s, names.items[i]);
    if (d != NULL) {
      lk_take_raw(&b, spec_document_stores_json(d));
    } else {
      som_buf_puts(&b, "null");
    }
    som_buf_putc(&b, ']');
  }
  som_buf_puts(&b, "]}");
  som_strlist_free(&names);
  spec_sync_report_free(&after);
  if (scoped) som_strlist_free(&pairs);
  spec_document_set_free(&s);
  return som_buf_take(&b);
}

static int ds_backfill_intent_holds(const char *token, const SomJson *cc) {
  const SomJson *e = som_json_get(cc, "expect");
  const SomJson *first = som_json_get(e, "first");
  const SomJson *second = som_json_get(e, "second");
  if (e == NULL || first == NULL || second == NULL) return 0;
  const SomJson *changes = som_json_get(first, "changes");
  const SomJson *left = som_json_get(first, "left");
  if (strcmp(token, "nothing") == 0) {
    return som_json_get(first, "refused") == NULL && ds_len(changes) == 0;
  }
  if (strcmp(token, "value") == 0 || strcmp(token, "elementAdded") == 0 ||
      strcmp(token, "elementRemoved") == 0 || strcmp(token, "revision") == 0 ||
      strcmp(token, "derived") == 0) {
    for (size_t i = 0; i < ds_len(changes); i++) {
      if (strcmp(som_json_str_or(som_json_array_at(changes, i), "kind"), token) == 0) {
        return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "heldHere") == 0 || strcmp(token, "mayBeAdded") == 0 ||
      strcmp(token, "agent") == 0) {
    for (size_t i = 0; i < ds_len(left); i++) {
      if (strcmp(som_json_str_or(som_json_array_at(left, i), "reason"), token) == 0) {
        return 1;
      }
    }
    return 0;
  }
  if (strcmp(token, "setHasMarks") == 0) {
    const SomJson *r = som_json_get(first, "refused");
    return r != NULL && strcmp(som_json_str_or(r, "code"), "setHasMarks") == 0 &&
           ds_len(som_json_get(r, "places")) > 0;
  }
  if (strcmp(token, "idempotent") == 0) return ds_len(som_json_get(second, "changes")) == 0;
  if (strcmp(token, "unchanged") == 0) {
    return ds_json_eq(som_json_get(e, "given"), som_json_get(cc, "documents"));
  }
  if (strcmp(token, "cleanAfter") == 0) {
    int v = 0;
    return som_json_as_bool(som_json_get(som_json_get(e, "reportAfter"), "clean"), &v) &&
           v;
  }
  return -1;
}

static void test_prefill_backfill(Checker *c) {
  char tag[640];
  for (int g = 0; g < 2; g++) {
    const char *label = g == 0 ? "prefill" : "backfill";
    SomJson *table = read_json(g == 0 ? "prefill_cases.json" : "backfill_cases.json");
    SpecModel *fixture = ds_table_model(table);
    const SomJson *cases = som_json_get(table, "cases");
    for (size_t i = 0; i < som_json_array_len(cases); i++) {
      const SomJson *cc = som_json_array_at(cases, i);
      const char *name = som_json_str_or(cc, "name");
      SpecModel *inline_model = ds_model_from(som_json_get(cc, "inline"));
      const SpecModel *model =
          g == 1 ? ds_model_of(fixture, inline_model, cc) : fixture;
      snprintf(tag, sizeof(tag), "%s[%s]", label, name);
      ds_check_case(c, tag,
                    g == 0 ? ds_prefill_case(model, cc) : ds_backfill_case(model, cc),
                    som_json_get(cc, "expect"));
      const SomJson *intent = som_json_get(cc, "intent");
      for (size_t k = 0; k < ds_len(intent); k++) {
        const char *token = som_json_as_str(som_json_array_at(intent, k));
        if (token == NULL) continue;
        int holds = g == 0 ? ds_prefill_intent_holds(token, cc)
                           : ds_backfill_intent_holds(token, cc);
        snprintf(tag, sizeof(tag), "%s.intent[%s: %s]", label, name, token);
        check(c, tag, holds == 1, ds_intent_detail(holds));
      }
      if (inline_model != NULL) spec_model_free(inline_model);
    }
    spec_model_free(fixture);
    som_json_free(table);
  }
}
