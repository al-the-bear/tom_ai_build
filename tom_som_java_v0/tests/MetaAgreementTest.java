// Agreement suite for the generated Java metadata module
// (`src/tom_som_java_v0/TomSomV0Meta.java`, SOM §7.2/§8) — the Java port of
// the Go facade's `som_v0_meta_test.go` (and the Dart facade's
// `test/generated_meta_test.dart`). Two guarantees over the *real* committed
// model:
//
//  1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
//     generated static SomMetaTree is field-for-field identical (via
//     SpecMetaDiff.somMetaNodeDiff) to the tree SomMetaBridge.buildSomMetaTree
//     derives from the committed `meta/spec_model.meta.json` at runtime. Since
//     the emitter writes the dot-notation / ID-tree accessor paths from the
//     same node walk, this also anchors every path the accessors can produce.
//  2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
//     points, and the dynamic byPath lookups all resolve to the *same* node
//     instances for representative positions (root, nested section, content
//     leaf, list, list element, hoisted id).
//
// The root set comes from the generated SOM_META_ROOTS registry, not a
// hand-list: adding a document root cannot leave this suite behind. That does
// not make the coverage check circular — `meta/spec_model.meta.json` is written
// by the model JSON exporter, a different code path from the meta emitter, so
// an emitter that drops a root still shows up as a count mismatch.
//
// Zero external deps: a plain `main()` that exits 0 on success (no JUnit), run
// by `run_tests.sh` from the project directory (the meta JSON is read
// relative to the cwd, matching GeneratedModelTest / GoldenLog).

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaNode;
import tom_som_runtime.SomMetaRef;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecMetaDiff;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecRoot;
import tom_som_java_v0.TomSomV0Meta;

public final class MetaAgreementTest {
  private MetaAgreementTest() {}

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

  /**
   * Every generated per-root static tree, keyed by root type — read from the
   * generated SOM_META_ROOTS registry rather than hand-listed, so a new
   * document root reaches this suite by regeneration instead of by
   * recollection.
   */
  private static Map<String, SomMetaTree> generatedTrees() {
    Map<String, SomMetaTree> m = new LinkedHashMap<>();
    for (Map.Entry<String, TomSomV0Meta.SomMetaRootEntry> e :
        TomSomV0Meta.SOM_META_ROOTS.entrySet()) {
      m.put(e.getKey(), e.getValue().tree);
    }
    return m;
  }

  /**
   * Parses the committed language-agnostic meta-data next to the generated
   * module (the same file the bridge builds trees from at runtime).
   */
  private static SpecModel loadModel() {
    try {
      String raw = Files.readString(Path.of("meta", "spec_model.meta.json"));
      return SpecModel.fromJson(Json.parseObject(raw));
    } catch (IOException e) {
      throw new java.io.UncheckedIOException(e);
    }
  }

  /** Resolves a ref's metadata node, recording a failure on error. */
  private static SomMetaNode mustMeta(String name, SomMetaRef ref) {
    try {
      return ref.meta();
    } catch (IllegalStateException e) {
      check(name + ".meta()", false, e.getMessage());
      return null;
    }
  }

  /**
   * Proves exhaustive tree agreement: the generated static trees cover
   * exactly the model's roots, and each is field-for-field identical to the
   * bridge-built tree.
   */
  private static void testGeneratedTreesAgreeWithBridge() {
    SpecModel model = loadModel();
    Map<String, SomMetaTree> trees = generatedTrees();

    check("bridge.root-count", model.roots.size() == trees.size(),
        "model has " + model.roots.size() + " roots, generated map has " + trees.size());
    for (SpecRoot root : model.roots) {
      check("bridge.root-covered." + root.type, trees.containsKey(root.type),
          "model root has no generated tree");
    }

    for (Map.Entry<String, SomMetaTree> e : trees.entrySet()) {
      SomMetaTree bridge = SomMetaBridge.buildSomMetaTree(model, e.getKey());
      String diff = SpecMetaDiff.somMetaNodeDiff(e.getValue().root, bridge.root);
      check("bridge.tree-agrees." + e.getKey(), diff.isEmpty(),
          "generated tree disagrees with bridge:\n" + diff);
    }
  }

  /**
   * Proves each registry entry describes itself consistently: the map key is
   * the entry's own type, both access roots sit at the declared segment, and
   * both resolve to the entry's own tree root.
   */
  private static void testRegistryEntriesAreSelfConsistent() {
    for (Map.Entry<String, TomSomV0Meta.SomMetaRootEntry> e :
        TomSomV0Meta.SOM_META_ROOTS.entrySet()) {
      TomSomV0Meta.SomMetaRootEntry entry = e.getValue();
      check("registry.key." + e.getKey(), entry.type.equals(e.getKey()),
          entry.type + " != " + e.getKey());
      check("registry.nav-segment." + e.getKey(), entry.nav.path.equals(entry.segment),
          entry.nav.path + " != " + entry.segment);
      check("registry.id-segment." + e.getKey(), entry.id.path.equals(entry.segment),
          entry.id.path + " != " + entry.segment);
      check("registry.nav-meta." + e.getKey(),
          mustMeta("registry.nav." + e.getKey(), entry.nav) == entry.tree.root,
          "nav meta() != tree root");
      check("registry.id-meta." + e.getKey(),
          mustMeta("registry.id." + e.getKey(), entry.id) == entry.tree.root,
          "id meta() != tree root");
    }
  }

