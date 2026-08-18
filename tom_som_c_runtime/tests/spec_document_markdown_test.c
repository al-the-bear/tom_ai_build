/* Unit tests for the DocSpecs-conform Markdown codec
 * (`spec_document_markdown.c`, SOM §11) — a 1:1 C port of
 * `tom_som_go_runtime/tests/spec_document_markdown_test.go` (itself a port of
 * the TypeScript/Python/Dart reference suites). The check *names* match the Go
 * suite byte-for-byte.
 *
 * The generated `*.md` is a genuine DocSpecs document: line 1 is the
 * `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is a heading of the form `## <!--[SECTION-ID]--> Title`, content
 * sections are normal markdown text (no fences), `@Form` sections use the
 * plain-text `FieldName: value` format, and a `List<T>` field heads a
 * `<!--[FOO-LST]-->` container section with its numbered items one level
 * deeper and their item-element children one level deeper again.
 *
 * The model fixture (demoModelJSON) and populated document (populatedDemoDoc)
 * mirror one_line_export_test.go / one_line_export_test.c.
 *
 * Standalone: links the runtime static lib, exit 0 == all green.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_document.h"
#include "spec_document_markdown.h"
#include "spec_model.h"

/* ---- test harness -------------------------------------------------------- */

static int g_checks = 0;
static int g_failures = 0;

/* mdCheck mirrors the reference suites' _check(name, condition, detail). */
static void md_check(const char *name, int condition, const char *detail) {
  g_checks++;
  if (!condition) {
    g_failures++;
    if (detail != NULL && detail[0] != '\0') {
      fprintf(stderr, "FAIL: %s: %s\n", name, detail);
    } else {
      fprintf(stderr, "FAIL: %s\n", name);
    }
  }
}

static void fatal(const char *msg) {
  fprintf(stderr, "FATAL: %s\n", msg);
  exit(2);
}

/* ---- string helpers (stand-ins for Go's strings package) ----------------- */

static int has_prefix(const char *s, const char *prefix) {
  return strncmp(s, prefix, strlen(prefix)) == 0;
}

static int has_suffix(const char *s, const char *suffix) {
  size_t ls = strlen(s), lf = strlen(suffix);
  return ls >= lf && strcmp(s + ls - lf, suffix) == 0;
}

static int contains(const char *s, const char *sub) {
  return strstr(s, sub) != NULL;
}

/* The first line of `s` (up to the first '\n' or end), owned. */
static char *first_line(const char *s) {
  const char *nl = strchr(s, '\n');
  size_t n = nl != NULL ? (size_t)(nl - s) : strlen(s);
  return som_strdup_n(s, n);
}

/* SpecDocument.ContentOr / FormFieldOr / ItemSectionIDOr — "" for absent. */
static const char *content_or(const SpecDocument *d, const char *path) {
  const char *v = spec_document_content(d, path);
  return v != NULL ? v : "";
}

static const char *form_field_or(const SpecDocument *d, const char *path,
                                 const char *field) {
  const char *v = spec_document_form_field(d, path, field);
  return v != NULL ? v : "";
}

static const char *item_section_id_or(const SpecDocument *d,
                                      const char *item_path) {
  const char *v = spec_document_item_section_id(d, item_path);
  return v != NULL ? v : "";
}

/* Renders every rejection joined by "; " (mirrors mdRejStr). Owned. */
static char *md_rej_str(const SpecMarkdownResult *r) {
  SomBuf b;
  som_buf_init(&b);
  for (size_t i = 0; i < r->rejections_len; i++) {
    char *line = spec_markdown_rejection_display(&r->rejections[i]);
    if (i > 0) {
      som_buf_puts(&b, "; ");
    }
    som_buf_puts(&b, line);
    free(line);
  }
  return som_buf_take(&b);
}

/* map[string]string equality on the staged forms of `path` vs a single-field
 * expectation {field: value} (the tests only ever compare one field). */
static int form_matches_single(const SpecMarkdownResult *r, const char *path,
                               const char *field, const char *value) {
  const DocFormEntry *entry = NULL;
  for (size_t i = 0; i < r->staged.forms_len; i++) {
    if (strcmp(r->staged.forms[i].key, path) == 0) {
      entry = &r->staged.forms[i];
      break;
    }
  }
  if (entry == NULL) return 0;
  if (entry->fields.len != 1) return 0;
  const char *got = som_map_get(&entry->fields, field);
  return got != NULL && strcmp(got, value) == 0;
}

/* The staged content value for `path`, or NULL when absent. */
static const char *staged_content(const SpecMarkdownResult *r,
                                  const char *path) {
  return som_map_get(&r->staged.content, path);
}

static size_t staged_content_len(const SpecMarkdownResult *r) {
  return r->staged.content.len;
}

/* ---- fixtures (shared with one_line_export_test.c) ----------------------- */

