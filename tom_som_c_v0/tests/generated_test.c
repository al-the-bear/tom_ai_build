/* Behavioural test for the **actually-committed** generated C typed model.
 *
 * Unlike the emitter's golden test (which compiles the small emitter fixture),
 * this harness exercises the real, full `tom_som_c_v0` translation unit (3000+
 * typed facade structs) against the generic `tom_som_c_runtime` and proves the
 * typed facade is a faithful editing surface over the shared document (SOM §6):
 *
 *   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
 *   - a content leaf round-trips typed -> generic and generic -> typed;
 *   - a nested complex section derives its path under the root;
 *   - the path-based `SomList` collection maps onto the generic list store;
 *   - the generated model-version accessor / macro return "1.0";
 *   - the instantiation-time version check (SOM §4.2) accepts an editable stamp and
 *     rejects a newer-minor / cross-major stamp with a non-zero return + message.
 *
 * Build & run via `./run_tests.sh` (compiles against the relative runtime
 * checkout). Exit 0 == all green; it prints "OK: N checks passed".
 *
 * C has no test framework here, so this is a hand-rolled checker mirroring the
 * runtime's conformance harness: a borrowed `SpecDocument` outlives every facade
 * bound to it, and every owned `char *` the typed getters return is freed.
 */
#include "tom_som_c_v0.h"

#include "docspecs_validator.h"

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

/* The SBP root, a content leaf, and a nested complex section round-trip in both
 * directions between the typed facade and the generic document. */
static void test_root_and_parity(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint pd;
  ok(d00_solution_blueprint_new(&pd, &doc, "", NULL) == 0, "new D00SolutionBlueprint");
  eq_str(som_node_path(&pd.node), "SBP", "root segment");

  /* Typed write -> generic read. */
  d00_solution_blueprint_set_content(&pd, "A clear vision");
  eq_str(spec_document_content(&doc, "SBP/content"), "A clear vision",
         "typed write visible generically");

  /* Generic write -> typed read. */
  spec_document_set_content(&doc, "SBP/content", "Revised vision");
  char *c = d00_solution_blueprint_content(&pd);
  eq_str(c, "Revised vision", "generic write visible through typed getter");
  free(c);

  /* An unset leaf reads as the empty string (never NULL). */
  SpecDocument fresh;
  spec_document_init(&fresh);
  D00SolutionBlueprint pd2;
  d00_solution_blueprint_new(&pd2, &fresh, "", NULL);
  char *empty = d00_solution_blueprint_content(&pd2);
  eq_str(empty, "", "unset leaf reads as empty string");
  free(empty);

  /* Nested complex section path derivation (camelCase segment preserved). */
  CurrentLandscape csa = d00_solution_blueprint_current_landscape(&pd);
  eq_str(som_node_path(&csa.node), "SBP/currentLandscape",
         "nested section path");

  /* A generic value under the nested typed node is addressable via the literal
   * path (typed path == generic path). */
  spec_document_set_content(&doc, "SBP/currentLandscape/probe", "x");
  eq_str(spec_document_content(&doc, "SBP/currentLandscape/probe"), "x",
         "typed path is the generic path");

  current_landscape_free(&csa);
  d00_solution_blueprint_free(&pd);
  d00_solution_blueprint_free(&pd2);
  spec_document_free(&fresh);
  spec_document_free(&doc);
}

/* The path-based typed list maps onto the generic list store; element facades
 * are constructed from the item paths the list yields. */
