// TomSpecs sample — author a Solution Blueprint end to end (Java).
//
// The Java port of `../bin/author_solution_blueprint.dart`: the same six
// steps, the same document, the same output (`../expected_output.txt`).
//
// Run (from this folder; see README.md):  mvn -q compile exec:java
//
// Six steps, in the order a real authoring task takes them:
//
//   1. open a fresh document and a typed root
//   2. author a small but coherent Solution Blueprint
//   3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
//   4. round-trip the yaml back through the one-call typed loader and prove
//      the reload is equal to what was written
//   5. validate on the instance tier
//   6. break one rule deliberately and read the diagnostic
//
// This sample is the NARRATIVE. The individual access styles each have their
// own focused example in the facade project (`tom_som_java_v0/examples/`),
// and this does not re-explain them.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

import tom_som_java_v0.TomSomV0;
import tom_som_java_v0.TomSomV0Meta;
import tom_som_runtime.Json;
import tom_som_runtime.SomList;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;

public final class Main {
  private Main() {}

  public static void main(String[] args) throws IOException {
    Path outDir = Path.of("build");
    Files.createDirectories(outDir);

    // -------------------------------------------------------------- step 1
    // A typed root over a fresh, empty document. Constructing the root also
    // runs the instantiation-time model-version check (SOM §4.2): an unstamped
    // document is editable, a document from a newer model is refused.
    SpecDocument doc = new SpecDocument();
    TomSomV0.D00SolutionBlueprint sbp = new TomSomV0.D00SolutionBlueprint(doc);

    System.out.println("1. A typed root over an empty document");
    System.out.println("   object model version : " + sbp.objectModelVersion());
    System.out.println("   root path            : " + sbp.path);
    System.out.println();

    // -------------------------------------------------------------- step 2
    // Author. Every write below goes through a NAMED accessor — no string
    // paths — and lands in the same path-keyed store the generic API reads.
    System.out.println("2. Authoring, printing each section id as it is written");

    sbp.content("Unify three legacy order systems behind one customer record.");
    wrote(sbp.path, "the blueprint itself");

    TomSomV0.IntroductionAndScope intro = sbp.introductionAndScope();
    intro.content("Replace per-region order intake with a single pipeline.");
    wrote(intro.path, "introduction and scope");

    TomSomV0.CurrentLandscape landscape = sbp.currentLandscape();
    landscape.content("Three systems, no shared customer record, manual reconciliation.");
    wrote(landscape.path, "the current landscape");

    // A list section. `add()` appends an item and returns it typed.
    SomList<TomSomV0.CurrentOperationalMetric> metrics = landscape.operationalMetrics();
    metrics.add().content("Average order turnaround: 4.2 days.");
    metrics.add().content("Manual reconciliation: about 12 hours a week.");
    wrote(metrics.listPath, metrics.length() + " operational metrics");

    System.out.println();

    // -------------------------------------------------------------- step 3
    // Both renditions of the same document. They are two encodings of one
    // store, not two documents — which is why step 4 can round-trip either.
    //
    // `toMarkdown` and the validator both need a whole SpecModel: the facade
    // project ships it as `meta/spec_model.meta.json`.
    SpecModel model = loadModel();

    String yaml = SpecDocumentYaml.encode(
        doc, TomSomV0Meta.D00SolutionBlueprintMetaTree, model.modelVersionString());
    String markdown = doc.toMarkdown(model, "D00SolutionBlueprint");

    Files.writeString(outDir.resolve("blueprint.tomspecs.yaml"), yaml);
    Files.writeString(outDir.resolve("blueprint.tomspecs.md"), markdown);

    System.out.println("3. Serialised both renditions into build/");
    System.out.println("   blueprint.tomspecs.yaml : " + lines(yaml) + " lines  (SOM §12)");
    System.out.println("   blueprint.tomspecs.md   : " + lines(markdown) + " lines  (SOM §11)");
    System.out.println();

    // -------------------------------------------------------------- step 4
    // The one-call typed loader: decode, apply the document's own authoring
    // stamp, and hand back a typed root. Re-encoding the reload and comparing
    // the two strings is the actual proof — comparing field by field would
    // only prove the fields somebody thought to compare.
    TomSomV0.D00SolutionBlueprint reloaded =
        TomSomV0.D00SolutionBlueprint.loadFile(outDir.resolve("blueprint.tomspecs.yaml").toString());
    String reYaml = SpecDocumentYaml.encode(
        reloaded.doc, TomSomV0Meta.D00SolutionBlueprintMetaTree, model.modelVersionString());

    System.out.println("4. Round-tripped the yaml through D00SolutionBlueprint.loadFile");
    System.out.println("   reload equals original  : " + reYaml.equals(yaml));
    System.out.println("   a value read back typed : \""
        + reloaded.currentLandscape().operationalMetrics().get(0).content() + "\"");
    System.out.println();

    // -------------------------------------------------------------- step 5
    List<SpecValidationError> errors = SpecValidator.validateDocument(model, doc);
    System.out.println("5. Instance-tier validation");
    System.out.println("   violations              : " + errors.size());
    System.out.println();

    // -------------------------------------------------------------- step 6
    // What a violation looks like. Writing to a path the model does not declare
    // is the clearest break to stage: the store accepts it — it is a plain
    // path-keyed map — and the validator is what notices.
    SpecDocument broken = SpecDocument.fromYaml(yaml, TomSomV0Meta.D00SolutionBlueprintMetaTree);
    broken.setContent("SBP/noSuchSection/content", "not part of the model");

    List<SpecValidationError> brokenErrors = SpecValidator.validateDocument(model, broken);
    System.out.println("6. The same document with one rule deliberately broken");
    System.out.println("   violations              : " + brokenErrors.size());
    for (SpecValidationError e : brokenErrors) {
      System.out.println("   " + e.code.value + ": " + e.path);
      System.out.println("     " + e.message);
    }
    System.out.println();
    System.out.println("Done. The two renditions are in build/.");
  }

  /**
   * Prints the section id a write landed under. The ids are the document's
   * addressing system — the same tokens appear in the yaml keys and in the
   * markdown `<!--[ID]-->` comments — so the sample shows them rather than
   * describing them.
   */
  private static void wrote(String path, String what) {
    System.out.println("   " + String.format("%-46s", path) + " " + what);
  }

  private static int lines(String s) {
    return s.stripTrailing().split("\n", -1).length;
  }

  /**
   * Reads the whole model the facade project ships, from the checkout:
   * `tom_som_java_v0/meta/spec_model.meta.json`. The checkout is the
   * `tomspecs.checkout` system property the pom sets, three folders above.
   */
  private static SpecModel loadModel() throws IOException {
    Path meta = checkout().resolve("tom_som_java_v0/meta/spec_model.meta.json");
    return SpecModel.fromJson(Json.parseObject(Files.readString(meta)));
  }

  private static Path checkout() {
    return Path.of(System.getProperty("tomspecs.checkout", "../../..")).normalize();
  }
}
