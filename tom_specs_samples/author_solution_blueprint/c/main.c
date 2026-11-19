/* TomSpecs sample — author a Solution Blueprint end to end (C).
 *
 * The C port of `../bin/author_solution_blueprint.dart`: the same six steps,
 * the same document, the same output (`../expected_output.txt`).
 *
 * Build and run (from this folder; see README.md):  make && ./build/sample
 *
 * Six steps, in the order a real authoring task takes them:
 *
 *   1. open a fresh document and a typed root
 *   2. author a small but coherent Solution Blueprint
 *   3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
 *   4. round-trip the yaml back through the one-call typed loader and prove
 *      the reload is equal to what was written
 *   5. validate on the instance tier
 *   6. break one rule deliberately and read the diagnostic
 *
 * MEMORY OWNERSHIP, as the runtime headers state it and this file follows it:
 *
 *   - A `SpecDocument` is owned by whoever initialised it (`spec_document_init`
 *     → `spec_document_free`; a heap one from `spec_document_from_yaml` or a
 *     `*_load_file` also needs `free`). It must outlive every facade bound to
 *     it: facades and `SomList` views BORROW the document.
 *   - Every facade value (`D00SolutionBlueprint`, `CurrentLandscape`, …) owns
 *     its path and is released with its `*_free`; so is a `SomList`.
 *   - Functions returning `char *` return an OWNED string the caller frees:
 *     typed content getters, `som_list_add*`, `encode_yaml`,
 *     `spec_document_to_markdown`, every `char **err`.
 *   - Functions returning `const char *` BORROW: `som_node_path` (valid while
 *     the node lives), `spec_document_content` and `som_list_item_path_at`
 *     (valid until the document is next mutated).
 *   - `validate_document` fills a `SpecValidationErrors` whose strings it owns;
 *     release with `spec_validation_errors_free`. A `SpecModel` from
 *     `spec_model_from_json_str` is released with `spec_model_free`.
 *
 * The sample runs clean under AddressSanitizer and a leak checker
 * (`tool/validate.sh`).
 */
#include "tom_som_c_v0.h"
#include "tom_som_c_v0_meta.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

static void wrote(const char *path, const char *what) {
  printf("   %-46s %s\n", path, what);
}

/* The number of lines in `s`, ignoring trailing whitespace. */
static int lines(const char *s) {
  size_t end = strlen(s);
  while (end > 0 && (s[end - 1] == '\n' || s[end - 1] == ' ' || s[end - 1] == '\t' || s[end - 1] == '\r')) {
    end--;
  }
  int n = 1;
  for (size_t i = 0; i < end; i++) {
    if (s[i] == '\n') n++;
  }
  return n;
}