static void test_typed_list(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  D00SolutionBlueprint pd;
  d00_solution_blueprint_new(&pd, &doc, "", NULL);

  CurrentLandscape csa = d00_solution_blueprint_current_landscape(&pd);
  SomList metrics = current_landscape_operational_metrics(&csa);

  /* Append two items, constructing the element facade from each new path. */
  char *p0 = som_list_add(&metrics);
  CurrentOperationalMetric m0;
  current_operational_metric_init(&m0, &doc, p0);
  current_operational_metric_set_content(&m0, "Average order turnaround: 4.2 days.");
  current_operational_metric_free(&m0);
  free(p0);

  char *p1 = som_list_add(&metrics);
  CurrentOperationalMetric m1;
  current_operational_metric_init(&m1, &doc, p1);
  current_operational_metric_set_content(&m1, "Manual reconciliation: ~12 hours / week.");
  current_operational_metric_free(&m1);
  free(p1);

  ok(som_list_length(&metrics) == 2, "typed list length");

  /* Read the first item back through an element facade over its borrowed path. */
  const char *ip0 = som_list_item_path_at(&metrics, 0);
  CurrentOperationalMetric r0;
  current_operational_metric_init(&r0, &doc, ip0);
  char *rc = current_operational_metric_content(&r0);
  eq_str(rc, "Average order turnaround: 4.2 days.", "typed list item content");
  free(rc);
  current_operational_metric_free(&r0);

  /* Typed list writes land in the generic list store under the same path. */
  ok(spec_document_list_item_count(
         &doc, "SBP/currentLandscape/CUOPME-OPER-LST") == 2,
     "generic list store mirrors typed list");

  som_list_free(&metrics);
  current_landscape_free(&csa);
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
}

/* A fixture bundling a fresh document with the typed facades bound to it, so
 * the `operational_metrics` list is exercised end-to-end for the section-id
 * scenarios. All facades hold pointers into `doc`, so the fixture is kept in
 * place (init and free the same local) and never copied. */
typedef struct {
  SpecDocument doc;
  D00SolutionBlueprint pd;
  CurrentLandscape csa;
  SomList metrics;
} MetricsFixture;

static void metrics_fixture_init(MetricsFixture *f) {
  spec_document_init(&f->doc);
  d00_solution_blueprint_new(&f->pd, &f->doc, "", NULL);
  f->csa = d00_solution_blueprint_current_landscape(&f->pd);
  f->metrics = current_landscape_operational_metrics(&f->csa);
}

static void metrics_fixture_free(MetricsFixture *f) {
  som_list_free(&f->metrics);
  current_landscape_free(&f->csa);
  d00_solution_blueprint_free(&f->pd);
  spec_document_free(&f->doc);
}

/* Appends a same-day item and asserts the generated section id of the new item
 * (queried through the typed facade over its path). */
static void add_on_expect(MetricsFixture *f, long long month, long long day,
                          const char *want) {
  char *path = som_list_add_on(&f->metrics, month, day);
  SomNode n;
  som_node_init(&n, &f->doc, path);
  char *sid = som_node_section_id(&n);
  eq_str(sid, want, "add_on section id");
  free(sid);
  som_node_free(&n);
  free(path);
}

/* Sets the section id of the item at `index` through the typed facade node. */
static int set_id_at(MetricsFixture *f, size_t index, const char *id,
                     SpecSectionIdError *err) {
  const char *path = som_list_item_path_at(&f->metrics, index);
  SomNode n;
  som_node_init(&n, &f->doc, path);
  int rc = som_node_set_section_id(&n, id, err);
  som_node_free(&n);
  return rc;
}

/* Asserts the list's section ids equal `want[0..n)` in order. */
static void expect_section_ids(MetricsFixture *f, const char *const *want,
                               size_t n, const char *name) {
  SomStrList ids;
  som_list_section_ids(&f->metrics, &ids);
  int match = ids.len == n;
  for (size_t i = 0; match && i < n; i++) {
    if (strcmp(ids.items[i], want[i]) != 0) {
      match = 0;
    }
  }
  ok(match, name);
  if (!match) {
    fprintf(stderr, "  got %zu ids:", ids.len);
    for (size_t i = 0; i < ids.len; i++) fprintf(stderr, " %s", ids.items[i]);
    fprintf(stderr, "\n");
  }
  som_strlist_free(&ids);
}

/* The generated typed facade drives section-id generation and the delete rules
 * (AA1 criteria 3–6) end-to-end. March 5 → the two-letter day code "CE"
 * (C = month 3, E = day 5). Mirrors the Rust v0 `section_ids` test. */
