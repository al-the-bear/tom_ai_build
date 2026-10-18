/* Unit tests for the prefix index behind `spec_document_has_values_under`,
 * the C port of the Dart reference's `value_index_test.dart`.
 *
 * `spec_document_has_values_under` answers from a lazily built prefix index
 * rather than a scan of every stored key. The markdown emitter, the validator
 * and the query engine ask it once per model node, so a scan made rendering a
 * large specification quadratic.
 *
 *   VI-1 holds the index to the scan it replaces, across every mutator, so a
 *        mutation that forgets to drop the index fails here.
 *   VI-2 guards the complexity itself: 20,000 stored values and 20,000 pairs
 *        of queries under a generous bound only a per-query scan can miss.
 *
 * Standalone: links the runtime static lib, exit 0 == all green.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "spec_document.h"
#include "spec_model.h"

static int g_failures = 0;

#define CHECK(cond, msg)                                                    \
  do {                                                                      \
    if (!(cond)) {                                                          \
      fprintf(stderr, "FAIL: %s (%s:%d)\n", (msg), __FILE__, __LINE__);     \
      g_failures++;                                                         \
    }                                                                       \
  } while (0)

/* The predicate the index must reproduce: a key of one of the five value
 * stores equal to `prefix`, or continuing it after a '/' or a '-'. */
static int under(const char *key, const char *prefix) {
  size_t n = strlen(prefix);
  if (strncmp(key, prefix, n) != 0) {
    return 0;
  }
  return key[n] == '\0' || key[n] == '/' || key[n] == '-';
}

static int list_has_under(const SomStrList *l, const char *prefix) {
  for (size_t i = 0; i < l->len; i++) {
    if (under(l->items[i], prefix)) {
      return 1;
    }
  }
  return 0;
}

static int scan(const SpecDocument *d, const char *prefix) {
  void (*stores[5])(const SpecDocument *, SomStrList *) = {
      spec_document_content_paths, spec_document_form_paths,
      spec_document_list_paths, spec_document_headline_paths,
      spec_document_code_spec_paths};
  int hit = 0;
  for (size_t s = 0; s < 5 && !hit; s++) {
    SomStrList keys;
    stores[s](d, &keys);
    hit = list_has_under(&keys, prefix);
    som_strlist_free(&keys);
  }
  return hit;
}

static const char *const PROBES[] = {
    "DEMO",          "DEMO/TTL",           "DEMO/TT",      "DEMO/SUM",
    "DEMO/DET",      "DEMO/items",         "DEMO/items-1", "DEMO/items-1/label",
    "DEMO/items-2",  "DEMO/items-3",       "DEMO/REF-LST", "DEMO/REF",
    "DEMO/CARD-LST-1", "DEMO/CARD",        "OTHER",        "OTHER/X",
    "DEM",           "",
};

static void expect_agrees(const SpecDocument *d, const char *when) {
  for (size_t i = 0; i < sizeof(PROBES) / sizeof(PROBES[0]); i++) {
    int got = spec_document_has_values_under(d, PROBES[i]);
    int want = scan(d, PROBES[i]);
    if (got != want) {
      fprintf(stderr, "FAIL: VI-1 %s: \"%s\" index=%d scan=%d\n", when,
              PROBES[i], got, want);
      g_failures++;
    }
  }
}

/* A minimal model for `spec_document_move_list_item`: a Demo root with an
 * `items` list of complex `Item` elements. */
static const char *MODEL_JSON =
    "{\"metaSchemaVersion\":1,\"modelVersion\":1,\"classCount\":2,"
    "\"rootCount\":1,"
    "\"roots\":[{\"type\":\"Demo\",\"title\":\"Demo\",\"sectionId\":\"DEMO\"}],"
    "\"classes\":{"
    "\"Demo\":{\"name\":\"Demo\",\"sectionId\":\"DEMO\",\"fields\":["
    "{\"name\":\"title\",\"kind\":\"content\",\"sectionId\":\"TTL\"},"
    "{\"name\":\"items\",\"kind\":\"list\",\"elementType\":\"Item\","
    "\"elementIsComplex\":true}]},"
    "\"Item\":{\"name\":\"Item\",\"fields\":["
    "{\"name\":\"label\",\"kind\":\"content\"}]}}}";

