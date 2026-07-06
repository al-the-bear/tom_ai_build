/* Sample (a) — TYPED object-model access (plan item #14, spec §3.1).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs (the generator only
 * rewrites the header/source pair (include/, src/), meta/, schemas/ and the
 * Makefile).
 *
 * Demonstrates editing a TomSpecs document through the generated *typed* facade
 * `tom_som_c_v0`: named accessor functions, nested-section navigation, and the
 * path-based `SomList` collection. The typed facade is a thin editing surface
 * over a generic `SpecDocument` — every typed write lands in the same path-keyed
 * store the generic API (sample b) reads, which the closing lines prove.
 *
 * Build & run from the project root:  ./run_tests.sh   (builds + runs all three)
 * or compile directly (see examples/README.md).
 *
 * C has no module system: the generic runtime header is reached purely through
 * the include path (`-I$(RUNTIME_DIR)/include`), wired by the Makefile's
 * relative `RUNTIME_DIR`, so the sample is portable across checkouts.
 *
 * Ownership: the `SpecDocument` is borrowed by every facade and must outlive
 * them; typed getters return owned `char *` results which the caller frees.
 */
#include "tom_som_c_v0.h"

#include <stdio.h>
#include <stdlib.h>

int main(void) {
  /* A typed root over a fresh, empty document. The constructor also runs the
   * §2.2 instantiation-time version check (an empty stamp is editable). */
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint pd;
  if (d00_solution_blueprint_new(&pd, &doc, "", NULL) != 0) {
    fprintf(stderr, "failed to create D00SolutionBlueprint\n");
    return 1;
  }

  printf("Model version of this typed facade: %s\n",
         d00_solution_blueprint_object_model_version(&pd));
  printf("Root path: %s\n\n", som_node_path(&pd.node));

  /* 1) A content leaf directly on the root. */
  d00_solution_blueprint_set_content(
      &pd, "A platform that unifies our fragmented order systems.");

  /* 2) Navigate into a nested complex section and edit its own content leaf. */
  CurrentLandscape csa = d00_solution_blueprint_current_landscape(&pd);
  current_landscape_set_content(
      &csa, "Three legacy systems with no shared customer record.");

  /* 3) The path-based collection API: append two list items and edit each. */
  SomList metrics = current_landscape_operational_metrics(&csa);
  char *p0 = som_list_add(&metrics);
  CurrentOperationalMetric m0;
  current_operational_metric_init(&m0, &doc, p0);
  current_operational_metric_set_content(&m0,
                                          "Average order turnaround: 4.2 days.");
  current_operational_metric_free(&m0);
  free(p0);

  char *p1 = som_list_add(&metrics);
  CurrentOperationalMetric m1;
  current_operational_metric_init(&m1, &doc, p1);
  current_operational_metric_set_content(
      &m1, "Manual reconciliation: ~12 hours / week.");
  current_operational_metric_free(&m1);
  free(p1);

  /* Read everything back through the typed accessors. */
  char *pd_content = d00_solution_blueprint_content(&pd);
  char *csa_content = current_landscape_content(&csa);
  printf("SBP.content              = %s\n", pd_content);
  printf("SBP.currentLandscape = %s\n", csa_content);
  printf("operationalMetrics.length = %zu\n", som_list_length(&metrics));
  free(pd_content);
  free(csa_content);

  for (size_t i = 0; i < som_list_length(&metrics); i++) {
    const char *ip = som_list_item_path_at(&metrics, i);
    CurrentOperationalMetric item;
    current_operational_metric_init(&item, &doc, ip);
    char *v = current_operational_metric_content(&item);
    printf("  metric[%zu] = %s\n", i, v);
    free(v);
    current_operational_metric_free(&item);
  }

  /* The typed path is the generic path: the same data is addressable through
   * the generic document API (this is exactly what sample (b) uses). */
  printf("\nSame value via the generic path (%s/content):\n",
         som_node_path(&csa.node));
  const char *raw = spec_document_content(&doc, "SBP/currentLandscape/content");
  printf("  %s\n", raw != NULL ? raw : "");

  som_list_free(&metrics);
  current_landscape_free(&csa);
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
  return 0;
}