static void test_section_ids(void) {
  const long long MAR = 3, DAY = 5;

  /* Generation: consecutive same-day items number CE1, CE2 (criteria 3–4). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE1");
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE2");
    metrics_fixture_free(&f);
  }

  /* Override to an arbitrary suffix; a duplicate override or explicit add with
   * the same id raises a collision (criterion 5). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    char *p0 = som_list_add_on(&f.metrics, MAR, DAY); /* CE1 */
    free(p0);
    char *p1 = som_list_add_on(&f.metrics, MAR, DAY); /* CE2 */
    free(p1);

    SpecSectionIdError e;
    spec_section_id_error_init(&e);
    ok(set_id_at(&f, 1, "CUOPME-OPER-ZZ9", &e) == 1, "override succeeds");
    spec_section_id_error_free(&e);

    const char *want[] = {"CUOPME-OPER-CE1", "CUOPME-OPER-ZZ9"};
    expect_section_ids(&f, want, 2, "override applied, no renumber");

    spec_section_id_error_init(&e);
    ok(set_id_at(&f, 0, "CUOPME-OPER-ZZ9", &e) == 0 &&
           spec_section_id_is_collision(&e),
       "override collision rejected");
    spec_section_id_error_free(&e);

    spec_section_id_error_init(&e);
    char *added = NULL;
    ok(som_list_add_with_id(&f.metrics, "CUOPME-OPER-ZZ9", &added, &e) == 0 &&
           spec_section_id_is_collision(&e),
       "add-with-id collision rejected");
    free(added);
    spec_section_id_error_free(&e);

    metrics_fixture_free(&f);
  }

  /* Delete a middle item: remaining ids never renumber, and a new same-day item
   * takes the next free number (criterion 6). */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    for (int i = 0; i < 3; i++) {  /* CE1, CE2, CE3 */
      char *p = som_list_add_on(&f.metrics, MAR, DAY);
      free(p);
    }
    som_list_remove_at(&f.metrics, 1); /* drop CE2 */
    const char *want[] = {"CUOPME-OPER-CE1", "CUOPME-OPER-CE3"};
    expect_section_ids(&f, want, 2, "delete-middle keeps ids");
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE4");
    metrics_fixture_free(&f);
  }

  /* Delete the last (max) item: a new same-day item reuses the freed number. */
  {
    MetricsFixture f;
    metrics_fixture_init(&f);
    for (int i = 0; i < 3; i++) {  /* CE1, CE2, CE3 */
      char *p = som_list_add_on(&f.metrics, MAR, DAY);
      free(p);
    }
    som_list_remove_at(&f.metrics, 2); /* drop CE3 (the max) */
    add_on_expect(&f, MAR, DAY, "CUOPME-OPER-CE3");
    metrics_fixture_free(&f);
  }
}

/* Aligned absence semantics (SOM §21): the typed `is_empty` on a section, its
 * agreement with the generic `has_values_under`, and `has_content` on the leaf
 * mirroring the typed `.content` answer. Mirrors the Dart "aligned absence
 * semantics" group. Uses the SBP `requirements` section. */
static void test_aligned_absence(void) {
  /* A section is empty until any value is written under it. */
  {
    SpecDocument doc;
    spec_document_init(&doc);
    D00SolutionBlueprint pd;
    d00_solution_blueprint_new(&pd, &doc, "", NULL);

    Requirements req = d00_solution_blueprint_requirements(&pd);
    ok(som_node_is_empty(&req.node) == 1, "fresh section is empty");
    /* A nested content value fills the section (subtree emptiness). */
    requirements_set_content(&req, "Some requirements");
    ok(som_node_is_empty(&req.node) == 0, "section non-empty after content");
    /* Clearing it empties the section again. */
    requirements_set_content(&req, "");
    ok(som_node_is_empty(&req.node) == 1, "section empty after clear");

    requirements_free(&req);
    d00_solution_blueprint_free(&pd);
    spec_document_free(&doc);
  }

  /* Typed is_empty and generic has_values_under agree, before and after a
   * generic write beneath the section path. */
  {
    SpecDocument doc;
    spec_document_init(&doc);
    D00SolutionBlueprint pd;
    d00_solution_blueprint_new(&pd, &doc, "", NULL);

    Requirements req = d00_solution_blueprint_requirements(&pd);
    const char *path = som_node_path(&req.node);
    ok(som_node_is_empty(&req.node) ==
           !spec_document_has_values_under(&doc, path),
       "is_empty agrees with !has_values_under (before)");

    char *leaf = malloc(strlen(path) + strlen("/content") + 1);
    strcpy(leaf, path);
    strcat(leaf, "/content");
    spec_document_set_content(&doc, leaf, "x");
    free(leaf);

    ok(som_node_is_empty(&req.node) ==
           !spec_document_has_values_under(&doc, path),
       "is_empty agrees with !has_values_under (after)");
    ok(som_node_is_empty(&req.node) == 0, "section non-empty after write");

    requirements_free(&req);
    d00_solution_blueprint_free(&pd);
    spec_document_free(&doc);
  }

  /* has_content on the leaf gives the generic path the typed .content answer. */
  {
    SpecDocument doc;
    spec_document_init(&doc);
    D00SolutionBlueprint pd;
    d00_solution_blueprint_new(&pd, &doc, "", NULL);

    Requirements req = d00_solution_blueprint_requirements(&pd);
    const char *path = som_node_path(&req.node);
    char *leaf = malloc(strlen(path) + strlen("/content") + 1);
    strcpy(leaf, path);
    strcat(leaf, "/content");

    /* Typed '' and generic has_content(false) agree the leaf is empty. */
    char *empty = requirements_content(&req);
    eq_str(empty, "", "typed content empty initially");
    free(empty);
    ok(spec_document_has_content(&doc, leaf) == 0,
       "has_content false initially");

    requirements_set_content(&req, "Filled");
    ok(spec_document_has_content(&doc, leaf) == 1, "has_content true after set");

    free(leaf);
    requirements_free(&req);
    d00_solution_blueprint_free(&pd);
    spec_document_free(&doc);
  }
}

