import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecMarkdownRejectReason;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;

/**
 * Tests for the DocSpecs-conform Markdown codec ({@code SpecDocumentMarkdown},
 * SOM §11) — a port of
 * {@code tom_som_go_runtime/tests/spec_document_markdown_test.go} (itself a
 * port of the TypeScript/Python/Dart reference suite).
 *
 * <p>The generated {@code *.md} is a genuine DocSpecs document: line 1 is the
 * {@code <!-- docspec: <schema-id>/<version> -->} declaration, every populated
 * section is a heading of the form {@code ## <!--[SECTION-ID]--> Title},
 * content sections are normal markdown text (no fences), {@code @Form}
 * sections use the plain-text {@code FieldName: value} format, and a list emits
 * its {@code -LST} container heading at the owner's child level, wrapping the
 * numbered item headings one level deeper (SOM §11.2).
 *
 * <p>JUnit is unavailable on the build host, so this is a plain {@code main()}
 * that exits 0 on success and 1 on failure (same shape as SomFacadeTest).
 */
public final class SpecDocumentMarkdownTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void check(String name, boolean condition) {
    check(name, condition, "");
  }

  // --- fixtures (shared shape with the Go item12/markdown tests) -------------

  /**
   * The single-root DemoDoc fixture covering content, enum, {@code @Form}, a
   * complex sub-section, and a list of complex items.
   */
  private static final String DEMO_MODEL_JSON = "{"
      + "\"roots\": ["
      + " {\"type\": \"DemoDoc\", \"title\": \"Demo Document\", \"sectionId\": \"D00\","
      + "  \"description\": \"A demo document.\"}"
      + "],"
      + "\"classes\": {"
      + " \"DemoDoc\": {"
      + "  \"name\": \"DemoDoc\","
      + "  \"sectionId\": \"D00\","
      + "  \"fields\": ["
      + "   {\"name\": \"overview\", \"kind\": \"content\", \"sectionId\": \"D00-OVR\"},"
      + "   {\"name\": \"status\", \"kind\": \"enum\", \"sectionId\": \"D00-ST\","
      + "    \"enumValues\": [\"draft\", \"final\"]},"
      + "   {\"name\": \"header\", \"kind\": \"form\", \"sectionId\": \"D00-HDR\","
      + "    \"formFields\": ["
      + "     {\"name\": \"author\", \"label\": \"Author\", \"type\": \"String\"},"
      + "     {\"name\": \"reviewer\", \"label\": \"Reviewer\", \"type\": \"String\"}"
      + "    ]},"
      + "   {\"name\": \"meta\", \"kind\": \"complex\", \"type\": \"DemoMeta\","
      + "    \"sectionId\": \"D00-MET\"},"
      + "   {\"name\": \"items\", \"kind\": \"list\", \"elementType\": \"DemoItem\","
      + "    \"elementIsComplex\": true, \"sectionId\": \"D00-ITM\"}"
      + "  ]"
      + " },"
      + " \"DemoMeta\": {"
      + "  \"name\": \"DemoMeta\","
      + "  \"sectionId\": \"D00-MET\","
      + "  \"fields\": ["
      + "   {\"name\": \"note\", \"kind\": \"content\", \"sectionId\": \"D00-MET-NOTE\"}"
      + "  ]"
      + " },"
      + " \"DemoItem\": {"
      + "  \"name\": \"DemoItem\","
      + "  \"fields\": ["
      + "   {\"name\": \"label\", \"kind\": \"content\", \"sectionId\": \"D01-LBL\"},"
      + "   {\"name\": \"body\", \"kind\": \"content\", \"sectionId\": \"D01-BODY\"}"
      + "  ]"
      + " }"
      + "}}";

  private static SpecModel demoModel() {
    return SpecModel.fromJson(Json.parseObject(DEMO_MODEL_JSON));
  }

  /**
   * A d4rt-flutter body that is multi-line and embeds a run of three backticks
   * mid-line — must pass through the plain-text body verbatim.
   */
  private static final String D4RT_BODY = "Column(\n"
      + "  children: [\n"
      + "    Text(\"hi\"),\n"
      + "  ],\n"
      + ") // not a fence: ``` still inside the body";

  /**
   * Exercises embedded markdown formatting: emphasis, a bullet list, a fenced
   * code block containing heading-like lines, and a leading {@code #} line at
   * column 0 (which the emitter escapes as {@code \#}).
   */
  private static final String RICH_MARKDOWN = "Intro with **bold** and *italic*.\n"
      + "\n"
      + "- first bullet\n"
      + "- second bullet\n"
      + "\n"
      + "```dart\n"
      + "# not a heading \u2014 shielded by the fence\n"
      + "## also shielded\n"
      + "void main() {}\n"
      + "```\n"
      + "\n"
      + "# looks like a heading at column 0\n"
      + "trailing paragraph";

  /** Mirrors the Go/Dart populatedDemoDoc() helper. */
  private static SpecDocument populatedDemoDoc() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-OVR", "An overview paragraph.\nWith two lines.");
    doc.setContent("D00/D00-ST", "final");
    doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
    doc.setContent("D00/D00-MET/D00-MET-NOTE", "A note.");
    String item = doc.addListItem("D00/D00-ITM");
    doc.setContent(item + "/D01-LBL", "First item");
    doc.setContent(item + "/D01-BODY", D4RT_BODY);
    String item2 = doc.addListItem("D00/D00-ITM");
    doc.setContent(item2 + "/D01-LBL", "Second item");
    return doc;
  }

  // --- helpers ----------------------------------------------------------------

  private static String mdExport(SpecDocument doc) {
    SpecModel model = demoModel();
    return new SpecDocumentMarkdown(model, doc).exportRoot(model.roots.get(0));
  }

  /** Parses {@code md} into a fresh document via the staged-values report. */
  private static Object[] mdReload(String md) {
    SpecDocument target = new SpecDocument();
    SpecMarkdownResult report = new SpecDocumentMarkdown(demoModel(), target).parse(md);
    target.loadJson(report.toLoadJson());
    return new Object[] {target, report};
  }

  private static SpecMarkdownResult mdParse(String md) {
    return new SpecDocumentMarkdown(demoModel(), new SpecDocument()).parse(md);
  }

  private static String rejStr(SpecMarkdownResult report) {
    List<String> parts = new ArrayList<>();
    for (SpecMarkdownRejection r : report.rejections) {
      parts.add(r.toString());
    }
    return String.join("; ", parts);
  }

  private static boolean shallowEqual(Map<String, String> a, Map<String, String> b) {
    if (a == null || b == null) {
      return false;
    }
    if (a.size() != b.size()) {
      return false;
    }
    for (Map.Entry<String, String> e : a.entrySet()) {
      if (!e.getValue().equals(b.get(e.getKey()))) {
        return false;
      }
    }
    return true;
  }

  private static Map<String, String> mapOf(String k, String v) {
    Map<String, String> m = new LinkedHashMap<>();
    m.put(k, v);
    return m;
  }

  private static String or(String s) {
    return s == null ? "" : s;
  }

  // --- export — DocSpecs format (SOM §11) -------------------------------------

  private static void testExportFormat() {
    String md = mdExport(populatedDemoDoc());
    String first = md.split("\n", -1)[0];
    check("export.docspec.prefix", first.startsWith("<!-- docspec: demo-document/"), first);
    check("export.docspec.suffix", first.endsWith("-->"), first);

    check("export.heading.root", md.contains("# <!--[D00]--> Demo Document"));
    check("export.heading.overview", md.contains("## <!--[D00-OVR]--> Overview"));
    check("export.heading.status", md.contains("## <!--[D00-ST]--> Status"));
    check("export.heading.header", md.contains("## <!--[D00-HDR]--> Header"));
    check("export.heading.meta", md.contains("## <!--[D00-MET]--> Meta"));
    check("export.heading.note", md.contains("### <!--[D00-MET-NOTE]--> Note"));

    check("export.content.plain", md.contains("An overview paragraph.\nWith two lines."));
    boolean noFence = true;
    for (String l : md.split("\n", -1)) {
      if (l.startsWith("```")) {
        noFence = false;
      }
    }
    check("export.content.noFence", noFence);
    check("export.content.noFieldAnchor", !md.contains("<!-- field:"));
    check("export.content.noPathHeading", !md.contains("D00/D00-OVR"));

    check("export.form.sparse.author", md.contains("Author: Ada Lovelace"));
    check("export.form.sparse.noReviewer", !md.contains("Reviewer"));

    // The list container heads (SOM §11.2): `D00-ITM` at the owner's child
    // level, its numbered items one level below it, item fields one deeper.
    check("export.item.container", md.contains("## <!--[D00-ITM]--> Items"));
    check("export.item.1", md.contains("### <!--[items-1]--> Demo Item 1"));
    check("export.item.2", md.contains("### <!--[items-2]--> Demo Item 2"));
    check("export.item.label", md.contains("#### <!--[D01-LBL]--> Label"));

    check("export.noSchemaDescription", !md.contains("A demo document."));
  }

  private static void testExportStoredItemId() {
    SpecDocument doc = new SpecDocument();
    String item = doc.addListItem("D00/D00-ITM", "D01-CUSTOM");
    doc.setContent(item + "/D01-LBL", "Custom-id item");
    String md = mdExport(doc);
    // YRD3: the stored id IS the md heading id; only
    // anonymous items fall back to the positional derivation.
    check("export.storedId.container",
        md.contains("## <!--[D00-ITM]--> Items"), md);
    check("export.storedId.heading",
        md.contains("### <!--[D01-CUSTOM]--> Demo Item 1"), md);
    check("export.storedId.noPositional", !md.contains("items-1"), md);
  }

  private static void testExportUntermFenceErrors() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-OVR", "before\n```dart\nnever closed");
    SpecModel model = demoModel();
    boolean raised = false;
    String detail = "no exception";
    try {
      new SpecDocumentMarkdown(model, doc).exportRoot(model.roots.get(0));
    } catch (IllegalStateException e) {
      raised = e.getMessage().contains("unterminated");
      detail = e.getMessage();
    }
    check("export.untermFence.raises", raised, detail);
  }

  // --- SpecDocument.toMarkdown (item 12) --------------------------------------

  private static void testToMarkdown() {
    SpecModel model = demoModel();
    SpecDocument doc = populatedDemoDoc();
    String oneLiner = doc.toMarkdown(model, "DemoDoc");
    String explicit =
        new SpecDocumentMarkdown(model, doc).exportRoot(model.rootByType("DemoDoc"));
    check("toMarkdown.explicitRoot", oneLiner.equals(explicit));
    String def = doc.toMarkdown(model, null);
    check("toMarkdown.defaultRoot", def.equals(oneLiner));

    boolean emptyThrew = false;
    String emptyMsg = "no exception";
    try {
      new SpecDocument().toMarkdown(model, null);
    } catch (IllegalStateException e) {
      emptyThrew = e.getMessage().contains("no populated root");
      emptyMsg = e.getMessage();
    }
    check("toMarkdown.emptyThrows", emptyThrew, emptyMsg);

    SpecModel twoModel = SpecModel.fromJson(Json.parseObject("{"
        + "\"roots\": ["
        + " {\"type\": \"Alpha\", \"title\": \"Alpha Doc\", \"sectionId\": \"A00\"},"
        + " {\"type\": \"Beta\",  \"title\": \"Beta Doc\",  \"sectionId\": \"B00\"}"
        + "],"
        + "\"classes\": {"
        + " \"Alpha\": {\"name\": \"Alpha\", \"sectionId\": \"A00\","
        + "  \"fields\": [{\"name\": \"overview\", \"kind\": \"content\","
        + "   \"sectionId\": \"A00-OVR\"}]},"
        + " \"Beta\": {\"name\": \"Beta\", \"sectionId\": \"B00\","
        + "  \"fields\": [{\"name\": \"overview\", \"kind\": \"content\","
        + "   \"sectionId\": \"B00-OVR\"}]}"
        + "}}"));
    SpecDocument doc2 = new SpecDocument();
    doc2.setContent("A00/A00-OVR", "a");
    doc2.setContent("B00/B00-OVR", "b");
    String twoMsg = "no exception";
    try {
      doc2.toMarkdown(twoModel, null);
    } catch (IllegalStateException e) {
      twoMsg = e.getMessage();
    }
    check("toMarkdown.twoRootsThrows.alpha", twoMsg.contains("Alpha"), twoMsg);
    check("toMarkdown.twoRootsThrows.beta", twoMsg.contains("Beta"), twoMsg);
  }

  // --- round-trip --------------------------------------------------------------

  private static void testRoundTripValues() {
    String md = mdExport(populatedDemoDoc());
    Object[] pair = mdReload(md);
    SpecDocument target = (SpecDocument) pair[0];
    SpecMarkdownResult report = (SpecMarkdownResult) pair[1];
    check("roundTrip.clean", report.isClean(), rejStr(report));
    check("roundTrip.overview",
        "An overview paragraph.\nWith two lines.".equals(target.content("D00/D00-OVR")));
    check("roundTrip.status", "final".equals(target.content("D00/D00-ST")));
    check("roundTrip.author",
        "Ada Lovelace".equals(target.formField("D00/D00-HDR", "author")));
    check("roundTrip.note", "A note.".equals(target.content("D00/D00-MET/D00-MET-NOTE")));
    List<String> items = target.listItems("D00/D00-ITM");
    check("roundTrip.itemCount", items.size() == 2, items.toString());
    if (items.size() == 2) {
      check("roundTrip.item1.label",
          "First item".equals(target.content(items.get(0) + "/D01-LBL")));
      // The embedded d4rt body survives verbatim, backticks and all.
      check("roundTrip.item1.body",
          D4RT_BODY.equals(target.content(items.get(0) + "/D01-BODY")),
          or(target.content(items.get(0) + "/D01-BODY")));
      check("roundTrip.item2.label",
          "Second item".equals(target.content(items.get(1) + "/D01-LBL")));
    }
  }

  private static void testRoundTripByteStable() {
    String md1 = mdExport(populatedDemoDoc());
    SpecDocument reloaded = (SpecDocument) mdReload(md1)[0];
    String md2 = mdExport(reloaded);
    check("roundTrip.byteStable", md2.equals(md1));
  }

  private static void testRoundTripRichMarkdown() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-OVR", RICH_MARKDOWN);
    String md1 = mdExport(doc);
    // Fence-shielded heading-like lines are NOT escaped; the column-0 `#` line
    // outside the fence IS.
    check("richMd.fenceShielded",
        md1.contains("\n# not a heading \u2014 shielded by the fence\n"));
    check("richMd.escapedHeading",
        md1.contains("\n\\# looks like a heading at column 0\n"));

    Object[] pair = mdReload(md1);
    SpecDocument reloaded = (SpecDocument) pair[0];
    SpecMarkdownResult report = (SpecMarkdownResult) pair[1];
    check("richMd.clean", report.isClean(), rejStr(report));
    check("richMd.value", RICH_MARKDOWN.equals(reloaded.content("D00/D00-OVR")),
        or(reloaded.content("D00/D00-OVR")));
    check("richMd.byteStable", mdExport(reloaded).equals(md1));
  }

  private static void testRoundTripStoredItemId() {
    SpecDocument doc = new SpecDocument();
    String item = doc.addListItem("D00/D00-ITM", "D01-CUSTOM");
    doc.setContent(item + "/D01-LBL", "Custom-id item");
    String md1 = mdExport(doc);
    // YRD3: the stored id IS the md heading id and is
    // recovered on parse.
    check("storedId.inMd", md1.contains("<!--[D01-CUSTOM]-->"), md1);
    Object[] pair = mdReload(md1);
    SpecDocument reloaded = (SpecDocument) pair[0];
    SpecMarkdownResult report = (SpecMarkdownResult) pair[1];
    check("storedId.clean", report.isClean(), rejStr(report));
    List<String> items = reloaded.listItems("D00/D00-ITM");
    check("storedId.itemCount", items.size() == 1, items.toString());
    if (items.size() == 1) {
      check("storedId.sectionId",
          "D01-CUSTOM".equals(reloaded.itemSectionId(items.get(0))),
          or(reloaded.itemSectionId(items.get(0))));
      check("storedId.label",
          "Custom-id item".equals(reloaded.content(items.get(0) + "/D01-LBL")));
    }
    check("storedId.byteStable", mdExport(reloaded).equals(md1));
  }

  private static void testRoundTripLabelShapedContinuation() {
    SpecDocument doc = new SpecDocument();
    doc.setFormField("D00/D00-HDR", "author",
        "Ada Lovelace\nNote: also a mathematician\nplain line");
    String md1 = mdExport(doc);
    // The label-shaped continuation is space-escaped on emit.
    check("formCont.escaped", md1.contains("\n Note: also a mathematician\n"), md1);

    Object[] pair = mdReload(md1);
    SpecDocument reloaded = (SpecDocument) pair[0];
    SpecMarkdownResult report = (SpecMarkdownResult) pair[1];
    check("formCont.clean", report.isClean(), rejStr(report));
    check("formCont.value",
        "Ada Lovelace\nNote: also a mathematician\nplain line"
            .equals(reloaded.formField("D00/D00-HDR", "author")),
        or(reloaded.formField("D00/D00-HDR", "author")));
    check("formCont.byteStable", mdExport(reloaded).equals(md1));
  }

  // --- parse-rejection protocol (SOM §11.7) -------------------------------------

  private static void testRejectUnknownSection() {
    // The bogus heading is nested under `meta` (which has no list children);
    // directly under the root any unresolved id would be absorbed by the
    // single-list-child fallback as a stored-id item.
    String md = "<!-- docspec: demo-document/1.0 -->\n"
        + "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-OVR]--> Overview\n\n"
        + "kept\n\n"
        + "## <!--[D00-MET]--> Meta\n\n"
        + "### <!--[D00-NOPE]--> Bogus\n\n"
        + "dropped\n";
    SpecMarkdownResult report = mdParse(md);
    check("reject.unknown.dirty", !report.isClean());
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if ("D00-NOPE".equals(r.anchor)
          && r.reason == SpecMarkdownRejectReason.UNKNOWN_SECTION) {
        found = true;
      }
    }
    check("reject.unknown.reason", found, rejStr(report));
    check("reject.unknown.siblingsKept", "kept".equals(report.content.get("D00/D00-OVR")));
  }

  private static void testRejectMalformedHeading() {
    String md = "<!-- docspec: demo-document/1.0 -->\n"
        + "# <!--[D00]--> Demo Document\n\n"
        + "## Overview without an id comment\n\n"
        + "lost\n";
    SpecMarkdownResult report = mdParse(md);
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if (r.reason == SpecMarkdownRejectReason.MALFORMED_HEADING) {
        found = true;
      }
    }
    check("reject.malformed.reason", found, rejStr(report));
    check("reject.malformed.noContent", report.content.isEmpty(),
        report.content.toString());
  }

  private static void testRejectOrphanPreamble() {
    String md = "stray preamble text\n"
        + "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-OVR]--> Overview\n\n"
        + "kept\n";
    SpecMarkdownResult report = mdParse(md);
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if (r.reason == SpecMarkdownRejectReason.ORPHAN_CONTENT) {
        found = true;
      }
    }
    check("reject.orphanPreamble.reason", found, rejStr(report));
    check("reject.orphanPreamble.kept", "kept".equals(report.content.get("D00/D00-OVR")));
  }

  private static void testRejectOrphanFormProse() {
    String md = "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-HDR]--> Header\n\n"
        + "prose before any field label\n"
        + "Author: Ada Lovelace\n";
    SpecMarkdownResult report = mdParse(md);
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if (r.reason == SpecMarkdownRejectReason.ORPHAN_CONTENT) {
        found = true;
      }
    }
    check("reject.orphanForm.reason", found, rejStr(report));
    // The labelled field still parses.
    check("reject.orphanForm.fieldParsed",
        shallowEqual(report.forms.get("D00/D00-HDR"), mapOf("author", "Ada Lovelace")),
        report.forms.toString());
  }

  private static void testRejectKindMismatch() {
    String md = "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-OVR]--> Overview\n\n"
        + "kept\n\n"
        + "### <!--[D00-MET-NOTE]--> Note\n\n"
        + "misplaced\n";
    SpecMarkdownResult report = mdParse(md);
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if (r.reason == SpecMarkdownRejectReason.KIND_MISMATCH) {
        found = true;
      }
    }
    check("reject.kindMismatch.reason", found, rejStr(report));
    check("reject.kindMismatch.kept", "kept".equals(report.content.get("D00/D00-OVR")));
  }

  private static void testRejectMissingValue() {
    String md = "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-OVR]--> Overview\n\n"
        + "## <!--[D00-ST]--> Status\n\n"
        + "final\n";
    SpecMarkdownResult report = mdParse(md);
    boolean found = false;
    for (SpecMarkdownRejection r : report.rejections) {
      if (r.reason == SpecMarkdownRejectReason.MISSING_VALUE
          && "D00/D00-OVR".equals(r.anchor)) {
        found = true;
      }
    }
    check("reject.missingValue.reason", found, rejStr(report));
    check("reject.missingValue.statusKept", "final".equals(report.content.get("D00/D00-ST")));
  }

  private static void testCaseInsensitiveLabels() {
    String md = "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-HDR]--> Header\n\n"
        + "author: lower-case label\n";
    SpecMarkdownResult report = mdParse(md);
    check("labels.caseInsensitive.clean", report.isClean(), rejStr(report));
    check("labels.caseInsensitive.value",
        shallowEqual(report.forms.get("D00/D00-HDR"), mapOf("author", "lower-case label")),
        report.forms.toString());
  }

  private static void testFenceShieldedHeadingsStayBody() {
    String md = "# <!--[D00]--> Demo Document\n\n"
        + "## <!--[D00-OVR]--> Overview\n\n"
        + "```\n"
        + "## <!--[D00-ST]--> not a real heading\n"
        + "```\n";
    SpecMarkdownResult report = mdParse(md);
    check("fenceShield.clean", report.isClean(), rejStr(report));
    check("fenceShield.body",
        "```\n## <!--[D00-ST]--> not a real heading\n```"
            .equals(report.content.get("D00/D00-OVR")),
        or(report.content.get("D00/D00-OVR")));
    check("fenceShield.noStatus", !report.content.containsKey("D00/D00-ST"));
  }

  // --- csmc8: stored codeSpec rides in the headline comment (§9.2) -----------

  private static void testCodeSpecRidesInHeadlineComment() {
    SpecDocument doc = populatedDemoDoc();
    doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
    String md = mdExport(doc);
    check("codeSpec.md.attribute",
        md.contains("## <!--[D00-OVR] codeSpec=\"CsOrder,CsOrder.total,"
            + "CsOrderRepository\"--> Overview"), md);
    // Untouched sections stay byte-stable (no empty codeSpec attribute).
    check("codeSpec.md.untouched", md.contains("## <!--[D00-ST]--> Status"));
  }

  private static void testCodeSpecParsedBackOut() {
    SpecDocument doc = populatedDemoDoc();
    doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total");
    String md = mdExport(doc);
    SpecMarkdownResult report = mdParse(md);
    check("codeSpec.md.parsed",
        "CsOrder,CsOrder.total".equals(report.codeSpecs.get("D00/D00-OVR")),
        report.codeSpecs.toString());
  }

  private static void testCodeSpecAndHeadlineRoundTripByteStable() {
    SpecDocument doc = populatedDemoDoc();
    doc.setHeadline("D00/D00-OVR", "Custom Overview");
    doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
    String md = mdExport(doc);
    SpecDocument target = (SpecDocument) mdReload(md)[0];
    check("codeSpec.md.byteStable", mdExport(target).equals(md));
    check("codeSpec.md.stored",
        "CsOrder,CsOrder.total,CsOrderRepository".equals(target.codeSpec("D00/D00-OVR")),
        or(target.codeSpec("D00/D00-OVR")));
  }

  public static void main(String[] args) {
    testExportFormat();
    testExportStoredItemId();
    testExportUntermFenceErrors();
    testToMarkdown();
    testRoundTripValues();
    testRoundTripByteStable();
    testRoundTripRichMarkdown();
    testRoundTripStoredItemId();
    testRoundTripLabelShapedContinuation();
    testRejectUnknownSection();
    testRejectMalformedHeading();
    testRejectOrphanPreamble();
    testRejectOrphanFormProse();
    testRejectKindMismatch();
    testRejectMissingValue();
    testCaseInsensitiveLabels();
    testFenceShieldedHeadingsStayBody();
    testCodeSpecRidesInHeadlineComment();
    testCodeSpecParsedBackOut();
    testCodeSpecAndHeadlineRoundTripByteStable();

    int total = passed + failed.size();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + total + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
      return;
    }
    System.out.println("OK: " + total + " checks passed");
  }

  private SpecDocumentMarkdownTest() {}
}
