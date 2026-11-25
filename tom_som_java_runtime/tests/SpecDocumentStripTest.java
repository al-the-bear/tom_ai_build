import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Set;

import tom_som_runtime.DocSpecsDocument;
import tom_som_runtime.DocSpecsSection;
import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentStrip;
import tom_som_runtime.SpecMarkdownImport;
import tom_som_runtime.SpecMarkdownRendition;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReadableHeader;
import tom_som_runtime.SpecReadableSource;
import tom_som_runtime.SpecReviewAnnotations;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecStripFinding;
import tom_som_runtime.SpecStripOptions;
import tom_som_runtime.SpecStripResult;

/**
 * Stripped renditions (SOM §11.10): styled-div headings, the readable header
 * and the document strip's checks, over a model nine sections deep — the Java
 * port of {@code tom_som_dart_runtime/test/spec_document_strip_test.dart}. The
 * per-value rules and the corpus documents are the conformance cases of
 * {@code strip_cases.json}, run by {@code ConformanceRunner}.
 *
 * <p>A plain {@code main()} that exits 0 on success and 1 on failure.
 */
public final class SpecDocumentStripTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail == null || detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void check(String name, boolean condition) {
    check(name, condition, "");
  }

  /**
   * A model nine sections deep: {@code L<n>} holds content {@code T<n>} and
   * section {@code L<n+1>}, so {@code T<n>} stands at depth n + 1.
   */
  private static SpecModel deepModel() {
    StringBuilder b =
        new StringBuilder(
            "{\"modelVersion\":1,\"modelVersionLabel\":\"0.1.0+1\","
                + "\"roots\":[{\"type\":\"L1\",\"title\":\"Deep\",\"sectionId\":\"L1\"}],"
                + "\"classes\":{");
    for (int n = 1; n <= 9; n++) {
      if (n > 1) {
        b.append(",");
      }
      b.append("\"L" + n + "\":{\"name\":\"L" + n + "\",\"sectionId\":\"L" + n + "\",");
      if (n == 1) {
        b.append(
            "\"annotations\":[{\"name\":\"Document\",\"arguments\":"
                + "{\"title\":\"Deep\"}},{\"name\":\"SectionId\","
                + "\"arguments\":{\"id\":\"L1\"}}],");
      }
      b.append(
          "\"fields\":[{\"name\":\"text\",\"kind\":\"content\",\"sectionId\":\"T"
              + n
              + "\",\"contentType\":\"text\"}");
      if (n < 9) {
        int m = n + 1;
        b.append(
            ",{\"name\":\"next\",\"kind\":\"complex\",\"sectionId\":\"L"
                + m
                + "\",\"type\":\"L"
                + m
                + "\"}");
      }
      b.append("]}");
    }
    b.append("}}");
    return SpecModel.fromJson(Json.parseObject(b.toString()));
  }

  /** {@code L1/…/L<n>[/T<n>]}. */
  private static String pathTo(int n, boolean text) {
    StringBuilder p = new StringBuilder();
    for (int k = 1; k <= n; k++) {
      if (k > 1) {
        p.append('/');
      }
      p.append('L').append(k);
    }
    if (text) {
      p.append("/T").append(n);
    }
    return p.toString();
  }

  private static SpecDocument deepDocument() {
    SpecDocument d = new SpecDocument();
    for (int n = 1; n <= 9; n++) {
      d.setContent(pathTo(n, true), "Text " + n + " [an aside]{.aside}.");
    }
    d.setHeadline(pathTo(7, false), "Seven & <more>\nsecond line");
    d.setContent(
        pathTo(8, true),
        "Before.\n\n<div class=\"heading9\" style=\"x\">Not a heading</div>"
            + "\n\n\\<div class=\"heading7\" style=\"x\">Escaped once</div>");
    return d;
  }

  private static boolean hasLine(String md, String line) {
    return Arrays.asList(md.split("\n", -1)).contains(line);
  }

  /** Whether {@code md} reads back as {@code want} without a rejection. */
  private static void checkReadsBack(String name, String md, SpecModel model, SpecDocument want) {
    SpecMarkdownImport back = SpecDocument.fromMarkdown(md, model);
    check(name + ": no rejections", back.rejections().isEmpty(), back.rejections().toString());
    check(
        name + ": reads back",
        back.document.toJson().equals(want.toJson()),
        Json.write(back.document.toJson()));
  }

  private static void testHeadingDivs(SpecModel model, SpecRoot root) {
    SpecDocument doc = deepDocument();
    SpecMarkdownRendition r =
        new SpecDocumentMarkdown(model, doc, null, null, true, null).exportRootWithMap(root);
    boolean deepHash = false;
    for (String l : r.markdown.split("\n", -1)) {
      if (l.startsWith("#######")) {
        deepHash = true;
      }
    }
    check("divs: no # heading deeper than 6", !deepHash);
    check(
        "divs: level 7 with the title escaped",
        hasLine(
            r.markdown,
            "<div class=\"heading7\" style=\"margin:1em 0 0.5em;padding-left:"
                + "0.75em;font-weight:bold\"><!--[L7]--> <a id=\"L7\"></a> "
                + "Seven &amp; &lt;more&gt;<br>second line</div>"),
        r.markdown);
    check(
        "divs: level 10 indent",
        r.markdown.contains(
            "<div class=\"heading10\" style=\"margin:1em 0 0.5em;padding-left:3em;"));
    check(
        "divs: a div-shaped value line is escaped",
        hasLine(r.markdown, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
    check(
        "divs: an escaped one once more",
        hasLine(r.markdown, "\\\\<div class=\"heading7\" style=\"x\">Escaped once</div>"));
    // Every heading is in the map, the div ones included.
    int headings = 0;
    int mapped = 0;
    int line = 1;
    for (String l : r.markdown.split("\n", -1)) {
      if ((l.startsWith("#") || l.startsWith("<div class=\"heading")) && l.contains("<!--[")) {
        headings++;
        if (r.headingPaths.containsKey(line)) {
          mapped++;
        }
      }
      line++;
    }
    check(
        "divs: the heading map holds the div headings",
        headings > 9 && mapped == headings && mapped == r.headingPaths.size(),
        headings + "/" + mapped);
    checkReadsBack("divs", r.markdown, model, doc);

    String plain = new SpecDocumentMarkdown(model, doc).exportRoot(root);
    check(
        "no divs: # headings",
        plain.contains("####### <!--[L7]-->") && !plain.contains("\n<div class=\"heading7\""));
    check(
        "no divs: the value line is still escaped",
        hasLine(plain, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
    checkReadsBack("no divs", plain, model, doc);

    String[] want = {"0.75", "1.5", "2.25", "3", "3.75", "4.5"};
    for (int d = 7; d <= 12; d++) {
      String got = SpecDocumentMarkdown.headingDivIndent(d);
      check("divs: indent", got.equals(want[d - 7]), got);
    }
    check(
        "divs: a heading6 div is content",
        SpecDocumentMarkdown.headingDiv("<div class=\"heading6\">x</div>") == null);
    SpecDocumentMarkdown.HeadingDiv h =
        SpecDocumentMarkdown.headingDiv("<div class=\"heading7\">a &amp;lt;</div>");
    check(
        "divs: a heading7 div is a heading",
        h != null && h.level == 7 && h.inner.equals("a &lt;"),
        h == null ? "null" : h.inner);
  }

  private static boolean hasNotes(List<DocSpecsSection> sections) {
    for (DocSpecsSection s : sections) {
      if ("Notes".equals(s.title) || hasNotes(s.children)) {
        return true;
      }
    }
    return false;
  }

  private static void testReadable(SpecModel model) {
    SpecReadableSource source = new SpecReadableSource("deep.tomspecs.yaml", "r3", "8e1d2a7", true);
    SpecStripOptions o =
        SpecStripOptions.fromNames(Arrays.asList("aside"), null, null, false, true);
    SpecDocument doc = deepDocument();
    SpecStripResult r = SpecDocumentStrip.strip(doc, o, model, null, null, null, null, source);
    check("readable: no findings", r.ok(), r.findings.toString());
    check(
        "readable: the header",
        r.readableHeader.equals(
            "<!-- readable: drop=aside; headings=divs; "
                + "of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->"),
        r.readableHeader);
    String readable = r.readable == null ? "" : r.readable;
    String[] lines = readable.split("\n", -1);
    check(
        "readable: the header follows the docspec line",
        lines.length > 1 && lines[0].startsWith("<!-- docspec: ")
            && lines[1].equals(r.readableHeader),
        readable);
    check(
        "readable: divs and no aside",
        readable.contains("<div class=\"heading8\"") && !readable.contains("{.aside}"));
    SpecMarkdownResult parsed = new SpecDocumentMarkdown(model, new SpecDocument()).parse(readable);
    check(
        "readable: the parse reads the header", r.readableHeader.equals(parsed.readableHeader));
    SpecReadableHeader h =
        SpecReadableHeader.parse(parsed.readableHeader == null ? "" : parsed.readableHeader);
    check("readable: the header parses", h != null);
    if (h != null) {
      check(
          "readable: format and parse are inverse",
          h.format().equals(r.readableHeader),
          h.format());
      check(
          "readable: the header's switches and source",
          h.options.drop.equals(Set.of("aside"))
              && h.options.headingDivs
              && h.source != null
              && h.source.dirty);
    }
    checkReadsBack("readable", readable, model, r.document);

    // The appendix lists the moved prose under its section titles.
    SpecStripOptions a =
        SpecStripOptions.fromNames(null, null, Arrays.asList("aside"), true, true);
    r = SpecDocumentStrip.strip(doc, a, model, null, null);
    check("appendix: no findings", r.ok(), r.findings.toString());
    check("appendix: eight entries", r.appendix.size() == 8, String.valueOf(r.appendix.size()));
    for (int i = 0; i < r.appendix.size(); i++) {
      int n = i + 1 + (i >= 7 ? 1 : 0); // T8 holds no aside
      String p = pathTo(n, true);
      check(
          "appendix: numbered in order, one value each",
          r.appendix.get(i).number == i + 1
              && r.appendix.get(i).value != null
              && r.appendix.get(i).value.path.equals(p),
          p);
    }
    String text = r.readable == null ? "" : r.readable;
    String marker = SpecDocumentMarkdown.APPENDIX_MARKER + "\n";
    int at = text.indexOf(marker);
    check("appendix: after the marker", at >= 0);
    if (at >= 0) {
      String notes = text.substring(at + marker.length());
      check("appendix: the Notes heading", notes.startsWith("\n## Notes\n"), notes);
      int sections = 0;
      for (int q = notes.indexOf("### Text\n"); q >= 0; q = notes.indexOf("### Text\n", q + 1)) {
        sections++;
      }
      check("appendix: a section each", sections == 8, String.valueOf(sections));
      check(
          "appendix: the entry with its back link",
          notes.contains("<a id=\"note-1\"></a>**[1]** an aside [↩](#note-1-ref)"),
          notes);
    }
    String first = r.document.content(pathTo(1, true));
    check(
        "appendix: the reference in the value",
        "Text 1<a id=\"note-1-ref\"></a>[\\[1\\]](#note-1).".equals(first),
        first);
    // The DocSpecs parse stops at the marker: no Notes section.
    check(
        "appendix: the validator does not read it",
        !hasNotes(DocSpecsDocument.parse(text).sections));

    // A value with a notation error is refused and reported.
    doc.setContent(pathTo(2, true), "::: {.aside}\nopen");
    r = SpecDocumentStrip.strip(doc, o, model, null, null);
    check("refused: not ok", !r.ok());
    SpecStripFinding f = r.findings.isEmpty() ? null : r.findings.get(0);
    check(
        "refused: one notation finding",
        r.findings.size() == 1 && f.kind.equals("notation") && f.ref != null,
        r.findings.toString());
    check(
        "refused: the value is kept",
        "::: {.aside}\nopen".equals(r.document.content(pathTo(2, true))));

    // Without a model nothing is rendered or checked.
    SpecStripOptions every =
        SpecStripOptions.fromNames(Arrays.asList("all"), null, null, false, false);
    r = SpecDocumentStrip.strip(deepDocument(), every);
    check("no model: no rendition", r.readable == null);
    check(
        "no model: stripped",
        "Text 1.".equals(r.document.content(pathTo(1, true))),
        r.document.content(pathTo(1, true)));
    List<String> report = r.report();
    check(
        "no model: the report",
        report.equals(Arrays.asList("aside: 8 dropped, 0 unmarked, 0 moved")),
        report.toString());
  }

  private static void testStripped() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("L1/T1", "Keep {++this++}.\n\n> ⬆️ **C-1** (Al): ok");
    doc.setHeadline("L1/L2", "Two {--old--}");
    SpecDocument s = new SpecReviewAnnotations(doc).stripped();
    check("stripped(): content", "Keep this.".equals(s.content("L1/T1")), s.content("L1/T1"));
    check("stripped(): headlines too", "Two".equals(s.headline("L1/L2")), s.headline("L1/L2"));
  }

  public static void main(String[] args) {
    SpecModel model = deepModel();
    SpecRoot root = model.rootByType("L1");
    testHeadingDivs(model, root);
    testReadable(model);
    testStripped();

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

  private SpecDocumentStripTest() {}
}
