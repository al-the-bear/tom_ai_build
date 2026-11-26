/* The document set (spec_document_set, `tom_specs_model_rules.md` §9.7):
 * SpecDocumentSet, spec_sync_report and spec_rename_id.
 *
 * The shared corpus (`document_set_cases.json`) pins the canonical JSON of the
 * construction, the report and the rename; this test holds the C surface it
 * does not: the accessors of the set (by type name and by section id, get,
 * put replacing a document), the typed report (counts by code and by
 * resolution, is_info), the refusals as errors with their fields, a refused
 * rename changing nothing, the comparison helpers, and loading YAML and SOM
 * Markdown files. Mirrors the Rust runtime's tests/spec_document_set.rs.
 * Exit status is the number of failed checks. */
#if !defined(_WIN32) && !defined(_POSIX_C_SOURCE)
#define _POSIX_C_SOURCE 200809L
#endif
#include <sys/stat.h>

#include "set_test_support.h"

static void test_accessors(void) {
  SomJson *t = table("document_set_cases.json");
  SpecModel *model = table_model(t);
  CaseDocs docs;
  case_docs(case_named(t, "construction", "the base set"), &docs);
  SpecDocumentSet s;
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  check("accessors.new", spec_document_set_new(model, docs.named, docs.len, &s, &err),
        err.message);
  check("accessors.blueprintRoot", strcmp(s.blueprint_root, "Blueprint") == 0,
        s.blueprint_root);
  check("accessors.blueprint", same_doc(spec_document_set_blueprint(&s), &docs.docs[0]),
        NULL);
  check("accessors.document(type)",
        same_doc(spec_document_set_document(&s, "Detail"), &docs.docs[1]), NULL);
  check("accessors.document(sid)",
        same_doc(spec_document_set_document(&s, "DET"), &docs.docs[1]), NULL);
  const char *n = spec_document_set_name_of(&s, "SCR");
  check("accessors.nameOf", n != NULL && strcmp(n, "screens") == 0, n);
  check("accessors.nameOf(unknown)", spec_document_set_name_of(&s, "Nope") == NULL, NULL);
  check("accessors.get", same_doc(spec_document_set_get(&s, "detail"), &docs.docs[1]),
        NULL);
  check("accessors.get(unknown)", spec_document_set_get(&s, "nope") == NULL, NULL);
  check("accessors.rootOf", strcmp(spec_document_set_root_of(&s, "screens"), "Screens") == 0,
        NULL);
  check("accessors.pairs", s.pairs_len == 3 && strcmp(s.pairs[0].section_id, "REQS") == 0 &&
                               strcmp(s.pairs[1].section_id, "ACC") == 0 &&
                               strcmp(s.pairs[2].section_id, "CRIT") == 0,
        NULL);
  check("accessors.anchors",
        strcmp(s.pairs[0].blueprint_anchor, "BLU/requirements") == 0 &&
            strcmp(s.pairs[0].detail_anchor, "DET/requirements") == 0,
        s.pairs[0].blueprint_anchor);
  check("accessors.sync", s.pairs[0].has_sync, NULL);
  /* `put` replaces the document of the same name. */
  SpecDocument other;
  spec_document_copy(&other, &docs.docs[1]);
  spec_document_set_content(&other, "DET/requirements/REQ-ITEM-LST-1/REQAB", "Changed.");
  check("accessors.put", spec_document_set_put(&s, "detail", &other, &err), err.message);
  check("accessors.put.replaced", same_doc(spec_document_set_get(&s, "detail"), &other),
        NULL);
  SomStrList names;
  spec_document_set_names(&s, &names);
  static const char *const want_names[3] = {"blueprint", "detail", "screens"};
  check("accessors.names", strlist_is(&names, want_names, 3), NULL);
  som_strlist_free(&names);
  spec_document_free(&other);
  spec_document_set_free(&s);
  /* An empty set knows its pairs and every Phase 3 root as missing. */
  SpecDocumentSet empty;
  check("accessors.empty", spec_document_set_new(model, NULL, 0, &empty, &err), NULL);
  spec_document_set_names(&empty, &names);
  check("accessors.empty.names", names.len == 0, NULL);
  som_strlist_free(&names);
  SomStrList missing;
  spec_document_set_missing_roots(&empty, &missing);
  static const char *const want_missing[2] = {"Detail", "Screens"};
  check("accessors.empty.missingRoots", strlist_is(&missing, want_missing, 2), NULL);
  som_strlist_free(&missing);
  check("accessors.empty.pairs", empty.pairs_len == 3, NULL);
  spec_document_set_free(&empty);
  spec_document_set_error_free(&err);
  case_docs_free(&docs);
  spec_model_free(model);
  som_json_free(t);
}

