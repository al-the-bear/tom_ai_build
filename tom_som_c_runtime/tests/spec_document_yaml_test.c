/* DR5 hierarchical `*.docspecs.yaml` v2 codec tests — a port of the Go
 * `tom_som_go_runtime/tests/spec_document_yaml_test.go` (itself a port of the
 * TypeScript / JavaScript / Python / Dart suites).
 *
 * The codec walks the document root's SomMetaTree: sections nest, keys are
 * `<section-id> <member-name>`, list items key by stored section id (or an
 * anonymous positional `<member>-<n>`), body text uses the literal `content`
 * key, and form fields use their bare names. Round-trip is lossless modulo
 * the DR1 §2.4.3 empty-line dedup; version-1 files and unmatched keys are
 * structured load errors.
 *
 * 58 checks; check names byte-match the Go suite. Exit status is the number
 * of failed checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_document_yaml.h"
#include "spec_meta.h"
#include "spec_meta_bridge.h"
#include "spec_model.h"
#include "spec_section_id.h"
#include "yaml.h"

/* ---- checker ------------------------------------------------------------- */

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

static void fatal(const char *what, char *err) {
  fprintf(stderr, "fatal: %s: %s\n", what, err != NULL ? err : "(no message)");
  free(err);
  exit(2);
}

static int str_eq(const char *a, const char *b) {
  return a != NULL && b != NULL && strcmp(a, b) == 0;
}

static char *cat2(const char *a, const char *b) {
  char *out = (char *)malloc(strlen(a) + strlen(b) + 1);
  strcpy(out, a);
  strcat(out, b);
  return out;
}

/* ---- fixture model / tree ------------------------------------------------ */

/* Exercises every field kind: root body content, a content section with a
 * nested complex section, a complex list with `@SectionIdPattern`, a scalar
 * list, a `@Form` with a numeric field, enum and int leaves. */
static const char *yaml_test_model_json =
    "{\n"
    "  \"modelVersion\": 1,\n"
    "  \"roots\": [{\"type\": \"Demo\", \"title\": \"Demo Document\", "
    "\"sectionId\": \"D00\"}],\n"
    "  \"classes\": {\n"
    "    \"Demo\": {\n"
    "      \"name\": \"Demo\",\n"
    "      \"sectionId\": \"D00\",\n"
    "      \"fields\": [\n"
    "        {\"name\": \"overview\", \"kind\": \"content\", \"sectionId\": "
    "\"D00-OVR\",\n"
    "         \"serializationOrder\": 0},\n"
    "        {\"name\": \"scope\", \"kind\": \"complex\", \"sectionId\": "
    "\"D00-SCO\",\n"
    "         \"type\": \"Scope\", \"serializationOrder\": 1},\n"
    "        {\"name\": \"header\", \"kind\": \"form\", \"sectionId\": "
    "\"D00-HDR\",\n"
    "         \"serializationOrder\": 2,\n"
    "         \"formFields\": [\n"
    "           {\"name\": \"author\", \"label\": \"Author\", \"type\": "
    "\"String\"},\n"
    "           {\"name\": \"reviewer\", \"label\": \"Reviewer\", \"type\": "
    "\"String\"},\n"
    "           {\"name\": \"revision\", \"label\": \"Revision\", \"type\": "
    "\"int\"}\n"
    "         ]},\n"
    "        {\"name\": \"requirements\", \"kind\": \"list\", \"sectionId\": "
    "\"D00-REQ\",\n"
    "         \"sectionIdPattern\": \"REQ-xxx\", \"elementType\": "
    "\"Requirement\",\n"
    "         \"elementIsComplex\": true, \"serializationOrder\": 3},\n"
    "        {\"name\": \"tags\", \"kind\": \"list\", \"sectionId\": "
    "\"D00-TAG\",\n"
    "         \"elementType\": \"String\", \"elementIsComplex\": false,\n"
    "         \"serializationOrder\": 4},\n"
    "        {\"name\": \"priority\", \"kind\": \"enum\", \"sectionId\": "
    "\"D00-PRI\",\n"
    "         \"enumType\": \"Priority\", \"enumValues\": [\"low\", "
    "\"high\"],\n"
    "         \"serializationOrder\": 5},\n"
    "        {\"name\": \"count\", \"kind\": \"scalar\", \"type\": \"int\",\n"
    "         \"serializationOrder\": 6}\n"
    "      ]\n"
    "    },\n"
    "    \"Scope\": {\n"
    "      \"name\": \"Scope\",\n"
    "      \"fields\": [\n"
    "        {\"name\": \"inScope\", \"kind\": \"content\", \"sectionId\": "
    "\"D00-INS\"},\n"
    "        {\"name\": \"outOfScope\", \"kind\": \"content\"}\n"
    "      ]\n"
    "    },\n"
    "    \"Requirement\": {\n"
    "      \"name\": \"Requirement\",\n"
    "      \"fields\": [\n"
    "        {\"name\": \"text\", \"kind\": \"content\"},\n"
    "        {\"name\": \"notes\", \"kind\": \"list\", \"elementType\": "
    "\"String\",\n"
    "         \"elementIsComplex\": false}\n"
    "      ]\n"
    "    }\n"
    "  }\n"
    "}";

