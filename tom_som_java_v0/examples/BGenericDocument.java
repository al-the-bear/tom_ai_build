// Sample (b) — GENERIC in-memory document access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs.
//
// Demonstrates editing the *same* document shape as sample (a) using ONLY the
// generic `tom_som_runtime` — string paths, no generated typed classes. This is
// the language-independent core: a sparse, path-keyed store plus the list and
// serialization helpers. Anything the typed facade can express is expressible
// here; the typed facade just makes it type-safe and discoverable.
//
// Compile + run via run_tests.sh, or directly:
//   javac -d build -sourcepath src:../tom_som_java_runtime/src \
//       examples/BGenericDocument.java
//   java -cp build BGenericDocument

import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;

public final class BGenericDocument {
  private BGenericDocument() {}

  public static void main(String[] args) {
    SpecDocument doc = new SpecDocument();

    // Content leaves are addressed by their full path from the root segment.
    doc.setContent("PD/content",
        "A platform that unifies our fragmented order systems.");
    doc.setContent("PD/currentStateAnalysis/content",
        "Three legacy systems with no shared customer record.");

    // A list: append items (each call returns the new item's path), then set a
    // content leaf under each. The list path mirrors the typed facade's
    // `operationalMetrics` accessor (segment `CUOPME-OPER-LST`).
    String listPath = "PD/currentStateAnalysis/CUOPME-OPER-LST";
    String item0 = doc.addListItem(listPath);
    doc.setContent(item0 + "/content", "Average order turnaround: 4.2 days.");
    String item1 = doc.addListItem(listPath);
    doc.setContent(item1 + "/content", "Manual reconciliation: ~12 hours / week.");

    // Read back generically.
    System.out.println("PD/content = " + doc.content("PD/content"));
    System.out.println("list item count = " + doc.listItemCount(listPath));
    for (String itemPath : doc.listItems(listPath)) {
      System.out.println("  " + itemPath + "/content = "
          + doc.content(itemPath + "/content"));
    }

    // The whole document serializes losslessly to JSON …
    System.out.println("\nDocument JSON:");
    System.out.println(Json.writePretty(doc.toJson()));

    // … and to the canonical YAML wire format (stamped with the model version).
    System.out.println("\nDocument YAML:");
    System.out.println(SpecDocumentYaml.encode(doc, "0.0"));
  }
}