/* Reads a file into an owned NUL-terminated buffer (or NULL on failure). Used to
 * drive the manual three-step decode -> load_json -> thread-version comparison
 * against the one-call loaders. */
static char *read_file(const char *path) {
  FILE *fp = fopen(path, "rb");
  if (fp == NULL) return NULL;
  fseek(fp, 0, SEEK_END);
  long n = ftell(fp);
  fseek(fp, 0, SEEK_SET);
  char *buf = malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, fp);
  buf[got] = '\0';
  fclose(fp);
  return buf;
}

/* One-call loading (SOM §21): the generated `load_yaml` / `load_file`
 * collapse the former decode -> load_json -> thread-version incantation, and the
 * generic `spec_document_from_yaml` retains the parsed model version. Mirrors the
 * Dart "one-call loading" group. */
static void test_one_call_loading(void) {
  const char *sample_path =
      "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";

  /* load_yaml collapses decode -> load_json -> thread-version into one call. */
  {
    char *yaml = read_file(sample_path);
    ok(yaml != NULL, "sample yaml read");
    if (yaml != NULL) {
      /* The former two-step incantation. `decode_yaml` walks the root's
       * generated metadata tree (SOM §8) to place every key, and now returns
       * the `document:` pass already populated as a SpecDocument (with its
       * model_version stamped) — so the manual path just wraps that document in
       * the typed root, no separate load_json step. */
      SpecYamlContents decoded;
      char *derr = NULL;
      ok(decode_yaml(yaml, d00_solution_blueprint_meta_tree(), &decoded,
                     &derr) == 1,
         "decode_yaml succeeds");
      free(derr);
      D00SolutionBlueprint manual;
      d00_solution_blueprint_new(&manual, &decoded.document,
                                 decoded.model_version, NULL);

      /* The one-call convenience. */
      D00SolutionBlueprint one_call;
      SpecDocument *one_doc = NULL;
      char *err = NULL;
      ok(d00_solution_blueprint_load_yaml(&one_call, yaml, &one_doc, &err) == 0,
         "load_yaml succeeds");
      free(err);

      /* The document stamp is applied automatically — no manual threading. */
      const char *one_mv = one_doc != NULL && one_doc->model_version != NULL
                               ? one_doc->model_version
                               : "";
      eq_str(one_mv, decoded.model_version, "load_yaml retains model version");

      /* Both paths read identical content from the shared sample. */
      char *one_c = d00_solution_blueprint_content(&one_call);
      char *man_c = d00_solution_blueprint_content(&manual);
      eq_str(one_c, man_c, "load_yaml content matches manual");
      free(one_c);
      free(man_c);

      IntroductionAndScope one_intro =
          d00_solution_blueprint_introduction_and_scope(&one_call);
      Goals one_goals = introduction_and_scope_goals(&one_intro);
      IntroductionAndScope man_intro =
          d00_solution_blueprint_introduction_and_scope(&manual);
      Goals man_goals = introduction_and_scope_goals(&man_intro);
      char *one_g = goals_content(&one_goals);
      char *man_g = goals_content(&man_goals);
      eq_str(one_g, man_g, "load_yaml goals content matches manual");
      free(one_g);
      free(man_g);
      goals_free(&one_goals);
      goals_free(&man_goals);
      introduction_and_scope_free(&one_intro);
      introduction_and_scope_free(&man_intro);

      CurrentLandscape one_cl = d00_solution_blueprint_current_landscape(&one_call);
      SomList one_metrics = current_landscape_operational_metrics(&one_cl);
      CurrentLandscape man_cl = d00_solution_blueprint_current_landscape(&manual);
      SomList man_metrics = current_landscape_operational_metrics(&man_cl);
      ok(som_list_length(&one_metrics) == som_list_length(&man_metrics),
         "load_yaml metrics length matches manual");
      som_list_free(&one_metrics);
      som_list_free(&man_metrics);
      current_landscape_free(&one_cl);
      current_landscape_free(&man_cl);

      d00_solution_blueprint_free(&one_call);
      if (one_doc != NULL) {
        spec_document_free(one_doc);
        free(one_doc);
      }
      d00_solution_blueprint_free(&manual);
      spec_yaml_contents_free(&decoded);
    }
    free(yaml);
  }

  /* load_file reads the file then delegates to load_yaml. */
  {
    char *yaml = read_file(sample_path);
    if (yaml != NULL) {
      D00SolutionBlueprint from_file;
      SpecDocument *file_doc = NULL;
      char *ferr = NULL;
      ok(d00_solution_blueprint_load_file(&from_file, sample_path, &file_doc,
                                          &ferr) == 0,
         "load_file succeeds");
      free(ferr);

      D00SolutionBlueprint from_yaml;
      SpecDocument *yaml_doc = NULL;
      char *yerr = NULL;
      d00_solution_blueprint_load_yaml(&from_yaml, yaml, &yaml_doc, &yerr);
      free(yerr);

      const char *fmv = file_doc != NULL && file_doc->model_version != NULL
                            ? file_doc->model_version
                            : "";
      const char *ymv = yaml_doc != NULL && yaml_doc->model_version != NULL
                            ? yaml_doc->model_version
                            : "";
      eq_str(fmv, ymv, "load_file model version matches load_yaml");

      char *fc = d00_solution_blueprint_content(&from_file);
      char *yc = d00_solution_blueprint_content(&from_yaml);
      eq_str(fc, yc, "load_file content matches load_yaml");
      free(fc);
      free(yc);

      d00_solution_blueprint_free(&from_file);
      d00_solution_blueprint_free(&from_yaml);
      if (file_doc != NULL) { spec_document_free(file_doc); free(file_doc); }
      if (yaml_doc != NULL) { spec_document_free(yaml_doc); free(yaml_doc); }
    }
    free(yaml);
  }

  /* The generic one-call yaml loader retains the parsed model version. */
  {
    const char *yaml =
        "version: 2\n"
        "modelVersion: \"1.0\"\n"
        "document:\n"
        "  SBP D00SolutionBlueprint:\n"
        "    content: |2-\n"
        "      Hello\n";
    char *ferr = NULL;
    SpecDocument *doc =
        spec_document_from_yaml(yaml, d00_solution_blueprint_meta_tree(), &ferr);
    ok(doc != NULL, "from_yaml returns a document");
    free(ferr);
    if (doc != NULL) {
      const char *mv = doc->model_version != NULL ? doc->model_version : "";
      eq_str(mv, "1.0", "from_yaml retains model version");
      const char *c = spec_document_content(doc, "SBP/content");
      eq_str(c != NULL ? c : "", "Hello", "from_yaml content parsed");
      spec_document_free(doc);
      free(doc);
    }
  }

  /* An unstamped document loads with the empty-string sentinel model version,
   * and load_yaml still succeeds. */
  {
    const char *yaml = "version: 2\ndocument: {}\n";
    char *uerr = NULL;
    SpecDocument *doc =
        spec_document_from_yaml(yaml, d00_solution_blueprint_meta_tree(), &uerr);
    ok(doc != NULL, "from_yaml (unstamped) returns a document");
    free(uerr);
    if (doc != NULL) {
      const char *mv = doc->model_version != NULL ? doc->model_version : "";
      eq_str(mv, "", "unstamped yaml -> empty model version sentinel");
      spec_document_free(doc);
      free(doc);
    }
    D00SolutionBlueprint root;
    SpecDocument *root_doc = NULL;
    char *err = NULL;
    ok(d00_solution_blueprint_load_yaml(&root, yaml, &root_doc, &err) == 0,
       "load_yaml accepts unstamped document");
    free(err);
    d00_solution_blueprint_free(&root);
    if (root_doc != NULL) { spec_document_free(root_doc); free(root_doc); }
  }
}

