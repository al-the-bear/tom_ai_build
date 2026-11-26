/* The rendition's generated parts (`spec_document_markdown_generated.c`, SOM
 * §11.12) through the codec's surface, over the real model: the requirement
 * views written in `derived` blocks at the start of their sections, the
 * headings they force, the option that turns them off, the parser removing a
 * block (and only a closed `derived` block at its place), and the missing
 * value an empty generated place is without its block; then the module's
 * own helpers. Mirrors the Rust runtime's
 * `tests/spec_document_markdown_generated.rs`. */
#include "set_test_support.h"

#include "../src/spec_document_markdown_internal.h"

static const char TRACE_OPEN[] =
    "::: {.derived label=\"Generated from each requirement's traceability; edit "
    "it there\"}";

static char *render_rsp(const RenditionFixture *f, int generated) {
  SpecMarkdownExportOptions o;
  memset(&o, 0, sizeof(o));
  o.file_stem = "links";
  o.no_generated_parts = !generated;
  return render_root(f->model, &f->doc, root_with_id(f->model, "RSP"), &o);
}

/* `md` split into lines (`*out` initialised by the callee). */
static void lines_of(const char *md, SomStrList *out) {
  som_strlist_init(out);
  const char *p = md;
  for (;;) {
    const char *nl = strchr(p, '\n');
    if (nl == NULL) {
      som_strlist_push_copy(out, p);
      return;
    }
    som_strlist_push(out, som_strdup_n(p, (size_t)(nl - p)));
    p = nl + 1;
  }
}

static void generated_tables_on_the_requirements_specification(RenditionFixture *f) {
  char *md = render_rsp(f, 1);
  check("the golden rendition", strcmp(md, rendition_golden(f)) == 0, NULL);
  char want[512];
  snprintf(want, sizeof(want),
           "%s\n| Requirement | Use cases | Screens | Data entities | Tests |\n"
           "| --- | --- | --- | --- | --- |\n",
           TRACE_OPEN);
  check("the traceability matrix", strstr(md, want) != NULL, NULL);
  check("the coverage", strstr(md, "| Requirement | Covered | By |") != NULL, NULL);
  check("the relationships",
        strstr(md, "| Requirement | Dependency | Related requirement |") != NULL, NULL);
  check("no placeholder is left", strchr(md, '\x1f') == NULL, NULL);
  /* The block opens its section, after the heading (and its marker). */
  SomStrList lines;
  lines_of(md, &lines);
  int seen = 0;
  for (size_t i = 2; i < lines.len; i++) {
    if (strcmp(lines.items[i], TRACE_OPEN) == 0) {
      seen = 1;
      check("the block follows its heading",
            strstr(lines.items[i - 2], "<!--[RSP-TRAC]-->") != NULL,
            lines.items[i - 2]);
    }
  }
  check("the block is written", seen, NULL);
  som_strlist_free(&lines);
  check("with generated parts: round trip", round_trips(md, f->model, &f->doc), NULL);
  free(md);
}

static void generated_parts_off(RenditionFixture *f) {
  char *plain = render_rsp(f, 0);
  check("parts off: no block", strstr(plain, "{.derived") == NULL, NULL);
  check("parts off: no forced heading", strstr(plain, "<!--[RSP-TRAC]-->") == NULL,
        NULL);
  check("parts off: round trip", round_trips(plain, f->model, &f->doc), NULL);
  free(plain);
}

static void an_edited_block_is_discarded(RenditionFixture *f) {
  char *md = render_rsp(f, 1);
  char *edited = replace_first(md, "| Requirement | Covered | By |",
                               "| Requirement | Covered |");
  check("edited block: round trip", round_trips(edited, f->model, &f->doc), NULL);
  free(edited);
  free(md);
}

static void a_removed_block_is_a_missing_value(RenditionFixture *f) {
  char *md = render_rsp(f, 1);
  SomStrList lines;
  lines_of(md, &lines);
  size_t i = 0, j = 0;
  while (i < lines.len && strcmp(lines.items[i], TRACE_OPEN) != 0) i++;
  j = i;
  while (j < lines.len && strcmp(lines.items[j], ":::") != 0) j++;
  SomBuf b;
  som_buf_init(&b);
  int first = 1;
  for (size_t k = 0; k < lines.len; k++) {
    if (k >= i && k < j + 2) continue;
    if (!first) som_buf_putc(&b, '\n');
    som_buf_puts(&b, lines.items[k]);
    first = 0;
  }
  char *given = som_buf_take(&b);
  SpecMarkdownImport imp;
  spec_document_from_markdown(given, f->model, &imp);
  const SpecMarkdownResult *r = &imp.result;
  check("a removed block is a missing value",
        r->rejections_len == 1 &&
            strcmp(r->rejections[0].reason, SPEC_MARKDOWN_REJECT_MISSING_VALUE) == 0 &&
            strcmp(r->rejections[0].anchor, "RSP/RSP-TRAC") == 0,
        NULL);
  spec_markdown_import_free(&imp);
  free(given);
  som_strlist_free(&lines);
  free(md);
}

