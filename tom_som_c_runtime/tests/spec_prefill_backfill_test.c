/* spec_prefill and spec_backfill: the Blueprint into a new Phase 3 document
 * (BP-8), and the accepted Phase 3 end state back into the Blueprint
 * (DP-part-operations-2).
 *
 * The shared corpus (`prefill_cases.json`, `backfill_cases.json`) pins the
 * canonical JSON of each run; this test holds the C surface it does not: the
 * created document joining the set under its default name, the typed results
 * (filled / skipped pairs, derived, findings; changes, left), the refusals as
 * errors with their codes and places, the revision entry's version bump and
 * default author, and the dry run leaving the set's Blueprint alone. Mirrors
 * the Rust runtime's tests/spec_prefill_backfill.rs. Exit status is the
 * number of failed checks. */
#include "set_test_support.h"

static void test_prefill(void) {
  SomJson *t = table("prefill_cases.json");
  SpecModel *model = table_model(t);
  SpecDocumentSet s;
  case_set(model, case_named(t, "cases", "a new Screens document"), &s);
  SomStrList missing;
  spec_document_set_missing_roots(&s, &missing);
  static const char *const want_missing[1] = {"Screens"};
  check("prefill.missingRoots", strlist_is(&missing, want_missing, 1), NULL);
  som_strlist_free(&missing);
  SpecPrefillOptions defaults;
  memset(&defaults, 0, sizeof(defaults));
  SpecPrefillResult r;
  SpecPrefillError err;
  spec_prefill_error_init(&err);
  check("prefill.ok", spec_prefill(&s, "SCR", &defaults, &r, &err), err.message);
  check("prefill.name", strcmp(r.name, "Screens") == 0, r.name);
  check("prefill.created", r.created, NULL);
  check("prefill.joined", same_doc(spec_document_set_get(&s, "Screens"), &r.document), NULL);
  static const char *const want_filled[1] = {"ACC"};
  check("prefill.filled", strlist_is(&r.filled_pairs, want_filled, 1), NULL);
  check("prefill.skipped", r.skipped_pairs.len == 0, NULL);
  spec_document_set_missing_roots(&s, &missing);
  check("prefill.noneMissing", missing.len == 0, NULL);
  som_strlist_free(&missing);
  spec_prefill_result_free(&r);
  check("prefill.again", spec_prefill(&s, "Screens", &defaults, &r, &err), NULL);
  check("prefill.again.created", !r.created, NULL);
  check("prefill.again.filled", r.filled_pairs.len == 0, NULL);
  check("prefill.again.skipped", strlist_is(&r.skipped_pairs, want_filled, 1), NULL);
  check("prefill.again.derived", r.derived.changes_len == 0, NULL);
  spec_prefill_result_free(&r);
  spec_document_set_free(&s);

  case_set(model, case_named(t, "cases", "a new Detail document"), &s);
  SpecPrefillOptions named;
  memset(&named, 0, sizeof(named));
  named.name = "detail.tomspecs.yaml";
  check("prefill.named", spec_prefill(&s, "Detail", &named, &r, &err), err.message);
  SomStrList names;
  spec_document_set_names(&s, &names);
  static const char *const want_names[3] = {"blueprint", "detail.tomspecs.yaml", "screens"};
  check("prefill.named.names", strlist_is(&names, want_names, 3), NULL);
  som_strlist_free(&names);
  check("prefill.named.derived", r.derived.changes_len > 0, NULL);
  SpecSyncReport report;
  spec_sync_report(&s, NULL, &report);
  size_t counts[SPEC_SYNC_CODE_COUNT];
  spec_sync_report_counts_by_code(&report, counts);
  int agrees = 1;
  for (int i = 0; i < SPEC_SYNC_CODE_COUNT; i++) {
    if (counts[i] > 0 && strncmp(spec_sync_code_name((SpecSyncCode)i), "shared", 6) == 0) {
      agrees = 0;
    }
  }
  check("prefill.named.agrees", agrees, NULL);
  spec_sync_report_free(&report);
  spec_prefill_result_free(&r);
  spec_document_set_free(&s);

  case_set(model, case_named(t, "cases", "a set without the Blueprint"), &s);
  check("prefill.noBlueprint", !spec_prefill(&s, "DET", &defaults, &r, &err) &&
                                   err.code == SPEC_PREFILL_ERROR_NO_BLUEPRINT,
        NULL);
  spec_prefill_result_free(&r);
  spec_document_set_free(&s);
  case_set(model, case_named(t, "cases", "the Blueprint's own root"), &s);
  check("prefill.ownRoot", !spec_prefill(&s, "BLU", &defaults, &r, &err) &&
                               err.code == SPEC_PREFILL_ERROR_UNKNOWN_ROOT,
        NULL);
  char *shown = spec_prefill_error_display(&err);
  check("prefill.ownRoot.display", strncmp(shown, "SpecPrefillError(unknownRoot): ", 31) == 0,
        shown);
  free(shown);
  spec_prefill_result_free(&r);
  check("prefill.unknown", !spec_prefill(&s, "Nope", &defaults, &r, &err) &&
                               err.code == SPEC_PREFILL_ERROR_UNKNOWN_ROOT,
        NULL);
  spec_prefill_result_free(&r);
  spec_document_set_free(&s);
  spec_prefill_error_free(&err);
  spec_model_free(model);
  som_json_free(t);
}

