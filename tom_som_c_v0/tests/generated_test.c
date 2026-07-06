/* Behavioural test for the **actually-committed** generated C typed model.
 *
 * Unlike the emitter's golden test (which compiles the small emitter fixture),
 * this harness exercises the real, full `tom_som_c_v0` translation unit (3000+
 * typed facade structs) against the generic `tom_som_c_runtime` and proves the
 * typed facade is a faithful editing surface over the shared document (spec §3):
 *
 *   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
 *   - a content leaf round-trips typed -> generic and generic -> typed;
 *   - a nested complex section derives its path under the root;
 *   - the path-based `SomList` collection maps onto the generic list store;
 *   - the generated model-version accessor / macro return "1.0";
 *   - the instantiation-time version check (§2.2) accepts an editable stamp and
 *     rejects a newer-minor / cross-major stamp with a non-zero return + message.
 *
 * Build & run via `./run_tests.sh` (compiles against the relative runtime
 * checkout). Exit 0 == all green; it prints "OK: N checks passed".
 *
 * C has no test framework here, so this is a hand-rolled checker mirroring the
 * runtime's conformance harness: a borrowed `SpecDocument` outlives every facade
 * bound to it, and every owned `char *` the typed getters return is freed.
 */
#include "tom_som_c_v0.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_passed = 0;
static int g_failed = 0;

static void ok(int cond, const char *name) {
  if (cond) {
    g_passed++;
  } else {
    g_failed++;
    fprintf(stderr, "FAIL: %s\n", name);
  }
}

static void eq_str(const char *got, const char *want, const char *name) {
  if (got != NULL && strcmp(got, want) == 0) {
    g_passed++;
  } else {
    g_failed++;
    fprintf(stderr, "FAIL: %s — got \"%s\" want \"%s\"\n", name,
            got != NULL ? got : "(null)", want);
  }
}

/* The SBP root, a content leaf, and a nested complex section round-trip in both
 * directions between the typed facade and the generic document. */
static void test_root_and_parity(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint pd;
  ok(d00_solution_blueprint_new(&pd, &doc, "", NULL) == 0, "new D00SolutionBlueprint");
  eq_str(som_node_path(&pd.node), "SBP", "root segment");

  /* Typed write -> generic read. */
  d00_solution_blueprint_set_content(&pd, "A clear vision");
  eq_str(spec_document_content(&doc, "SBP/content"), "A clear vision",
         "typed write visible generically");

  /* Generic write -> typed read. */
  spec_document_set_content(&doc, "SBP/content", "Revised vision");
  char *c = d00_solution_blueprint_content(&pd);
  eq_str(c, "Revised vision", "generic write visible through typed getter");
  free(c);

  /* An unset leaf reads as the empty string (never NULL). */
  SpecDocument fresh;
  spec_document_init(&fresh);
  D00SolutionBlueprint pd2;
  d00_solution_blueprint_new(&pd2, &fresh, "", NULL);
  char *empty = d00_solution_blueprint_content(&pd2);
  eq_str(empty, "", "unset leaf reads as empty string");
  free(empty);

  /* Nested complex section path derivation (camelCase segment preserved). */
  CurrentLandscape csa = d00_solution_blueprint_current_landscape(&pd);
  eq_str(som_node_path(&csa.node), "SBP/currentLandscape",
         "nested section path");

  /* A generic value under the nested typed node is addressable via the literal
   * path (typed path == generic path). */
  spec_document_set_content(&doc, "SBP/currentLandscape/probe", "x");
  eq_str(spec_document_content(&doc, "SBP/currentLandscape/probe"), "x",
         "typed path is the generic path");

  current_landscape_free(&csa);
  d00_solution_blueprint_free(&pd);
  d00_solution_blueprint_free(&pd2);
  spec_document_free(&fresh);
  spec_document_free(&doc);
}

/* The path-based typed list maps onto the generic list store; element facades
 * are constructed from the item paths the list yields. */
