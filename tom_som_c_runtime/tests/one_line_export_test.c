/* Unit test for the SOM §21 one-line export (root-by-type + one-call
 * Markdown), the C port of the Dart reference in `tom_som_dart_runtime`
 * (groups `SpecModel.rootByType (one-line export, SOM §21)` in
 * spec_model_test.dart and `SpecDocument.toMarkdown (one-line export,
 * SOM §21)` in spec_document_markdown_test.dart).
 *
 * FEATURE 1 — `spec_model_root_by_type`: returns the root whose type matches, or
 * NULL (setting an owned `err` message that names the missing and available
 * types) on no match — the C null-return + `char **err` convention mirroring the
 * Dart `ArgumentError`.
 *
 * FEATURE 2 — `spec_document_to_markdown`: exports a root by name, or defaults to
 * the single *populated* root; NULL + owned `err` when the default is ambiguous
 * (zero or more than one populated root), mirroring the Dart `StateError`.
 *
 * Standalone: links the runtime static lib, exit 0 == all green.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document.h"
#include "spec_document_markdown.h"
#include "spec_model.h"

static int g_failures = 0;

#define CHECK(cond, msg)                                                    \
  do {                                                                      \
    if (!(cond)) {                                                          \
      fprintf(stderr, "FAIL: %s (%s:%d)\n", (msg), __FILE__, __LINE__);     \
      g_failures++;                                                         \
    }                                                                       \
  } while (0)

/* A two-root model with no fields, mirroring the Dart `twoRootModel()`. */
static SpecModel *two_root_model(void) {
  const char *json =
      "{\"roots\":["
      "{\"type\":\"Alpha\",\"title\":\"Alpha Doc\",\"sectionId\":\"A00\"},"
      "{\"type\":\"Beta\",\"title\":\"Beta Doc\",\"sectionId\":\"B00\"}"
      "],\"classes\":{}}";
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(json, &err);
  if (m == NULL) {
    fprintf(stderr, "two_root_model parse failed: %s\n", err ? err : "?");
    free(err);
  }
  return m;
}

/* FEATURE 1: returns the root whose type matches. */
static void test_root_by_type_matches(void) {
  SpecModel *m = two_root_model();
  CHECK(m != NULL, "model parsed");
  if (m == NULL) return;

  char *err = NULL;
  const SpecRoot *alpha = spec_model_root_by_type(m, "Alpha", &err);
  CHECK(alpha != NULL, "Alpha root found");
  CHECK(err == NULL, "no error on a match");
  CHECK(alpha != NULL && strcmp(alpha->title, "Alpha Doc") == 0,
        "Alpha title matches");

  const SpecRoot *beta = spec_model_root_by_type(m, "Beta", &err);
  CHECK(beta != NULL && strcmp(beta->section_id, "B00") == 0,
        "Beta sectionId matches");

  spec_model_free(m);
}

/* FEATURE 1: NULL + a message naming the missing and available types. */
static void test_root_by_type_missing(void) {
  SpecModel *m = two_root_model();
  if (m == NULL) return;

  char *err = NULL;
  const SpecRoot *gamma = spec_model_root_by_type(m, "Gamma", &err);
  CHECK(gamma == NULL, "missing type returns NULL");
  CHECK(err != NULL, "missing type sets an error message");
  if (err != NULL) {
    CHECK(strstr(err, "Alpha") != NULL, "message names available Alpha");
    CHECK(strstr(err, "Beta") != NULL, "message names available Beta");
    CHECK(strstr(err, "Gamma") != NULL, "message names the missing Gamma");
    free(err);
  }

  /* err may be NULL — must not crash. */
  CHECK(spec_model_root_by_type(m, "Gamma", NULL) == NULL,
        "missing type with NULL err returns NULL");

  spec_model_free(m);
}

/* A one-root model with a single content field, for the export cases. */
static SpecModel *demo_model(void) {
  const char *json =
      "{\"roots\":[{\"type\":\"DemoDoc\",\"title\":\"Demo Document\","
      "\"sectionId\":\"D00\"}],\"classes\":{"
      "\"DemoDoc\":{\"name\":\"DemoDoc\",\"sectionId\":\"D00\",\"fields\":["
      "{\"name\":\"overview\",\"kind\":\"content\",\"sectionId\":\"D00-OVR\"}"
      "]}}}";
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(json, &err);
  if (m == NULL) {
    fprintf(stderr, "demo_model parse failed: %s\n", err ? err : "?");
    free(err);
  }
  return m;
}

