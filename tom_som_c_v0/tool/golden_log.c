/* Cross-language golden-log generator for C (roadmap item 7b).
 *
 * Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
 * canonical format. Loads the shared sample and emits a byte-identical reading
 * of essentially every section through both the generic string-path API and the
 * typed facade, asserting typed == generic before writing.
 *
 * Build & run (from the project root):
 *   cc -std=c11 -Iinclude -I../tom_som_c_runtime/include tool/golden_log.c \
 *      build/libtom_som_c_v0.a ../tom_som_c_runtime/build/libtom_som_c_runtime.a \
 *      -o build/golden_log
 *   ./build/golden_log [samplePath] [outputPath]
 */
#include "tom_som_c_v0.h"

#include "docspecs_validator.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char *esc(const char *s) {
  size_t n = strlen(s);
  char *out = malloc(2 * n + 1);
  char *w = out;
  for (size_t i = 0; i < n; i++) {
    char c = s[i];
    switch (c) {
      case '\\': *w++ = '\\'; *w++ = '\\'; break;
      case '\n': *w++ = '\\'; *w++ = 'n'; break;
      case '\r': *w++ = '\\'; *w++ = 'r'; break;
      case '\t': *w++ = '\\'; *w++ = 't'; break;
      default:   *w++ = c; break;
    }
  }
  *w = '\0';
  return out;
}

static char *fmt(const char *f, ...) {
  va_list a;
  va_start(a, f);
  int n = vsnprintf(NULL, 0, f, a);
  va_end(a);
  char *buf = malloc((size_t)n + 1);
  va_start(a, f);
  vsnprintf(buf, (size_t)n + 1, f, a);
  va_end(a);
  return buf;
}

static void die(const char *msg) {
  fprintf(stderr, "%s\n", msg);
  exit(2);
}

/* Reads a whole file into an owned NUL-terminated buffer, or aborts. */
static char *read_text_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) die(fmt("read %s: cannot open", path));
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  if (n < 0) {
    fclose(f);
    die(fmt("read %s: ftell failed", path));
  }
  fseek(f, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  fclose(f);
  buf[got] = '\0';
  return buf;
}

/* Asserts the typed content equals the generic read at <node_path>/content,
 * appends the `T` line, and frees the (owned) typed value. */
static void typed_content(SpecDocument *doc, SomStrList *out,
                          const char *node_path, char *value) {
  char *leaf = fmt("%s/content", node_path);
  const char *generic = spec_document_content(doc, leaf);
  if (generic == NULL) generic = "";
  if (strcmp(value, generic) != 0) {
    die(fmt("TYPED MISMATCH at %s", leaf));
  }
  char *e = esc(value);
  som_strlist_push(out, fmt("T\t%s\t%s", leaf, e));
  free(e);
  free(leaf);
  free(value);
}

/* Maps a runtime kind literal (SOM_META_KIND_*) to the canonical DART enum
 * spelling used in the cross-language golden log. The runtime spells the
 * enum-value kind "enum"; the Dart reference spells it "enumValue". Every other
 * kind already matches the Dart `SomMetaKind.name`. */
static const char *kind_dart(const char *kind) {
  if (strcmp(kind, SOM_META_KIND_LIST) == 0) return "list";
  if (strcmp(kind, SOM_META_KIND_FORM) == 0) return "form";
  if (strcmp(kind, SOM_META_KIND_SECTION) == 0) return "section";
  if (strcmp(kind, SOM_META_KIND_CONTENT) == 0) return "content";
  if (strcmp(kind, SOM_META_KIND_ENUM_VALUE) == 0) return "enumValue";
  if (strcmp(kind, SOM_META_KIND_COMPLEX) == 0) return "complex";
  if (strcmp(kind, SOM_META_KIND_SCALAR) == 0) return "scalar";
  die(fmt("UNKNOWN KIND %s", kind));
  return "";
}

/* Emits one `M` line for the node the tree resolves at `path`: kind (DART
 * spelling) plus sectionId / contentHelp / comment / docComment, each escaped
 * and blank when absent. C node string fields are owned char* that are never
 * NULL ("" == absent), matching the reference's empty trailing fields. Aborts
 * (exit 3) if the path resolves to no node, mirroring the Dart generator. */
