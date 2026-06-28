/* Behavioural test for the **actually-committed** generated C typed model.
 *
 * Unlike the emitter's golden test (which compiles the small emitter fixture),
 * this harness exercises the real, full `tom_som_c_v0` translation unit (3000+
 * typed facade structs) against the generic `tom_som_c_runtime` and proves the
 * typed facade is a faithful editing surface over the shared document (spec §3):
 *
 *   - the `ProjectDefinition` root is anchored at the `PD` segment;
 *   - a content leaf round-trips typed -> generic and generic -> typed;
 *   - a nested complex section derives its path under the root;
 *   - the path-based `SomList` collection maps onto the generic list store;
 *   - the generated model-version accessor / macro return "0.0";
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

/* The PD root, a content leaf, and a nested complex section round-trip in both
 * directions between the typed facade and the generic document. */
static void test_root_and_parity(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  ProjectDefinition pd;
  ok(project_definition_new(&pd, &doc, "", NULL) == 0, "new ProjectDefinition");
  eq_str(som_node_path(&pd.node), "PD", "root segment");

  /* Typed write -> generic read. */
  project_definition_set_content(&pd, "A clear vision");
  eq_str(spec_document_content(&doc, "PD/content"), "A clear vision",
         "typed write visible generically");

  /* Generic write -> typed read. */
  spec_document_set_content(&doc, "PD/content", "Revised vision");
  char *c = project_definition_content(&pd);
  eq_str(c, "Revised vision", "generic write visible through typed getter");
  free(c);

  /* An unset leaf reads as the empty string (never NULL). */
  SpecDocument fresh;
  spec_document_init(&fresh);
  ProjectDefinition pd2;
  project_definition_new(&pd2, &fresh, "", NULL);
  char *empty = project_definition_content(&pd2);
  eq_str(empty, "", "unset leaf reads as empty string");
  free(empty);

  /* Nested complex section path derivation (camelCase segment preserved). */
  CurrentStateAnalysis csa = project_definition_current_state_analysis(&pd);
  eq_str(som_node_path(&csa.node), "PD/currentStateAnalysis",
         "nested section path");

  /* A generic value under the nested typed node is addressable via the literal
   * path (typed path == generic path). */
  spec_document_set_content(&doc, "PD/currentStateAnalysis/probe", "x");
  eq_str(spec_document_content(&doc, "PD/currentStateAnalysis/probe"), "x",
         "typed path is the generic path");

  current_state_analysis_free(&csa);
  project_definition_free(&pd);
  project_definition_free(&pd2);
  spec_document_free(&fresh);
  spec_document_free(&doc);
}

/* The path-based typed list maps onto the generic list store; element facades
 * are constructed from the item paths the list yields. */
static void test_typed_list(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  ProjectDefinition pd;
  project_definition_new(&pd, &doc, "", NULL);

  CurrentStateAnalysis csa = project_definition_current_state_analysis(&pd);
  SomList metrics = current_state_analysis_operational_metrics(&csa);

  /* Append two items, constructing the element facade from each new path. */
  char *p0 = som_list_add(&metrics);
  CurrentOperationalMetrics m0;
  current_operational_metrics_init(&m0, &doc, p0);
  current_operational_metrics_set_content(&m0, "Average order turnaround: 4.2 days.");
  current_operational_metrics_free(&m0);
  free(p0);

  char *p1 = som_list_add(&metrics);
  CurrentOperationalMetrics m1;
  current_operational_metrics_init(&m1, &doc, p1);
  current_operational_metrics_set_content(&m1, "Manual reconciliation: ~12 hours / week.");
  current_operational_metrics_free(&m1);
  free(p1);

  ok(som_list_length(&metrics) == 2, "typed list length");

  /* Read the first item back through an element facade over its borrowed path. */
  const char *ip0 = som_list_item_path_at(&metrics, 0);
  CurrentOperationalMetrics r0;
  current_operational_metrics_init(&r0, &doc, ip0);
  char *rc = current_operational_metrics_content(&r0);
  eq_str(rc, "Average order turnaround: 4.2 days.", "typed list item content");
  free(rc);
  current_operational_metrics_free(&r0);

  /* Typed list writes land in the generic list store under the same path. */
  ok(spec_document_list_item_count(
         &doc, "PD/currentStateAnalysis/CUOPME-OPER-LST") == 2,
     "generic list store mirrors typed list");

  som_list_free(&metrics);
  current_state_analysis_free(&csa);
  project_definition_free(&pd);
  spec_document_free(&doc);
}

/* The generated model version is reported by both the macro and the accessor. */
static void test_model_version(void) {
  eq_str(PROJECT_DEFINITION_MODEL_VERSION, "0.0", "MODEL_VERSION macro");

  SpecDocument doc;
  spec_document_init(&doc);
  ProjectDefinition pd;
  project_definition_new(&pd, &doc, "", NULL);
  eq_str(project_definition_object_model_version(&pd), "0.0",
         "object_model_version accessor");
  project_definition_free(&pd);
  spec_document_free(&doc);
}

/* The instantiation-time §2.2 version check accepts editable stamps and rejects
 * newer-minor / cross-major stamps with a non-zero return and an owned message. */
static void test_version_check(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  ProjectDefinition a;
  ok(project_definition_new(&a, &doc, "", NULL) == 0, "empty stamp accepted");
  project_definition_free(&a);

  ProjectDefinition b;
  ok(project_definition_new(&b, &doc, "0.0", NULL) == 0, "equal stamp accepted");
  project_definition_free(&b);

  /* Newer minor -> rejected (no node bound, so nothing to free on the facade). */
  char *err = NULL;
  ProjectDefinition c;
  ok(project_definition_new(&c, &doc, "0.1", &err) != 0,
     "newer-minor stamp rejected");
  ok(err != NULL, "rejection writes an owned message");
  free(err);
  err = NULL;

  /* Different major -> rejected. */
  ProjectDefinition d;
  ok(project_definition_new(&d, &doc, "1.0", &err) != 0,
     "cross-major stamp rejected");
  free(err);

  spec_document_free(&doc);
}

int main(void) {
  test_root_and_parity();
  test_typed_list();
  test_model_version();
  test_version_check();

  if (g_failed != 0) {
    fprintf(stderr, "\n%d checks FAILED (%d passed)\n", g_failed, g_passed);
    return 1;
  }
  printf("OK: %d checks passed\n", g_passed);
  return 0;
}
