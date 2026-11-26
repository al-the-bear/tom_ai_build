import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentStrip;
import tom_som_runtime.SpecMarkdownImport;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecStripOptions;
import tom_som_runtime.SpecStripResult;

/**
 * The rendition's navigation ({@code SpecDocumentMarkdownLinked}) through the
 * codec's surface: qualified anchors (SOM §11.2), the {@code linked} marker
 * and its entries in their order (SOM §11.11), the placeholder resolution, the
 * option that turns the marker off, the strip kinds that do, and the parser
 * removing the marker.
 *
 * <p>The shared corpus ({@code link_rendition_cases.json}) pins whole
 * renditions; this test holds the module's behaviour over the corpus's
 * {@code links.meta.json}. Mirrors the Go runtime's
 * spec_document_markdown_linked_test.go. A plain {@code main()} that exits 0
 * on success and 1 on failure.
 */
public final class SpecDocumentMarkdownLinkedTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void ok(String name, boolean condition) {
    if (condition) {
      passed++;
    } else {
      failed.add(name);
    }
  }

  /** A rendition case: its model, its document and the case itself. */
  static final class Fixture {
    final SpecModel model;
    final SpecDocument doc;
    final Map<String, Object> c;

    Fixture(SpecModel model, SpecDocument doc, Map<String, Object> c) {
      this.model = model;
      this.doc = doc;
      this.c = c;
    }

    @SuppressWarnings("unchecked")
    String goldenMarkdown() {
      return (String) ((Map<String, Object>) c.get("expect")).get("markdown");
    }

    /** The section id of the first root the document holds a value under. */
    String rootId() {
      for (SpecRoot r : model.roots) {
        if (r.sectionId != null && !r.sectionId.isEmpty() && doc.hasValuesUnder(r.sectionId)) {
          return r.sectionId;
        }
      }
      throw new IllegalStateException("no root holds a value");
    }
  }

  private static SpecModel realModel;

  @SuppressWarnings("unchecked")
  private static SpecModel modelOf(Map<String, Object> c) throws IOException {
    if (c.get("inline") instanceof Map) {
      return SpecModel.fromJson((Map<String, Object>) c.get("inline"));
    }
    if ("som".equals(c.get("model"))) {
      if (realModel == null) {
        realModel = SpecModel.fromJson(Json.parseObject(new String(
            Files.readAllBytes(Paths.get("../tom_som_dart_v0/meta/spec_model.meta.json")),
            StandardCharsets.UTF_8)));
      }
      return realModel;
    }
    return SpecModel.fromJson(SpecDocumentSetTest.table("links.meta.json"));
  }

  /** The corpus case whose intent names {@code token}. */
  @SuppressWarnings("unchecked")
  static Fixture fixture(String token) throws IOException {
    Map<String, Object> table = SpecDocumentSetTest.table("link_rendition_cases.json");
    for (Object raw : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) raw;
      Object intent = c.get("intent");
      if (intent instanceof List && ((List<Object>) intent).contains(token)) {
        return new Fixture(modelOf(c), SpecDocumentSetTest.stateDocument(c.get("state")), c);
      }
    }
    throw new IllegalStateException("no rendition case with intent " + token);
  }

  /** {@code doc} rendered as root {@code rootId}, file stem {@code links}. */
  static String render(SpecModel model, SpecDocument doc, String rootId, boolean markers,
      boolean generated) {
    SpecRoot root = null;
    for (SpecRoot r : model.roots) {
      if (rootId.equals(r.sectionId)) {
        root = r;
      }
    }
    if (root == null) {
      throw new IllegalStateException("no root " + rootId);
    }
    return new SpecDocumentMarkdown(model, doc, "links", null, false, null, markers, generated)
        .exportRoot(root);
  }

  static String render(Fixture f, String rootId) {
    return render(f.model, f.doc, rootId, true, true);
  }

  /** The marker paragraph right after the heading carrying {@code anchor}, "" when none. */
  private static String markerAfter(String md, String anchor) {
    String[] lines = md.split("\n", -1);
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains("<a id=\"" + anchor + "\"></a>") && lines[i].startsWith("#")) {
        return i + 2 < lines.length && lines[i + 2].endsWith("{.linked}") ? lines[i + 2] : "";
      }
    }
    return "";
  }

  /** Whether {@code md} parses to exactly {@code doc} without a rejection. */
  static boolean roundTrips(String md, SpecModel model, SpecDocument doc) {
    SpecMarkdownImport parsed = SpecDocument.fromMarkdown(md, model);
    return parsed.rejections().isEmpty() && sameDocument(parsed.document, doc);
  }

  static boolean sameDocument(SpecDocument a, SpecDocument b) {
    return Objects.equals(Json.parse(Json.write(a.toJson())), Json.parse(Json.write(b.toJson())));
  }

  private static void entriesOnTheBlueprint() throws IOException {
    Fixture f = fixture("copyOf");
    String md = render(f, "BLU");
    ok("blueprint.golden", md.equals(f.goldenMarkdown()));
    ok("blueprint.copyOf",
        markerAfter(md, "CSUM/CRIT").equals("[Copy of [CRIT](#CRIT), edit it there]{.linked}"));
    ok("blueprint.extractedFrom", markerAfter(md, "REQ-EXPORT/LNK-ITEM-LST")
        .equals("[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}"));
    // An item's entries in the order of SOM §11.11: Also in, Summarised in,
    // Derived from.
    String item = markerAfter(md, "REQ-EXPORT");
    int also = item.indexOf(
        "Also in [DET REQ-EXPORT](links.det.tomspecs.md#REQ-EXPORT), held there except REQ.owner");
    int summarised = item.indexOf("; Summarised in [KEY-1](#KEY-1)");
    int derived = item.indexOf("; Derived from ");
    ok("blueprint.order", also == 1 && summarised > also && derived > summarised);
    ok("blueprint.rootUnmarked", !md.startsWith("[") && markerAfter(md, "BLU").isEmpty());
    // Qualified anchors below an item and in a copy.
    ok("blueprint.itemAnchor", md.contains("<a id=\"REQ-EXPORT/REQD\"></a>"));
    ok("blueprint.copyAnchor", md.contains("<a id=\"CSUM/CRIT\"></a>"));
    ok("blueprint.roundTrip", roundTrips(md, f.model, f.doc));
  }

  private static void markersOff() throws IOException {
    Fixture f = fixture("copyOf");
    String plain = render(f.model, f.doc, "BLU", false, true);
    ok("off.noMarker", !plain.contains("{.linked}"));
    ok("off.anchorsKept", plain.contains("<a id=\"CSUM/CRIT\"></a>"));
    ok("off.roundTrip", roundTrips(plain, f.model, f.doc));
    // A marker deleted by hand is restored on the next export.
    String md = render(f, "BLU");
    SpecDocument parsed = SpecDocument.fromMarkdown(plain, f.model).document;
    ok("off.restored", render(f.model, parsed, "BLU", true, true).equals(md));
    SpecDocumentMarkdown codec = new SpecDocumentMarkdown(f.model, f.doc);
    ok("off.defaults", codec.linkedMarkers && codec.generatedParts);
  }

  private static void handEditDiscarded() throws IOException {
    Fixture f = fixture("copyOf");
    String edited = render(f, "BLU").replace(
        "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
        "[Copy of [X](#X), edit it there]{.linked}");
    ok("edit.discarded", roundTrips(edited, f.model, f.doc));
  }

  private static void textAfterIsAValue() throws IOException {
    // A paragraph that is more than one `linked` span is the value's, not the
    // marker: it stays content (or is rejected), never silently dropped.
    Fixture f = fixture("copyOf");
    String edited = render(f, "BLU").replace(
        "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
        "[Copy of [CRIT](#CRIT), edit it there]{.linked} and more");
    SpecMarkdownImport parsed = SpecDocument.fromMarkdown(edited, f.model);
    ok("textAfter.kept",
        !(sameDocument(parsed.document, f.doc) && parsed.rejections().isEmpty()));
  }

  private static void emptyMarkerBeforeALinkedValue() throws IOException {
    Fixture f = fixture("emptyMarker");
    String md = render(f, f.rootId());
    ok("empty.marker", md.contains("[]{.linked}\n\n[To be chosen"));
    ok("empty.noPlaceholder", !md.contains("\u0000"));
    ok("empty.roundTrip", roundTrips(md, f.model, f.doc));
  }

  private static void summaryRowIdCell() throws IOException {
    Fixture f = fixture("summaryRowLink");
    String md = render(f, f.rootId());
    ok("summaryRow.golden", md.equals(f.goldenMarkdown()));
    ok("summaryRow.link",
        Pattern.compile("\\| <a id=\"TOP-BETA\"></a>\\[TOP-BETA\\]\\(#TOP-BETA\\) \\|")
            .matcher(md)
            .find());
    ok("summaryRow.roundTrip", roundTrips(md, f.model, f.doc));
  }

  private static void stripKindsTurnTheMarkerOff() throws IOException {
    Fixture f = fixture("copyOf");
    List<List<List<String>>> names = List.of(
        List.of(List.of("linked"), List.of()),
        List.of(List.of(), List.of("linked")));
    for (List<List<String>> n : names) {
      SpecStripOptions o = SpecStripOptions.fromNames(n.get(0), n.get(1), null, false, false);
      SpecStripResult r =
          SpecDocumentStrip.strip(f.doc, o, f.model, null, "Blueprint", "links", null, null);
      ok("strip" + n + ".readable", r.readable != null && !r.readable.isEmpty());
      ok("strip" + n + ".noMarker", r.readable != null && !r.readable.contains("{.linked}"));
    }
    SpecStripOptions o = SpecStripOptions.fromNames(List.of("provenance"), null, null, false, false);
    SpecStripResult r =
        SpecDocumentStrip.strip(f.doc, o, f.model, null, "Blueprint", "links", null, null);
    ok("strip.otherKindKeepsMarker", r.readable != null && r.readable.contains("{.linked}"));
  }

  public static void main(String[] args) throws IOException {
    entriesOnTheBlueprint();
    markersOff();
    handEditDiscarded();
    textAfterIsAValue();
    emptyMarkerBeforeALinkedValue();
    summaryRowIdCell();
    stripKindsTurnTheMarkerOff();
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
