/* Unit tests for the SOM §21 content-only list convenience in the C list API
 * (`som_list_add_content` / `som_list_add_content_on` /
 * `som_list_add_content_with_id` / `som_list_contents`),
 * the C port of the Dart `SomList.addContent` + `SomList.contents` reference in
 * `tom_som_dart_runtime/lib/src/som_facade.dart`.
 *
 * A content-only element type is modelled by a plain list field whose items
 * each carry a nested `<item>/content` leaf — the same shape the Dart reference
 * writes with `doc.setContent('$itemPath/content', content)`.
 *
 * Covers:
 *   (a) add_content appends an item and sets its nested content leaf, visible
 *       through the generic `spec_document_content` read;
 *   (b) a pattern-carrying list honours its `@SectionIdPattern` on add_content;
 *   (c) add_content_on accepts an explicit (month, day) override for the id;
 *   (d) `som_list_contents` yields every item's content in item order;
 *   (e) `som_list_contents` reads "" for an item with no content leaf set;
 *   (f) `som_list_add_content_with_id` stores the explicit id and the content;
 *   (g) a colliding explicit id is reported as COLLISION, adding nothing;
 *   (h) a pattern-less list ignores the id on `som_list_add_with_id` and
 *       `som_list_add_content_with_id` and appends plainly.
 *
 * Standalone: links the runtime static lib, exit 0 == all green.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_facade.h"
#include "spec_document.h"

static int g_failures = 0;

#define CHECK(cond, msg)                                                    \
  do {                                                                      \
    if (!(cond)) {                                                          \
      fprintf(stderr, "FAIL: %s (%s:%d)\n", (msg), __FILE__, __LINE__);     \
      g_failures++;                                                         \
    }                                                                       \
  } while (0)

#define CHECK_STR(got, want, msg)                                           \
  do {                                                                      \
    const char *g_ = (got);                                                 \
    const char *w_ = (want);                                                \
    if (g_ == NULL || strcmp(g_, w_) != 0) {                                \
      fprintf(stderr, "FAIL: %s: got \"%s\" want \"%s\" (%s:%d)\n", (msg),  \
              g_ != NULL ? g_ : "(null)", w_, __FILE__, __LINE__);          \
      g_failures++;                                                         \
    }                                                                       \
  } while (0)

/* (a) add_content appends + sets the nested content leaf, readable generically. */
static void test_add_content_sets_leaf(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init(&list, &doc, "notes"); /* pattern-less */

  CHECK(som_list_length(&list) == 0, "list starts empty");
  char *item = som_list_add_content(&list, "hello world");
  CHECK(item != NULL, "add_content returns an item path");
  CHECK(som_list_length(&list) == 1, "add_content appended one item");

  /* Same handle the plain add returns: it is the appended item's path. */
  CHECK_STR(som_list_item_path_at(&list, 0), item,
            "returned handle equals the appended item path");

  /* The content lands at the nested <item>/content leaf, visible generically. */
  char leaf[256];
  snprintf(leaf, sizeof(leaf), "%s/content", item);
  CHECK_STR(spec_document_content(&doc, leaf), "hello world",
            "nested content leaf holds the value");

  free(item);
  som_list_free(&list);
  spec_document_free(&doc);
}

/* (b) a pattern-carrying list honours its @SectionIdPattern on add_content. */
static void test_add_content_honours_pattern(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init_pattern(&list, &doc, "tasks", "TASK-xxx");

  /* add_content_on pins the date so the generated id is deterministic:
   * month 3 -> 'C', day 1 -> 'A', first-of-day -> 1  =>  "TASK-CA1". */
  char *item = som_list_add_content_on(&list, "do the thing", 3, 1);
  CHECK(item != NULL, "add_content_on returns an item path");

  char *id = spec_document_item_section_id(&doc, item) != NULL
                 ? som_strdup(spec_document_item_section_id(&doc, item))
                 : NULL;
  CHECK_STR(id, "TASK-CA1", "generated section id follows the pattern");

  char leaf[256];
  snprintf(leaf, sizeof(leaf), "%s/content", item);
  CHECK_STR(spec_document_content(&doc, leaf), "do the thing",
            "content leaf set alongside the generated id");

  free(id);
  free(item);
  som_list_free(&list);
  spec_document_free(&doc);
}

/* (c) add_content_on accepts an explicit (month, day) override for the id. */
static void test_add_content_on_date_override(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init_pattern(&list, &doc, "tasks", "TASK-xxx");

  /* month 12 -> 'L', day 26 -> 'Z'  =>  "TASK-LZ1". */
  char *item = som_list_add_content_on(&list, "later", 12, 26);
  const char *id = spec_document_item_section_id(&doc, item);
  CHECK_STR(id, "TASK-LZ1", "explicit date drives the two-letter-date code");

  free(item);
  som_list_free(&list);
  spec_document_free(&doc);
}