static void test_refusals(void) {
  SomJson *t = table("document_set_cases.json");
  SpecModel *model = table_model(t);
  const SomJson *same = case_named(t, "construction", "two documents of one root");
  CaseDocs docs;
  case_docs(same, &docs);
  SpecDocumentSet s;
  SpecDocumentSetError err;
  spec_document_set_error_init(&err);
  check("refusals.sameRoot", !spec_document_set_new(model, docs.named, docs.len, &s, &err),
        NULL);
  check("refusals.sameRoot.refusal", err.refusal == SPEC_DOCUMENT_SET_REFUSAL_SAME_ROOT,
        NULL);
  char *json = spec_document_set_error_to_json(&err);
  check("refusals.sameRoot.json",
        json_text_eq(json, som_json_get(som_json_get(same, "expect"), "refused")), json);
  free(json);
  char *shown = spec_document_set_error_display(&err);
  check("refusals.sameRoot.display",
        strncmp(shown, "SpecDocumentSetError(sameRoot): ", 32) == 0, shown);
  free(shown);
  check("refusals.empty set left", s.entries_len == 0 && s.pairs_len == 0, NULL);
  spec_document_set_free(&s);
  case_docs_free(&docs);

  const SomJson *unp = case_named(t, "construction", "a synced class whose positions");
  SpecModel *meta = spec_model_from_json(som_json_get(unp, "meta"));
  case_docs(unp, &docs);
  check("refusals.unpairable", !spec_document_set_new(meta, docs.named, docs.len, &s, &err),
        NULL);
  check("refusals.unpairable.refusal",
        err.refusal == SPEC_DOCUMENT_SET_REFUSAL_UNPAIRABLE, NULL);
  check("refusals.unpairable.className", err.class_name != NULL && err.class_name[0] != '\0',
        NULL);
  spec_document_set_free(&s);
  case_docs_free(&docs);
  spec_model_free(meta);

  /* `put` refuses an empty document. */
  spec_document_set_new(model, NULL, 0, &s, &err);
  SpecDocument blank;
  spec_document_init(&blank);
  check("refusals.noRoot", !spec_document_set_put(&s, "x", &blank, &err), NULL);
  check("refusals.noRoot.refusal", err.refusal == SPEC_DOCUMENT_SET_REFUSAL_NO_ROOT, NULL);
  spec_document_free(&blank);
  spec_document_set_free(&s);
  spec_document_set_error_free(&err);
  spec_model_free(model);
  som_json_free(t);
}

