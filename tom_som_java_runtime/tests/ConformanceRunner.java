import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecSectionId;
import tom_som_runtime.SpecSectionIdCollision;
import tom_som_runtime.SpecSerializationOrder;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;
import tom_som_runtime.SpecYamlContents;

/**
 * Shared-corpus conformance runner for the Java generic runtime — a plain-Java
 * port of {@code tests/conformance_runner.py}. JUnit is unavailable on the build
 * host (no Maven/Gradle/JUnit jar), so this is a dependency-free {@code main()}
 * that asserts every golden byte-for-byte and exits 0 on success, 1 on failure.
 *
 * <p>Run with: {@code java -cp <out>:<tests> ConformanceRunner <corpusDir>}.
 */
public final class ConformanceRunner {
  private static final String MODEL_VERSION = "1.0";

  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();
  private static Path corpus;

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static String read(String name) throws IOException {
    return new String(Files.readAllBytes(corpus.resolve(name)), StandardCharsets.UTF_8);
  }

  private static Object readJson(String name) throws IOException {
    return Json.parse(read(name));
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> readJsonObject(String name) throws IOException {
    return (Map<String, Object>) readJson(name);
  }

  @SuppressWarnings("unchecked")
  private static List<Object> readJsonArray(String name) throws IOException {
    return (List<Object>) readJson(name);
  }

  private static String byteDiff(String label, String actual, String expected) {
    if (actual.equals(expected)) {
      return "";
    }
    String[] a = actual.split("\n", -1);
    String[] e = expected.split("\n", -1);
    int max = Math.max(a.length, e.length);
    for (int idx = 0; idx < max; idx++) {
      String al = idx < a.length ? a[idx] : "<EOF>";
      String el = idx < e.length ? e[idx] : "<EOF>";
      if (!al.equals(el)) {
        return label + ": first diff at line " + (idx + 1) + ": got " + repr(al) + " want " + repr(el);
      }
    }
    return label + ": differ (len got " + actual.length() + " want " + expected.length() + ")";
  }

  private static String repr(String s) {
    return "'" + s.replace("\n", "\\n") + "'";
  }

  private static SpecModel loadModel() throws IOException {
    return SpecModel.fromJson(readJsonObject("model.meta.json"));
  }

  private static SpecDocument documentFromState(Map<String, Object> state) {
    SpecDocument doc = new SpecDocument();
    doc.loadJson(state);
    return doc;
  }

  // --- tests --------------------------------------------------------------

  private static void testModelMeta(SpecModel model) {
    SpecRoot root = model.roots.get(0);
    check("model.root.sectionId", "DEMO".equals(root.sectionId), String.valueOf(root.sectionId));
    check("model.root.type", "Demo".equals(root.type), String.valueOf(root.type));
    check("model.classCount", model.classes.size() == 3, String.valueOf(model.classes.size()));
    SpecClass demo = model.classNamed("Demo");
    check("model.Demo.found", demo != null, "");
    if (demo != null) {
      List<String> names = new ArrayList<>();
      for (SpecField f : demo.fields) {
        names.add(f.name);
      }
      List<String> want =
          List.of("title", "summary", "priority", "count", "details", "items", "meta");
      check("model.Demo.fields", names.equals(want), names.toString());
    }
  }

  private static void testStateRoundTrip() throws IOException {
    Map<String, Object> state = readJsonObject("state.json");
    SpecDocument doc = documentFromState(state);
    check("state.toJson", doc.toJson().equals(state), jsonMismatch(doc.toJson(), state));
  }

  private static String jsonMismatch(Object actual, Object expected) {
    if (actual.equals(expected)) {
      return "";
    }
    return "got " + Json.write(actual) + " want " + Json.write(expected);
  }

  private static void testYamlEncode(SomMetaTree tree) throws IOException {
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    String expected = read("expected.docspecs.yaml");
    String actual = SpecDocumentYaml.encode(doc, tree, MODEL_VERSION);
    check("yaml.encode", actual.equals(expected), byteDiff("yaml.encode", actual, expected));
  }

  private static void testYamlDecodeRoundTrip(SomMetaTree tree) throws IOException {
    String expected = read("expected.docspecs.yaml");
    SpecYamlContents contents = SpecDocumentYaml.decode(expected, tree);
    check(
        "yaml.decode.stamp",
        MODEL_VERSION.equals(contents.modelVersion),
        String.valueOf(contents.modelVersion));
    Map<String, Object> state = readJsonObject("state.json");
    check(
        "yaml.decode.memory",
        contents.document.toJson().equals(state),
        jsonMismatch(contents.document.toJson(), state));
    String stamp = contents.modelVersion != null ? contents.modelVersion : MODEL_VERSION;
    String actual = SpecDocumentYaml.encode(contents.document, tree, stamp);
    check(
        "yaml.decode.reencode",
        actual.equals(expected),
        byteDiff("yaml.decode.reencode", actual, expected));
  }

  // --- markdown conformance (DR6/DR20) ------------------------------------

  private static void testMarkdownExport(SpecModel model) throws IOException {
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    String expected = read("expected.md");
    String actual;
    try {
      actual = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots.get(0));
    } catch (RuntimeException e) {
      check("md.export", false, String.valueOf(e.getMessage()));
      return;
    }
    check("md.export", actual.equals(expected), byteDiff("md.export", actual, expected));
  }

