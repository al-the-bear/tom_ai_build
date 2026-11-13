/* SOM §11.2 `units`: the generation units a section goes to — a port of the
 * Dart `tom_som_dart_runtime/test/spec_units_test.dart` cases this runtime
 * has a surface for. Kept exactly as `codeSpec` is: a sparse store by section
 * path, the Markdown heading key `units="a,b"` after `codeSpec`, the YAML key
 * `units` after `codeSpec`, the snapshot's `units` map — and checked by the
 * instance tier's phase 8 — and the document's register of units
 * (`spec_generation_units`, `spec_default_units`).
 *
 * Not ported: the Dart `captureState` / fingerprint and path-normalizer cases
 * (this runtime has neither surface).
 *
 * Reads the shared corpus model (`../tom_som_conformance/corpus/
 * model.meta.json`, the demo root with the generation-unit register
 * `DEMO/DLV-LST`). Exit status is the number of failed checks (0 = green). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

#define UNITS_SIBLINGS ".."

static int g_checks = 0;
static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  if (detail != NULL && detail[0] != '\0')
    fprintf(stderr, "FAIL %s: %s\n", name, detail);
  else
    fprintf(stderr, "FAIL %s\n", name);
}

static int str_eq(const char *a, const char *b) {
  return a != NULL && b != NULL && strcmp(a, b) == 0;
}

static char *read_file(const char *path) {
  FILE *f = fopen(path, "rb");
  if (f == NULL) {
    fprintf(stderr, "fatal: cannot read %s\n", path);
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  rewind(f);
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  buf[got] = '\0';
  fclose(f);
  return buf;
}

static SpecModel *corpus_model(void) {
  char *text =
      read_file(UNITS_SIBLINGS "/tom_som_conformance/corpus/model.meta.json");
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(text, &err);
  free(text);
  if (m == NULL) {
    fprintf(stderr, "fatal: corpus model: %s\n", err != NULL ? err : "");
    free(err);
    exit(2);
  }
  return m;
}

static char *snapshot(const SpecDocument *d) {
  DocumentJson j;
  spec_document_to_json(d, &j);
  char *s = document_json_to_canonical_json(&j);
  document_json_free(&j);
  return s;
}

static void set_form(SpecDocument *d, const char *item, const char *field,
                     const char *value) {
  size_t n = strlen(item) + sizeof("/content");
  char *form = (char *)malloc(n);
  snprintf(form, n, "%s/content", item);
  spec_document_set_form_field(d, form, field, value);
  free(form);
}

/* A register declaring `u_a` and `u_b`, both building something. */
static void make_register(SpecDocument *d) {
  spec_document_init(d);
  char *a = spec_document_add_list_item(d, "DEMO/DLV-LST");
  set_form(d, a, "unitId", "u_a");
  set_form(d, a, "component", "ARCM-COMP-A");
  char *b = spec_document_add_list_item(d, "DEMO/DLV-LST");
  set_form(d, b, "unitId", "u_b");
  set_form(d, b, "deploymentTarget", "DEPTAR-DEPL-B");
  free(a);
  free(b);
}

/* ---- the store ----------------------------------------------------------- */

