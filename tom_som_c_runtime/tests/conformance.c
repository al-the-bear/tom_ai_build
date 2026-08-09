/* Shared-corpus conformance suite for the C generic runtime
 * (`tom_som_c_runtime`), a faithful port of the Rust `tests/conformance.rs`.
 *
 * It loads the language-agnostic conformance corpus produced from the Dart
 * reference (`tom_som_conformance/corpus`) and asserts the C port reproduces
 * every golden byte-for-byte and matches every behavioural case:
 *   - model meta-data loads (root + class structure);
 *   - state.json loads and re-serialises identically;
 *   - YAML encode == expected.docspecs.yaml (byte-for-byte);
 *   - YAML decode -> memory -> encode is byte-stable + preserves the stamp;
 *   - Markdown export == expected.md (byte-for-byte);
 *   - Markdown parse -> memory -> export is clean + byte-stable;
 *   - the Markdown route lands the fixture in the same memory as the YAML route;
 *   - reflection resolution cases;
 *   - validation cases;
 *   - the imperative operations script;
 *   - the generic editing script (SpecEditor, YRD7);
 *   - the SOM §14 DocSpecs tier (one case per violation rule);
 *   - the portable text-pattern subset (SOM §9);
 *   - the lexical/structural query, its cursor and the node projection;
 *   - the meta-model-validated node-creation gate and its creator.
 *
 * The corpus directory is argv[1], defaulting to
 * "../tom_som_conformance/corpus" relative to the runner's cwd. Exit 0 == all
 * green; non-zero on the first failed group of checks.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

#define MODEL_VERSION "1.0"

static char g_corpus_dir[4096] = "../tom_som_conformance/corpus";

/* ---- corpus IO ---------------------------------------------------------- */

static char *read_corpus(const char *name) {
  char path[4608];
  snprintf(path, sizeof(path), "%s/%s", g_corpus_dir, name);
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "read corpus %s: cannot open\n", path);
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  if (n < 0) {
    fclose(f);
    fprintf(stderr, "read corpus %s: ftell failed\n", path);
    exit(2);
  }
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

static SomJson *read_json(const char *name) {
  char *text = read_corpus(name);
  char *err = NULL;
  SomJson *v = som_json_parse(text, &err);
  if (v == NULL) {
    fprintf(stderr, "parse corpus %s: %s\n", name, err ? err : "(null)");
    free(err);
    free(text);
    exit(2);
  }
  free(text);
  return v;
}

/* ---- Checker ------------------------------------------------------------ */

typedef struct {
  size_t passed;
  char **failed;
  size_t failed_len;
  size_t failed_cap;
} Checker;

static void checker_init(Checker *c) {
  c->passed = 0;
  c->failed = NULL;
  c->failed_len = 0;
  c->failed_cap = 0;
}

static void checker_fail(Checker *c, const char *line) {
  if (c->failed_len == c->failed_cap) {
    c->failed_cap = c->failed_cap ? c->failed_cap * 2 : 16;
    c->failed = (char **)realloc(c->failed, c->failed_cap * sizeof(char *));
  }
  c->failed[c->failed_len++] = som_strdup(line);
}

static void check(Checker *c, const char *name, int cond, const char *detail) {
  if (cond) {
    c->passed++;
    return;
  }
  if (detail == NULL || detail[0] == '\0') {
    checker_fail(c, name);
  } else {
    char buf[4352];
    snprintf(buf, sizeof(buf), "%s: %s", name, detail);
    checker_fail(c, buf);
  }
}

static int checker_finish(Checker *c) {
  size_t total = c->passed + c->failed_len;
  if (c->failed_len > 0) {
    for (size_t i = 0; i < c->failed_len; i++) {
      fprintf(stderr, "  - %s\n", c->failed[i]);
      free(c->failed[i]);
    }
    free(c->failed);
    fprintf(stderr, "FAIL: %zu/%zu checks failed\n", c->failed_len, total);
    return 1;
  }
  free(c->failed);
  printf("OK: %zu checks passed\n", total);
  return 0;
}

/* ---- helpers ------------------------------------------------------------ */

static char *byte_diff(const char *label, const char *actual,
                       const char *expected) {
  if (strcmp(actual, expected) == 0) {
    return som_strdup("");
  }
  /* find first differing line */
  size_t ai = 0, ei = 0;
  size_t line = 1;
  while (1) {
    size_t as = ai, es = ei;
    while (actual[ai] != '\0' && actual[ai] != '\n') ai++;
    while (expected[ei] != '\0' && expected[ei] != '\n') ei++;
    size_t alen = ai - as, elen = ei - es;
    if (alen != elen || memcmp(actual + as, expected + es, alen) != 0) {
      char *got = som_strdup_n(actual + as, alen);
      char *want = som_strdup_n(expected + es, elen);
      char buf[2048];
      snprintf(buf, sizeof(buf), "%s: first diff at line %zu: got \"%s\" want \"%s\"",
               label, line, got, want);
      free(got);
      free(want);
      return som_strdup(buf);
    }
    if (actual[ai] == '\0' && expected[ei] == '\0') break;
    if (actual[ai] == '\n') ai++;
    if (expected[ei] == '\n') ei++;
    line++;
  }
  char buf[256];
  snprintf(buf, sizeof(buf), "%s: differ (len got %zu want %zu)", label,
           strlen(actual), strlen(expected));
  return som_strdup(buf);
}

static SpecModel *load_model(void) {
  char *text = read_corpus("model.meta.json");
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(text, &err);
  if (m == NULL) {
    fprintf(stderr, "load model: %s\n", err ? err : "(null)");
    exit(2);
  }
  free(text);
  return m;
}

static void doc_from_state(SpecDocument *doc, const DocumentJson *state) {
  spec_document_init(doc);
  spec_document_load_json(doc, state);
}

/* Builds a SomStrList from a JSON array of strings (init by callee). */
static void json_str_list(const SomJson *arr, SomStrList *out) {
  som_strlist_init(out);
  size_t n = som_json_array_len(arr);
  for (size_t i = 0; i < n; i++) {
    const char *s = som_json_as_str(som_json_array_at(arr, i));
    if (s != NULL) {
      som_strlist_push_copy(out, s);
    }
  }
}

static int strlist_eq(const SomStrList *a, const SomStrList *b) {
  if (a->len != b->len) {
    return 0;
  }
  for (size_t i = 0; i < a->len; i++) {
    if (strcmp(a->items[i], b->items[i]) != 0) {
      return 0;
    }
  }
  return 1;
}

/* ---- groups ------------------------------------------------------------- */

static void test_model_meta(Checker *c, const SpecModel *model) {
  const SpecRoot *root = &model->roots[0];
  check(c, "model.root.sectionId", strcmp(root->section_id, "DEMO") == 0,
        root->section_id);
  check(c, "model.root.type", strcmp(root->type, "Demo") == 0, root->type);
  char cnt[32];
  snprintf(cnt, sizeof(cnt), "%zu", model->classes_len);
  check(c, "model.classCount", model->classes_len == 11, cnt);
  const SpecClass *demo = spec_model_class_named(model, "Demo");
  check(c, "model.Demo.found", demo != NULL, "");
  if (demo != NULL) {
    const char *want[] = {"title", "summary", "priority", "count",
                          "details", "items", "refs",     "cards",
                          "meta",    "control", "registry"};
    int ok = demo->fields_len == 11;
    SomBuf names;
    som_buf_init(&names);
    for (size_t i = 0; i < demo->fields_len; i++) {
      if (i > 0) som_buf_putc(&names, ',');
      som_buf_puts(&names, demo->fields[i].name);
      if (ok && i < 11 && strcmp(demo->fields[i].name, want[i]) != 0) ok = 0;
    }
    char *joined = som_buf_take(&names);
    check(c, "model.Demo.fields", ok, joined);
    free(joined);
  }
}

/* Compares an optional long long against an optional JSON integer under `key`:
 * both absent, or both present and equal. */
static int opt_i64_eq(int has, long long value, const SomJson *v,
                      const char *key) {
  long long want = 0;
  int want_has = som_json_as_i64(som_json_get(v, key), &want);
  return has == want_has && (!has || value == want);
}

/* The generation stamp: the five keys the exporter writes, and the staleness
 * verdict every runtime must reach from the same input. */
