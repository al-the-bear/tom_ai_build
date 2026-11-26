/* The rendition's navigation (`spec_document_markdown_linked.c`) through the
 * codec's surface: qualified anchors (SOM §11.2), the `linked` marker and its
 * entries in their order (SOM §11.11), the placeholder resolution, the option
 * that turns the marker off, the strip kinds that do, the file stem and
 * document files of cross-document links, and the parser removing the marker;
 * then the module's own helpers.
 *
 * The shared corpus (`link_rendition_cases.json`) pins whole renditions;
 * these tests hold the module's behaviour over the corpus's
 * `links.meta.json`. Mirrors the Rust runtime's
 * `tests/spec_document_markdown_linked.rs`. */
#include "set_test_support.h"

#include "../src/spec_document_markdown_internal.h"

/* The marker paragraph written right after the heading carrying `anchor`,
 * "" when none follows it. Owned. */
static char *marker_after(const char *md, const char *anchor) {
  char needle[512];
  snprintf(needle, sizeof(needle), "<a id=\"%s\"></a>", anchor);
  const char *p = md;
  while (*p != '\0') {
    const char *nl = strchr(p, '\n');
    size_t len = nl != NULL ? (size_t)(nl - p) : strlen(p);
    char *line = som_strdup_n(p, len);
    int heading = line[0] == '#' && strstr(line, needle) != NULL;
    free(line);
    if (heading && nl != NULL && nl[1] == '\n') {
      const char *m = nl + 2;
      const char *mend = strchr(m, '\n');
      size_t ml = mend != NULL ? (size_t)(mend - m) : strlen(m);
      static const char tail[] = "{.linked}";
      if (ml >= sizeof(tail) - 1 && memcmp(m + ml - (sizeof(tail) - 1), tail,
                                           sizeof(tail) - 1) == 0) {
        return som_strdup_n(m, ml);
      }
      return som_strdup("");
    }
    if (nl == NULL) break;
    p = nl + 1;
  }
  return som_strdup("");
}

static void check_marker(const char *md, const char *anchor, const char *want) {
  char *got = marker_after(md, anchor);
  char name[256];
  snprintf(name, sizeof(name), "marker after %s", anchor);
  check(name, strcmp(got, want) == 0, got);
  free(got);
}

static void marker_entries_on_the_blueprint(void) {
  RenditionFixture f;
  rendition_fixture("copyOf", &f);
  char *md = render_root(f.model, &f.doc, root_with_id(f.model, "BLU"), NULL);
  check("blueprint: the golden rendition", strcmp(md, rendition_golden(&f)) == 0,
        NULL);
  check_marker(md, "CSUM/CRIT", "[Copy of [CRIT](#CRIT), edit it there]{.linked}");
  check_marker(md, "REQ-EXPORT/LNK-ITEM-LST",
               "[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}");
  /* An item's entries in the order of SOM §11.11: Also in, Summarised in,
   * Derived from. */
  char *item = marker_after(md, "REQ-EXPORT");
  const char *also = strstr(item,
                            "Also in [DET REQ-EXPORT](links.det.tomspecs.md#REQ-"
                            "EXPORT), held there except REQ.owner");
  const char *summarised = strstr(item, "; Summarised in [KEY-1](#KEY-1)");
  const char *derived = strstr(item, "; Derived from ");
  check("item marker order",
        also == item + 1 && summarised > also && derived > summarised, item);
  free(item);
  char *root_marker = marker_after(md, "BLU");
  check("the root carries no marker", md[0] != '[' && root_marker[0] == '\0', NULL);
  free(root_marker);
  check("anchor below an item", strstr(md, "<a id=\"REQ-EXPORT/REQD\"></a>") != NULL,
        NULL);
  check("anchor in a copy", strstr(md, "<a id=\"CSUM/CRIT\"></a>") != NULL, NULL);
  check("with markers: round trip", round_trips(md, f.model, &f.doc), NULL);
  free(md);
  rendition_fixture_free(&f);
}