static void test_store(const SpecModel *model) {
  {
    SpecDocument d;
    spec_document_init(&d);
    check("store.unset", spec_document_units(&d, "DEMO/TTL") == NULL, "");
    spec_document_set_units(&d, "DEMO/TTL", "u_a,u_b");
    check("store.get", str_eq(spec_document_units(&d, "DEMO/TTL"), "u_a,u_b"),
          "");
    SomStrList paths;
    spec_document_units_paths(&d, &paths);
    check("store.paths", paths.len == 1 && str_eq(paths.items[0], "DEMO/TTL"),
          "");
    som_strlist_free(&paths);
    check("store.notEmpty", !spec_document_is_empty(&d), "");
    check("store.hasValuesUnder", spec_document_has_values_under(&d, "DEMO"),
          "");
    spec_document_set_units(&d, "DEMO/TTL", "");
    check("store.cleared", spec_document_units(&d, "DEMO/TTL") == NULL, "");
    spec_document_units_paths(&d, &paths);
    check("store.pathsEmpty", paths.len == 0, "");
    som_strlist_free(&paths);
    check("store.empty", spec_document_is_empty(&d), "");
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    spec_document_init(&d);
    spec_document_set_code_spec(&d, "DEMO/TTL", "A");
    spec_document_set_units(&d, "DEMO/TTL", "u_b");
    spec_document_set_units(&d, "DEMO/SUM", "u_a");
    char *json = snapshot(&d);
    check("snapshot.unitsAfterCodeSpecs",
          str_eq(json, "{\"codeSpecs\":{\"DEMO/TTL\":\"A\"},\"units\":{"
                       "\"DEMO/SUM\":\"u_a\",\"DEMO/TTL\":\"u_b\"}}"),
          json);
    char *err = NULL;
    SomJson *parsed = som_json_parse(json, &err);
    free(err);
    DocumentJson j;
    document_json_from_json(parsed, &j);
    SpecDocument back;
    spec_document_init(&back);
    spec_document_load_json(&back, &j);
    char *again = snapshot(&back);
    check("snapshot.roundTrip", str_eq(again, json), again);
    free(again);
    spec_document_free(&back);
    document_json_free(&j);
    som_json_free(parsed);
    free(json);
    spec_document_free(&d);

    SpecDocument empty;
    spec_document_init(&empty);
    char *none = snapshot(&empty);
    check("snapshot.noUnitsNoKey", strstr(none, "units") == NULL, none);
    free(none);
    spec_document_free(&empty);
  }
  {
    SpecDocument d;
    spec_document_init(&d);
    spec_document_set_units(&d, "DEMO/notes", "u_a");
    spec_document_set_units(&d, "DEMO/notes/NOTE-BDY", "u_b");
    spec_document_set_units(&d, "DEMO/TTL", "u_a");
    spec_document_remove_values_under(&d, "DEMO/notes");
    SomStrList paths;
    spec_document_units_paths(&d, &paths);
    check("store.removeValuesUnder",
          paths.len == 1 && str_eq(paths.items[0], "DEMO/TTL"), "");
    som_strlist_free(&paths);
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    spec_document_init(&d);
    char *first = spec_document_add_list_item(&d, "DEMO/items");
    char *second = spec_document_add_list_item(&d, "DEMO/items");
    char *p1 = (char *)malloc(strlen(first) + 8);
    char *p2 = (char *)malloc(strlen(second) + 8);
    snprintf(p1, strlen(first) + 8, "%s/label", first);
    snprintf(p2, strlen(second) + 8, "%s/label", second);
    spec_document_set_content(&d, p1, "one");
    spec_document_set_content(&d, p2, "two");
    spec_document_set_units(&d, second, "u_a");
    SpecListItemMove mv;
    SpecListMoveError merr;
    spec_list_move_error_init(&merr);
    int ok = spec_document_move_list_item(&d, model, second, 0, NULL, &mv,
                                          &merr);
    check("store.move.ok", ok, merr.message != NULL ? merr.message : "");
    check("store.move.first", str_eq(spec_document_units(&d, "DEMO/items-1"),
                                     "u_a"),
          "");
    check("store.move.second",
          spec_document_units(&d, "DEMO/items-2") == NULL, "");
    spec_list_item_move_free(&mv);
    spec_list_move_error_free(&merr);
    free(p1);
    free(p2);
    free(first);
    free(second);
    spec_document_free(&d);
  }
}

static void test_facade(void) {
  SpecDocument d;
  spec_document_init(&d);
  SomNode node = {&d, "DEMO/TTL"};
  char *v = som_node_units(&node);
  check("facade.unset", str_eq(v, ""), v);
  free(v);
  som_node_set_units(&node, "u_a");
  check("facade.set", str_eq(spec_document_units(&d, "DEMO/TTL"), "u_a"), "");
  v = som_node_units(&node);
  check("facade.get", str_eq(v, "u_a"), v);
  free(v);
  som_node_set_units(&node, "");
  check("facade.cleared", spec_document_units(&d, "DEMO/TTL") == NULL, "");
  spec_document_free(&d);
}