static void test_stamp(Checker *c, const SpecModel *model) {
  /* The shared model fixture carries the stamp, minus `containerRoot` (it is a
   * single synthetic document with no container class). */
  check(c, "stamp.meta.generatedAt",
        model->has_generated_at && model->generated_at == 1784534400LL, "");
  check(c, "stamp.meta.metaSchemaVersion",
        model->has_meta_schema_version && model->meta_schema_version == 1, "");
  check(c, "stamp.meta.classCount",
        model->has_class_count &&
            model->class_count == (long long)model->classes_len,
        "");
  check(c, "stamp.meta.rootCount",
        model->has_root_count &&
            model->root_count == (long long)model->roots_len,
        "");
  check(c, "stamp.meta.containerRoot", model->container_root[0] == '\0',
        model->container_root);

  SomJson *table = read_json("stamp_cases.json");
  long long default_days = 0;
  check(c, "stamp.defaultMaxAgeDays",
        som_json_as_i64(som_json_get(table, "defaultMaxAgeDays"),
                        &default_days) &&
            default_days == SPEC_DEFAULT_MAX_SNAPSHOT_AGE_SECONDS /
                                SPEC_SECONDS_PER_DAY,
        "");

  const SomJson *cases = som_json_get(table, "cases");
  size_t n = som_json_array_len(cases);
  for (size_t i = 0; i < n; i++) {
    const SomJson *kase = som_json_array_at(cases, i);
    const char *name = som_json_str_or(kase, "name");
    SpecModel *loaded = spec_model_from_json(som_json_get(kase, "model"));
    const SomJson *want = som_json_get(kase, "expect");
    char label[160];

    snprintf(label, sizeof(label), "stamp[%s].generatedAt", name);
    check(c, label,
          opt_i64_eq(loaded->has_generated_at, loaded->generated_at, want,
                     "generatedAtEpochSeconds"),
          "");
    snprintf(label, sizeof(label), "stamp[%s].metaSchemaVersion", name);
    check(c, label,
          opt_i64_eq(loaded->has_meta_schema_version,
                     loaded->meta_schema_version, want, "metaSchemaVersion"),
          "");
    snprintf(label, sizeof(label), "stamp[%s].classCount", name);
    check(c, label,
          opt_i64_eq(loaded->has_class_count, loaded->class_count, want,
                     "classCount"),
          "");
    snprintf(label, sizeof(label), "stamp[%s].rootCount", name);
    check(c, label,
          opt_i64_eq(loaded->has_root_count, loaded->root_count, want,
                     "rootCount"),
          "");
    snprintf(label, sizeof(label), "stamp[%s].containerRoot", name);
    check(c, label,
          strcmp(loaded->container_root,
                 som_json_str_or(want, "containerRoot")) == 0,
          loaded->container_root);
    snprintf(label, sizeof(label), "stamp[%s].actualClassCount", name);
    check(c, label,
          opt_i64_eq(1, (long long)loaded->classes_len, want,
                     "actualClassCount"),
          "");
    snprintf(label, sizeof(label), "stamp[%s].actualRootCount", name);
    check(c, label,
          opt_i64_eq(1, (long long)loaded->roots_len, want, "actualRootCount"),
          "");

    const SomJson *wc = som_json_get(kase, "check");
    long long max_age_days = 0, now = 0;
    som_json_as_i64(som_json_get(wc, "maxAgeDays"), &max_age_days);
    som_json_as_i64(som_json_get(wc, "nowEpochSeconds"), &now);
    SpecModelStampCheck got =
        spec_model_check_stamp(loaded, max_age_days * SPEC_SECONDS_PER_DAY, now);

    snprintf(label, sizeof(label), "stamp[%s].ageSeconds", name);
    check(c, label, opt_i64_eq(got.has_age, got.age_seconds, wc, "ageSeconds"),
          "");

    const char *keys[] = {"isAged", "classCountDisagrees", "rootCountDisagrees",
                          "countsDisagree", "isStale"};
    int actuals[] = {spec_stamp_check_is_aged(&got),
                     spec_stamp_check_class_count_disagrees(&got),
                     spec_stamp_check_root_count_disagrees(&got),
                     spec_stamp_check_counts_disagree(&got),
                     spec_stamp_check_is_stale(&got)};
    for (size_t k = 0; k < sizeof(keys) / sizeof(keys[0]); k++) {
      snprintf(label, sizeof(label), "stamp[%s].%s", name, keys[k]);
      check(c, label, (actuals[k] != 0) == (som_json_bool_or(wc, keys[k]) != 0),
            "");
    }

    SomStrList got_warnings;
    spec_stamp_check_warnings(&got, &got_warnings);
    SomStrList want_warnings;
    json_str_list(som_json_get(wc, "warnings"), &want_warnings);
    char *joined = som_strlist_join(&got_warnings, " | ");
    snprintf(label, sizeof(label), "stamp[%s].warnings", name);
    check(c, label, strlist_eq(&got_warnings, &want_warnings), joined);
    free(joined);
    som_strlist_free(&got_warnings);
    som_strlist_free(&want_warnings);

    spec_model_free(loaded);
  }
  som_json_free(table);
}

static void test_state_round_trip(Checker *c) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  DocumentJson dj;
  spec_document_to_json(&doc, &dj);
  char *got = document_json_to_canonical_json(&dj);
  char *want = document_json_to_canonical_json(&state);
  char detail[2048];
  snprintf(detail, sizeof(detail), "got %s want %s", got, want);
  check(c, "state.toJson", strcmp(got, want) == 0, detail);
  free(got);
  free(want);
  document_json_free(&dj);
  spec_document_free(&doc);
  document_json_free(&state);
  som_json_free(sj);
}

static void test_yaml_encode(Checker *c, const SomMetaTree *tree) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  char *expected = read_corpus("expected.docspecs.yaml");
  char *err = NULL;
  char *actual = encode_yaml(&doc, tree, MODEL_VERSION, &err);
  if (actual == NULL) {
    check(c, "yaml.encode", 0, err ? err : "(no message)");
    free(err);
  } else {
    char *d = byte_diff("yaml.encode", actual, expected);
    check(c, "yaml.encode", strcmp(actual, expected) == 0, d);
    free(d);
    free(actual);
  }
  free(expected);
  spec_document_free(&doc);
  document_json_free(&state);
  som_json_free(sj);
}

static void test_yaml_decode_round_trip(Checker *c, const SomMetaTree *tree) {
  char *expected = read_corpus("expected.docspecs.yaml");
  SpecYamlContents contents;
  char *err = NULL;
  if (!decode_yaml(expected, tree, &contents, &err)) {
    check(c, "yaml.decode.stamp", 0, err ? err : "(no message)");
    free(err);
    free(expected);
    return;
  }
  check(c, "yaml.decode.stamp",
        strcmp(contents.model_version, MODEL_VERSION) == 0,
        contents.model_version);

  /* The decoded memory equals the canonical state (the hierarchical decode
   * lands the same sparse stores state.json describes). */
  {
    SomJson *sj = read_json("state.json");
    DocumentJson canonical;
    document_json_from_json(sj, &canonical);
    DocumentJson dj;
    spec_document_to_json(&contents.document, &dj);
    char *got = document_json_to_canonical_json(&dj);
    char *want = document_json_to_canonical_json(&canonical);
    char detail[2048];
    snprintf(detail, sizeof(detail), "got %s want %s", got, want);
    check(c, "yaml.decode.memory", strcmp(got, want) == 0, detail);
    free(got);
    free(want);
    document_json_free(&dj);
    document_json_free(&canonical);
    som_json_free(sj);
  }

  const char *stamp = (contents.model_version[0] == '\0')
                          ? MODEL_VERSION
                          : contents.model_version;
  char *err2 = NULL;
  char *actual = encode_yaml(&contents.document, tree, stamp, &err2);
  if (actual == NULL) {
    check(c, "yaml.decode.reencode", 0, err2 ? err2 : "(no message)");
    free(err2);
  } else {
    char *d = byte_diff("yaml.decode.reencode", actual, expected);
    check(c, "yaml.decode.reencode", strcmp(actual, expected) == 0, d);
    free(d);
    free(actual);
  }
  spec_yaml_contents_free(&contents);
  free(expected);
}

/* Markdown conformance (md.export / md.parse.* / md.land.*). */
static void test_markdown_export(Checker *c, const SpecModel *model) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  char *expected = read_corpus("expected.md");
  char *actual = spec_markdown_export_root(model, &doc, &model->roots[0], NULL);
  char *d = byte_diff("md.export", actual, expected);
  check(c, "md.export", strcmp(actual, expected) == 0, d);
  free(d);
  free(actual);
  free(expected);
  spec_document_free(&doc);
  document_json_free(&state);
  som_json_free(sj);
}

static char *rej_str(const SpecMarkdownResult *r) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < r->rejections_len; i++) {
    if (i > 0) som_buf_puts(&b, "; ");
    char *d = spec_markdown_rejection_display(&r->rejections[i]);
    som_buf_puts(&b, d);
    free(d);
  }
  return som_buf_take(&b);
}

static void test_markdown_round_trip(Checker *c, const SpecModel *model) {
  char *expected = read_corpus("expected.md");
  SpecMarkdownResult result;
  spec_markdown_parse(model, expected, &result);
  char *rs = rej_str(&result);
  check(c, "md.parse.clean", spec_markdown_result_is_clean(&result), rs);
  free(rs);
  SpecDocument applied;
  spec_document_init(&applied);
  spec_document_load_json(&applied, spec_markdown_result_document(&result));
  /* YRD3: the stored item id and stored headline round-trip through md. */
  {
    const char *sid = spec_document_item_section_id(&applied, "DEMO/REF-LST-1");
    check(c, "md.parse.storedId",
          sid != NULL && strcmp(sid, "REF-SPEC") == 0, sid != NULL ? sid : "");
    const char *hl = spec_document_headline(&applied, "DEMO/REF-LST-1");
    check(c, "md.parse.headline",
          hl != NULL && strcmp(hl, "Reference to the Spec") == 0,
          hl != NULL ? hl : "");
  }
  char *actual =
      spec_markdown_export_root(model, &applied, &model->roots[0], NULL);
  char *d = byte_diff("md.parse.reexport", actual, expected);
  check(c, "md.parse.reexport", strcmp(actual, expected) == 0, d);
  free(d);
  free(actual);
  spec_document_free(&applied);
  spec_markdown_result_free(&result);
  free(expected);
}

static void test_markdown_memory_landing(Checker *c, const SpecModel *model) {
  char *expected_md = read_corpus("expected.md");
  SomJson *sj = read_json("state.json");
  DocumentJson canonical;
  document_json_from_json(sj, &canonical);
  SpecMarkdownResult result;
  spec_markdown_parse(model, expected_md, &result);
  char *rs = rej_str(&result);
  check(c, "md.land.clean", spec_markdown_result_is_clean(&result), rs);
  free(rs);
  SpecDocument landed;
  spec_document_init(&landed);
  spec_document_load_json(&landed, spec_markdown_result_document(&result));
  DocumentJson dj;
  spec_document_to_json(&landed, &dj);
  char *got = document_json_to_canonical_json(&dj);
  char *want = document_json_to_canonical_json(&canonical);
  char detail[2048];
  snprintf(detail, sizeof(detail), "got %s want %s", got, want);
  check(c, "md.land.memory", strcmp(got, want) == 0, detail);
  free(got);
  free(want);
  document_json_free(&dj);
  spec_document_free(&landed);
  spec_markdown_result_free(&result);
  document_json_free(&canonical);
  som_json_free(sj);
  free(expected_md);
}