/* (d) contents yields every item's content in order; (e) "" for a missing leaf. */
static void test_contents_ordered_and_missing(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init(&list, &doc, "notes");

  char *a = som_list_add_content(&list, "first");
  char *b = som_list_add(&list); /* item WITHOUT a content leaf */
  char *c = som_list_add_content(&list, "third");

  SomStrList contents;
  som_list_contents(&list, &contents);
  CHECK(contents.len == 3, "contents has one entry per item");
  if (contents.len == 3) {
    CHECK_STR(contents.items[0], "first", "contents[0] is the first content");
    CHECK_STR(contents.items[1], "",
              "contents[1] coalesces a missing leaf to empty string");
    CHECK_STR(contents.items[2], "third", "contents[2] is the third content");
  }

  som_strlist_free(&contents);
  free(a);
  free(b);
  free(c);
  som_list_free(&list);
  spec_document_free(&doc);
}

/* (f) explicit id + content; (g) a colliding id adds nothing. */
static void test_add_content_with_id(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init_pattern(&list, &doc, "tasks", "TASK-xxx");

  char *item = NULL;
  SpecSectionIdError err;
  spec_section_id_error_init(&err);
  int ok = som_list_add_content_with_id(&list, "alpha", "TASK-ALPHA", &item,
                                        &err);
  CHECK(ok == 1, "explicit id add succeeds");
  CHECK(err.kind == SPEC_SECTION_ID_OK, "no error on success");
  CHECK_STR(item, "tasks-1", "first item path");
  CHECK_STR(spec_document_item_section_id(&doc, item), "TASK-ALPHA",
            "explicit id stored");
  char leaf[256];
  snprintf(leaf, sizeof(leaf), "%s/content", item);
  CHECK_STR(spec_document_content(&doc, leaf), "alpha", "content leaf set");
  free(item);

  char *again = NULL;
  ok = som_list_add_content_with_id(&list, "again", "TASK-ALPHA", &again, &err);
  CHECK(ok == 0, "colliding id refused");
  CHECK(again == NULL, "no item path on collision");
  CHECK(spec_section_id_is_collision(&err), "collision reported");
  CHECK_STR(err.id, "TASK-ALPHA", "collision names the id");
  CHECK(som_list_length(&list) == 1, "collision adds nothing");
  spec_section_id_error_free(&err);

  /* NULL out path: the item is still added and the path freed internally. */
  ok = som_list_add_content_with_id(&list, "beta", "TASK-BETA", NULL, NULL);
  CHECK(ok == 1 && som_list_length(&list) == 2, "NULL out path still adds");

  som_list_free(&list);
  spec_document_free(&doc);
}

/* (h) a pattern-less list ignores the explicit id and appends plainly. */
static void test_patternless_ignores_id(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  SomList list;
  som_list_init(&list, &doc, "refs");

  char *a = NULL, *b = NULL, *c = NULL;
  CHECK(som_list_add_with_id(&list, "REF-X", &a, NULL) == 1,
        "add_with_id on a pattern-less list succeeds");
  /* The same id again: ignored, so no collision. */
  CHECK(som_list_add_with_id(&list, "REF-X", &b, NULL) == 1,
        "repeated id ignored on a pattern-less list");
  CHECK(som_list_add_content_with_id(&list, "plain", "REF-X", &c, NULL) == 1,
        "add_content_with_id on a pattern-less list succeeds");
  CHECK(a != NULL && spec_document_item_section_id(&doc, a) == NULL,
        "no section id stored (add_with_id)");
  CHECK(c != NULL && spec_document_item_section_id(&doc, c) == NULL,
        "no section id stored (add_content_with_id)");
  SomStrList ids;
  som_list_section_ids(&list, &ids);
  CHECK(ids.len == 0, "pattern-less list has no section ids");
  som_strlist_free(&ids);
  if (c != NULL) {
    char leaf[256];
    snprintf(leaf, sizeof(leaf), "%s/content", c);
    CHECK_STR(spec_document_content(&doc, leaf), "plain", "content leaf set");
  }
  CHECK(som_list_length(&list) == 3, "three items appended");

  free(a);
  free(b);
  free(c);
  som_list_free(&list);
  spec_document_free(&doc);
}

int main(void) {
  test_add_content_sets_leaf();
  test_add_content_honours_pattern();
  test_add_content_on_date_override();
  test_contents_ordered_and_missing();
  test_add_content_with_id();
  test_patternless_ignores_id();
  if (g_failures == 0) {
    printf("list_add_content: all checks passed\n");
    return 0;
  }
  fprintf(stderr, "list_add_content: %d check(s) failed\n", g_failures);
  return 1;
}