static const char *DEMO_MODEL_JSON =
    "{"
    "  \"roots\": ["
    "    {\"type\": \"DemoDoc\", \"title\": \"Demo Document\", \"sectionId\": "
    "\"D00\", \"description\": \"A demo document.\"}"
    "  ],"
    "  \"classes\": {"
    "    \"DemoDoc\": {"
    "      \"name\": \"DemoDoc\","
    "      \"sectionId\": \"D00\","
    "      \"fields\": ["
    "        {\"name\": \"overview\", \"kind\": \"content\", \"sectionId\": "
    "\"D00-OVR\"},"
    "        {\"name\": \"status\", \"kind\": \"enum\", \"sectionId\": "
    "\"D00-ST\", \"enumValues\": [\"draft\", \"final\"]},"
    "        {\"name\": \"header\", \"kind\": \"form\", \"sectionId\": "
    "\"D00-HDR\","
    "         \"formFields\": ["
    "           {\"name\": \"author\", \"label\": \"Author\", \"type\": "
    "\"String\"},"
    "           {\"name\": \"reviewer\", \"label\": \"Reviewer\", \"type\": "
    "\"String\"}"
    "         ]},"
    "        {\"name\": \"meta\", \"kind\": \"complex\", \"type\": \"DemoMeta\", "
    "\"sectionId\": \"D00-MET\"},"
    "        {\"name\": \"items\", \"kind\": \"list\", \"elementType\": "
    "\"DemoItem\", \"elementIsComplex\": true, \"sectionId\": \"D00-ITM\"}"
    "      ]"
    "    },"
    "    \"DemoMeta\": {"
    "      \"name\": \"DemoMeta\","
    "      \"sectionId\": \"D00-MET\","
    "      \"fields\": ["
    "        {\"name\": \"note\", \"kind\": \"content\", \"sectionId\": "
    "\"D00-MET-NOTE\"}"
    "      ]"
    "    },"
    "    \"DemoItem\": {"
    "      \"name\": \"DemoItem\","
    "      \"fields\": ["
    "        {\"name\": \"label\", \"kind\": \"content\", \"sectionId\": "
    "\"D01-LBL\"},"
    "        {\"name\": \"body\", \"kind\": \"content\", \"sectionId\": "
    "\"D01-BODY\"}"
    "      ]"
    "    }"
    "  }"
    "}";

/* mdD4rtBody — multi-line d4rt body with a run of three backticks mid-line. */
static const char *MD_D4RT_BODY =
    "Column(\n"
    "  children: [\n"
    "    Text(\"hi\"),\n"
    "  ],\n"
    ") // not a fence: ``` still inside the body";

/* mdRichMarkdown — emphasis, a bullet list, a fenced code block containing
 * heading-like lines, and a leading `#` line at column 0. */
static const char *MD_RICH_MARKDOWN =
    "Intro with **bold** and *italic*.\n"
    "\n"
    "- first bullet\n"
    "- second bullet\n"
    "\n"
    "```dart\n"
    "# not a heading — shielded by the fence\n"
    "## also shielded\n"
    "void main() {}\n"
    "```\n"
    "\n"
    "# looks like a heading at column 0\n"
    "trailing paragraph";

static SpecModel *demo_model(void) {
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(DEMO_MODEL_JSON, &err);
  if (m == NULL) {
    fprintf(stderr, "demo_model parse failed: %s\n", err ? err : "?");
    free(err);
    fatal("demo_model");
  }
  return m;
}

/* populatedDemoDoc mirrors the Dart _populated() helper. Caller frees. */
static void populate_demo_doc(SpecDocument *doc) {
  spec_document_init(doc);
  spec_document_set_content(doc, "D00/D00-OVR",
                            "An overview paragraph.\nWith two lines.");
  spec_document_set_content(doc, "D00/D00-ST", "final");
  spec_document_set_form_field(doc, "D00/D00-HDR", "author", "Ada Lovelace");
  spec_document_set_content(doc, "D00/D00-MET/D00-MET-NOTE", "A note.");
  char *item = spec_document_add_list_item(doc, "D00/D00-ITM");
  char *lbl = malloc(strlen(item) + 16);
  sprintf(lbl, "%s/D01-LBL", item);
  spec_document_set_content(doc, lbl, "First item");
  free(lbl);
  char *body = malloc(strlen(item) + 16);
  sprintf(body, "%s/D01-BODY", item);
  spec_document_set_content(doc, body, MD_D4RT_BODY);
  free(body);
  free(item);
  char *item2 = spec_document_add_list_item(doc, "D00/D00-ITM");
  char *lbl2 = malloc(strlen(item2) + 16);
  sprintf(lbl2, "%s/D01-LBL", item2);
  spec_document_set_content(doc, lbl2, "Second item");
  free(lbl2);
  free(item2);
}

/* mdExport — export the single (first) root of `doc` against the demo model.
 * Owned result; fatal on error. */