static void test_reflection(Checker *c, const SpecModel *model) {
  SpecReflection refl = spec_reflection_make(model);
  SomJson *cases = read_json("reflection_cases.json");
  size_t n = som_json_array_len(cases);
  for (size_t i = 0; i < n; i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *path = som_json_str_or(cc, "path");
    int resolves = som_json_bool_or(cc, "resolves");
    SpecResolution res;
    int ok = spec_reflection_resolve(&refl, path, &res);
    char tag[1024];
    if (!resolves) {
      snprintf(tag, sizeof(tag), "reflect[%s].none", path);
      check(c, tag, !ok, "expected no resolution");
      if (ok) spec_resolution_free(&res);
      continue;
    }
    if (!ok) {
      snprintf(tag, sizeof(tag), "reflect[%s].some", path);
      check(c, tag, 0, "expected resolution, got nil");
      continue;
    }

    const char *want_kind = som_json_str_or(cc, "kind");
    snprintf(tag, sizeof(tag), "reflect[%s].kind", path);
    char kd[512];
    snprintf(kd, sizeof(kd), "%s != %s", res.kind, want_kind);
    check(c, tag, strcmp(res.kind, want_kind) == 0, kd);

    const char *field_name = res.field != NULL ? res.field->name : "";
    const SomJson *wf = som_json_get(cc, "field");
    const char *want_field = som_json_as_str(wf); /* NULL if absent/non-str */
    int field_eq = (want_field == NULL) ? (field_name[0] == '\0')
                                        : (strcmp(field_name, want_field) == 0);
    snprintf(tag, sizeof(tag), "reflect[%s].field", path);
    check(c, tag, field_eq, field_name);

    const char *target = res.target_class != NULL ? res.target_class->name : "";
    const SomJson *wt = som_json_get(cc, "targetClass");
    const char *want_target = som_json_as_str(wt);
    int target_eq = (want_target == NULL)
                        ? (target[0] == '\0')
                        : (strcmp(target, want_target) == 0);
    snprintf(tag, sizeof(tag), "reflect[%s].target", path);
    check(c, tag, target_eq, target);

    snprintf(tag, sizeof(tag), "reflect[%s].leaf", path);
    check(c, tag,
          spec_resolution_is_value_leaf(&res) == som_json_bool_or(cc, "isValueLeaf"),
          "");
    spec_resolution_free(&res);
  }
  som_json_free(cases);
}

static void test_validation(Checker *c, const SpecModel *model) {
  SomJson *cases = read_json("validation_cases.json");
  size_t n = som_json_array_len(cases);
  for (size_t i = 0; i < n; i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");
    DocumentJson state;
    document_json_from_json(som_json_get(cc, "state"), &state);
    SpecDocument doc;
    doc_from_state(&doc, &state);
    SpecValidationErrors errs;
    validate_document(model, &doc, &errs);

    /* build got string: "path:code|path:code|..." */
    SomBuf got;
    som_buf_init(&got);
    for (size_t e = 0; e < errs.len; e++) {
      if (e > 0) som_buf_putc(&got, '|');
      som_buf_puts(&got, errs.items[e].path);
      som_buf_putc(&got, ':');
      som_buf_puts(&got, errs.items[e].code);
    }
    char *got_s = som_buf_take(&got);

    SomBuf want;
    som_buf_init(&want);
    const SomJson *warr = som_json_get(cc, "errors");
    size_t wlen = som_json_array_len(warr);
    for (size_t e = 0; e < wlen; e++) {
      const SomJson *we = som_json_array_at(warr, e);
      if (e > 0) som_buf_putc(&want, '|');
      som_buf_puts(&want, som_json_str_or(we, "path"));
      som_buf_putc(&want, ':');
      som_buf_puts(&want, som_json_str_or(we, "code"));
    }
    char *want_s = som_buf_take(&want);

    char tag[512], detail[2048];
    snprintf(tag, sizeof(tag), "validate[%s]", name);
    snprintf(detail, sizeof(detail), "%s != %s", got_s, want_s);
    check(c, tag, strcmp(got_s, want_s) == 0, detail);
    free(got_s);
    free(want_s);
    spec_validation_errors_free(&errs);
    spec_document_free(&doc);
    document_json_free(&state);
  }
  som_json_free(cases);
}

/* ---- the generic editing API (YRD7) ------------------------------------- */

/* The corpus's typed value positions as a `SomValue`. The distinctions the
 * typed contract rests on live in the JSON types themselves — the integer `2`
 * is not the float `2.5` is not the string `"12"`, `true` is not
 * `"not-a-bool"` — so they are carried across, not flattened to text. */
static SomValue json_som_value(const SomJson *v) {
  if (v == NULL) {
    return som_value_none();
  }
  switch (v->type) {
    case SOM_JSON_BOOL:
      return som_value_bool(v->as.boolean);
    case SOM_JSON_INT:
      return som_value_int(v->as.integer);
    case SOM_JSON_FLOAT:
      return som_value_double(v->as.real);
    case SOM_JSON_STR:
      return som_value_str(v->as.str);
    default:
      return som_value_none();
  }
}

/* Asserts `got` equals the JSON expectation under `key`, reporting the actual
 * value on a mismatch. Consumes nothing; the caller still owns `got`. */
static void check_value(Checker *c, const char *tag, const SomValue *got,
                        const SomJson *step, const char *key) {
  SomValue want = json_som_value(som_json_get(step, key));
  char *shown = som_value_debug(got);
  char *wanted = som_value_debug(&want);
  char detail[512];
  snprintf(detail, sizeof(detail), "%s != %s", shown, wanted);
  check(c, tag, som_value_equals(got, &want), detail);
  free(shown);
  free(wanted);
  som_value_free(&want);
}

/* Asserts an optional string reads as the JSON expectation under `key` (a JSON
 * null / absent key means "unset"). */
static void check_opt_str(Checker *c, const char *tag, const char *got,
                          const SomJson *step, const char *key) {
  const char *want = som_json_as_str(som_json_get(step, key));
  if (want == NULL) {
    check(c, tag, got == NULL, got != NULL ? got : "");
  } else {
    check(c, tag, got != NULL && strcmp(got, want) == 0, got != NULL ? got : "");
  }
}

/* Asserts a fallible editor call failed, and releases the message it produced.
 * The strict-write half of the typed contract: every `*Throws` op must be
 * rejected, not silently absorbed. */
static void check_rejected(Checker *c, const char *tag, int ok, char *err) {
  check(c, tag, !ok, "did not fail");
  free(err);
}

/* YRD7: the generic, meta-validated modification API (SpecEditor) — typed
 * value/form-field round-trips through the shared boundary helpers, enum domain
 * validation, and structural create/clear ops.
 *
 * A stateful, ordered script: one document, each step building on the last.
 * Executed against the corpus model, so every language's generic editor replays
 * the identical sequence. */