static SpecModel *g_model = NULL;
static SomMetaTree *g_tree = NULL;

/* ---- helpers -------------------------------------------------------------- */

static char *yaml_enc(const SpecDocument *d, const char *stamp) {
  char *err = NULL;
  char *out = encode_yaml(d, g_tree, stamp, &err);
  if (out == NULL) fatal("encode", err);
  return out;
}

static void yaml_dec(const char *yaml, SpecYamlContents *out) {
  char *err = NULL;
  if (!decode_yaml(yaml, g_tree, out, &err)) fatal("decode", err);
}

/* Encode → decode; the caller frees `out` with spec_yaml_contents_free. */
static void yaml_round_trip(const SpecDocument *d, SpecYamlContents *out) {
  char *yaml = yaml_enc(d, "");
  yaml_dec(yaml, out);
  free(yaml);
}

static const char *content_or(const SpecDocument *d, const char *path) {
  const char *v = spec_document_content(d, path);
  return v != NULL ? v : "";
}

static const char *form_field_or(const SpecDocument *d, const char *path,
                                 const char *field) {
  const char *v = spec_document_form_field(d, path, field);
  return v != NULL ? v : "";
}

/* Builds a document touching every store and the §2.4 edge cases. */
static void yaml_populated(SpecDocument *doc) {
  spec_document_init(doc);
  spec_document_set_content(doc, "D00", "Preamble body text.");
  spec_document_set_content(doc, "D00/D00-OVR",
                            "line one\nline two\nline three");
  spec_document_set_content(doc, "D00/D00-SCO/D00-INS",
                            "  indented first line\n    deeper");
  spec_document_set_content(doc, "D00/D00-SCO/outOfScope",
                            "ends with newline\n");
  spec_document_set_content(doc, "D00/D00-PRI", "high");
  spec_document_set_content(doc, "D00/count", "3");
  spec_document_set_form_field(doc, "D00/D00-HDR", "author", "Ada Lovelace");
  spec_document_set_form_field(doc, "D00/D00-HDR", "reviewer", "Grace Hopper");
  spec_document_set_form_field(doc, "D00/D00-HDR", "revision", "7");
  SpecSectionIdError sid_err;
  spec_section_id_error_init(&sid_err);
  char *a = spec_document_add_list_item_with_section_id(doc, "D00/D00-REQ",
                                                        "REQ-AB1", &sid_err);
  if (a == NULL) fatal("addListItem", som_strdup("section id rejected"));
  {
    char *p = cat2(a, "/text");
    spec_document_set_content(doc, p, "value: with: colons # and hash");
    free(p);
  }
  {
    char *notes_path = cat2(a, "/notes");
    char *n1 = spec_document_add_list_item(doc, notes_path);
    spec_document_set_content(doc, n1, "a nested scalar note");
    free(n1);
    free(notes_path);
  }
  free(a);
  char *b = spec_document_add_list_item(doc, "D00/D00-REQ"); /* anonymous */
  {
    char *p = cat2(b, "/text");
    spec_document_set_content(doc, p, "second requirement");
    free(p);
  }
  free(b);
  char *t1 = spec_document_add_list_item(doc, "D00/D00-TAG");
  spec_document_set_content(doc, t1, "alpha");
  free(t1);
}

