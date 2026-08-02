/* Cross-language golden-log generator for C (SOM §19).
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

/* Asserts a node's typed codeSpec read equals the generic
 * `spec_document_code_spec` read at the same path (codespecs_mapping.md §9.2). Emits nothing — the
 * assertion is the point; the values themselves are already in the `CS` lines. */
static void typed_code_spec(SpecDocument *doc, const SomNode *node) {
  char *typed = som_node_code_spec(node);
  const char *generic = spec_document_code_spec(doc, som_node_path(node));
  if (generic == NULL) generic = "";
  if (strcmp(typed, generic) != 0) {
    die(fmt("CODESPEC MISMATCH at %s: typed=\"%s\" generic=\"%s\"",
            som_node_path(node), typed, generic));
  }
  free(typed);
}

/* Boundary canonicalisation for typed non-String form fields (FORMAT 7): an
 * int renders as its decimal string, a bool as "true"/"false". Returns an owned
 * buffer the caller frees. The sample values are always present, matching the
 * Dart reference which emits the raw stored string for these fields. */
static char *som_format_int(long v) { return fmt("%ld", v); }
static char *som_format_bool(int v) { return fmt("%s", v ? "true" : "false"); }

/* Asserts the canonical typed value equals the generic form-store read at
 * <form_path>.<field>, appends the `TF` line, and frees `canonical` (owned). */
static void typed_form(SpecDocument *doc, SomStrList *out, const char *form_path,
                       const char *field, char *canonical) {
  const char *generic = spec_document_form_field(doc, form_path, field);
  if (generic == NULL) generic = "";
  if (strcmp(canonical, generic) != 0) {
    die(fmt("TYPED FORM MISMATCH at %s.%s: typed=\"%s\" generic=\"%s\"",
            form_path, field, canonical, generic));
  }
  char *e = esc(generic);
  som_strlist_push(out, fmt("TF\t%s\t%s\t%s", form_path, field, e));
  free(e);
  free(canonical);
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
  char *headline = esc(n->headline);
  som_strlist_push(out,
                   fmt("M\t%s\t%s\t%s\t%s\t%s\t%s\t%s", path,
                       kind_dart(n->kind), sid, help, comment, doc, headline));
  free(sid);
  free(help);
  free(comment);
  free(doc);
  free(headline);
}

/* Joins `len` strings with commas into one freshly allocated string ("" when
 * empty). Both list-valued MF columns — enumValues and refersTo — are written
 * this way, so the join lives here once. Caller frees. */
static char *join_csv(char *const *items, size_t len) {
  size_t joined_len = 0;
  for (size_t j = 0; j < len; j++) {
    joined_len += strlen(items[j]) + 1;
  }
  char *joined = malloc(joined_len + 1);
  joined[0] = '\0';
  for (size_t j = 0; j < len; j++) {
    if (j > 0) strcat(joined, ",");
    strcat(joined, items[j]);
  }
  return joined;
}

/* Emits the meta-form lines for any list path whose element content is a form:
 * one `MF` line per field (declaration order) with type/required, the
 * enumValues column (FORMAT 7, YRD7 — comma-joined constant names, empty for
 * non-enum fields) and the refersTo column (FORMAT 9, csrb3 — comma-joined
 * registry keys, empty for non-reference fields). All values are
 * model-derived, so the lines match across every language. */
