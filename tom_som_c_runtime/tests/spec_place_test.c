/* The places and filters of the link vocabulary (spec_place,
 * `tom_specs_model_rules.md` §9.7) and the typed link readers of the model
 * they are read from (spec_model_links): the grammar, resolution under an
 * anchor over the corpus's `links.meta.json`, the filter's `|` alternatives,
 * the `@SameAs` holders and the readers' defaults for a key a meta does not
 * carry. Mirrors the Go runtime's spec_place_test.go.
 *
 * The shared corpus (`link_reader_cases.json`) pins the canonical JSON of
 * these; this test holds the C surface around it — the errors, the defaults,
 * the meta order and the section positions. Reads
 * `../tom_som_conformance/corpus/links.meta.json` (run from the package root,
 * as run_tests.sh does). Exit status is the number of failed checks. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

static int g_checks = 0;
static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

/* Checks owned JSON text `got` against `want`; frees it. */
static void check_json(const char *name, char *got, const char *want) {
  check(name, strcmp(got, want) == 0, got);
  free(got);
}

static SpecModel *links_model(void) {
  FILE *f = fopen("../tom_som_conformance/corpus/links.meta.json", "rb");
  if (f == NULL) {
    fprintf(stderr, "fatal: cannot read links.meta.json\n");
    exit(2);
  }
  fseek(f, 0, SEEK_END);
  long n = ftell(f);
  rewind(f);
  char *buf = (char *)malloc((size_t)n + 1);
  size_t got = fread(buf, 1, (size_t)n, f);
  buf[got] = '\0';
  fclose(f);
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(buf, &err);
  free(buf);
  if (m == NULL) {
    fprintf(stderr, "fatal: %s\n", err != NULL ? err : "load links.meta.json");
    exit(2);
  }
  return m;
}

static void test_place_grammar(void) {
  SpecPlace p;
  SpecPlaceError err;
  spec_place_error_init(&err);
  int ok = spec_place_parse("./FRE/REQDEP/RQDEP.description", &p, &err);
  check("place.parse", ok, NULL);
  if (ok) {
    check("place.parts",
          p.scoped && p.prefix.len == 2 && strcmp(p.prefix.items[0], "FRE") == 0 &&
              strcmp(p.prefix.items[1], "REQDEP") == 0 &&
              strcmp(p.section_id, "RQDEP") == 0 && p.slot != NULL &&
              strcmp(p.slot, "description") == 0 &&
              strcmp(p.text, "./FRE/REQDEP/RQDEP.description") == 0,
          NULL);
    spec_place_free(&p);
  }
  if (spec_place_try_parse("FRE.@headline", &p)) {
    check("place.headline", p.slot != NULL && strcmp(p.slot, "@headline") == 0,
          NULL);
    spec_place_free(&p);
  } else {
    check("place.headline", 0, "did not parse");
  }
  if (spec_place_try_parse("FRE-REQU-LST", &p)) {
    check_json("place.bareJson", spec_place_to_json(&p),
               "{\"scoped\":false,\"prefix\":[],\"sectionId\":\"FRE-REQU-LST\"}");
    spec_place_free(&p);
  }
  static const char *const bad[] = {"", "./", "-X", "FRE.", "FRE.a-b",
                                    "FRE/.x", "FRE..x"};
  for (size_t i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
    int parsed = spec_place_try_parse(bad[i], &p);
    check("place.bad", !parsed, bad[i]);
    if (parsed) spec_place_free(&p);
  }
  ok = spec_place_parse("a b", &p, &err);
  check("place.malformed",
        !ok && err.problem != NULL &&
            strcmp(err.problem, SPEC_PLACE_PROBLEM_MALFORMED) == 0 &&
            strcmp(err.text, "a b") == 0,
        NULL);
  if (ok) spec_place_free(&p);
  spec_place_error_free(&err);
}

