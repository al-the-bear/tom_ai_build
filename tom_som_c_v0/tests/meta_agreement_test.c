/* Agreement suite for the generated C metadata module
 * (`tom_som_c_v0_meta.c`, SOM §7.2/§8) — the C port of the Go facade's
 * `som_v0_meta_test.go` (and the Dart `generated_meta_test.dart`). Two
 * guarantees over the *real* committed model:
 *
 *  1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
 *     generated static SomMetaTree is field-for-field identical (via
 *     `som_meta_node_diff`) to the tree `som_build_meta_tree` derives from the
 *     committed `meta/spec_model.meta.json` at runtime. Because the emitter
 *     writes the dot-notation / ID-tree accessor paths from the same node
 *     walk, this anchors every path the accessors can produce.
 *  2. SURFACE AGREEMENT — the dot-notation entry points (SOM §8), the ID-tree
 *     entry points (SOM §8), and the dynamic by-path lookups all resolve to the
 *     *same* SomMetaNode instances for representative positions (root, nested
 *     section, content leaf, list, list element, hoisted id).
 *
 * Build & run via `./run_tests.sh`. Exit 0 == all green; prints "OK: N checks".
 *
 * C has no test framework here, so this is a hand-rolled checker mirroring the
 * runtime's conformance harness: every bridge tree is freed before the model,
 * and every owned buffer the accessors return is released.
 */
#include "tom_som_c_v0.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int g_passed = 0;
static int g_failed = 0;

static void ok(int cond, const char *name) {
  if (cond) {
    g_passed++;
  } else {
    g_failed++;
    fprintf(stderr, "FAIL: %s\n", name);
  }
}

static void eq_str(const char *got, const char *want, const char *name) {
  if (got != NULL && strcmp(got, want) == 0) {
    g_passed++;
  } else {
    g_failed++;
    fprintf(stderr, "FAIL: %s — got \"%s\" want \"%s\"\n", name,
            got != NULL ? got : "(null)", want);
  }
}

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

/* Resolves a ref's node, freeing any (unexpected) error message. */
static const SomMetaNode *meta_of(const SomMetaRef *ref) {
  char *err = NULL;
  const SomMetaNode *node = som_meta_ref_meta(ref, &err);
  free(err);
  return node;
}

/* One row of the document-root registry: the model root type, the generated
 * static tree, and the ID-tree entry point resolved to its root ref. */
typedef struct {
  const char *type;
  const SomMetaTree *tree;
  SomMetaRef id_ref; /* the section-id root accessor's ref */
} RootRow;

/* The number of document roots `build_rows` fills in. Named so the caller's
 * stack array cannot silently be one short of the registry when a root is
 * added (C has no bounds check to catch it). */
#define ROOT_ROW_COUNT 14

/* Builds the registry of all document roots. The ID entry points return
 * distinct struct types, so each is called explicitly and its `.ref` captured. */
static size_t build_rows(RootRow *rows) {
  size_t i = 0;
  rows[i++] = (RootRow){"D00SolutionBlueprint",
                        d00_solution_blueprint_meta_tree(),
                        SBP(d00_solution_blueprint_meta_tree()).ref};
  rows[i++] = (RootRow){"D01CurrentLandscapeAssessment",
                        d01_current_landscape_assessment_meta_tree(),
                        CLA(d01_current_landscape_assessment_meta_tree()).ref};
  rows[i++] = (RootRow){"D02TargetOperatingModel",
                        d02_target_operating_model_meta_tree(),
                        TOM(d02_target_operating_model_meta_tree()).ref};
  rows[i++] = (RootRow){"D03InformationModel",
                        d03_information_model_meta_tree(),
                        IFM(d03_information_model_meta_tree()).ref};
  rows[i++] = (RootRow){"D04RequirementsSpecification",
                        d04_requirements_specification_meta_tree(),
                        RSP(d04_requirements_specification_meta_tree()).ref};
  rows[i++] = (RootRow){"D05InteractionScenarios",
                        d05_interaction_scenarios_meta_tree(),
                        ISC(d05_interaction_scenarios_meta_tree()).ref};
  rows[i++] = (RootRow){"D06ArchitectureTechnologySpecification",
                        d06_architecture_technology_specification_meta_tree(),
                        ATS(d06_architecture_technology_specification_meta_tree())
                            .ref};
  rows[i++] = (RootRow){"D07IntegrationInterfaceSpecification",
                        d07_integration_interface_specification_meta_tree(),
                        IIS(d07_integration_interface_specification_meta_tree())
                            .ref};
  rows[i++] = (RootRow){"D08SecurityAccessSpecification",
                        d08_security_access_specification_meta_tree(),
                        SAS(d08_security_access_specification_meta_tree()).ref};
  rows[i++] = (RootRow){"D09ExperienceDesignSpecification",
                        d09_experience_design_specification_meta_tree(),
                        XDS(d09_experience_design_specification_meta_tree()).ref};
  rows[i++] = (RootRow){"D10QualityAcceptancePlan",
                        d10_quality_acceptance_plan_meta_tree(),
                        QAP(d10_quality_acceptance_plan_meta_tree()).ref};
  rows[i++] = (RootRow){"D11DeliveryRoadmap",
                        d11_delivery_roadmap_meta_tree(),
                        DRM(d11_delivery_roadmap_meta_tree()).ref};
  rows[i++] = (RootRow){"D12TransitionRolloutPlan",
                        d12_transition_rollout_plan_meta_tree(),
                        TRP(d12_transition_rollout_plan_meta_tree()).ref};
  rows[i++] = (RootRow){"D13CodeSpecsProjection",
                        d13_code_specs_projection_meta_tree(),
                        CGP(d13_code_specs_projection_meta_tree()).ref};
  return i;
}

