/* The link checks of one document (spec_links_validator,
 * `tom_specs_model_rules.md` §9.7), the derived numbers of the instance tier
 * (spec_derived_numbers) and the typed reading of a value under review
 * (som_typed_reading, the headline field of the review operations). Mirrors
 * the Go runtime's spec_links_validator_test.go.
 *
 * The shared corpus (`link_validation_cases.json`) pins the findings as
 * `{path, code}`; this test holds what it does not: the fixes `deriveFields`
 * reads beside each finding (an `addRow`'s values in the order they are
 * written), the finding order and messages, reading the proposal
 * (`read_proposed`), the derived numbers, and a headline refusing a comment
 * block. Reads the corpus from `../tom_som_conformance/corpus/` (run from the
 * package root). Exit status is the number of failed checks. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

static int g_checks = 0;
static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "fatal: cannot read %s\n", path);
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  rewind(f);
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  buf[got] = '\0';
  fclose(f);
  return buf;
}

static SpecModel *g_model;
static SomJson *g_cases;

/* Loads the state of the link-validation case whose name starts with
 * `prefix` into `doc`. */
static void case_doc(const char *prefix, SpecDocument *doc) {
  const SomJson *cases = som_json_get(g_cases, "cases");
  for (size_t i = 0; i < som_json_array_len(cases); i++) {
    const SomJson *cc = som_json_array_at(cases, i);
    if (strncmp(som_json_str_or(cc, "name"), prefix, strlen(prefix)) != 0) {
      continue;
    }
    DocumentJson state;
    document_json_from_json(som_json_get(cc, "state"), &state);
    spec_document_init(doc);
    spec_document_load_json(doc, &state);
    document_json_free(&state);
    return;
  }
  fprintf(stderr, "fatal: no link-validation case %s\n", prefix);
  exit(2);
}

/* The fixes of a case as JSON lines (owned, one per line). */
static char *case_fixes(const char *prefix, int read_proposed) {
  SpecDocument doc;
  case_doc(prefix, &doc);
  SpecLinkValidator v;
  spec_link_validator_init(&v, g_model, &doc, read_proposed);
  spec_link_validator_run(&v);
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < v.fixes.len; i++) {
    char *j = spec_link_fix_to_json(&v.fixes.items[i]);
    som_buf_puts(&b, j);
    som_buf_putc(&b, '\n');
    free(j);
  }
  spec_link_validator_free(&v);
  spec_document_free(&doc);
  return som_buf_take(&b);
}

static void check_text(const char *name, char *got, const char *want) {
  check(name, strcmp(got, want) == 0, got);
  free(got);
}

static void test_fixes(void) {
  /* A derived value not written yet: no finding, but deriveFields writes
   * it. */
  SpecDocument doc;
  case_doc("a derived value not written yet", &doc);
  SpecValidationErrors errs;
  spec_validate_links(g_model, &doc, &errs);
  check("fixes.notYet.clean", errs.len == 0, NULL);
  spec_validation_errors_free(&errs);
  spec_document_free(&doc);
  check_text("fixes.notYet", case_fixes("a derived value not written yet", 0),
             "{\"step\":2,\"kind\":\"set\",\"path\":\"BLU/requirements/"
             "REQ-ITEM-LST-1/REQAB\",\"field\":null,\"value\":\"Exports use the "
             "formats of REQ-IMPORT and never run with REQ-PURGE.\"}\n");
  /* A one-way link not named back: the other end gets the id appended. */
  check_text("fixes.inverse", case_fixes("a one-way link not named back", 0),
             "{\"step\":1,\"kind\":\"append\",\"path\":\"BLU/acceptance/"
             "criteria/CRIT-ITEM-LST-1/content\",\"field\":"
             "\"relatedRequirements\",\"value\":\"REQ-EXPORT\"}\n");
  /* A symmetric row without its counterpart: a row is added there, its
   * values in the order they are written. */
  check_text("fixes.symmetric",
             case_fixes("a symmetric row without its counterpart", 0),
             "{\"step\":1,\"kind\":\"addRow\",\"path\":\"BLU/requirements/"
             "REQ-ITEM-LST-3/LNK-ITEM-LST\",\"values\":{\"LNK-REF#ref\":"
             "\"REQ-EXPORT\",\"content#linkType\":\"conflict\"}}\n");
  /* A generated row the text no longer names: removed. */
  check_text("fixes.stale",
             case_fixes("a generated row the text no longer names", 0),
             "{\"step\":1,\"kind\":\"removeRow\",\"path\":\"BLU/requirements/"
             "REQ-ITEM-LST-1/LNK-ITEM-LST-1\",\"empty\":false}\n");
  /* A copy edited apart from its holder: copied back whole. */
  char *got = case_fixes("a copy edited apart from its holder", 0);
  check("fixes.sameAs",
        strncmp(got,
                "{\"step\":2,\"kind\":\"copy\",\"path\":\"BLU/criteriaSummary/"
                "criteria\"",
                60) == 0 &&
            strchr(got, '\n') == got + strlen(got) - 1,
        got);
  free(got);
}