static void meta_node(const SomMetaTree *tree, SomStrList *out,
                      const char *path) {
  const SomMetaNode *n = som_meta_tree_by_path(tree, path);
  if (n == NULL) {
    fprintf(stderr, "META MISSING at %s\n", path);
    exit(3);
  }
  char *sid = esc(n->section_id);
  char *help = esc(n->content_help);
  char *comment = esc(n->comment);
  char *doc = esc(n->doc_comment);
  som_strlist_push(out, fmt("M\t%s\t%s\t%s\t%s\t%s\t%s", path, kind_dart(n->kind),
                            sid, help, comment, doc));
  free(sid);
  free(help);
  free(comment);
  free(doc);
}

/* Emits one `N` line: asserts the nav ref resolves to `expected_path` and to
 * the *same* node instance the by-path lookup finds (pointer identity, the C
 * analogue of Dart `identical`). */
static void meta_nav(const SomMetaTree *tree, SomStrList *out,
                     const SomMetaRef *ref, const char *expected_path) {
  if (strcmp(ref->path, expected_path) != 0) {
    fprintf(stderr, "META NAV PATH at %s expected %s\n", ref->path,
            expected_path);
    exit(3);
  }
  char *err = NULL;
  const SomMetaNode *via_ref = som_meta_ref_meta(ref, &err);
  free(err);
  const SomMetaNode *via_path = som_meta_tree_by_path(tree, expected_path);
  if (via_path == NULL || via_ref != via_path) {
    fprintf(stderr, "META NAV NODE mismatch at %s\n", expected_path);
    exit(3);
  }
  som_strlist_push(out, fmt("N\t%s", expected_path));
}

/* Emits one `D` line: asserts the ID-tree ref and the dot-notation ref share
 * the same path and resolve to the same node instance. */
static void meta_id(SomStrList *out, const SomMetaRef *id_ref,
                    const SomMetaRef *nav_ref) {
  char *e1 = NULL;
  char *e2 = NULL;
  const SomMetaNode *idn = som_meta_ref_meta(id_ref, &e1);
  const SomMetaNode *navn = som_meta_ref_meta(nav_ref, &e2);
  free(e1);
  free(e2);
  if (strcmp(id_ref->path, nav_ref->path) != 0 || idn != navn) {
    fprintf(stderr, "META ID mismatch at %s vs %s\n", id_ref->path,
            nav_ref->path);
    exit(3);
  }
  som_strlist_push(out, fmt("D\t%s", id_ref->path));
}