static void test_filter_grammar(void) {
  SpecPlaceFilter f;
  SpecPlaceError err;
  spec_place_error_init(&err);
  int ok = spec_place_filter_parse("./FRE.priority=must|should", &f, &err);
  check("filter.parse", ok, NULL);
  if (!ok) return;
  check("filter.parts",
        f.scoped && strcmp(f.field, "priority") == 0 && f.values.len == 2 &&
            strcmp(f.values.items[0], "must") == 0 &&
            strcmp(f.values.items[1], "should") == 0,
        NULL);
  const char *stored[2] = {"could", " should "};
  check("filter.matchesTrimmed", spec_place_filter_matches(&f, stored, 2), NULL);
  check("filter.noMatch", !spec_place_filter_matches(&f, stored, 1) &&
                              !spec_place_filter_matches(&f, NULL, 0),
        NULL);
  SpecPlaceFilter every;
  spec_place_filter_try_parse("FRE", &every);
  check("filter.every", spec_place_filter_matches(&every, NULL, 0), NULL);
  SpecPlace a, b;
  spec_place_filter_place(&every, &a);
  spec_place_filter_place(&f, &b);
  check("filter.place", strcmp(a.text, "FRE") == 0 && strcmp(b.text, "./FRE") == 0,
        NULL);
  spec_place_free(&a);
  spec_place_free(&b);
  spec_place_filter_free(&every);
  spec_place_filter_free(&f);
  static const char *const bad[] = {"FRE.priority", "FRE.priority=",
                                    "FRE.priority=a||b", "FRE.9x=a", ".x=a"};
  for (size_t i = 0; i < sizeof(bad) / sizeof(bad[0]); i++) {
    int parsed = spec_place_filter_try_parse(bad[i], &f);
    check("filter.bad", !parsed, bad[i]);
    if (parsed) spec_place_filter_free(&f);
  }
  spec_place_error_free(&err);
}

/* The problem of resolving `place` under `anchor` (NULL when it resolves). */
static const char *problem_of(const SpecReflection *refl, const char *place,
                              const char *anchor) {
  SpecPlace p;
  if (!spec_place_try_parse(place, &p)) return SPEC_PLACE_PROBLEM_MALFORMED;
  SpecPlaceResolution r;
  SpecPlaceError err;
  spec_place_error_init(&err);
  const char *problem = NULL;
  if (spec_place_resolve(&p, refl, anchor, &r, &err)) {
    spec_place_resolution_free(&r);
  } else {
    problem = err.problem != NULL ? err.problem : "(no place problem)";
  }
  spec_place_error_free(&err);
  spec_place_free(&p);
  return problem;
}

static void test_resolution(const SpecModel *model) {
  SpecReflection refl = spec_reflection_make(model);
  const char *item = "BLU/requirements/REQ-ITEM-LST-1";
  SpecPlace p;
  spec_place_try_parse("REQD.description", &p);
  SpecPlaceResolution r;
  SpecPlaceError err;
  spec_place_error_init(&err);
  int ok = spec_place_resolve(&p, &refl, item, &r, &err);
  check("resolve.formField",
        ok && strcmp(r.kind, SPEC_PLACE_KIND_FORM_FIELD) == 0 &&
            r.form_field != NULL &&
            strcmp(spec_place_resolution_field(&r), "description") == 0 &&
            strcmp(r.path, "BLU/requirements/REQ-ITEM-LST-1/REQD") == 0,
        NULL);
  if (ok) spec_place_resolution_free(&r);
  spec_place_free(&p);
  static const char *const cases[][3] = {
      {"REQD", "BLU/nowhere", SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED},
      {"./REQD", "BLU", SPEC_PLACE_PROBLEM_NOT_SCOPED},
      {"NOPE", "BLU", SPEC_PLACE_PROBLEM_UNRESOLVED},
      {"REQD.@nope", "BLU/requirements/REQ-ITEM-LST-1",
       SPEC_PLACE_PROBLEM_RESERVED_SLOT},
      {"REQD.nope", "BLU/requirements/REQ-ITEM-LST-1",
       SPEC_PLACE_PROBLEM_NO_SUCH_FIELD},
  };
  for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
    const char *got = problem_of(&refl, cases[i][0], cases[i][1]);
    check("resolve.problem", got != NULL && strcmp(got, cases[i][2]) == 0,
          cases[i][0]);
  }
  /* The filter reports with its own text. */
  SpecPlaceFilter f;
  spec_place_filter_try_parse("NOPE.x=1", &f);
  ok = spec_place_filter_resolve(&f, &refl, "BLU", &r, &err);
  check("resolve.filterText",
        !ok && err.text != NULL && strcmp(err.text, "NOPE.x=1") == 0 &&
            strcmp(err.problem, SPEC_PLACE_PROBLEM_UNRESOLVED) == 0,
        NULL);
  if (ok) spec_place_resolution_free(&r);
  spec_place_filter_free(&f);
  spec_place_error_free(&err);
}

