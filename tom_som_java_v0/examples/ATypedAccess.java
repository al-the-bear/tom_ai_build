// Sample (a) — TYPED object-model access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites src/TomSomV0.java, meta/, schemas/ and tom_som_build.json).
//
// Demonstrates editing a TomSpecs document through the generated *typed* facade
// `tom_som_java_v0.TomSomV0`: named accessors, nested-section navigation, and
// the typed `SomList` collection. The typed facade is a thin editing surface
// over a generic `SpecDocument` — every typed write lands in the same path-keyed
// store the generic API (sample b) reads, which the closing lines prove.
//
// Compile + run via run_tests.sh, or directly:
//   javac -d build -sourcepath src:../tom_som_java_runtime/src \
//       examples/ATypedAccess.java
//   java -cp build ATypedAccess

import tom_som_runtime.SpecDocument;
import tom_som_java_v0.TomSomV0;

public final class ATypedAccess {
  private ATypedAccess() {}

  public static void main(String[] args) {
    // A typed root over a fresh, empty document. The constructor also runs the
    // §2.2 instantiation-time version check (an unstamped document is editable).
    SpecDocument doc = new SpecDocument();
    TomSomV0.D00SolutionBlueprint pd = new TomSomV0.D00SolutionBlueprint(doc);

    System.out.println("Model version of this typed facade: "
        + pd.objectModelVersion());
    System.out.println("Root path: " + pd.path + "\n");

    // 1) A content leaf directly on the root.
    pd.content("A platform that unifies our fragmented order systems.");

    // 2) Navigate into a nested complex section and edit its own content leaf.
    TomSomV0.CurrentLandscape csa = pd.currentLandscape();
    csa.content("Three legacy systems with no shared customer record.");

    // 3) The typed collection API: append two list items and edit each.
    TomSomV0.CurrentOperationalMetrics m0 = csa.operationalMetrics().add();
    m0.content("Average order turnaround: 4.2 days.");
    TomSomV0.CurrentOperationalMetrics m1 = csa.operationalMetrics().add();
    m1.content("Manual reconciliation: ~12 hours / week.");

    // Read everything back through the typed accessors.
    System.out.println("SBP.content              = " + pd.content());
    System.out.println("SBP.currentLandscape = " + csa.content());
    int len = csa.operationalMetrics().length();
    System.out.println("operationalMetrics.length = " + len);
    for (int i = 0; i < len; i++) {
      System.out.println("  metric[" + i + "] = "
          + csa.operationalMetrics().get(i).content());
    }

    // The typed path is the generic path: the same data is addressable through
    // the generic document API (this is exactly what sample (b) uses).
    System.out.println("\nSame value via the generic path "
        + "(doc.content(\"" + csa.path + "/content\")):");
    System.out.println("  " + doc.content(csa.path + "/content"));
  }
}