static void test_typed_list(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  D00SolutionBlueprint pd;
  d00_solution_blueprint_new(&pd, &doc, "", NULL);

  CurrentLandscape csa = d00_solution_blueprint_current_landscape(&pd);
  SomList metrics = current_landscape_operational_metrics(&csa);

  /* Append two items, constructing the element facade from each new path. */
  char *p0 = som_list_add(&metrics);
  CurrentOperationalMetric m0;
  current_operational_metric_init(&m0, &doc, p0);
  current_operational_metric_set_content(&m0, "Average order turnaround: 4.2 days.");
  current_operational_metric_free(&m0);
  free(p0);

  char *p1 = som_list_add(&metrics);
  CurrentOperationalMetric m1;
  current_operational_metric_init(&m1, &doc, p1);
  current_operational_metric_set_content(&m1, "Manual reconciliation: ~12 hours / week.");
  current_operational_metric_free(&m1);
  free(p1);

  ok(som_list_length(&metrics) == 2, "typed list length");

  /* Read the first item back through an element facade over its borrowed path. */
  const char *ip0 = som_list_item_path_at(&metrics, 0);
  CurrentOperationalMetric r0;
  current_operational_metric_init(&r0, &doc, ip0);
  char *rc = current_operational_metric_content(&r0);
  eq_str(rc, "Average order turnaround: 4.2 days.", "typed list item content");
  free(rc);
  current_operational_metric_free(&r0);

  /* Typed list writes land in the generic list store under the same path. */
  ok(spec_document_list_item_count(
         &doc, "SBP/currentLandscape/CUOPME-OPER-LST") == 2,
     "generic list store mirrors typed list");

  som_list_free(&metrics);
  current_landscape_free(&csa);
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
}

/* A fixture bundling a fresh document with the typed facades bound to it, so
 * the `operational_metrics` list is exercised end-to-end for the section-id
 * scenarios. All facades hold pointers into `doc`, so the fixture is kept in
 * place (init and free the same local) and never copied. */
typedef struct {
  SpecDocument doc;
  D00SolutionBlueprint pd;
  CurrentLandscape csa;
  SomList metrics;
} MetricsFixture;

static void metrics_fixture_init(MetricsFixture *f) {
  spec_document_init(&f->doc);
  d00_solution_blueprint_new(&f->pd, &f->doc, "", NULL);
  f->csa = d00_solution_blueprint_current_landscape(&f->pd);
  f->metrics = current_landscape_operational_metrics(&f->csa);
}

static void metrics_fixture_free(MetricsFixture *f) {
  som_list_free(&f->metrics);
  current_landscape_free(&f->csa);
  d00_solution_blueprint_free(&f->pd);
  spec_document_free(&f->doc);
}

/* Appends a same-day item and asserts the generated section id of the new item
 * (queried through the typed facade over its path). */
static void add_on_expect(MetricsFixture *f, long long month, long long day,
                          const char *want) {
  char *path = som_list_add_on(&f->metrics, month, day);
  SomNode n;
  som_node_init(&n, &f->doc, path);
  char *sid = som_node_section_id(&n);
  eq_str(sid, want, "add_on section id");
  free(sid);
  som_node_free(&n);
  free(path);
}

/* Sets the section id of the item at `index` through the typed facade node. */
static int set_id_at(MetricsFixture *f, size_t index, const char *id,
                     SpecSectionIdError *err) {
  const char *path = som_list_item_path_at(&f->metrics, index);
  SomNode n;
  som_node_init(&n, &f->doc, path);
  int rc = som_node_set_section_id(&n, id, err);
  som_node_free(&n);
  return rc;
}

/* Asserts the list's section ids equal `want[0..n)` in order. */
static void expect_section_ids(MetricsFixture *f, const char *const *want,
                               size_t n, const char *name) {
  SomStrList ids;
  som_list_section_ids(&f->metrics, &ids);
  int match = ids.len == n;
  for (size_t i = 0; match && i < n; i++) {
    if (strcmp(ids.items[i], want[i]) != 0) {
      match = 0;
    }
  }
  ok(match, name);
  if (!match) {
    fprintf(stderr, "  got %zu ids:", ids.len);
    for (size_t i = 0; i < ids.len; i++) fprintf(stderr, " %s", ids.items[i]);
    fprintf(stderr, "\n");
  }
  som_strlist_free(&ids);
}

/* The generated typed facade drives section-id generation and the delete rules
 * (AA1 criteria 3–6) end-to-end. March 5 → the two-letter day code "CE"
 * (C = month 3, E = day 5). Mirrors the Rust v0 `section_ids` test. */