/* ---- Markdown ------------------------------------------------------------ */

static void test_markdown(const SpecModel *model) {
  const SpecRoot *root = spec_model_root_by_type(model, "Demo", NULL);
  {
    SpecDocument d;
    spec_document_init(&d);
    spec_document_set_content(&d, "DEMO/TTL", "Hello");
    spec_document_set_code_spec(&d, "DEMO/TTL", "DemoTitle");
    spec_document_set_units(&d, "DEMO/TTL", "u_a,u_b");
    spec_document_set_content(&d, "DEMO/SUM", "Sum");
    spec_document_set_units(&d, "DEMO/SUM", "u_a");
    char *md = spec_markdown_export_root(model, &d, root, NULL);
    check("md.emit.afterCodeSpec",
          strstr(md, "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> "
                     "Document Title\n") != NULL,
          md);
    check("md.emit.alone",
          strstr(md, "## <!--[SUM] units=\"u_a\"--> Summary\n") != NULL, md);
    free(md);
    spec_document_free(&d);
  }
  {
    const char *md =
        "# <!--[DEMO] units=u_root--> Demo Document\n\n"
        "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Title\n\n"
        "Hello\n\n"
        "## <!--[SUM] units='u_c'--> Summary\n\n"
        "Sum\n\n"
        "## <!--[CNT] codeSpec=\"units=no\"--> Count\n\n"
        "3\n";
    SpecMarkdownResult r;
    spec_markdown_parse(model, md, &r);
    check("md.parse.clean", r.rejections_len == 0, "");
    const SomMap *u = &r.staged.units;
    check("md.parse.units.count", u->len == 3, "");
    check("md.parse.units.bare", str_eq(som_map_get(u, "DEMO"), "u_root"), "");
    check("md.parse.units.double",
          str_eq(som_map_get(u, "DEMO/TTL"), "u_a,u_b"), "");
    check("md.parse.units.single", str_eq(som_map_get(u, "DEMO/SUM"), "u_c"),
          "");
    check("md.parse.codeSpec",
          str_eq(som_map_get(&r.staged.code_specs, "DEMO/TTL"), "DemoTitle"),
          "");
    check("md.parse.unitsInsideCodeSpec",
          str_eq(som_map_get(&r.staged.code_specs, "DEMO/CNT"), "units=no") &&
              som_map_get(u, "DEMO/CNT") == NULL,
          "");
    spec_markdown_result_free(&r);
  }
  {
    /* Both keys read as the pattern `"…"|'…'|[^,\s>]+` reads them: a quote
     * that is never closed is a bare value, and an occurrence with no value
     * is passed over. */
    const char *md =
        "# <!--[DEMO] codeSpec=, codeSpec=Later--> Demo Document\n\n"
        "## <!--[TTL] codeSpec=\"Open--> Title\n\n"
        "Hello\n\n"
        "## <!--[SUM] units=\"u_x--> Summary\n\n"
        "Sum\n";
    SpecMarkdownResult r;
    spec_markdown_parse(model, md, &r);
    check("md.parse.codeSpec.skipsEmpty",
          str_eq(som_map_get(&r.staged.code_specs, "DEMO"), "Later"), "");
    check("md.parse.codeSpec.unclosedIsBare",
          str_eq(som_map_get(&r.staged.code_specs, "DEMO/TTL"), "\"Open"),
          "");
    check("md.parse.units.unclosedIsBare",
          str_eq(som_map_get(&r.staged.units, "DEMO/SUM"), "\"u_x"), "");
    spec_markdown_result_free(&r);
  }
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_content(&d, "DEMO/TTL", "Hello");
    spec_document_set_code_spec(&d, "DEMO/TTL", "DemoTitle");
    spec_document_set_units(&d, "DEMO/TTL", "u_a");
    spec_document_set_content(&d, "DEMO/notes/NOTE-BDY", "Body");
    spec_document_set_units(&d, "DEMO/notes", "u_a,u_b");
    char *md = spec_markdown_export_root(model, &d, root, NULL);
    SpecMarkdownImport imp;
    spec_document_from_markdown(md, model, &imp);
    check("md.roundTrip.ttl",
          str_eq(spec_document_units(imp.document, "DEMO/TTL"), "u_a"), "");
    check("md.roundTrip.notes",
          str_eq(spec_document_units(imp.document, "DEMO/notes"), "u_a,u_b"),
          "");
    char *again = spec_markdown_export_root(model, imp.document, root, NULL);
    check("md.roundTrip.byteStable", str_eq(again, md), again);
    free(again);
    spec_markdown_import_free(&imp);
    free(md);
    spec_document_free(&d);
  }
}

