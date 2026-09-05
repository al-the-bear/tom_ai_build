import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import tom_som_runtime.CodeSpecsAreaCatalog;
import tom_som_runtime.CodeSpecsExtract;
import tom_som_runtime.CodeSpecsExtractEntry;
import tom_som_runtime.CodeSpecsExtractError;
import tom_som_runtime.CodeSpecsExtractor;
import tom_som_runtime.CodeSpecsRouting;
import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsValidator;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.FormFieldSpec;
import tom_som_runtime.Json;
import tom_som_runtime.SomEditability;
import tom_som_runtime.SomFacade;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SomPatternError;
import tom_som_runtime.SomTextPattern;
import tom_som_runtime.SomVersionError;
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecCreationCode;
import tom_som_runtime.SpecCreationError;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecEditor;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecMatchSpan;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecModelStampCheck;
import tom_som_runtime.SpecNodeCreator;
import tom_som_runtime.SpecNodeKind;
import tom_som_runtime.SpecNodeProjection;
import tom_som_runtime.SpecQuery;
import tom_som_runtime.SpecQueryCursor;
import tom_som_runtime.SpecQueryEngine;
import tom_som_runtime.SpecQueryMatch;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecSectionId;
import tom_som_runtime.SpecSectionIdCollision;
import tom_som_runtime.SpecSerializationOrder;
import tom_som_runtime.SpecStateFilter;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;
import tom_som_runtime.SpecYamlContents;