static char *md_export(SpecModel *model, const SpecDocument *doc) {
  char *err = NULL;
  char *md = spec_markdown_export_root(model, doc, &model->roots[0], &err);
  if (md == NULL) {
    fprintf(stderr, "ExportRoot: unexpected error %s\n", err ? err : "?");
    free(err);
    fatal("md_export");
  }
  return md;
}

/* mdParse — parse md into a fresh result. Caller frees with
 * spec_markdown_result_free. */
static void md_parse(SpecModel *model, const char *md,
                     SpecMarkdownResult *out) {
  spec_markdown_parse(model, md, out);
}

/* mdReload — parse md and load the staged values into a fresh document. Caller
 * frees the document and the result. */
static void md_reload(SpecModel *model, const char *md, SpecDocument *target,
                      SpecMarkdownResult *report) {
  md_parse(model, md, report);
  spec_document_init(target);
  spec_document_load_json(target, &report->staged);
}

/* ---- export — DocSpecs format (SOM §11) ---------------------------------- */

static void test_markdown_export_format(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  populate_demo_doc(&doc);
  char *md = md_export(m, &doc);

  char *first = first_line(md);
  md_check("export.docspec.prefix",
           has_prefix(first, "<!-- docspec: demo-document/"), first);
  md_check("export.docspec.suffix", has_suffix(first, "-->"), first);
  free(first);

  md_check("export.heading.root", contains(md, "# <!--[D00]--> Demo Document"),
           NULL);
  md_check("export.heading.overview",
           contains(md, "## <!--[D00-OVR]--> Overview"), NULL);
  md_check("export.heading.status", contains(md, "## <!--[D00-ST]--> Status"),
           NULL);
  md_check("export.heading.header", contains(md, "## <!--[D00-HDR]--> Header"),
           NULL);
  md_check("export.heading.meta", contains(md, "## <!--[D00-MET]--> Meta"),
           NULL);
  md_check("export.heading.note",
           contains(md, "### <!--[D00-MET-NOTE]--> Note"), NULL);

  md_check("export.content.plain",
           contains(md, "An overview paragraph.\nWith two lines."), NULL);

  int no_fence = 1;
  {
    const char *p = md;
    while (p != NULL && *p != '\0') {
      if (has_prefix(p, "```")) {
        no_fence = 0;
        break;
      }
      const char *nl = strchr(p, '\n');
      p = nl != NULL ? nl + 1 : NULL;
    }
  }
  md_check("export.content.noFence", no_fence, NULL);
  md_check("export.content.noFieldAnchor", !contains(md, "<!-- field:"), NULL);
  md_check("export.content.noPathHeading", !contains(md, "D00/D00-OVR"), NULL);

  md_check("export.form.sparse.author", contains(md, "Author: Ada Lovelace"),
           NULL);
  md_check("export.form.sparse.noReviewer", !contains(md, "Reviewer"), NULL);

  md_check("export.item.container",
           contains(md, "## <!--[D00-ITM]--> Items"), NULL);
  md_check("export.item.1", contains(md, "### <!--[items-1]--> Demo Item 1"),
           NULL);
  md_check("export.item.2", contains(md, "### <!--[items-2]--> Demo Item 2"),
           NULL);
  md_check("export.item.label", contains(md, "#### <!--[D01-LBL]--> Label"),
           NULL);

  md_check("export.noSchemaDescription", !contains(md, "A demo document."),
           NULL);

  free(md);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_export_stored_item_id(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  char *item =
      spec_document_add_list_item_with_section_id(&doc, "D00/D00-ITM",
                                                  "D01-CUSTOM", NULL);
  if (item == NULL) fatal("AddListItemWithSectionID");
  char *lbl = malloc(strlen(item) + 16);
  sprintf(lbl, "%s/D01-LBL", item);
  spec_document_set_content(&doc, lbl, "Custom-id item");
  free(lbl);
  free(item);

  char *md = md_export(m, &doc);
  /* YRD3: the stored id IS the md heading id; only
     anonymous items fall back to the positional derivation. */
  md_check("export.storedId.container",
           contains(md, "## <!--[D00-ITM]--> Items"), md);
  md_check("export.storedId.heading",
           contains(md, "### <!--[D01-CUSTOM]--> Demo Item 1"), md);
  md_check("export.storedId.noPositional", !contains(md, "items-1"), md);

  free(md);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_export_unterm_fence_errors(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-OVR",
                            "before\n```dart\nnever closed");
  char *err = NULL;
  char *out = spec_markdown_export_root(m, &doc, &m->roots[0], &err);
  md_check("export.untermFence.raises",
           out == NULL && err != NULL && contains(err, "unterminated"),
           err ? err : "(no error)");
  free(out);
  free(err);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* SOM §9, "Form-field order": md refuses an undeclared stored field, as yaml
 * does (SOM §12.8). Omitting it would lose a stored value in a file that looks
 * complete — the silent drop the codecs must never do. */
static void test_markdown_export_undeclared_form_field_errors(void) {
  SpecModel *m = demo_model();

  SpecDocument doc;
  populate_demo_doc(&doc);
  spec_document_set_form_field(&doc, "D00/D00-HDR", "stale", "x");
  char *err = NULL;
  char *out = spec_markdown_export_root(m, &doc, &m->roots[0], &err);
  md_check("export.undeclaredField.raises",
           out == NULL && err != NULL && contains(err, "stale"),
           err ? err : "(no error)");
  md_check("export.undeclaredField.namesPath",
           err != NULL && contains(err, "D00/D00-HDR"),
           err ? err : "(no error)");
  free(out);
  free(err);
  spec_document_free(&doc);

  /* The check has to run even when the form has nothing else, or the whole
   * section is skipped before the check is reached and the drop is silent
   * again. */
  SpecDocument only;
  spec_document_init(&only);
  spec_document_set_content(&only, "D00/D00-OVR", "An overview paragraph.");
  spec_document_set_form_field(&only, "D00/D00-HDR", "stale", "x");
  err = NULL;
  out = spec_markdown_export_root(m, &only, &m->roots[0], &err);
  md_check("export.undeclaredFieldOnly.raises",
           out == NULL && err != NULL && contains(err, "stale"),
           err ? err : "(no error)");
  free(out);
  free(err);
  spec_document_free(&only);

  /* Sorted, so the reported name is the same in all nine runtimes. */
  SpecDocument two;
  populate_demo_doc(&two);
  spec_document_set_form_field(&two, "D00/D00-HDR", "zulu", "z");
  spec_document_set_form_field(&two, "D00/D00-HDR", "alpha", "a");
  err = NULL;
  out = spec_markdown_export_root(m, &two, &m->roots[0], &err);
  md_check("export.undeclaredField.sortedFirst",
           out == NULL && err != NULL && contains(err, "alpha") &&
               !contains(err, "zulu"),
           err ? err : "(no error)");
  free(out);
  free(err);
  spec_document_free(&two);

  spec_model_free(m);
}

/* ---- SpecDocument.ToMarkdown (one-line export, SOM §21) ------------------ */

static void test_markdown_to_markdown(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  populate_demo_doc(&doc);

  char *err = NULL;
  char *one_liner = spec_document_to_markdown(&doc, m, "DemoDoc", &err);
  if (one_liner == NULL) fatal("ToMarkdown(DemoDoc)");
  const SpecRoot *root = spec_model_root_by_type(m, "DemoDoc", &err);
  if (root == NULL) fatal("RootByType(DemoDoc)");
  char *explicit = spec_markdown_export_root(m, &doc, root, &err);
  if (explicit == NULL) fatal("ExportRoot(DemoDoc)");
  md_check("toMarkdown.explicitRoot", strcmp(one_liner, explicit) == 0, NULL);

  char *def = spec_document_to_markdown(&doc, m, "", &err);
  if (def == NULL) fatal("ToMarkdown(\"\")");
  md_check("toMarkdown.defaultRoot", strcmp(def, one_liner) == 0, NULL);

  SpecDocument empty;
  spec_document_init(&empty);
  char *empty_err = NULL;
  char *empty_md = spec_document_to_markdown(&empty, m, "", &empty_err);
  md_check("toMarkdown.emptyThrows",
           empty_md == NULL && empty_err != NULL &&
               contains(empty_err, "no populated root"),
           empty_err ? empty_err : "(no error)");
  free(empty_md);
  free(empty_err);
  spec_document_free(&empty);

  free(one_liner);
  free(explicit);
  free(def);
  spec_document_free(&doc);
  spec_model_free(m);

  /* Two-root model: the default is ambiguous and names both candidates. */
  const char *two_json =
      "{"
      "  \"roots\": ["
      "    {\"type\": \"Alpha\", \"title\": \"Alpha Doc\", \"sectionId\": "
      "\"A00\"},"
      "    {\"type\": \"Beta\",  \"title\": \"Beta Doc\",  \"sectionId\": "
      "\"B00\"}"
      "  ],"
      "  \"classes\": {"
      "    \"Alpha\": {\"name\": \"Alpha\", \"sectionId\": \"A00\","
      "      \"fields\": [{\"name\": \"overview\", \"kind\": \"content\", "
      "\"sectionId\": \"A00-OVR\"}]},"
      "    \"Beta\": {\"name\": \"Beta\", \"sectionId\": \"B00\","
      "      \"fields\": [{\"name\": \"overview\", \"kind\": \"content\", "
      "\"sectionId\": \"B00-OVR\"}]}"
      "  }"
      "}";
  char *two_err = NULL;
  SpecModel *two_model = spec_model_from_json_str(two_json, &two_err);
  if (two_model == NULL) fatal("SpecModelFromJSON (two roots)");
  SpecDocument doc2;
  spec_document_init(&doc2);
  spec_document_set_content(&doc2, "A00/A00-OVR", "a");
  spec_document_set_content(&doc2, "B00/B00-OVR", "b");
  char *two_md_err = NULL;
  char *two_md = spec_document_to_markdown(&doc2, two_model, "", &two_md_err);
  md_check("toMarkdown.twoRootsThrows.alpha",
           two_md == NULL && two_md_err != NULL &&
               contains(two_md_err, "Alpha"),
           two_md_err ? two_md_err : "(no error)");
  md_check("toMarkdown.twoRootsThrows.beta",
           two_md == NULL && two_md_err != NULL && contains(two_md_err, "Beta"),
           two_md_err ? two_md_err : "(no error)");
  free(two_md);
  free(two_md_err);
  spec_document_free(&doc2);
  spec_model_free(two_model);
}

/* ---- round-trip ---------------------------------------------------------- */

static void test_markdown_round_trip_values(void) {
  SpecModel *m = demo_model();
  SpecDocument src;
  populate_demo_doc(&src);
  char *md = md_export(m, &src);

  SpecDocument target;
  SpecMarkdownResult report;
  md_reload(m, md, &target, &report);

  char *rej = md_rej_str(&report);
  md_check("roundTrip.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("roundTrip.overview",
           strcmp(content_or(&target, "D00/D00-OVR"),
                  "An overview paragraph.\nWith two lines.") == 0,
           NULL);
  md_check("roundTrip.status",
           strcmp(content_or(&target, "D00/D00-ST"), "final") == 0, NULL);
  md_check("roundTrip.author",
           strcmp(form_field_or(&target, "D00/D00-HDR", "author"),
                  "Ada Lovelace") == 0,
           NULL);
  md_check("roundTrip.note",
           strcmp(content_or(&target, "D00/D00-MET/D00-MET-NOTE"), "A note.") ==
               0,
           NULL);

  const SomStrList *items = spec_document_list_items(&target, "D00/D00-ITM");
  size_t items_len = items != NULL ? items->len : 0;
  md_check("roundTrip.itemCount", items_len == 2, NULL);
  if (items_len == 2) {
    char path[128];
    sprintf(path, "%s/D01-LBL", items->items[0]);
    md_check("roundTrip.item1.label",
             strcmp(content_or(&target, path), "First item") == 0, NULL);
    sprintf(path, "%s/D01-BODY", items->items[0]);
    md_check("roundTrip.item1.body",
             strcmp(content_or(&target, path), MD_D4RT_BODY) == 0,
             content_or(&target, path));
    sprintf(path, "%s/D01-LBL", items->items[1]);
    md_check("roundTrip.item2.label",
             strcmp(content_or(&target, path), "Second item") == 0, NULL);
  }

  free(md);
  spec_markdown_result_free(&report);
  spec_document_free(&target);
  spec_document_free(&src);
  spec_model_free(m);
}

static void test_markdown_round_trip_byte_stable(void) {
  SpecModel *m = demo_model();
  SpecDocument src;
  populate_demo_doc(&src);
  char *md1 = md_export(m, &src);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *md2 = md_export(m, &reloaded);
  md_check("roundTrip.byteStable", strcmp(md2, md1) == 0, NULL);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&src);
  spec_model_free(m);
}

static void test_markdown_round_trip_rich_markdown(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-OVR", MD_RICH_MARKDOWN);
  char *md1 = md_export(m, &doc);

  md_check("richMd.fenceShielded",
           contains(md1, "\n# not a heading — shielded by the fence\n"), NULL);
  md_check("richMd.escapedHeading",
           contains(md1, "\n\\# looks like a heading at column 0\n"), NULL);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("richMd.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("richMd.value",
           strcmp(content_or(&reloaded, "D00/D00-OVR"), MD_RICH_MARKDOWN) == 0,
           content_or(&reloaded, "D00/D00-OVR"));
  char *md2 = md_export(m, &reloaded);
  md_check("richMd.byteStable", strcmp(md2, md1) == 0, NULL);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_round_trip_stored_item_id(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  char *item = spec_document_add_list_item_with_section_id(
      &doc, "D00/D00-ITM", "D01-CUSTOM", NULL);
  if (item == NULL) fatal("AddListItemWithSectionID");
  char *lbl = malloc(strlen(item) + 16);
  sprintf(lbl, "%s/D01-LBL", item);
  spec_document_set_content(&doc, lbl, "Custom-id item");
  free(lbl);
  free(item);
  char *md1 = md_export(m, &doc);
  /* YRD3: the stored id IS the md heading id and is
     recovered on parse. */
  md_check("storedId.inMd", contains(md1, "<!--[D01-CUSTOM]-->"), md1);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("storedId.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);

  const SomStrList *items = spec_document_list_items(&reloaded, "D00/D00-ITM");
  size_t items_len = items != NULL ? items->len : 0;
  md_check("storedId.itemCount", items_len == 1, NULL);
  if (items_len == 1) {
    md_check("storedId.sectionId",
             strcmp(item_section_id_or(&reloaded, items->items[0]),
                    "D01-CUSTOM") == 0,
             item_section_id_or(&reloaded, items->items[0]));
    char path[128];
    sprintf(path, "%s/D01-LBL", items->items[0]);
    md_check("storedId.label",
             strcmp(content_or(&reloaded, path), "Custom-id item") == 0, NULL);
  }
  char *md2 = md_export(m, &reloaded);
  md_check("storedId.byteStable", strcmp(md2, md1) == 0, NULL);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_round_trip_label_shaped_continuation(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_form_field(
      &doc, "D00/D00-HDR", "author",
      "Ada Lovelace\nNote: also a mathematician\nplain line");
  char *md1 = md_export(m, &doc);

  md_check("formCont.escaped",
           contains(md1, "\n Note: also a mathematician\n"), md1);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("formCont.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("formCont.value",
           strcmp(form_field_or(&reloaded, "D00/D00-HDR", "author"),
                  "Ada Lovelace\nNote: also a mathematician\nplain line") == 0,
           form_field_or(&reloaded, "D00/D00-HDR", "author"));
  char *md2 = md_export(m, &reloaded);
  md_check("formCont.byteStable", strcmp(md2, md1) == 0, NULL);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* ---- a form section's preamble (SOM §11.4 rule 7) ------------------------ */

static void test_markdown_form_preamble_parses(void) {
  SpecModel *m = demo_model();
  const char *md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-HDR]--> Header\n\n"
      "prose before any field label\n"
      "Author: Ada Lovelace\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("formPre.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  const char *got = staged_content(&report, "D00/D00-HDR");
  md_check("formPre.content",
           got != NULL && strcmp(got, "prose before any field label") == 0,
           got != NULL ? got : "(absent)");
  md_check("formPre.fieldParsed",
           form_matches_single(&report, "D00/D00-HDR", "author",
                               "Ada Lovelace"),
           NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_form_preamble_emits(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-HDR", "why this header exists");
  spec_document_set_form_field(&doc, "D00/D00-HDR", "author", "Ada Lovelace");
  char *md = md_export(m, &doc);
  md_check("formPre.emitOrder",
           contains(md, "why this header exists\n\nAuthor: Ada Lovelace\n"), md);

  free(md);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_form_preamble_only(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-HDR", "nothing filled in yet");
  char *md1 = md_export(m, &doc);
  md_check("formPreOnly.emitted", contains(md1, "nothing filled in yet"), md1);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("formPreOnly.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("formPreOnly.value",
           strcmp(content_or(&reloaded, "D00/D00-HDR"),
                  "nothing filled in yet") == 0,
           content_or(&reloaded, "D00/D00-HDR"));
  char *md2 = md_export(m, &reloaded);
  md_check("formPreOnly.byteStable", strcmp(md2, md1) == 0, md2);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_form_preamble_round_trip(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-HDR",
                            "first paragraph\n\nsecond paragraph");
  spec_document_set_form_field(&doc, "D00/D00-HDR", "author", "Ada Lovelace");
  char *md1 = md_export(m, &doc);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("formPreRT.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("formPreRT.content",
           strcmp(content_or(&reloaded, "D00/D00-HDR"),
                  "first paragraph\n\nsecond paragraph") == 0,
           content_or(&reloaded, "D00/D00-HDR"));
  md_check("formPreRT.field",
           strcmp(form_field_or(&reloaded, "D00/D00-HDR", "author"),
                  "Ada Lovelace") == 0,
           form_field_or(&reloaded, "D00/D00-HDR", "author"));
  char *md2 = md_export(m, &reloaded);
  md_check("formPreRT.byteStable", strcmp(md2, md1) == 0, md2);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

static void test_markdown_form_preamble_label_shaped(void) {
  /* Without the escape the parser would read `Author: …` as the first field
   * label and the line would leave the preamble. */
  SpecModel *m = demo_model();
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "D00/D00-HDR",
                            "Author: is a field of this form");
  spec_document_set_form_field(&doc, "D00/D00-HDR", "author", "Ada Lovelace");
  char *md1 = md_export(m, &doc);
  md_check("formPreLbl.escaped",
           contains(md1, "\n Author: is a field of this form\n"), md1);

  SpecDocument reloaded;
  SpecMarkdownResult report;
  md_reload(m, md1, &reloaded, &report);
  char *rej = md_rej_str(&report);
  md_check("formPreLbl.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("formPreLbl.content",
           strcmp(content_or(&reloaded, "D00/D00-HDR"),
                  "Author: is a field of this form") == 0,
           content_or(&reloaded, "D00/D00-HDR"));
  md_check("formPreLbl.field",
           strcmp(form_field_or(&reloaded, "D00/D00-HDR", "author"),
                  "Ada Lovelace") == 0,
           form_field_or(&reloaded, "D00/D00-HDR", "author"));
  char *md2 = md_export(m, &reloaded);
  md_check("formPreLbl.byteStable", strcmp(md2, md1) == 0, md2);

  free(md1);
  free(md2);
  spec_markdown_result_free(&report);
  spec_document_free(&reloaded);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* ---- parse-rejection protocol (SOM §11.7) -------------------------------- */

/* Reports whether any rejection matches (reason [+ anchor when non-NULL]). */
static int has_rejection(const SpecMarkdownResult *r, const char *reason,
                         const char *anchor) {
  for (size_t i = 0; i < r->rejections_len; i++) {
    const SpecMarkdownRejection *rej = &r->rejections[i];
    if (strcmp(rej->reason, reason) != 0) continue;
    if (anchor != NULL && strcmp(rej->anchor, anchor) != 0) continue;
    return 1;
  }
  return 0;
}

static void test_markdown_reject_unknown_section(void) {
  SpecModel *m = demo_model();
  const char *md =
      "<!-- docspec: demo-document/1.0 -->\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n\n"
      "## <!--[D00-MET]--> Meta\n\n"
      "### <!--[D00-NOPE]--> Bogus\n\n"
      "dropped\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  md_check("reject.unknown.dirty", !spec_markdown_result_is_clean(&report),
           NULL);
  char *rej = md_rej_str(&report);
  md_check("reject.unknown.reason",
           has_rejection(&report, SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
                         "D00-NOPE"),
           rej);
  free(rej);
  const char *kept = staged_content(&report, "D00/D00-OVR");
  md_check("reject.unknown.siblingsKept", kept != NULL && strcmp(kept, "kept") == 0,
           NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_reject_malformed_heading(void) {
  SpecModel *m = demo_model();
  const char *md =
      "<!-- docspec: demo-document/1.0 -->\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## Overview without an id comment\n\n"
      "lost\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("reject.malformed.reason",
           has_rejection(&report, SPEC_MARKDOWN_REJECT_MALFORMED_HEADING, NULL),
           rej);
  free(rej);
  md_check("reject.malformed.noContent", staged_content_len(&report) == 0,
           NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_reject_orphan_preamble(void) {
  SpecModel *m = demo_model();
  const char *md =
      "stray preamble text\n"
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("reject.orphanPreamble.reason",
           has_rejection(&report, SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT, NULL),
           rej);
  free(rej);
  const char *kept = staged_content(&report, "D00/D00-OVR");
  md_check("reject.orphanPreamble.kept",
           kept != NULL && strcmp(kept, "kept") == 0, NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_reject_kind_mismatch(void) {
  SpecModel *m = demo_model();
  const char *md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "kept\n\n"
      "### <!--[D00-MET-NOTE]--> Note\n\n"
      "misplaced\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("reject.kindMismatch.reason",
           has_rejection(&report, SPEC_MARKDOWN_REJECT_KIND_MISMATCH, NULL),
           rej);
  free(rej);
  const char *kept = staged_content(&report, "D00/D00-OVR");
  md_check("reject.kindMismatch.kept",
           kept != NULL && strcmp(kept, "kept") == 0, NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_reject_missing_value(void) {
  SpecModel *m = demo_model();
  const char *md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "## <!--[D00-ST]--> Status\n\n"
      "final\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("reject.missingValue.reason",
           has_rejection(&report, SPEC_MARKDOWN_REJECT_MISSING_VALUE,
                         "D00/D00-OVR"),
           rej);
  free(rej);
  const char *st = staged_content(&report, "D00/D00-ST");
  md_check("reject.missingValue.statusKept",
           st != NULL && strcmp(st, "final") == 0, NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_case_insensitive_labels(void) {
  SpecModel *m = demo_model();
  const char *md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-HDR]--> Header\n\n"
      "author: lower-case label\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("labels.caseInsensitive.clean",
           spec_markdown_result_is_clean(&report), rej);
  free(rej);
  md_check("labels.caseInsensitive.value",
           form_matches_single(&report, "D00/D00-HDR", "author",
                               "lower-case label"),
           NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

static void test_markdown_fence_shielded_headings_stay_body(void) {
  SpecModel *m = demo_model();
  const char *md =
      "# <!--[D00]--> Demo Document\n\n"
      "## <!--[D00-OVR]--> Overview\n\n"
      "```\n"
      "## <!--[D00-ST]--> not a real heading\n"
      "```\n";
  SpecMarkdownResult report;
  md_parse(m, md, &report);

  char *rej = md_rej_str(&report);
  md_check("fenceShield.clean", spec_markdown_result_is_clean(&report), rej);
  free(rej);
  const char *body = staged_content(&report, "D00/D00-OVR");
  md_check("fenceShield.body",
           body != NULL &&
               strcmp(body,
                      "```\n## <!--[D00-ST]--> not a real heading\n```") == 0,
           body ? body : "(absent)");
  md_check("fenceShield.noStatus", staged_content(&report, "D00/D00-ST") == NULL,
           NULL);

  spec_markdown_result_free(&report);
  spec_model_free(m);
}

/* ---- codeSpec (codespecs_mapping.md §9.2, csmc8) ---------------------------------------------- */

/* A stored codeSpec rides inside the heading comment as a ` codeSpec="…"`
 * attribute; untouched sections stay byte-stable (no empty attribute).
 * Mirrors Python test_code_spec_rides_in_headline_comment. */
static void test_markdown_code_spec_rides_in_comment(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  populate_demo_doc(&doc);
  spec_document_set_code_spec(&doc, "D00/D00-OVR",
                              "CsOrder,CsOrder.total,CsOrderRepository");
  char *md = md_export(m, &doc);
  md_check("codeSpec.md.attribute",
           contains(md,
                    "## <!--[D00-OVR] codeSpec=\"CsOrder,CsOrder.total,"
                    "CsOrderRepository\"--> Overview"),
           md);
  md_check("codeSpec.md.untouched",
           contains(md, "## <!--[D00-ST]--> Status"), md);
  free(md);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* The codeSpec attribute parses back out into the result's codeSpecs store.
 * Mirrors Python test_code_spec_parsed_back_out. */
static void test_markdown_code_spec_parsed_back_out(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  populate_demo_doc(&doc);
  spec_document_set_code_spec(&doc, "D00/D00-OVR", "CsOrder,CsOrder.total");
  char *md = md_export(m, &doc);
  SpecMarkdownResult report;
  md_parse(m, md, &report);
  const char *got = som_map_get(&report.staged.code_specs, "D00/D00-OVR");
  md_check("codeSpec.md.parsed",
           got != NULL && strcmp(got, "CsOrder,CsOrder.total") == 0,
           got != NULL ? got : "(null)");
  spec_markdown_result_free(&report);
  free(md);
  spec_document_free(&doc);
  spec_model_free(m);
}

/* A headline + codeSpec together survive parse → load → re-export byte-stably,
 * and the codeSpec lands in the reloaded document.
 * Mirrors Python test_code_spec_and_headline_round_trip_byte_stable. */
static void test_markdown_code_spec_and_headline_byte_stable(void) {
  SpecModel *m = demo_model();
  SpecDocument doc;
  populate_demo_doc(&doc);
  spec_document_set_headline(&doc, "D00/D00-OVR", "Custom Overview");
  spec_document_set_code_spec(&doc, "D00/D00-OVR",
                              "CsOrder,CsOrder.total,CsOrderRepository");
  char *md1 = md_export(m, &doc);
  SpecDocument target;
  SpecMarkdownResult report;
  md_reload(m, md1, &target, &report);
  char *md2 = md_export(m, &target);
  md_check("codeSpec.md.byteStable", strcmp(md2, md1) == 0, md2);
  const char *stored = spec_document_code_spec(&target, "D00/D00-OVR");
  md_check("codeSpec.md.stored",
           stored != NULL &&
               strcmp(stored, "CsOrder,CsOrder.total,CsOrderRepository") == 0,
           stored != NULL ? stored : "(null)");
  free(md2);
  free(md1);
  spec_markdown_result_free(&report);
  spec_document_free(&target);
  spec_document_free(&doc);
  spec_model_free(m);
}

int main(void) {
  test_markdown_export_format();
  test_markdown_export_stored_item_id();
  test_markdown_export_unterm_fence_errors();
  test_markdown_export_undeclared_form_field_errors();
  test_markdown_to_markdown();
  test_markdown_round_trip_values();
  test_markdown_round_trip_byte_stable();
  test_markdown_round_trip_rich_markdown();
  test_markdown_round_trip_stored_item_id();
  test_markdown_round_trip_label_shaped_continuation();
  test_markdown_form_preamble_parses();
  test_markdown_form_preamble_emits();
  test_markdown_form_preamble_only();
  test_markdown_form_preamble_round_trip();
  test_markdown_form_preamble_label_shaped();
  test_markdown_reject_unknown_section();
  test_markdown_reject_malformed_heading();
  test_markdown_reject_orphan_preamble();
  test_markdown_reject_kind_mismatch();
  test_markdown_reject_missing_value();
  test_markdown_case_insensitive_labels();
  test_markdown_fence_shielded_headings_stay_body();
  test_markdown_code_spec_rides_in_comment();
  test_markdown_code_spec_parsed_back_out();
  test_markdown_code_spec_and_headline_byte_stable();

  if (g_failures == 0) {
    printf("spec_document_markdown: all %d checks passed\n", g_checks);
    return 0;
  }
  fprintf(stderr, "spec_document_markdown: %d/%d check(s) failed\n", g_failures,
          g_checks);
  return 1;
}