static void test_editor(Checker *c, const SpecModel *model) {
  SpecDocument doc;
  spec_document_init(&doc);
  SpecEditor ed = spec_editor_for_model(&doc, model);
  SomJson *steps = read_json("editor_cases.json");
  size_t n = som_json_array_len(steps);
  for (size_t i = 0; i < n; i++) {
    const SomJson *s = som_json_array_at(steps, i);
    const char *op = som_json_str_or(s, "op");
    const char *path = som_json_str_or(s, "path");
    const char *field = som_json_str_or(s, "field");
    char tag[640];
    char *err = NULL;

    if (strcmp(op, "setValue") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].setValue %s", i, path);
      SomValue v = json_som_value(som_json_get(s, "value"));
      int ok = spec_editor_set_value(&ed, path, &v, &err);
      check(c, tag, ok, err != NULL ? err : "");
      free(err);
      som_value_free(&v);
    } else if (strcmp(op, "value") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].value %s", i, path);
      SomValue got = som_value_none();
      if (!spec_editor_value(&ed, path, &got, &err)) {
        check(c, tag, 0, err != NULL ? err : "");
        free(err);
      } else {
        check_value(c, tag, &got, s, "expect");
      }
      som_value_free(&got);
    } else if (strcmp(op, "setValueThrows") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].setValueThrows %s", i, path);
      SomValue v = json_som_value(som_json_get(s, "value"));
      check_rejected(c, tag, spec_editor_set_value(&ed, path, &v, &err), err);
      som_value_free(&v);
    } else if (strcmp(op, "setContent") == 0) {
      /* raw store write — deliberately bypasses the typed boundary */
      spec_document_set_content(&doc, path, som_json_str_or(s, "value"));
    } else if (strcmp(op, "rawContent") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].rawContent %s", i, path);
      check_opt_str(c, tag, spec_document_content(&doc, path), s, "expect");
    } else if (strcmp(op, "setFormValue") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].setFormValue %s#%s", i, path,
               field);
      SomValue v = json_som_value(som_json_get(s, "value"));
      int ok = spec_editor_set_form_value(&ed, path, field, &v, &err);
      check(c, tag, ok, err != NULL ? err : "");
      free(err);
      som_value_free(&v);
    } else if (strcmp(op, "formValue") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].formValue %s#%s", i, path, field);
      SomValue got = som_value_none();
      if (!spec_editor_form_value(&ed, path, field, &got, &err)) {
        check(c, tag, 0, err != NULL ? err : "");
        free(err);
      } else {
        check_value(c, tag, &got, s, "expect");
      }
      som_value_free(&got);
    } else if (strcmp(op, "setFormValueThrows") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].setFormValueThrows %s#%s", i, path,
               field);
      SomValue v = json_som_value(som_json_get(s, "value"));
      check_rejected(c, tag,
                     spec_editor_set_form_value(&ed, path, field, &v, &err),
                     err);
      som_value_free(&v);
    } else if (strcmp(op, "rawFormField") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].rawFormField %s#%s", i, path,
               field);
      check_opt_str(c, tag, spec_document_form_field(&doc, path, field), s,
                    "expect");
    } else if (strcmp(op, "formFieldNames") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].formFieldNames %s", i, path);
      const FormFieldSpec *ffs = NULL;
      size_t ffs_len = 0;
      if (!spec_editor_form_fields(&ed, path, &ffs, &ffs_len, &err)) {
        check(c, tag, 0, err != NULL ? err : "");
        free(err);
      } else {
        SomStrList got;
        som_strlist_init(&got);
        for (size_t k = 0; k < ffs_len; k++) {
          som_strlist_push_copy(&got, ffs[k].name);
        }
        SomStrList want;
        json_str_list(som_json_get(s, "expect"), &want);
        char *gj = som_strlist_join(&got, ",");
        check(c, tag, strlist_eq(&got, &want), gj);
        free(gj);
        som_strlist_free(&got);
        som_strlist_free(&want);
      }
    } else if (strcmp(op, "formFieldNamesThrows") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].formFieldNamesThrows %s", i, path);
      check_rejected(c, tag,
                     spec_editor_form_fields(&ed, path, NULL, NULL, &err), err);
    } else if (strcmp(op, "setHeadline") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].setHeadline %s", i, path);
      int ok = spec_editor_set_headline(
          &ed, path, som_json_as_str(som_json_get(s, "value")), &err);
      check(c, tag, ok, err != NULL ? err : "");
      free(err);
    } else if (strcmp(op, "headline") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].headline %s", i, path);
      const char *got = NULL;
      if (!spec_editor_headline(&ed, path, &got, &err)) {
        check(c, tag, 0, err != NULL ? err : "");
        free(err);
      } else {
        check_opt_str(c, tag, got, s, "expect");
      }
    } else if (strcmp(op, "headlineThrows") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].headlineThrows %s", i, path);
      check_rejected(c, tag, spec_editor_headline(&ed, path, NULL, &err), err);
    } else if (strcmp(op, "itemSectionId") == 0) {
      const char *item_path = som_json_str_or(s, "itemPath");
      snprintf(tag, sizeof(tag), "editor[%zu].itemSectionId %s", i, item_path);
      check_opt_str(c, tag, spec_document_item_section_id(&doc, item_path), s,
                    "expect");
    } else if (strcmp(op, "addListItem") == 0 ||
               strcmp(op, "addListItemThrows") == 0) {
      const char *list_path = som_json_str_or(s, "listPath");
      long long month = 0, day = 0;
      som_json_as_i64(som_json_get(s, "month"), &month);
      som_json_as_i64(som_json_get(s, "day"), &day);
      char *item_path = NULL;
      SpecSectionIdError id_err;
      spec_section_id_error_init(&id_err);
      int ok = spec_editor_add_list_item(&ed, list_path, NULL, month, day,
                                         &item_path, &id_err, &err);
      spec_section_id_error_free(&id_err);
      if (strcmp(op, "addListItemThrows") == 0) {
        snprintf(tag, sizeof(tag), "editor[%zu].addListItemThrows %s", i,
                 list_path);
        check_rejected(c, tag, ok, err);
        free(item_path);
        continue;
      }
      snprintf(tag, sizeof(tag), "editor[%zu].addListItem %s", i, list_path);
      if (!ok) {
        check(c, tag, 0, err != NULL ? err : "");
        free(err);
        continue;
      }
      const char *expect_path = som_json_str_or(s, "expectPath");
      char detail[1024];
      snprintf(detail, sizeof(detail), "%s != %s", item_path, expect_path);
      check(c, tag, strcmp(item_path, expect_path) == 0, detail);
      if (som_json_get(s, "expectId") != NULL) {
        char idtag[672];
        snprintf(idtag, sizeof(idtag), "%s id", tag);
        check_opt_str(c, idtag, spec_document_item_section_id(&doc, item_path),
                      s, "expectId");
      }
      free(item_path);
    } else if (strcmp(op, "removeListItem") == 0) {
      const char *item_path = som_json_str_or(s, "itemPath");
      snprintf(tag, sizeof(tag), "editor[%zu].removeListItem %s", i, item_path);
      check(c, tag,
            spec_editor_remove_list_item(&ed, item_path) ==
                som_json_bool_or(s, "expect"),
            "");
    } else if (strcmp(op, "clearSection") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].clearSection %s", i, path);
      int ok = spec_editor_clear_section(&ed, path, &err);
      check(c, tag, ok, err != NULL ? err : "");
      free(err);
    } else if (strcmp(op, "clearSectionThrows") == 0) {
      snprintf(tag, sizeof(tag), "editor[%zu].clearSectionThrows %s", i, path);
      check_rejected(c, tag, spec_editor_clear_section(&ed, path, &err), err);
    } else if (strcmp(op, "hasValuesUnder") == 0) {
      const char *prefix = som_json_str_or(s, "prefix");
      snprintf(tag, sizeof(tag), "editor[%zu].hasValuesUnder %s", i, prefix);
      check(c, tag,
            spec_document_has_values_under(&doc, prefix) ==
                som_json_bool_or(s, "expect"),
            "");
    } else {
      snprintf(tag, sizeof(tag), "editor[%zu].unknown", i);
      check(c, tag, 0, op);
    }
  }
  som_json_free(steps);
  spec_document_free(&doc);
}

static void test_operations(Checker *c) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomJson *cases = read_json("operations_cases.json");
  size_t n = som_json_array_len(cases);
  for (size_t i = 0; i < n; i++) {
    const SomJson *op = som_json_array_at(cases, i);
    const char *op_name = som_json_str_or(op, "op");
    char tag[512];
    snprintf(tag, sizeof(tag), "op[%zu].%s", i, op_name);

    if (strcmp(op_name, "isEmpty") == 0) {
      int exp = som_json_bool_or(op, "expect");
      check(c, tag, spec_document_is_empty(&doc) == exp, "");
    } else if (strcmp(op_name, "setContent") == 0) {
      spec_document_set_content(&doc, som_json_str_or(op, "path"),
                               som_json_str_or(op, "value"));
    } else if (strcmp(op_name, "content") == 0) {
      const char *val = spec_document_content(&doc, som_json_str_or(op, "path"));
      const SomJson *e = som_json_get(op, "expect");
      const char *exp = som_json_as_str(e);
      if (exp == NULL) {
        check(c, tag, val == NULL, "expected unset");
      } else {
        check(c, tag, val != NULL && strcmp(val, exp) == 0, val ? val : "");
      }
    } else if (strcmp(op_name, "setFormField") == 0) {
      spec_document_set_form_field(&doc, som_json_str_or(op, "path"),
                                  som_json_str_or(op, "field"),
                                  som_json_str_or(op, "value"));
    } else if (strcmp(op_name, "formField") == 0) {
      const char *val = spec_document_form_field(&doc, som_json_str_or(op, "path"),
                                                som_json_str_or(op, "field"));
      const SomJson *e = som_json_get(op, "expect");
      const char *exp = som_json_as_str(e);
      if (exp == NULL) {
        check(c, tag, val == NULL, "expected unset");
      } else {
        check(c, tag, val != NULL && strcmp(val, exp) == 0, val ? val : "");
      }
    } else if (strcmp(op_name, "addListItem") == 0) {
      const char *exp = som_json_str_or(op, "expect");
      char *got = spec_document_add_list_item(&doc, som_json_str_or(op, "listPath"));
      char detail[1024];
      snprintf(detail, sizeof(detail), "%s != %s", got, exp);
      check(c, tag, strcmp(got, exp) == 0, detail);
      free(got);
    } else if (strcmp(op_name, "listItems") == 0) {
      const SomStrList *got = spec_document_list_items(&doc, som_json_str_or(op, "listPath"));
      SomBuf gb;
      som_buf_init(&gb);
      if (got != NULL) {
        for (size_t k = 0; k < got->len; k++) {
          if (k > 0) som_buf_putc(&gb, ',');
          som_buf_puts(&gb, got->items[k]);
        }
      }
      char *got_s = som_buf_take(&gb);
      const SomJson *arr = som_json_get(op, "expect");
      SomBuf wb;
      som_buf_init(&wb);
      size_t alen = som_json_array_len(arr);
      for (size_t k = 0; k < alen; k++) {
        if (k > 0) som_buf_putc(&wb, ',');
        som_buf_puts(&wb, som_json_as_str(som_json_array_at(arr, k)));
      }
      char *want_s = som_buf_take(&wb);
      check(c, tag, strcmp(got_s, want_s) == 0, got_s);
      free(got_s);
      free(want_s);
    } else if (strcmp(op_name, "listItemCount") == 0) {
      long long exp = 0;
      som_json_as_i64(som_json_get(op, "expect"), &exp);
      size_t got = spec_document_list_item_count(&doc, som_json_str_or(op, "listPath"));
      char detail[64];
      snprintf(detail, sizeof(detail), "%zu", got);
      check(c, tag, got == (size_t)exp, detail);
    } else if (strcmp(op_name, "setHeadline") == 0) {
      spec_document_set_headline(&doc, som_json_str_or(op, "path"),
                                 som_json_str_or(op, "value"));
    } else if (strcmp(op_name, "headline") == 0) {
      const char *val =
          spec_document_headline(&doc, som_json_str_or(op, "path"));
      const SomJson *e = som_json_get(op, "expect");
      const char *exp = som_json_as_str(e);
      if (exp == NULL) {
        check(c, tag, val == NULL, "expected unset");
      } else {
        check(c, tag, val != NULL && strcmp(val, exp) == 0, val ? val : "");
      }
    } else if (strcmp(op_name, "hasValuesUnder") == 0) {
      int exp = som_json_bool_or(op, "expect");
      check(c, tag,
            spec_document_has_values_under(&doc, som_json_str_or(op, "prefix")) == exp,
            "");
    } else if (strcmp(op_name, "removeListItem") == 0) {
      int exp = som_json_bool_or(op, "expect");
      check(c, tag,
            spec_document_remove_list_item(&doc, som_json_str_or(op, "itemPath")) == exp,
            "");
    } else {
      char t2[600];
      snprintf(t2, sizeof(t2), "%s.unknown", tag);
      check(c, t2, 0, op_name);
    }
  }
  som_json_free(cases);
  spec_document_free(&doc);
}

/* ---- section-id conformance (AA1 criteria 3–6) -------------------------- */