int main(int argc, char **argv) {
  const char *sample = argc > 1
      ? argv[1]
      : "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
  const char *output = argc > 2 ? argv[2] : "../tom_som_conformance/golden/c.log";

  char *load_generic_err = NULL;
  SpecDocument *doc = spec_document_from_file(
      sample, d00_solution_blueprint_meta_tree(), &load_generic_err);
  if (doc == NULL)
    die(load_generic_err != NULL ? load_generic_err : "load sample failed");

  D00SolutionBlueprint sbp;
  SpecDocument *typed_doc = NULL;
  char *load_err = NULL;
  if (d00_solution_blueprint_load_file(&sbp, sample, &typed_doc, &load_err) != 0) {
    die(load_err != NULL ? load_err : "load typed root failed");
  }

  SomStrList out;
  som_strlist_init(&out);
  som_strlist_push_copy(&out,
      "# TomSpecs SOM golden log — canonical cross-language reading.");
  som_strlist_push_copy(&out,
      "# All nine per-language generators must emit byte-identical output.");
  som_strlist_push_copy(&out, "FORMAT\t2");
  {
    const char *mv = doc->model_version != NULL ? doc->model_version : "";
    char *e = esc(mv);
    som_strlist_push(&out, fmt("MODELVERSION\t%s", e));
    free(e);
  }

  /* Generic: content leaves (enumerations are byte-sorted by the runtime). */
  som_strlist_push_copy(&out, "SECTION\tgeneric-content");
  {
    SomStrList paths;
    som_strlist_init(&paths);
    spec_document_content_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      const char *v = spec_document_content(doc, p);
      char *e = esc(v != NULL ? v : "");
      som_strlist_push(&out, fmt("C\t%s\t%s", p, e));
      free(e);
    }
    som_strlist_free(&paths);
  }

  /* Generic: form sections + fields, sorted by path then field. */
  som_strlist_push_copy(&out, "SECTION\tgeneric-forms");
  {
    SomStrList paths;
    som_strlist_init(&paths);
    spec_document_form_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      SomStrList fields;
      som_strlist_init(&fields);
      spec_document_form_field_names(doc, p, &fields);
      for (size_t j = 0; j < fields.len; j++) {
        const char *f = fields.items[j];
        const char *v = spec_document_form_field(doc, p, f);
        char *e = esc(v != NULL ? v : "");
        som_strlist_push(&out, fmt("F\t%s\t%s\t%s", p, f, e));
        free(e);
      }
      som_strlist_free(&fields);
    }
    som_strlist_free(&paths);
  }

  /* Generic: list containers + item paths (document order). */
  som_strlist_push_copy(&out, "SECTION\tgeneric-lists");
  {
    SomStrList paths;
    som_strlist_init(&paths);
    spec_document_list_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      const SomStrList *items = spec_document_list_items(doc, p);
      size_t count = items != NULL ? items->len : 0;
      som_strlist_push(&out, fmt("L\t%s\t%zu", p, count));
      for (size_t j = 0; j < count; j++) {
        som_strlist_push(&out, fmt("I\t%s", items->items[j]));
      }
    }
    som_strlist_free(&paths);
  }

  /* Typed: curated traversal that must agree with the generic reads. */
  som_strlist_push_copy(&out, "SECTION\ttyped");

  typed_content(doc, &out, som_node_path(&sbp.node),
                d00_solution_blueprint_content(&sbp));

  DocumentControl s_dc = d00_solution_blueprint_document_control(&sbp);
  typed_content(doc, &out, som_node_path(&s_dc.node), document_control_content(&s_dc));

  IntroductionAndScope s_intro = d00_solution_blueprint_introduction_and_scope(&sbp);
  typed_content(doc, &out, som_node_path(&s_intro.node),
                introduction_and_scope_content(&s_intro));

  GlossaryAndAbbreviations s_glo = d00_solution_blueprint_glossary_and_abbreviations(&sbp);
  typed_content(doc, &out, som_node_path(&s_glo.node),
                glossary_and_abbreviations_content(&s_glo));

  StakeholdersAndGovernance s_stk = d00_solution_blueprint_stakeholders_and_governance(&sbp);
  typed_content(doc, &out, som_node_path(&s_stk.node),
                stakeholders_and_governance_content(&s_stk));

  CurrentLandscape s_cl = d00_solution_blueprint_current_landscape(&sbp);
  typed_content(doc, &out, som_node_path(&s_cl.node), current_landscape_content(&s_cl));

  AssumptionsConstraintsDependencies s_acd =
      d00_solution_blueprint_assumptions_constraints_dependencies(&sbp);
  typed_content(doc, &out, som_node_path(&s_acd.node),
                assumptions_constraints_dependencies_content(&s_acd));

  TargetOperatingModel s_tom = d00_solution_blueprint_target_operating_model_concept(&sbp);
  typed_content(doc, &out, som_node_path(&s_tom.node),
                target_operating_model_content(&s_tom));

  InformationAndDataModel s_ifm = d00_solution_blueprint_information_and_data_model(&sbp);
  typed_content(doc, &out, som_node_path(&s_ifm.node),
                information_and_data_model_content(&s_ifm));

  Requirements s_req = d00_solution_blueprint_requirements(&sbp);
  typed_content(doc, &out, som_node_path(&s_req.node), requirements_content(&s_req));

  SolutionArchitectureAndTechnology s_sat =
      d00_solution_blueprint_solution_architecture_and_technology(&sbp);
  typed_content(doc, &out, som_node_path(&s_sat.node),
                solution_architecture_and_technology_content(&s_sat));

  SecurityAndAccessModel s_sam = d00_solution_blueprint_security_and_access_model(&sbp);
  typed_content(doc, &out, som_node_path(&s_sam.node),
                security_and_access_model_content(&s_sam));

  ExperienceAndInterfaceDesign s_xds = d00_solution_blueprint_experience_and_interface_design(&sbp);
  typed_content(doc, &out, som_node_path(&s_xds.node),
                experience_and_interface_design_content(&s_xds));

  QualityAndAcceptanceModel s_qam = d00_solution_blueprint_quality_and_acceptance_model(&sbp);
  typed_content(doc, &out, som_node_path(&s_qam.node),
                quality_and_acceptance_model_content(&s_qam));

  DeliveryTransitionAndRollout s_dtr = d00_solution_blueprint_delivery_transition_and_rollout(&sbp);
  typed_content(doc, &out, som_node_path(&s_dtr.node),
                delivery_transition_and_rollout_content(&s_dtr));

  IntroductionAndScope s_intro2 = d00_solution_blueprint_introduction_and_scope(&sbp);
  Goals s_goals = introduction_and_scope_goals(&s_intro2);
  typed_content(doc, &out, som_node_path(&s_goals.node), goals_content(&s_goals));

  CurrentLandscape s_cl2 = d00_solution_blueprint_current_landscape(&sbp);
  SomList metrics = current_landscape_operational_metrics(&s_cl2);
  const SomStrList *metric_items = spec_document_list_items(doc, metrics.list_path);
  size_t metric_count = metric_items != NULL ? metric_items->len : 0;
  if (som_list_length(&metrics) != metric_count) {
    die(fmt("TYPED LIST LENGTH MISMATCH at %s", metrics.list_path));
  }
  som_strlist_push(&out, fmt("TL\t%s\t%zu", metrics.list_path, som_list_length(&metrics)));
  for (size_t i = 0; i < som_list_length(&metrics); i++) {
    const char *ip = som_list_item_path_at(&metrics, i);
    CurrentOperationalMetric elem;
    current_operational_metric_init(&elem, typed_doc, ip);
    char *leaf = fmt("%s/content", som_node_path(&elem.node));
    const char *generic = spec_document_content(doc, leaf);
    if (generic == NULL) generic = "";
    char *value = current_operational_metric_content(&elem);
    if (strcmp(value, generic) != 0) {
      die(fmt("TYPED LIST ITEM MISMATCH at %s", leaf));
    }
    char *e = esc(value);
    som_strlist_push(&out, fmt("TI\t%s\t%s", leaf, e));
    free(e);
    free(value);
    free(leaf);
    current_operational_metric_free(&elem);
  }

  /* --- Meta (FORMAT 2): the generated metadata tree read three ways. The SBP
   * root's static tree is the one the sample is decoded against. Every emitted
   * path/field is model-derived, so the lines are byte-identical across all
   * nine languages even though accessor names and node types differ. --- */
  const SomMetaTree *meta_tree = d00_solution_blueprint_meta_tree();

  som_strlist_push_copy(&out, "SECTION\tmeta");
  meta_node(meta_tree, &out, "SBP");
  meta_node(meta_tree, &out, "SBP/documentControl");
  meta_node(meta_tree, &out, "SBP/documentControl/revisionHistory");
  meta_node(meta_tree, &out, "SBP/documentControl/revisionHistory/RVHST-REVS-LST");
  meta_node(meta_tree, &out, "SBP/introductionAndScope");
  meta_node(meta_tree, &out, "SBP/introductionAndScope/goals");
  meta_node(meta_tree, &out, "SBP/introductionAndScope/goals/content");
  meta_node(meta_tree, &out, "SBP/currentLandscape");
  meta_node(meta_tree, &out, "SBP/currentLandscape/CUOPME-OPER-LST");
  meta_node(meta_tree, &out, "SBP/requirements");
  meta_node(meta_tree, &out, "SBP/requirements/content");

  /* Dot-notation navigation: the typed nav accessors must resolve to exactly
   * the path byPath finds, and to the *same* node instance. */
  som_strlist_push_copy(&out, "SECTION\tmeta-nav");
  {
    som_nav_d00_solution_blueprint nroot = d00_solution_blueprint_meta(meta_tree);
    som_nav_document_control n_dc = d00_solution_blueprint_nav_document_control(nroot);
    som_nav_introduction_and_scope n_intro =
        d00_solution_blueprint_nav_introduction_and_scope(nroot);
    som_nav_goals n_goals = introduction_and_scope_nav_goals(n_intro);
    SomMetaRef n_goals_content = goals_nav_content(n_goals);
    som_nav_current_landscape n_cl = d00_solution_blueprint_nav_current_landscape(nroot);
    som_nav_requirements n_req = d00_solution_blueprint_nav_requirements(nroot);
    SomMetaRef n_req_content = requirements_nav_content(n_req);

    meta_nav(meta_tree, &out, &nroot.ref, "SBP");
    meta_nav(meta_tree, &out, &n_dc.ref, "SBP/documentControl");
    meta_nav(meta_tree, &out, &n_intro.ref, "SBP/introductionAndScope");
    meta_nav(meta_tree, &out, &n_goals.ref, "SBP/introductionAndScope/goals");
    meta_nav(meta_tree, &out, &n_goals_content,
             "SBP/introductionAndScope/goals/content");
    meta_nav(meta_tree, &out, &n_cl.ref, "SBP/currentLandscape");
    meta_nav(meta_tree, &out, &n_req.ref, "SBP/requirements");
    meta_nav(meta_tree, &out, &n_req_content, "SBP/requirements/content");

    som_meta_ref_free(&n_req_content);
    som_meta_ref_free(&n_req.ref);
    som_meta_ref_free(&n_cl.ref);
    som_meta_ref_free(&n_goals_content);
    som_meta_ref_free(&n_goals.ref);
    som_meta_ref_free(&n_intro.ref);
    som_meta_ref_free(&n_dc.ref);
    som_meta_ref_free(&nroot.ref);
  }

  /* ID-tree navigation: the hoisted-id accessors must agree — same path, same
   * node instance — with the dot-notation position, including list elements. */
  som_strlist_push_copy(&out, "SECTION\tmeta-id");
  {
    som_id_d00_solution_blueprint id_sbp = SBP(meta_tree);
    som_nav_d00_solution_blueprint nroot = d00_solution_blueprint_meta(meta_tree);
    meta_id(&out, &id_sbp.ref, &nroot.ref);

    SomListMetaRef id_revs = d00_solution_blueprint_id_rvhst_revs_lst(id_sbp);
    som_nav_document_control n_dc = d00_solution_blueprint_nav_document_control(nroot);
    som_nav_revision_history n_rh = document_control_nav_revision_history(n_dc);
    SomListMetaRef nav_revs = revision_history_nav_revisions(n_rh);
    meta_id(&out, &id_revs.ref, &nav_revs.ref);

    void *id_item0 = som_list_meta_ref_item(&id_revs, 0);
    void *nav_item0 = som_list_meta_ref_item(&nav_revs, 0);
    meta_id(&out, (SomMetaRef *)id_item0, (SomMetaRef *)nav_item0);
    som_meta_ref_free((SomMetaRef *)id_item0);
    free(id_item0);
    som_meta_ref_free((SomMetaRef *)nav_item0);
    free(nav_item0);

    som_meta_ref_free(&nav_revs.ref);
    som_meta_ref_free(&n_rh.ref);
    som_meta_ref_free(&n_dc.ref);
    som_meta_ref_free(&id_revs.ref);
    som_meta_ref_free(&nroot.ref);
    som_meta_ref_free(&id_sbp.ref);
  }

  /* DocSpecs validation: the shared markdown rendering of the sample validates
   * cleanly against the facade's generated Solution-Blueprint schema. */
  som_strlist_push_copy(&out, "SECTION\tdocspecs");
  {
    char *schema_text =
        read_text_file("schemas/solution-blueprint/"
                       "solution-blueprint.1.0.docspecs-schema.yaml");
    char *sample_md =
        read_text_file("../tom_som_conformance/samples/meridian_order_management.md");
    DocSpecsSchema *schema = NULL;
    char *ds_err = NULL;
    if (!docspecs_schema_from_yaml_text(schema_text, &schema, &ds_err)) {
      die(ds_err != NULL ? ds_err : "schema load failed");
    }
    DocSpecsValidator val = docspecs_validator_new(schema);
    DocSpecsViolationList violations;
    docspecs_violation_list_init(&violations);
    docspecs_validator_validate_markdown(&val, sample_md, &violations);

    char *root = docspecs_schema_root_section_id(schema);
    char *root_e = esc(root != NULL ? root : "");
    som_strlist_push(&out, fmt("DS\troot\t%s", root_e));
    free(root_e);
    free(root);
    som_strlist_push(&out, fmt("DS\twarnings\t%zu", schema->warnings.len));
    som_strlist_push(&out, fmt("DS\tviolations\t%zu", violations.len));
    for (size_t i = 0; i < violations.len; i++) {
      const DocSpecsViolation *v = &violations.items[i];
      char *sid = esc(v->section_id);
      som_strlist_push(&out, fmt("DV\t%s\t%s\t%d", v->rule, sid, v->line));
      free(sid);
    }

    docspecs_violation_list_free(&violations);
    docspecs_schema_free(schema);
    free(sample_md);
    free(schema_text);
  }

  char *body = som_strlist_join(&out, "\n");
  size_t blen = strlen(body);
  char *withnl = malloc(blen + 2);
  memcpy(withnl, body, blen);
  withnl[blen] = '\n';
  withnl[blen + 1] = '\0';

  FILE *fp = fopen(output, "wb");
  if (fp == NULL) die("write failed");
  fwrite(withnl, 1, blen + 1, fp);
  fclose(fp);
  printf("wrote %zu lines to %s\n", out.len, output);

  free(withnl);
  free(body);
  som_strlist_free(&out);
  som_list_free(&metrics);
  return 0;
}