/* GUARANTEE 1: every generated static tree is field-for-field identical to the
 * bridge-built tree, and the generated trees cover exactly the model roots. */
static void test_trees_agree_with_bridge(void) {
  char *data = read_file("meta/spec_model.meta.json");
  ok(data != NULL, "read meta/spec_model.meta.json");
  if (data == NULL) return;

  char *err = NULL;
  SpecModel *model = spec_model_from_json_str(data, &err);
  free(data);
  ok(model != NULL, "parse spec model");
  if (model == NULL) {
    free(err);
    return;
  }

  RootRow rows[ROOT_ROW_COUNT];
  size_t n = build_rows(rows);
  ok(model->roots_len == n, "model root count matches generated tree count");

  for (size_t i = 0; i < n; i++) {
    err = NULL;
    SomMetaTree *bridge = som_build_meta_tree(model, rows[i].type, &err);
    if (bridge == NULL) {
      g_failed++;
      fprintf(stderr, "FAIL: som_build_meta_tree(%s): %s\n", rows[i].type,
              err != NULL ? err : "?");
      free(err);
      continue;
    }
    char *diff = som_meta_node_diff(rows[i].tree->root, bridge->root);
    if (diff != NULL && diff[0] != '\0') {
      g_failed++;
      fprintf(stderr, "FAIL: generated tree for %s disagrees with bridge:\n%s\n",
              rows[i].type, diff);
    } else {
      g_passed++;
    }
    free(diff);
    som_meta_tree_free(bridge);
  }

  /* Every model root has a generated tree (same set, by type). */
  for (size_t r = 0; r < model->roots_len; r++) {
    const char *type = model->roots[r].type;
    int found = 0;
    for (size_t i = 0; i < n; i++) {
      if (strcmp(rows[i].type, type) == 0) {
        found = 1;
        break;
      }
    }
    ok(found, "model root has a generated tree");
  }

  spec_model_free(model);
}

/* GUARANTEE 2a: the dot-notation entry points resolve representative positions
 * to the expected paths and to the same nodes the by-path lookups find. */
