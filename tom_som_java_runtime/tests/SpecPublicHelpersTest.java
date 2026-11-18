import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.CodeSpecsExtract;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;

/**
 * The helpers the TypeScript runtime exports, called from outside the package
 * (so they must be public): {@code SpecDocumentYaml.writeHeader},
 * {@code SpecDocumentMarkdown.codeSpecOf} / {@code unitsOf} and
 * {@code CodeSpecsExtract.codeSpecsYamlString}. The expected values are the
 * TypeScript runtime's output for the same inputs. A plain {@code main()} that
 * exits 0 on success and 1 on failure.
 */
public final class SpecPublicHelpersTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, String got, String want) {
    if (got.equals(want)) {
      passed++;
    } else {
      failed.add(name + ": expected <" + want + ">, got <" + got + ">");
    }
  }

  public static void main(String[] args) {
    StringBuilder b = new StringBuilder();
    SpecDocumentYaml.writeHeader(b, "1.2.3");
    SpecDocumentYaml.writeHeader(b, "");
    eq("writeHeader", b.toString(),
        "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\nversion: 2\n"
            + "modelVersion: \"1.2.3\"\n"
            + "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\nversion: 2\n");

    eq("codeSpecOf", SpecDocumentMarkdown.codeSpecOf("sectionId=\"X\" codeSpec=\" a,b \""), "a,b");
    eq("codeSpecOf absent", SpecDocumentMarkdown.codeSpecOf("sectionId=\"X\""), "");
    eq("unitsOf", SpecDocumentMarkdown.unitsOf("units='server,web'"), "server,web");
    eq("unitsOf absent", SpecDocumentMarkdown.unitsOf("codeSpec=\"units=x\""), "");

    eq("codeSpecsYamlString",
        CodeSpecsExtract.codeSpecsYamlString("a\"b\né😀"),
        "\"a\\\"b\\né😀\"");

    if (failed.isEmpty()) {
      System.out.println("SpecPublicHelpersTest: all " + passed + " checks passed.");
      System.exit(0);
    }
    System.err.println("SpecPublicHelpersTest: " + failed.size() + " FAILED (of "
        + (passed + failed.size()) + "):");
    for (String f : failed) {
      System.err.println("  - " + f);
    }
    System.exit(1);
  }
}