/* The per-type structural `can_have_content` predicate (SOM §21): every
 * generated type emits a `<type>_can_have_content` accessor returning the
 * literal answer to "does this section TYPE declare the standard `content` text
 * leaf?" — WITHOUT probing the document (mirrors the item-8 `editability_for` /
 * item-5 `is_empty` per-type C emission). A content-bearing section (Goals) and
 * the content-bearing root (D00SolutionBlueprint) report 1; a container-only
 * section (SystemsToReplace, which has no `content` leaf) reports 0. Mirrors the
 * Dart `canHaveContent` structural checks. */
static void test_can_have_content(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  /* The root itself is content-bearing (it carries `content` / `set_content`). */
  D00SolutionBlueprint pd;
  d00_solution_blueprint_new(&pd, &doc, "", NULL);
  ok(d00_solution_blueprint_can_have_content(&pd) == 1,
     "root D00SolutionBlueprint can_have_content is true");

  /* Goals is a content-bearing section (has a `content` leaf). */
  Goals goals;
  goals_init(&goals, &doc, "SBP/introductionAndScope/goals");
  ok(goals_can_have_content(&goals) == 1,
     "Goals can_have_content is true");

  /* SystemsToReplace is container-only (no `content` leaf) → false. */
  SystemsToReplace systems;
  systems_to_replace_init(&systems, &doc, "SBP/systemsToReplace");
  ok(systems_to_replace_can_have_content(&systems) == 0,
     "SystemsToReplace can_have_content is false");

  /* Structural, never stateful: writing a value under Goals' content leaf does
   * not change the answer. */
  goals_set_content(&goals, "Some goals");
  ok(goals_can_have_content(&goals) == 1,
     "Goals can_have_content stays true after content is written");

  goals_free(&goals);
  systems_to_replace_free(&systems);
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
}