/* ---- YAML ---------------------------------------------------------------- */

static char *yaml_round(SomMetaTree *tree, const SpecDocument *d,
                        const char *tag) {
  char *err = NULL;
  char *yaml = encode_yaml(d, tree, "1.0", &err);
  if (yaml == NULL) {
    check(tag, 0, err);
    free(err);
    return NULL;
  }
  SpecYamlContents back;
  int ok = decode_yaml(yaml, tree, &back, &err);
  if (!ok) {
    check(tag, 0, err);
    free(err);
    return yaml;
  }
  char *want = snapshot(d);
  char *got = snapshot(&back.document);
  char name[128];
  snprintf(name, sizeof(name), "%s.document", tag);
  check(name, str_eq(got, want), got);
  char *again = encode_yaml(&back.document, tree, "1.0", NULL);
  snprintf(name, sizeof(name), "%s.byteStable", tag);
  check(name, str_eq(again, yaml), again);
  free(again);
  free(got);
  free(want);
  spec_yaml_contents_free(&back);
  return yaml;
}

static void test_yaml(const SpecModel *model) {
  char *err = NULL;
  SomMetaTree *tree = som_build_meta_tree(model, "Demo", &err);
  check("yaml.tree", tree != NULL, err);
  free(err);
  if (tree == NULL) return;
  {
    SpecDocument d;
    spec_document_init(&d);
    spec_document_set_content(&d, "DEMO/TTL", "Hello");
    spec_document_set_headline(&d, "DEMO/TTL", "Title");
    spec_document_set_code_spec(&d, "DEMO/TTL", "DemoTitle");
    spec_document_set_units(&d, "DEMO/TTL", "u_a");
    spec_document_set_content(&d, "DEMO/CNT", "3");
    spec_document_set_units(&d, "DEMO/CNT", "u_b");
    spec_document_set_content(&d, "DEMO/notes/NOTE-BDY", "Body");
    spec_document_set_units(&d, "DEMO/notes", "u_a,u_b");
    char *yaml = yaml_round(tree, &d, "yaml.scalar");
    if (yaml != NULL) {
      check("yaml.scalar.promoted",
            strstr(yaml, "    TTL title:\n"
                         "      headline: |2-\n        Title\n"
                         "      codeSpec: |2-\n        DemoTitle\n"
                         "      units: |2-\n        u_a\n"
                         "      content: |2-\n        Hello\n") != NULL,
            yaml);
      check("yaml.scalar.plainContent",
            strstr(yaml, "    CNT count:\n      units: |2-\n        u_b\n"
                         "      content: 3\n") != NULL,
            yaml);
      check("yaml.section.units",
            strstr(yaml, "    NOTE notes:\n      units: |2-\n        "
                         "u_a,u_b\n") != NULL,
            yaml);
    }
    free(yaml);
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_form_field(&d, "DEMO/DET", "owner", "Bob");
    spec_document_set_units(&d, "DEMO/DET", "u_a");
    spec_document_set_units(&d, "DEMO/DLV-LST", "u_b");
    spec_document_set_units(&d, "DEMO/DLV-LST-1", "u_a");
    char *tag = spec_document_add_list_item(&d, "DEMO/META/tags");
    spec_document_set_content(&d, tag, "on");
    spec_document_set_units(&d, tag, "u_b");
    free(tag);
    free(yaml_round(tree, &d, "yaml.formListItem"));
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    spec_document_init(&d);
    char *item = spec_document_add_list_item_with_section_id(
        &d, "DEMO/DLV-LST", "units", NULL);
    free(item);
    char *yerr = NULL;
    char *yaml = encode_yaml(&d, tree, "1.0", &yerr);
    check("yaml.itemKeyedUnits.refused", yaml == NULL, yaml);
    free(yaml);
    free(yerr);
    spec_document_free(&d);
  }
  som_meta_tree_free(tree);

  /* A child or a form field named `units` refuses the stored units. */
  const char *clash_json =
      "{\"roots\": [{\"type\": \"R\", \"title\": \"R\", \"sectionId\": "
      "\"R\"}],\n"
      " \"classes\": {\"R\": {\"name\": \"R\", \"sectionId\": \"R\", "
      "\"fields\": [\n"
      "   {\"name\": \"units\", \"kind\": \"content\"},\n"
      "   {\"name\": \"shape\", \"kind\": \"form\", \"sectionId\": \"SHP\",\n"
      "    \"formFields\": [{\"name\": \"units\", \"label\": \"Units\", "
      "\"type\": \"String\"}]}]}}}";
  SpecModel *clash = spec_model_from_json_str(clash_json, &err);
  check("yaml.clash.model", clash != NULL, err);
  free(err);
  if (clash == NULL) return;
  SomMetaTree *ct = som_build_meta_tree(clash, "R", &err);
  check("yaml.clash.tree", ct != NULL, err);
  free(err);
  if (ct != NULL) {
    SpecDocument d;
    spec_document_init(&d);
    spec_document_set_units(&d, "R", "u_a");
    char *yerr = NULL;
    char *yaml = encode_yaml(&d, ct, "1.0", &yerr);
    check("yaml.clash.child",
          yaml == NULL && yerr != NULL &&
              strstr(yerr, "also serializes as key `units`") != NULL,
          yerr != NULL ? yerr : "");
    free(yaml);
    free(yerr);
    spec_document_free(&d);

    spec_document_init(&d);
    spec_document_set_form_field(&d, "R/SHP", "units", "3");
    spec_document_set_units(&d, "R/SHP", "u_a");
    yerr = NULL;
    yaml = encode_yaml(&d, ct, "1.0", &yerr);
    check("yaml.clash.formField",
          yaml == NULL && yerr != NULL &&
              strstr(yerr, "field literally named `units`") != NULL,
          yerr != NULL ? yerr : "");
    free(yaml);
    free(yerr);
    spec_document_free(&d);
    som_meta_tree_free(ct);
  }
  spec_model_free(clash);
}