static void test_section_id(Checker *c) {
  SomJson *cases = read_json("section_id_cases.json");

  /* Criterion 4: the two-letter day code. */
  const SomJson *tld = som_json_get(cases, "twoLetterDate");
  size_t tn = som_json_array_len(tld);
  for (size_t i = 0; i < tn; i++) {
    const SomJson *tc = som_json_array_at(tld, i);
    long long month = 0, day = 0;
    som_json_as_i64(som_json_get(tc, "month"), &month);
    som_json_as_i64(som_json_get(tc, "day"), &day);
    const char *expect = som_json_str_or(tc, "expect");
    char *got = spec_encode_two_letter_date(month, day);
    char tag[128], detail[256];
    snprintf(tag, sizeof(tag), "sectionId.twoLetterDate[%lld/%lld]", month, day);
    snprintf(detail, sizeof(detail), "%s != %s", got, expect);
    check(c, tag, strcmp(got, expect) == 0, detail);
    free(got);
  }

  /* Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1). */
  const SomJson *gen = som_json_get(cases, "generate");
  size_t gn = som_json_array_len(gen);
  for (size_t i = 0; i < gn; i++) {
    const SomJson *tc = som_json_array_at(gen, i);
    const char *pattern = som_json_str_or(tc, "pattern");
    long long month = 0, day = 0;
    som_json_as_i64(som_json_get(tc, "month"), &month);
    som_json_as_i64(som_json_get(tc, "day"), &day);
    SomStrList existing;
    json_str_list(som_json_get(tc, "existing"), &existing);
    const char *expect = som_json_str_or(tc, "expect");
    char *got =
        spec_generate_list_item_section_id(pattern, month, day, &existing);
    char tag[256], detail[512];
    snprintf(tag, sizeof(tag), "sectionId.generate[%s]", pattern);
    snprintf(detail, sizeof(detail), "%s != %s", got, expect);
    check(c, tag, strcmp(got, expect) == 0, detail);
    free(got);
    som_strlist_free(&existing);
  }

  /* Criteria 5 & 6 at the document level. */
  SpecDocument doc;
  spec_document_init(&doc);
  const SomJson *ops = som_json_get(cases, "documentOps");
  size_t on = som_json_array_len(ops);
  for (size_t i = 0; i < on; i++) {
    const SomJson *s = som_json_array_at(ops, i);
    const char *op = som_json_str_or(s, "op");
    char tag[256];
    snprintf(tag, sizeof(tag), "sectionId.op[%zu].%s", i, op);
    if (strcmp(op, "addGen") == 0) {
      const char *list_path = som_json_str_or(s, "listPath");
      const char *pattern = som_json_str_or(s, "pattern");
      long long month = 0, day = 0;
      som_json_as_i64(som_json_get(s, "month"), &month);
      som_json_as_i64(som_json_get(s, "day"), &day);
      const char *expect_id = som_json_str_or(s, "expectId");
      const char *expect_path = som_json_str_or(s, "expectPath");
      SomStrList existing;
      spec_document_list_item_section_ids(&doc, list_path, &existing);
      char *gen_id =
          spec_generate_list_item_section_id(pattern, month, day, &existing);
      som_strlist_free(&existing);
      char idtag[288], iddetail[512];
      snprintf(idtag, sizeof(idtag), "%s.id", tag);
      snprintf(iddetail, sizeof(iddetail), "%s != %s", gen_id, expect_id);
      check(c, idtag, strcmp(gen_id, expect_id) == 0, iddetail);
      SpecSectionIdError err;
      spec_section_id_error_init(&err);
      char *path = spec_document_add_list_item_with_section_id(&doc, list_path,
                                                               gen_id, &err);
      char ptag[288];
      snprintf(ptag, sizeof(ptag), "%s.path", tag);
      if (path == NULL) {
        check(c, ptag, 0, "unexpected add failure");
      } else {
        char pdetail[512];
        snprintf(pdetail, sizeof(pdetail), "%s != %s", path, expect_path);
        check(c, ptag, strcmp(path, expect_path) == 0, pdetail);
        free(path);
      }
      spec_section_id_error_free(&err);
      free(gen_id);
    } else if (strcmp(op, "sectionIds") == 0) {
      SomStrList exp;
      json_str_list(som_json_get(s, "expect"), &exp);
      SomStrList got;
      spec_document_list_item_section_ids(&doc, som_json_str_or(s, "listPath"),
                                          &got);
      char *gj = som_strlist_join(&got, ",");
      check(c, tag, strlist_eq(&got, &exp), gj);
      free(gj);
      som_strlist_free(&got);
      som_strlist_free(&exp);
    } else if (strcmp(op, "removeListItem") == 0) {
      int exp = som_json_bool_or(s, "expect");
      check(c, tag,
            spec_document_remove_list_item(&doc, som_json_str_or(s, "itemPath")) ==
                exp,
            "");
    } else if (strcmp(op, "override") == 0) {
      SpecSectionIdError err;
      spec_section_id_error_init(&err);
      int ok = spec_document_set_item_section_id(
          &doc, som_json_str_or(s, "itemPath"), som_json_str_or(s, "id"), &err);
      check(c, tag, ok, "unexpected error");
      spec_section_id_error_free(&err);
    } else if (strcmp(op, "overrideThrows") == 0) {
      SpecSectionIdError err;
      spec_section_id_error_init(&err);
      int ok = spec_document_set_item_section_id(
          &doc, som_json_str_or(s, "itemPath"), som_json_str_or(s, "id"), &err);
      check(c, tag, !ok && spec_section_id_is_collision(&err),
            "expected collision");
      spec_section_id_error_free(&err);
    } else if (strcmp(op, "addExplicitThrows") == 0) {
      SpecSectionIdError err;
      spec_section_id_error_init(&err);
      char *path = spec_document_add_list_item_with_section_id(
          &doc, som_json_str_or(s, "listPath"), som_json_str_or(s, "id"), &err);
      check(c, tag, path == NULL && spec_section_id_is_collision(&err),
            "expected collision");
      free(path);
      spec_section_id_error_free(&err);
    } else {
      char t2[300];
      snprintf(t2, sizeof(t2), "%s.unknown", tag);
      check(c, t2, 0, op);
    }
  }
  spec_document_free(&doc);
  som_json_free(cases);
}

/* ---- serialization-order conformance (AA1 criterion 7) ------------------ */

static void test_serialization_order(Checker *c) {
  SomJson *cases = read_json("serialization_order_cases.json");
  SpecModel *model = spec_model_from_json(som_json_get(cases, "model"));
  SpecSerializationOrder order = spec_serialization_order_make(model);

  SomStrList content_paths, expected_order, got_paths;
  json_str_list(som_json_get(cases, "contentPaths"), &content_paths);
  json_str_list(som_json_get(cases, "expectedOrder"), &expected_order);
  spec_serialization_order_paths(&order, &content_paths, &got_paths);
  char *gj = som_strlist_join(&got_paths, ",");
  char *ej = som_strlist_join(&expected_order, ",");
  char detail[1024];
  snprintf(detail, sizeof(detail), "%s != %s", gj, ej);
  check(c, "serialOrder.orderPaths", strlist_eq(&got_paths, &expected_order),
        detail);
  free(gj);
  free(ej);
  som_strlist_free(&content_paths);
  som_strlist_free(&expected_order);
  som_strlist_free(&got_paths);

  SomStrList form_fields, expected_form_order, got_fields;
  json_str_list(som_json_get(cases, "formFields"), &form_fields);
  json_str_list(som_json_get(cases, "expectedFormOrder"), &expected_form_order);
  spec_serialization_order_form_fields(&order, som_json_str_or(cases, "formPath"),
                                       &form_fields, &got_fields);
  char *gf = som_strlist_join(&got_fields, ",");
  char *ef = som_strlist_join(&expected_form_order, ",");
  char fdetail[1024];
  snprintf(fdetail, sizeof(fdetail), "%s != %s", gf, ef);
  check(c, "serialOrder.orderFormFields",
        strlist_eq(&got_fields, &expected_form_order), fdetail);
  free(gf);
  free(ef);
  som_strlist_free(&form_fields);
  som_strlist_free(&expected_form_order);
  som_strlist_free(&got_fields);

  spec_model_free(model);
  som_json_free(cases);
}

/* The SOM §14 DocSpecs tier: one shared schema, one case per violation rule.
 *
 * The corpus carries the rule/sectionId/line triples the Dart reference
 * produces; matching them is what proves this port implements each rule at all,
 * rather than merely declaring its name. `som_json_str_or` yields "" for the
 * corpus's JSON null, which is exactly this port's absent-section-id value. */
static void test_docspecs(Checker *c) {
  char *yaml = read_corpus("docspecs_schema.yaml");
  DocSpecsSchema *schema = NULL;
  char *serr = NULL;
  if (!docspecs_schema_from_yaml_text(yaml, &schema, &serr)) {
    fprintf(stderr, "docspecs schema: %s\n", serr ? serr : "(no message)");
    exit(2);
  }
  free(yaml);
  check(c, "docspecs.schemaWarnings", schema->warnings.len == 0, "");
  char *root_id = docspecs_schema_root_section_id(schema);
  check(c, "docspecs.rootSectionId", strcmp(root_id, "D00") == 0, root_id);
  free(root_id);

  DocSpecsValidator val = docspecs_validator_new(schema);
  SomJson *cases = read_json("docspecs_cases.json");
  int covered[DOCSPECS_ALL_RULES_COUNT] = {0};
  size_t n = som_json_array_len(cases);
  for (size_t i = 0; i < n; i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    const char *name = som_json_str_or(cc, "name");

    DocSpecsViolationList got_list;
    docspecs_violation_list_init(&got_list);
    docspecs_validator_validate_markdown(&val, som_json_str_or(cc, "markdown"),
                                         &got_list);
    /* "rule|sectionId|line" joined by '/' — one string per side, so a length
     * mismatch is as visible as a value mismatch. */
    SomBuf got;
    som_buf_init(&got);
    for (size_t k = 0; k < got_list.len; k++) {
      if (k > 0) som_buf_putc(&got, '/');
      char *line = som_format_i64(got_list.items[k].line);
      som_buf_puts(&got, got_list.items[k].rule);
      som_buf_putc(&got, '|');
      som_buf_puts(&got, got_list.items[k].section_id);
      som_buf_putc(&got, '|');
      som_buf_puts(&got, line);
      free(line);
    }
    char *got_s = som_buf_take(&got);
    docspecs_violation_list_free(&got_list);

    SomBuf want;
    som_buf_init(&want);
    const SomJson *warr = som_json_get(cc, "violations");
    size_t wlen = som_json_array_len(warr);
    for (size_t k = 0; k < wlen; k++) {
      const SomJson *wv = som_json_array_at(warr, k);
      const char *rule = som_json_str_or(wv, "rule");
      for (size_t r = 0; r < DOCSPECS_ALL_RULES_COUNT; r++) {
        if (strcmp(rule, DOCSPECS_ALL_RULES[r]) == 0) covered[r] = 1;
      }
      long long line_no = 0;
      som_json_as_i64(som_json_get(wv, "line"), &line_no);
      char *line = som_format_i64(line_no);
      if (k > 0) som_buf_putc(&want, '/');
      som_buf_puts(&want, rule);
      som_buf_putc(&want, '|');
      som_buf_puts(&want, som_json_str_or(wv, "sectionId"));
      som_buf_putc(&want, '|');
      som_buf_puts(&want, line);
      free(line);
    }
    char *want_s = som_buf_take(&want);

    char tag[512], detail[4096];
    snprintf(tag, sizeof(tag), "docspecs[%s]", name);
    snprintf(detail, sizeof(detail), "%s != %s", got_s, want_s);
    check(c, tag, strcmp(got_s, want_s) == 0, detail);
    free(got_s);
    free(want_s);
  }

  SomBuf uncovered;
  som_buf_init(&uncovered);
  for (size_t r = 0; r < DOCSPECS_ALL_RULES_COUNT; r++) {
    if (covered[r]) continue;
    if (uncovered.len > 0) som_buf_putc(&uncovered, ',');
    som_buf_puts(&uncovered, DOCSPECS_ALL_RULES[r]);
  }
  char *uncovered_s = som_buf_take(&uncovered);
  char cov_detail[1024];
  snprintf(cov_detail, sizeof(cov_detail), "uncovered: %s", uncovered_s);
  check(c, "docspecs.ruleCoverage", uncovered_s[0] == '\0', cov_detail);
  free(uncovered_s);

  som_json_free(cases);
  docspecs_schema_free(schema);
}