static void test_sync_report_typed(void) {
  SomJson *t = table("document_set_cases.json");
  SpecModel *model = table_model(t);
  const SomJson *c = case_named(t, "reports", "an enum value differs");
  SpecDocumentSet s;
  case_set(model, c, &s);
  SpecSyncReport r;
  spec_sync_report(&s, NULL, &r);
  check("report.clean", !spec_sync_report_clean(&r), NULL);
  size_t by_code[SPEC_SYNC_CODE_COUNT];
  spec_sync_report_counts_by_code(&r, by_code);
  check("report.countsByCode", by_code[SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS] == 1 &&
                                   r.findings_len == 1,
        NULL);
  size_t by_res[SPEC_SYNC_RESOLUTION_COUNT];
  spec_sync_report_counts_by_resolution(&r, by_res);
  check("report.countsByResolution", by_res[SPEC_SYNC_RESOLUTION_BACKFILL] == 1, NULL);
  const SpecSyncFinding *f = &r.findings[0];
  check("report.pair", strcmp(f->pair, "REQS") == 0, f->pair);
  check("report.holder", f->holder == SPEC_SYNC_HOLDER_DETAIL, NULL);
  check("report.info", !spec_sync_finding_is_info(f), NULL);
  check("report.values", f->blueprint.value != NULL && f->detail.value != NULL &&
                             strcmp(f->blueprint.value, "approved") == 0 &&
                             strcmp(f->detail.value, "done") == 0,
        NULL);
  check("report.field", strcmp(f->blueprint.field, "status") == 0, f->blueprint.field);
  check("report.documentFindings",
        r.document_findings_len == 3 &&
            strcmp(r.document_findings[0].name, "blueprint") == 0 &&
            strcmp(r.document_findings[1].name, "detail") == 0 &&
            strcmp(r.document_findings[2].name, "screens") == 0,
        NULL);
  char *json = spec_sync_report_to_json(&r);
  check("report.json", json_text_eq(json, som_json_get(c, "expect")), json);
  free(json);
  spec_sync_report_free(&r);
  /* Scoped to another pair, the finding is left out. */
  SomStrList scope;
  som_strlist_init(&scope);
  som_strlist_push_copy(&scope, "ACC");
  spec_sync_report(&s, &scope, &r);
  check("report.scoped", r.findings_len == 0, NULL);
  spec_sync_report_free(&r);
  som_strlist_free(&scope);
  spec_document_set_free(&s);
  case_set(model, case_named(t, "reports", "a value holding a pending change"), &s);
  spec_sync_report(&s, NULL, &r);
  int all_info = r.findings_len > 0;
  for (size_t i = 0; i < r.findings_len; i++) {
    all_info = all_info && spec_sync_finding_is_info(&r.findings[i]);
  }
  check("report.pending.clean", spec_sync_report_clean(&r), NULL);
  check("report.pending.info", all_info, NULL);
  spec_sync_report_free(&r);
  spec_document_set_free(&s);
  spec_model_free(model);
  som_json_free(t);
}

static void test_rename(void) {
  SomJson *t = table("document_set_cases.json");
  SpecModel *model = table_model(t);
  const SomJson *ok = case_named(t, "renames", "an id renamed");
  SpecDocumentSet s;
  case_set(model, ok, &s);
  const char *from = som_json_str_or(ok, "from");
  const char *to = som_json_str_or(ok, "to");
  SpecRenameChanges changes;
  SpecRenameError err;
  spec_rename_error_init(&err);
  check("rename.ok", spec_rename_id(&s, from, to, &changes, &err), err.message);
  check("rename.first", changes.len > 0 && strcmp(changes.items[0].kind, "sectionId") == 0 &&
                            strcmp(changes.items[0].old_value, from) == 0 &&
                            strcmp(changes.items[0].new_value, to) == 0,
        NULL);
  spec_rename_changes_free(&changes);
  check("rename.again", spec_rename_id(&s, from, "REQ-OTHER", &changes, &err), NULL);
  check("rename.again.empty", changes.len == 0, NULL);
  spec_rename_changes_free(&changes);
  spec_document_set_free(&s);

  const SomJson *refused = case_named(t, "renames", "a rename onto an id");
  case_set(model, refused, &s);
  SomStrList names;
  spec_document_set_names(&s, &names);
  SomStrList before;
  som_strlist_init(&before);
  for (size_t i = 0; i < names.len; i++) {
    som_strlist_push(&before, spec_document_stores_json(spec_document_set_get(&s, names.items[i])));
  }
  check("rename.refused",
        !spec_rename_id(&s, som_json_str_or(refused, "from"), som_json_str_or(refused, "to"),
                        &changes, &err),
        NULL);
  const SomJson *want = som_json_get(som_json_get(refused, "expect"), "refused");
  int same = err.documents.len == som_json_array_len(want);
  for (size_t i = 0; same && i < err.documents.len; i++) {
    same = strcmp(err.documents.items[i], som_json_as_str(som_json_array_at(want, i))) == 0;
  }
  check("rename.refused.documents", same, NULL);
  char *shown = spec_rename_error_display(&err);
  check("rename.refused.display", strncmp(shown, "SpecRenameError: ", 17) == 0, shown);
  free(shown);
  int unchanged = 1;
  for (size_t i = 0; i < names.len; i++) {
    char *now = spec_document_stores_json(spec_document_set_get(&s, names.items[i]));
    unchanged = unchanged && strcmp(now, before.items[i]) == 0;
    free(now);
  }
  check("rename.refused.unchanged", unchanged, NULL);
  spec_rename_changes_free(&changes);
  spec_rename_error_free(&err);
  som_strlist_free(&before);
  som_strlist_free(&names);
  spec_document_set_free(&s);
  spec_model_free(model);
  som_json_free(t);
}

