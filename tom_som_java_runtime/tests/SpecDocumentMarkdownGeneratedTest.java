import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentStrip;
import tom_som_runtime.SpecMarkdownImport;
import tom_som_runtime.SpecMarkdownRejectReason;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecStripOptions;
import tom_som_runtime.SpecStripResult;

/**
 * The rendition's generated parts ({@code SpecDocumentMarkdownGenerated}, SOM
 * §11.12) through the codec's surface, over the real model: the requirement
 * views written in {@code derived} blocks at the start of their sections, the
 * headings they force, the option that turns them off, the parser removing a
 * block (and only a closed {@code derived} block at its place), and the
 * missing value an empty generated place is without its block. Mirrors the Go
 * runtime's spec_document_markdown_generated_test.go. A plain {@code main()}
 * that exits 0 on success and 1 on failure.
 */
public final class SpecDocumentMarkdownGeneratedTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static final String TRACE_OPEN =
      "::: {.derived label=\"Generated from each requirement's traceability; edit it there\"}";

  private static void ok(String name, boolean condition) {
    if (condition) {
      passed++;
    } else {
      failed.add(name);
    }
  }

  private static SpecDocumentMarkdownLinkedTest.Fixture fixture() throws IOException {
    return SpecDocumentMarkdownLinkedTest.fixture("generatedTrace");
  }

  private static String render(SpecDocumentMarkdownLinkedTest.Fixture f) {
    return SpecDocumentMarkdownLinkedTest.render(f, "RSP");
  }

  private static void tablesOnTheRequirementsSpecification() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    String md = render(f);
    ok("tables.golden", md.equals(f.goldenMarkdown()));
    ok("tables.trace", md.contains(TRACE_OPEN
        + "\n| Requirement | Use cases | Screens | Data entities | Tests |\n"
        + "| --- | --- | --- | --- | --- |\n"));
    ok("tables.coverage", md.contains("| Requirement | Covered | By |"));
    ok("tables.relationships", md.contains("| Requirement | Dependency | Related requirement |"));
    ok("tables.noPlaceholder", !md.contains("\u0000"));
    // The block opens its section, after the heading (and its marker).
    String[] lines = md.split("\n", -1);
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].equals(TRACE_OPEN)) {
        ok("tables.opensSection", lines[i - 2].contains("<!--[RSP-TRAC]-->"));
      }
    }
    ok("tables.roundTrip", SpecDocumentMarkdownLinkedTest.roundTrips(md, f.model, f.doc));
  }

  private static void partsOff() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    String plain = SpecDocumentMarkdownLinkedTest.render(f.model, f.doc, "RSP", true, false);
    ok("off.noBlock", !plain.contains("{.derived"));
    ok("off.noForcedHeading", !plain.contains("<!--[RSP-TRAC]-->"));
    ok("off.roundTrip", SpecDocumentMarkdownLinkedTest.roundTrips(plain, f.model, f.doc));
  }

  private static void blockEditedIsDiscarded() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    String edited = render(f).replaceFirst(
        "\\| Requirement \\| Covered \\| By \\|", "| Requirement | Covered |");
    ok("edited.discarded", SpecDocumentMarkdownLinkedTest.roundTrips(edited, f.model, f.doc));
  }

  private static void blockRemovedIsAMissingValue() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    List<String> lines = Arrays.asList(render(f).split("\n", -1));
    int i = lines.indexOf(TRACE_OPEN);
    int j = i;
    while (!lines.get(j).equals(":::")) {
      j++;
    }
    List<String> given = new ArrayList<>(lines.subList(0, i));
    given.addAll(lines.subList(j + 2, lines.size()));
    List<SpecMarkdownRejection> r =
        SpecDocument.fromMarkdown(String.join("\n", given), f.model).rejections();
    ok("removed.missingValue",
        r.size() == 1
            && r.get(0).reason == SpecMarkdownRejectReason.MISSING_VALUE
            && "RSP/RSP-TRAC".equals(r.get(0).anchor));
  }

  private static void onlyAClosedDerivedBlockIsRemoved() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    String md = render(f);
    // Indented by four spaces the fence opens no block: the lines are the
    // value's, and the traceability matrix holds them.
    SpecMarkdownImport parsed = SpecDocument.fromMarkdown(md.replace(TRACE_OPEN, "    " + TRACE_OPEN), f.model);
    String v = parsed.document.content("RSP/RSP-TRAC");
    ok("closed.indented", v != null && v.contains("Generated from"));
    // A block of another kind is the value's too.
    parsed = SpecDocument.fromMarkdown(md.replace(TRACE_OPEN, "::: {.derivedX}"), f.model);
    v = parsed.document.content("RSP/RSP-TRAC");
    ok("closed.otherKind", v != null && v.contains("{.derivedX}"));
  }

  private static void stripKindsTurnThePartsOff() throws IOException {
    SpecDocumentMarkdownLinkedTest.Fixture f = fixture();
    SpecStripOptions o = SpecStripOptions.fromNames(List.of("derived"), null, null, false, false);
    SpecStripResult r = SpecDocumentStrip.strip(f.doc, o, f.model, null, "D04RequirementsSpecification");
    ok("strip.readable", r.readable != null && !r.readable.isEmpty());
    ok("strip.noBlock", r.readable != null && !r.readable.contains("{.derived"));
  }

  public static void main(String[] args) throws IOException {
    tablesOnTheRequirementsSpecification();
    partsOff();
    blockEditedIsDiscarded();
    blockRemovedIsAMissingValue();
    onlyAClosedDerivedBlockIsRemoved();
    stripKindsTurnThePartsOff();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + (passed + failed.size()) + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
    }
    System.out.println("OK: " + passed + " checks passed");
  }
}
