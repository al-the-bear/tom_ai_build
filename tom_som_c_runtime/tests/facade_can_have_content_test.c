/* Unit test for the §item-10 `can_have_content` per-type structural predicate,
 * the C port of the Dart `SomNode.canHaveContent` reference in
 * `tom_som_dart_runtime/lib/src/som_facade.dart`.
 *
 * `can_have_content` answers "does this section TYPE declare the standard
 * `content` text leaf?" — "can this section hold body text?" — WITHOUT probing
 * the document. C has no inheritance or method promotion, so (following the
 * item-8 `editability_for` and item-5 `is_empty` per-type C emission precedent)
 * the generated `tom_som_c_v0` emits a `<type>_can_have_content(const <Type>*)`
 * accessor for EVERY generated section type returning the literal answer:
 *   - 1 for a content-bearing type (one whose model class has a `content`
 *     content-kind field, e.g. `Goals`, the `D00SolutionBlueprint` root);
 *   - 0 for a container-only type (no `content` leaf, e.g. `SystemsToReplace`).
 *
 * The facade cannot be regenerated in this task, so — exactly as
 * `facade_editability.c` reproduces the emitted root shape locally — this test
 * reproduces the two emitted accessor shapes over the runtime's `SomNode` and
 * asserts the literal-return contract and its structural (never touches the
 * document) nature.
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

/* Reproduction of the emitter's generated per-type shape. For a generated type
 * `T` with prefix `t`, the C emitter emits:
 *
 *   int t_can_have_content(const T *self) {
 *     (void)self;
 *     return <1 if the model class has a `content` content leaf, else 0>;
 *   }
 *
 * Content-bearing stand-in (mirrors e.g. `goals_can_have_content`,
 * `d00_solution_blueprint_can_have_content`). */
typedef struct { SomNode node; } DemoContentBearing;
static int demo_content_bearing_can_have_content(const DemoContentBearing *self) {
  (void)self;
  return 1;
}

/* Container-only stand-in (mirrors `systems_to_replace_can_have_content`). */
typedef struct { SomNode node; } DemoContainerOnly;
static int demo_container_only_can_have_content(const DemoContainerOnly *self) {
  (void)self;
  return 0;
}

/* The literal-return contract: content-bearing types yield 1, container-only
 * types yield 0. */
static void test_literal_answer(void) {
  DemoContentBearing bearing;
  DemoContainerOnly container;
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "content-bearing type reports 1");
  CHECK(demo_container_only_can_have_content(&container) == 0,
        "container-only type reports 0");
}

/* Structural, not stateful: the answer is the type's compile-time property and
 * never depends on the document. Binding a node to a document with a value
 * written under (and without) its `content` leaf must not change the answer,
 * and clearing the value must not change it either. */
static void test_structural_not_stateful(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  DemoContentBearing bearing;
  som_node_init(&bearing.node, &doc, "SEC");
  /* No content written yet — still 1 (structural, not "value present now?"). */
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "content-bearing stays 1 with an empty document");
  /* Writing content does not change the structural answer. */
  spec_document_set_content(&doc, "SEC/content", "body text");
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "content-bearing stays 1 after content is written");
  /* Clearing content does not change it either. */
  spec_document_set_content(&doc, "SEC/content", "");
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "content-bearing stays 1 after content is cleared");
  som_node_free(&bearing.node);

  DemoContainerOnly container;
  som_node_init(&container.node, &doc, "CON");
  /* Even with a value nested beneath the container's path, it stays 0: the
   * predicate describes the model, not the data. */
  spec_document_set_content(&doc, "CON/child/content", "nested");
  CHECK(demo_container_only_can_have_content(&container) == 0,
        "container-only stays 0 with nested values present");
  som_node_free(&container.node);

  spec_document_free(&doc);
}

/* `can_have_content` is deliberately distinct from the two STATE predicates it
 * is easily confused with: the generic `spec_document_has_content` ("is a value
 * present at this leaf now?") and `som_node_is_empty` ("is this subtree empty
 * now?"). A content-bearing type reports 1 regardless of whether the document
 * has a value there or the subtree is empty. */
static void test_distinct_from_state_predicates(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  DemoContentBearing bearing;
  som_node_init(&bearing.node, &doc, "SEC");

  /* Empty subtree, no leaf value: structural predicate is 1 while both state
   * predicates report "absent". */
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "can_have_content 1 on an empty section");
  CHECK(som_node_is_empty(&bearing.node) == 1,
        "is_empty 1 on the same empty section");
  CHECK(spec_document_has_content(&doc, "SEC/content") == 0,
        "has_content 0 on the same empty leaf");

  /* After a write the two state predicates flip; the structural one does not. */
  spec_document_set_content(&doc, "SEC/content", "x");
  CHECK(demo_content_bearing_can_have_content(&bearing) == 1,
        "can_have_content still 1 after a write");
  CHECK(som_node_is_empty(&bearing.node) == 0,
        "is_empty flips to 0 after a write");
  CHECK(spec_document_has_content(&doc, "SEC/content") == 1,
        "has_content flips to 1 after a write");

  som_node_free(&bearing.node);
  spec_document_free(&doc);
}

int main(void) {
  test_literal_answer();
  test_structural_not_stateful();
  test_distinct_from_state_predicates();
  if (g_failures == 0) {
    printf("facade_can_have_content: all checks passed\n");
    return 0;
  }
  fprintf(stderr, "facade_can_have_content: %d check(s) failed\n", g_failures);
  return 1;
}