/* The generated model version is reported by both the macro and the accessor. */
static void test_model_version(void) {
  eq_str(D00_SOLUTION_BLUEPRINT_MODEL_VERSION, "1.0", "MODEL_VERSION macro");

  SpecDocument doc;
  spec_document_init(&doc);
  D00SolutionBlueprint pd;
  d00_solution_blueprint_new(&pd, &doc, "", NULL);
  eq_str(d00_solution_blueprint_object_model_version(&pd), "1.0",
         "object_model_version accessor");
  d00_solution_blueprint_free(&pd);
  spec_document_free(&doc);
}

/* The instantiation-time SOM §4.2 version check accepts editable stamps and rejects
 * newer-minor / cross-major stamps with a non-zero return and an owned message. */
static void test_version_check(void) {
  SpecDocument doc;
  spec_document_init(&doc);

  D00SolutionBlueprint a;
  ok(d00_solution_blueprint_new(&a, &doc, "", NULL) == 0, "empty stamp accepted");
  d00_solution_blueprint_free(&a);

  D00SolutionBlueprint b;
  ok(d00_solution_blueprint_new(&b, &doc, "1.0", NULL) == 0, "equal stamp accepted");
  d00_solution_blueprint_free(&b);

  /* Newer minor -> rejected (no node bound, so nothing to free on the facade). */
  char *err = NULL;
  D00SolutionBlueprint c;
  ok(d00_solution_blueprint_new(&c, &doc, "1.1", &err) != 0,
     "newer-minor stamp rejected");
  ok(err != NULL, "rejection writes an owned message");
  free(err);
  err = NULL;

  /* Different major -> rejected. */
  D00SolutionBlueprint d;
  ok(d00_solution_blueprint_new(&d, &doc, "2.0", &err) != 0,
     "cross-major stamp rejected");
  free(err);

  spec_document_free(&doc);
}