static void test_helpers(void) {
  FormFieldSpec dbl;
  memset(&dbl, 0, sizeof(dbl));
  dbl.name = (char *)"n";
  dbl.type = (char *)"double";
  check("helpers.sameTyped(2, 2.0)", spec_set_same_typed("2", "2.0", &dbl), NULL);
  check("helpers.sameTyped(hex)", spec_set_same_typed("0x10", "16", &dbl), NULL);
  check("helpers.sameTyped(NaN)", !spec_set_same_typed("NaN", "NaN", &dbl), NULL);
  check("helpers.sameTyped(text)", !spec_set_same_typed("2", "2.0", NULL), NULL);
  FormFieldSpec boolean = dbl;
  boolean.type = (char *)"bool";
  check("helpers.sameTyped(bool)", spec_set_same_typed("True", "true", &boolean), NULL);
  SomStrList ids;
  spec_link_ids(" A, ,B ,C", &ids);
  static const char *const want_ids[3] = {"A", "B", "C"};
  check("helpers.linkIds", strlist_is(&ids, want_ids, 3), NULL);
  som_strlist_free(&ids);
  char *k = spec_set_strip_kind("f:LIST[X]/content#status");
  check("helpers.stripKind(form)", strcmp(k, "LIST[X]/content") == 0, k);
  free(k);
  k = spec_set_strip_kind("i:LIST[X]");
  check("helpers.stripKind(item)", strcmp(k, "LIST[X]") == 0, k);
  free(k);
  char *r = spec_set_reviewed(" a {++b ++}");
  check("helpers.reviewed", strcmp(r, "a") == 0, r);
  free(r);
  check("helpers.pending", spec_set_is_pending("a {++b++}"), NULL);
  check("helpers.notPending", !spec_set_is_pending("a b"), NULL);
  check("helpers.codeIndex", SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS == 0 &&
                                 SPEC_SYNC_CODE_UNMARKABLE == 9,
        NULL);
  SpecSyncCode code;
  check("helpers.fromName(unknown)", !spec_sync_code_from_name("nope", &code), NULL);
  check("helpers.fromName", spec_sync_code_from_name("pendingReview", &code) &&
                                code == SPEC_SYNC_CODE_PENDING_REVIEW,
        NULL);
  check("helpers.names", strcmp(spec_sync_code_name(SPEC_SYNC_CODE_CROSS_INVERSE_MISSING),
                                "crossInverseMissing") == 0 &&
                             strcmp(spec_sync_resolution_name(SPEC_SYNC_RESOLUTION_DERIVE_FIELDS),
                                    "deriveFields") == 0 &&
                             strcmp(spec_sync_holder_name(SPEC_SYNC_HOLDER_BLUEPRINT),
                                    "blueprint") == 0,
        NULL);
}

