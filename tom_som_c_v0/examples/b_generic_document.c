/* Sample (b) — GENERIC in-memory document access (som_multiplatform_spec_model.md §6).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs (the generator only
 * rewrites the header/source pair (include/, src/), meta/, schemas/ and the
 * Makefile).
 *
 * Demonstrates editing the *same* document shape as sample (a) using ONLY the
 * generic `tom_som_c_runtime` — string paths, no generated typed structs. This
 * is the language-independent core: a sparse, path-keyed store plus the list and
 * serialization helpers. Anything the typed facade can express is expressible
 * here; the typed facade just makes it type-safe and discoverable.
 *
 * Build & run from the project root:  ./run_tests.sh   (builds + runs all three)
 * or compile directly (see examples/README.md).
 *
 * Ownership: `spec_document_to_json` / `document_json_to_canonical_json` and
 * `encode_yaml` return owned buffers the caller frees.
 *
 * The canonical YAML encoder walks the document root's metadata tree (SOM §8)
 * to place every value, so the sole generated symbol this otherwise-generic
 * sample reaches for is `d00_solution_blueprint_meta_tree()` — mirroring the Go
 * `b_generic_document` sample, which passes `D00SolutionBlueprintMetaTree`.
 */
#include "tom_som_c_runtime.h"
#include "tom_som_c_v0_meta.h"

#include <stdio.h>
#include <stdlib.h>

int main(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  /* Content leaves are addressed by their full path from the root segment. */
  spec_document_set_content(
      &doc, "SBP/content",
      "A platform that unifies our fragmented order systems.");
  spec_document_set_content(
      &doc, "SBP/currentLandscape/content",
      "Three legacy systems with no shared customer record.");

  /* A list: append items (each call returns the new item's owned path), then
   * set a content leaf under each. The list path mirrors the typed facade's
   * `operationalMetrics` accessor. */
  const char *list_path = "SBP/currentLandscape/CUOPME-OPER-LST";
  char *item0 = spec_document_add_list_item(&doc, list_path);
  char *buf = spec_path_join(item0, "content");
  spec_document_set_content(&doc, buf, "Average order turnaround: 4.2 days.");
  free(buf);
  free(item0);

  char *item1 = spec_document_add_list_item(&doc, list_path);
  buf = spec_path_join(item1, "content");
  spec_document_set_content(&doc, buf, "Manual reconciliation: ~12 hours / week.");
  free(buf);
  free(item1);

  /* Read back generically. */
  printf("SBP/content = %s\n", spec_document_content(&doc, "SBP/content"));
  printf("list item count = %zu\n",
         spec_document_list_item_count(&doc, list_path));
  const SomStrList *items = spec_document_list_items(&doc, list_path);
  if (items != NULL) {
    for (size_t i = 0; i < items->len; i++) {
      char *cp = spec_path_join(items->items[i], "content");
      const char *v = spec_document_content(&doc, cp);
      printf("  %s/content = %s\n", items->items[i], v != NULL ? v : "");
      free(cp);
    }
  }

  /* The whole document serializes losslessly to canonical JSON. Keys are
   * emitted in sorted order, so the dump is deterministic regardless of
   * insertion order (matching the Dart/Rust/Go/TS counterparts). */
  DocumentJson dj;
  spec_document_to_json(&doc, &dj);
  char *json = document_json_to_canonical_json(&dj);
  printf("\nDocument JSON:\n%s\n", json);
  free(json);
  document_json_free(&dj);

  /* … and to the canonical YAML wire format (stamped with the model version).
   * The encoder places each value by walking the root's metadata tree. */
  char *yerr = NULL;
  char *yaml = encode_yaml(&doc, d00_solution_blueprint_meta_tree(), "0.0", &yerr);
  if (yaml == NULL) {
    fprintf(stderr, "encode_yaml failed: %s\n", yerr != NULL ? yerr : "?");
    free(yerr);
    spec_document_free(&doc);
    return 1;
  }
  printf("\nDocument YAML:\n%s", yaml);
  free(yaml);

  spec_document_free(&doc);
  return 0;
}