/* ---- the query surfaces (llm_and_d4rt_tools.md §5–6, SOM §9/§15) -------- */

/* The fixture document every query/creation group starts from — the same one
 * the Dart reference's `_buildDocument()` produces, which is exactly what
 * `state.json` records (list sequence counters included), so re-loading it is a
 * genuinely fresh build and not a replay of an earlier group's mutations.
 * `spec_document_load_json` copies, so the JSON behind it is released here. */
static void fresh_document(SpecDocument *doc) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  doc_from_state(doc, &state);
  document_json_free(&state);
  som_json_free(sj);
}

/* Null and the empty string are different answers here — an absent headline is
 * not a blank one — so they must not both render as "". This port spells the
 * other ports' `null` as `""`, so the marker stands in for both. */
static const char *const K_NULL_TEXT = "<null>";

static const char *opt_text(const char *v) {
  return (v == NULL || v[0] == '\0') ? K_NULL_TEXT : v;
}

static const char *json_opt_text(const SomJson *v) {
  const char *s = som_json_as_str(v);
  return s == NULL ? K_NULL_TEXT : s;
}

/* `start-end,start-end, …` — one string per side, so an extra, missing or
 * reordered span is as visible as a wrong offset. Owned result. */
static char *spans_text(const SpecMatchSpanList *spans) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < spans->len; i++) {
    if (i > 0) som_buf_putc(&b, ',');
    char *s = som_format_i64(spans->items[i].start);
    char *e = som_format_i64(spans->items[i].end);
    som_buf_puts(&b, s);
    som_buf_putc(&b, '-');
    som_buf_puts(&b, e);
    free(s);
    free(e);
  }
  return som_buf_take(&b);
}

/* The corpus writes spans as `[[start, end], …]`. */
static char *json_spans_text(const SomJson *arr) {
  SomBuf b;
  som_buf_init(&b);
  size_t n = som_json_array_len(arr);
  for (size_t i = 0; i < n; i++) {
    const SomJson *pair = som_json_array_at(arr, i);
    long long s = -1, e = -1;
    som_json_as_i64(som_json_array_at(pair, 0), &s);
    som_json_as_i64(som_json_array_at(pair, 1), &e);
    if (i > 0) som_buf_putc(&b, ',');
    char *ss = som_format_i64(s);
    char *es = som_format_i64(e);
    som_buf_puts(&b, ss);
    som_buf_putc(&b, '-');
    som_buf_puts(&b, es);
    free(ss);
    free(es);
  }
  return som_buf_take(&b);
}

/* SOM §9's portable pattern subset: every match case's spans, and every
 * rejection case's refusal to compile at all. `regex: false` exercises the
 * literal constructor, where `.` `*` `[` are plain characters. */
static void test_text_pattern(Checker *c) {
  SomJson *cases = read_json("pattern_cases.json");
  size_t n = som_json_array_len(cases);
  size_t match_cases = 0, rejection_cases = 0, literal_cases = 0;

  for (size_t i = 0; i < n; i++) {
    const SomJson *k = som_json_array_at(cases, i);
    const char *source = som_json_str_or(k, "pattern");
    int regex = som_json_bool_or(k, "regex");
    int case_insensitive = som_json_bool_or(k, "caseInsensitive");
    char *shown = som_json_encode_str(source);
    char tag[1024];
    snprintf(tag, sizeof(tag), "pattern[%zu] %s", i, shown);
    free(shown);

    SomPatternError perr;
    som_pattern_error_init(&perr);
    SomTextPattern pattern;

    if (som_json_bool_or(k, "error")) {
      rejection_cases++;
      /* A malformed pattern must fail *at compile*, not match nothing later. */
      char t[1100];
      snprintf(t, sizeof(t), "%s.rejected", tag);
      if (spec_text_pattern_compile(&pattern, source, case_insensitive, &perr)) {
        check(c, t, 0, "compiled without error");
        spec_text_pattern_free(&pattern);
      } else {
        check(c, t, perr.pattern != NULL && strcmp(perr.pattern, source) == 0,
              perr.pattern != NULL ? perr.pattern : "(no pattern)");
      }
      som_pattern_error_free(&perr);
      continue;
    }

    match_cases++;
    if (regex) {
      char t[1100];
      snprintf(t, sizeof(t), "%s.compiles", tag);
      if (!spec_text_pattern_compile(&pattern, source, case_insensitive,
                                     &perr)) {
        check(c, t, 0, perr.message != NULL ? perr.message : "(no message)");
        som_pattern_error_free(&perr);
        continue;
      }
    } else {
      literal_cases++;
      spec_text_pattern_literal(&pattern, source, case_insensitive);
    }
    som_pattern_error_free(&perr);

    const char *text = som_json_str_or(k, "text");
    SpecMatchSpanList spans;
    spec_match_span_list_init(&spans);
    spec_text_pattern_all_matches(&pattern, text, &spans);
    char *got = spans_text(&spans);
    char *want = json_spans_text(som_json_get(k, "spans"));
    char t[1100], detail[2048];
    snprintf(t, sizeof(t), "%s.spans", tag);
    snprintf(detail, sizeof(detail), "%s != %s", got, want);
    check(c, t, strcmp(got, want) == 0, detail);
    snprintf(t, sizeof(t), "%s.hasMatch", tag);
    check(c, t, spec_text_pattern_has_match(&pattern, text) == (want[0] != '\0'),
          "");
    free(got);
    free(want);
    spec_match_span_list_free(&spans);
    spec_text_pattern_free(&pattern);
  }

  /* A table of only-matches (or only-rejections) would leave half the contract
   * unexercised while still reporting green. */
  char detail[64];
  snprintf(detail, sizeof(detail), "%zu", match_cases);
  check(c, "pattern.hasMatchCases", match_cases > 0, detail);
  snprintf(detail, sizeof(detail), "%zu", rejection_cases);
  check(c, "pattern.hasRejectionCases", rejection_cases > 0, detail);
  snprintf(detail, sizeof(detail), "%zu", literal_cases);
  check(c, "pattern.hasLiteralCases", literal_cases > 0, detail);

  som_json_free(cases);
}

/* Decodes one corpus query. An **absent** key leaves the dimension unset — it
 * must never become a default that happens to match, which is why every string
 * dimension is read through `som_json_as_str(som_json_get(...))` (NULL when
 * absent) rather than through `som_json_str_or` (which would yield `""`, a
 * meaningful "set to empty").
 *
 * The query *borrows*: its strings point into the parsed corpus JSON and its
 * `kinds` at the caller-owned `*kinds` (always initialised, so the caller frees
 * it unconditionally). Both must outlive every cursor built from `*out`. */
static void query_from_json(const SomJson *q, SpecQuery *out,
                            SomStrList *kinds) {
  spec_query_init(out);
  som_strlist_init(kinds);
  if (q == NULL) {
    return;
  }
  out->text = som_json_as_str(som_json_get(q, "text"));
  out->regex = som_json_bool_or(q, "regex");
  out->case_insensitive = som_json_bool_or(q, "caseInsensitive");
  const SomJson *ks = som_json_get(q, "kinds");
  if (ks != NULL && ks->type == SOM_JSON_ARRAY) {
    json_str_list(ks, kinds);
    out->kinds = kinds;
  }
  out->class_name = som_json_as_str(som_json_get(q, "className"));
  out->section_id_exact = som_json_as_str(som_json_get(q, "sectionIdExact"));
  out->section_id_prefix = som_json_as_str(som_json_get(q, "sectionIdPrefix"));
  out->path_glob = som_json_as_str(som_json_get(q, "pathGlob"));
  out->maps_to = som_json_as_str(som_json_get(q, "mapsTo"));
  out->detailed_in = som_json_as_str(som_json_get(q, "detailedIn"));
  const char *state = som_json_as_str(som_json_get(q, "state"));
  if (state != NULL) {
    if (!spec_state_filter_parse(state, &out->state)) {
      fprintf(stderr, "corpus query: unknown state filter \"%s\"\n", state);
      exit(2);
    }
    out->has_state = 1;
  }
}

/* One match rendered as a single line, so an extra/missing/reordered match is
 * as visible as a wrong field. Owned result. */