/* FEATURE 2: an explicit root_type matches the direct codec output, and the
 * NULL (default) form picks the single populated root — same output. */
static void test_to_markdown_explicit_and_default(void) {
  SpecModel *m = demo_model();
  CHECK(m != NULL, "demo model parsed");
  if (m == NULL) return;

  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-OVR", "An overview paragraph.");

  char *err = NULL;
  char *one_liner = spec_document_to_markdown(&doc, m, "DemoDoc", &err);
  CHECK(one_liner != NULL, "explicit rootType exports");
  CHECK(err == NULL, "no error on explicit rootType");

  const SpecRoot *root = spec_model_root_by_type(m, "DemoDoc", NULL);
  char *explicit = spec_markdown_export_root(m, &doc, root, NULL);
  CHECK(one_liner != NULL && explicit != NULL &&
            strcmp(one_liner, explicit) == 0,
        "toMarkdown(rootType) equals exportRoot(rootByType)");

  /* Default (NULL root_type) resolves to the single populated root: DemoDoc. */
  char *defaulted = spec_document_to_markdown(&doc, m, NULL, &err);
  CHECK(defaulted != NULL, "default export resolves the single populated root");
  CHECK(defaulted != NULL && one_liner != NULL &&
            strcmp(defaulted, one_liner) == 0,
        "default output equals the explicit-DemoDoc output");

  free(one_liner);
  free(explicit);
  free(defaulted);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* FEATURE 2: an empty document has no populated root → NULL + a message. */
static void test_to_markdown_no_populated_root(void) {
  SpecModel *m = demo_model();
  if (m == NULL) return;

  SpecDocument doc;
  spec_document_init(&doc);

  char *err = NULL;
  char *md = spec_document_to_markdown(&doc, m, NULL, &err);
  CHECK(md == NULL, "no populated root returns NULL");
  CHECK(err != NULL, "no populated root sets an error message");
  if (err != NULL) {
    CHECK(strstr(err, "no populated root") != NULL,
          "message mentions no populated root");
    free(err);
  }

  spec_document_free(&doc);
  spec_model_free(m);
}

/* FEATURE 2: two populated roots → NULL + a message naming both candidates. */
static void test_to_markdown_ambiguous_roots(void) {
  const char *json =
      "{\"roots\":["
      "{\"type\":\"Alpha\",\"title\":\"Alpha Doc\",\"sectionId\":\"A00\"},"
      "{\"type\":\"Beta\",\"title\":\"Beta Doc\",\"sectionId\":\"B00\"}"
      "],\"classes\":{"
      "\"Alpha\":{\"name\":\"Alpha\",\"sectionId\":\"A00\",\"fields\":["
      "{\"name\":\"overview\",\"kind\":\"content\",\"sectionId\":\"A00-OVR\"}]},"
      "\"Beta\":{\"name\":\"Beta\",\"sectionId\":\"B00\",\"fields\":["
      "{\"name\":\"overview\",\"kind\":\"content\",\"sectionId\":\"B00-OVR\"}]}"
      "}}";
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(json, &err);
  CHECK(m != NULL, "ambiguous model parsed");
  if (m == NULL) {
    free(err);
    return;
  }

  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "A00/A00-OVR", "a");
  spec_document_set_content(&doc, "B00/B00-OVR", "b");

  char *md = spec_document_to_markdown(&doc, m, NULL, &err);
  CHECK(md == NULL, "ambiguous default returns NULL");
  CHECK(err != NULL, "ambiguous default sets an error message");
  if (err != NULL) {
    CHECK(strstr(err, "Alpha") != NULL, "message names candidate Alpha");
    CHECK(strstr(err, "Beta") != NULL, "message names candidate Beta");
    free(err);
  }

  spec_document_free(&doc);
  spec_model_free(m);
}

int main(void) {
  test_root_by_type_matches();
  test_root_by_type_missing();
  test_to_markdown_explicit_and_default();
  test_to_markdown_no_populated_root();
  test_to_markdown_ambiguous_roots();
  if (g_failures == 0) {
    printf("one_line_export: all checks passed\n");
    return 0;
  }
  fprintf(stderr, "one_line_export: %d check(s) failed\n", g_failures);
  return 1;
}