static void test_findings(void) {
  SpecDocument doc;
  case_doc("a copy differing from its source", &doc);
  SpecValidationErrors errs;
  spec_validate_links(g_model, &doc, &errs);
  check("findings.copy",
        errs.len == 1 &&
            strcmp(errs.items[0].code,
                   SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH) == 0 &&
            strstr(errs.items[0].message, "is derived (copy of") != NULL,
        NULL);
  spec_validation_errors_free(&errs);
  spec_document_free(&doc);
  /* Sorted by path, then by code in declaration order. */
  case_doc("an id named in a generate-mode text", &doc);
  spec_validate_links(g_model, &doc, &errs);
  int sorted = 1;
  for (size_t i = 1; i < errs.len; i++) {
    int c = strcmp(errs.items[i - 1].path, errs.items[i].path);
    if (c > 0 || (c == 0 && spec_validation_code_index(errs.items[i - 1].code) >
                                spec_validation_code_index(errs.items[i].code))) {
      sorted = 0;
    }
  }
  check("findings.sorted", sorted && errs.len > 0, NULL);
  spec_validation_errors_free(&errs);
  spec_document_free(&doc);
  /* A value holding a pending change is read with the mark rejected and
   * listed once; reading the proposal lists nothing. */
  case_doc("a source holding a pending change", &doc);
  spec_validate_links(g_model, &doc, &errs);
  size_t pending = 0;
  for (size_t i = 0; i < errs.len; i++) {
    if (strcmp(errs.items[i].code, SPEC_VALIDATION_CODE_LINK_VALUE_PENDING) == 0) {
      pending++;
    }
  }
  check("findings.pendingOnce", pending == 1, NULL);
  spec_validation_errors_free(&errs);
  SpecLinkValidator v;
  spec_link_validator_init(&v, g_model, &doc, 1);
  spec_link_validator_run(&v);
  int proposal_pending = 0;
  for (size_t i = 0; i < v.errors.len; i++) {
    if (strcmp(v.errors.items[i].code, SPEC_VALIDATION_CODE_LINK_VALUE_PENDING) ==
        0) {
      proposal_pending = 1;
    }
  }
  check("findings.proposalNotPending", !proposal_pending, NULL);
  spec_link_validator_free(&v);
  spec_document_free(&doc);
}

static void test_expand_and_ids(void) {
  SpecDocument doc;
  case_doc("a clean Blueprint", &doc);
  SomStrList paths;
  spec_expand_pattern(&doc, "BLU/requirements/REQ-ITEM-LST-*/REQD", &paths);
  char *joined = som_strlist_join(&paths, ",");
  check_text("expand.items", joined,
             "BLU/requirements/REQ-ITEM-LST-1/REQD,BLU/requirements/"
             "REQ-ITEM-LST-2/REQD,BLU/requirements/REQ-ITEM-LST-3/REQD");
  som_strlist_free(&paths);
  spec_expand_pattern(&doc, "BLU/requirements", &paths);
  check("expand.plain",
        paths.len == 1 && strcmp(paths.items[0], "BLU/requirements") == 0, NULL);
  som_strlist_free(&paths);
  spec_document_free(&doc);
  SomStrList ids;
  spec_link_ids(" A, ,B ,", &ids);
  check_text("ids", som_strlist_join(&ids, "|"), "A|B");
  som_strlist_free(&ids);
  check("codeIndex",
        spec_validation_code_index(SPEC_VALIDATION_CODE_UNMARKABLE) ==
                SPEC_VALIDATION_ALL_CODES_COUNT - 1 &&
            spec_validation_code_index("nope") == -1,
        NULL);
}

/* The derived number of `path#field`, or NULL. Borrowed from `n`. */
static const char *number_at(const SpecDerivedNumbers *n, const char *path,
                             const char *field) {
  for (size_t i = 0; i < n->len; i++) {
    if (strcmp(n->items[i].path, path) == 0 &&
        strcmp(n->items[i].field, field) == 0) {
      return n->items[i].value;
    }
  }
  return NULL;
}

static int str_is(const char *got, const char *want) {
  return got != NULL && strcmp(got, want) == 0;
}

