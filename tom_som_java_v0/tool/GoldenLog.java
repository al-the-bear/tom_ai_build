// Cross-language golden-log generator for Java (roadmap item 7b).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Compile with the runtime + typed module on the source path, then run:
//   javac -d build -sourcepath src:../tom_som_java_runtime/src tool/GoldenLog.java
//   java -cp build GoldenLog [samplePath] [outputPath]

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import tom_som_runtime.SpecDocument;
import tom_som_runtime.SomList;
import tom_som_java_v0.TomSomV0.D00SolutionBlueprint;
import tom_som_java_v0.TomSomV0.CurrentOperationalMetric;

public final class GoldenLog {
  static String esc(String s) {
    return s.replace("\\", "\\\\")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t");
  }

  static void die(String msg) {
    System.err.println(msg);
    System.exit(2);
  }

  public static void main(String[] args) throws IOException {
    String sample = args.length > 0 ? args[0]
        : "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
    String output = args.length > 1 ? args[1]
        : "../tom_som_conformance/golden/java.log";

    SpecDocument doc = SpecDocument.fromFile(sample);
    D00SolutionBlueprint sbp = D00SolutionBlueprint.loadFile(sample);

    List<String> out = new ArrayList<>();
    out.add("# TomSpecs SOM golden log — canonical cross-language reading.");
    out.add("# All nine per-language generators must emit byte-identical output.");
    out.add("FORMAT\t1");
    out.add("MODELVERSION\t" + esc(doc.modelVersion()));

    // Generic: content leaves, sorted by path.
    out.add("SECTION\tgeneric-content");
    List<String> contentPaths = new ArrayList<>(doc.contentPaths());
    Collections.sort(contentPaths);
    for (String p : contentPaths) {
      String v = doc.content(p);
      out.add("C\t" + p + "\t" + esc(v == null ? "" : v));
    }

    // Generic: form sections + fields, sorted by path then field.
    out.add("SECTION\tgeneric-forms");
    List<String> formPaths = new ArrayList<>(doc.formPaths());
    Collections.sort(formPaths);
    for (String p : formPaths) {
      List<String> fields = new ArrayList<>(doc.formFieldNames(p));
      Collections.sort(fields);
      for (String f : fields) {
        String v = doc.formField(p, f);
        out.add("F\t" + p + "\t" + f + "\t" + esc(v == null ? "" : v));
      }
    }

    // Generic: list containers + item paths (document order).
    out.add("SECTION\tgeneric-lists");
    List<String> listPaths = new ArrayList<>(doc.listPaths());
    Collections.sort(listPaths);
    for (String p : listPaths) {
      List<String> items = doc.listItems(p);
      out.add("L\t" + p + "\t" + items.size());
      for (String item : items) {
        out.add("I\t" + item);
      }
    }

    // Typed: curated traversal that must agree with the generic reads.
    out.add("SECTION\ttyped");

    typedContent(doc, out, sbp.path, sbp.content());
    typedContent(doc, out, sbp.documentControl().path, sbp.documentControl().content());
    typedContent(doc, out, sbp.introductionAndScope().path, sbp.introductionAndScope().content());
    typedContent(doc, out, sbp.glossaryAndAbbreviations().path, sbp.glossaryAndAbbreviations().content());
    typedContent(doc, out, sbp.stakeholdersAndGovernance().path, sbp.stakeholdersAndGovernance().content());
    typedContent(doc, out, sbp.currentLandscape().path, sbp.currentLandscape().content());
    typedContent(doc, out, sbp.assumptionsConstraintsDependencies().path,
        sbp.assumptionsConstraintsDependencies().content());
    typedContent(doc, out, sbp.targetOperatingModelConcept().path,
        sbp.targetOperatingModelConcept().content());
    typedContent(doc, out, sbp.informationAndDataModel().path, sbp.informationAndDataModel().content());
    typedContent(doc, out, sbp.requirements().path, sbp.requirements().content());
    typedContent(doc, out, sbp.solutionArchitectureAndTechnology().path,
        sbp.solutionArchitectureAndTechnology().content());
    typedContent(doc, out, sbp.securityAndAccessModel().path, sbp.securityAndAccessModel().content());
    typedContent(doc, out, sbp.experienceAndInterfaceDesign().path,
        sbp.experienceAndInterfaceDesign().content());
    typedContent(doc, out, sbp.qualityAndAcceptanceModel().path, sbp.qualityAndAcceptanceModel().content());
    typedContent(doc, out, sbp.deliveryTransitionAndRollout().path,
        sbp.deliveryTransitionAndRollout().content());

    typedContent(doc, out, sbp.introductionAndScope().goals().path,
        sbp.introductionAndScope().goals().content());

    SomList<CurrentOperationalMetric> metrics = sbp.currentLandscape().operationalMetrics();
    List<String> metricItemPaths = doc.listItems(metrics.listPath);
    if (metrics.length() != metricItemPaths.size()) {
      die("TYPED LIST LENGTH MISMATCH at " + metrics.listPath);
    }
    out.add("TL\t" + metrics.listPath + "\t" + metrics.length());
    for (int i = 0; i < metrics.length(); i++) {
      CurrentOperationalMetric elem = metrics.get(i);
      String leaf = elem.path + "/content";
      String generic = doc.content(leaf);
      generic = generic == null ? "" : generic;
      if (!elem.content().equals(generic)) {
        die("TYPED LIST ITEM MISMATCH at " + leaf);
      }
      out.add("TI\t" + leaf + "\t" + esc(elem.content()));
    }

    Path outPath = Paths.get(output);
    if (outPath.getParent() != null) {
      Files.createDirectories(outPath.getParent());
    }
    String body = String.join("\n", out) + "\n";
    Files.write(outPath, body.getBytes(StandardCharsets.UTF_8));
    System.out.println("wrote " + out.size() + " lines to " + output);
  }

  static void typedContent(SpecDocument doc, List<String> out, String nodePath, String value) {
    String leaf = nodePath + "/content";
    String generic = doc.content(leaf);
    generic = generic == null ? "" : generic;
    if (!value.equals(generic)) {
      die("TYPED MISMATCH at " + leaf);
    }
    out.add("T\t" + leaf + "\t" + esc(value));
  }
}