static void markers_off(void) {
  RenditionFixture f;
  rendition_fixture("copyOf", &f);
  const SpecRoot *blu = root_with_id(f.model, "BLU");
  SpecMarkdownExportOptions o;
  memset(&o, 0, sizeof(o));
  o.file_stem = "links";
  o.no_linked_markers = 1;
  char *without = render_root(f.model, &f.doc, blu, &o);
  check("markers off: no marker", strstr(without, "{.linked}") == NULL, NULL);
  check("markers off: the anchors stay",
        strstr(without, "<a id=\"CSUM/CRIT\"></a>") != NULL, NULL);
  check("markers off: round trip", round_trips(without, f.model, &f.doc), NULL);
  /* A marker deleted by hand is restored on the next export. */
  char *md = render_root(f.model, &f.doc, blu, NULL);
  SpecMarkdownImport imp;
  spec_document_from_markdown(without, f.model, &imp);
  char *again = render_root(f.model, imp.document, blu, NULL);
  check("markers off: restored on the next export", strcmp(again, md) == 0, NULL);
  free(again);
  spec_markdown_import_free(&imp);
  free(md);
  free(without);
  rendition_fixture_free(&f);
}

static void a_hand_edited_marker_is_discarded(void) {
  RenditionFixture f;
  rendition_fixture("copyOf", &f);
  char *md = render_root(f.model, &f.doc, root_with_id(f.model, "BLU"), NULL);
  char *edited = replace_first(md, "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
                               "[Copy of [X](#X), edit it there]{.linked}");
  check("edited marker: round trip", round_trips(edited, f.model, &f.doc), NULL);
  free(edited);
  free(md);
  rendition_fixture_free(&f);
}

static void text_after_the_marker_is_a_value(void) {
  /* A paragraph that is more than one `linked` span is the value's, not the
   * marker: it stays content (and the copy's form has no content, so it is
   * rejected rather than silently dropped). */
  RenditionFixture f;
  rendition_fixture("copyOf", &f);
  char *md = render_root(f.model, &f.doc, root_with_id(f.model, "BLU"), NULL);
  char *edited =
      replace_first(md, "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
                    "[Copy of [CRIT](#CRIT), edit it there]{.linked} and more");
  SpecMarkdownImport imp;
  spec_document_from_markdown(edited, f.model, &imp);
  int same = same_doc(imp.document, &f.doc);
  check("text beside the marker is not dropped",
        !same || imp.result.rejections_len > 0, NULL);
  spec_markdown_import_free(&imp);
  free(edited);
  free(md);
  rendition_fixture_free(&f);
}

static void the_empty_marker_before_a_linked_value(void) {
  RenditionFixture f;
  rendition_fixture("emptyMarker", &f);
  char *md = render_root(f.model, &f.doc, populated_root(f.model, &f.doc), NULL);
  check("the empty marker before the linked value",
        strstr(md, "[]{.linked}\n\n[To be chosen") != NULL, md);
  check("no placeholder is left", strchr(md, '\x1f') == NULL, NULL);
  check("empty marker: round trip", round_trips(md, f.model, &f.doc), NULL);
  free(md);
  rendition_fixture_free(&f);
}

static void a_summary_row_links_its_detail_element(void) {
  RenditionFixture f;
  rendition_fixture("summaryRowLink", &f);
  char *md = render_root(f.model, &f.doc, populated_root(f.model, &f.doc), NULL);
  check("summary rows: the golden rendition", strcmp(md, rendition_golden(&f)) == 0,
        NULL);
  check("the summary row's Id cell is a link",
        strstr(md, "| <a id=\"TOP-BETA\"></a>[TOP-BETA](#TOP-BETA) |") != NULL, NULL);
  check("summary rows: round trip", round_trips(md, f.model, &f.doc), NULL);
  free(md);
  rendition_fixture_free(&f);
}

static void the_file_stem_and_document_files(void) {
  RenditionFixture f;
  rendition_fixture("dangling", &f);
  const SpecRoot *root = populated_root(f.model, &f.doc);
  char *stem = render_root(f.model, &f.doc, root, NULL);
  check("the file stem names the file",
        strstr(stem, "](links.blu.tomspecs.md#REQ-PRESETS)") != NULL, NULL);
  SpecMarkdownExportOptions o;
  memset(&o, 0, sizeof(o));
  char *bare = render_root(f.model, &f.doc, root, &o);
  check("without a stem", strstr(bare, "](blu.tomspecs.md#REQ-PRESETS)") != NULL,
        NULL);
  SomMap files;
  som_map_init(&files);
  som_map_set(&files, "BLU", "blueprint.md");
  o.file_stem = "links";
  o.document_files = &files;
  char *mapped = render_root(f.model, &f.doc, root, &o);
  check("the document files win",
        strstr(mapped, "](blueprint.md#REQ-PRESETS)") != NULL, NULL);
  check("mapped files: round trip", round_trips(mapped, f.model, &f.doc), NULL);
  som_map_free(&files);
  free(mapped);
  free(bare);
  free(stem);
  rendition_fixture_free(&f);
}