static void test_section_ids(void) {
  const long long MAR = 3, DAY = 5;

  /* Generation: consecutive same-day items number CE1, CE2 (criteria 3–4). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE1");
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE2");
    metrics_fixture_free(&f);
  }

  /* Override to an arbitrary suffix; a duplicate override or explicit add with
   * the same id raises a collision (criterion 5). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    char *p0 = som_list_add_on(&f.metrics, MAR, DAY); /* CE1 */
    free(p0);
    char *p1 = som_list_add_on(&f.metrics, MAR, DAY); /* CE2 */
    free(p1);

    SpecSectionIdError e;
    spec_section_id_error_init(&e);
    ok(set_id_at(&f, 1, "CUOPME-OPER-ZZ9", &e) == 1, "override succeeds");
    spec_section_id_error_free(&e);

    const char *want[] = {"CUOPME-OPER-CE1", "CUOPME-OPER-ZZ9"};
    expect_section_ids(&f, want, 2, "override applied, no renumber");

    spec_section_id_error_init(&e);
    ok(set_id_at(&f, 0, "CUOPME-OPER-ZZ9", &e) == 0 &&
           spec_section_id_is_collision(&e),
       "override collision rejected");
    spec_section_id_error_free(&e);

    spec_section_id_error_init(&e);
    char *added = NULL;
    ok(som_list_add_with_id(&f.metrics, "CUOPME-OPER-ZZ9", &added, &e) == 0 &&
           spec_section_id_is_collision(&e),
       "add-with-id collision rejected");
    free(added);
    spec_section_id_error_free(&e);

    metrics_fixture_free(&f);
  }

  /* Delete a middle item: remaining ids never renumber, and a new same-day item
   * takes the next free number (criterion 6). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    for (int i = 0; i < 3; i++) {  /* CE1, CE2, CE3 */
      char *p = som_list_add_on(&f.metrics, MAR, DAY);
      free(p);
    }
    som_list_remove_at(&f.metrics, 1); /* drop CE2 */
    const char *want[] = {"CUOPME-OPER-CE1", "CUOPME-OPER-CE3"};
    expect_section_ids(&f, want, 2, "delete-middle keeps ids");
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE4");
    metrics_fixture_free(&f);
  }

  /* Delete the last (max) item: a new same-day item reuses the freed number. */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    for (int i = 0; i < 3; i++) {  /* CE1, CE2, CE3 */
      char *p = som_list_add_on(&f.metrics, MAR, DAY);
      free(p);
    }
    som_list_remove_at(&f.metrics, 2); /* drop CE3 (the max) */
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE3");
    metrics_fixture_free(&f);
  }
}

/* The generated model version is reported by both the macro and the accessor. */
static void test_model_version(void) {
  eq_str(D00_SOLUTION_BLUEPRINT_MODEL_VERSION, "1.0", "MODEL_VERSION macro");

  SpecDocument doc;
  spec_document_init(&doc);
  D00SolutionBlueprint pd;
  d00_solution_blueprint_new(&pd, &doc, "", NULL);
  eq_str(d00_solution_blueprint_object_model_version(&pd), "1.0",
         "object_model_version accessor");
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
}

/* The instantiation-time §2.2 version check accepts editable stamps and rejects
 * newer-minor / cross-major stamps with a non-zero return and an owned message. */
static void test_version_check(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint a;
  ok(d00_solution_blueprint_new(&a, &doc, "", NULL) == 0, "empty stamp accepted");
  d00_solution_blueprint_free(&a);

  D00SolutionBlueprint b;
  ok(d00_solution_blueprint_new(&b, &doc, "1.0", NULL) == 0, "equal stamp accepted");
  d00_solution_blueprint_free(&b);

  /* Newer minor -> rejected (no node bound, so nothing to free on the facade). */
  char *err = NULL;
  D00SolutionBlueprint c;
  ok(d00_solution_blueprint_new(&c, &doc, "1.1", &err) != 0,
     "newer-minor stamp rejected");
  ok(err != NULL, "rejection writes an owned message");
  free(err);
  err = NULL;

  /* Different major -> rejected. */
  D00SolutionBlueprint d;
  ok(d00_solution_blueprint_new(&d, &doc, "2.0", &err) != 0,
     "cross-major stamp rejected");
  free(err);

  spec_document_free(&doc);
}

int main(void) {
  test_root_and_parity();
  test_typed_list();
  test_section_ids();
  test_model_version();
  test_version_check();

  if (g_failed != 0) {
    fprintf(stderr, "\n%d checks FAILED (%d passed)\n", g_failed, g_passed);
    return 1;
  }
  printf("OK: %d checks passed\n", g_passed);
  return 0;
}