/* ---- apply, assembly, review merge --------------------------------------- */

static void test_apply(const SpecModel *model) {
  SpecDocument d;
  spec_document_init(&d);
  spec_document_set_units(&d, "DEMO/TTL", "stale");
  spec_document_set_units(&d, "DEMO/SUM", "stale");
  spec_document_set_units(&d, "OTHER/kept", "kept");
  const char *md = "# <!--[DEMO]--> Demo Document\n\n"
                   "## <!--[TTL] units=\"u_a\"--> Document Title\n\nHello\n";
  SpecMarkdownResult r;
  spec_markdown_parse(model, md, &r);
  char *err = NULL;
  int rc = spec_document_apply_markdown_result(&d, &r, 0, &err);
  check("apply.ok", rc == 0, err);
  free(err);
  char *json = snapshot(&d);
  check("apply.units",
        strstr(json, "\"units\":{\"DEMO/TTL\":\"u_a\",\"OTHER/kept\":\"kept\"}") !=
            NULL,
        json);
  free(json);
  spec_markdown_result_free(&r);
  spec_document_free(&d);
}

static void test_assembly(void) {
  SpecDocument a, b, c;
  spec_document_init(&a);
  spec_document_init(&b);
  spec_document_init(&c);
  spec_document_set_units(&a, "DEMO/TTL", "u_a");
  spec_document_set_units(&b, "DEMO/SUM", "u_b");
  spec_document_set_units(&c, "DEMO/TTL", "u_b");
  SpecAssemblyFragment ok_frags[2] = {{"a", &a}, {"b", &b}};
  SpecDocumentAssembly ok;
  spec_document_assemble(ok_frags, 2, &ok);
  check("assembly.ok", spec_document_assembly_ok(&ok), "");
  check("assembly.units",
        ok.document != NULL &&
            str_eq(spec_document_units(ok.document, "DEMO/SUM"), "u_b"),
        "");
  spec_document_assembly_free(&ok);
  SpecAssemblyFragment clash_frags[2] = {{"a", &a}, {"c", &c}};
  SpecDocumentAssembly clash;
  spec_document_assemble(clash_frags, 2, &clash);
  check("assembly.clash", !spec_document_assembly_ok(&clash), "");
  check("assembly.clash.store",
        clash.overlaps_len == 1 && str_eq(clash.overlaps[0].store, "units") &&
            str_eq(clash.overlaps[0].path, "DEMO/TTL"),
        "");
  spec_document_assembly_free(&clash);
  spec_document_free(&a);
  spec_document_free(&b);
  spec_document_free(&c);
}