  /**
   * Proves the dot-notation entry points (SOM §8) resolve representative
   * positions to the expected paths and to the same SomMetaNode instances the
   * dynamic byPath lookups find.
   */
  private static void testDotNotationSurface() {
    check("dot.root-path", TomSomV0Meta.D00SolutionBlueprintMeta.path.equals("SBP"),
        TomSomV0Meta.D00SolutionBlueprintMeta.path);
    check("dot.section-path",
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().path
            .equals("SBP/introductionAndScope"),
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().path);
    check("dot.leaf-path",
        TomSomV0Meta.D00SolutionBlueprintMeta.requirements().content().path
            .equals("SBP/requirements/content"),
        TomSomV0Meta.D00SolutionBlueprintMeta.requirements().content().path);
    check("dot.nested-leaf-path",
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().goals().content().path
            .equals("SBP/introductionAndScope/goals/content"),
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope().goals().content().path);

    // meta() resolves to the same node byPath finds.
    SomMetaNode viaDot = mustMeta("IntroductionAndScope",
        TomSomV0Meta.D00SolutionBlueprintMeta.introductionAndScope());
    SomMetaNode viaPath =
        TomSomV0Meta.D00SolutionBlueprintMetaTree.byPath("SBP/introductionAndScope");
    check("dot.meta==bypath", viaDot != null && viaDot == viaPath);
    check("dot.member-name", viaDot != null && "introductionAndScope".equals(viaDot.memberName),
        viaDot == null ? "null node" : String.valueOf(viaDot.memberName));

    // List positions expose item() with element accessors.
    var revs = TomSomV0Meta.D00SolutionBlueprintMeta
        .documentControl().revisionHistory();
    check("dot.list-path",
        revs.path.equals("SBP/documentControl/RVHST-REVS-LST"), revs.path);
    check("dot.list-item-path",
        revs.item(3).path.equals("SBP/documentControl/RVHST-REVS-LST-3"),
        revs.item(3).path);
    // The list node's metadata carries the section-id pattern.
    SomMetaNode revsNode = mustMeta("Revisions", revs);
    check("dot.list-sid-pattern",
        revsNode != null && revsNode.sectionIdPattern != null
            && !revsNode.sectionIdPattern.isEmpty(),
        "list node sectionIdPattern is empty");

    // A second root has its own entry point and segment.
    check("dot.second-root-segment",
        !TomSomV0Meta.D01CurrentLandscapeAssessmentMeta.path.equals("SBP"),
        "second root shares the SBP segment");
    check("dot.second-root-meta",
        mustMeta("D01CurrentLandscapeAssessmentMeta",
            TomSomV0Meta.D01CurrentLandscapeAssessmentMeta)
            == TomSomV0Meta.D01CurrentLandscapeAssessmentMetaTree.root,
        "second-root meta() != its tree root");
  }

  /**
   * Proves the ID-tree entry points (SOM §8) agree with the dot-notation
   * positions and that every root's ID entry point sits at its own section-id
   * segment over the same tree root node.
   */
  private static void testIdTreeSurface() {
    // The ID root shares the dot root position.
    check("id.root-path", TomSomV0Meta.SBP.path.equals(TomSomV0Meta.D00SolutionBlueprintMeta.path),
        TomSomV0Meta.SBP.path + " != " + TomSomV0Meta.D00SolutionBlueprintMeta.path);
    check("id.root-meta",
        mustMeta("SBP", TomSomV0Meta.SBP)
            == mustMeta("D00SolutionBlueprintMeta", TomSomV0Meta.D00SolutionBlueprintMeta),
        "SBP.meta() != dot root meta()");

    // A hoisted list id agrees with the dot-notation position: RVHST_REVS_LST
    // is hoisted onto the root ID type through the id-less documentControl /
    // revisionHistory members.
    var revs = TomSomV0Meta.D00SolutionBlueprintMeta
        .documentControl().revisionHistory();
    var hoisted = TomSomV0Meta.SBP.RVHST_REVS_LST();
    check("id.hoisted-path", hoisted.path.equals(revs.path),
        hoisted.path + " != " + revs.path);
    check("id.hoisted-meta",
        mustMeta("SBP.RVHST_REVS_LST", hoisted) == mustMeta("revisions", revs),
        "hoisted meta() != dot meta()");
    check("id.hoisted-item0",
        hoisted.item(0).path.equals(revs.item(0).path),
        hoisted.item(0).path + " != " + revs.item(0).path);

    // Every root has a distinct ID entry point at its own segment, resolving
    // to its generated tree's root node.
    Map<String, SomMetaRef> idRoots = new LinkedHashMap<>();
    for (Map.Entry<String, TomSomV0Meta.SomMetaRootEntry> e :
        TomSomV0Meta.SOM_META_ROOTS.entrySet()) {
      idRoots.put(e.getKey(), e.getValue().id);
    }

    Map<String, SomMetaTree> trees = generatedTrees();
    check("id.root-count", idRoots.size() == trees.size(),
        "idRoots has " + idRoots.size() + " entries, generatedTrees " + trees.size());
    for (Map.Entry<String, SomMetaRef> e : idRoots.entrySet()) {
      SomMetaTree tree = trees.get(e.getKey());
      if (tree == null) {
        check("id.tree." + e.getKey(), false, "no generated tree for id root");
        continue;
      }
      check("id.segment." + e.getKey(), e.getValue().path.equals(tree.root.sectionId),
          e.getValue().path + " != " + tree.root.sectionId);
      check("id.meta." + e.getKey(), mustMeta(e.getKey(), e.getValue()) == tree.root,
          "id meta() != tree root");
    }
  }

  public static void main(String[] args) {
    testGeneratedTreesAgreeWithBridge();
    testRegistryEntriesAreSelfConsistent();
    testDotNotationSurface();
    testIdTreeSurface();

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
