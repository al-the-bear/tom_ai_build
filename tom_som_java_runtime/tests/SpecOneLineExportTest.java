import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecRoot;

/**
 * Dependency-free unit tests for {@link SpecModel#rootByType} and
 * {@link SpecDocument#toMarkdown} (SOM §21). Mirrors the Dart reference
 * groups {@code SpecModel.rootByType (one-line export, SOM §21)} and
 * {@code SpecDocument.toMarkdown (one-line export, SOM §21)}: JUnit is
 * unavailable on the build host, so this is a plain {@code main()} that exits 0
 * on success and 1 on failure — the same shape as {@code SomFacadeTest}.
 */
public final class SpecOneLineExportTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void eq(String name, Object got, Object want) {
    check(name, want == null ? got == null : want.equals(got), got + " != " + want);
  }

  // --- fixtures -----------------------------------------------------------

  private static Map<String, Object> root(String type, String title, String sectionId) {
    Map<String, Object> m = new LinkedHashMap<>();
    m.put("type", type);
    m.put("title", title);
    m.put("sectionId", sectionId);
    return m;
  }

  private static Map<String, Object> field(String name, String kind, String sectionId) {
    Map<String, Object> m = new LinkedHashMap<>();
    m.put("name", name);
    m.put("kind", kind);
    m.put("sectionId", sectionId);
    return m;
  }

  private static Map<String, Object> cls(String name, String sectionId, List<Object> fields) {
    Map<String, Object> m = new LinkedHashMap<>();
    m.put("name", name);
    m.put("sectionId", sectionId);
    m.put("fields", fields);
    return m;
  }

  /** A model with two roots and no populated classes. */
  private static SpecModel twoRootModel() {
    Map<String, Object> j = new LinkedHashMap<>();
    j.put("roots", new ArrayList<Object>(Arrays.asList(
        root("Alpha", "Alpha Doc", "A00"),
        root("Beta", "Beta Doc", "B00"))));
    j.put("classes", new LinkedHashMap<String, Object>());
    return SpecModel.fromJson(j);
  }

  /** A single-root DemoDoc model whose one content field can be populated. */
  private static SpecModel demoModel() {
    Map<String, Object> j = new LinkedHashMap<>();
    j.put("roots", new ArrayList<Object>(Arrays.asList(
        root("DemoDoc", "Demo Document", "D00"))));
    Map<String, Object> classes = new LinkedHashMap<>();
    classes.put("DemoDoc", cls("DemoDoc", "D00", new ArrayList<Object>(Arrays.asList(
        field("overview", "content", "D00-OVR")))));
    j.put("classes", classes);
    return SpecModel.fromJson(j);
  }

  /** A DemoDoc document with a single populated content leaf. */
  private static SpecDocument populatedDemo() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-OVR", "An overview paragraph.");
    return doc;
  }

  /** A two-root model whose Alpha and Beta both carry a content leaf. */
  private static SpecModel twoPopulatedModel() {
    Map<String, Object> j = new LinkedHashMap<>();
    j.put("roots", new ArrayList<Object>(Arrays.asList(
        root("Alpha", "Alpha Doc", "A00"),
        root("Beta", "Beta Doc", "B00"))));
    Map<String, Object> classes = new LinkedHashMap<>();
    classes.put("Alpha", cls("Alpha", "A00", new ArrayList<Object>(Arrays.asList(
        field("overview", "content", "A00-OVR")))));
    classes.put("Beta", cls("Beta", "B00", new ArrayList<Object>(Arrays.asList(
        field("overview", "content", "B00-OVR")))));
    j.put("classes", classes);
    return SpecModel.fromJson(j);
  }

  public static void main(String[] args) {
    // --- SpecModel.rootByType --------------------------------------------
    // returns the root whose type matches.
    SpecModel two = twoRootModel();
    eq("rootByType-alpha-title", two.rootByType("Alpha").title, "Alpha Doc");
    eq("rootByType-beta-sectionId", two.rootByType("Beta").sectionId, "B00");

    // throws naming the missing and available types.
    try {
      two.rootByType("Gamma");
      check("rootByType-missing-throws", false, "did not throw");
    } catch (IllegalArgumentException e) {
      String m = e.getMessage();
      check("rootByType-missing-names-gamma", m.contains("Gamma"), m);
      check("rootByType-missing-names-alpha", m.contains("Alpha"), m);
      check("rootByType-missing-names-beta", m.contains("Beta"), m);
    }

    // --- SpecDocument.toMarkdown -----------------------------------------
    // matches the explicit codec output for an explicit rootType.
    SpecModel model = demoModel();
    SpecDocument doc = populatedDemo();
    String oneLiner = doc.toMarkdown(model, "DemoDoc");
    String explicit =
        new SpecDocumentMarkdown(model, doc).exportRoot(model.rootByType("DemoDoc"));
    eq("toMarkdown-explicit-matches-codec", oneLiner, explicit);

    // defaults to the single populated root when rootType is omitted.
    eq("toMarkdown-default-single-populated",
        doc.toMarkdown(model), doc.toMarkdown(model, "DemoDoc"));

    // throws when no root is populated.
    try {
      new SpecDocument().toMarkdown(demoModel());
      check("toMarkdown-none-throws", false, "did not throw");
    } catch (IllegalStateException e) {
      check("toMarkdown-none-msg", e.getMessage().contains("no populated root"),
          e.getMessage());
    }

    // throws naming the candidates when more than one root is populated.
    SpecModel twoPop = twoPopulatedModel();
    SpecDocument ambiguous = new SpecDocument();
    ambiguous.setContent("A00/A00-OVR", "a");
    ambiguous.setContent("B00/B00-OVR", "b");
    try {
      ambiguous.toMarkdown(twoPop);
      check("toMarkdown-many-throws", false, "did not throw");
    } catch (IllegalStateException e) {
      String m = e.getMessage();
      check("toMarkdown-many-names-alpha", m.contains("Alpha"), m);
      check("toMarkdown-many-names-beta", m.contains("Beta"), m);
    }

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

  private SpecOneLineExportTest() {}
}
