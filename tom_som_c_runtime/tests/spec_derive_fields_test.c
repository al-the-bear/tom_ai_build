/* spec_derive_fields (`tom_specs_model_rules.md` §9.7): the derived places of
 * one document, written plain or as marks.
 *
 * The shared corpus (`derive_cases.json`) pins the canonical JSON of each run;
 * this test holds the C surface it does not: the typed changes (step, kind,
 * field and values), the dry run answering a copy and leaving the given
 * document alone, the unresolved entries with their code, and the canonical
 * JSON of a change without a field. Mirrors the Rust runtime's
 * tests/spec_derive_fields.rs. Exit status is the number of failed checks. */
#include "set_test_support.h"

static void derive_doc(const SomJson *t, const char *prefix, SpecDocument *doc) {
  state_document(som_json_get(case_named(t, "cases", prefix), "state"), doc);
}

static void test_plain_steps(const SomJson *t, const SpecModel *model) {
  SpecDocument doc;
  derive_doc(t, "step 1: a missing symmetric row", &doc);
  SpecDeriveOptions plain;
  memset(&plain, 0, sizeof(plain));
  SpecDeriveResult r;
  spec_derive_fields(model, &doc, &plain, &r);
  check("plain.inPlace", r.document == NULL, NULL);
  check("plain.first", r.changes_len > 0 && r.changes[0].step == 1 &&
                           r.changes[0].kind == SPEC_DERIVE_CHANGE_ROW_ADDED &&
                           r.changes[0].field[0] == '\0',
        NULL);
  int step1 = 0, step2 = 0, other = 0;
  for (size_t i = 0; i < r.changes_len; i++) {
    if (r.changes[i].step == 1) {
      step1 = 1;
    } else if (r.changes[i].step == 2) {
      step2 = 1;
    } else {
      other = 1;
    }
  }
  check("plain.steps", step1 && step2 && !other, NULL);
  const SpecDeriveChange *last = r.changes_len > 0 ? &r.changes[r.changes_len - 1] : NULL;
  check("plain.last", last != NULL && last->kind == SPEC_DERIVE_CHANGE_VALUE &&
                          strcmp(last->field, "conflictsWith") == 0 &&
                          last->old_value[0] == '\0' &&
                          strcmp(last->new_value, "REQ-EXPORT") == 0,
        last != NULL ? last->new_value : NULL);
  check("plain.unresolved", r.unresolved.len == 0, NULL);
  SpecValidationErrors after;
  spec_validate_links(model, &doc, &after);
  check("plain.clean", after.len == 0, NULL);
  spec_validation_errors_free(&after);
  spec_derive_result_free(&r);
  spec_derive_fields(model, &doc, &plain, &r);
  check("plain.idempotent", r.changes_len == 0, NULL);
  spec_derive_result_free(&r);
  spec_document_free(&doc);
}

static void test_dry_run(const SomJson *t, const SpecModel *model) {
  SpecDocument doc;
  derive_doc(t, "a dry run writes nothing", &doc);
  char *before = spec_document_stores_json(&doc);
  SpecDeriveOptions options;
  memset(&options, 0, sizeof(options));
  options.dry_run = 1;
  SpecDeriveResult r;
  spec_derive_fields(model, &doc, &options, &r);
  check("dryRun.copy", r.document != NULL, NULL);
  char *now = spec_document_stores_json(&doc);
  check("dryRun.given unchanged", strcmp(now, before) == 0, NULL);
  free(now);
  check("dryRun.changes", r.changes_len > 0, NULL);
  char *copy = r.document != NULL ? spec_document_stores_json(r.document) : som_strdup("");
  check("dryRun.copy differs", strcmp(copy, before) != 0, NULL);
  char *written = spec_document_stores_json(spec_derive_result_written(&r, &doc));
  check("dryRun.written", strcmp(written, copy) == 0, NULL);
  free(written);
  free(copy);
  free(before);
  spec_derive_result_free(&r);
  spec_document_free(&doc);
}