  private static void testMarkdownRoundTrip(SpecModel model) throws IOException {
    String golden = read("expected.md");
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    SpecMarkdownResult parsed = new SpecDocumentMarkdown(model, doc).parse(golden);
    check("md.parse.clean", parsed.rejections.isEmpty(), rejDetail(parsed));
    SpecDocument reDoc = new SpecDocument();
    reDoc.loadJson(parsed.toLoadJson());
    String actual;
    try {
      actual = new SpecDocumentMarkdown(model, reDoc).exportRoot(model.roots.get(0));
    } catch (RuntimeException e) {
      check("md.parse.reexport", false, String.valueOf(e.getMessage()));
      return;
    }
    check("md.parse.reexport", actual.equals(golden), byteDiff("md.parse.reexport", actual, golden));
  }

  /**
   * Plan item #9: parsing {@code expected.md} and applying it must reproduce
   * {@code state.json} (the YAML-route memory) exactly, proving both formats
   * converge on one in-memory document (§4.1).
   */
  private static void testMarkdownMemoryLanding(SpecModel model) throws IOException {
    String golden = read("expected.md");
    Map<String, Object> canonical = readJsonObject("state.json");
    SpecDocument doc = documentFromState(canonical);
    SpecMarkdownResult parsed = new SpecDocumentMarkdown(model, doc).parse(golden);
    check("md.land.clean", parsed.rejections.isEmpty(), rejDetail(parsed));
    SpecDocument landed = new SpecDocument();
    landed.loadJson(parsed.toLoadJson());
    check(
        "md.land.memory",
        landed.toJson().equals(canonical),
        jsonMismatch(landed.toJson(), canonical));
  }

  private static String rejDetail(SpecMarkdownResult r) {
    StringBuilder out = new StringBuilder();
    for (SpecMarkdownRejection rej : r.rejections) {
      if (out.length() > 0) {
        out.append("; ");
      }
      out.append(rej);
    }
    return out.toString();
  }

  @SuppressWarnings("unchecked")
  private static void testReflection(SpecModel model) throws IOException {
    SpecReflection refl = new SpecReflection(model);
    for (Object caseObj : readJsonArray("reflection_cases.json")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String path = (String) c.get("path");
      SpecResolution res = refl.resolve(path);
      boolean resolves = Boolean.TRUE.equals(c.get("resolves"));
      if (!resolves) {
        check("reflect[" + path + "].none", res == null, "expected no resolution");
        continue;
      }
      if (res == null) {
        check("reflect[" + path + "].some", false, "expected resolution, got null");
        continue;
      }
      check(
          "reflect[" + path + "].kind",
          Objects.equals(res.kind.value, c.get("kind")),
          res.kind.value + " != " + c.get("kind"));
      String fieldName = res.field != null ? res.field.name : null;
      check(
          "reflect[" + path + "].field",
          Objects.equals(fieldName, c.get("field")),
          fieldName + " != " + c.get("field"));
      String target = res.targetClass != null ? res.targetClass.name : null;
      check(
          "reflect[" + path + "].target",
          Objects.equals(target, c.get("targetClass")),
          target + " != " + c.get("targetClass"));
      check(
          "reflect[" + path + "].leaf",
          res.isValueLeaf() == Boolean.TRUE.equals(c.get("isValueLeaf")),
          res.isValueLeaf() + " != " + c.get("isValueLeaf"));
    }
  }

