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
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;
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

  private static void testYamlEncode() throws IOException {
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    String expected = read("expected.docspecs.yaml");
    String actual = SpecDocumentYaml.encode(doc, MODEL_VERSION);
    check("yaml.encode", actual.equals(expected), byteDiff("yaml.encode", actual, expected));
  }

  private static void testYamlDecodeRoundTrip() throws IOException {
    String expected = read("expected.docspecs.yaml");
    SpecYamlContents contents = SpecDocumentYaml.decode(expected);
    check(
        "yaml.decode.stamp",
        MODEL_VERSION.equals(contents.modelVersion),
        String.valueOf(contents.modelVersion));
    SpecDocument doc = new SpecDocument();
    doc.loadJson(contents.document);
    String stamp = contents.modelVersion != null ? contents.modelVersion : MODEL_VERSION;
    String actual = SpecDocumentYaml.encode(doc, stamp);
    check(
        "yaml.decode.reencode",
        actual.equals(expected),
        byteDiff("yaml.decode.reencode", actual, expected));
  }

  private static void testMarkdownExport(SpecModel model) throws IOException {
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    String expected = read("expected.md");
    String actual = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots.get(0));
    check("md.export", actual.equals(expected), byteDiff("md.export", actual, expected));
  }

  private static void testMarkdownRoundTrip(SpecModel model) throws IOException {
    String expected = read("expected.md");
    SpecMarkdownResult result = new SpecDocumentMarkdown(model, new SpecDocument()).parse(expected);
    check("md.parse.clean", result.isClean(), joinRejections(result));
    SpecDocument applied = new SpecDocument();
    applied.loadJson(result.toLoadJson());
    String actual = new SpecDocumentMarkdown(model, applied).exportRoot(model.roots.get(0));
    check(
        "md.parse.reexport",
        actual.equals(expected),
        byteDiff("md.parse.reexport", actual, expected));
  }

  private static void testMarkdownMemoryLanding(SpecModel model) throws IOException {
    String expectedMd = read("expected.md");
    Map<String, Object> canonical = readJsonObject("state.json");
    SpecMarkdownResult result =
        new SpecDocumentMarkdown(model, new SpecDocument()).parse(expectedMd);
    check("md.land.clean", result.isClean(), joinRejections(result));
    SpecDocument landed = new SpecDocument();
    landed.loadJson(result.toLoadJson());
    check(
        "md.land.memory",
        landed.toJson().equals(canonical),
        jsonMismatch(landed.toJson(), canonical));
  }

  private static String joinRejections(SpecMarkdownResult result) {
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i < result.rejections.size(); i++) {
      if (i > 0) {
        sb.append("; ");
      }
      sb.append(result.rejections.get(i).toString());
    }
    return sb.toString();
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
    testModelMeta(model);
    testStateRoundTrip();
    testYamlEncode();
    testYamlDecodeRoundTrip();
    testMarkdownExport(model);
    testMarkdownRoundTrip(model);
    testMarkdownMemoryLanding(model);
    testReflection(model);
    testValidation(model);
    testOperations();

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