static void test_review_merge(const SpecModel *model) {
  SpecDocument base;
  spec_document_init(&base);
  char *first = spec_document_add_list_item(&base, "DEMO/items");
  char *label = (char *)malloc(strlen(first) + 8);
  snprintf(label, strlen(first) + 8, "%s/label", first);
  spec_document_set_content(&base, label, "one");
  free(label);
  free(first);

  SpecDocument copy;
  spec_document_init(&copy);
  DocumentJson j;
  spec_document_to_json(&base, &j);
  spec_document_load_json(&copy, &j);
  document_json_free(&j);
  char *added = spec_document_add_list_item(&copy, "DEMO/items");
  label = (char *)malloc(strlen(added) + 8);
  snprintf(label, strlen(added) + 8, "%s/label", added);
  spec_document_set_content(&copy, label, "two");
  free(label);
  spec_document_set_units(&copy, added, "u_a");
  free(added);

  SpecReviewMember member = {"alice", "Alice", ""};
  SpecReviewedDocument copies[1] = {{member, &copy}};
  SpecReviewMergeOptions opts = {&member, 1, "2026-11-12", "alice", NULL};
  SpecDocument merged;
  SpecReviewMergeReport report;
  SpecReviewMergeError err;
  spec_review_merge_error_init(&err);
  int ok = spec_review_merge_documents(model, &base, copies, 1, &opts, &merged,
                                       &report, &err);
  check("merge.ok", ok, err.message != NULL ? err.message : "");
  const SomStrList *items = spec_document_list_items(&merged, "DEMO/items");
  check("merge.items", items != NULL && items->len == 2, "");
  if (items != NULL && items->len == 2) {
    const char *u = spec_document_units(&merged, items->items[1]);
    check("merge.addedItemUnits", str_eq(u, "u_a"), u != NULL ? u : "(null)");
  }
  spec_review_merge_error_free(&err);
  spec_review_merge_report_free(&report);
  spec_document_free(&merged);
  spec_document_free(&copy);
  spec_document_free(&base);
}

/* ---- validation phase 8 -------------------------------------------------- */

/* The findings as `path|code|message` lines. Owned. */
static char *findings(const SpecModel *model, const SpecDocument *d) {
  SpecValidationErrors errs;
  validate_document(model, d, &errs);
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < errs.len; i++) {
    som_buf_puts(&b, errs.items[i].path);
    som_buf_putc(&b, '|');
    som_buf_puts(&b, errs.items[i].code);
    som_buf_putc(&b, '|');
    som_buf_puts(&b, errs.items[i].message);
    som_buf_putc(&b, '\n');
  }
  spec_validation_errors_free(&errs);
  return som_buf_take(&b);
}

static void expect_findings(const char *name, const SpecModel *model,
                            const SpecDocument *d, const char *want) {
  char *got = findings(model, d);
  check(name, str_eq(got, want), got);
  free(got);
}

