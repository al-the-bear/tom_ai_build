/* Unit tests for the §2.2 model-version editability classifier (§ item 8),
 * the C port of the Dart `somEditabilityFor` reference in
 * `tom_som_dart_runtime/lib/src/som_facade.dart`.
 *
 * Covers:
 *   - `som_editability_for`, mirroring every Dart case (with the CS4-D2
 *     empty-string sentinel standing in for Dart's `null`);
 *   - `check_som_model_version` reports an error exactly where the classifier is
 *     non-editable, and stays silent (returns 0) where it is editable, with the
 *     same error messages;
 *   - a facade behavioural check of a generated root's
 *     `<prefix>_editability_for`, whose emitted body is a one-line delegation to
 *     `som_editability_for(<ROOT>_MODEL_VERSION, document_version)`. The facade
 *     cannot be regenerated here, so the emitted shape is reproduced locally.
 *
 * Standalone: links the runtime static lib, exit 0 == all green.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_facade.h"

static int g_failures = 0;

#define CHECK(cond, msg)                                                    \
  do {                                                                      \
    if (!(cond)) {                                                          \
      fprintf(stderr, "FAIL: %s (%s:%d)\n", (msg), __FILE__, __LINE__);     \
      g_failures++;                                                         \
    }                                                                       \
  } while (0)

/* The object model's own version used throughout, matching the shared corpus
 * model version ("1.0" major.minor with a couple of higher-minor variants). */
#define GEN "1.3"

static void test_editability_for(void) {
  /* Absent stamp -> editable. CS4-D2: C uses the "" sentinel (Dart uses null);
   * be defensive about NULL too. */
  CHECK(som_editability_for(GEN, "") == SOM_EDITABILITY_EDITABLE,
        "empty stamp is editable");
  CHECK(som_editability_for(GEN, NULL) == SOM_EDITABILITY_EDITABLE,
        "NULL stamp is editable");

  /* Same major, older minor -> editable. */
  CHECK(som_editability_for(GEN, "1.0") == SOM_EDITABILITY_EDITABLE,
        "same-major older minor is editable");
  /* Same major, equal minor -> editable. */
  CHECK(som_editability_for(GEN, "1.3") == SOM_EDITABILITY_EDITABLE,
        "same-major equal minor is editable");

  /* Same major, newer minor -> rejected. */
  CHECK(som_editability_for(GEN, "1.4") == SOM_EDITABILITY_REJECTED_NEWER_MINOR,
        "same-major newer minor is rejected");

  /* Different major (higher) -> cross-major read-only. */
  CHECK(som_editability_for(GEN, "2.0") ==
            SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR,
        "higher major is cross-major read-only");
  /* Different major (lower) -> cross-major read-only. */
  CHECK(som_editability_for(GEN, "0.9") ==
            SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR,
        "lower major is cross-major read-only");

  /* Unparseable stamps -> invalid. */
  CHECK(som_editability_for(GEN, "not-a-version") ==
            SOM_EDITABILITY_INVALID_VERSION,
        "garbage stamp is invalid");
  CHECK(som_editability_for(GEN, "1") == SOM_EDITABILITY_INVALID_VERSION,
        "single-component stamp is invalid");
  CHECK(som_editability_for(GEN, "1.2.3") == SOM_EDITABILITY_INVALID_VERSION,
        "three-component stamp is invalid");
  CHECK(som_editability_for(GEN, "1.x") == SOM_EDITABILITY_INVALID_VERSION,
        "non-numeric minor is invalid");

  /* An unparseable generated version also classifies as invalid (matching Go). */
  CHECK(som_editability_for("bogus", "1.0") == SOM_EDITABILITY_INVALID_VERSION,
        "unparseable generated is invalid");
}

/* Asserts check_som_model_version reports (or not) exactly in line with the
 * classifier, and that a reported message contains an expected fragment. */
static void expect_check(const char *generated, const char *document_version,
                         int want_err, const char *want_fragment) {
  char *msg = NULL;
  int rc = check_som_model_version(generated, document_version, &msg);
  CHECK(rc == want_err, "check_som_model_version return code");
  if (want_err) {
    CHECK(msg != NULL, "error message allocated on rejection");
    if (msg != NULL && want_fragment != NULL) {
      CHECK(strstr(msg, want_fragment) != NULL,
            "error message contains expected fragment");
    }
  } else {
    CHECK(msg == NULL, "no error message on acceptance");
  }
  free(msg);
}

static void test_check_matches_classifier(void) {
  /* Editable cases: no error reported. */
  expect_check(GEN, "", 0, NULL);
  expect_check(GEN, NULL, 0, NULL);
  expect_check(GEN, "1.0", 0, NULL);
  expect_check(GEN, "1.3", 0, NULL);

  /* Newer minor: rejected with the "is newer" message. */
  expect_check(GEN, "1.4", 1, "is newer than the object model version");

  /* Cross-major: rejected with the "cross-major" message. */
  expect_check(GEN, "2.0", 1, "cross-major documents are read-only");

  /* Invalid document stamp: rejected with the "not a valid major.minor"
   * message referencing the document. */
  expect_check(GEN, "nope", 1, "document model version");

  /* Invalid generated version: rejected with the "not a valid major.minor
   * version" message referencing the generated version. */
  expect_check("bogus", "1.0", 1, "is not a valid major.minor version");
}

/* ---- facade behavioural check ------------------------------------------- */

/* Reproduction of the emitter's generated per-root shape. The C emitter emits,
 * for a root facade with prefix `p`:
 *
 *   #define P_MODEL_VERSION "<modelVersion>"
 *   SomEditability p_editability_for(const char *document_version) {
 *     return som_editability_for(P_MODEL_VERSION, document_version);
 *   }
 *
 * We stand this in locally (the facade cannot be regenerated in this task) and
 * assert it delegates identically to the classifier. */
#define DEMO_ROOT_MODEL_VERSION "1.3"

static SomEditability demo_root_editability_for(const char *document_version) {
  return som_editability_for(DEMO_ROOT_MODEL_VERSION, document_version);
}

static void test_root_editability_for(void) {
  CHECK(demo_root_editability_for("") == SOM_EDITABILITY_EDITABLE,
        "root facade: empty stamp editable");
  CHECK(demo_root_editability_for("1.3") == SOM_EDITABILITY_EDITABLE,
        "root facade: equal minor editable");
  CHECK(demo_root_editability_for("1.9") ==
            SOM_EDITABILITY_REJECTED_NEWER_MINOR,
        "root facade: newer minor rejected");
  CHECK(demo_root_editability_for("9.0") ==
            SOM_EDITABILITY_READ_ONLY_CROSS_MAJOR,
        "root facade: cross-major read-only");
  CHECK(demo_root_editability_for("bad") == SOM_EDITABILITY_INVALID_VERSION,
        "root facade: invalid stamp");
  /* Delegation invariant: the facade result matches the classifier called with
   * the root's own model version. */
  const char *stamps[] = {"", "1.0", "1.3", "1.9", "9.0", "bad", "1.2.3"};
  for (size_t i = 0; i < sizeof(stamps) / sizeof(stamps[0]); i++) {
    CHECK(demo_root_editability_for(stamps[i]) ==
              som_editability_for(DEMO_ROOT_MODEL_VERSION, stamps[i]),
          "root facade delegates to som_editability_for");
  }
}

int main(void) {
  test_editability_for();
  test_check_matches_classifier();
  test_root_editability_for();
  if (g_failures == 0) {
    printf("facade_editability: all checks passed\n");
    return 0;
  }
  fprintf(stderr, "facade_editability: %d check(s) failed\n", g_failures);
  return 1;
}