static void write_text(const char *path, const char *text) {
  FILE *f = fopen(path, "wb");
  if (f == NULL) {
    fprintf(stderr, "fatal: cannot write %s\n", path);
    exit(2);
  }
  fputs(text, f);
  fclose(f);
}

static void test_load(void) {
  SomJson *t = table("document_set_cases.json");
  SpecModel *model = table_model(t);
  CaseDocs docs;
  case_docs(case_named(t, "construction", "the base set"), &docs);
  const char *dir = "build/spec_document_set_load";
  mkdir("build", 0755);
  mkdir(dir, 0755);
  char paths[3][256];
  const char *files[3];
  for (size_t i = 0; i < docs.len && i < 3; i++) {
    SpecDocumentSet one;
    SpecDocumentSetError err;
    spec_document_set_error_init(&err);
    spec_document_set_new(model, &docs.named[i], 1, &one, &err);
    SomStrList roots;
    spec_document_set_roots(&one, &roots);
    const SpecRoot *root = spec_model_root_by_type(model, roots.items[0], NULL);
    /* The first document as SOM Markdown, the others as YAML. */
    char *text;
    if (i == 0) {
      snprintf(paths[i], sizeof(paths[i]), "%s/%s.tomspecs.md", dir, docs.named[i].name);
      text = spec_markdown_export_root(model, &docs.docs[i], root, NULL);
    } else {
      snprintf(paths[i], sizeof(paths[i]), "%s/%s.tomspecs.yaml", dir, docs.named[i].name);
      SomMetaTree *tree = som_build_meta_tree(model, root->type, NULL);
      text = encode_yaml(&docs.docs[i], tree, "", NULL);
      som_meta_tree_free(tree);
    }
    check("load.write", text != NULL, paths[i]);
    if (text != NULL) write_text(paths[i], text);
    free(text);
    files[i] = paths[i];
    som_strlist_free(&roots);
    spec_document_set_free(&one);
    spec_document_set_error_free(&err);
  }
  SpecDocumentSet s;
  SpecDocumentSetLoadError lerr;
  spec_document_set_load_error_init(&lerr);
  check("load.ok", spec_document_set_load(model, files, 3, &s, &lerr), lerr.message);
  SomStrList names;
  spec_document_set_names(&s, &names);
  static const char *const want_names[3] = {
      "blueprint.tomspecs.md", "detail.tomspecs.yaml", "screens.tomspecs.yaml"};
  check("load.names", strlist_is(&names, want_names, 3), NULL);
  for (size_t i = 1; i < 3 && i < names.len; i++) {
    check("load.yaml round trip",
          same_doc(spec_document_set_get(&s, names.items[i]), &docs.docs[i]), names.items[i]);
  }
  const SpecDocument *bp = spec_document_set_blueprint(&s);
  check("load.blueprint", bp != NULL && !spec_document_is_empty(bp), NULL);
  som_strlist_free(&names);
  spec_document_set_free(&s);
  char missing[256];
  snprintf(missing, sizeof(missing), "%s/nope.yaml", dir);
  const char *missing_files[1] = {missing};
  check("load.missing", !spec_document_set_load(model, missing_files, 1, &s, &lerr) &&
                            lerr.kind == SPEC_DOCUMENT_SET_LOAD_READ,
        NULL);
  spec_document_set_free(&s);
  spec_document_set_load_error_free(&lerr);
  for (int i = 0; i < 3; i++) remove(paths[i]);
  remove(dir);
  case_docs_free(&docs);
  spec_model_free(model);
  som_json_free(t);
}

int main(void) {
  test_accessors();
  test_refusals();
  test_sync_report_typed();
  test_rename();
  test_helpers();
  test_load();
  return report_done("spec_document_set_test");
}