static char *match_text(const SpecQueryMatch *m) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, m->path);
  som_buf_putc(&b, '|');
  som_buf_puts(&b, m->kind);
  som_buf_putc(&b, '|');
  som_buf_puts(&b, opt_text(m->class_id));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, opt_text(m->headline));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, opt_text(m->snippet));
  som_buf_putc(&b, '|');
  char *sp = spans_text(&m->spans);
  som_buf_puts(&b, sp);
  free(sp);
  return som_buf_take(&b);
}

static char *json_match_text(const SomJson *m) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, som_json_str_or(m, "path"));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, som_json_str_or(m, "kind"));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, json_opt_text(som_json_get(m, "classId")));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, json_opt_text(som_json_get(m, "headline")));
  som_buf_putc(&b, '|');
  som_buf_puts(&b, json_opt_text(som_json_get(m, "snippet")));
  som_buf_putc(&b, '|');
  char *sp = json_spans_text(som_json_get(m, "spans"));
  som_buf_puts(&b, sp);
  free(sp);
  return som_buf_take(&b);
}

/* Drains `cur` into `out` (initialised by the callee) as one line per match. */
static void drain_match_lines(SpecQueryCursor *cur, SomStrList *out) {
  som_strlist_init(out);
  SpecQueryMatchList matches;
  spec_query_match_list_init(&matches);
  spec_query_cursor_to_list(cur, &matches);
  for (size_t i = 0; i < matches.len; i++) {
    char *line = match_text(&matches.items[i]);
    som_strlist_push_copy(out, line);
    free(line);
  }
  spec_query_match_list_free(&matches);
}

/* The AND-combined query surface: every dimension, alone and in combination,
 * replayed against a freshly-built fixture. Match **order** is part of the
 * contract (document order), so the drained cursor is compared as an ordered
 * list. `count` is asserted separately on a second cursor: it must agree with
 * the number of committed matches while consuming nothing. */
static void test_query(Checker *c, const SpecModel *model) {
  SpecDocument doc;
  fresh_document(&doc);
  SpecQueryEngine engine = spec_query_engine_make(model, &doc);
  SomJson *cases = read_json("query_cases.json");
  size_t n = som_json_array_len(cases);

  for (size_t i = 0; i < n; i++) {
    const SomJson *k = som_json_array_at(cases, i);
    char tag[512];
    snprintf(tag, sizeof(tag), "query[%s]", som_json_str_or(k, "name"));

    SpecQuery q;
    SomStrList kinds;
    query_from_json(som_json_get(k, "query"), &q, &kinds);

    SomPatternError perr;
    som_pattern_error_init(&perr);
    SpecQueryCursor cur;
    if (!spec_query_engine_query(&engine, &q, &cur, &perr)) {
      check(c, tag, 0, perr.message != NULL ? perr.message : "pattern refused");
      som_pattern_error_free(&perr);
      som_strlist_free(&kinds);
      continue;
    }
    som_pattern_error_free(&perr);

    SomStrList got;
    drain_match_lines(&cur, &got);
    spec_query_cursor_free(&cur);

    SomStrList want;
    som_strlist_init(&want);
    const SomJson *arr = som_json_get(k, "matches");
    size_t wn = som_json_array_len(arr);
    for (size_t j = 0; j < wn; j++) {
      char *line = json_match_text(som_json_array_at(arr, j));
      som_strlist_push_copy(&want, line);
      free(line);
    }

    char *gj = som_strlist_join(&got, " ~ ");
    char *wj = som_strlist_join(&want, " ~ ");
    char detail[4096];
    snprintf(detail, sizeof(detail), "%s != %s", gj, wj);
    check(c, tag, strlist_eq(&got, &want), detail);
    free(gj);
    free(wj);

    /* A fresh cursor: count must see the same matches without consuming them. */
    if (spec_query_engine_query(&engine, &q, &cur, NULL)) {
      size_t cnt = spec_query_cursor_count(&cur);
      char ctag[544], cdetail[128];
      snprintf(ctag, sizeof(ctag), "%s.count", tag);
      snprintf(cdetail, sizeof(cdetail), "%zu != %zu", cnt, want.len);
      check(c, ctag, cnt == want.len, cdetail);
      spec_query_cursor_free(&cur);
    }

    som_strlist_free(&got);
    som_strlist_free(&want);
    som_strlist_free(&kinds);
  }

  som_json_free(cases);
  spec_document_free(&doc);
}

/* The tier-1 index source: the full project-nodes walk in document order. */
static void test_projection(Checker *c, const SpecModel *model) {
  SpecDocument doc;
  fresh_document(&doc);
  SpecQueryEngine engine = spec_query_engine_make(model, &doc);
  SomJson *cases = read_json("projection_cases.json");
  size_t n = som_json_array_len(cases);

  SpecNodeProjectionList got;
  spec_query_engine_project_nodes(&engine, &got);
  char cdetail[64];
  snprintf(cdetail, sizeof(cdetail), "%zu != %zu", got.len, n);
  check(c, "projection.count", got.len == n, cdetail);

  size_t limit = got.len < n ? got.len : n;
  for (size_t i = 0; i < limit; i++) {
    const SomJson *w = som_json_array_at(cases, i);
    const SpecNodeProjection *p = &got.items[i];
    char tag[640], t[704], detail[2048];
    snprintf(tag, sizeof(tag), "projection[%zu] %s", i, p->path);

    struct {
      const char *field;
      const char *got;
      const char *want;
    } strs[] = {
        {"path", p->path, som_json_str_or(w, "path")},
        {"kind", p->kind, som_json_str_or(w, "kind")},
        {"classId", opt_text(p->class_id),
         json_opt_text(som_json_get(w, "classId"))},
        {"sectionId", opt_text(p->section_id),
         json_opt_text(som_json_get(w, "sectionId"))},
        {"mapsTo", opt_text(p->maps_to),
         json_opt_text(som_json_get(w, "mapsTo"))},
        {"detailedIn", opt_text(p->detailed_in),
         json_opt_text(som_json_get(w, "detailedIn"))},
        {"headline", opt_text(p->headline),
         json_opt_text(som_json_get(w, "headline"))},
    };
    for (size_t f = 0; f < sizeof(strs) / sizeof(strs[0]); f++) {
      snprintf(t, sizeof(t), "%s.%s", tag, strs[f].field);
      snprintf(detail, sizeof(detail), "%s != %s", strs[f].got, strs[f].want);
      check(c, t, strcmp(strs[f].got, strs[f].want) == 0, detail);
    }

    SomStrList want_strings;
    json_str_list(som_json_get(w, "searchableStrings"), &want_strings);
    char *gj = som_strlist_join(&p->searchable_strings, " ~ ");
    char *wj = som_strlist_join(&want_strings, " ~ ");
    snprintf(t, sizeof(t), "%s.searchableStrings", tag);
    snprintf(detail, sizeof(detail), "%s != %s", gj, wj);
    check(c, t, strlist_eq(&p->searchable_strings, &want_strings), detail);
    free(gj);
    free(wj);
    som_strlist_free(&want_strings);

    snprintf(t, sizeof(t), "%s.hasValue", tag);
    check(c, t, p->has_value == som_json_bool_or(w, "hasValue"),
          p->has_value ? "true" : "false");
  }

  /* project-node must agree with the walk for every path it visited. */
  for (size_t i = 0; i < got.len; i++) {
    const SpecNodeProjection *p = &got.items[i];
    SpecNodeProjection one;
    int ok = spec_query_engine_project_node(&engine, p->path, &one);
    char tag[640];
    snprintf(tag, sizeof(tag), "projection.single %s", p->path);
    check(c, tag,
          ok && strcmp(one.kind, p->kind) == 0 &&
              strlist_eq(&one.searchable_strings, &p->searchable_strings),
          p->path);
    if (ok) {
      spec_node_projection_free(&one);
    }
  }

  spec_node_projection_list_free(&got);
  som_json_free(cases);
  spec_document_free(&doc);
}

/* The cursor's laziness and its view of a **mutating** document: the script
 * removes a list item between opening a cursor and draining it, and the removed
 * item must not surface. */
static void test_cursor(Checker *c, const SpecModel *model) {
  SpecDocument doc;
  fresh_document(&doc);
  SpecQueryEngine engine = spec_query_engine_make(model, &doc);
  SomJson *steps = read_json("cursor_cases.json");
  size_t n = som_json_array_len(steps);

  /* The open cursor and the state it borrows: the query's strings point into
   * `steps`, its kinds at `kinds`, so both outlive every cursor here. */
  SpecQuery q;
  SomStrList kinds;
  som_strlist_init(&kinds);
  SpecQueryCursor cur;
  int open = 0;

  for (size_t i = 0; i < n; i++) {
    const SomJson *s = som_json_array_at(steps, i);
    const char *op = som_json_str_or(s, "op");
    char tag[512], detail[2048];
    snprintf(tag, sizeof(tag), "cursor[%zu].%s", i, op);

    if (strcmp(op, "open") == 0) {
      if (open) {
        spec_query_cursor_free(&cur);
        open = 0;
      }
      som_strlist_free(&kinds);
      query_from_json(som_json_get(s, "query"), &q, &kinds);
      SomPatternError perr;
      som_pattern_error_init(&perr);
      open = spec_query_engine_query(&engine, &q, &cur, &perr);
      check(c, tag, open,
            perr.message != NULL ? perr.message : "pattern refused");
      som_pattern_error_free(&perr);
    } else if (strcmp(op, "count") == 0) {
      long long want = -1;
      som_json_as_i64(som_json_get(s, "expect"), &want);
      long long gotc = open ? (long long)spec_query_cursor_count(&cur) : -1;
      snprintf(detail, sizeof(detail), "%lld != %lld", gotc, want);
      check(c, tag, gotc == want, detail);
    } else if (strcmp(op, "take") == 0 || strcmp(op, "toList") == 0) {
      SpecQueryMatchList matches;
      spec_query_match_list_init(&matches);
      if (open) {
        if (strcmp(op, "take") == 0) {
          long long take = 0;
          som_json_as_i64(som_json_get(s, "n"), &take);
          spec_query_cursor_take(&cur, take < 0 ? 0 : (size_t)take, &matches);
        } else {
          spec_query_cursor_to_list(&cur, &matches);
        }
      }
      SomStrList gotp;
      som_strlist_init(&gotp);
      for (size_t j = 0; j < matches.len; j++) {
        som_strlist_push_copy(&gotp, matches.items[j].path);
      }
      spec_query_match_list_free(&matches);
      SomStrList wantp;
      json_str_list(som_json_get(s, "expect"), &wantp);
      char *gj = som_strlist_join(&gotp, ",");
      char *wj = som_strlist_join(&wantp, ",");
      snprintf(detail, sizeof(detail), "%s != %s", gj, wj);
      check(c, tag, strlist_eq(&gotp, &wantp), detail);
      free(gj);
      free(wj);
      som_strlist_free(&gotp);
      som_strlist_free(&wantp);
    } else if (strcmp(op, "next") == 0) {
      SpecQueryMatch m;
      int has = open ? spec_query_cursor_next(&cur, &m) : 0;
      const char *gotp = has ? m.path : K_NULL_TEXT;
      const char *wantp = json_opt_text(som_json_get(s, "expect"));
      snprintf(detail, sizeof(detail), "%s != %s", gotp, wantp);
      check(c, tag, strcmp(gotp, wantp) == 0, detail);
      if (has) {
        spec_query_match_free(&m);
      }
    } else if (strcmp(op, "removeListItem") == 0) {
      const char *item_path = som_json_str_or(s, "itemPath");
      char t[544];
      snprintf(t, sizeof(t), "%s %s", tag, item_path);
      check(c, t, spec_document_remove_list_item(&doc, item_path), item_path);
    } else {
      char t2[544];
      snprintf(t2, sizeof(t2), "%s.unknown", tag);
      check(c, t2, 0, op);
    }
  }

  if (open) {
    spec_query_cursor_free(&cur);
  }
  som_strlist_free(&kinds);
  som_json_free(steps);
  spec_document_free(&doc);
}