static void test_validation(const SpecModel *model) {
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_units(&d, "DEMO/TTL", "u_a");
    spec_document_set_units(&d, "DEMO/REG", "u_a,u_b");
    expect_findings("phase8.clean", model, &d, "");
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_units(&d, "DEMO/TTL", "u_x, u_a ,u_y");
    expect_findings(
        "phase8.unknownUnit", model, &d,
        "DEMO/TTL|unknownUnit|units names \"u_x\", which no generation unit "
        "declares\n"
        "DEMO/TTL|unknownUnit|units names \"u_y\", which no generation unit "
        "declares\n");
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_units(&d, "DEMO/META", "u_a");
    spec_document_set_units(&d, "DEMO/META/tags", "u_a");
    spec_document_set_units(&d, "DEMO/control", "u_a");
    spec_document_set_units(&d, "DEMO/DLV-LST-1", "u_a");
    /* Routed: a field of a routed class, a list of a routed element. */
    spec_document_set_units(&d, "DEMO/PRI", "u_a");
    spec_document_set_units(&d, "DEMO/CARD-LST", "u_a");
#define UNROUTED "|unitsUnrouted|units is set on a section that routes " \
                 "nothing to CodeSpecs\n"
    expect_findings("phase8.unitsUnrouted", model, &d,
                    "DEMO/DLV-LST-1" UNROUTED "DEMO/META" UNROUTED
                    "DEMO/META/tags" UNROUTED "DEMO/control" UNROUTED);
#undef UNROUTED
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    make_register(&d);
    char *dup = spec_document_add_list_item(&d, "DEMO/DLV-LST");
    set_form(&d, dup, "unitId", "u_a");
    set_form(&d, dup, "kind", "server");
    free(dup);
    /* An item with no value at all is absence, not a finding. */
    free(spec_document_add_list_item(&d, "DEMO/DLV-LST"));
    const char *areas[] = {"CE-DB", "ce-db", "CE-", "CE-D1"};
    for (size_t i = 0; i < 4; i++) {
      char *route = spec_document_add_list_item(&d, "DEMO/DLV-LST-1/DLR-LST");
      set_form(&d, route, "area", areas[i]);
      set_form(&d, route, "mapping", "dart-tom");
      free(route);
    }
#define MALFORMED(p, a) \
  p "|unitAreaMalformed|mapping area \"" a          \
    "\" is not an area code (CE-\xe2\x80\xa6)\n"
    expect_findings(
        "phase8.register", model, &d,
        MALFORMED("DEMO/DLV-LST-1/DLR-LST-2", "ce-db")
            MALFORMED("DEMO/DLV-LST-1/DLR-LST-3", "CE-")
                MALFORMED("DEMO/DLV-LST-1/DLR-LST-4", "CE-D1")
        "DEMO/DLV-LST-3|duplicateUnitId|generation unit \"u_a\" is declared "
        "twice\n"
        "DEMO/DLV-LST-3|unitBuildsNothing|generation unit \"u_a\" builds "
        "neither a deploymentTarget nor a component\n");
#undef MALFORMED
    spec_document_free(&d);
  }
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_units(&d, "DEMO/TTL", "u_x");
    spec_document_set_content(
        &d, "DEMO/SUM",
        "> \xe2\xac\x86\xef\xb8\x8f **C-1** a\n\n"
        "> \xe2\xac\x86\xef\xb8\x8f **C-1** b");
    SpecValidationErrors errs;
    validate_document(model, &d, &errs);
    check("phase8.order",
          errs.len == 2 && str_eq(errs.items[0].code, "unknownUnit") &&
              str_eq(errs.items[1].code, "duplicateAnnotationId"),
          "");
    spec_validation_errors_free(&errs);
    spec_document_free(&d);
  }
}

/* ---- the register (spec_generation_units) ------------------------------- */

/* The unit ids of `units`, joined by `,`. Owned. */
static char *unit_ids(const SpecGenerationUnitList *units) {
  SomStrList ids;
  som_strlist_init(&ids);
  for (size_t i = 0; i < units->len; i++) {
    som_strlist_push_copy(&ids, units->items[i].unit_id);
  }
  char *joined = som_strlist_join(&ids, ",");
  som_strlist_free(&ids);
  return joined;
}

/* `spec_default_units(units, area)`, joined by `,`. Owned. */
static char *default_units(const SpecGenerationUnitList *units,
                           const char *area) {
  SomStrList ids;
  spec_default_units(units, area, &ids);
  char *joined = som_strlist_join(&ids, ",");
  som_strlist_free(&ids);
  return joined;
}

