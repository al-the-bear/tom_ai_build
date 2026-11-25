/* Stripped renditions (SOM §11.10): styled-div headings, the readable header
 * and the document strip's checks, over a model nine sections deep — the C
 * port of `tom_som_dart_runtime/test/spec_document_strip_test.dart`. The
 * per-value rules and the corpus documents are the conformance cases of
 * `strip_cases.json`, run by tests/conformance.c.
 *
 * Exit status is the number of failed checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "docspecs_validator.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_document_markdown.h"
#include "spec_document_strip.h"
#include "spec_model.h"
#include "spec_review_annotations.h"

static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

/* A model nine sections deep: `L<n>` holds content `T<n>` and section
 * `L<n+1>`, so `T<n>` stands at depth n + 1. */
static SpecModel *deep_model(void) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, "{\"modelVersion\":1,\"modelVersionLabel\":\"0.1.0+1\","
                   "\"roots\":[{\"type\":\"L1\",\"title\":\"Deep\","
                   "\"sectionId\":\"L1\"}],\"classes\":{");
  for (int n = 1; n <= 9; n++) {
    char cls[1024];
    snprintf(cls, sizeof(cls),
             "%s\"L%d\":{\"name\":\"L%d\",\"sectionId\":\"L%d\",%s"
             "\"fields\":[{\"name\":\"text\",\"kind\":\"content\","
             "\"sectionId\":\"T%d\",\"contentType\":\"text\"}",
             n > 1 ? "," : "", n, n, n,
             n == 1 ? "\"annotations\":[{\"name\":\"Document\",\"arguments\":"
                      "{\"title\":\"Deep\"}},{\"name\":\"SectionId\","
                      "\"arguments\":{\"id\":\"L1\"}}],"
                    : "",
             n);
    som_buf_puts(&b, cls);
    if (n < 9) {
      snprintf(cls, sizeof(cls),
               ",{\"name\":\"next\",\"kind\":\"complex\",\"sectionId\":\"L%d\","
               "\"type\":\"L%d\"}",
               n + 1, n + 1);
      som_buf_puts(&b, cls);
    }
    som_buf_puts(&b, "]}");
  }
  som_buf_puts(&b, "}}");
  char *json = som_buf_take(&b);
  char *err = NULL;
  SpecModel *m = spec_model_from_json_str(json, &err);
  free(json);
  if (m == NULL) {
    fprintf(stderr, "fatal: deep model: %s\n", err != NULL ? err : "?");
    exit(2);
  }
  return m;
}

/* `L1/…/L<n>[/T<n>]`. Owned. */
static char *path_to(int n, int text) {
  SomBuf b;
  som_buf_init(&b);
  for (int k = 1; k <= n; k++) {
    char seg[16];
    snprintf(seg, sizeof(seg), "%sL%d", k > 1 ? "/" : "", k);
    som_buf_puts(&b, seg);
  }
  if (text) {
    char seg[16];
    snprintf(seg, sizeof(seg), "/T%d", n);
    som_buf_puts(&b, seg);
  }
  return som_buf_take(&b);
}

static void set_content(SpecDocument *d, int n, const char *value) {
  char *p = path_to(n, 1);
  spec_document_set_content(d, p, value);
  free(p);
}

static const char *content(const SpecDocument *d, int n) {
  char *p = path_to(n, 1);
  const char *v = spec_document_content(d, p);
  free(p);
  return v != NULL ? v : "";
}

static void deep_document(SpecDocument *d) {
  spec_document_init(d);
  for (int n = 1; n <= 9; n++) {
    char v[64];
    snprintf(v, sizeof(v), "Text %d [an aside]{.aside}.", n);
    set_content(d, n, v);
  }
  char *seven = path_to(7, 0);
  spec_document_set_headline(d, seven, "Seven & <more>\nsecond line");
  free(seven);
  set_content(d, 8,
              "Before.\n\n<div class=\"heading9\" style=\"x\">Not a heading</div>"
              "\n\n\\<div class=\"heading7\" style=\"x\">Escaped once</div>");
}

static char *doc_json(const SpecDocument *d) {
  DocumentJson j;
  spec_document_to_json(d, &j);
  char *s = document_json_to_canonical_json(&j);
  document_json_free(&j);
  return s;
}

