/* Meta-tree diff tests: som_meta_node_diff reports a form field that differs
 * only in one of its flags (`code`, `multiParagraph`), so the generated-tree
 * == bridge-tree agreement cannot pass over a lost flag.
 *
 * Two trees are built by the bridge from one inline model, then one flag of
 * one form field is changed in the second. Exit status is the number of
 * failed checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_meta.h"
#include "spec_meta_bridge.h"
#include "spec_meta_diff.h"
#include "spec_model.h"

static int g_checks = 0;
static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

static const char *kModel =
    "{\"roots\":[{\"type\":\"DiffDoc\",\"title\":\"Diff Doc\","
    "\"sectionId\":\"DIF\"}],"
    "\"classes\":{\"DiffDoc\":{\"name\":\"DiffDoc\",\"sectionId\":\"DIF\","
    "\"annotations\":[{\"name\":\"Document\"},"
    "{\"name\":\"SectionId\",\"arguments\":{\"id\":\"DIF\"}}],"
    "\"fields\":[{\"name\":\"control\",\"kind\":\"form\","
    "\"sectionId\":\"DIF-CTL\",\"formFields\":["
    "{\"name\":\"notes\",\"type\":\"String\",\"multiParagraph\":true},"
    "{\"name\":\"pattern\",\"type\":\"String\",\"code\":true}]}]}}}";

static SomMetaTree *build(SpecModel *model) {
  char *err = NULL;
  SomMetaTree *t = som_build_meta_tree(model, "DiffDoc", &err);
  if (t == NULL) {
    fprintf(stderr, "fatal: som_build_meta_tree: %s\n", err ? err : "?");
    exit(2);
  }
  return t;
}

static SomFormFieldMeta *field(SomMetaTree *t, const char *name) {
  SomMetaNode *n = som_meta_tree_by_id(t, "DIF-CTL");
  if (n == NULL || n->form == NULL) return NULL;
  return (SomFormFieldMeta *)som_form_meta_field_named(n->form, name);
}

int main(void) {
  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(kModel, &err);
  if (model == NULL) {
    fprintf(stderr, "fatal: model: %s\n", err ? err : "?");
    return 2;
  }

  SomMetaTree *a = build(model);
  SomMetaTree *b = build(model);
  SomFormFieldMeta *notes = field(b, "notes");
  SomFormFieldMeta *pattern = field(b, "pattern");
  check("MD0: the model reads multiParagraph into the form-field meta",
        notes != NULL && notes->multi_paragraph == 1 && notes->code == 0,
        NULL);
  check("MD0: the model reads code into the form-field meta",
        pattern != NULL && pattern->code == 1 && pattern->multi_paragraph == 0,
        NULL);

  char *same = som_meta_node_diff(a->root, b->root);
  check("MD1: two trees of one model agree", same[0] == '\0', same);
  free(same);

  if (notes != NULL) notes->multi_paragraph = 0;
  char *d1 = som_meta_node_diff(a->root, b->root);
  check("MD2: a form field differing only in multiParagraph is reported",
        strstr(d1, "form field notes differs") != NULL, d1);
  free(d1);
  if (notes != NULL) notes->multi_paragraph = 1;

  if (pattern != NULL) pattern->code = 0;
  char *d2 = som_meta_node_diff(a->root, b->root);
  check("MD3: a form field differing only in code is reported",
        strstr(d2, "form field pattern differs") != NULL, d2);
  free(d2);

  som_meta_tree_free(a);
  som_meta_tree_free(b);
  spec_model_free(model);

  if (g_failures == 0) {
    printf("spec_meta_diff_test: %d checks passed\n", g_checks);
  } else {
    fprintf(stderr, "spec_meta_diff_test: %d/%d checks FAILED\n", g_failures,
            g_checks);
  }
  return g_failures;
}