static void only_a_closed_derived_block_is_removed(RenditionFixture *f) {
  char *md = render_rsp(f, 1);
  /* Indented by four spaces the fence opens no block: the lines are the
   * value's, and the traceability matrix holds them. */
  char indented_open[512];
  snprintf(indented_open, sizeof(indented_open), "    %s", TRACE_OPEN);
  char *indented = replace_first(md, TRACE_OPEN, indented_open);
  SpecMarkdownImport imp;
  spec_document_from_markdown(indented, f->model, &imp);
  const char *v = spec_document_content(imp.document, "RSP/RSP-TRAC");
  check("indented lines are the value", v != NULL && strstr(v, "Generated from") != NULL,
        v);
  spec_markdown_import_free(&imp);
  free(indented);
  /* A block of another kind is the value's too. */
  char *other = replace_first(md, TRACE_OPEN, "::: {.derivedX}");
  spec_document_from_markdown(other, f->model, &imp);
  v = spec_document_content(imp.document, "RSP/RSP-TRAC");
  check("a block of another kind is the value", v != NULL && strstr(v, "{.derivedX}") != NULL,
        v);
  spec_markdown_import_free(&imp);
  free(other);
  free(md);
}

static void the_strip_kinds_turn_the_parts_off(RenditionFixture *f) {
  SomStrList d, u, a;
  som_strlist_init(&d);
  som_strlist_init(&u);
  som_strlist_init(&a);
  som_strlist_push_copy(&d, "derived");
  SpecStripOptions o;
  char *err = NULL;
  int ok = spec_strip_options_from_names(&d, &u, &a, 0, 0, &o, &err);
  check("drop derived: options", ok, err);
  free(err);
  SpecDocumentStripOptions extra;
  memset(&extra, 0, sizeof(extra));
  extra.model = f->model;
  extra.root_type = "D04RequirementsSpecification";
  SpecStripResult r;
  spec_document_strip(&f->doc, &o, &extra, &r);
  check("drop derived: no generated block",
        r.readable != NULL && strstr(r.readable, "{.derived") == NULL, NULL);
  spec_strip_result_free(&r);
  som_strlist_free(&d);
  som_strlist_free(&u);
  som_strlist_free(&a);
}

/* ---- the module's helpers ------------------------------------------------ */

static void derived_fences_open_and_close(void) {
  check("opens", spec_mdi_opens_derived("::: {.derived}"), NULL);
  check("opens indented, longer, with a label",
        spec_mdi_opens_derived("   :::: {.derived label=\"x\"}"), NULL);
  check("four spaces open nothing", !spec_mdi_opens_derived("    ::: {.derived}"), NULL);
  check("another kind", !spec_mdi_opens_derived("::: {.derivedX}"), NULL);
  check("two colons", !spec_mdi_opens_derived(":: {.derived}"), NULL);
  check("closes", spec_mdi_closes_derived(":::: {.derived}", "::::"), NULL);
  check("closes longer", spec_mdi_closes_derived("::: {.derived}", ":::::  "), NULL);
  check("shorter does not close", !spec_mdi_closes_derived(":::: {.derived}", ":::"), NULL);
  check("text does not close", !spec_mdi_closes_derived("::: {.derived}", "::: x"), NULL);
}

static void derived_placeholders_resolve_to_the_empty_block_or_go(void) {
  char *kept = spec_mdi_resolve_derived_placeholders(som_strdup(
      "# H\n\n" SPEC_MDI_DERIVED_PLACEHOLDER "\n\n::: {.derived}\nx\n:::\n"));
  check("the placeholder before a derived block",
        strcmp(kept, "# H\n\n::: {.derived}\n:::\n\n::: {.derived}\nx\n:::\n") == 0,
        kept);
  free(kept);
  char *gone = spec_mdi_resolve_derived_placeholders(
      som_strdup("# H\n\n" SPEC_MDI_DERIVED_PLACEHOLDER "\n\nText.\n"));
  check("the placeholder before text goes", strcmp(gone, "# H\n\nText.\n") == 0, gone);
  free(gone);
}

int main(void) {
  derived_fences_open_and_close();
  derived_placeholders_resolve_to_the_empty_block_or_go();
  RenditionFixture f;
  rendition_fixture("generatedTrace", &f);
  generated_tables_on_the_requirements_specification(&f);
  generated_parts_off(&f);
  an_edited_block_is_discarded(&f);
  a_removed_block_is_a_missing_value(&f);
  only_a_closed_derived_block_is_removed(&f);
  the_strip_kinds_turn_the_parts_off(&f);
  rendition_fixture_free(&f);
  return report_done("spec_document_markdown_generated_test") == 0 ? 0 : 1;
}
