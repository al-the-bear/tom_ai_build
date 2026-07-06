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

int main(int argc, char **argv) {
  const char *sample = argc > 1
      ? argv[1]
      : "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
  const char *output = argc > 2 ? argv[2] : "../tom_som_conformance/golden/c.log";

  SpecDocument *doc = spec_document_from_file(sample);
  if (doc == NULL) die("load sample failed");

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
  som_strlist_push_copy(&out, "FORMAT\t1");
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