  @SuppressWarnings("unchecked")
  private static void testValidation(SpecModel model) throws IOException {
    for (Object caseObj : readJsonArray("validation_cases.json")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      SpecDocument doc = documentFromState((Map<String, Object>) c.get("state"));
      List<SpecValidationError> errors = SpecValidator.validateDocument(model, doc);
      List<String> got = new ArrayList<>();
      for (SpecValidationError e : errors) {
        got.add(e.path + "|" + e.code.value);
      }
      List<String> want = new ArrayList<>();
      for (Object eObj : (List<Object>) c.get("errors")) {
        Map<String, Object> e = (Map<String, Object>) eObj;
        want.add(e.get("path") + "|" + e.get("code"));
      }
      check("validate[" + name + "]", got.equals(want), got + " != " + want);
    }
  }

  @SuppressWarnings("unchecked")
  private static void testOperations() throws IOException {
    SpecDocument doc = new SpecDocument();
    List<Object> ops = readJsonArray("operations_cases.json");
    for (int n = 0; n < ops.size(); n++) {
      Map<String, Object> op = (Map<String, Object>) ops.get(n);
      String kind = (String) op.get("op");
      switch (kind) {
        case "isEmpty":
          check("op[" + n + "].isEmpty", doc.isEmpty() == Boolean.TRUE.equals(op.get("expect")), "");
          break;
        case "setContent":
          doc.setContent((String) op.get("path"), (String) op.get("value"));
          break;
        case "content":
          check(
              "op[" + n + "].content",
              Objects.equals(doc.content((String) op.get("path")), op.get("expect")),
              String.valueOf(doc.content((String) op.get("path"))));
          break;
        case "setFormField":
          doc.setFormField(
              (String) op.get("path"), (String) op.get("field"), (String) op.get("value"));
          break;
        case "formField":
          check(
              "op[" + n + "].formField",
              Objects.equals(
                  doc.formField((String) op.get("path"), (String) op.get("field")),
                  op.get("expect")),
              "");
          break;
        case "addListItem":
          check(
              "op[" + n + "].addListItem",
              Objects.equals(doc.addListItem((String) op.get("listPath")), op.get("expect")),
              "");
          break;
        case "listItems":
          check(
              "op[" + n + "].listItems",
              doc.listItems((String) op.get("listPath")).equals(op.get("expect")),
              String.valueOf(doc.listItems((String) op.get("listPath"))));
          break;
        case "listItemCount":
          check(
              "op[" + n + "].listItemCount",
              doc.listItemCount((String) op.get("listPath"))
                  == ((Number) op.get("expect")).intValue(),
              "");
          break;
        case "hasValuesUnder":
          check(
              "op[" + n + "].hasValuesUnder",
              doc.hasValuesUnder((String) op.get("prefix")) == Boolean.TRUE.equals(op.get("expect")),
              "");
          break;
        case "removeListItem":
          check(
              "op[" + n + "].removeListItem",
              doc.removeListItem((String) op.get("itemPath")) == Boolean.TRUE.equals(op.get("expect")),
              "");
          break;
        default:
          check("op[" + n + "].unknown", false, kind);
      }
    }
  }

  @SuppressWarnings("unchecked")
  private static List<String> stringList(Object array) {
    List<String> out = new ArrayList<>();
    for (Object o : (List<Object>) array) {
      out.add((String) o);
    }
    return out;
  }

  private static int intAt(Map<String, Object> m, String key) {
    return ((Number) m.get(key)).intValue();
  }