/* SomStrList element-wise equality (both lists are byte-sorted by the runtime
 * enumerators, so a positional compare is exact). */
static int strlist_eq(const SomStrList *a, const SomStrList *b) {
  if (a->len != b->len) return 0;
  for (size_t i = 0; i < a->len; i++) {
    if (strcmp(a->items[i], b->items[i]) != 0) return 0;
  }
  return 1;
}

/* Live-document conformance case durability guard (YRD8 / dsa14). The
 * cross-language golden harness (tom_som_conformance/tool/regenerate_golden.sh +
 * compare_golden.dart) already exercises the shared Meridian sample end to end
 * and asserts c.log is byte-identical to the Dart reference, but golden/ is
 * git-ignored. This committed test pins the three live-document guarantees the C
 * golden generator emits — a regression fails ./run_tests.sh, not only a full
 * nine-toolchain golden run. Mirrors the Dart (dsa7) … Rust (dsa13) guards. */
static void test_live_document_case(void) {
  const char *sample_path =
      "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
  const char *sample_md_path =
      "../tom_som_conformance/samples/meridian_order_management.md";
  const char *schema_path =
      "schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml";
  const SomMetaTree *tree = d00_solution_blueprint_meta_tree();

  /* 1) Round-trip: decode -> encode -> decode is stable over content + lists. */
  char *load_err = NULL;
  SpecDocument *original = spec_document_from_file(sample_path, tree, &load_err);
  ok(original != NULL, "live: from_file loads the sample");
  free(load_err);
  if (original != NULL) {
    char *enc_err = NULL;
    char *re_encoded = encode_yaml(original, tree, original->model_version, &enc_err);
    ok(re_encoded != NULL, "live: encode_yaml re-serializes");
    free(enc_err);
    char *dec_err = NULL;
    SpecDocument *round =
        re_encoded != NULL ? spec_document_from_yaml(re_encoded, tree, &dec_err) : NULL;
    ok(round != NULL, "live: from_yaml round-trips");
    free(dec_err);

    if (round != NULL) {
      const char *omv = original->model_version != NULL ? original->model_version : "";
      const char *rmv = round->model_version != NULL ? round->model_version : "";
      eq_str(rmv, omv, "live: round-trip model version stable");

      SomStrList oc, rc;
      som_strlist_init(&oc);
      som_strlist_init(&rc);
      spec_document_content_paths(original, &oc);
      spec_document_content_paths(round, &rc);
      ok(strlist_eq(&oc, &rc), "live: content-path set stable");
      int content_vals_ok = 1;
      for (size_t i = 0; i < oc.len && i < rc.len; i++) {
        const char *ov = spec_document_content(original, oc.items[i]);
        const char *rv = spec_document_content(round, oc.items[i]);
        if (strcmp(ov != NULL ? ov : "", rv != NULL ? rv : "") != 0) {
          content_vals_ok = 0;
        }
      }
      ok(content_vals_ok, "live: content values stable");
      som_strlist_free(&oc);
      som_strlist_free(&rc);

      SomStrList ol, rl;
      som_strlist_init(&ol);
      som_strlist_init(&rl);
      spec_document_list_paths(original, &ol);
      spec_document_list_paths(round, &rl);
      ok(strlist_eq(&ol, &rl), "live: list-path set stable");
      int list_items_ok = 1;
      for (size_t i = 0; i < ol.len; i++) {
        const SomStrList *oi = spec_document_list_items(original, ol.items[i]);
        const SomStrList *ri = spec_document_list_items(round, ol.items[i]);
        if (oi == NULL || ri == NULL || !strlist_eq(oi, ri)) list_items_ok = 0;
      }
      ok(list_items_ok, "live: list items stable");
      som_strlist_free(&ol);
      som_strlist_free(&rl);

      spec_document_free(round);
      free(round);
    }
    free(re_encoded);
    spec_document_free(original);
    free(original);
  }

  /* 2) Validation: the markdown twin is clean under the SBP schema. */
  char *schema_text = read_file(schema_path);
  char *sample_md = read_file(sample_md_path);
  ok(schema_text != NULL && sample_md != NULL, "live: read schema + markdown");
  if (schema_text != NULL && sample_md != NULL) {
    DocSpecsSchema *schema = NULL;
    char *serr = NULL;
    ok(docspecs_schema_from_yaml_text(schema_text, &schema, &serr) != 0,
       "live: schema parses");
    free(serr);
    if (schema != NULL) {
      DocSpecsValidator val = docspecs_validator_new(schema);
      DocSpecsViolationList violations;
      docspecs_violation_list_init(&violations);
      docspecs_validator_validate_markdown(&val, sample_md, &violations);
      char *root = docspecs_schema_root_section_id(schema);
      eq_str(root != NULL ? root : "", "SBP", "live: schema root is SBP");
      free(root);
      ok(schema->warnings.len == 0, "live: schema carries no warnings");
      ok(violations.len == 0, "live: markdown validates cleanly");
      docspecs_violation_list_free(&violations);
      docspecs_schema_free(schema);
    }
  }
  free(sample_md);
  free(schema_text);

  /* 3) Node operations: by_path / nav / id resolve to the same node instance. */
  const SomMetaNode *list_by_path =
      som_meta_tree_by_path(tree, "SBP/currentLandscape/CUOPME-OPER-LST");
  ok(list_by_path != NULL, "live: by_path finds the operationalMetrics list");
  if (list_by_path != NULL) {
    ok(strcmp(list_by_path->kind, SOM_META_KIND_LIST) == 0,
       "live: operationalMetrics kind is list");
  }

  som_nav_d00_solution_blueprint nroot = d00_solution_blueprint_meta(tree);
  som_nav_current_landscape n_cl = d00_solution_blueprint_nav_current_landscape(nroot);
  SomListMetaRef nav_metrics = current_landscape_nav_operational_metrics(n_cl);
  eq_str(nav_metrics.ref.path, "SBP/currentLandscape/CUOPME-OPER-LST",
         "live: nav path");
  char *nav_err = NULL;
  const SomMetaNode *nav_node = som_meta_ref_meta(&nav_metrics.ref, &nav_err);
  free(nav_err);
  ok(nav_node == list_by_path, "live: nav node identity == by_path node");

  som_id_d00_solution_blueprint id_sbp = SBP(tree);
  SomListMetaRef id_revs = d00_solution_blueprint_id_rvhst_revs_lst(id_sbp);
  som_nav_document_control n_dc = d00_solution_blueprint_nav_document_control(nroot);
  SomListMetaRef nav_revs = document_control_nav_revision_history(n_dc);
  void *id_item0 = som_list_meta_ref_item(&id_revs, 0);
  void *nav_item0 = som_list_meta_ref_item(&nav_revs, 0);
  SomMetaRef *id_ref0 = (SomMetaRef *)id_item0;
  SomMetaRef *nav_ref0 = (SomMetaRef *)nav_item0;
  eq_str(id_ref0->path, nav_ref0->path, "live: id item path == nav item path");
  char *ierr = NULL;
  char *nerr = NULL;
  const SomMetaNode *idn = som_meta_ref_meta(id_ref0, &ierr);
  const SomMetaNode *navn = som_meta_ref_meta(nav_ref0, &nerr);
  free(ierr);
  free(nerr);
  ok(idn == navn, "live: id item node identity == nav item node");

  som_meta_ref_free((SomMetaRef *)id_item0);
  free(id_item0);
  som_meta_ref_free((SomMetaRef *)nav_item0);
  free(nav_item0);
  som_meta_ref_free(&nav_revs.ref);
  som_meta_ref_free(&n_dc.ref);
  som_meta_ref_free(&id_revs.ref);
  som_meta_ref_free(&id_sbp.ref);
  som_meta_ref_free(&nav_metrics.ref);
  som_meta_ref_free(&n_cl.ref);
  som_meta_ref_free(&nroot.ref);
}

int main(void) {
  test_root_and_parity();
  test_typed_list();
  test_section_ids();
  test_aligned_absence();
  test_can_have_content();
  test_one_call_loading();
  test_model_version();
  test_version_check();
  test_live_document_case();

  if (g_failed != 0) {
    fprintf(stderr, "\n%d checks FAILED (%d passed)\n", g_failed, g_passed);
    return 1;
  }
  printf("OK: %d checks passed\n", g_passed);
  return 0;
}