static void test_positions_and_same_as(const SpecModel *model) {
  SpecReflection refl = spec_reflection_make(model);
  SpecSectionPositionList positions;
  spec_section_positions(&refl, "Blueprint", &positions);
  check("positions.root",
        positions.len > 0 && strcmp(positions.items[0].path, "BLU") == 0 &&
            !positions.items[0].is_member && positions.items[0].member == NULL,
        NULL);
  int items = 0;
  for (size_t i = 0; i < positions.len; i++) {
    if (strstr(positions.items[i].path, "-*") != NULL) items = 1;
  }
  check("positions.items", items, NULL);
  spec_section_position_list_free(&positions);
  spec_section_positions(&refl, "Nope", &positions);
  check("positions.unknownRoot", positions.len == 0, NULL);
  spec_section_position_list_free(&positions);
  SpecSameAsBindingList bindings;
  spec_same_as_bindings(&refl, "Blueprint", &bindings);
  check("sameAs.holder", bindings.len == 1 && bindings.items[0].holder_path != NULL,
        NULL);
  spec_same_as_binding_list_free(&bindings);
  spec_same_as_bindings(&refl, "Nope", &bindings);
  check("sameAs.unknownRoot", bindings.len == 0, NULL);
  spec_same_as_binding_list_free(&bindings);
}

/* Parses `json` (an argument object) and keeps the tree for the caller. */
static SomJson *args(const char *json) {
  char *err = NULL;
  SomJson *v = som_json_parse(json, &err);
  if (v == NULL) {
    fprintf(stderr, "fatal: %s\n", err != NULL ? err : "bad JSON");
    exit(2);
  }
  return v;
}

