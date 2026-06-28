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
 *   - the imperative operations script.
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

/* ---- groups ------------------------------------------------------------- */

static void test_model_meta(Checker *c, const SpecModel *model) {
  const SpecRoot *root = &model->roots[0];
  check(c, "model.root.sectionId", strcmp(root->section_id, "DEMO") == 0,
        root->section_id);
  check(c, "model.root.type", strcmp(root->type, "Demo") == 0, root->type);
  char cnt[32];
  snprintf(cnt, sizeof(cnt), "%zu", model->classes_len);
  check(c, "model.classCount", model->classes_len == 3, cnt);
  const SpecClass *demo = spec_model_class_named(model, "Demo");
  check(c, "model.Demo.found", demo != NULL, "");
  if (demo != NULL) {
    const char *want[] = {"title",   "summary", "priority", "count",
                          "details", "items",   "meta"};
    int ok = demo->fields_len == 7;
    SomBuf names;
    som_buf_init(&names);
    for (size_t i = 0; i < demo->fields_len; i++) {
      if (i > 0) som_buf_putc(&names, ',');
      som_buf_puts(&names, demo->fields[i].name);
      if (ok && i < 7 && strcmp(demo->fields[i].name, want[i]) != 0) ok = 0;
    }
    char *joined = som_buf_take(&names);
    check(c, "model.Demo.fields", ok, joined);
    free(joined);
  }
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

static void test_yaml_encode(Checker *c) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  char *expected = read_corpus("expected.docspecs.yaml");
  char *actual = encode_yaml(&doc, MODEL_VERSION);
  char *d = byte_diff("yaml.encode", actual, expected);
  check(c, "yaml.encode", strcmp(actual, expected) == 0, d);
  free(d);
  free(actual);
  free(expected);
  spec_document_free(&doc);
  document_json_free(&state);
  som_json_free(sj);
}

static void test_yaml_decode_round_trip(Checker *c) {
  char *expected = read_corpus("expected.docspecs.yaml");
  SpecYamlContents contents;
  decode_yaml(expected, &contents);
  check(c, "yaml.decode.stamp",
        strcmp(contents.model_version, MODEL_VERSION) == 0,
        contents.model_version);
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_load_json(&doc, &contents.document);
  const char *stamp = (contents.model_version[0] == '\0') ? MODEL_VERSION
                                                          : contents.model_version;
  char *actual = encode_yaml(&doc, stamp);
  char *d = byte_diff("yaml.decode.reencode", actual, expected);
  check(c, "yaml.decode.reencode", strcmp(actual, expected) == 0, d);
  free(d);
  free(actual);
  spec_document_free(&doc);
  spec_yaml_contents_free(&contents);
  free(expected);
}

static void test_markdown_export(Checker *c, const SpecModel *model) {
  SomJson *sj = read_json("state.json");
  DocumentJson state;
  document_json_from_json(sj, &state);
  SpecDocument doc;
  doc_from_state(&doc, &state);
  char *expected = read_corpus("expected.md");
  char *actual = spec_markdown_export_root(model, &doc, &model->roots[0]);
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
  char *actual = spec_markdown_export_root(model, &applied, &model->roots[0]);
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

int main(int argc, char **argv) {
  if (argc > 1) {
    snprintf(g_corpus_dir, sizeof(g_corpus_dir), "%s", argv[1]);
  }
  Checker c;
  checker_init(&c);
  SpecModel *model = load_model();

  test_model_meta(&c, model);
  test_state_round_trip(&c);
  test_yaml_encode(&c);
  test_yaml_decode_round_trip(&c);
  test_markdown_export(&c, model);
  test_markdown_round_trip(&c, model);
  test_markdown_memory_landing(&c, model);
  test_reflection(&c, model);
  test_validation(&c, model);
  test_operations(&c);

  int rc = checker_finish(&c);
  spec_model_free(model);
  return rc;
}