static void test_marked(const SomJson *t, const SpecModel *model) {
  SpecDocument doc;
  derive_doc(t, "under review: every derived value", &doc);
  const char *at = "2026-11-24T10:00+01:00";
  SpecDeriveOptions options;
  memset(&options, 0, sizeof(options));
  options.marked = 1;
  options.author = "agent_spec_author";
  options.at = at;
  SpecDeriveResult r;
  spec_derive_fields(model, &doc, &options, &r);
  size_t values = 0;
  for (size_t i = 0; i < r.changes_len; i++) {
    const SpecDeriveChange *c = &r.changes[i];
    if (c->kind != SPEC_DERIVE_CHANGE_VALUE) continue;
    values++;
    check("marked.value", strchr(c->new_value, '{') != NULL &&
                              strstr(c->new_value, "@agent_spec_author 2026-11-24T10:00+01:00") != NULL,
          c->new_value);
  }
  check("marked.values", values > 0, NULL);
  spec_derive_result_free(&r);
  spec_derive_fields(model, &doc, &options, &r);
  check("marked.idempotent", r.changes_len == 0, NULL);
  spec_derive_result_free(&r);
  spec_document_free(&doc);
}

static void test_unresolved(const SomJson *t, const SpecModel *model) {
  SpecDocument doc;
  derive_doc(t, "a lookup without its row", &doc);
  SpecDeriveOptions plain;
  memset(&plain, 0, sizeof(plain));
  SpecDeriveResult r;
  spec_derive_fields(model, &doc, &plain, &r);
  int miss = 0;
  for (size_t i = 0; i < r.unresolved.len; i++) {
    miss = miss || strcmp(r.unresolved.items[i].code,
                          SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS) == 0;
  }
  check("unresolved.lookupMiss", miss, NULL);
  spec_derive_result_free(&r);
  spec_document_free(&doc);

  derive_doc(t, "under review: a change inside fenced code", &doc);
  SpecDeriveOptions options;
  memset(&options, 0, sizeof(options));
  options.marked = 1;
  options.at = "2026-11-24T10:00+01:00";
  spec_derive_fields(model, &doc, &options, &r);
  check("unresolved.unmarkable",
        r.unresolved.len == 1 &&
            strcmp(r.unresolved.items[0].code, SPEC_VALIDATION_CODE_UNMARKABLE) == 0,
        NULL);
  char *json = spec_derive_result_to_json(&r, &doc);
  check("unresolved.json", strstr(json, "\"code\":\"unmarkable\"") != NULL, json);
  free(json);
  spec_derive_result_free(&r);
  spec_document_free(&doc);
}

static void test_change_json(void) {
  SpecDeriveChange row;
  row.step = 1;
  row.kind = SPEC_DERIVE_CHANGE_ROW_REMOVED;
  row.path = (char *)"A/b-1";
  row.field = (char *)"";
  row.old_value = (char *)"";
  row.new_value = (char *)"";
  char *json = spec_derive_change_to_json(&row);
  check("changeJson.row",
        json_texts_eq(json, "{\"step\":1,\"kind\":\"rowRemoved\",\"path\":\"A/b-1\","
                            "\"old\":\"\",\"new\":\"\"}"),
        json);
  free(json);
  SpecDeriveChange value;
  value.step = 3;
  value.kind = SPEC_DERIVE_CHANGE_VALUE;
  value.path = (char *)"A/c";
  value.field = (char *)"n";
  value.old_value = (char *)"1";
  value.new_value = (char *)"2";
  json = spec_derive_change_to_json(&value);
  check("changeJson.value",
        json_texts_eq(json, "{\"step\":3,\"kind\":\"value\",\"path\":\"A/c\","
                            "\"field\":\"n\",\"old\":\"1\",\"new\":\"2\"}"),
        json);
  free(json);
  check("changeJson.kinds",
        strcmp(spec_derive_change_kind_name(SPEC_DERIVE_CHANGE_ROW_ADDED), "rowAdded") == 0,
        NULL);
}

int main(void) {
  SomJson *t = table("derive_cases.json");
  SpecModel *model = table_model(t);
  test_plain_steps(t, model);
  test_dry_run(t, model);
  test_marked(t, model);
  test_unresolved(t, model);
  test_change_json();
  spec_model_free(model);
  som_json_free(t);
  return report_done("spec_derive_fields_test");
}