/* ---- suites --------------------------------------------------------------- */

static void yaml_test_encode(void) {
  /* writes the v2 header, version and hierarchical structure */
  SpecDocument populated;
  yaml_populated(&populated);
  char *yaml = yaml_enc(&populated, "1.0");
  static const char *header =
      "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n";
  check("encode.header", strncmp(yaml, header, strlen(header)) == 0, yaml);
  check("encode.version", strstr(yaml, "version: 2\n") != NULL, "");
  check("encode.stamp", strstr(yaml, "modelVersion: \"1.0\"\n") != NULL, "");
  check("encode.rootKey", strstr(yaml, "\ndocument:\n  D00 Demo:\n") != NULL,
        "");
  check("encode.nesting",
        strstr(yaml, "\n    D00-SCO scope:\n      D00-INS inScope:") != NULL,
        "");
  check("encode.rootContent",
        strstr(yaml, "\n    content: |2-\n      Preamble body text.\n") != NULL,
        "");
  check("encode.storedItemId",
        strstr(yaml, "\n    D00-REQ requirements:\n      REQ-AB1:\n") != NULL,
        "");
  check("encode.anonItem", strstr(yaml, "\n      requirements-2:\n") != NULL,
        "");
  check("encode.noFlatPaths", strstr(yaml, "\"D00/") == NULL, "");
  free(yaml);
  spec_document_free(&populated);

  /* sibling order follows @SerializationOrder, sparse emission */
  {
    SpecDocument doc;
    spec_document_init(&doc);
    spec_document_set_content(&doc, "D00/D00-PRI", "low");   /* order 5 */
    spec_document_set_content(&doc, "D00/D00-OVR", "first"); /* order 0 */
    char *sparse = yaml_enc(&doc, "");
    const char *ovr = strstr(sparse, "D00-OVR overview:");
    const char *pri = strstr(sparse, "D00-PRI priority:");
    check("encode.order", ovr != NULL && pri != NULL && ovr < pri, "");
    check("encode.sparse", strstr(sparse, "D00-SCO") == NULL, "");
    free(sparse);
    spec_document_free(&doc);
  }

  /* non-text values are plain scalars (§2.5) */
  {
    SpecDocument doc2;
    yaml_populated(&doc2);
    char *yaml2 = yaml_enc(&doc2, "");
    check("encode.plainEnum",
          strstr(yaml2, "\n    D00-PRI priority: high\n") != NULL, "");
    check("encode.plainInt", strstr(yaml2, "\n    count: 3\n") != NULL, "");
    check("encode.plainFormInt",
          strstr(yaml2, "\n      revision: 7\n") != NULL, "");
    free(yaml2);
    spec_document_free(&doc2);
  }

  /* YAML 1.1-special values are quoted, not plain (§2.5, DRC6). `on`/`no` are
   * 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings under
   * YAML 1.2 but bool/number under YAML 1.1. They must emit as block scalars so
   * every runtime reads back the exact string; an ordinary token stays plain. */
  {
    SpecDocument special;
    spec_document_init(&special);
    const char *vals[4] = {"on", "no", "1:30", "plain"};
    for (int i = 0; i < 4; i++) {
      char *p = spec_document_add_list_item(&special, "D00/D00-TAG");
      spec_document_set_content(&special, p, vals[i]);
      free(p);
    }
    char *yaml3 = yaml_enc(&special, "");
    check("encode.yaml11.on",
          strstr(yaml3, "\n      tags-1: |2-\n        on\n") != NULL, "");
    check("encode.yaml11.no",
          strstr(yaml3, "\n      tags-2: |2-\n        no\n") != NULL, "");
    check("encode.yaml11.sexagesimal",
          strstr(yaml3, "\n      tags-3: |2-\n        1:30\n") != NULL, "");
    check("encode.yaml11.plain",
          strstr(yaml3, "\n      tags-4: plain\n") != NULL, "");
    free(yaml3);
    SpecYamlContents rt_special;
    yaml_round_trip(&special, &rt_special);
    const SpecDocument *outs = &rt_special.document;
    const SomStrList *stags = spec_document_list_items(outs, "D00/D00-TAG");
    check("encode.yaml11.roundTrip",
          stags != NULL && stags->len == 4 &&
              str_eq(content_or(outs, stags->items[0]), "on") &&
              str_eq(content_or(outs, stags->items[1]), "no") &&
              str_eq(content_or(outs, stags->items[2]), "1:30") &&
              str_eq(content_or(outs, stags->items[3]), "plain"),
          "");
    spec_yaml_contents_free(&rt_special);
    spec_document_free(&special);
  }

  /* an empty document emits `document: {}` */
  {
    SpecDocument empty;
    spec_document_init(&empty);
    char *out = yaml_enc(&empty, "");
    check("encode.emptyDoc", strstr(out, "document: {}") != NULL, "");
    free(out);

    /* the model-version stamp is omitted when absent */
    char *out2 = yaml_enc(&empty, "");
    check("encode.noStamp", strstr(out2, "modelVersion:") == NULL, "");
    free(out2);
    spec_document_free(&empty);
  }

  /* values the tree cannot place are a structured error */
  {
    SpecDocument ghost;
    spec_document_init(&ghost);
    spec_document_set_content(&ghost, "D00/ghost", "x");
    char *err_ghost = NULL;
    char *out = encode_yaml(&ghost, g_tree, "", &err_ghost);
    check("encode.leftoverError", out == NULL && err_ghost != NULL, "");
    free(out);
    free(err_ghost);
    spec_document_free(&ghost);
  }

  /* an unknown form field is a structured error */
  {
    SpecDocument bogus;
    spec_document_init(&bogus);
    spec_document_set_form_field(&bogus, "D00/D00-HDR", "bogus", "v");
    char *err_bogus = NULL;
    char *out = encode_yaml(&bogus, g_tree, "", &err_bogus);
    check("encode.unknownFormField", out == NULL && err_bogus != NULL, "");
    free(out);
    free(err_bogus);
    spec_document_free(&bogus);
  }
}