/* llm_and_d4rt_tools.md §5: the stateless rule check. Every probe runs against a
 * *freshly built* document, so an accepted add in one case cannot change the
 * verdict of the next. A rejection is asserted on its code and the pair it names
 * — not on the message text, which is prose and not part of the contract. */
static void test_node_creation_cases(Checker *c, const SpecModel *model) {
  SomJson *cases = read_json("node_creation_cases.json");
  size_t n = som_json_array_len(cases);
  int covered[SPEC_CREATION_ALL_CODES_COUNT] = {0};

  for (size_t i = 0; i < n; i++) {
    const SomJson *k = som_json_array_at(cases, i);
    const char *name = som_json_str_or(k, "name");
    const char *parent_path = som_json_str_or(k, "parentPath");
    const char *child_segment = som_json_str_or(k, "childSegment");
    /* An absent `itemId` is "no id proposed", not the empty id. */
    const char *item_id = som_json_as_str(som_json_get(k, "itemId"));

    SpecDocument doc;
    fresh_document(&doc);
    SpecCreationError err;
    spec_check_add_node(model, &doc, parent_path, child_segment, item_id, &err);
    spec_document_free(&doc);

    int accepted = som_json_bool_or(k, "accepted");
    int ok = spec_creation_error_is_ok(&err);
    char tag[512], detail[1024];
    char *shown = ok ? som_strdup("accepted") : spec_creation_error_string(&err);
    snprintf(tag, sizeof(tag), "nodeCreation[%s].accepted", name);
    check(c, tag, ok == accepted, shown);
    free(shown);
    if (accepted || ok) {
      spec_creation_error_free(&err);
      continue;
    }

    const char *want_code = som_json_str_or(k, "code");
    const char *got_code = spec_creation_code_name(err.code);
    for (size_t r = 0; r < SPEC_CREATION_ALL_CODES_COUNT; r++) {
      if (strcmp(spec_creation_code_name(SPEC_CREATION_ALL_CODES[r]),
                 want_code) == 0) {
        covered[r] = 1;
      }
    }
    snprintf(tag, sizeof(tag), "nodeCreation[%s].code", name);
    snprintf(detail, sizeof(detail), "%s != %s", got_code, want_code);
    check(c, tag, strcmp(got_code, want_code) == 0, detail);
    snprintf(tag, sizeof(tag), "nodeCreation[%s].parentPath", name);
    check(c, tag,
          err.parent_path != NULL && strcmp(err.parent_path, parent_path) == 0,
          err.parent_path != NULL ? err.parent_path : "");
    snprintf(tag, sizeof(tag), "nodeCreation[%s].childSegment", name);
    check(c, tag,
          err.child_segment != NULL &&
              strcmp(err.child_segment, child_segment) == 0,
          err.child_segment != NULL ? err.child_segment : "");
    spec_creation_error_free(&err);
  }

  SomBuf uncovered;
  som_buf_init(&uncovered);
  for (size_t r = 0; r < SPEC_CREATION_ALL_CODES_COUNT; r++) {
    if (covered[r]) continue;
    if (uncovered.len > 0) som_buf_putc(&uncovered, ',');
    som_buf_puts(&uncovered, spec_creation_code_name(SPEC_CREATION_ALL_CODES[r]));
  }
  char *uncovered_s = som_buf_take(&uncovered);
  char cov_detail[512];
  snprintf(cov_detail, sizeof(cov_detail), "uncovered: %s", uncovered_s);
  check(c, "nodeCreation.codeCoverage", uncovered_s[0] == '\0', cov_detail);
  free(uncovered_s);

  som_json_free(cases);
}

/* The stateful companion: one document, each add building on the last, then the
 * whole document state compared as canonical JSON. */
static void test_node_creation_script(Checker *c, const SpecModel *model) {
  SpecDocument doc;
  fresh_document(&doc);
  SpecNodeCreator creator = spec_node_creator_make(model, &doc);
  SomJson *steps = read_json("node_creation_script.json");
  size_t n = som_json_array_len(steps);

  for (size_t i = 0; i < n; i++) {
    const SomJson *s = som_json_array_at(steps, i);
    const char *op = som_json_str_or(s, "op");
    char tag[512], detail[2048];
    snprintf(tag, sizeof(tag), "nodeScript[%zu].%s", i, op);

    if (strcmp(op, "add") == 0 || strcmp(op, "addThrows") == 0) {
      const char *parent_path = som_json_str_or(s, "parentPath");
      const char *child_segment = som_json_str_or(s, "childSegment");
      const char *item_id = som_json_as_str(som_json_get(s, "itemId"));
      /* `addThrows` names no date: the gate rejects before an id is minted, so
       * any valid date does — the corpus's own 2026-03-04. */
      long long month = 3, day = 4;
      som_json_as_i64(som_json_get(s, "month"), &month);
      som_json_as_i64(som_json_get(s, "day"), &day);

      char *path = NULL;
      SpecCreationError err;
      spec_creation_error_init(&err);
      int ok = spec_node_creator_add(&creator, parent_path, child_segment,
                                     item_id, month, day, &path, &err);

      if (strcmp(op, "addThrows") == 0) {
        const char *want_code = som_json_str_or(s, "expectCode");
        const char *got_code = spec_creation_code_name(err.code);
        snprintf(detail, sizeof(detail), "%s != %s",
                 ok ? "(accepted)" : got_code, want_code);
        check(c, tag, !ok && strcmp(got_code, want_code) == 0, detail);
      } else {
        char t[544];
        snprintf(t, sizeof(t), "%s.path", tag);
        const char *want_path = som_json_str_or(s, "expectPath");
        snprintf(detail, sizeof(detail), "%s != %s",
                 path != NULL ? path : "(rejected)", want_path);
        check(c, t, ok && path != NULL && strcmp(path, want_path) == 0, detail);
        if (ok && path != NULL) {
          snprintf(t, sizeof(t), "%s.id", tag);
          const char *got_id = opt_text(spec_document_item_section_id(&doc, path));
          const char *want_id = json_opt_text(som_json_get(s, "expectId"));
          snprintf(detail, sizeof(detail), "%s != %s", got_id, want_id);
          check(c, t, strcmp(got_id, want_id) == 0, detail);
        }
      }
      free(path);
      spec_creation_error_free(&err);
    } else if (strcmp(op, "finalState") == 0) {
      DocumentJson dj;
      spec_document_to_json(&doc, &dj);
      char *got = document_json_to_canonical_json(&dj);
      DocumentJson want_state;
      document_json_from_json(som_json_get(s, "expect"), &want_state);
      char *want = document_json_to_canonical_json(&want_state);
      char *diff = byte_diff("finalState", got, want);
      check(c, tag, strcmp(got, want) == 0, diff);
      free(diff);
      free(got);
      free(want);
      document_json_free(&dj);
      document_json_free(&want_state);
    } else {
      char t2[544];
      snprintf(t2, sizeof(t2), "%s.unknown", tag);
      check(c, t2, 0, op);
    }
  }

  som_json_free(steps);
  spec_document_free(&doc);
}

int main(int argc, char **argv) {
  if (argc > 1) {
    snprintf(g_corpus_dir, sizeof(g_corpus_dir), "%s", argv[1]);
  }
  Checker c;
  checker_init(&c);
  SpecModel *model = load_model();
  char *tree_err = NULL;
  SomMetaTree *tree = som_build_meta_tree(model, "", &tree_err);
  if (tree == NULL) {
    fprintf(stderr, "build meta tree: %s\n",
            tree_err ? tree_err : "(no message)");
    free(tree_err);
    spec_model_free(model);
    return 2;
  }

  test_model_meta(&c, model);
  test_stamp(&c, model);
  test_state_round_trip(&c);
  test_yaml_encode(&c, tree);
  test_yaml_decode_round_trip(&c, tree);
  test_markdown_export(&c, model);
  test_markdown_round_trip(&c, model);
  test_markdown_memory_landing(&c, model);
  test_reflection(&c, model);
  test_validation(&c, model);
  test_operations(&c);
  test_editor(&c, model);
  test_section_id(&c);
  test_serialization_order(&c);
  test_docspecs(&c);
  test_text_pattern(&c);
  test_query(&c, model);
  test_projection(&c, model);
  test_cursor(&c, model);
  test_node_creation_cases(&c, model);
  test_node_creation_script(&c, model);

  int rc = checker_finish(&c);
  som_meta_tree_free(tree);
  spec_model_free(model);
  return rc;
}