/**
 * Shared-corpus conformance runner for the Java generic runtime — a plain-Java
 * port of {@code tests/conformance_runner.py}. JUnit is unavailable on the build
 * host (no Maven/Gradle/JUnit jar), so this is a dependency-free {@code main()}
 * that asserts every golden byte-for-byte and exits 0 on success, 1 on failure.
 *
 * <p>The tiers, in the order {@link #main} runs them: the model meta and its
 * generation stamp, the SOM §4.2 version contract, the state round-trip, the
 * YAML and Markdown codecs (export, re-import, memory landing, rejections), the
 * reflection / validation / operations / editor surfaces, section ids,
 * serialization order, the DocSpecs schema tier, and the SOM §9 tier — patterns,
 * queries, projection, the <b>Phase-4 CodeSpecs extract generator</b>, the cursor
 * script and node creation.
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
    check("model.classCount", model.classes.size() == 12, String.valueOf(model.classes.size()));
    SpecClass demo = model.classNamed("Demo");
    check("model.Demo.found", demo != null, "");
    if (demo != null) {
      List<String> names = new ArrayList<>();
      for (SpecField f : demo.fields) {
        names.add(f.name);
      }
      List<String> want =
          List.of(
              "title", "summary", "priority", "count", "ratio", "score", "details", "items",
              "refs", "cards", "meta", "control", "notes", "registry");
      check("model.Demo.fields", names.equals(want), names.toString());
    }
  }

  /**
   * The generation stamp: the five keys the exporter writes, and the staleness
   * verdict every runtime must reach from the same input.
   */
  @SuppressWarnings("unchecked")
  private static void testStamp(SpecModel model) throws IOException {
    // The shared model fixture carries the stamp, minus `containerRoot` (it is a
    // single synthetic document with no container class).
    check(
        "stamp.meta.generatedAt",
        model.generatedAt != null && model.generatedAt.getEpochSecond() == 1784534400L,
        String.valueOf(model.generatedAt));
    check("stamp.meta.metaSchemaVersion", Integer.valueOf(1).equals(model.metaSchemaVersion), "");
    check(
        "stamp.meta.classCount",
        model.classCount != null && model.classCount == model.classes.size(),
        "");
    check(
        "stamp.meta.rootCount",
        model.rootCount != null && model.rootCount == model.roots.size(),
        "");
    check("stamp.meta.containerRoot", model.containerRoot == null, "");

    Map<String, Object> table = readJsonObject("stamp_cases.json");
    check(
        "stamp.defaultMaxAgeDays",
        ((Number) table.get("defaultMaxAgeDays")).longValue()
            == SpecModel.DEFAULT_MAX_SNAPSHOT_AGE.toDays(),
        "");
    for (Object rawCase : (List<Object>) table.get("cases")) {
      Map<String, Object> kase = (Map<String, Object>) rawCase;
      String name = (String) kase.get("name");
      SpecModel loaded = SpecModel.fromJson((Map<String, Object>) kase.get("model"));
      Map<String, Object> want = (Map<String, Object>) kase.get("expect");
      Long gotEpoch = loaded.generatedAt == null ? null : loaded.generatedAt.getEpochSecond();
      Long wantEpoch = optionalLong(want.get("generatedAtEpochSeconds"));
      check(
          "stamp[" + name + "].generatedAt",
          Objects.equals(gotEpoch, wantEpoch),
          gotEpoch + " != " + wantEpoch);
      checkOptionalInt(name, "metaSchemaVersion", loaded.metaSchemaVersion, want);
      checkOptionalInt(name, "classCount", loaded.classCount, want);
      checkOptionalInt(name, "rootCount", loaded.rootCount, want);
      check(
          "stamp[" + name + "].containerRoot",
          Objects.equals(loaded.containerRoot, want.get("containerRoot")),
          loaded.containerRoot + " != " + want.get("containerRoot"));
      check(
          "stamp[" + name + "].actualClassCount",
          loaded.classes.size() == ((Number) want.get("actualClassCount")).intValue(),
          "");
      check(
          "stamp[" + name + "].actualRootCount",
          loaded.roots.size() == ((Number) want.get("actualRootCount")).intValue(),
          "");

      Map<String, Object> wc = (Map<String, Object>) kase.get("check");
      SpecModelStampCheck got =
          loaded.checkStamp(
              Duration.ofDays(((Number) wc.get("maxAgeDays")).longValue()),
              Instant.ofEpochSecond(((Number) wc.get("nowEpochSeconds")).longValue()));
      Long ageSeconds = got.age == null ? null : got.age.getSeconds();
      Long wantAge = optionalLong(wc.get("ageSeconds"));
      check(
          "stamp[" + name + "].ageSeconds",
          Objects.equals(ageSeconds, wantAge),
          ageSeconds + " != " + wantAge);
      checkFlag(name, "isAged", got.isAged(), wc);
      checkFlag(name, "classCountDisagrees", got.classCountDisagrees(), wc);
      checkFlag(name, "rootCountDisagrees", got.rootCountDisagrees(), wc);
      checkFlag(name, "countsDisagree", got.countsDisagree(), wc);
      checkFlag(name, "isStale", got.isStale(), wc);
      check(
          "stamp[" + name + "].warnings",
          got.warnings().equals(wc.get("warnings")),
          got.warnings() + " != " + wc.get("warnings"));
    }
  }

  private static Long optionalLong(Object raw) {
    return raw instanceof Number ? ((Number) raw).longValue() : null;
  }

  private static void checkOptionalInt(
      String caseName, String key, Integer got, Map<String, Object> want) {
    Long expected = optionalLong(want.get(key));
    Long actual = got == null ? null : got.longValue();
    check("stamp[" + caseName + "]." + key, Objects.equals(actual, expected),
        actual + " != " + expected);
  }

  private static void checkFlag(
      String caseName, String key, boolean got, Map<String, Object> want) {
    check("stamp[" + caseName + "]." + key, got == Boolean.TRUE.equals(want.get(key)),
        got + " != " + want.get(key));
  }

  /**
   * The SOM §4.2/§21 version contract: the classification and the refusal.
   *
   * <p>Both halves matter. {@code somEditabilityFor} is the single definition of
   * the rules and {@code checkModelVersion} throws from it, so a port that
   * classifies differently also throws differently — and a port that classifies
   * right but throws out of the <em>classifier</em> has broken the one promise
   * §21 makes about it.
   *
   * <p>Corpus tokens are spelled as the Dart constant names; Java's are
   * SCREAMING_SNAKE, so the token is translated before comparing.
   */
  @SuppressWarnings("unchecked")
  private static void testEditability() throws IOException {
    for (Object caseObj : (List<Object>) readJsonObject("editability_cases.json").get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      String generated = (String) c.get("generated");
      String documentVersion = (String) c.get("documentVersion");
      SomEditability want = editabilityToken((String) c.get("editability"));

      SomEditability got = SomFacade.somEditabilityFor(generated, documentVersion);
      check("editability[" + name + "].classification", got == want, got + " != " + want);

      String raised = null;
      try {
        SomFacade.checkModelVersion(generated, documentVersion);
      } catch (SomVersionError e) {
        raised = e.getMessage();
      }
      check("editability[" + name + "].rejects",
          (raised != null) == Boolean.TRUE.equals(c.get("rejects")), "raised=" + raised);
      check("editability[" + name + "].message",
          Objects.equals(raised, c.get("message")), raised + " != " + c.get("message"));
    }
  }

  private static SomEditability editabilityToken(String token) {
    switch (token) {
      case "editable":
        return SomEditability.EDITABLE;
      case "readOnlyCrossMajor":
        return SomEditability.READ_ONLY_CROSS_MAJOR;
      case "rejectedNewerMinor":
        return SomEditability.REJECTED_NEWER_MINOR;
      case "invalidVersion":
        return SomEditability.INVALID_VERSION;
      default:
        throw new IllegalArgumentException("unknown editability token: " + token);
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

  // --- markdown conformance (SOM §11) -------------------------------------

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
    // YRD3: the stored item id and stored headline round-trip through md.
    check(
        "md.parse.storedId",
        "REF-SPEC".equals(reDoc.itemSectionId("DEMO/REF-LST-1")),
        String.valueOf(reDoc.itemSectionId("DEMO/REF-LST-1")));
    check(
        "md.parse.headline",
        "Reference to the Spec".equals(reDoc.headline("DEMO/REF-LST-1")),
        String.valueOf(reDoc.headline("DEMO/REF-LST-1")));
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
   * Markdown/YAML convergence: parsing {@code expected.md} and applying it must
   * reproduce {@code state.json} (the YAML-route memory) exactly, proving both
   * formats converge on one in-memory document (SOM §8).
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

  /**
   * The SOM §11.7 rejection protocol: nothing is silently dropped. Each case asserts both halves
   * together — the full {@code (line, reason, anchor, message)} report <em>and</em> the document
   * that still landed. A port that drops an unplaceable block fails the first; one that reports it
   * and abandons the rest of the parse fails the second.
   */
  @SuppressWarnings("unchecked")
  private static void testMarkdownImportRejections(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("markdown_import_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      SpecMarkdownResult parsed =
          new SpecDocumentMarkdown(model, new SpecDocument()).parse((String) c.get("markdown"));
      List<Object> got = new ArrayList<>();
      for (SpecMarkdownRejection rej : parsed.rejections) {
        Map<String, Object> entry = new LinkedHashMap<>();
        entry.put("line", Integer.valueOf(rej.line));
        entry.put("reason", rej.reason.value);
        entry.put("anchor", rej.anchor);
        entry.put("message", rej.message);
        got.add(entry);
      }
      Object wantRejections = c.get("rejections");
      check(
          "md.reject[" + name + "].report",
          got.equals(wantRejections),
          jsonMismatch(got, wantRejections));
      SpecDocument landed = new SpecDocument();
      landed.loadJson(parsed.toLoadJson());
      Object wantDocument = c.get("document");
      check(
          "md.reject[" + name + "].landed",
          landed.toJson().equals(wantDocument),
          jsonMismatch(landed.toJson(), wantDocument));
    }
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
        case "setHeadline":
          doc.setHeadline((String) op.get("path"), (String) op.get("value"));
          break;
        case "headline":
          check(
              "op[" + n + "].headline",
              Objects.equals(doc.headline((String) op.get("path")), op.get("expect")),
              String.valueOf(doc.headline((String) op.get("path"))));
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

  /**
   * YRD7: the generic, meta-validated modification API ({@link SpecEditor}) —
   * typed value/form-field round-trips through the shared boundary helpers, enum
   * domain validation, and structural create/clear ops.
   *
   * <p>The script is stateful and ordered: it is replayed start to finish
   * against one document, so every language's generic editor reaches the
   * identical store state step by step.
   */
  @SuppressWarnings("unchecked")
  private static void testEditor(SpecModel model) throws IOException {
    SpecDocument doc = new SpecDocument();
    SpecEditor ed = SpecEditor.forModel(doc, model);
    List<Object> steps = readJsonArray("editor_cases.json");
    for (int n = 0; n < steps.size(); n++) {
      Map<String, Object> s = (Map<String, Object>) steps.get(n);
      String kind = (String) s.get("op");
      String path = (String) s.get("path");
      String field = (String) s.get("field");
      String at = "editor[" + n + "]." + kind + " ";
      switch (kind) {
        case "setValue":
          ed.setValue(path, s.get("value"));
          break;
        case "value": {
          Object got = ed.value(path);
          check(at + path, sameValue(got, s.get("expect")), String.valueOf(got));
          break;
        }
        case "setValueThrows":
          check(at + path, raisesArgument(() -> ed.setValue(path, s.get("value"))), "");
          break;
        case "valueThrows":
          check(at + path, raisesArgument(() -> ed.value(path)), "");
          break;
        case "setContent": // raw store write (bypasses the typed boundary)
          doc.setContent(path, (String) s.get("value"));
          break;
        case "rawContent":
          check(
              at + path,
              Objects.equals(doc.content(path), s.get("expect")),
              String.valueOf(doc.content(path)));
          break;
        case "setFormValue":
          ed.setFormValue(path, field, s.get("value"));
          break;
        case "formValue": {
          Object got = ed.formValue(path, field);
          check(at + path + "#" + field, sameValue(got, s.get("expect")), String.valueOf(got));
          break;
        }
        case "setFormValueThrows":
          check(
              at + path + "#" + field,
              raisesArgument(() -> ed.setFormValue(path, field, s.get("value"))),
              "");
          break;
        case "formValueThrows":
          check(at + path + "#" + field, raisesArgument(() -> ed.formValue(path, field)), "");
          break;
        case "rawFormField":
          check(
              at + path + "#" + field,
              Objects.equals(doc.formField(path, field), s.get("expect")),
              String.valueOf(doc.formField(path, field)));
          break;
        case "formFieldNames": {
          List<String> got = new ArrayList<>();
          for (FormFieldSpec ff : ed.formFields(path)) {
            got.add(ff.name);
          }
          List<String> want = stringList(s.get("expect"));
          check(at + path, got.equals(want), got + " != " + want);
          break;
        }
        case "formFieldNamesThrows":
          check(at + path, raisesArgument(() -> ed.formFields(path)), "");
          break;
        case "setHeadline":
          ed.setHeadline(path, (String) s.get("value"));
          break;
        case "headline":
          check(
              at + path,
              Objects.equals(ed.headline(path), s.get("expect")),
              String.valueOf(ed.headline(path)));
          break;
        case "headlineThrows":
          check(at + path, raisesArgument(() -> ed.headline(path)), "");
          break;
        case "itemSectionId": {
          String itemPath = (String) s.get("itemPath");
          check(
              at + itemPath,
              Objects.equals(doc.itemSectionId(itemPath), s.get("expect")),
              String.valueOf(doc.itemSectionId(itemPath)));
          break;
        }
        case "addListItem": {
          String listPath = (String) s.get("listPath");
          String itemPath =
              ed.addListItem(listPath, null, intAt(s, "month"), intAt(s, "day"));
          check(at + listPath, itemPath.equals(s.get("expectPath")), itemPath);
          if (s.containsKey("expectId")) {
            check(
                at + listPath + " generated id",
                Objects.equals(doc.itemSectionId(itemPath), s.get("expectId")),
                String.valueOf(doc.itemSectionId(itemPath)));
          }
          break;
        }
        case "addListItemThrows": {
          String listPath = (String) s.get("listPath");
          int month = intAt(s, "month");
          int day = intAt(s, "day");
          check(
              at + listPath,
              raisesArgument(() -> ed.addListItem(listPath, null, month, day)),
              "");
          break;
        }
        case "removeListItem": {
          String itemPath = (String) s.get("itemPath");
          check(
              at + itemPath,
              ed.removeListItem(itemPath) == Boolean.TRUE.equals(s.get("expect")),
              "");
          break;
        }
        case "clearSection":
          ed.clearSection(path);
          break;
        case "clearSectionThrows":
          check(at + path, raisesArgument(() -> ed.clearSection(path)), "");
          break;
        case "hasValuesUnder": {
          String prefix = (String) s.get("prefix");
          check(
              at + prefix,
              doc.hasValuesUnder(prefix) == Boolean.TRUE.equals(s.get("expect")),
              "");
          break;
        }
        default:
          check("editor[" + n + "].unknown", false, kind);
      }
    }
  }

  /**
   * Whether {@code fn} raises {@link IllegalArgumentException} — the caller-error
   * signal the editor's strict-write contract uses (the corpus's {@code *Throws}
   * ops only require that the operation fails).
   */
  private static boolean raisesArgument(Runnable fn) {
    try {
      fn.run();
      return false;
    } catch (IllegalArgumentException e) {
      return true;
    }
  }

  /**
   * Corpus-value equality for a typed read. Numbers compare by value, because
   * the corpus's JSON types an integral literal as {@link Integer} while a
   * {@code double} field legitimately reads back as {@link Double} ({@code 2} vs
   * {@code 2.0}) — the same {@code ==} the Dart and Python runners apply.
   */
  private static boolean sameValue(Object got, Object expect) {
    if (got instanceof Number && expect instanceof Number) {
      return ((Number) got).doubleValue() == ((Number) expect).doubleValue();
    }
    return Objects.equals(got, expect);
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

  /**
   * The SOM §14 DocSpecs tier: one shared schema, one case per violation rule.
   *
   * <p>The corpus carries the rule/sectionId/line triples the Dart reference
   * produces; matching them is what proves this port implements each rule at
   * all, rather than merely declaring its name.
   */
  @SuppressWarnings("unchecked")
  private static void testDocSpecs() throws IOException {
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(read("docspecs_schema.yaml"));
    check("docspecs.schemaWarnings", schema.warnings.isEmpty(), String.valueOf(schema.warnings));
    check("docspecs.rootSectionId", "D00".equals(schema.rootSectionId()), schema.rootSectionId());

    DocSpecsValidator validator = new DocSpecsValidator(schema);
    List<String> covered = new ArrayList<>();
    for (Object caseObj : readJsonArray("docspecs_cases.json")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      List<String> got = new ArrayList<>();
      for (DocSpecsViolation v : validator.validateMarkdown((String) c.get("markdown"))) {
        got.add(v.rule + "|" + v.sectionId + "|" + v.line);
      }
      List<String> want = new ArrayList<>();
      for (Object vObj : (List<Object>) c.get("violations")) {
        Map<String, Object> v = (Map<String, Object>) vObj;
        String rule = (String) v.get("rule");
        want.add(rule + "|" + v.get("sectionId") + "|" + ((Number) v.get("line")).intValue());
        covered.add(rule);
      }
      check("docspecs[" + name + "]", got.equals(want), got + " != " + want);
    }

    List<String> uncovered = new ArrayList<>();
    for (String rule : DocSpecsViolation.ALL_RULES) {
      if (!covered.contains(rule)) {
        uncovered.add(rule);
      }
    }
    check("docspecs.ruleCoverage", uncovered.isEmpty(), "uncovered: " + uncovered);
  }

  // --- SOM §9: text pattern / query / node creation -------------------------

  /**
   * The reference fixture document, rebuilt exactly as the Dart conformance
   * test's {@code _buildDocument()} does.
   *
   * <p>Deliberately <b>not</b> loaded from {@code state.json}: {@code toJson}
   * sorts each form's fields, so a reloaded document would hold
   * {@code DEMO/DET} alphabetically and a port that iterated the store would
   * look right for the wrong reason. Form fields are emitted in
   * <b>model-declaration</b> order (SOM §9, "Form-field order"), so the
   * populate order below is deliberately neither declaration order nor
   * alphabetical — a port that follows its store picks a different snippet and
   * fails {@code projection_cases.json}. {@link #testFixtureDocument} pins the
   * two views together.
   */
  private static SpecDocument buildDocument() {
    SpecDocument d = new SpecDocument();
    d.setContent("DEMO/TTL", "Hello");
    d.setContent("DEMO/SUM", "Line one\nLine two\n\nLine four");
    d.setContent("DEMO/PRI", "high");
    d.setContent("DEMO/CNT", "3");
    // Scrambled on purpose — see the doc comment. Do not "tidy" into order.
    d.setFormField("DEMO/DET", "priority", "high");
    d.setFormField("DEMO/DET", "weight", "2.5");
    d.setFormField("DEMO/DET", "owner", "Bob");
    d.setFormField("DEMO/DET", "active", "true");
    d.setFormField("DEMO/DET", "estimate", "8");
    d.setFormField("DEMO/DET", "contact", "bob@example.com");
    // The form preamble (SOM §11.4 rule 7): free text in the form's own content
    // slot, beside its fields. Line 2 is label-shaped AND shadows the declared
    // `owner` field, so the rule-3 escape has to hold on emit.
    d.setContent(
        "DEMO/DET",
        "Captured during the November review.\nOwner: this line is prose, not the field.");
    String i1 = d.addListItem("DEMO/items");
    d.setContent(i1 + "/label", "First");
    d.setContent(i1 + "/STS", "open");
    String i2 = d.addListItem("DEMO/items");
    d.setContent(i2 + "/label", "Second line A\nwith ```triple``` ticks");
    d.setContent(i2 + "/STS", "done");
    for (String ref : List.of("spec \u00a71.2", "ADR7")) {
      d.setContent(d.addListItem("DEMO/REF-LST"), ref);
    }
    d.setHeadline("DEMO/SUM", "Executive Summary");
    d.setHeadline("DEMO/DET", "Details & Contacts");
    d.setHeadline("DEMO/items", "Work Items");
    d.setItemSectionId("DEMO/REF-LST-1", "REF-SPEC");
    d.setHeadline("DEMO/REF-LST-1", "Reference to the Spec");
    String c1 = d.addListItem("DEMO/CARD-LST");
    d.setItemSectionId(c1, "CARD-ALPHA");
    d.setHeadline(c1, "Alpha Card");
    d.setFormField(c1 + "/content", "note", "first card");
    String c2 = d.addListItem("DEMO/CARD-LST");
    d.setFormField(c2 + "/content", "note", "second card");
    d.setContent("DEMO/META/OWNR", "alice");
    for (String tag : List.of("on", "no", "1:30", "plain")) {
      d.setContent(d.addListItem("DEMO/META/tags"), tag);
    }
    d.setContent("DEMO/control/CTRL-SUM", "Controlled summary");
    d.setContent("DEMO/control/owner", "ctrl-owner");
    // The `section`-kind member (`Notes`, class id `NOTE`, id-less field): a
    // section collapses into its target class exactly as a complex member does,
    // and keys on the target class's id when the field carries none.
    d.setContent("DEMO/notes/NOTE-BDY", "Section-kind body");
    return d;
  }

  /**
   * The hand-built fixture is the same document {@code state.json} was written
   * from — so the §9 tables and every other table describe one document, not two
   * that happen to look alike.
   */
  private static void testFixtureDocument() throws IOException {
    Map<String, Object> state = readJsonObject("state.json");
    Map<String, Object> built = buildDocument().toJson();
    check("fixture.matchesState", built.equals(state), jsonMismatch(built, state));
  }

  /**
   * SOM §9: the portable pattern subset ({@link SomTextPattern}). Hand-rolled on
   * purpose — {@code java.util.regex} is leftmost-first but Unicode-case-folding
   * and would put this port's {@code matchSpans} outside the nine-language
   * contract the moment a case left the corpus.
   */
  @SuppressWarnings("unchecked")
  private static void testPatterns() throws IOException {
    List<Object> cases = readJsonArray("pattern_cases.json");
    int rejections = 0;
    int matchTables = 0;
    for (int n = 0; n < cases.size(); n++) {
      Map<String, Object> c = (Map<String, Object>) cases.get(n);
      String source = (String) c.get("pattern");
      boolean regex = Boolean.TRUE.equals(c.get("regex"));
      boolean ci = Boolean.TRUE.equals(c.get("caseInsensitive"));
      String at = "pattern[" + n + "] " + repr(source);
      if (Boolean.TRUE.equals(c.get("error"))) {
        rejections++;
        check(at + " rejected", rejectsPattern(source), "compiled without error");
        continue;
      }
      matchTables++;
      SomTextPattern p =
          regex ? SomTextPattern.compile(source, ci) : SomTextPattern.literal(source, ci);
      List<String> got = new ArrayList<>();
      for (SpecMatchSpan s : p.allMatches((String) c.get("text"))) {
        got.add(s.start + "-" + s.end);
      }
      List<String> want = spanList(c.get("spans"));
      check(at + " over " + repr((String) c.get("text")), got.equals(want), got + " != " + want);
    }
    // A table of matches alone would let a port accept everything; a table of
    // rejections alone would let one reject everything.
    check("pattern.tableHasRejections", rejections > 0, "no error case in the table");
    check("pattern.tableHasMatches", matchTables > 0, "no match case in the table");
  }

  /** Whether compiling {@code source} raises {@link SomPatternError}. */
  private static boolean rejectsPattern(String source) {
    try {
      SomTextPattern.compile(source);
      return false;
    } catch (SomPatternError e) {
      return true;
    }
  }

  /** The corpus's {@code [[start, end], …]} spans as comparable {@code "start-end"} keys. */
  @SuppressWarnings("unchecked")
  private static List<String> spanList(Object array) {
    List<String> out = new ArrayList<>();
    for (Object o : (List<Object>) array) {
      List<Object> pair = (List<Object>) o;
      out.add(((Number) pair.get(0)).intValue() + "-" + ((Number) pair.get(1)).intValue());
    }
    return out;
  }

  /**
   * Rebuilds a {@link SpecQuery} from its corpus wire form.
   *
   * <p>Every port needs this same decode, so its shape <i>is</i> part of the
   * contract: an absent key means "dimension unset", never a default that happens
   * to match.
   */
  @SuppressWarnings("unchecked")
  private static SpecQuery queryFromJson(Map<String, Object> j) {
    Set<SpecNodeKind> kinds = null;
    Object rawKinds = j.get("kinds");
    if (rawKinds != null) {
      kinds = new LinkedHashSet<>();
      for (String k : stringList(rawKinds)) {
        kinds.add(nodeKindNamed(k));
      }
    }
    Object state = j.get("state");
    return new SpecQuery(
        (String) j.get("text"),
        Boolean.TRUE.equals(j.get("regex")),
        Boolean.TRUE.equals(j.get("caseInsensitive")),
        kinds,
        (String) j.get("className"),
        (String) j.get("sectionIdExact"),
        (String) j.get("sectionIdPrefix"),
        (String) j.get("pathGlob"),
        (String) j.get("mapsTo"),
        (String) j.get("detailedIn"),
        state == null ? null : SpecStateFilter.parse((String) state));
  }

  private static SpecNodeKind nodeKindNamed(String raw) {
    for (SpecNodeKind k : SpecNodeKind.values()) {
      if (k.value.equals(raw)) {
        return k;
      }
    }
    throw new IllegalArgumentException("\"" + raw + "\" is not a node kind");
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> queryOf(Map<String, Object> c) {
    return (Map<String, Object>) c.get("query");
  }

  /** One cursor match in the corpus's record shape, for exact list comparison. */
  private static Map<String, Object> matchRecord(SpecQueryMatch m) {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("path", m.path);
    o.put("kind", m.kind.value);
    o.put("classId", m.classId);
    o.put("headline", m.headline);
    o.put("snippet", m.snippet);
    List<Object> spans = new ArrayList<>();
    for (SpecMatchSpan s : m.matchSpans) {
      spans.add(s.start + "-" + s.end);
    }
    o.put("spans", spans);
    return o;
  }

  /** The same record, read off the committed table. */
  private static Map<String, Object> expectedMatchRecord(Map<String, Object> c) {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("path", c.get("path"));
    o.put("kind", c.get("kind"));
    o.put("classId", c.get("classId"));
    o.put("headline", c.get("headline"));
    o.put("snippet", c.get("snippet"));
    o.put("spans", new ArrayList<Object>(spanList(c.get("spans"))));
    return o;
  }

  /**
   * SOM §9: the {@link SpecQueryEngine} surface — every committed query
   * reproduces its match list <b>in order</b>, and (separately) {@code count}
   * agrees with that list's length.
   *
   * <p>The second assertion is not the first one restated: a port that drains for
   * {@code toList} but returns the raw candidate count for {@code count} passes
   * the first and fails this one.
   */
  @SuppressWarnings("unchecked")
  private static void testQueries(SpecModel model) throws IOException {
    SpecQueryEngine engine = new SpecQueryEngine(model, buildDocument());
    for (Object caseObj : readJsonArray("query_cases.json")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      List<Object> want = new ArrayList<>();
      for (Object mObj : (List<Object>) c.get("matches")) {
        want.add(expectedMatchRecord((Map<String, Object>) mObj));
      }
      List<Object> got = new ArrayList<>();
      for (SpecQueryMatch m : engine.query(queryFromJson(queryOf(c))).toList()) {
        got.add(matchRecord(m));
      }
      check("query[" + name + "]", got.equals(want), jsonMismatch(got, want));

      int count = engine.query(queryFromJson(queryOf(c))).count();
      check(
          "query[" + name + "].count",
          count == want.size(),
          count + " != " + want.size());
    }
  }

  /** SOM §9: the full {@code projectNodes()} walk, in document order. */
  private static void testProjection(SpecModel model) throws IOException {
    SpecQueryEngine engine = new SpecQueryEngine(model, buildDocument());
    List<Object> got = new ArrayList<>();
    for (SpecNodeProjection p : engine.projectNodes()) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("path", p.path);
      o.put("kind", p.kind.value);
      o.put("classId", p.classId);
      o.put("sectionId", p.sectionId);
      o.put("mapsTo", p.mapsTo);
      o.put("detailedIn", p.detailedIn);
      o.put("headline", p.headline);
      o.put("searchableStrings", new ArrayList<Object>(p.searchableStrings));
      o.put("hasValue", p.hasValue);
      got.add(o);
    }
    List<Object> want = readJsonArray("projection_cases.json");
    check("projection.count", got.size() == want.size(), got.size() + " != " + want.size());
    for (int i = 0; i < Math.min(got.size(), want.size()); i++) {
      check(
          "projection[" + i + "]",
          got.get(i).equals(want.get(i)),
          jsonMismatch(got.get(i), want.get(i)));
    }
  }

  /**
   * The Phase-4 CodeSpecs extract generator ({@code codespecs_mapping.md}
   * §1.1.1): the routing verdicts, the per-area extracts with their YAML and
   * Markdown artifacts, the copy-don't-compose guard, the {@code @FollowUpKind}
   * exclusion, and the {@code ROUTE-TOTAL} error cases.
   *
   * <p>The catalogue rides in the corpus rather than in this runtime: it is the
   * machine-readable form of {@code codespecs_mapping.md} §4.1/§4.4.3/§4.4.6,
   * authored once and read by all nine ports.
   */
  @SuppressWarnings("unchecked")
  private static void testCodeSpecsExtract(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("codespecs_extract_cases.json");
    CodeSpecsAreaCatalog catalog =
        CodeSpecsAreaCatalog.fromJson((Map<String, Object>) table.get("catalog"));
    CodeSpecsExtractor extractor = new CodeSpecsExtractor(model, buildDocument(), catalog);

    // 1. The routing diagnostic — every class node the walk reaches, in order.
    List<Object> gotRoutings = new ArrayList<>();
    for (CodeSpecsRouting r : extractor.routings()) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("path", r.path);
      o.put("className", r.className);
      o.put("verdict", r.verdict.value);
      o.put("values", new ArrayList<Object>(r.values));
      o.put("note", r.note);
      o.put("declaredAt", r.declaredAt);
      gotRoutings.add(o);
    }
    Object wantRoutings = table.get("routings");
    check(
        "codeSpecs.routings",
        gotRoutings.equals(wantRoutings),
        jsonMismatch(gotRoutings, wantRoutings));

    // 2. The extracts, byte for byte — the record, then the two artifacts (kept
    // separate only so a divergence reports a line number instead of 8 KB of
    // YAML).
    List<CodeSpecsExtract> extracts = extractor.extractAll();
    List<Object> wantExtracts = (List<Object>) table.get("extracts");
    check(
        "codeSpecs.extracts.count",
        extracts.size() == wantExtracts.size(),
        extracts.size() + " != " + wantExtracts.size());
    for (int i = 0; i < Math.min(extracts.size(), wantExtracts.size()); i++) {
      CodeSpecsExtract x = extracts.get(i);
      Map<String, Object> want = (Map<String, Object>) wantExtracts.get(i);
      String at = "codeSpecs.extract[" + x.area.code + "]";
      Map<String, Object> got = new LinkedHashMap<>();
      got.put("area", x.area.code);
      got.put("canonicalId", x.area.canonicalId);
      got.put("part", x.area.kindValue());
      got.put("documentRoot", x.documentRoot);
      got.put("fileStem", x.fileStem());
      got.put("projects", new ArrayList<Object>(x.projects));
      got.put("citableParts", new ArrayList<Object>(x.citableParts));
      List<Object> gotEntries = new ArrayList<>();
      for (CodeSpecsExtractEntry e : x.entries) {
        Map<String, Object> o = new LinkedHashMap<>();
        o.put("sectionId", e.sectionId);
        o.put("headline", e.headline);
        o.put("path", e.path);
        o.put("className", e.className);
        o.put("fieldName", e.fieldName);
        o.put("formField", e.formField);
        o.put("routedBy", e.routedBy);
        o.put("routedAt", e.routedAt);
        o.put("routingNote", e.routingNote);
        o.put("value", e.value);
        gotEntries.add(o);
      }
      got.put("entries", gotEntries);
      Map<String, Object> wantRecord = new LinkedHashMap<>(want);
      wantRecord.remove("yaml");
      wantRecord.remove("markdown");
      check(at, got.equals(wantRecord), jsonMismatch(got, wantRecord));
      check(
          at + ".yaml",
          x.toYaml().equals(want.get("yaml")),
          byteDiff(at + ".yaml", x.toYaml(), (String) want.get("yaml")));
      check(
          at + ".markdown",
          x.toMarkdown().equals(want.get("markdown")),
          byteDiff(at + ".markdown", x.toMarkdown(), (String) want.get("markdown")));
    }

    // 3. The guard `codespecs_derivation_contract.md` §2.8 C1 rests on, carried
    // in the corpus rather than left to each port's own conscience: the
    // generator may copy and index, it may not compose. Membership, not
    // substring — that is what makes "verbatim" mean verbatim rather than
    // "derived from".
    Map<String, Object> state = readJsonObject("state.json");
    Set<String> stored = new LinkedHashSet<>();
    for (Object v : ((Map<String, Object>) state.get("content")).values()) {
      stored.add((String) v);
    }
    for (Object section : ((Map<String, Object>) state.get("forms")).values()) {
      for (Object v : ((Map<String, Object>) section).values()) {
        stored.add((String) v);
      }
    }
    check("codeSpecs.storedValues", !stored.isEmpty(), "no stored value in state.json");
    List<String> emitted = new ArrayList<>();
    for (Object xObj : wantExtracts) {
      Map<String, Object> x = (Map<String, Object>) xObj;
      for (Object eObj : (List<Object>) x.get("entries")) {
        Map<String, Object> e = (Map<String, Object>) eObj;
        String value = (String) e.get("value");
        emitted.add(value);
        check(
            "codeSpecs.verbatim[" + x.get("area") + " " + e.get("path") + "]",
            stored.contains(value),
            "was not copied from the document");
      }
    }

    // 4. `Control` is populated, and populated distinctively, so its absence
    // cannot be an accident of an empty section.
    check("codeSpecs.followUp.summary", !emitted.contains("Controlled summary"), "");
    check("codeSpecs.followUp.owner", !emitted.contains("ctrl-owner"), "");
    // …and neither does a @NoArtifact section's own leaf.
    check("codeSpecs.noArtifact.leaf", !emitted.contains("alice"), "");

    // 5. `ROUTE-TOTAL`: a section routed nowhere fails `extractAll()` loudly and
    // is *reported* — not thrown on — by `routings()`.
    //
    // Each error case carries its own model and state rather than mutating the
    // shared fixture: `model.meta.json` is a VALID model by construction (§10.2
    // `ROUTE-TOTAL` holds over it), and a port should not have to break it to
    // run this case. `state` is the ordinary `state.json` shape, so every
    // runtime already has the loader.
    for (Object caseObj : (List<Object>) table.get("errorCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      SpecModel errModel = SpecModel.fromJson((Map<String, Object>) c.get("model"));
      SpecDocument errDoc = documentFromState((Map<String, Object>) c.get("state"));
      CodeSpecsExtractor errExtractor = new CodeSpecsExtractor(errModel, errDoc, catalog);
      Map<String, Object> want = (Map<String, Object>) c.get("expect");
      String at = "codeSpecs.error[" + name + "]";

      CodeSpecsExtractError err = null;
      try {
        errExtractor.extractAll();
      } catch (CodeSpecsExtractError e) {
        err = e;
      }
      check(at + ".throws", err != null, "extractAll() succeeded");
      if (err != null) {
        check(at + ".path", Objects.equals(err.path, want.get("path")), err.path);
        check(
            at + ".className",
            Objects.equals(err.className, want.get("className")),
            err.className);
        check(
            at + ".message",
            err.getMessage().contains((String) want.get("messageContains")),
            err.getMessage());
      }
      List<String> verdicts = new ArrayList<>();
      for (CodeSpecsRouting r : errExtractor.routings()) {
        if (r.path.equals(want.get("path"))) {
          verdicts.add(r.verdict.value);
        }
      }
      List<Object> wantVerdicts = new ArrayList<>();
      wantVerdicts.add(want.get("routingVerdict"));
      check(at + ".routing", verdicts.equals(wantVerdicts), verdicts + " != " + wantVerdicts);
    }

    // 6. Root scoping (`codespecs_prompt.md` §5): the walk starts at ONE root.
    // The models here carry two, because over a single-root model "walks the
    // named root" and "walks every root" give the same answer.
    for (Object caseObj : (List<Object>) table.get("rootCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      SpecModel rootModel = SpecModel.fromJson((Map<String, Object>) c.get("model"));
      SpecDocument rootDoc = documentFromState((Map<String, Object>) c.get("state"));
      Map<String, Object> want = (Map<String, Object>) c.get("expect");
      String at = "codeSpecs.root[" + name + "]";

      CodeSpecsExtractor x = null;
      CodeSpecsExtractError err = null;
      try {
        x = new CodeSpecsExtractor(rootModel, rootDoc, catalog, (String) c.get("rootType"));
      } catch (CodeSpecsExtractError e) {
        err = e;
      }
      if (Boolean.TRUE.equals(want.get("fails"))) {
        check(at + ".thrown", err != null, "the extractor bound instead of failing");
        if (err != null) {
          check(at + ".path", Objects.equals(err.path, want.get("path")), err.path);
          check(
              at + ".className",
              Objects.equals(err.className, want.get("className")),
              err.className);
          check(
              at + ".message",
              err.getMessage().contains((String) want.get("messageContains")),
              err.getMessage());
        }
        continue;
      }
      check(at + ".bound", x != null, String.valueOf(err));
      if (x == null) {
        continue;
      }
      check(at + ".root", Objects.equals(x.root.type, want.get("root")), x.root.type);
      // `routings` and `extractAll` walk the same resolved root, so the verdict
      // sequence is scoped too — that is what makes the bare `@Document` root
      // of case 2 the corpus's `documentRoot` producer.
      List<String> rootVerdicts = new ArrayList<>();
      for (CodeSpecsRouting r : x.routings()) {
        rootVerdicts.add(r.verdict.value);
      }
      check(
          at + ".routingVerdicts",
          rootVerdicts.equals(want.get("routingVerdicts")),
          rootVerdicts + " != " + want.get("routingVerdicts"));
      List<CodeSpecsExtract> rootExtracts = x.extractAll();
      check(
          at + ".documentRoot",
          Objects.equals(rootExtracts.get(0).documentRoot, want.get("documentRoot")),
          rootExtracts.get(0).documentRoot);
      List<String> paths = new ArrayList<>();
      for (CodeSpecsExtract g : rootExtracts) {
        for (CodeSpecsExtractEntry e : g.entries) {
          paths.add(e.path);
        }
      }
      check(at + ".paths", paths.equals(want.get("paths")), paths + " != " + want.get("paths"));
    }
  }

  /**
   * SOM §9: a scripted cursor session over a freshly built document. The
   * {@code removeListItem} step mutates the document mid-iteration — the cursor
   * must skip the now-dead candidate rather than return it, which is the whole
   * point of re-validating each step against the live document.
   */
  @SuppressWarnings("unchecked")
  private static void testCursorScript(SpecModel model) throws IOException {
    SpecDocument d = buildDocument();
    SpecQueryEngine engine = new SpecQueryEngine(model, d);
    SpecQueryCursor cursor = null;
    List<Object> steps = readJsonArray("cursor_cases.json");
    for (int n = 0; n < steps.size(); n++) {
      Map<String, Object> s = (Map<String, Object>) steps.get(n);
      String kind = (String) s.get("op");
      String at = "cursor[" + n + "]." + kind;
      switch (kind) {
        case "open":
          cursor = engine.query(queryFromJson(queryOf(s)));
          break;
        case "count": {
          int got = cursor.count();
          check(at, got == ((Number) s.get("expect")).intValue(), String.valueOf(got));
          break;
        }
        case "take": {
          List<String> got = new ArrayList<>();
          for (SpecQueryMatch m : cursor.take(intAt(s, "n"))) {
            got.add(m.path);
          }
          List<String> want = stringList(s.get("expect"));
          check(at, got.equals(want), got + " != " + want);
          break;
        }
        case "next": {
          SpecQueryMatch m = cursor.next();
          String got = m == null ? null : m.path;
          check(at, Objects.equals(got, s.get("expect")), String.valueOf(got));
          break;
        }
        case "toList": {
          List<String> got = new ArrayList<>();
          for (SpecQueryMatch m : cursor.toList()) {
            got.add(m.path);
          }
          List<String> want = stringList(s.get("expect"));
          check(at, got.equals(want), got + " != " + want);
          break;
        }
        case "removeListItem":
          d.removeListItem((String) s.get("itemPath"));
          break;
        default:
          check("cursor[" + n + "].unknown", false, kind);
      }
    }
  }

  /**
   * SOM §9: the stateless {@code checkAddNode} gate. Each probe runs against a
   * <b>fresh</b> document, so the table is order-independent.
   *
   * <p>Only the {@link SpecCreationCode} is asserted, never the message: the code
   * is the contract, the message is prose, and pinning prose across nine
   * languages would make rewording a nine-package change. The table exercises
   * every code, which {@link #testNodeCreationCoverage} enforces.
   */
  @SuppressWarnings("unchecked")
  private static void testNodeCreationCases(SpecModel model) throws IOException {
    for (Object caseObj : readJsonArray("node_creation_cases.json")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      SpecDocument d = buildDocument();
      String parentPath = (String) c.get("parentPath");
      String childSegment = (String) c.get("childSegment");
      SpecCreationError err =
          SpecNodeCreator.checkAddNode(
              model, d, parentPath, childSegment, (String) c.get("itemId"));
      boolean accepted = err == null;
      check(
          "nodeCreation[" + name + "].accepted",
          accepted == Boolean.TRUE.equals(c.get("accepted")),
          accepted ? "accepted" : String.valueOf(err));
      if (err != null) {
        check("nodeCreation[" + name + "].code", err.code.value.equals(c.get("code")), err.code.value);
        check("nodeCreation[" + name + "].parentPath", err.parentPath.equals(parentPath), err.parentPath);
        check(
            "nodeCreation[" + name + "].childSegment",
            err.childSegment.equals(childSegment),
            err.childSegment);
      }
    }
  }

  /** Every {@link SpecCreationCode} is exercised by the table (nothing is declared-only). */
  @SuppressWarnings("unchecked")
  private static void testNodeCreationCoverage() throws IOException {
    List<String> covered = new ArrayList<>();
    for (Object caseObj : readJsonArray("node_creation_cases.json")) {
      Object code = ((Map<String, Object>) caseObj).get("code");
      if (code != null) {
        covered.add((String) code);
      }
    }
    List<String> uncovered = new ArrayList<>();
    for (SpecCreationCode code : SpecCreationCode.values()) {
      if (!covered.contains(code.value)) {
        uncovered.add(code.value);
      }
    }
    check("nodeCreation.codeCoverage", uncovered.isEmpty(), "uncovered: " + uncovered);
  }

  /**
   * SOM §9: the sequential {@link SpecNodeCreator} script — one document, so each
   * step sees what the previous produced (generated ids, item numbering).
   */
  @SuppressWarnings("unchecked")
  private static void testNodeCreationScript(SpecModel model) throws IOException {
    SpecDocument d = buildDocument();
    SpecNodeCreator creator = new SpecNodeCreator(model, d);
    List<Object> steps = readJsonArray("node_creation_script.json");
    for (int n = 0; n < steps.size(); n++) {
      Map<String, Object> s = (Map<String, Object>) steps.get(n);
      String kind = (String) s.get("op");
      String at = "nodeScript[" + n + "]." + kind;
      switch (kind) {
        case "add": {
          String path =
              creator.add(
                  (String) s.get("parentPath"),
                  (String) s.get("childSegment"),
                  (String) s.get("itemId"),
                  intAt(s, "month"),
                  intAt(s, "day"));
          check(at, path.equals(s.get("expectPath")), path);
          check(
              at + " id",
              Objects.equals(d.itemSectionId(path), s.get("expectId")),
              String.valueOf(d.itemSectionId(path)));
          break;
        }
        case "addThrows": {
          // The date is irrelevant to a rejected add, but must be supplied:
          // 2026-03-04, the same instant the Dart reference uses.
          String code = null;
          try {
            creator.add(
                (String) s.get("parentPath"),
                (String) s.get("childSegment"),
                (String) s.get("itemId"),
                3,
                4);
          } catch (SpecCreationError e) {
            code = e.code.value;
          }
          check(at, Objects.equals(code, s.get("expectCode")), String.valueOf(code));
          break;
        }
        case "finalState":
          check(at, d.toJson().equals(s.get("expect")), jsonMismatch(d.toJson(), s.get("expect")));
          break;
        default:
          check("nodeScript[" + n + "].unknown", false, kind);
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
    SomMetaTree tree = SomMetaBridge.buildSomMetaTree(model, null);
    testModelMeta(model);
    testStamp(model);
    testEditability();
    testStateRoundTrip();
    testYamlEncode(tree);
    testYamlDecodeRoundTrip(tree);
    testMarkdownExport(model);
    testMarkdownRoundTrip(model);
    testMarkdownMemoryLanding(model);
    testMarkdownImportRejections(model);
    testReflection(model);
    testValidation(model);
    testOperations();
    testEditor(model);
    testSectionId();
    testSerializationOrder();
    testDocSpecs();
    testFixtureDocument();
    testPatterns();
    testQueries(model);
    testProjection(model);
    testCodeSpecsExtract(model);
    testCursorScript(model);
    testNodeCreationCases(model);
    testNodeCreationCoverage();
    testNodeCreationScript(model);

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