static void test_derived_numbers(void) {
  const char *base = "BLU/requirements";
  SpecDocument d;
  spec_document_init(&d);
  static const char *const statuses[3] = {"approved", "done", "draft"};
  for (size_t i = 0; i < 3; i++) {
    char *item = spec_document_add_list_item(&d, "BLU/requirements/REQ-ITEM-LST");
    char form[256];
    snprintf(form, sizeof(form), "%s/content", item);
    spec_document_set_form_field(&d, form, "status", statuses[i]);
    free(item);
  }
  char sum[128];
  snprintf(sum, sizeof(sum), "%s/REQS-SUM", base);
  spec_document_set_form_field(&d, sum, "total", "1");
  SpecDerivedNumbers n;
  spec_derived_numbers(g_model, &d, 0, &n);
  check("derived.counts",
        str_is(number_at(&n, sum, "total"), "3") &&
            str_is(number_at(&n, sum, "settled"), "2"),
        NULL);
  spec_derived_numbers_free(&n);
  /* A count reading a pending mark: rejected by default, accepted with
   * read_proposed. */
  spec_document_set_form_field(&d, "BLU/requirements/REQ-ITEM-LST-3/content",
                               "status", "{~~draft~>done~~}");
  spec_derived_numbers(g_model, &d, 0, &n);
  check("derived.rejected", str_is(number_at(&n, sum, "settled"), "2"), NULL);
  spec_derived_numbers_free(&n);
  spec_derived_numbers(g_model, &d, 1, &n);
  check("derived.proposed", str_is(number_at(&n, sum, "settled"), "3"), NULL);
  spec_derived_numbers_free(&n);
  spec_document_free(&d);
}

static void check_reading(const char *name, const char *raw, const char *want) {
  char *got = som_typed_reading(raw);
  check(name, got != NULL && strcmp(got, want) == 0, got);
  free(got);
}

static void test_typed_reading(void) {
  check_reading("typed.plain", "30", "30");
  check_reading("typed.none", "", "");
  check_reading("typed.change", "{~~ 30 ~> 15 ~~}", "30");
  check_reading("typed.insertion", "{++15++}", "");
  long long i = 0;
  check("typed.int", som_parse_int("{~~30~>15~~}", &i) && i == 30, NULL);
  int b = 0;
  check("typed.bool", som_parse_bool("{~~true~>false~~}", &b) && b == 1, NULL);
  SomStrList values;
  som_strlist_init(&values);
  som_strlist_push_copy(&values, "low");
  som_strlist_push_copy(&values, "high");
  char *e = NULL;
  check("typed.enum",
        som_parse_enum_name("{~~high~>low~~}", &values, &e) && str_is(e, "high"),
        NULL);
  free(e);
  check("typed.readable", som_typed_text_readable("int", "{~~30~>lots~~}"), NULL);
  check("typed.isTyped",
        som_is_typed_field("String", &values) && som_is_typed_field("int?", NULL) &&
            !som_is_typed_field("String", NULL),
        NULL);
  som_strlist_free(&values);
}

static char *fixed_clock(void *context) {
  (void)context;
  return som_strdup("2026-11-07T14:05+01:00");
}

static void test_headline_field(void) {
  SpecDocument d;
  spec_document_init(&d);
  spec_document_set_headline(&d, "BLU/requirements", "Requirements {++and links++}");
  SpecReviewAnnotations api =
      spec_review_annotations_make_with_clock(&d, NULL, fixed_clock, NULL);
  SpecMarkEntryList marks;
  spec_review_annotations_list_marks(&api, NULL, &marks);
  check("headline.listed",
        marks.len == 1 && strcmp(marks.items[0].path, "BLU/requirements") == 0 &&
            marks.items[0].field != NULL &&
            strcmp(marks.items[0].field, SPEC_HEADLINE_FIELD) == 0,
        NULL);
  spec_mark_entry_list_free(&marks);
  SpecReviewAnnotationError err;
  spec_review_annotation_error_init(&err);
  char *id = spec_review_annotations_insert_comment(
      &api, "BLU/requirements", SPEC_HEADLINE_FIELD, 0, "x", NULL, NULL, NULL,
      &err);
  check("headline.noComment", id == NULL && err.message != NULL, NULL);
  free(id);
  spec_review_annotation_error_free(&err);
  SpecMarkReport report;
  spec_review_annotations_accept_all_marks(&api, NULL, &report);
  spec_mark_report_free(&report);
  const char *h = spec_document_headline(&d, "BLU/requirements");
  check("headline.accepted", str_is(h, "Requirements and links"), h);
  spec_document_free(&d);
}

int main(void) {
  char *meta = read_file("../tom_som_conformance/corpus/links.meta.json");
  char *err = NULL;
  g_model = spec_model_from_json_str(meta, &err);
  free(meta);
  if (g_model == NULL) {
    fprintf(stderr, "fatal: %s\n", err != NULL ? err : "load links.meta.json");
    return 2;
  }
  char *cases = read_file("../tom_som_conformance/corpus/link_validation_cases.json");
  g_cases = som_json_parse(cases, &err);
  free(cases);
  if (g_cases == NULL) {
    fprintf(stderr, "fatal: %s\n", err != NULL ? err : "parse cases");
    return 2;
  }
  test_fixes();
  test_findings();
  test_expand_and_ids();
  test_derived_numbers();
  test_typed_reading();
  test_headline_field();
  som_json_free(g_cases);
  spec_model_free(g_model);
  if (g_failures == 0) {
    printf("spec_links_validator_test: all %d checks passed\n", g_checks);
  } else {
    fprintf(stderr, "spec_links_validator_test: %d of %d checks failed\n",
            g_failures, g_checks);
  }
  return g_failures;
}
