// Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs.
//
// Demonstrates the value-free "reflection" surface: load the exported meta-data
// (`meta/spec_model.meta.json`, the lossless class graph) into a `SpecModel` and
// query its shape with `SpecReflection` — enumerate roots and fields, and
// resolve a concrete document *path* to the model node it lands on. No document
// values are involved; this answers "what CAN the model hold?", not "what does a
// given document hold?".
//
// Compile + run via run_tests.sh, or directly (from the package dir):
//   javac -d build -sourcepath src:../tom_som_java_runtime/src \
//       examples/CReflectionMetadata.java
//   java -cp build CReflectionMetadata          # reads ./meta/spec_model.meta.json
//   java -cp build CReflectionMetadata <path>   # or an explicit meta path

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;

public final class CReflectionMetadata {
  private CReflectionMetadata() {}

  public static void main(String[] args) throws Exception {
    // The meta-data shipped in this package; override with an explicit path.
    Path metaPath = Path.of(args.length > 0 ? args[0]
        : Path.of("meta", "spec_model.meta.json").toString());
    Map<String, Object> json = Json.parseObject(Files.readString(metaPath));
    SpecModel model = SpecModel.fromJson(json);
    SpecReflection reflection = new SpecReflection(model);

    String label = model.modelVersionLabel == null || model.modelVersionLabel.isEmpty()
        ? "unstamped"
        : model.modelVersionLabel;
    System.out.println("Model version: " + model.modelVersion + " (" + label + ")");
    List<SpecRoot> roots = reflection.roots();
    System.out.println("Roots: " + roots.size()
        + ", classes: " + reflection.classes().size() + "\n");

    // Enumerate the document roots by their addressable segment.
    System.out.println("Document roots:");
    for (SpecRoot root : roots) {
      System.out.printf("  %-4s %s%n", reflection.rootSegment(root), root.title);
    }

    // Inspect the fields of the D00SolutionBlueprint root class.
    SpecRoot pdRoot = reflection.rootForSegment("SBP");
    List<SpecField> pdFields = reflection.fieldsOf(pdRoot.type);
    System.out.println("\nFirst fields of " + pdRoot.type
        + " (" + pdFields.size() + " total):");
    for (int i = 0; i < Math.min(6, pdFields.size()); i++) {
      SpecField field = pdFields.get(i);
      StringBuilder extra = new StringBuilder();
      if (field.type != null) {
        extra.append("  type=").append(field.type);
      }
      if (field.elementType != null) {
        extra.append("  elem=").append(field.elementType);
      }
      System.out.printf("  %-24s kind=%s%s%n", field.name, field.kind.raw, extra);
    }

    // Resolve concrete document paths to model nodes (value-free).
    System.out.println("\nPath resolution:");
    String[] paths = {
        "SBP",
        "SBP/content",
        "SBP/currentLandscape",
        "SBP/currentLandscape/CUOPME-OPER-LST",
    };
    for (String path : paths) {
      SpecResolution res = reflection.resolve(path);
      if (res == null) {
        System.out.println("  " + path + "  ->  (unresolved)");
        continue;
      }
      SpecClass cls = res.targetClass;
      String clsPart = cls == null ? "" : "  class=" + cls.name;
      System.out.printf("  %-40s -> kind=%s%s  value_leaf=%s%n",
          path, res.kind.value, clsPart, res.isValueLeaf());
    }
  }
}
