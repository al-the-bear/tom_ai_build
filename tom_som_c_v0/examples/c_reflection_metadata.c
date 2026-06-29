/* Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).
 *
 * HAND-AUTHORED — preserved across `generate_som` runs (the generator only
 * rewrites the header/source pair (include/, src/), meta/, schemas/ and the
 * Makefile).
 *
 * Demonstrates the value-free "reflection" surface: load the exported meta-data
 * (`meta/spec_model.meta.json`, the lossless class graph) into a `SpecModel` and
 * query its shape with `SpecReflection` — enumerate roots and fields, and
 * resolve a concrete document *path* to the model node it lands on. No document
 * values are involved; this answers "what CAN the model hold?", not "what does a
 * given document hold?".
 *
 * Run from the project root:  ./build/c_reflection_metadata [meta.json]
 * The meta-data path defaults to `meta/spec_model.meta.json` (relative to cwd);
 * pass an explicit path to run from elsewhere. `run_tests.sh` runs it from the
 * project root so the default resolves.
 */
#include "tom_som_c_runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Reads the whole file at `path` into an owned NUL-terminated buffer, or NULL. */
static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) return NULL;
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  if (n < 0) {
    fclose(f);
    return NULL;
  }
  fseek(f, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  if (buf == NULL) {
    fclose(f);
    return NULL;
  }
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

int main(int argc, char **argv) {
  const char *meta_path =
      argc > 1 ? argv[1] : "meta/spec_model.meta.json";
  char *data = read_file(meta_path);
  if (data == NULL) {
    fprintf(stderr, "could not read meta-data at %s\n", meta_path);
    return 1;
  }

  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(data, &err);
  free(data);
  if (model == NULL) {
    fprintf(stderr, "parse meta-data failed: %s\n", err != NULL ? err : "?");
    free(err);
    return 1;
  }

  SpecReflection ref = spec_reflection_make(model);

  const char *label = (model->model_version_label != NULL &&
                       model->model_version_label[0] != '\0')
                          ? model->model_version_label
                          : "unstamped";
  printf("Model version: %lld (%s)\n", model->model_version, label);
  printf("Roots: %zu, classes: %zu\n\n", model->roots_len, model->classes_len);

  /* Enumerate the document roots by their addressable segment. */
  printf("Document roots:\n");
  for (size_t i = 0; i < model->roots_len; i++) {
    const SpecRoot *root = &model->roots[i];
    printf("  %-4s %s\n", spec_reflection_root_segment(root),
           root->title != NULL ? root->title : "");
  }

  /* Inspect the fields of the D00SolutionBlueprint root class. */
  const SpecRoot *pd_root = spec_reflection_root_for_segment(&ref, "SBP");
  if (pd_root == NULL) {
    printf("SBP root not found\n");
    spec_model_free(model);
    return 1;
  }
  const SpecClass *pd_cls = spec_model_class_named(model, pd_root->type);
  size_t total = pd_cls != NULL ? pd_cls->fields_len : 0;
  printf("\nFirst fields of %s (%zu total):\n", pd_root->type, total);
  for (size_t i = 0; pd_cls != NULL && i < pd_cls->fields_len && i < 6; i++) {
    const SpecField *field = &pd_cls->fields[i];
    printf("  %-24s kind=%s", field->name, field->kind);
    if (field->type != NULL && field->type[0] != '\0') {
      printf("  type=%s", field->type);
    }
    if (field->element_type != NULL && field->element_type[0] != '\0') {
      printf("  elem=%s", field->element_type);
    }
    printf("\n");
  }

  /* Resolve concrete document paths to model nodes (value-free). */
  printf("\nPath resolution:\n");
  const char *paths[] = {
      "SBP",
      "SBP/content",
      "SBP/currentLandscape",
      "SBP/currentLandscape/CUOPME-OPER-LST",
  };
  for (size_t i = 0; i < sizeof(paths) / sizeof(paths[0]); i++) {
    SpecResolution res;
    if (spec_reflection_resolve(&ref, paths[i], &res) == 0) {
      printf("  %s  ->  (unresolved)\n", paths[i]);
      continue;
    }
    printf("  %-40s -> kind=%s", paths[i], res.kind);
    if (res.target_class != NULL) {
      printf("  class=%s", res.target_class->name);
    }
    printf("  value_leaf=%d\n", spec_resolution_is_value_leaf(&res));
    spec_resolution_free(&res);
  }

  spec_model_free(model);
  return 0;
}