static void test_register(const SpecModel *model) {
  /* units in register order, each with its own mappings */
  {
    SpecDocument d;
    make_register(&d);
    spec_document_set_form_field(&d, "DEMO/DLV-LST-1/content", "kind",
                                 "client");
    const char *routes[][3] = {
        {"DEMO/DLV-LST-1", "CE-NV", "dart-tom"},
        {"DEMO/DLV-LST-1", "CE-TX", " ts-react "},
        {"DEMO/DLV-LST-2", "CE-NV", "dart-tom"},
    };
    for (size_t i = 0; i < 3; i++) {
      char list[64];
      snprintf(list, sizeof(list), "%s/DLR-LST", routes[i][0]);
      char *r = spec_document_add_list_item(&d, list);
      set_form(&d, r, "area", routes[i][1]);
      set_form(&d, r, "mapping", routes[i][2]);
      free(r);
    }
    SpecGenerationUnitList units;
    spec_generation_units(model, &d, &units);
    char *ids = unit_ids(&units);
    check("register.order", str_eq(ids, "u_a,u_b"), ids);
    free(ids);
    if (units.len == 2) {
      const SpecGenerationUnit *first = &units.items[0];
      const SpecGenerationUnit *last = &units.items[1];
      check("register.kind", str_eq(first->kind, "client"), first->kind);
      check("register.path", str_eq(first->path, "DEMO/DLV-LST-1"),
            first->path);
      check("register.mappings",
            first->mappings_len == 2 &&
                str_eq(first->mappings[0].area, "CE-NV") &&
                str_eq(first->mappings[0].mapping, "dart-tom") &&
                str_eq(first->mappings[1].area, "CE-TX") &&
                str_eq(first->mappings[1].mapping, "ts-react"),
            "");
      check("register.mappingFor",
            str_eq(spec_generation_unit_mapping_for(first, "CE-TX"),
                   "ts-react"),
            "");
      check("register.mappingForAbsent",
            spec_generation_unit_mapping_for(last, "CE-TX") == NULL, "");
    }
    char *nv = default_units(&units, "CE-NV");
    char *tx = default_units(&units, "CE-TX");
    char *db = default_units(&units, "CE-DB");
    check("register.default.nv", str_eq(nv, "u_a,u_b"), nv);
    check("register.default.tx", str_eq(tx, "u_a"), tx);
    check("register.default.none", str_eq(db, ""), db);
    free(nv);
    free(tx);
    free(db);
    spec_generation_unit_list_free(&units);
    spec_document_free(&d);
  }
  /* a unit without an id, and a second unit of one id, are left out */
  {
    SpecDocument d;
    make_register(&d);
    free(spec_document_add_list_item(&d, "DEMO/DLV-LST"));
    char *dup = spec_document_add_list_item(&d, "DEMO/DLV-LST");
    set_form(&d, dup, "unitId", "u_a");
    free(dup);
    SpecGenerationUnitList units;
    spec_generation_units(model, &d, &units);
    char *ids = unit_ids(&units);
    check("register.skipped", str_eq(ids, "u_a,u_b"), ids);
    free(ids);
    spec_generation_unit_list_free(&units);
    spec_document_free(&d);
  }
  /* a document without a register declares none */
  {
    SpecDocument d;
    spec_document_init(&d);
    SpecGenerationUnitList units;
    spec_generation_units(model, &d, &units);
    check("register.none", units.len == 0, "");
    spec_generation_unit_list_free(&units);
    spec_document_free(&d);
  }
}

int main(void) {
  SpecModel *model = corpus_model();
  test_store(model);
  test_facade();
  test_markdown(model);
  test_yaml(model);
  test_apply(model);
  test_assembly();
  test_review_merge(model);
  test_validation(model);
  test_register(model);
  spec_model_free(model);
  if (g_failures == 0) {
    printf("spec_units: all %d checks passed\n", g_checks);
  } else {
    printf("spec_units: %d/%d checks failed\n", g_failures, g_checks);
  }
  return g_failures;
}