static void test_backfill(void) {
  SomJson *pt = table("prefill_cases.json");
  SpecModel *model = table_model(pt);
  SomJson *t = table("backfill_cases.json");
  SpecDocumentSet s;
  case_set(model, case_named(t, "cases", "a differing enum value"), &s);
  SpecBackfillOptions options;
  memset(&options, 0, sizeof(options));
  options.author = "agent_spec_author";
  options.date = "2026-11-24";
  SpecBackfillResult r;
  SpecBackfillError err;
  spec_backfill_error_init(&err);
  check("backfill.ok", spec_backfill(&s, &options, &r, &err), err.message);
  check("backfill.blueprint", same_doc(spec_document_set_blueprint(&s), &r.blueprint), NULL);
  check("backfill.kinds", r.changes_len == 2 &&
                              r.changes[0].kind == SPEC_BACKFILL_CHANGE_VALUE &&
                              r.changes[1].kind == SPEC_BACKFILL_CHANGE_REVISION,
        NULL);
  if (r.changes_len == 2) {
    check("backfill.value", strcmp(r.changes[0].pair, "REQS") == 0 &&
                                strcmp(r.changes[0].old_value, "approved") == 0 &&
                                strcmp(r.changes[0].new_value, "done") == 0,
          NULL);
    check("backfill.version", strcmp(r.changes[1].new_value, "1.1") == 0,
          r.changes[1].new_value);
    char form[256];
    snprintf(form, sizeof(form), "%s/content", r.changes[1].path);
    const SpecDocument *bp = spec_document_set_blueprint(&s);
    const char *author = spec_document_form_field(bp, form, "author");
    const char *summary = spec_document_form_field(bp, form, "summary");
    check("backfill.author", author != NULL && strcmp(author, "agent_spec_author") == 0,
          author);
    check("backfill.summary",
          summary != NULL && strcmp(summary, "Backfilled from detail, screens: REQS") == 0,
          summary);
  }
  SpecSyncReport report;
  spec_sync_report(&s, NULL, &report);
  check("backfill.cleanAfter", spec_sync_report_clean(&report), NULL);
  spec_sync_report_free(&report);
  spec_backfill_result_free(&r);
  SpecBackfillOptions defaults;
  memset(&defaults, 0, sizeof(defaults));
  check("backfill.again", spec_backfill(&s, &defaults, &r, &err) && r.changes_len == 0, NULL);
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);

  /* The default author; the default date is today's. */
  case_set(model, case_named(t, "cases", "a value the Blueprint leaves empty"), &s);
  check("backfill.defaults", spec_backfill(&s, &defaults, &r, &err), NULL);
  const SpecBackfillChange *rev = NULL;
  for (size_t i = 0; i < r.changes_len; i++) {
    if (r.changes[i].kind == SPEC_BACKFILL_CHANGE_REVISION) rev = &r.changes[i];
  }
  check("backfill.defaults.revision", rev != NULL, NULL);
  if (rev != NULL) {
    char form[256];
    snprintf(form, sizeof(form), "%s/content", rev->path);
    const SpecDocument *bp = spec_document_set_blueprint(&s);
    const char *author = spec_document_form_field(bp, form, "author");
    const char *date = spec_document_form_field(bp, form, "date");
    check("backfill.defaults.author", author != NULL && strcmp(author, "backfill") == 0,
          author);
    check("backfill.defaults.date",
          date != NULL && strlen(date) == 10 && date[4] == '-' && date[7] == '-', date);
  }
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);

  case_set(model, case_named(t, "cases", "a dry run writes a copy"), &s);
  char *before = spec_document_stores_json(spec_document_set_blueprint(&s));
  SpecBackfillOptions dry;
  memset(&dry, 0, sizeof(dry));
  dry.dry_run = 1;
  check("backfill.dryRun", spec_backfill(&s, &dry, &r, &err), NULL);
  char *now = spec_document_stores_json(spec_document_set_blueprint(&s));
  char *copy = spec_document_stores_json(&r.blueprint);
  check("backfill.dryRun.unchanged", strcmp(now, before) == 0, NULL);
  check("backfill.dryRun.copy", strcmp(copy, before) != 0, NULL);
  check("backfill.dryRun.changes", r.changes_len > 0, NULL);
  free(now);
  free(copy);
  free(before);
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);

  case_set(model, case_named(t, "cases", "a heldHere value"), &s);
  check("backfill.held", spec_backfill(&s, &defaults, &r, &err), NULL);
  check("backfill.held.changes", r.changes_len == 0, NULL);
  check("backfill.held.left", r.left_len == 1 &&
                                  r.left[0].reason.kind == SPEC_BACKFILL_LEFT_HELD_HERE &&
                                  r.left[0].finding.code ==
                                      SPEC_SYNC_CODE_SHARED_VALUE_DIFFERS,
        NULL);
  if (r.left_len == 1) {
    check("backfill.held.reason",
          strcmp(spec_backfill_left_reason_name(r.left[0].reason), "heldHere") == 0, NULL);
  }
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);

  case_set(model, case_named(t, "cases", "a set holding an inline mark"), &s);
  check("backfill.marks", !spec_backfill(&s, &defaults, &r, &err) &&
                              err.code == SPEC_BACKFILL_ERROR_SET_HAS_MARKS,
        NULL);
  check("backfill.marks.places", err.places_len > 0 && err.places[0].document != NULL, NULL);
  char *shown = spec_backfill_error_display(&err);
  check("backfill.marks.display", strncmp(shown, "SpecBackfillError(setHasMarks): ", 32) == 0,
        shown);
  free(shown);
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);
  SpecDocumentSetError serr;
  spec_document_set_error_init(&serr);
  spec_document_set_new(model, NULL, 0, &s, &serr);
  check("backfill.noBlueprint", !spec_backfill(&s, &defaults, &r, &err) &&
                                    err.code == SPEC_BACKFILL_ERROR_NO_BLUEPRINT,
        NULL);
  spec_backfill_result_free(&r);
  spec_document_set_free(&s);
  spec_document_set_error_free(&serr);
  spec_backfill_error_free(&err);
  spec_model_free(model);
  som_json_free(t);
  som_json_free(pt);
}

static void test_bump_and_json(void) {
  static const char *const cases[4][2] = {
      {"", "1"}, {"1.2", "1.3"}, {"v1.9-rc", "v1.10-rc"}, {"draft", "draft.1"}};
  for (int i = 0; i < 4; i++) {
    char *got = spec_backfill_bump(cases[i][0]);
    check("bump", strcmp(got, cases[i][1]) == 0, got);
    free(got);
  }
  SpecBackfillChange change;
  change.pair = (char *)"";
  change.kind = SPEC_BACKFILL_CHANGE_REVISION;
  change.path = (char *)"B/R-1";
  change.field = (char *)"";
  change.old_value = (char *)"";
  change.new_value = (char *)"2";
  char *json = spec_backfill_change_to_json(&change);
  check("changeJson",
        json_texts_eq(json, "{\"pair\":\"\",\"kind\":\"revision\",\"path\":\"B/R-1\","
                            "\"old\":\"\",\"new\":\"2\"}"),
        json);
  free(json);
}

int main(void) {
  test_prefill();
  test_backfill();
  test_bump_and_json();
  return report_done("spec_prefill_backfill_test");
}