static int has_line(const char *md, const char *line) {
  size_t n = strlen(line);
  for (const char *p = md; p != NULL && *p != '\0';) {
    const char *nl = strchr(p, '\n');
    size_t len = nl != NULL ? (size_t)(nl - p) : strlen(p);
    if (len == n && strncmp(p, line, n) == 0) return 1;
    p = nl != NULL ? nl + 1 : NULL;
  }
  return 0;
}

/* Whether `md` reads back as `want` without a rejection. */
static void check_reads_back(const char *name, const char *md,
                             const SpecModel *model, const SpecDocument *want) {
  SpecMarkdownImport back;
  spec_document_from_markdown(md, model, &back);
  char label[256];
  snprintf(label, sizeof(label), "%s: no rejections", name);
  check(label, back.result.rejections_len == 0, NULL);
  char *g = doc_json(back.document);
  char *w = doc_json(want);
  snprintf(label, sizeof(label), "%s: reads back", name);
  check(label, strcmp(g, w) == 0, g);
  free(g);
  free(w);
  spec_markdown_import_free(&back);
}

static void test_heading_divs(const SpecModel *model, const SpecRoot *root) {
  SpecDocument doc;
  deep_document(&doc);
  SpecMarkdownExportOptions mo = {1, NULL};
  SpecMarkdownRendition r;
  char *err = NULL;
  check("divs: export", spec_markdown_export_root_with_options(
                            model, &doc, root, &mo, &r, &err),
        err);
  int deep_hash = 0;
  for (const char *p = r.markdown; p != NULL && *p != '\0';) {
    if (strncmp(p, "#######", 7) == 0) deep_hash = 1;
    const char *nl = strchr(p, '\n');
    p = nl != NULL ? nl + 1 : NULL;
  }
  check("divs: no # heading deeper than 6", !deep_hash, NULL);
  check("divs: level 7 with the title escaped",
        has_line(r.markdown,
                 "<div class=\"heading7\" style=\"margin:1em 0 0.5em;padding-left:"
                 "0.75em;font-weight:bold\"><!--[L7]--> <a id=\"L7\"></a> "
                 "Seven &amp; &lt;more&gt;<br>second line</div>"),
        r.markdown);
  check("divs: level 10 indent", strstr(r.markdown, "<div class=\"heading10\" style="
                                                    "\"margin:1em 0 0.5em;padding-"
                                                    "left:3em;") != NULL,
        NULL);
  check("divs: a div-shaped value line is escaped",
        has_line(r.markdown,
                 "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"),
        NULL);
  check("divs: an escaped one once more",
        has_line(r.markdown,
                 "\\\\<div class=\"heading7\" style=\"x\">Escaped once</div>"),
        NULL);
  /* Every heading is in the map, the div ones included: each line the map
   * names is a heading line of the rendition. */
  int headings = 0, mapped = 0;
  {
    int line = 1;
    size_t at = 0;
    for (const char *p = r.markdown; p != NULL && *p != '\0'; line++) {
      if (strncmp(p, "#", 1) == 0 || strncmp(p, "<div class=\"heading", 19) == 0) {
        if (strstr(p, "<!--[") != NULL) headings++;
        if (at < r.headings_len && r.headings[at].line == line) {
          mapped++;
          at++;
        }
      }
      const char *nl = strchr(p, '\n');
      p = nl != NULL ? nl + 1 : NULL;
    }
  }
  check("divs: the heading map holds the div headings",
        headings > 9 && mapped == headings && (size_t)mapped == r.headings_len,
        NULL);
  check_reads_back("divs", r.markdown, model, &doc);
  spec_markdown_rendition_free(&r);

  char *plain = spec_markdown_export_root(model, &doc, root, &err);
  check("no divs: # headings", strstr(plain, "####### <!--[L7]-->") != NULL &&
                                   strstr(plain, "\n<div class=\"heading7\"") == NULL,
        NULL);
  check("no divs: the value line is still escaped",
        has_line(plain, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"),
        NULL);
  check_reads_back("no divs", plain, model, &doc);
  free(plain);
  spec_document_free(&doc);

  const char *want[6] = {"0.75", "1.5", "2.25", "3", "3.75", "4.5"};
  for (int d = 7; d <= 12; d++) {
    char *got = spec_markdown_heading_div_indent(d);
    check("divs: indent", strcmp(got, want[d - 7]) == 0, got);
    free(got);
  }
  check("divs: a heading6 div is content",
        !spec_markdown_heading_div("<div class=\"heading6\">x</div>", NULL, NULL),
        NULL);
  int level = 0;
  char *inner = NULL;
  check("divs: a heading7 div is a heading",
        spec_markdown_heading_div("<div class=\"heading7\">a &amp;lt;</div>",
                                  &level, &inner) &&
            level == 7 && strcmp(inner, "a &lt;") == 0,
        inner);
  free(inner);
}

static void test_readable(const SpecModel *model) {
  SpecReadableSource source = {"deep.tomspecs.yaml", "r3", "8e1d2a7", 1};
  SpecDocumentStripOptions extra = {model, NULL, NULL, &source};
  SomStrList drop, none;
  som_strlist_init(&drop);
  som_strlist_init(&none);
  som_strlist_push_copy(&drop, "aside");
  SpecStripOptions o;
  char *err = NULL;
  spec_strip_options_from_names(&drop, &none, &none, 0, 1, &o, &err);
  SpecDocument doc;
  deep_document(&doc);
  SpecStripResult r;
  spec_document_strip(&doc, &o, &extra, &r);
  check("readable: no findings", spec_strip_result_ok(&r), NULL);
  check("readable: the header",
        strcmp(r.readable_header,
               "<!-- readable: drop=aside; headings=divs; "
               "of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->") == 0,
        r.readable_header);
  const char *nl = strchr(r.readable, '\n');
  check("readable: the header follows the docspec line",
        strncmp(r.readable, "<!-- docspec: ", 14) == 0 && nl != NULL &&
            strncmp(nl + 1, r.readable_header, strlen(r.readable_header)) == 0,
        r.readable);
  check("readable: divs and no aside",
        strstr(r.readable, "<div class=\"heading8\"") != NULL &&
            strstr(r.readable, "{.aside}") == NULL,
        NULL);
  SpecMarkdownResult parsed;
  spec_markdown_parse(model, r.readable, &parsed);
  check("readable: the parse reads the header",
        parsed.readable_header != NULL &&
            strcmp(parsed.readable_header, r.readable_header) == 0,
        NULL);
  SpecReadableHeader h;
  check("readable: the header parses",
        spec_readable_header_parse(parsed.readable_header, &h), NULL);
  char *again = spec_readable_header_format(&h.options, h.source);
  check("readable: format and parse are inverse",
        strcmp(again, r.readable_header) == 0, again);
  check("readable: the header's switches and source",
        h.options.drop == (1u << spec_strip_kind_index("aside")) &&
            h.options.heading_divs && h.source != NULL && h.source->dirty,
        NULL);
  free(again);
  spec_readable_header_free(&h);
  spec_markdown_result_free(&parsed);
  check_reads_back("readable", r.readable, model, r.document);
  spec_strip_result_free(&r);

  /* The appendix lists the moved prose under its section titles. */
  SpecStripOptions a;
  spec_strip_options_from_names(&none, &none, &drop, 1, 1, &a, &err);
  extra.source = NULL;
  spec_document_strip(&doc, &a, &extra, &r);
  check("appendix: no findings", spec_strip_result_ok(&r), NULL);
  check("appendix: eight entries", r.appendix_len == 8, NULL);
  for (size_t i = 0; i < r.appendix_len; i++) {
    int n = (int)i + 1 + (i >= 7 ? 1 : 0); /* T8 holds no aside */
    char *p = path_to(n, 1);
    check("appendix: numbered in order, one value each",
          r.appendix[i].number == (long long)i + 1 && r.appendix[i].value != NULL &&
              strcmp(r.appendix[i].value->path, p) == 0,
          p);
    free(p);
  }
  const char *notes = strstr(r.readable, SPEC_MARKDOWN_APPENDIX_MARKER "\n");
  check("appendix: after the marker", notes != NULL, NULL);
  if (notes != NULL) {
    notes += strlen(SPEC_MARKDOWN_APPENDIX_MARKER "\n");
    check("appendix: the Notes heading", strncmp(notes, "\n## Notes\n", 10) == 0,
          notes);
    int sections = 0;
    for (const char *q = strstr(notes, "### Text\n"); q != NULL;
         q = strstr(q + 1, "### Text\n")) {
      sections++;
    }
    check("appendix: a section each", sections == 8, NULL);
    check("appendix: the entry with its back link",
          strstr(notes, "<a id=\"note-1\"></a>**[1]** an aside "
                        "[\xe2\x86\xa9](#note-1-ref)") != NULL,
          notes);
  }
  check("appendix: the reference in the value",
        strcmp(content(r.document, 1),
               "Text 1<a id=\"note-1-ref\"></a>[\\[1\\]](#note-1).") == 0,
        content(r.document, 1));
  /* The DocSpecs parse stops at the marker: no Notes section. */
  DocSpecsDocument *dd = docspecs_parse_document(r.readable);
  size_t all = 0;
  const DocSpecsSection **secs = docspecs_document_all_sections(dd, &all);
  int notes_section = 0;
  for (size_t i = 0; i < all; i++) {
    if (strcmp(secs[i]->title, "Notes") == 0) notes_section = 1;
  }
  check("appendix: the validator does not read it", !notes_section, NULL);
  free(secs);
  docspecs_document_free(dd);
  spec_strip_result_free(&r);

  /* A value with a notation error is refused and reported. */
  set_content(&doc, 2, "::: {.aside}\nopen");
  spec_document_strip(&doc, &o, &extra, &r);
  check("refused: not ok", !spec_strip_result_ok(&r), NULL);
  check("refused: one notation finding",
        r.findings_len == 1 && strcmp(r.findings[0].kind, "notation") == 0 &&
            r.findings[0].ref != NULL,
        NULL);
  check("refused: the value is kept",
        strcmp(content(r.document, 2), "::: {.aside}\nopen") == 0, NULL);
  spec_strip_result_free(&r);
  spec_document_free(&doc);

  /* Without a model nothing is rendered or checked. */
  SomStrList all_kinds;
  som_strlist_init(&all_kinds);
  som_strlist_push_copy(&all_kinds, "all");
  SpecStripOptions every;
  spec_strip_options_from_names(&all_kinds, &none, &none, 0, 0, &every, &err);
  deep_document(&doc);
  spec_document_strip(&doc, &every, NULL, &r);
  check("no model: no rendition", r.readable == NULL, NULL);
  check("no model: stripped", strcmp(content(r.document, 1), "Text 1.") == 0,
        content(r.document, 1));
  check("no model: counted",
        r.dropped[spec_strip_kind_index("aside")] == 8, NULL);
  SomStrList report;
  spec_strip_result_report(&r, &report);
  check("no model: the report",
        report.len == 1 &&
            strcmp(report.items[0], "aside: 8 dropped, 0 unmarked, 0 moved") == 0,
        report.len > 0 ? report.items[0] : "none");
  som_strlist_free(&report);
  spec_strip_result_free(&r);
  spec_document_free(&doc);
  som_strlist_free(&all_kinds);
  som_strlist_free(&drop);
  som_strlist_free(&none);
  free(err);
}

static void test_stripped(void) {
  SpecDocument doc;
  spec_document_init(&doc);
  spec_document_set_content(&doc, "L1/T1",
                            "Keep {++this++}.\n\n> \xe2\xac\x86\xef\xb8\x8f **C-1** (Al): ok");
  spec_document_set_headline(&doc, "L1/L2", "Two {--old--}");
  SpecReviewAnnotations ra = spec_review_annotations_make(&doc, NULL);
  SpecDocument *s = spec_review_annotations_stripped(&ra);
  const char *t = spec_document_content(s, "L1/T1");
  const char *h = spec_document_headline(s, "L1/L2");
  check("stripped(): content", t != NULL && strcmp(t, "Keep this.") == 0, t);
  check("stripped(): headlines too", h != NULL && strcmp(h, "Two") == 0, h);
  spec_document_free(s);
  free(s);
  spec_document_free(&doc);
}

int main(void) {
  SpecModel *model = deep_model();
  char *err = NULL;
  const SpecRoot *root = spec_model_root_by_type(model, "L1", &err);
  if (root == NULL) {
    fprintf(stderr, "fatal: root: %s\n", err != NULL ? err : "?");
    return 2;
  }
  test_heading_divs(model, root);
  test_readable(model);
  test_stripped();
  spec_model_free(model);
  if (g_failures == 0) printf("spec_document_strip_test: OK\n");
  return g_failures;
}