  /**
   * AA1 criteria 3–6: two-letter-date encoding, list-item id generation
   * (within-day numbering), same-day reuse on last-item deletion, and
   * unique-id enforcement on override — replayed from the shared corpus so
   * every port reproduces the identical id semantics.
   */
  @SuppressWarnings("unchecked")
  private static void testSectionId() throws IOException {
    Map<String, Object> cases = readJsonObject("section_id_cases.json");

    // Criterion 4: the two-letter day code.
    for (Object caseObj : (List<Object>) cases.get("twoLetterDate")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      int month = intAt(c, "month");
      int day = intAt(c, "day");
      String got = SpecSectionId.encodeTwoLetterDate(month, day);
      check(
          "sectionId.twoLetterDate[" + month + "/" + day + "]",
          got.equals(c.get("expect")),
          got + " != " + c.get("expect"));
    }

    // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
    for (Object caseObj : (List<Object>) cases.get("generate")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String pattern = (String) c.get("pattern");
      String got =
          SpecSectionId.generateListItemSectionId(
              pattern, intAt(c, "month"), intAt(c, "day"), stringList(c.get("existing")));
      check(
          "sectionId.generate[" + pattern + "]",
          got.equals(c.get("expect")),
          got + " != " + c.get("expect"));
    }

    // Criteria 5 & 6 at the document level: override keeps ids unique,
    // deleting the last same-day item frees its number for reuse, deleting a
    // middle one never renumbers the rest.
    SpecDocument doc = new SpecDocument();
    List<Object> docOps = (List<Object>) cases.get("documentOps");
    for (int i = 0; i < docOps.size(); i++) {
      Map<String, Object> s = (Map<String, Object>) docOps.get(i);
      String op = (String) s.get("op");
      switch (op) {
        case "addGen": {
          String genId =
              SpecSectionId.generateListItemSectionId(
                  (String) s.get("pattern"),
                  intAt(s, "month"),
                  intAt(s, "day"),
                  doc.listItemSectionIds((String) s.get("listPath")));
          check(
              "sectionId.op[" + i + "].addGen.id",
              genId.equals(s.get("expectId")),
              genId + " != " + s.get("expectId"));
          String path = doc.addListItem((String) s.get("listPath"), genId);
          check(
              "sectionId.op[" + i + "].addGen.path",
              path.equals(s.get("expectPath")),
              path + " != " + s.get("expectPath"));
          break;
        }
        case "sectionIds": {
          List<String> got = doc.listItemSectionIds((String) s.get("listPath"));
          List<String> want = stringList(s.get("expect"));
          check(
              "sectionId.op[" + i + "].sectionIds",
              got.equals(want),
              got + " != " + want);
          break;
        }
        case "removeListItem": {
          boolean got = doc.removeListItem((String) s.get("itemPath"));
          check(
              "sectionId.op[" + i + "].removeListItem",
              got == Boolean.TRUE.equals(s.get("expect")),
              "");
          break;
        }
        case "override":
          doc.setItemSectionId((String) s.get("itemPath"), (String) s.get("id"));
          break;
        case "overrideThrows":
          check(
              "sectionId.op[" + i + "].overrideThrows",
              raisesCollision(
                  () -> doc.setItemSectionId((String) s.get("itemPath"), (String) s.get("id"))),
              "");
          break;
        case "addExplicitThrows":
          check(
              "sectionId.op[" + i + "].addExplicitThrows",
              raisesCollision(
                  () -> doc.addListItem((String) s.get("listPath"), (String) s.get("id"))),
              "");
          break;
        default:
          check("sectionId.op[" + i + "].unknown", false, op);
      }
    }
  }

  /** Whether {@code fn} raises {@link SpecSectionIdCollision} (criterion-5 guard). */
  private static boolean raisesCollision(Runnable fn) {
    try {
      fn.run();
      return false;
    } catch (SpecSectionIdCollision e) {
      return true;
    }
  }

  /** AA1 criterion 7: members serialize in {@code @SerializationOrder}, not alphabetical. */
  @SuppressWarnings("unchecked")
  private static void testSerializationOrder() throws IOException {
    Map<String, Object> c = readJsonObject("serialization_order_cases.json");
    SpecModel orderModel = SpecModel.fromJson((Map<String, Object>) c.get("model"));
    SpecSerializationOrder order = new SpecSerializationOrder(orderModel);

    List<String> gotPaths = order.orderPaths(stringList(c.get("contentPaths")));
    List<String> wantPaths = stringList(c.get("expectedOrder"));
    check("serialOrder.orderPaths", gotPaths.equals(wantPaths), gotPaths + " != " + wantPaths);

    List<String> gotFields =
        order.orderFormFields((String) c.get("formPath"), stringList(c.get("formFields")));
    List<String> wantFields = stringList(c.get("expectedFormOrder"));
    check(
        "serialOrder.orderFormFields",
        gotFields.equals(wantFields),
        gotFields + " != " + wantFields);
  }

  public static void main(String[] args) throws IOException {
    String corpusArg =
        args.length > 0 ? args[0] : "../tom_som_conformance/corpus";
    corpus = Paths.get(corpusArg).toAbsolutePath().normalize();
    if (!Files.isDirectory(corpus)) {
      System.err.println("corpus not found at " + corpus);
      System.exit(2);
      return;
    }
    SpecModel model = loadModel();
    SomMetaTree tree = SomMetaBridge.buildSomMetaTree(model, null);
    testModelMeta(model);
    testStateRoundTrip();
    testYamlEncode(tree);
    testYamlDecodeRoundTrip(tree);
    testMarkdownExport(model);
    testMarkdownRoundTrip(model);
    testMarkdownMemoryLanding(model);
    testReflection(model);
    testValidation(model);
    testOperations();
    testSectionId();
    testSerializationOrder();

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
