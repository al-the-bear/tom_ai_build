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

import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsValidator;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.SomMetaKind;
import tom_som_runtime.SomMetaNode;
import tom_som_runtime.SomMetaRef;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SomList;
import tom_som_java_v0.TomSomV0.D00SolutionBlueprint;
import tom_som_java_v0.TomSomV0.CurrentOperationalMetric;
import tom_som_java_v0.TomSomV0Meta;

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

    SpecDocument doc = SpecDocument.fromFile(
        sample, TomSomV0Meta.D00SolutionBlueprintMetaTree);
    D00SolutionBlueprint sbp = D00SolutionBlueprint.loadFile(sample);

    List<String> out = new ArrayList<>();
    out.add("# TomSpecs SOM golden log — canonical cross-language reading.");
    out.add("# All nine per-language generators must emit byte-identical output.");
    out.add("FORMAT\t3");
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
        String storedId = doc.itemSectionId(item);
        if (storedId != null) {
          out.add("ID\t" + item + "\t" + esc(storedId));
        }
      }
    }

    // Generic: stored headlines (YRD3), sorted by path.
    out.add("SECTION\tgeneric-headlines");
    List<String> headlinePaths = new ArrayList<>(doc.headlinePaths());
    Collections.sort(headlinePaths);
    for (String p : headlinePaths) {
      String h = doc.headline(p);
      out.add("H\t" + p + "\t" + esc(h == null ? "" : h));
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

    // --- Meta (FORMAT 2): the generated metadata tree read three ways. ---
    SomMetaTree metaTree = TomSomV0Meta.D00SolutionBlueprintMetaTree;

    out.add("SECTION\tmeta");
    metaNode(out, metaTree, "SBP");
    metaNode(out, metaTree, "SBP/documentControl");
    metaNode(out, metaTree, "SBP/documentControl/RVHST-REVS-LST");
    metaNode(out, metaTree, "SBP/introductionAndScope");
    metaNode(out, metaTree, "SBP/introductionAndScope/goals");
    metaNode(out, metaTree, "SBP/introductionAndScope/goals/content");
    metaNode(out, metaTree, "SBP/currentLandscape");
    metaNode(out, metaTree, "SBP/currentLandscape/CUOPME-OPER-LST");
    metaNode(out, metaTree, "SBP/requirements");
    metaNode(out, metaTree, "SBP/requirements/content");

    out.add("SECTION\tmeta-nav");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta, "SBP");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta.documentControl(),
        "SBP/documentControl");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope(),
        "SBP/introductionAndScope");
    metaNav(out, metaTree,
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().goals(),
        "SBP/introductionAndScope/goals");
    metaNav(out, metaTree,
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().goals().content(),
        "SBP/introductionAndScope/goals/content");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta.currentLandscape(),
        "SBP/currentLandscape");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta.requirements(),
        "SBP/requirements");
    metaNav(out, metaTree, TomSomV0Meta.D00SolutionBlueprintMeta.requirements().content(),
        "SBP/requirements/content");

    out.add("SECTION\tmeta-id");
    metaId(out, TomSomV0Meta.SBP, TomSomV0Meta.D00SolutionBlueprintMeta);
    metaId(out, TomSomV0Meta.SBP.RVHST_REVS_LST(),
        TomSomV0Meta.D00SolutionBlueprintMeta.documentControl().revisionHistory());
    metaId(out, TomSomV0Meta.SBP.RVHST_REVS_LST().item(0),
        TomSomV0Meta.D00SolutionBlueprintMeta.documentControl().revisionHistory()
            .item(0));

    out.add("SECTION\tdocspecs");
    String schemaText = new String(Files.readAllBytes(Paths.get(
        "schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml")),
        StandardCharsets.UTF_8);
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(schemaText);
    String sampleMd = new String(Files.readAllBytes(Paths.get(
        "../tom_som_conformance/samples/meridian_order_management.md")),
        StandardCharsets.UTF_8);
    List<DocSpecsViolation> violations = new DocSpecsValidator(schema).validateMarkdown(sampleMd);
    String rootSid = schema.rootSectionId();
    out.add("DS\troot\t" + esc(rootSid == null ? "" : rootSid));
    out.add("DS\twarnings\t" + schema.warnings.size());
    out.add("DS\tviolations\t" + violations.size());
    for (DocSpecsViolation v : violations) {
      out.add("DV\t" + v.rule + "\t" + esc(v.sectionId == null ? "" : v.sectionId) + "\t" + v.line);
    }

    Path outPath = Paths.get(output);
    if (outPath.getParent() != null) {
      Files.createDirectories(outPath.getParent());
    }
    String body = String.join("\n", out) + "\n";
    Files.write(outPath, body.getBytes(StandardCharsets.UTF_8));
    System.out.println("wrote " + out.size() + " lines to " + output);
  }

  /** Maps a native kind constant to the canonical DART enum spelling. */
  static String kindName(String kind) {
    if (SomMetaKind.LIST.equals(kind)) return "list";
    if (SomMetaKind.FORM.equals(kind)) return "form";
    if (SomMetaKind.SECTION.equals(kind)) return "section";
    if (SomMetaKind.CONTENT.equals(kind)) return "content";
    if (SomMetaKind.ENUM_VALUE.equals(kind)) return "enumValue";
    if (SomMetaKind.COMPLEX.equals(kind)) return "complex";
    if (SomMetaKind.SCALAR.equals(kind)) return "scalar";
    die("UNKNOWN KIND " + kind);
    return kind;
  }

  static void metaNode(List<String> out, SomMetaTree metaTree, String path) {
    SomMetaNode n = metaTree.byPath(path);
    if (n == null) {
      System.err.println("META MISSING at " + path);
      System.exit(3);
    }
    out.add("M\t" + path + "\t" + kindName(n.kind) + "\t"
        + esc(n.sectionId == null ? "" : n.sectionId) + "\t"
        + esc(n.contentHelp == null ? "" : n.contentHelp) + "\t"
        + esc(n.comment == null ? "" : n.comment) + "\t"
        + esc(n.docComment == null ? "" : n.docComment));
  }

  static void metaNav(List<String> out, SomMetaTree metaTree, SomMetaRef ref, String expectedPath) {
    if (!ref.path.equals(expectedPath)) {
      System.err.println("META NAV PATH at " + ref.path + " expected " + expectedPath);
      System.exit(3);
    }
    SomMetaNode byPath = metaTree.byPath(expectedPath);
    if (byPath == null || ref.meta() != byPath) {
      System.err.println("META NAV NODE mismatch at " + expectedPath);
      System.exit(3);
    }
    out.add("N\t" + expectedPath);
  }

  static void metaId(List<String> out, SomMetaRef idRef, SomMetaRef navRef) {
    if (!idRef.path.equals(navRef.path) || idRef.meta() != navRef.meta()) {
      System.err.println("META ID mismatch at " + idRef.path + " vs " + navRef.path);
      System.exit(3);
    }
    out.add("D\t" + idRef.path);
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