static void strip_with(const RenditionFixture *f, const char *drop,
                       const char *unmark, SpecStripResult *out) {
  SomStrList d, u, a;
  som_strlist_init(&d);
  som_strlist_init(&u);
  som_strlist_init(&a);
  if (drop != NULL) som_strlist_push_copy(&d, drop);
  if (unmark != NULL) som_strlist_push_copy(&u, unmark);
  SpecStripOptions o;
  char *err = NULL;
  if (!spec_strip_options_from_names(&d, &u, &a, 0, 0, &o, &err)) {
    fprintf(stderr, "fatal: options: %s\n", err != NULL ? err : "");
    exit(2);
  }
  SpecDocumentStripOptions extra;
  memset(&extra, 0, sizeof(extra));
  extra.model = f->model;
  extra.root_type = "Blueprint";
  extra.file_stem = "links";
  spec_document_strip(&f->doc, &o, &extra, out);
  som_strlist_free(&d);
  som_strlist_free(&u);
  som_strlist_free(&a);
}

static void the_strip_kinds_turn_the_marker_off(void) {
  RenditionFixture f;
  rendition_fixture("copyOf", &f);
  for (int k = 0; k < 2; k++) {
    SpecStripResult r;
    strip_with(&f, k == 0 ? "linked" : NULL, k == 1 ? "linked" : NULL, &r);
    check(k == 0 ? "drop linked: a readable rendition" : "unmark linked: a readable rendition",
          r.readable != NULL, NULL);
    check(k == 0 ? "drop linked: no marker" : "unmark linked: no marker",
          r.readable != NULL && strstr(r.readable, "{.linked}") == NULL, NULL);
    spec_strip_result_free(&r);
  }
  SpecStripResult r;
  strip_with(&f, "provenance", NULL, &r);
  check("dropping another kind keeps the marker",
        r.readable != NULL && strstr(r.readable, "{.linked}") != NULL, NULL);
  spec_strip_result_free(&r);
  rendition_fixture_free(&f);
}

/* ---- the module's helpers ------------------------------------------------ */

static void a_linked_paragraph_is_one_linked_span(void) {
  check("linked paragraph", spec_mdi_is_linked_paragraph("[Also in [X](#X), held here]{.linked}"), NULL);
  check("the empty marker", spec_mdi_is_linked_paragraph("[]{.linked}"), NULL);
  check("another kind", !spec_mdi_is_linked_paragraph("[a]{.aside}"), NULL);
  check("text before the span", !spec_mdi_is_linked_paragraph("text [a]{.linked}"), NULL);
  check("two spans", !spec_mdi_is_linked_paragraph("[a]{.linked} [b]{.linked}"), NULL);
}

static void placeholders_resolve_to_the_empty_marker_or_go(void) {
  char *kept = spec_mdi_resolve_linked_placeholders(
      som_strdup("# H\n\n" SPEC_MDI_LINKED_PLACEHOLDER "\n\n[x]{.linked}\n"));
  check("the placeholder before a linked value",
        strcmp(kept, "# H\n\n[]{.linked}\n\n[x]{.linked}\n") == 0, kept);
  free(kept);
  char *gone = spec_mdi_resolve_linked_placeholders(
      som_strdup("# H\n\n" SPEC_MDI_LINKED_PLACEHOLDER "\n\nText.\n"));
  check("the placeholder before text goes", strcmp(gone, "# H\n\nText.\n") == 0, gone);
  free(gone);
  char *none = spec_mdi_resolve_linked_placeholders(som_strdup("# H\n"));
  check("a rendition without placeholders", strcmp(none, "# H\n") == 0, none);
  free(none);
}

int main(void) {
  marker_entries_on_the_blueprint();
  markers_off();
  a_hand_edited_marker_is_discarded();
  text_after_the_marker_is_a_value();
  the_empty_marker_before_a_linked_value();
  a_summary_row_links_its_detail_element();
  the_file_stem_and_document_files();
  the_strip_kinds_turn_the_marker_off();
  a_linked_paragraph_is_one_linked_span();
  placeholders_resolve_to_the_empty_marker_or_go();
  return report_done("spec_document_markdown_linked_test") == 0 ? 0 : 1;
}
