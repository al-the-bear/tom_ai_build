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
//   * the D00SolutionBlueprint root is anchored at the `PD` segment;
//   * a content leaf round-trips typed -> generic and generic -> typed;
//   * a nested complex section derives its path under the root;
//   * the typed SomList collection parity (add / length / get) lands in the
//     same generic store;
//   * the generated model-version accessor returns `1.0`;
//   * the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp.
//
// Zero external deps: a plain `main()` that exits 0 on success (no JUnit), run
// by `run_tests.sh`.

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;

import tom_som_runtime.SomVersionError;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecSectionIdCollision;
import tom_som_java_v0.TomSomV0;
import tom_som_java_v0.TomSomV0Meta;

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
    TomSomV0.D00SolutionBlueprint pd = new TomSomV0.D00SolutionBlueprint(doc);

    check("root.segment", pd.path.equals("SBP"), pd.path);

    // Typed write -> generic read.
    pd.content("A clear vision");
    check("content.typed->generic", "A clear vision".equals(doc.content("SBP/content")),
        String.valueOf(doc.content("SBP/content")));

    // Generic write -> typed read.
    doc.setContent("SBP/content", "Revised vision");
    check("content.generic->typed", "Revised vision".equals(pd.content()), pd.content());

    // Unset leaf reads as empty string.
    check("content.unset-empty",
        new TomSomV0.D00SolutionBlueprint(new SpecDocument()).content().isEmpty());

    // Nested complex section path derivation (camelCase accessor preserved).
    TomSomV0.CurrentLandscape csa = pd.currentLandscape();
    check("nested.path", csa.path.equals("SBP/currentLandscape"), csa.path);

    // A generic value under the nested typed node is addressable via the
    // expected literal path (proves typed path == generic path).
    String headerPath = pd.documentControl().path;
    doc.setContent(headerPath + "/probe", "x");
    check("nested.typed-path==generic", "x".equals(doc.content("SBP/documentControl/probe")));

    // Typed SomList collection parity: append items, read them back, and prove
    // they land in the same generic store under the list segment.
    TomSomV0.CurrentLandscape csa2 = pd.currentLandscape();
    csa2.operationalMetrics().add().content("Average order turnaround: 4.2 days.");
    csa2.operationalMetrics().add().content("Manual reconciliation: ~12h / week.");
    check("list.length", csa2.operationalMetrics().length() == 2,
        String.valueOf(csa2.operationalMetrics().length()));
    check("list.typed-read",
        csa2.operationalMetrics().get(0).content().equals(
            "Average order turnaround: 4.2 days."));
    check("list.generic-count",
        doc.listItemCount("SBP/currentLandscape/CUOPME-OPER-LST") == 2);
  }

  private static void testModelVersion() {
    check("version.classattr", TomSomV0.D00SolutionBlueprint.MODEL_VERSION.equals("1.0"),
        TomSomV0.D00SolutionBlueprint.MODEL_VERSION);
    TomSomV0.D00SolutionBlueprint pd = new TomSomV0.D00SolutionBlueprint(new SpecDocument());
    check("version.accessor", pd.objectModelVersion().equals("1.0"),
        pd.objectModelVersion());
  }

  private static void testVersionCheck() {
    // New / equal-stamp document → accepted.
    try {
      new TomSomV0.D00SolutionBlueprint(new SpecDocument());
      new TomSomV0.D00SolutionBlueprint(new SpecDocument(), "1.0");
      check("version.editable", true);
    } catch (SomVersionError e) {
      check("version.editable", false, e.getMessage());
    }

    // Newer minor → rejected.
    try {
      new TomSomV0.D00SolutionBlueprint(new SpecDocument(), "1.1");
      check("version.newer-rejected", false, "expected SomVersionError");
    } catch (SomVersionError e) {
      check("version.newer-rejected", true);
    }

    // Different major → rejected.
    try {
      new TomSomV0.D00SolutionBlueprint(new SpecDocument(), "2.0");
      check("version.cross-major-rejected", false, "expected SomVersionError");
    } catch (SomVersionError e) {
      check("version.cross-major-rejected", true);
    }
  }

  // A fresh operationalMetrics list (a `@SectionIdPattern` list, CUOPME-OPER-xxx)
  // anchored under the SBP root.
  private static TomSomV0.CurrentLandscape freshLandscape() {
    return new TomSomV0.D00SolutionBlueprint(new SpecDocument()).currentLandscape();
  }

  private static final LocalDate MAR5 = LocalDate.of(2026, 3, 5); // month 3 → C, day 5 → E

  // Criteria 3–6: pattern-generated section ids, override + uniqueness, and the
  // delete-renumbering rules, all through the real generated pattern list.
  private static void testSectionIds() {
    // Criterion 3 + 4: generated id = prefix + two-letter-date + within-day number.
    {
      TomSomV0.CurrentLandscape csa = freshLandscape();
      String id1 = csa.operationalMetrics().add(null, MAR5).$sectionId();
      String id2 = csa.operationalMetrics().add(null, MAR5).$sectionId();
      check("sid.gen.first", "CUOPME-OPER-CE1".equals(id1), id1);
      check("sid.gen.second", "CUOPME-OPER-CE2".equals(id2), id2);
    }

    // Criterion 5: override to an arbitrary-but-unique suffix succeeds; a
    // duplicate raises SpecSectionIdCollision.
    {
      TomSomV0.CurrentLandscape csa = freshLandscape();
      csa.operationalMetrics().add(null, MAR5); // CUOPME-OPER-CE1
      TomSomV0.CurrentOperationalMetric second = csa.operationalMetrics().add(null, MAR5);
      second.$sectionId("CUOPME-OPER-ZZ9");
      check("sid.override.unique",
          csa.operationalMetrics().sectionIds().contains("CUOPME-OPER-ZZ9"),
          String.valueOf(csa.operationalMetrics().sectionIds()));
      try {
        csa.operationalMetrics().get(0).$sectionId("CUOPME-OPER-ZZ9");
        check("sid.override.collision", false, "expected SpecSectionIdCollision");
      } catch (SpecSectionIdCollision e) {
        check("sid.override.collision", true);
      }
      // Add-time override collision also raises.
      try {
        csa.operationalMetrics().add("CUOPME-OPER-ZZ9");
        check("sid.add.collision", false, "expected SpecSectionIdCollision");
      } catch (SpecSectionIdCollision e) {
        check("sid.add.collision", true);
      }
    }

    // Criterion 6a: deleting a *middle* item does NOT renumber — a later same-day
    // add takes max+1, so numbering may stay non-consecutive.
    {
      TomSomV0.CurrentLandscape csa = freshLandscape();
      csa.operationalMetrics().add(null, MAR5); // CE1
      csa.operationalMetrics().add(null, MAR5); // CE2
      csa.operationalMetrics().add(null, MAR5); // CE3
      csa.operationalMetrics().removeAt(1); // remove CE2
      check("sid.delete-middle.no-renumber",
          csa.operationalMetrics().sectionIds().equals(
              java.util.Arrays.asList("CUOPME-OPER-CE1", "CUOPME-OPER-CE3")),
          String.valueOf(csa.operationalMetrics().sectionIds()));
      String next = csa.operationalMetrics().add(null, MAR5).$sectionId();
      check("sid.delete-middle.next", "CUOPME-OPER-CE4".equals(next), next);
    }

    // Criterion 6b: deleting the *last* item frees its number; a same-day add
    // reuses it.
    {
      TomSomV0.CurrentLandscape csa = freshLandscape();
      csa.operationalMetrics().add(null, MAR5); // CE1
      csa.operationalMetrics().add(null, MAR5); // CE2
      csa.operationalMetrics().add(null, MAR5); // CE3
      csa.operationalMetrics().removeAt(2); // remove last (CE3)
      String reused = csa.operationalMetrics().add(null, MAR5).$sectionId();
      check("sid.delete-last.reuse", "CUOPME-OPER-CE3".equals(reused), reused);
    }
  }

  // The language-agnostic shared sample; read relative to the project dir so the
  // ../tom_som_conformance path resolves (matches GoldenLog + run_tests.sh cwd).
  private static final String SAMPLE_PATH =
      "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";

  private static String readSample() {
    try {
      return Files.readString(Path.of(SAMPLE_PATH));
    } catch (IOException e) {
      throw new java.io.UncheckedIOException(e);
    }
  }

  // Item 5: aligned absence semantics — typed isEmpty / generic
  // hasValuesUnder / hasContent all agree on subtree emptiness.
  private static void testAbsenceSemantics() {
    // A section isEmpty until any value is written under it.
    {
      SpecDocument doc = new SpecDocument();
      TomSomV0.D00SolutionBlueprint sbp = new TomSomV0.D00SolutionBlueprint(doc);
      check("absence.fresh-empty", sbp.requirements().isEmpty());
      sbp.requirements().content("Some requirements");
      check("absence.filled-not-empty", !sbp.requirements().isEmpty());
      sbp.requirements().content("");
      check("absence.cleared-empty", sbp.requirements().isEmpty());
    }

    // Typed isEmpty and generic hasValuesUnder agree, before and after a write.
    {
      SpecDocument doc = new SpecDocument();
      TomSomV0.D00SolutionBlueprint sbp = new TomSomV0.D00SolutionBlueprint(doc);
      String path = sbp.requirements().path;
      check("absence.hvu-agrees-before",
          sbp.requirements().isEmpty() == !doc.hasValuesUnder(path));
      doc.setContent(path + "/content", "x");
      check("absence.hvu-agrees-after",
          sbp.requirements().isEmpty() == !doc.hasValuesUnder(path));
      check("absence.hvu-after-not-empty", !sbp.requirements().isEmpty());
    }

    // hasContent gives the generic leaf path the typed .content answer.
    {
      SpecDocument doc = new SpecDocument();
      TomSomV0.D00SolutionBlueprint sbp = new TomSomV0.D00SolutionBlueprint(doc);
      String leaf = sbp.requirements().path + "/content";
      check("absence.hascontent-empty-init",
          sbp.requirements().content().isEmpty() && !doc.hasContent(leaf));
      sbp.requirements().content("Filled");
      check("absence.hascontent-after", doc.hasContent(leaf));
    }
  }

  // A "SBP/content: Hello" fixture in the hierarchical v2 wire format, built
  // via SpecDocumentYaml.encode against the root's metadata tree. A null
  // modelVersion emits an unstamped file.
  private static String buildV2Yaml(String modelVersion) {
    SpecDocument d = new SpecDocument();
    d.setContent("SBP/content", "Hello");
    return SpecDocumentYaml.encode(
        d, TomSomV0Meta.D00SolutionBlueprintMetaTree, modelVersion);
  }

  // Item 4: one-call loading — loadYaml / loadFile / SpecDocument.fromYaml
  // collapse the former decode → loadJson → thread-version incantation and
  // retain the parsed model version (null when unstamped).
  private static void testOneCallLoading() {
    // loadYaml collapses decode → loadJson → thread-version to one call.
    {
      String yaml = readSample();

      // The former multi-step incantation, built by hand: parse into a
      // document (hierarchical v2 decoding needs the root's metadata tree),
      // then construct the typed root with the retained model version.
      SpecDocument manualDoc = SpecDocument.fromYaml(
          yaml, TomSomV0Meta.D00SolutionBlueprintMetaTree);
      TomSomV0.D00SolutionBlueprint manual =
          new TomSomV0.D00SolutionBlueprint(manualDoc, manualDoc.modelVersion());

      // The one-call convenience.
      TomSomV0.D00SolutionBlueprint oneCall =
          TomSomV0.D00SolutionBlueprint.loadYaml(yaml);

      check("load.yaml.version",
          java.util.Objects.equals(oneCall.doc.modelVersion(), manualDoc.modelVersion()),
          String.valueOf(oneCall.doc.modelVersion()));
      check("load.yaml.content",
          java.util.Objects.equals(oneCall.content(), manual.content()));
      check("load.yaml.nested",
          java.util.Objects.equals(
              oneCall.introductionAndScope().goals().content(),
              manual.introductionAndScope().goals().content()));
      check("load.yaml.list-length",
          oneCall.currentLandscape().operationalMetrics().length()
              == manual.currentLandscape().operationalMetrics().length());
    }

    // loadFile reads the file then delegates to loadYaml.
    {
      TomSomV0.D00SolutionBlueprint fromFile =
          TomSomV0.D00SolutionBlueprint.loadFile(SAMPLE_PATH);
      TomSomV0.D00SolutionBlueprint fromYaml =
          TomSomV0.D00SolutionBlueprint.loadYaml(readSample());
      check("load.file.version",
          java.util.Objects.equals(
              fromFile.doc.modelVersion(), fromYaml.doc.modelVersion()),
          String.valueOf(fromFile.doc.modelVersion()));
      check("load.file.content",
          java.util.Objects.equals(fromFile.content(), fromYaml.content()));
    }

    // SpecDocument.fromYaml (the generic one-call loader) retains the parsed
    // model version. The wire format is hierarchical v2, so the fixture yaml
    // is built via SpecDocumentYaml.encode against the root's metadata tree
    // (mirrors the Go suite's buildV2Yaml helper).
    {
      String yaml = buildV2Yaml("1.0");
      SpecDocument doc =
          SpecDocument.fromYaml(yaml, TomSomV0Meta.D00SolutionBlueprintMetaTree);
      check("load.fromyaml.version", "1.0".equals(doc.modelVersion()),
          String.valueOf(doc.modelVersion()));
      check("load.fromyaml.content", "Hello".equals(doc.content("SBP/content")),
          String.valueOf(doc.content("SBP/content")));
    }

    // A document with no modelVersion stamp loads with a null stamp (Java uses
    // the null convention, not an empty-string sentinel) and the facade accepts
    // it (a new document is editable).
    {
      String yaml = buildV2Yaml(null);
      SpecDocument doc =
          SpecDocument.fromYaml(yaml, TomSomV0Meta.D00SolutionBlueprintMetaTree);
      check("load.unstamped.null", doc.modelVersion() == null,
          String.valueOf(doc.modelVersion()));
      try {
        TomSomV0.D00SolutionBlueprint.loadYaml(yaml);
        check("load.unstamped.editable", true);
      } catch (SomVersionError e) {
        check("load.unstamped.editable", false, e.getMessage());
      }
    }
  }

  // Item 10: the structural `canHaveContent()` per-type predicate — "does this
  // section TYPE declare the standard `content` leaf?" — answered without
  // probing `.content()` and without ever looking at the document. Distinct from
  // the state predicates (`hasContent(path)` / `isEmpty()`).
  private static void testCanHaveContent() {
    SpecDocument doc = new SpecDocument();
    TomSomV0.D00SolutionBlueprint sbp = new TomSomV0.D00SolutionBlueprint(doc);

    // A content-bearing section (Goals declares the standard `content` leaf).
    check("canhavecontent.goals-true",
        sbp.introductionAndScope().goals().canHaveContent());

    // A container-only section (SystemsToReplace holds only child sections).
    check("canhavecontent.systemstoreplace-false",
        !sbp.introductionAndScope().systemsToReplace().canHaveContent());

    // The document root itself declares a `content` leaf → true.
    check("canhavecontent.root-true", sbp.canHaveContent());

    // Structural — independent of whether content is written. The content-bearing
    // section stays true after a write, and the container-only sibling stays
    // false regardless.
    TomSomV0.Goals goals = sbp.introductionAndScope().goals();
    check("canhavecontent.structural-before", goals.canHaveContent());
    goals.content("Grow revenue");
    check("canhavecontent.structural-after", goals.canHaveContent());
    check("canhavecontent.sibling-still-false",
        !sbp.introductionAndScope().systemsToReplace().canHaveContent());
  }

  public static void main(String[] args) {
    testRootAndParity();
    testModelVersion();
    testVersionCheck();
    testSectionIds();
    testAbsenceSemantics();
    testOneCallLoading();
    testCanHaveContent();

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
