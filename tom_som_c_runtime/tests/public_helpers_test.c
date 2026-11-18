/* The functions TS exports that this port had kept `static` or had no
 * accessor for: the serialization order key, the YAML writer pieces, the
 * Markdown heading-comment readers, `DocSpecsDocument.allSections` and the
 * reflection lookups. The expected values are the TypeScript runtime's output
 * for the same inputs (the corpus model and the small model below). */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "tom_som_c_runtime.h"

#define SIBLINGS ".."

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

static void check_str(const char *name, char *got, const char *want) {
  int ok = got != NULL && strcmp(got, want) == 0;
  char detail[512];
  snprintf(detail, sizeof detail, "got <%s>, want <%s>", got ? got : "(null)",
           want);
  check(name, ok, detail);
  free(got);
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

static SpecModel *model_from(const char *json) {
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(json, &err);
  if (m == NULL) {
    fprintf(stderr, "fatal: model: %s\n", err ? err : "?");
    exit(2);
  }
  return m;
}

/* The small model: ordered members, an unordered one, and a complex list. */
static const char *SMALL_MODEL =
    "{\"metaSchemaVersion\":1,\"modelVersion\":1,\"classCount\":2,"
    "\"rootCount\":1,"
    "\"roots\":[{\"type\":\"Demo\",\"title\":\"Demo\",\"sectionId\":\"DEMO\"}],"
    "\"classes\":{"
    "\"Demo\":{\"name\":\"Demo\",\"sectionId\":\"DEMO\",\"fields\":["
    "{\"name\":\"title\",\"kind\":\"content\",\"sectionId\":\"TTL\","
    "\"serializationOrder\":3},"
    "{\"name\":\"items\",\"kind\":\"list\",\"elementType\":\"Item\","
    "\"elementIsComplex\":true,\"serializationOrder\":1}]},"
    "\"Item\":{\"name\":\"Item\",\"fields\":["
    "{\"name\":\"label\",\"kind\":\"content\",\"serializationOrder\":0},"
    "{\"name\":\"note\",\"kind\":\"content\"}]}}}";

static void check_key(const SpecSerializationOrder *o, const char *path,
                      const long long *want, size_t want_len) {
  size_t len = 99;
  long long *key = spec_serialization_order_order_key(o, path, &len);
  int ok = len == want_len && (want_len == 0 ? key == NULL : key != NULL);
  for (size_t i = 0; ok && i < len; i++) {
    ok = key[i] == want[i];
  }
  check(path, ok, "order key differs");
  free(key);
}

static void test_order_key(void) {
  SpecModel *m = model_from(SMALL_MODEL);
  SpecSerializationOrder o = spec_serialization_order_make(m);
  const long long fb = SPEC_SERIALIZATION_UNORDERED_FALLBACK;
  check_key(&o, "DEMO/TTL", (const long long[]){3}, 1);
  check_key(&o, "DEMO/items", (const long long[]){1}, 1);
  check_key(&o, "DEMO/items-4", (const long long[]){1, 4}, 2);
  check_key(&o, "DEMO/items-4/label", (const long long[]){1, 4, 0}, 3);
  check_key(&o, "DEMO/items-4/note", (const long long[]){1, 4, fb}, 3);
  check_key(&o, "DEMO/nope", NULL, 0);
  check_key(&o, "DEMO", NULL, 0);
  check_key(&o, "NOPE/x", NULL, 0);
  check(
      "fallback", fb == 1073741824LL, "SPEC_SERIALIZATION_UNORDERED_FALLBACK");
  spec_model_free(m);
}

static void test_yaml_and_markdown_helpers(void) {
  SomBuf b;
  som_buf_init(&b);
  spec_yaml_write_header(&b, "1.2.3");
  spec_yaml_write_header(&b, "");
  spec_yaml_write_header(&b, NULL);
  check_str("spec_yaml_write_header", som_buf_take(&b),
            "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"
            "version: 2\nmodelVersion: \"1.2.3\"\n"
            "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"
            "version: 2\n"
            "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"
            "version: 2\n");

  check_str("spec_yaml_key", spec_yaml_key("a b"), "\"a b\"");
  check_str("spec_yaml_key escapes", spec_yaml_key("q\"\n"), "\"q\\\"\\n\"");

  {
    YamlValue t = {.type = YAML_BOOL, .as.boolean = 1};
    YamlValue i = {.type = YAML_INT, .as.integer = 3};
    YamlValue f = {.type = YAML_FLOAT, .as.real = 2.5};
    YamlValue w = {.type = YAML_FLOAT, .as.real = 3.0};
    YamlValue n = {.type = YAML_NULL};
    YamlValue nan = {.type = YAML_FLOAT, .as.real = 0.0 / 0.0};
    YamlValue inf = {.type = YAML_FLOAT, .as.real = -1.0 / 0.0};
    YamlValue str = {.type = YAML_STR, .as.str = (char *)"plain"};
    check_str("review_scalar true", spec_yaml_review_scalar(&t), "true");
    check_str("review_scalar 3", spec_yaml_review_scalar(&i), "3");
    check_str("review_scalar 2.5", spec_yaml_review_scalar(&f), "2.5");
    check_str("review_scalar 3.0", spec_yaml_review_scalar(&w), "3.0");
    check_str("review_scalar null", spec_yaml_review_scalar(&n), "null");
    check_str("review_scalar nan", spec_yaml_review_scalar(&nan), ".nan");
    check_str("review_scalar -inf", spec_yaml_review_scalar(&inf), "-.inf");
    check_str("review_scalar string", spec_yaml_review_scalar(&str), "plain");
  }

  check_str("code_spec_of",
            spec_markdown_code_spec_of("sectionId=\"X\" codeSpec=\" a,b \""),
            "a,b");
  check_str("code_spec_of absent", spec_markdown_code_spec_of("sectionId=\"X\""),
            "");
  check_str("units_of", spec_markdown_units_of("units='server,web'"),
            "server,web");
  check_str("units_of inside a codeSpec value",
            spec_markdown_units_of("codeSpec=\"units=x\""), "");
}

static void test_all_sections(void) {
  DocSpecsDocument *doc = docspecs_parse_document(
      "<!-- docspec: x/1.0 -->\n# <!--[A]--> A\n\ntext\n\n## <!--[A1]--> A1\n\n"
      "### <!--[A11]--> A11\n\n## <!--[A2]--> A2\n\n# <!--[B]--> B\n");
  size_t n = 0;
  const DocSpecsSection **all = docspecs_document_all_sections(doc, &n);
  const char *want[] = {"A", "A1", "A11", "A2", "B"};
  int ok = n == 5 && all != NULL;
  for (size_t i = 0; ok && i < n; i++) {
    ok = strcmp(all[i]->id, want[i]) == 0;
  }
  check("docspecs_document_all_sections", ok, "order A, A1, A11, A2, B");
  free(all);
  docspecs_document_free(doc);

  DocSpecsDocument *empty = docspecs_parse_document("no headings\n");
  n = 99;
  all = docspecs_document_all_sections(empty, &n);
  check("all_sections empty", all == NULL && n == 0, "");
  docspecs_document_free(empty);
}

static void test_reflection(void) {
  char *json = read_file(SIBLINGS "/tom_som_conformance/corpus/model.meta.json");
  SpecModel *m = model_from(json);
  free(json);
  SpecReflection r = spec_reflection_make(m);
  size_t n = 0;

  const SpecRoot *roots = spec_reflection_roots(&r, &n);
  check("roots", n == 2 && strcmp(roots[0].type, "Demo") == 0 &&
                     strcmp(roots[1].type, "Sidecar") == 0,
        "Demo, Sidecar");

  /* The model's order, not sorted: Demo, Registry, ..., Meta. */
  const SpecClass *const *classes = spec_reflection_classes(&r, &n);
  check("classes", n == 18 && strcmp(classes[0]->name, "Demo") == 0 &&
                       strcmp(classes[1]->name, "Registry") == 0 &&
                       strcmp(classes[8]->name, "Sidecar") == 0 &&
                       strcmp(classes[n - 1]->name, "Meta") == 0,
        "18 classes in the model's order");

  check("class_named", spec_reflection_class_named(&r, "Demo") != NULL, "");
  check("class_named unknown", spec_reflection_class_named(&r, "Nope") == NULL,
        "");
  check("class_named NULL", spec_reflection_class_named(&r, NULL) == NULL, "");

  const char *want_fields[] = {"title",    "summary",  "priority", "count",
                               "ratio",    "score",    "details",  "items",
                               "refs",     "cards",    "meta",     "control",
                               "notes",    "mixed",    "registry", "deliverables"};
  const SpecField *fields = spec_reflection_fields_of(&r, "Demo", &n);
  int ok = n == 16 && fields != NULL;
  for (size_t i = 0; ok && i < n; i++) {
    ok = strcmp(fields[i].name, want_fields[i]) == 0;
  }
  check("fields_of", ok, "the 16 fields of Demo in order");
  n = 99;
  check("fields_of unknown",
        spec_reflection_fields_of(&r, "Nope", &n) == NULL && n == 0, "");

  const SpecAnnotation *anns = spec_reflection_annotations_of(&r, "Demo", &n);
  check("annotations_of",
        n == 3 && strcmp(anns[0].name, "Document") == 0 &&
            strcmp(anns[1].name, "SectionId") == 0 &&
            strcmp(anns[2].name, "CodeSpecKind") == 0,
        "Document, SectionId, CodeSpecKind");

  anns = spec_reflection_field_annotations(&r, "Demo", "priority", &n);
  check("field_annotations",
        n == 1 && strcmp(anns[0].name, "CodeSpecKind") == 0, "CodeSpecKind");
  n = 99;
  check("field_annotations unknown field",
        spec_reflection_field_annotations(&r, "Demo", "nope", &n) == NULL &&
            n == 0,
        "");
  n = 99;
  check("field_annotations unknown class",
        spec_reflection_field_annotations(&r, "Nope", "title", &n) == NULL &&
            n == 0,
        "");
  spec_model_free(m);
}

int main(void) {
  test_order_key();
  test_yaml_and_markdown_helpers();
  test_all_sections();
  test_reflection();
  if (g_failures == 0) {
    printf("public_helpers_test: all %d checks passed.\n", g_checks);
    return 0;
  }
  fprintf(stderr, "public_helpers_test: %d of %d checks FAILED\n", g_failures,
          g_checks);
  return 1;
}
