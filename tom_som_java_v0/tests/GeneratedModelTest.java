// HAND-AUTHORED behavioural test for the **actually-committed** generated Java
// typed model — preserved across `generate_som` runs (the generator only
// rewrites src/TomSomV0.java, meta/, schemas/ and tom_som_build.json).
//
// Unlike the runtime's ConformanceRunner — which exercises the small emitter
// golden fixture — this suite uses the real, full `tom_som_java_v0.TomSomV0`
// (3000+ nested classes) against the generic `tom_som_runtime` and proves the
// typed facade is a faithful editing surface over the shared document (spec §3):
//
//   * the real module compiles + loads against the runtime;
//   * the ProjectDefinition root is anchored at the `PD` segment;
//   * a content leaf round-trips typed -> generic and generic -> typed;
//   * a nested complex section derives its path under the root;
//   * the typed SomList collection parity (add / length / get) lands in the
//     same generic store;
//   * the generated model-version accessor returns `0.0`;
//   * the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp.
//
// Zero external deps: a plain `main()` that exits 0 on success (no JUnit), run
// by `run_tests.sh`.

import tom_som_runtime.SomVersionError;
import tom_som_runtime.SpecDocument;
import tom_som_java_v0.TomSomV0;

public final class GeneratedModelTest {
  private GeneratedModelTest() {}

  private static int passed = 0;
  private static final java.util.List<String> failures = new java.util.ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failures.add(detail.isEmpty() ? name : name + ": " + detail);
    }
  }

  private static void check(String name, boolean condition) {
    check(name, condition, "");
  }

  private static void testRootAndParity() {
    SpecDocument doc = new SpecDocument();
    TomSomV0.ProjectDefinition pd = new TomSomV0.ProjectDefinition(doc);

    check("root.segment", pd.path.equals("PD"), pd.path);

    // Typed write -> generic read.
    pd.content("A clear vision");
    check("content.typed->generic", "A clear vision".equals(doc.content("PD/content")),
        String.valueOf(doc.content("PD/content")));

    // Generic write -> typed read.
    doc.setContent("PD/content", "Revised vision");
    check("content.generic->typed", "Revised vision".equals(pd.content()), pd.content());

    // Unset leaf reads as empty string.
    check("content.unset-empty",
        new TomSomV0.ProjectDefinition(new SpecDocument()).content().isEmpty());

    // Nested complex section path derivation (camelCase accessor preserved).
    TomSomV0.CurrentStateAnalysis csa = pd.currentStateAnalysis();
    check("nested.path", csa.path.equals("PD/currentStateAnalysis"), csa.path);

    // A generic value under the nested typed node is addressable via the
    // expected literal path (proves typed path == generic path).
    String headerPath = pd.header().path;
    doc.setContent(headerPath + "/probe", "x");
    check("nested.typed-path==generic", "x".equals(doc.content("PD/header/probe")));

    // Typed SomList collection parity: append items, read them back, and prove
    // they land in the same generic store under the list segment.
    TomSomV0.CurrentStateAnalysis csa2 = pd.currentStateAnalysis();
    csa2.operationalMetrics().add().content("Average order turnaround: 4.2 days.");
    csa2.operationalMetrics().add().content("Manual reconciliation: ~12h / week.");
    check("list.length", csa2.operationalMetrics().length() == 2,
        String.valueOf(csa2.operationalMetrics().length()));
    check("list.typed-read",
        csa2.operationalMetrics().get(0).content().equals(
            "Average order turnaround: 4.2 days."));
    check("list.generic-count",
        doc.listItemCount("PD/currentStateAnalysis/CUOPME-OPER-LST") == 2);
  }

  private static void testModelVersion() {
    check("version.classattr", TomSomV0.ProjectDefinition.MODEL_VERSION.equals("0.0"),
        TomSomV0.ProjectDefinition.MODEL_VERSION);
    TomSomV0.ProjectDefinition pd = new TomSomV0.ProjectDefinition(new SpecDocument());
    check("version.accessor", pd.objectModelVersion().equals("0.0"),
        pd.objectModelVersion());
  }

  private static void testVersionCheck() {
    // New / equal-stamp document → accepted.
    try {
      new TomSomV0.ProjectDefinition(new SpecDocument());
      new TomSomV0.ProjectDefinition(new SpecDocument(), "0.0");
      check("version.editable", true);
    } catch (SomVersionError e) {
      check("version.editable", false, e.getMessage());
    }

    // Newer minor → rejected.
    try {
      new TomSomV0.ProjectDefinition(new SpecDocument(), "0.1");
      check("version.newer-rejected", false, "expected SomVersionError");
    } catch (SomVersionError e) {
      check("version.newer-rejected", true);
    }

    // Different major → rejected.
    try {
      new TomSomV0.ProjectDefinition(new SpecDocument(), "1.0");
      check("version.cross-major-rejected", false, "expected SomVersionError");
    } catch (SomVersionError e) {
      check("version.cross-major-rejected", true);
    }
  }

  public static void main(String[] args) {
    testRootAndParity();
    testModelVersion();
    testVersionCheck();

    int total = passed + failures.size();
    if (!failures.isEmpty()) {
      System.out.println("FAIL: " + failures.size() + "/" + total + " checks failed");
      for (String f : failures) {
        System.out.println("  - " + f);
      }
      System.exit(1);
    }
    System.out.println("OK: " + total + " checks passed");
  }
}