static void test_reader_defaults(void) {
  /* An absent key takes the annotation's default; an enum constant loses its
   * type prefix. */
  SomJson *a = args("{\"source\":\"X\",\"kind\":\"DerivationKind.rows\"}");
  SpecDerivation d;
  spec_derivation_from_arguments(a, &d);
  check("defaults.kindPrefix", strcmp(d.kind, "rows") == 0, d.kind);
  check_json("defaults.derivationJson", spec_derivation_to_json(&d),
             "{\"kind\":\"rows\",\"source\":\"X\",\"take\":[],\"map\":{}}");
  spec_derivation_free(&d);
  som_json_free(a);
  spec_derivation_from_arguments(NULL, &d);
  check("defaults.kindCopy", strcmp(d.kind, "copy") == 0, NULL);
  spec_derivation_free(&d);
  a = args("{\"detail\":\"D-LST\"}");
  SpecSummaryOf s;
  spec_summary_of_from_arguments(a, &s);
  check_json("defaults.summaryJson", spec_summary_of_to_json(&s),
             "{\"detail\":\"D-LST\",\"relation\":\"subset\",\"repeats\":{}}");
  spec_summary_of_free(&s);
  som_json_free(a);
  a = args("{\"fields\":[\"@self\"]}");
  SpecInverseOf inv;
  spec_inverse_of_from_arguments(a, &inv);
  check("defaults.symmetric", spec_inverse_of_symmetric(&inv), NULL);
  spec_inverse_of_free(&inv);
  som_json_free(a);
  a = args("{\"fields\":[\"@self\",\"X.y\"]}");
  spec_inverse_of_from_arguments(a, &inv);
  check("defaults.notSymmetric", !spec_inverse_of_symmetric(&inv), NULL);
  spec_inverse_of_free(&inv);
  som_json_free(a);
  a = args("{\"ref\":\"L.ref\",\"from\":[\"A.b\",null]}");
  SpecExtractsLinks e;
  spec_extracts_links_from_arguments(a, &e);
  check_json("defaults.extractsJson", spec_extracts_links_to_json(&e),
             "{\"from\":[\"A.b\"],\"ref\":\"L.ref\",\"set\":{},\"mode\":"
             "\"generate\"}");
  spec_extracts_links_free(&e);
  som_json_free(a);
  a = args("{\"document\":\"D\",\"relations\":[{\"place\":\"P\"},\"junk\"]}");
  SpecSync sync;
  spec_sync_from_arguments(a, &sync);
  check("defaults.syncRelations", sync.relations_len == 1, NULL);
  if (sync.relations_len == 1) {
    check_json("defaults.relationJson",
               spec_list_relation_to_json(&sync.relations[0]),
               "{\"place\":\"P\",\"relation\":\"equal\"}");
  }
  spec_sync_free(&sync);
  som_json_free(a);
  SpecSameAs same;
  spec_same_as_from_arguments(NULL, &same);
  check_json("defaults.sameAsJson", spec_same_as_to_json(&same), "{}");
  spec_same_as_free(&same);
}

/* A string -> string argument keeps the order the meta writes it in. */
static void test_reader_keeps_meta_order(void) {
  SomJson *a = args("{\"detail\":\"D-LST\",\"repeats\":{\"Z.a\":\"1\","
                    "\"A.b\":\"2\",\"M.c\":\"3\"}}");
  SpecAnnotation ann = {(char *)"SummaryOf", a};
  SpecAnnotationList list = {&ann, 1};
  SpecSummaryOf s;
  int ok = spec_annotations_summary_of(&list, &s);
  check("order.repeats",
        ok && s.repeats.len == 3 && strcmp(s.repeats.items[0].key, "Z.a") == 0 &&
            strcmp(s.repeats.items[1].key, "A.b") == 0 &&
            strcmp(s.repeats.items[2].key, "M.c") == 0,
        NULL);
  if (ok) spec_summary_of_free(&s);
  som_json_free(a);
}

static void test_model_accessors(const SpecModel *model) {
  const SpecClass *req = spec_model_class_named(model, "Requirement");
  SpecExtractsLinksList links;
  spec_annotations_extracts_links(
      &spec_class_field_named(req, "links")->annotations, &links);
  check("accessors.extractsLinks", links.len == 2, NULL);
  spec_extracts_links_list_free(&links);
  const SpecClass *blu = spec_model_class_named(model, "Blueprint");
  SpecSync sync;
  int has = spec_annotations_synced_with(&blu->annotations, &sync);
  check("accessors.noSync", !has, NULL);
  if (has) spec_sync_free(&sync);
  check("accessors.notProjection", !spec_class_is_code_specs_projection(blu),
        NULL);
}

int main(void) {
  SpecModel *model = links_model();
  test_place_grammar();
  test_filter_grammar();
  test_resolution(model);
  test_positions_and_same_as(model);
  test_reader_defaults();
  test_reader_keeps_meta_order();
  test_model_accessors(model);
  spec_model_free(model);
  if (g_failures == 0) {
    printf("spec_place_test: all %d checks passed\n", g_checks);
  } else {
    fprintf(stderr, "spec_place_test: %d of %d checks failed\n", g_failures,
            g_checks);
  }
  return g_failures;
}