static void emit_meta_form(const SomMetaTree *tree, SomStrList *out,
                           const char *list_path) {
  const SomMetaNode *list_node = som_meta_tree_by_path(tree, list_path);
  const SomMetaNode *element = list_node != NULL ? list_node->element_node : NULL;
  const SomMetaNode *content_node = NULL;
  if (element != NULL) {
    for (size_t i = 0; i < element->children_len; i++) {
      if (strcmp(element->children[i]->member_name, "content") == 0) {
        content_node = element->children[i];
      }
    }
  }
  const SomFormMeta *form = content_node != NULL ? content_node->form : NULL;
  if (form == NULL) {
    fprintf(stderr, "META FORM MISSING at %s element content\n", list_path);
    exit(3);
  }
  /* Element subtrees have no static document path; use an ASCII marker segment
   * so the log path stays ASCII (mirrored verbatim per language). */
  char *form_path = fmt("%s/#element/content", list_path);
  for (size_t i = 0; i < form->fields_len; i++) {
    const SomFormFieldMeta *f = &form->fields[i];
    char *en = esc(f->name);
    char *et = esc(f->type_name);
    /* Both list columns: comma-join, then escape as one field. */
    char *enum_joined = join_csv(f->enum_values, f->enum_values_len);
    char *refs_joined = join_csv(f->refers_to, f->refers_to_len);
    char *ev = esc(enum_joined);
    char *rt = esc(refs_joined);
    som_strlist_push(out, fmt("MF\t%s\t%s\t%s\t%d\t%s\t%s", form_path, en, et,
                              f->required ? 1 : 0, ev, rt));
    free(rt);
    free(ev);
    free(refs_joined);
    free(enum_joined);
    free(et);
    free(en);
  }
  free(form_path);
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
  som_strlist_push_copy(&out, "FORMAT\t9");
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

  /* Generic: list containers + item paths (document order). FORMAT 3: each
     item with a *stored* section id additionally emits an `ID` line (item
     path + stored id); items without one emit no `ID` line. */
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
        const char *id = spec_document_item_section_id(doc, items->items[j]);
        if (id != NULL) {
          char *e = esc(id);
          som_strlist_push(&out, fmt("ID\t%s\t%s", items->items[j], e));
          free(e);
        }
      }
    }
    som_strlist_free(&paths);
  }

  /* Generic: every stored headline, sorted by path (FORMAT 3, YRD3). */
  som_strlist_push_copy(&out, "SECTION\tgeneric-headlines");
  {
    SomStrList paths;
    som_strlist_init(&paths);
    spec_document_headline_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      const char *v = spec_document_headline(doc, p);
      char *e = esc(v != NULL ? v : "");
      som_strlist_push(&out, fmt("H\t%s\t%s", p, e));
      free(e);
    }
    som_strlist_free(&paths);
  }

  /* Generic: stored codeSpecs, sorted by path (FORMAT 8, codespecs_mapping.md §9.2 mirror of headline). */
  som_strlist_push_copy(&out, "SECTION\tgeneric-codespecs");
  {
    SomStrList paths;
    som_strlist_init(&paths);
    spec_document_code_spec_paths(doc, &paths);
    for (size_t i = 0; i < paths.len; i++) {
      const char *p = paths.items[i];
      const char *v = spec_document_code_spec(doc, p);
      char *e = esc(v != NULL ? v : "");
      som_strlist_push(&out, fmt("CS\t%s\t%s", p, e));
      free(e);
    }
    som_strlist_free(&paths);
  }

  /* Typed cross-check of the same two mappings through the facade's structural
   * som_node_code_spec accessor (codespecs_mapping.md §9.2). Emits nothing: the values are already in
   * the CS lines above, so a duplicate line would add no information — what this
   * adds is the assertion that the typed accessor reads the same store the
   * generic API does. A divergence aborts the generator. */
  {
    IntroductionAndScope s_intro_cs = d00_solution_blueprint_introduction_and_scope(&sbp);
    RequirementsOverview s_reqs_cs = introduction_and_scope_requirements(&s_intro_cs);
    FunctionalRequirements s_frs = requirements_overview_functional_requirements(&s_reqs_cs);
    SomList fr_list = functional_requirements_requirements(&s_frs);
    FunctionalRequirementEntry fr_first;
    functional_requirement_entry_init(&fr_first, typed_doc,
                                      som_list_item_path_at(&fr_list, 0));
    typed_code_spec(doc, &s_frs.node);
    typed_code_spec(doc, &fr_first.node);
    functional_requirement_entry_free(&fr_first);
    som_list_free(&fr_list);
    functional_requirements_free(&s_frs);
    requirements_overview_free(&s_reqs_cs);
    introduction_and_scope_free(&s_intro_cs);
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

  /* --- Typed non-String form fields (FORMAT 7, YRD7): native int/bool/enum
   * members read through the typed facade and asserted against the generic form
   * store, canonicalised through the SAME boundary rules the facade setters used
   * to write them (int -> decimal, bool -> "true"/"false", enum -> constant
   * name). The emitted value is the raw stored string, so the lines are
   * byte-identical across languages regardless of native member types. --- */
  som_strlist_push_copy(&out, "SECTION\ttyped-form");
  {
    TargetOperatingModel s_tomc =
        d00_solution_blueprint_target_operating_model_concept(&sbp);
    ProcessStepsAndActorInteractions s_psai =
        target_operating_model_process_steps_and_actor_interactions(&s_tomc);
    ActorOverview s_ao = process_steps_and_actor_interactions_actor_overview(&s_psai);
    ActorOverviewOverviewForm ao_form = actor_overview_overview(&s_ao);
    const char *ao_path = som_node_path(&ao_form.node);
    typed_form(doc, &out, ao_path, "totalActorCount",
               som_format_int(actor_overview_overview_form_total_actor_count(&ao_form)));
    typed_form(doc, &out, ao_path, "humanActorCount",
               som_format_int(actor_overview_overview_form_human_actor_count(&ao_form)));
    typed_form(doc, &out, ao_path, "systemActorCount",
               som_format_int(actor_overview_overview_form_system_actor_count(&ao_form)));
    typed_form(doc, &out, ao_path, "externalActorCount",
               som_format_int(actor_overview_overview_form_external_actor_count(&ao_form)));
    actor_overview_overview_form_free(&ao_form);

    ExperienceAndInterfaceDesign s_xdsf =
        d00_solution_blueprint_experience_and_interface_design(&sbp);
    ExperienceDesignFollowUp s_xdfu =
        experience_and_interface_design_design_follow_up(&s_xdsf);
    Accessibility s_acc = experience_design_follow_up_accessibility(&s_xdfu);
    AccessibilityAccessibilityOverviewContentForm acc_form =
        accessibility_accessibility_overview_content(&s_acc);
    const char *acc_path = som_node_path(&acc_form.node);
    typed_form(doc, &out, acc_path, "accessibilityStatement",
               som_format_bool(accessibility_accessibility_overview_content_form_accessibility_statement(&acc_form)));
    accessibility_accessibility_overview_content_form_free(&acc_form);

    QualityAndAcceptanceModel s_qamf =
        d00_solution_blueprint_quality_and_acceptance_model(&sbp);
    Iso25010Coverage s_cov = quality_and_acceptance_model_iso25010_coverage(&s_qamf);
    SomList cov_list = iso25010_coverage_characteristics(&s_cov);
    som_strlist_push(&out, fmt("TL\t%s\t%zu", cov_list.list_path,
                               som_list_length(&cov_list)));
    for (size_t i = 0; i < som_list_length(&cov_list); i++) {
      const char *ip = som_list_item_path_at(&cov_list, i);
      Iso25010CoverageEntry entry;
      iso25010_coverage_entry_init(&entry, typed_doc, ip);
      Iso25010CoverageEntryContentForm cform =
          iso25010_coverage_entry_content(&entry);
      char *characteristic =
          iso25010_coverage_entry_content_form_characteristic(&cform);
      typed_form(doc, &out, som_node_path(&cform.node), "characteristic",
                 fmt("%s", characteristic));
      free(characteristic);
      iso25010_coverage_entry_content_form_free(&cform);
      iso25010_coverage_entry_free(&entry);
    }
    som_list_free(&cov_list);
  }

  /* --- Meta (FORMAT 2): the generated metadata tree read three ways. The SBP
   * root's static tree is the one the sample is decoded against. Every emitted
   * path/field is model-derived, so the lines are byte-identical across all
   * nine languages even though accessor names and node types differ. --- */
  const SomMetaTree *meta_tree = d00_solution_blueprint_meta_tree();

  som_strlist_push_copy(&out, "SECTION\tmeta");
  meta_node(meta_tree, &out, "SBP");
  meta_node(meta_tree, &out, "SBP/documentControl");
  meta_node(meta_tree, &out, "SBP/documentControl/RVHST-REVS-LST");
  meta_node(meta_tree, &out, "SBP/introductionAndScope");
  meta_node(meta_tree, &out, "SBP/introductionAndScope/goals");
  meta_node(meta_tree, &out, "SBP/introductionAndScope/goals/content");
  meta_node(meta_tree, &out, "SBP/currentLandscape");
  meta_node(meta_tree, &out, "SBP/currentLandscape/CUOPME-OPER-LST");
  meta_node(meta_tree, &out, "SBP/requirements");
  meta_node(meta_tree, &out, "SBP/requirements/content");

  /* --- Meta form fields (FORMAT 7, YRD7): list-element content forms read
   * through the metadata tree — one MF line per field (declaration order)
   * with type/required plus the enumValues column and, since FORMAT 9
   * (csrb3), the refersTo column. All values are model-derived. --- */
  som_strlist_push_copy(&out, "SECTION\tmeta-form");
  emit_meta_form(meta_tree, &out,
                 "SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST");
  emit_meta_form(meta_tree, &out,
                 "SBP/qualityAndAcceptanceModel/iso25010Coverage/I25CV-CHAR-LST");
  emit_meta_form(meta_tree, &out,
                 "SBP/experienceAndInterfaceDesign/experienceCodeSpecs/screenFlow/"
                 "screenRouteMap/SCTREN-TRAN-LST");

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
    SomListMetaRef nav_revs = document_control_nav_revision_history(n_dc);
    meta_id(&out, &id_revs.ref, &nav_revs.ref);

    void *id_item0 = som_list_meta_ref_item(&id_revs, 0);
    void *nav_item0 = som_list_meta_ref_item(&nav_revs, 0);
    meta_id(&out, (SomMetaRef *)id_item0, (SomMetaRef *)nav_item0);
    som_meta_ref_free((SomMetaRef *)id_item0);
    free(id_item0);
    som_meta_ref_free((SomMetaRef *)nav_item0);
    free(nav_item0);

    som_meta_ref_free(&nav_revs.ref);
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