/* VI-1: the index agrees with a full scan after every mutator. */
static void test_index_agrees_after_every_mutator(void) {
  SpecDocument d;
  spec_document_init(&d);
  expect_agrees(&d, "empty");

  spec_document_set_content(&d, "DEMO/TTL", "Hello");
  expect_agrees(&d, "set_content");
  spec_document_set_headline(&d, "DEMO/SUM", "Summary");
  expect_agrees(&d, "set_headline");
  spec_document_set_code_spec(&d, "DEMO/DET", "a.b");
  expect_agrees(&d, "set_code_spec");
  spec_document_set_form_field(&d, "DEMO/CARD-LST-1/content", "note", "x");
  expect_agrees(&d, "set_form_field");

  char *item = spec_document_add_list_item(&d, "DEMO/items");
  char label[256];
  snprintf(label, sizeof(label), "%s/label", item);
  spec_document_set_content(&d, label, "First");
  char *second = spec_document_add_list_item(&d, "DEMO/items");
  expect_agrees(&d, "add_list_item");

  char *third = spec_document_add_list_item_with_section_id(
      &d, "DEMO/items", "ITEM-C", NULL);
  CHECK(third != NULL, "add_list_item_with_section_id succeeds");
  expect_agrees(&d, "add_list_item_with_section_id");

  CHECK(spec_document_set_item_section_id(&d, item, "ITEM-A", NULL),
        "set_item_section_id succeeds");
  expect_agrees(&d, "set_item_section_id");

  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(MODEL_JSON, &err);
  CHECK(model != NULL, "minimal model decodes");
  if (model != NULL) {
    SpecListItemMove move;
    SpecListMoveError merr;
    spec_list_move_error_init(&merr);
    /* Move the first item (with its label) to the end: every path renumbers. */
    int ok = spec_document_move_list_item(&d, model, item, 2, NULL, &move,
                                          &merr);
    CHECK(ok, "move_list_item succeeds");
    expect_agrees(&d, "move_list_item");
    CHECK(spec_document_has_values_under(&d, "DEMO/items-3/label"),
          "moved label lives at its new path");
    CHECK(!spec_document_has_values_under(&d, "DEMO/items-1/label"),
          "moved label left its old path");
    spec_list_item_move_free(&move);
    spec_list_move_error_free(&merr);
    spec_model_free(model);
  }
  free(err);

  spec_document_set_content(&d, "DEMO/TTL", "");
  expect_agrees(&d, "set_content to empty");
  spec_document_set_form_field(&d, "DEMO/CARD-LST-1/content", "note", "");
  expect_agrees(&d, "set_form_field to empty");
  spec_document_set_headline(&d, "DEMO/SUM", "");
  expect_agrees(&d, "set_headline to empty");

  CHECK(spec_document_remove_list_item(&d, "DEMO/items-3"),
        "remove_list_item succeeds");
  expect_agrees(&d, "remove_list_item");

  spec_document_remove_values_under(&d, "DEMO/DET");
  expect_agrees(&d, "remove_values_under");

  DocumentJson j;
  document_json_init(&j);
  som_map_set(&j.content, "DEMO/REF-LST-1", "spec");
  som_map_set(&j.content, "OTHER/X", "y");
  DocListEntry *le = document_json_list_entry(&j, "DEMO/REF-LST");
  le->seq = 1;
  som_strlist_push_copy(&le->items, "DEMO/REF-LST-1");
  som_map_set(&j.headlines, "DEMO/CARD-LST-1", "Card");
  spec_document_load_json(&d, &j);
  document_json_free(&j);
  expect_agrees(&d, "load_json");

  spec_document_free(&d);
  expect_agrees(&d, "free");

  free(item);
  free(second);
  free(third);
  spec_document_free(&d);
}

/* VI-2: has_values_under is not a scan of every stored key. 20,000 stored
 * values and 40,000 queries: a per-query scan costs ~8 * 10^8 key
 * comparisons; the index answers in milliseconds. The bound is generous, so
 * only the complexity class can fail it. */
static void test_index_is_not_a_scan(void) {
  enum { N = 20000 };
  SpecDocument d;
  spec_document_init(&d);
  char path[128];
  char value[32];
  for (int i = 0; i < N; i++) {
    snprintf(path, sizeof(path), "ROOT/S%d/F%d", i / 100, i);
    snprintf(value, sizeof(value), "v%d", i);
    spec_document_set_content(&d, path, value);
  }
  clock_t start = clock();
  int hits = 0;
  for (int i = 0; i < N; i++) {
    snprintf(path, sizeof(path), "ROOT/S%d/F%d", i / 100, i);
    if (spec_document_has_values_under(&d, path)) {
      hits++;
    }
    snprintf(path, sizeof(path), "ROOT/S%d/G%d", i / 100, i);
    if (spec_document_has_values_under(&d, path)) {
      hits--;
    }
  }
  double seconds = (double)(clock() - start) / CLOCKS_PER_SEC;
  CHECK(hits == N, "VI-2: every stored value found, no false hit");
  if (seconds >= 2.0) {
    fprintf(stderr, "FAIL: VI-2 took %.3f s (bound 2 s)\n", seconds);
    g_failures++;
  }
  spec_document_free(&d);
}

int main(void) {
  test_index_agrees_after_every_mutator();
  test_index_is_not_a_scan();
  if (g_failures == 0) {
    printf("value_index: all checks passed\n");
    return 0;
  }
  fprintf(stderr, "value_index: %d check(s) failed\n", g_failures);
  return 1;
}