static void yaml_test_round_trip(void) {
  /* every value survives verbatim */
  SpecDocument populated;
  yaml_populated(&populated);
  SpecYamlContents rt;
  yaml_round_trip(&populated, &rt);
  SpecDocument *out = &rt.document;
  check("rt.root", str_eq(content_or(out, "D00"), "Preamble body text."), "");
  check("rt.overview",
        str_eq(content_or(out, "D00/D00-OVR"),
               "line one\nline two\nline three"),
        "");
  check("rt.inScope",
        str_eq(content_or(out, "D00/D00-SCO/D00-INS"),
               "  indented first line\n    deeper"),
        "");
  check("rt.outOfScope",
        str_eq(content_or(out, "D00/D00-SCO/outOfScope"),
               "ends with newline\n"),
        "");
  check("rt.priority", str_eq(content_or(out, "D00/D00-PRI"), "high"), "");
  check("rt.count", str_eq(content_or(out, "D00/count"), "3"), "");
  check("rt.author",
        str_eq(form_field_or(out, "D00/D00-HDR", "author"), "Ada Lovelace"),
        "");
  check("rt.reviewer",
        str_eq(form_field_or(out, "D00/D00-HDR", "reviewer"), "Grace Hopper"),
        "");
  check("rt.revision",
        str_eq(form_field_or(out, "D00/D00-HDR", "revision"), "7"), "");
  check("rt.reqCount", spec_document_list_item_count(out, "D00/D00-REQ") == 2,
        "");
  const SomStrList *items = spec_document_list_items(out, "D00/D00-REQ");
  check("rt.item0.id",
        items != NULL && items->len == 2 &&
            str_eq(spec_document_item_section_id(out, items->items[0]),
                   "REQ-AB1"),
        "");
  check("rt.item1.id",
        items != NULL && items->len == 2 &&
            spec_document_item_section_id(out, items->items[1]) == NULL,
        "");
  {
    char *p0 = cat2(items->items[0], "/text");
    char *p1 = cat2(items->items[1], "/text");
    check("rt.item0.text",
          str_eq(content_or(out, p0), "value: with: colons # and hash"), "");
    check("rt.item1.text", str_eq(content_or(out, p1), "second requirement"),
          "");
    free(p0);
    free(p1);
  }
  {
    char *notes_path = cat2(items->items[0], "/notes");
    const SomStrList *notes = spec_document_list_items(out, notes_path);
    check("rt.notes",
          notes != NULL && notes->len == 1 &&
              str_eq(content_or(out, notes->items[0]), "a nested scalar note"),
          "");
    free(notes_path);
  }
  {
    const SomStrList *tags = spec_document_list_items(out, "D00/D00-TAG");
    check("rt.tags",
          tags != NULL && tags->len == 1 &&
              str_eq(content_or(out, tags->items[0]), "alpha"),
          "");
  }
  spec_yaml_contents_free(&rt);

  /* encode is byte-stable across decode → re-encode */
  {
    char *yaml1 = yaml_enc(&populated, "1.2");
    SpecYamlContents c1;
    yaml_dec(yaml1, &c1);
    char *yaml2 = yaml_enc(&c1.document, "1.2");
    check("rt.byteStable", str_eq(yaml2, yaml1), "");
    free(yaml2);
    spec_yaml_contents_free(&c1);
    free(yaml1);
  }

  /* the model-version stamp lands on the decoded document */
  {
    char *yaml = yaml_enc(&populated, "2.5");
    SpecYamlContents decoded;
    yaml_dec(yaml, &decoded);
    check("rt.stamp.contents", str_eq(decoded.model_version, "2.5"), "");
    check("rt.stamp.document", str_eq(decoded.document.model_version, "2.5"),
          "");
    spec_yaml_contents_free(&decoded);
    free(yaml);
  }
  spec_document_free(&populated);

  /* markdown edge cases survive */
  {
    static const char *cases[] = {
        "\nleading blank line",
        "trailing blank line kept as one\n\nend",
        "two trailing newlines\n\n", /* block cannot represent → JSON fallback */
        "trailing space on a line \nnext",
        "\ttab\tpreserved",
        "- looks: like\n  yaml: [a, b]\n# comment-ish",
        "\"double\" and 'single' quotes",
        "ends with newline\n",
        "   only-indentation-sensitive\n      nested deeper\n   back",
    };
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); ++i) {
      SpecDocument doc;
      spec_document_init(&doc);
      spec_document_set_content(&doc, "D00/D00-OVR", cases[i]);
      SpecYamlContents c;
      yaml_round_trip(&doc, &c);
      const char *got = content_or(&c.document, "D00/D00-OVR");
      char name[32];
      snprintf(name, sizeof(name), "rt.edge[%zu]", i);
      check(name, str_eq(got, cases[i]), got);
      spec_yaml_contents_free(&c);
      spec_document_free(&doc);
    }
  }

  /* runs of 2+ empty lines collapse to one on write (§2.4.3) */
  {
    SpecDocument doc;
    spec_document_init(&doc);
    spec_document_set_content(&doc, "D00/D00-OVR", "a\n\n\n\nb\n\n\nc");
    SpecYamlContents c;
    yaml_round_trip(&doc, &c);
    check("rt.emptyLineDedup",
          str_eq(content_or(&c.document, "D00/D00-OVR"), "a\n\nb\n\nc"), "");
    spec_yaml_contents_free(&c);
    spec_document_free(&doc);
  }

  /* an empty complex list item round-trips as `{}` */
  {
    SpecDocument empty_item;
    spec_document_init(&empty_item);
    free(spec_document_add_list_item(&empty_item, "D00/D00-REQ"));
    char *yaml3 = yaml_enc(&empty_item, "");
    check("rt.emptyItem.enc", strstr(yaml3, "requirements-1: {}") != NULL,
          yaml3);
    SpecYamlContents c;
    yaml_round_trip(&empty_item, &c);
    check("rt.emptyItem.count",
          spec_document_list_item_count(&c.document, "D00/D00-REQ") == 1, "");
    spec_yaml_contents_free(&c);
    free(yaml3);
    spec_document_free(&empty_item);
  }
}