/* Reads a whole file; owned result, NULL when it cannot be read. */
static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) return NULL;
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  fseek(f, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

static int write_file(const char *path, const char *text) {
  FILE *f = fopen(path, "wb");
  if (f == NULL) return 1;
  fputs(text, f);
  fclose(f);
  return 0;
}

/* The whole model the facade project ships, read from the checkout:
 * `tom_som_c_v0/meta/spec_model.meta.json`. Owned; `spec_model_free`. */
static SpecModel *load_model(void) {
  const char *path = TOMSPECS_CHECKOUT "/tom_som_c_v0/meta/spec_model.meta.json";
  char *json = read_file(path);
  if (json == NULL) {
    fprintf(stderr, "cannot read %s\n", path);
    return NULL;
  }
  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(json, &err);
  free(json);
  if (model == NULL) {
    fprintf(stderr, "model: %s\n", err != NULL ? err : "?");
    free(err);
  }
  return model;
}

int main(void) {
  mkdir("build", 0755);

  /* ------------------------------------------------------------ step 1
   * A typed root over a fresh, empty document. Constructing the root also
   * runs the instantiation-time model-version check (SOM §4.2): an unstamped
   * document is editable, a document from a newer model is refused. */
  SpecDocument doc;
  spec_document_init(&doc);
  D00SolutionBlueprint sbp;
  if (d00_solution_blueprint_new(&sbp, &doc, "", NULL) != 0) {
    fprintf(stderr, "failed to create the typed root\n");
    return 1;
  }

  printf("1. A typed root over an empty document\n");
  printf("   object model version : %s\n", d00_solution_blueprint_object_model_version(&sbp));
  printf("   root path            : %s\n", som_node_path(&sbp.node));
  printf("\n");

  /* ------------------------------------------------------------ step 2
   * Author. Every write below goes through a NAMED accessor — no string
   * paths — and lands in the same path-keyed store the generic API reads. */
  printf("2. Authoring, printing each section id as it is written\n");

  d00_solution_blueprint_set_content(&sbp, "Unify three legacy order systems behind one customer record.");
  wrote(som_node_path(&sbp.node), "the blueprint itself");

  IntroductionAndScope intro = d00_solution_blueprint_introduction_and_scope(&sbp);
  introduction_and_scope_set_content(&intro, "Replace per-region order intake with a single pipeline.");
  wrote(som_node_path(&intro.node), "introduction and scope");

  CurrentLandscape landscape = d00_solution_blueprint_current_landscape(&sbp);
  current_landscape_set_content(&landscape, "Three systems, no shared customer record, manual reconciliation.");
  wrote(som_node_path(&landscape.node), "the current landscape");

  /* A list section. `som_list_add` appends an item and returns its path
   * (owned); the typed item is a view bound to that path. */
  SomList metrics = current_landscape_operational_metrics(&landscape);
  const char *metric_texts[] = {
      "Average order turnaround: 4.2 days.",
      "Manual reconciliation: about 12 hours a week.",
  };
  for (size_t i = 0; i < 2; i++) {
    char *item_path = som_list_add(&metrics);
    CurrentOperationalMetric metric;
    current_operational_metric_init(&metric, &doc, item_path);
    current_operational_metric_set_content(&metric, metric_texts[i]);
    current_operational_metric_free(&metric);
    free(item_path);
  }
  char what[64];
  snprintf(what, sizeof what, "%zu operational metrics", som_list_length(&metrics));
  wrote(metrics.list_path, what);
  printf("\n");

  /* ------------------------------------------------------------ step 3
   * Both renditions of the same document. They are two encodings of one
   * store, not two documents — which is why step 4 can round-trip either.
   *
   * `spec_document_to_markdown` and the validator both need a whole
   * SpecModel: the facade project ships it as `meta/spec_model.meta.json`. */
  SpecModel *model = load_model();
  if (model == NULL) return 1;
  char *version = som_model_version_string(model->model_version, model->model_version_label);
  const SomMetaTree *tree = d00_solution_blueprint_meta_tree();

  char *yaml = encode_yaml(&doc, tree, version, NULL);
  char *markdown = spec_document_to_markdown(&doc, model, "D00SolutionBlueprint", NULL);
  if (yaml == NULL || markdown == NULL) {
    fprintf(stderr, "serialisation failed\n");
    return 1;
  }
  write_file("build/blueprint.tomspecs.yaml", yaml);
  write_file("build/blueprint.tomspecs.md", markdown);

  printf("3. Serialised both renditions into build/\n");
  printf("   blueprint.tomspecs.yaml : %d lines  (SOM §12)\n", lines(yaml));
  printf("   blueprint.tomspecs.md   : %d lines  (SOM §11)\n", lines(markdown));
  printf("\n");

  /* ------------------------------------------------------------ step 4
   * The one-call typed loader: decode, apply the document's own authoring
   * stamp, and hand back a typed root. Re-encoding the reload and comparing
   * the two strings is the actual proof — comparing field by field would only
   * prove the fields somebody thought to compare. The loaded document is
   * owned here (`spec_document_free` + `free`); the root borrows it. */
  D00SolutionBlueprint reloaded;
  SpecDocument *reloaded_doc = NULL;
  char *err = NULL;
  if (d00_solution_blueprint_load_file(&reloaded, "build/blueprint.tomspecs.yaml", &reloaded_doc, &err) != 0) {
    fprintf(stderr, "reload: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }
  char *re_yaml = encode_yaml(reloaded_doc, tree, version, NULL);

  CurrentLandscape re_landscape = d00_solution_blueprint_current_landscape(&reloaded);
  SomList re_metrics = current_landscape_operational_metrics(&re_landscape);
  CurrentOperationalMetric first;
  current_operational_metric_init(&first, reloaded_doc, som_list_item_path_at(&re_metrics, 0));
  char *first_value = current_operational_metric_content(&first);

  printf("4. Round-tripped the yaml through D00SolutionBlueprint.loadFile\n");
  printf("   reload equals original  : %s\n", re_yaml != NULL && strcmp(re_yaml, yaml) == 0 ? "true" : "false");
  printf("   a value read back typed : \"%s\"\n", first_value);
  printf("\n");

  free(first_value);
  current_operational_metric_free(&first);
  som_list_free(&re_metrics);
  current_landscape_free(&re_landscape);
  d00_solution_blueprint_free(&reloaded);
  spec_document_free(reloaded_doc);
  free(reloaded_doc);
  free(re_yaml);

  /* ------------------------------------------------------------ step 5 */
  SpecValidationErrors errors;
  validate_document(model, &doc, &errors);
  printf("5. Instance-tier validation\n");
  printf("   violations              : %zu\n", errors.len);
  printf("\n");
  spec_validation_errors_free(&errors);

  /* ------------------------------------------------------------ step 6
   * What a violation looks like. Writing to a path the model does not
   * declare is the clearest break to stage: the store accepts it — it is a
   * plain path-keyed map — and the validator is what notices. */
  SpecDocument *broken = spec_document_from_yaml(yaml, tree, NULL);
  spec_document_set_content(broken, "SBP/noSuchSection/content", "not part of the model");

  SpecValidationErrors broken_errors;
  validate_document(model, broken, &broken_errors);
  printf("6. The same document with one rule deliberately broken\n");
  printf("   violations              : %zu\n", broken_errors.len);
  for (size_t i = 0; i < broken_errors.len; i++) {
    printf("   %s: %s\n", broken_errors.items[i].code, broken_errors.items[i].path);
    printf("     %s\n", broken_errors.items[i].message);
  }
  printf("\n");
  printf("Done. The two renditions are in build/.\n");

  spec_validation_errors_free(&broken_errors);
  spec_document_free(broken);
  free(broken);
  free(yaml);
  free(markdown);
  free(version);
  spec_model_free(model);
  som_list_free(&metrics);
  current_landscape_free(&landscape);
  introduction_and_scope_free(&intro);
  d00_solution_blueprint_free(&sbp);
  spec_document_free(&doc);
  return 0;
}
