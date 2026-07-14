import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import tom_som_runtime.DocSpecsDocument;
import tom_som_runtime.DocSpecsFormField;
import tom_som_runtime.DocSpecsFormType;
import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsSection;
import tom_som_runtime.DocSpecsSectionType;
import tom_som_runtime.DocSpecsValidator;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;

/**
 * Tests for the consolidated DocSpecs parsing + validation module (DR1 §6,
 * DR7 / DR20) — a port of
 * {@code tom_som_go_runtime/tests/docspecs_validator_test.go} (itself a port
 * of the TypeScript/Python/Dart reference suite): the generic schema-free
 * parse, schema loading (with warnings for unsupported features), the
 * structured violation list, and the DR7 acceptance criterion — the
 * DR6-emitted Solution Blueprint sample validates cleanly against the
 * DR3-generated {@code solution-blueprint} schema.
 *
 * <p>JUnit is unavailable on the build host, so this is a plain {@code main()}
 * that exits 0 on success and 1 on failure (same shape as
 * SpecDocumentMarkdownTest).
 */
public final class DocSpecsValidatorTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  /** The ai_build folder holding the sibling runtime packages. */
  private static final String SIBLINGS = "..";

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void check(String name, boolean condition) {
    check(name, condition, "");
  }

  // ---------------------------------------------------------------------------
  // Fixture schema (hand-written in the exact DR3 generator output shape).
  // ---------------------------------------------------------------------------

  private static final String SCHEMA_YAML = ""
      + "title-format: \"# <!--[D00]--> Demo Document\"\n"
      + "section-types:\n"
      + "  goal-item:\n"
      + "    prefix: GOAL_ITEM_\n"
      + "    pattern-check-id:\n"
      + "      pattern: \"^GOAL-ITEM-[0-9]+$\"\n"
      + "      error-message: IDs of this section must match GOAL-ITEM-xxx\n"
      + "  d00-ovr:\n"
      + "    prefix: D00_OVR\n"
      + "    text-required: true\n"
      + "  d00-hdr:\n"
      + "    prefix: D00_HDR\n"
      + "    format: header-form\n"
      + "  gsum:\n"
      + "    prefix: GSUM\n"
      + "  diag:\n"
      + "    prefix: DIAG\n"
      + "    format: mermaid\n"
      + "  goals:\n"
      + "    prefix: GOALS\n"
      + "    subsection-types:\n"
      + "      goal-item:\n"
      + "        min-count: 1\n"
      + "        max-count: infinite\n"
      + "      gsum:\n"
      + "        max-count: 1\n"
      + "form-types:\n"
      + "  header-form:\n"
      + "    fields:\n"
      + "      - fieldname: author\n"
      + "        required: true\n"
      + "      - fieldname: reviewer\n"
      + "        pattern-check:\n"
      + "          pattern: \"^[A-Z]\"\n"
      + "          error-message: Reviewer must start with an uppercase letter\n"
      + "document:\n"
      + "  sections:\n"
      + "    d00-ovr:\n"
      + "      section-type: d00-ovr\n"
      + "    d00-hdr:\n"
      + "      section-type: d00-hdr\n"
      + "      optional: true\n"
      + "    goals:\n"
      + "      section-type: goals\n"
      + "      optional: true\n"
      + "    diag:\n"
      + "      section-type: diag\n"
      + "      optional: true\n";

  private static final String VALID_DOC = ""
      + "<!-- docspec: demo-document/1.0 -->\n"
      + "# <!--[D00]--> Demo Document\n"
      + "\n"
      + "Intro text.\n"
      + "\n"
      + "## <!--[D00-OVR]--> Overview\n"
      + "\n"
      + "Some overview text.\n"
      + "\n"
      + "## <!--[D00-HDR]--> Header\n"
      + "\n"
      + "Author: Alice\n"
      + "Reviewer: Bob\n"
      + "\n"
      + "## <!--[GOALS]--> Goals\n"
      + "\n"
      + "### <!--[GOAL-ITEM-1]--> Goal 1\n"
      + "\n"
      + "First goal.\n"
      + "\n"
      + "### <!--[GOAL-ITEM-2]--> Goal 2\n"
      + "\n"
      + "Second goal.\n";

  private static DocSpecsSchema schema() {
    return DocSpecsSchema.fromYamlText(SCHEMA_YAML);
  }

  private static List<DocSpecsViolation> validate(String md) {
    return new DocSpecsValidator(schema()).validateMarkdown(md);
  }

  private static String detail(List<DocSpecsViolation> violations) {
    List<String> parts = new ArrayList<>();
    for (DocSpecsViolation v : violations) {
      parts.add(v.toString());
    }
    return String.join("; ", parts);
  }

  private static List<String> childIds(DocSpecsSection s) {
    List<String> ids = new ArrayList<>();
    for (DocSpecsSection c : s.children) {
      ids.add(c.id);
    }
    return ids;
  }

  private static String replaceFirst(String text, String target, String replacement) {
    int i = text.indexOf(target);
    if (i < 0) {
      return text;
    }
    return text.substring(0, i) + replacement + text.substring(i + target.length());
  }

  // --- DocSpecsDocument parse (generic, schema-free) ---------------------------

  private static void testParseTree() {
    DocSpecsDocument doc = DocSpecsDocument.parse(VALID_DOC);
    check(
        "parse.declaredSchema",
        "demo-document/1.0".equals(doc.declaredSchema),
        String.valueOf(doc.declaredSchema));
    check("parse.noViolations", doc.violations.isEmpty(), detail(doc.violations));
    check("parse.oneRoot", doc.sections.size() == 1, String.valueOf(doc.sections.size()));
    DocSpecsSection root = doc.sections.get(0);
    check("parse.root.id", "D00".equals(root.id), String.valueOf(root.id));
    check("parse.root.title", "Demo Document".equals(root.title), root.title);
    check("parse.root.level", root.level == 1, String.valueOf(root.level));
    check("parse.root.text", "Intro text.".equals(root.text()), "'" + root.text() + "'");
    check(
        "parse.root.children",
        childIds(root).equals(List.of("D00-OVR", "D00-HDR", "GOALS")),
        String.join(",", childIds(root)));
    DocSpecsSection goals = root.children.get(root.children.size() - 1);
    check(
        "parse.goals.children",
        childIds(goals).equals(List.of("GOAL-ITEM-1", "GOAL-ITEM-2")),
        String.join(",", childIds(goals)));
    check(
        "parse.goal1.text",
        "First goal.".equals(goals.children.get(0).text()),
        "'" + goals.children.get(0).text() + "'");
  }

  private static void testParseFenceShield() {
    DocSpecsDocument doc =
        DocSpecsDocument.parse(
            "# <!--[D00]--> Demo Document\n"
                + "\n"
                + "```md\n"
                + "## <!--[NOT-A-SECTION]--> shielded\n"
                + "```\n");
    check("parse.fence.noChildren", doc.sections.get(0).children.isEmpty());
    check("parse.fence.bodyKept", doc.sections.get(0).text().contains("NOT-A-SECTION"));
  }

  private static void testParseMalformedHeading() {
    DocSpecsDocument doc =
        DocSpecsDocument.parse("# <!--[D00]--> Demo Document\n" + "\n" + "## Plain Heading\n");
    check("parse.malformed.count", doc.violations.size() == 1, detail(doc.violations));
    if (!doc.violations.isEmpty()) {
      DocSpecsViolation v = doc.violations.get(0);
      check(
          "parse.malformed.rule",
          DocSpecsViolation.RULE_MALFORMED_HEADING.equals(v.rule),
          v.toString());
      check("parse.malformed.line", v.line == 3, String.valueOf(v.line));
    }
  }

  // --- DocSpecsSchema.fromYamlText ----------------------------------------------

  private static void testSchemaLoading() {
    DocSpecsSchema schema = schema();
    check("schema.noWarnings", schema.warnings.isEmpty(), String.join("; ", schema.warnings));
    check(
        "schema.rootSectionId",
        "D00".equals(schema.rootSectionId()),
        String.valueOf(schema.rootSectionId()));
    DocSpecsSectionType goalItem = schema.sectionTypesByName.get("goal-item");
    check("schema.goalItem.present", goalItem != null);
    if (goalItem != null) {
      check("schema.goalItem.prefix", "GOAL_ITEM_".equals(goalItem.prefix), goalItem.prefix);
      check(
          "schema.goalItem.pattern",
          goalItem.patternCheck != null
              && "^GOAL-ITEM-[0-9]+$".equals(goalItem.patternCheck.pattern),
          String.valueOf(goalItem.patternCheck));
    }
    DocSpecsSectionType goals = schema.sectionTypesByName.get("goals");
    check("schema.goals.min", goals.subsectionTypes.get("goal-item").minCount == 1);
    check("schema.goals.maxInfinite", goals.subsectionTypes.get("goal-item").maxCount == null);
    check(
        "schema.gsum.max1",
        goals.subsectionTypes.get("gsum").maxCount != null
            && goals.subsectionTypes.get("gsum").maxCount == 1);
    DocSpecsFormType form = schema.formTypes.get("header-form");
    List<String> fieldNames = new ArrayList<>();
    for (DocSpecsFormField f : form.fields) {
      fieldNames.add(f.name);
    }
    check(
        "schema.form.fields",
        fieldNames.equals(List.of("author", "reviewer")),
        String.join(",", fieldNames));
    check("schema.form.authorRequired", form.fields.get(0).required);
    check("schema.doc.ovrRequired", !schema.documentSections.get("d00-ovr").optional);
    check("schema.doc.hdrOptional", schema.documentSections.get("d00-hdr").optional);
  }

  private static void testSchemaResolution() {
    DocSpecsSchema schema = schema();
    check("resolve.goalItem", "goal-item".equals(nameOf(schema, "GOAL-ITEM-7")),
        nameOf(schema, "GOAL-ITEM-7"));
    check("resolve.goals", "goals".equals(nameOf(schema, "GOALS")), nameOf(schema, "GOALS"));
    check("resolve.ovr", "d00-ovr".equals(nameOf(schema, "D00-OVR")), nameOf(schema, "D00-OVR"));
    check("resolve.none", "<nil>".equals(nameOf(schema, "NOPE-1")), nameOf(schema, "NOPE-1"));
  }

  private static String nameOf(DocSpecsSchema schema, String id) {
    DocSpecsSectionType st = schema.resolveSectionType(id);
    return st == null ? "<nil>" : st.name;
  }

  private static void testSchemaWarnings() {
    DocSpecsSchema schema =
        DocSpecsSchema.fromYamlText(
            "title-format: \"# <!--[D00]--> Demo\"\n"
                + "generators:\n"
                + "  something: true\n"
                + "section-types:\n"
                + "  d00-ovr:\n"
                + "    prefix: D00_OVR\n"
                + "    database-schema:\n"
                + "      table: t\n"
                + "document:\n"
                + "  sections:\n"
                + "    d00-ovr:\n"
                + "      section-type: d00-ovr\n"
                + "  custom-tag: x\n");
    check("warnings.count", schema.warnings.size() == 3, String.join("; ", schema.warnings));
    String joined = String.join("\n", schema.warnings);
    check("warnings.generators", joined.contains("generators"), joined);
    check("warnings.databaseSchema", joined.contains("database-schema"), joined);
    check("warnings.customTag", joined.contains("custom-tag"), joined);
    // The supported parts still load.
    check("warnings.stillLoads", schema.sectionTypesByName.get("d00-ovr") != null);
  }

  // --- DocSpecsValidator.validate ------------------------------------------------

  private static void testValidateValid() {
    List<DocSpecsViolation> v = validate(VALID_DOC);
    check("validate.valid.empty", v.isEmpty(), detail(v));
  }

  private static void testValidateMissingRequiredSection() {
    String md =
        replaceFirst(VALID_DOC, "## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n", "");
    List<DocSpecsViolation> v = validate(md);
    check("validate.missingSection.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.missingSection.rule",
          DocSpecsViolation.RULE_MISSING_REQUIRED_SECTION.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.missingSection.id",
          "d00-ovr".equals(v.get(0).sectionId),
          String.valueOf(v.get(0).sectionId));
      check(
          "validate.missingSection.msg",
          v.get(0).message.contains("d00-ovr"),
          v.get(0).message);
    }
  }

  private static void testValidateIdPatternMismatch() {
    String md = replaceFirst(VALID_DOC, "GOAL-ITEM-2", "GOAL-ITEM-B");
    List<DocSpecsViolation> v = validate(md);
    check("validate.idPattern.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.idPattern.rule",
          DocSpecsViolation.RULE_ID_PATTERN_MISMATCH.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.idPattern.id",
          "GOAL-ITEM-B".equals(v.get(0).sectionId),
          String.valueOf(v.get(0).sectionId));
      check(
          "validate.idPattern.msg",
          "IDs of this section must match GOAL-ITEM-xxx".equals(v.get(0).message),
          v.get(0).message);
      check("validate.idPattern.line", v.get(0).line == 21, String.valueOf(v.get(0).line));
    }
  }

  private static void testValidateUnknownSection() {
    String md =
        replaceFirst(VALID_DOC, "### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[XYZ-2]--> Goal 2");
    List<DocSpecsViolation> v = validate(md);
    check("validate.unknown.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.unknown.rule",
          DocSpecsViolation.RULE_UNKNOWN_SECTION.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.unknown.id",
          "XYZ-2".equals(v.get(0).sectionId),
          String.valueOf(v.get(0).sectionId));
    }
  }

  private static void testValidateDisallowedPosition() {
    String md =
        replaceFirst(VALID_DOC, "### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[DIAG]--> Diagram");
    List<DocSpecsViolation> v = validate(md);
    check("validate.disallowed.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.disallowed.rule",
          DocSpecsViolation.RULE_UNKNOWN_SECTION.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.disallowed.msg",
          v.get(0).message.contains("not an allowed subsection"),
          v.get(0).message);
    }
  }

  private static void testValidateMissingRequiredField() {
    String md = replaceFirst(VALID_DOC, "Author: Alice\n", "");
    List<DocSpecsViolation> v = validate(md);
    check("validate.missingField.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.missingField.rule",
          DocSpecsViolation.RULE_MISSING_REQUIRED_FIELD.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.missingField.id",
          "D00-HDR".equals(v.get(0).sectionId),
          String.valueOf(v.get(0).sectionId));
      check("validate.missingField.msg", v.get(0).message.contains("author"), v.get(0).message);
    }
  }

  private static void testValidateFieldPatternMismatch() {
    String md = replaceFirst(VALID_DOC, "Reviewer: Bob", "Reviewer: bob");
    List<DocSpecsViolation> v = validate(md);
    check("validate.fieldPattern.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.fieldPattern.rule",
          DocSpecsViolation.RULE_FIELD_PATTERN_MISMATCH.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.fieldPattern.msg",
          "Reviewer must start with an uppercase letter".equals(v.get(0).message),
          v.get(0).message);
      check("validate.fieldPattern.line", v.get(0).line == 13, String.valueOf(v.get(0).line));
    }
  }

  private static void testValidateTextRequired() {
    String md = replaceFirst(VALID_DOC, "Some overview text.\n\n", "");
    List<DocSpecsViolation> v = validate(md);
    check("validate.textRequired.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.textRequired.rule",
          DocSpecsViolation.RULE_TEXT_REQUIRED.equals(v.get(0).rule),
          v.get(0).toString());
      check(
          "validate.textRequired.id",
          "D00-OVR".equals(v.get(0).sectionId),
          String.valueOf(v.get(0).sectionId));
    }
  }

  private static void testValidateTooManyItems() {
    String md =
        VALID_DOC
            + "\n"
            + "### <!--[GSUM]--> Summary\n\nOne.\n\n"
            + "### <!--[GSUM]--> Summary\n\nTwo.\n";
    List<DocSpecsViolation> v = validate(md);
    check("validate.tooMany.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.tooMany.rule",
          DocSpecsViolation.RULE_TOO_MANY_ITEMS.equals(v.get(0).rule),
          v.get(0).toString());
      check("validate.tooMany.msg", v.get(0).message.contains("gsum"), v.get(0).message);
    }
  }

  private static void testValidateFormatMismatch() {
    String md = VALID_DOC + "\n## <!--[DIAG]--> Diagram\n\nno fence here\n";
    List<DocSpecsViolation> v = validate(md);
    check("validate.format.count", v.size() == 1, detail(v));
    if (!v.isEmpty()) {
      check(
          "validate.format.rule",
          DocSpecsViolation.RULE_FORMAT_MISMATCH.equals(v.get(0).rule),
          v.get(0).toString());
    }
    String ok = VALID_DOC + "\n## <!--[DIAG]--> Diagram\n\n" + "```mermaid\ngraph TD;\n```\n";
    List<DocSpecsViolation> vOk = validate(ok);
    check("validate.format.fencedOk", vOk.isEmpty(), detail(vOk));
  }

  private static void testValidateRootMismatch() {
    String md = replaceFirst(VALID_DOC, "# <!--[D00]-->", "# <!--[D99]-->");
    List<DocSpecsViolation> v = validate(md);
    boolean found = false;
    for (DocSpecsViolation x : v) {
      if (DocSpecsViolation.RULE_FORMAT_MISMATCH.equals(x.rule)) {
        found = true;
      }
    }
    check("validate.rootMismatch.rule", found, detail(v));
  }

  private static void testValidateNeverFailFast() {
    String md = replaceFirst(VALID_DOC, "Author: Alice\n", "");
    md = replaceFirst(md, "Reviewer: Bob", "Reviewer: bob");
    md = replaceFirst(md, "GOAL-ITEM-2", "GOAL-ITEM-B");
    List<DocSpecsViolation> v = validate(md);
    Set<String> seen = new LinkedHashSet<>();
    for (DocSpecsViolation x : v) {
      seen.add(x.rule);
    }
    List<String> got = new ArrayList<>(seen);
    Collections.sort(got);
    List<String> want =
        new ArrayList<>(
            List.of(
                DocSpecsViolation.RULE_MISSING_REQUIRED_FIELD,
                DocSpecsViolation.RULE_FIELD_PATTERN_MISMATCH,
                DocSpecsViolation.RULE_ID_PATTERN_MISMATCH));
    Collections.sort(want);
    check(
        "validate.neverFailFast",
        got.equals(want),
        String.join(",", got) + " != " + String.join(",", want));
  }

  // --- bindDocspecsMarkdown ------------------------------------------------------

  private static String readFile(String path) throws IOException {
    return new String(Files.readAllBytes(Paths.get(path)), StandardCharsets.UTF_8);
  }

  @SuppressWarnings("unchecked")
  private static SpecModel modelFromFile(String path) throws IOException {
    return SpecModel.fromJson((Map<String, Object>) Json.parse(readFile(path)));
  }

  private static void testBindDocspecsMarkdown() throws IOException {
    String corpus = SIBLINGS + "/tom_som_conformance/corpus";
    SpecModel model = modelFromFile(corpus + "/model.meta.json");
    String md = readFile(corpus + "/expected.md");
    SpecMarkdownResult result =
        DocSpecsValidator.bindDocspecsMarkdown(model, new SpecDocument(), md);
    check("bind.clean", result.isClean(), rejStr(result));
    check("bind.appliedCount", result.appliedCount() > 0, String.valueOf(result.appliedCount()));
  }

  private static String rejStr(SpecMarkdownResult result) {
    List<String> parts = new ArrayList<>();
    for (Object r : result.rejections) {
      parts.add(r.toString());
    }
    return String.join("; ", parts);
  }

  // --- DR7 acceptance: DR6 sample vs DR3 schema ----------------------------------

  /**
   * The Solution Blueprint sample emitted by the DR6 codec validates cleanly
   * against the generated {@code solution-blueprint} schema.
   */
  private static void testDr7Acceptance() throws IOException {
    String metaPath = SIBLINGS + "/tom_som_dart_v0/meta/spec_model.meta.json";
    SpecModel model = modelFromFile(metaPath);
    // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (DR9): decode it
    // against the metadata tree bridged from the exported model.
    String samplePath =
        SIBLINGS + "/tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
    SomMetaTree tree = SomMetaBridge.buildSomMetaTree(model, "D00SolutionBlueprint");
    SpecDocument document = SpecDocument.fromFile(samplePath, tree);
    String md = document.toMarkdown(model);

    String schemaPath =
        SIBLINGS
            + "/tom_som_dart_v0/schemas/solution-blueprint/"
            + "solution-blueprint.1.0.docspecs-schema.yaml";
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(readFile(schemaPath));
    check(
        "dr7.rootSectionId",
        "SBP".equals(schema.rootSectionId()),
        String.valueOf(schema.rootSectionId()));

    List<DocSpecsViolation> violations = new DocSpecsValidator(schema).validateMarkdown(md);
    StringBuilder detail = new StringBuilder();
    for (int i = 0; i < violations.size() && i < 20; i++) {
      detail.append("\n").append(violations.get(i));
    }
    check("dr7.violationsEmpty", violations.isEmpty(), detail.toString());
  }

  // --- harness ----------------------------------------------------------------

  public static void main(String[] args) throws IOException {
    testParseTree();
    testParseFenceShield();
    testParseMalformedHeading();
    testSchemaLoading();
    testSchemaResolution();
    testSchemaWarnings();
    testValidateValid();
    testValidateMissingRequiredSection();
    testValidateIdPatternMismatch();
    testValidateUnknownSection();
    testValidateDisallowedPosition();
    testValidateMissingRequiredField();
    testValidateFieldPatternMismatch();
    testValidateTextRequired();
    testValidateTooManyItems();
    testValidateFormatMismatch();
    testValidateRootMismatch();
    testValidateNeverFailFast();
    testBindDocspecsMarkdown();
    testDr7Acceptance();

    int total = passed + failed.size();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + total + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
      return;
    }
    System.out.println("OK: " + total + " checks passed");
  }
}