/* Decodes expecting failure; reports whether an error containing `needle` was
 * produced (the C stand-in for the other ports' `_throwsFormat` helper). */
static int decode_fails_with(const char *yaml, const char *needle) {
  SpecYamlContents c;
  char *err = NULL;
  if (decode_yaml(yaml, g_tree, &c, &err)) {
    spec_yaml_contents_free(&c);
    return 0;
  }
  int ok = err != NULL && strstr(err, needle) != NULL;
  free(err);
  return ok;
}

static void yaml_test_strict_decode(void) {
  /* version 1 files are rejected with a clear error */
  check("decode.v1Rejected",
        decode_fails_with("version: 1\ndocument: {}\n", "version 1"), "");

  /* a missing version is rejected */
  check("decode.missingVersion", decode_fails_with("document: {}\n", ""), "");
  check("decode.emptyText", decode_fails_with("", ""), "");

  /* an unmatched key is a structured load error, not a silent skip */
  check("decode.unmatchedKey",
        decode_fails_with(
            "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n",
            "nonsense"),
        "");

  /* a wrong root key is a structured load error */
  check("decode.wrongRoot",
        decode_fails_with("version: 2\ndocument:\n  WRONG Other: {}\n", ""),
        "");

  /* an unknown form field on read is a structured load error */
  check("decode.unknownFormField",
        decode_fails_with("version: 2\ndocument:\n  D00 Demo:\n"
                          "    D00-HDR header:\n      bogus: |-\n        v\n",
                          ""),
        "");

  /* a missing/empty document pass decodes as an empty document */
  {
    SpecYamlContents c;
    yaml_dec("version: 2\n", &c);
    check("decode.noDocKey", spec_document_is_empty(&c.document), "");
    spec_yaml_contents_free(&c);
  }
  {
    SpecYamlContents c;
    yaml_dec("version: 2\ndocument: {}\n", &c);
    check("decode.emptyDoc", spec_document_is_empty(&c.document), "");
    spec_yaml_contents_free(&c);
  }

  /* the raw review pass is passed through untouched */
  {
    SpecYamlContents c;
    yaml_dec("version: 2\n"
             "document: {}\n"
             "review:\n"
             "  \"D00/a\":\n"
             "    scope: global\n",
             &c);
    check("decode.review", yaml_get(c.review, "D00/a") != NULL, "");
    spec_yaml_contents_free(&c);
  }
}

int main(void) {
  char *err = NULL;
  g_model = spec_model_from_json_str(yaml_test_model_json, &err);
  if (g_model == NULL) fatal("model", err);
  g_tree = som_build_meta_tree(g_model, "", &err);
  if (g_tree == NULL) fatal("tree", err);

  yaml_test_encode();
  yaml_test_round_trip();
  yaml_test_strict_decode();

  som_meta_tree_free(g_tree);
  spec_model_free(g_model);

  if (g_failures == 0) {
    printf("spec_document_yaml_test: %d checks passed\n", g_checks);
  } else {
    fprintf(stderr, "spec_document_yaml_test: %d/%d checks FAILED\n",
            g_failures, g_checks);
  }
  return g_failures;
}