static void test_dot_notation_surface(void) {
  const SomMetaTree *tree = d00_solution_blueprint_meta_tree();
  som_nav_d00_solution_blueprint root = d00_solution_blueprint_meta(tree);
  eq_str(root.ref.path, "SBP", "dot root path");

  som_nav_introduction_and_scope intro =
      d00_solution_blueprint_nav_introduction_and_scope(root);
  eq_str(intro.ref.path, "SBP/introductionAndScope", "dot section path");

  som_nav_requirements req = d00_solution_blueprint_nav_requirements(root);
  SomMetaRef req_content = requirements_nav_content(req);
  eq_str(req_content.path, "SBP/requirements/content", "dot leaf path");

  som_nav_goals goals = introduction_and_scope_nav_goals(intro);
  SomMetaRef goals_content = goals_nav_content(goals);
  eq_str(goals_content.path, "SBP/introductionAndScope/goals/content",
         "dot nested-leaf path");

  /* Meta() resolves to the same node by-path finds. */
  const SomMetaNode *via_dot = meta_of(&intro.ref);
  const SomMetaNode *via_path =
      som_meta_tree_by_path(tree, "SBP/introductionAndScope");
  ok(via_dot == via_path, "dot Meta() == by-path node");
  ok(via_dot != NULL && strcmp(via_dot->member_name, "introductionAndScope") == 0,
     "dot node member name");

  /* List positions expose item accessors and the section-id pattern. */
  som_nav_document_control dc =
      d00_solution_blueprint_nav_document_control(root);
  SomListMetaRef revs = document_control_nav_revision_history(dc);
  eq_str(revs.ref.path, "SBP/documentControl/RVHST-REVS-LST",
         "dot list path");

  void *item3 = som_list_meta_ref_item(&revs, 3);
  SomMetaRef *item3_ref = (SomMetaRef *)item3; /* first member of any accessor */
  eq_str(item3_ref->path,
         "SBP/documentControl/RVHST-REVS-LST-3",
         "dot list-item path");
  som_meta_ref_free(item3_ref);
  free(item3);

  const SomMetaNode *revs_node = meta_of(&revs.ref);
  ok(revs_node != NULL && revs_node->section_id_pattern[0] != '\0',
     "list node carries a section-id pattern");

  som_meta_ref_free(&revs.ref);
  som_meta_ref_free(&dc.ref);
  som_meta_ref_free(&goals_content);
  som_meta_ref_free(&goals.ref);
  som_meta_ref_free(&req_content);
  som_meta_ref_free(&req.ref);
  som_meta_ref_free(&intro.ref);
  som_meta_ref_free(&root.ref);

  /* A second root has its own entry point and segment, resolving to its own
   * tree root. */
  const SomMetaTree *tree1 = d01_current_landscape_assessment_meta_tree();
  som_nav_d01_current_landscape_assessment root1 =
      d01_current_landscape_assessment_meta(tree1);
  ok(strcmp(root1.ref.path, "SBP") != 0, "second root does not share SBP");
  ok(meta_of(&root1.ref) == tree1->root, "second-root Meta() == its tree root");
  som_meta_ref_free(&root1.ref);
}

/* GUARANTEE 2b: the ID-tree entry points agree with the dot-notation positions
 * and each root's ID entry sits over its own tree root node. */
static void test_id_tree_surface(void) {
  const SomMetaTree *tree = d00_solution_blueprint_meta_tree();

  som_id_d00_solution_blueprint sbp = SBP(tree);
  som_nav_d00_solution_blueprint dot = d00_solution_blueprint_meta(tree);
  eq_str(sbp.ref.path, dot.ref.path, "ID root path == dot root path");
  ok(meta_of(&sbp.ref) == meta_of(&dot.ref), "ID root Meta() == dot root Meta()");

  /* The hoisted list id agrees with the dot-notation position. */
  som_nav_document_control dc = d00_solution_blueprint_nav_document_control(dot);
  SomListMetaRef dot_revs = document_control_nav_revision_history(dc);
  SomListMetaRef id_revs = d00_solution_blueprint_id_rvhst_revs_lst(sbp);
  eq_str(id_revs.ref.path, dot_revs.ref.path, "hoisted id path == dot list path");
  ok(meta_of(&id_revs.ref) == meta_of(&dot_revs.ref),
     "hoisted id Meta() == dot list Meta()");

  void *id_item0 = som_list_meta_ref_item(&id_revs, 0);
  void *dot_item0 = som_list_meta_ref_item(&dot_revs, 0);
  eq_str(((SomMetaRef *)id_item0)->path, ((SomMetaRef *)dot_item0)->path,
         "hoisted item0 path == dot item0 path");
  som_meta_ref_free((SomMetaRef *)id_item0);
  free(id_item0);
  som_meta_ref_free((SomMetaRef *)dot_item0);
  free(dot_item0);

  som_meta_ref_free(&id_revs.ref);
  som_meta_ref_free(&dot_revs.ref);
  som_meta_ref_free(&dc.ref);
  som_meta_ref_free(&sbp.ref);
  som_meta_ref_free(&dot.ref);

  /* Every root has a distinct ID entry point resolving to its own tree root. */
  RootRow rows[ROOT_ROW_COUNT];
  size_t n = build_rows(rows);
  for (size_t i = 0; i < n; i++) {
    ok(meta_of(&rows[i].id_ref) == rows[i].tree->root,
       "ID root Meta() == its tree root");
    som_meta_ref_free(&rows[i].id_ref);
  }
}

int main(void) {
  test_trees_agree_with_bridge();
  test_dot_notation_surface();
  test_id_tree_surface();

  if (g_failed != 0) {
    fprintf(stderr, "\n%d checks FAILED (%d passed)\n", g_failed, g_passed);
    return 1;
  }
  printf("OK: %d checks passed\n", g_passed);
  return 0;
}
