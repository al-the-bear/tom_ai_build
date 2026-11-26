import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

import tom_som_runtime.CodeSpecsArea;
import tom_som_runtime.CodeSpecsAreaCatalog;
import tom_som_runtime.CodeSpecsExtract;
import tom_som_runtime.CodeSpecsExtractEntry;
import tom_som_runtime.CodeSpecsExtractError;
import tom_som_runtime.CodeSpecsExtractSet;
import tom_som_runtime.CodeSpecsExtractor;
import tom_som_runtime.CodeSpecsExcludedArea;
import tom_som_runtime.CodeSpecsGate;
import tom_som_runtime.CodeSpecsGateCheckResult;
import tom_som_runtime.CodeSpecsGateFinding;
import tom_som_runtime.CodeSpecsGateReport;
import tom_som_runtime.CodeSpecsGateEntry;
import tom_som_runtime.CodeSpecsGateGap;
import tom_som_runtime.CodeSpecsGateRecord;
import tom_som_runtime.CodeSpecsGateVerdict;
import tom_som_runtime.CodeSpecsRecordError;
import tom_som_runtime.CodeSpecsRouting;
import tom_som_runtime.CodeSpecsStep;
import tom_som_runtime.DocSpecsDocument;
import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsValidator;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.FormFieldSpec;
import tom_som_runtime.Json;
import tom_som_runtime.SomEditability;
import tom_som_runtime.SomFacade;
import tom_som_runtime.SomList;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SomPatternError;
import tom_som_runtime.SomTextPattern;
import tom_som_runtime.SomVersionError;
import tom_som_runtime.SpecAssemblyOverlap;
import tom_som_runtime.SpecClass;
import tom_som_runtime.SpecBackfill;
import tom_som_runtime.SpecBackfillError;
import tom_som_runtime.SpecBackfillOptions;
import tom_som_runtime.SpecDeriveFields;
import tom_som_runtime.SpecDeriveOptions;
import tom_som_runtime.SpecDeriveResult;
import tom_som_runtime.SpecDocumentSet;
import tom_som_runtime.SpecDocumentSetError;
import tom_som_runtime.SpecPrefill;
import tom_som_runtime.SpecPrefillError;
import tom_som_runtime.SpecPrefillOptions;
import tom_som_runtime.SpecRenameChange;
import tom_som_runtime.SpecRenameError;
import tom_som_runtime.SpecSyncFinding;
import tom_som_runtime.SpecSyncPair;
import tom_som_runtime.SpecSyncReport;
import tom_som_runtime.SpecCreationCode;
import tom_som_runtime.SpecCreationError;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentAssembly;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecEditor;
import tom_som_runtime.SpecField;
import tom_som_runtime.SpecGenerationUnit;
import tom_som_runtime.SpecGenerationUnitMapping;
import tom_som_runtime.SpecGenerationUnits;
import tom_som_runtime.SpecImpactFolder;
import tom_som_runtime.SpecImpactLevel;
import tom_som_runtime.SpecImpactRootWalk;
import tom_som_runtime.SpecImpactWalk;
import tom_som_runtime.SpecListItemMove;
import tom_som_runtime.SpecMarkdownImport;
import tom_som_runtime.SpecMarkdownRendition;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecMatchSpan;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecModelStampCheck;
import tom_som_runtime.SpecNodeCreator;
import tom_som_runtime.SpecNodeKind;
import tom_som_runtime.SpecNodeProjection;
import tom_som_runtime.SpecParagraph;
import tom_som_runtime.SpecQuery;
import tom_som_runtime.SpecQueryCursor;
import tom_som_runtime.SpecQueryEngine;
import tom_som_runtime.SpecQueryMatch;
import tom_som_runtime.SpecQuestionDraft;
import tom_som_runtime.SpecReflection;
import tom_som_runtime.SpecResolution;
import tom_som_runtime.SpecMarkDecision;
import tom_som_runtime.SpecMarkEntry;
import tom_som_runtime.SpecMarkedChange;
import tom_som_runtime.SpecAnswerExtract;
import tom_som_runtime.SpecAnswerRenderOptions;
import tom_som_runtime.SpecAnswers;
import tom_som_runtime.SpecReviewAnnotation;
import tom_som_runtime.SpecReviewAnnotationError;
import tom_som_runtime.SpecReviewAnnotations;
import tom_som_runtime.NotationElement;
import tom_som_runtime.NotationFinding;
import tom_som_runtime.NotationFindingCode;
import tom_som_runtime.NotationScan;
import tom_som_runtime.SpecNotation;
import tom_som_runtime.SpecAppendixEntry;
import tom_som_runtime.SpecDocumentStrip;
import tom_som_runtime.SpecReadableHeader;
import tom_som_runtime.SpecReadableSource;
import tom_som_runtime.SpecStripFinding;
import tom_som_runtime.SpecStripKept;
import tom_som_runtime.SpecStripMerge;
import tom_som_runtime.SpecStripMergeOptions;
import tom_som_runtime.SpecStripMergeResult;
import tom_som_runtime.SpecStripResult;
import tom_som_runtime.SpecStripOptions;
import tom_som_runtime.SpecStripPiece;
import tom_som_runtime.SpecStripTextResult;
import tom_som_runtime.SpecStripUsageError;
import tom_som_runtime.SpecReviewMember;
import tom_som_runtime.SpecReviewMerge;
import tom_som_runtime.SpecReviewMergeError;
import tom_som_runtime.SpecReviewMergeOptions;
import tom_som_runtime.SpecReviewMergeResult;
import tom_som_runtime.SpecReviewedCopy;
import tom_som_runtime.SpecRoot;
import tom_som_runtime.SpecSectionId;
import tom_som_runtime.SpecSectionIdCollision;
import tom_som_runtime.SpecSchemaValidation;
import tom_som_runtime.SpecSerializationOrder;
import tom_som_runtime.SpecStateFilter;
import tom_som_runtime.SpecTypedValues;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;
import tom_som_runtime.SpecYamlContents;
import tom_som_runtime.SpecDerivation;
import tom_som_runtime.SpecExtractsLinks;
import tom_som_runtime.SpecInverseOf;
import tom_som_runtime.SpecPlace;
import tom_som_runtime.SpecPlaceException;
import tom_som_runtime.SpecPlaceFilter;
import tom_som_runtime.SpecPlaceProblem;
import tom_som_runtime.SpecSameAs;
import tom_som_runtime.SpecSameAsBinding;
import tom_som_runtime.SpecSummaryOf;
import tom_som_runtime.SpecSync;
import tom_som_runtime.SpecValidationCode;

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
 * queries, projection, the <b>Phase-4 CodeSpecs extract generator</b> and the
 * reading back of its extracts and gate record, the cursor
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

  // --- codespecs_gate_cases.json: the Stage-A gate, A1–A5 -------------------

  /**
   * Every case of the gate table: the catalogue is {@code catalog} plus the
   * case's (or the table's) {@code gate} block, the schema the case's (or the
   * table's) {@code schema}. A case key that is <b>present with null</b>
   * overrides the default — no schema, or a catalogue without gate tables — so
   * presence is tested with {@code containsKey}, not by the value.
   */
  @SuppressWarnings("unchecked")
  private static void testCodeSpecsGate() throws IOException {
    Map<String, Object> table = readJsonObject("codespecs_gate_cases.json");
    Map<String, Object> meta = readJsonObject("model.meta.json");
    for (Object raw : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) raw;
      String name = "codespecs gate: " + c.get("name");
      Object got;
      try {
        got = runGateCase(table, c, meta);
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
        continue;
      }
      check(name, got.equals(expectFor(c)), jsonMismatch(got, expectFor(c)));
    }
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> runGateCase(
      Map<String, Object> table, Map<String, Object> c, Map<String, Object> meta) {
    Map<String, Object> catalogJson =
        new LinkedHashMap<>((Map<String, Object>) table.get("catalog"));
    Object gate = c.containsKey("gate") ? c.get("gate") : table.get("gate");
    if (gate != null) {
      catalogJson.put("gate", gate);
    }
    Object schemaYaml = c.containsKey("schema") ? c.get("schema") : table.get("schema");
    Object modelJson = c.get("model") != null ? c.get("model") : meta;
    SpecModel model = SpecModel.fromJson((Map<String, Object>) modelJson);
    SpecDocument doc = documentFromState((Map<String, Object>) c.get("state"));
    CodeSpecsGateReport report =
        new CodeSpecsGate(
                model,
                doc,
                CodeSpecsAreaCatalog.fromJson(catalogJson),
                schemaYaml == null ? null : DocSpecsSchema.fromYamlText((String) schemaYaml))
            .run();
    List<Object> results = new ArrayList<>();
    for (CodeSpecsGateCheckResult r : report.results) {
      List<Object> findings = new ArrayList<>();
      for (CodeSpecsGateFinding f : r.findings) {
        Map<String, Object> fo = new LinkedHashMap<>();
        fo.put("code", f.code);
        fo.put("location", f.location);
        fo.put("message", f.message);
        findings.add(fo);
      }
      Map<String, Object> ro = new LinkedHashMap<>();
      ro.put("check", r.check.label());
      ro.put("ran", Boolean.valueOf(r.ran));
      ro.put("notRunReason", r.notRunReason);
      ro.put("findings", findings);
      results.add(ro);
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("passed", Boolean.valueOf(report.passed()));
    out.put("results", results);
    return out;
  }

  // --- codespecs_record_cases.json: reading extracts and the gate record ----

  /**
   * Reading back what a Phase-4 run wrote: extract files (each read is checked
   * against its summary and must write back byte for byte), the gate record
   * (read, written, edited, refused) and the scoping of a file set by its
   * record. Error cases compare by substring of the Dart reference's message.
   */
  @SuppressWarnings("unchecked")
  private static void testCodeSpecsRecords() throws IOException {
    Map<String, Object> table = readJsonObject("codespecs_record_cases.json");
    Map<String, Object> extractTable = readJsonObject("codespecs_extract_cases.json");
    CodeSpecsAreaCatalog catalog =
        CodeSpecsAreaCatalog.fromJson((Map<String, Object>) extractTable.get("catalog"));

    for (Object o : (List<Object>) table.get("extractReads")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.extractRead[" + c.get("source") + "]";
      String yaml = (String) c.get("yaml");
      try {
        CodeSpecsExtract x = CodeSpecsExtract.fromYaml(yaml, (String) c.get("source"));
        Object got = extractSummary(x);
        check(at, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
        check(at + ".roundTrip", x.toYaml().equals(yaml), byteDiff(at, x.toYaml(), yaml));
      } catch (CodeSpecsRecordError e) {
        check(at, false, e.getMessage());
      }
    }

    Map<String, Object> minimal = (Map<String, Object>) table.get("extractMinimal");
    try {
      Object got = extractSummary(
          CodeSpecsExtract.fromYaml((String) minimal.get("yaml"), (String) minimal.get("source")));
      check("codeSpecsRecords.extractMinimal", got.equals(minimal.get("expect")),
          jsonMismatch(got, minimal.get("expect")));
    } catch (CodeSpecsRecordError e) {
      check("codeSpecsRecords.extractMinimal", false, e.getMessage());
    }

    for (Object o : (List<Object>) table.get("extractErrors")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.extractError[" + c.get("name") + "]";
      String error = null;
      try {
        CodeSpecsExtract.fromYaml((String) c.get("yaml"), (String) c.get("source"));
      } catch (CodeSpecsRecordError e) {
        error = e.getMessage();
      }
      String want = (String) c.get("messageContains");
      check(at, error != null && error.contains(want), "got " + error + ", want contains " + want);
    }

    for (Object o : (List<Object>) table.get("gateRecords")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.gateRecord[" + c.get("name") + "]";
      String yaml = (String) c.get("yaml");
      try {
        CodeSpecsGateRecord g = CodeSpecsGateRecord.fromYaml(yaml);
        Object got = gateSummary(g);
        check(at, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
        check(at + ".toYaml", g.toYaml().equals(yaml), byteDiff(at, g.toYaml(), yaml));
        g.checkAgainst(catalog);
        check(at + ".checkAgainst", true, "");
      } catch (CodeSpecsRecordError e) {
        check(at, false, e.getMessage());
      }
    }

    for (Object o : (List<Object>) table.get("gateWrites")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.gateWrite[" + c.get("name") + "]";
      try {
        List<CodeSpecsGateEntry> verdicts = new ArrayList<>();
        for (Object v : (List<Object>) c.get("verdicts")) {
          verdicts.add(gateEntry((Map<String, Object>) v));
        }
        CodeSpecsGateRecord g = new CodeSpecsGateRecord(verdicts);
        String want = (String) c.get("yaml");
        check(at, g.toYaml().equals(want), byteDiff(at, g.toYaml(), want));
        Object then = c.get("then");
        if (then != null) {
          g = g.withVerdict(gateEntry((Map<String, Object>) then));
          String thenWant = (String) c.get("thenYaml");
          check(at + ".then", g.toYaml().equals(thenWant), byteDiff(at, g.toYaml(), thenWant));
        }
      } catch (CodeSpecsRecordError e) {
        check(at, false, e.getMessage());
      }
    }

    for (Object o : (List<Object>) table.get("gateErrors")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.gateError[" + c.get("name") + "]";
      String error = null;
      try {
        CodeSpecsGateRecord g = CodeSpecsGateRecord.fromYaml((String) c.get("yaml"));
        if (Boolean.TRUE.equals(c.get("againstCatalog"))) {
          g.checkAgainst(catalog);
        }
      } catch (CodeSpecsRecordError e) {
        error = e.getMessage();
      }
      String want = (String) c.get("messageContains");
      check(at, error != null && error.contains(want), "got " + error + ", want contains " + want);
    }

    for (Object o : (List<Object>) table.get("scopeCases")) {
      Map<String, Object> c = (Map<String, Object>) o;
      String at = "codeSpecsRecords.scope[" + c.get("name") + "]";
      List<Map.Entry<String, String>> files = new ArrayList<>();
      for (Object f : (List<Object>) c.get("files")) {
        List<Object> pair = (List<Object>) f;
        files.add(Map.entry((String) pair.get(0), (String) pair.get(1)));
      }
      Map<String, Object> want = (Map<String, Object>) c.get("expect");
      Object got;
      String error = null;
      try {
        got = scopeSummary(CodeSpecsExtractSet.fromFiles(files));
      } catch (CodeSpecsRecordError e) {
        error = e.getMessage();
        got = null;
      }
      if (want.containsKey("error")) {
        String wantError = (String) want.get("error");
        check(at, error != null && error.contains(wantError),
            "got " + (error != null ? error : got) + ", want " + wantError);
      } else {
        check(at, error == null && want.equals(got),
            error != null ? error : jsonMismatch(got, want));
      }
    }
  }

  private static CodeSpecsGateEntry gateEntry(Map<String, Object> v) {
    return new CodeSpecsGateEntry(
        (String) v.get("area"),
        CodeSpecsGateVerdict.parse((String) v.get("verdict")),
        (String) v.get("resolution"),
        (String) v.get("note"),
        gateGaps(v.get("gaps")));
  }

  @SuppressWarnings("unchecked")
  private static List<CodeSpecsGateGap> gateGaps(Object raw) {
    List<CodeSpecsGateGap> out = new ArrayList<>();
    if (raw == null) {
      return out;
    }
    for (Object gObj : (List<Object>) raw) {
      Map<String, Object> g = (Map<String, Object>) gObj;
      out.add(
          new CodeSpecsGateGap(
              (String) g.get("sectionId"), (String) g.get("required"), (String) g.get("carrier")));
    }
    return out;
  }

  private static Map<String, Object> extractSummary(CodeSpecsExtract x) {
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("area", x.area.code);
    o.put("canonicalId", x.area.canonicalId);
    o.put("part", x.area.part);
    o.put("documentRoot", x.documentRoot);
    o.put("projects", new ArrayList<Object>(x.projects));
    o.put("citableParts", new ArrayList<Object>(x.citableParts));
    o.put("entryCount", Integer.valueOf(x.entries.size()));
    List<Object> sectionIds = new ArrayList<>();
    List<Object> values = new ArrayList<>();
    List<Object> classNames = new ArrayList<>();
    List<Object> headlines = new ArrayList<>();
    for (CodeSpecsExtractEntry e : x.entries) {
      sectionIds.add(e.sectionId);
      values.add(e.value);
      classNames.add(e.className);
      headlines.add(e.headline);
    }
    o.put("sectionIds", sectionIds);
    o.put("values", values);
    o.put("classNames", classNames);
    o.put("headlines", headlines);
    return o;
  }

  private static Map<String, Object> gateSummary(CodeSpecsGateRecord g) {
    List<Object> verdicts = new ArrayList<>();
    for (CodeSpecsGateEntry v : g.verdicts) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("area", v.area);
      o.put("verdict", v.verdict.word);
      o.put("resolution", v.resolution);
      o.put("note", v.note);
      // Only when present, so a gap-less entry's summary is unchanged.
      if (!v.gaps.isEmpty()) {
        List<Object> gaps = new ArrayList<>();
        for (CodeSpecsGateGap gap : v.gaps) {
          Map<String, Object> m = new LinkedHashMap<>();
          m.put("sectionId", gap.sectionId);
          m.put("required", gap.required);
          m.put("carrier", gap.carrier);
          gaps.add(m);
        }
        o.put("gaps", gaps);
      }
      verdicts.add(o);
    }
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("verdicts", verdicts);
    return o;
  }

  private static Map<String, Object> scopeSummary(CodeSpecsExtractSet set) {
    List<Object> inScope = new ArrayList<>();
    for (CodeSpecsExtract x : set.extracts) {
      inScope.add(x.area.code);
    }
    List<Object> excluded = new ArrayList<>();
    for (CodeSpecsExcludedArea e : set.excluded) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("area", e.area);
      o.put("verdict", e.verdict.word);
      o.put("descoped", Boolean.valueOf(e.descoped));
      o.put("entryCount", Integer.valueOf(e.entryCount));
      o.put("source", e.source);
      excluded.add(o);
    }
    Map<String, Object> o = new LinkedHashMap<>();
    o.put("inScope", inScope);
    o.put("sources", new ArrayList<Object>(set.sources));
    o.put("hasGate", Boolean.valueOf(set.gate != null));
    o.put("excluded", excluded);
    return o;
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
    check("model.classCount", model.classes.size() == 19, String.valueOf(model.classes.size()));
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
              "refs", "cards", "meta", "control", "notes", "mixed", "registry",
              "deliverables");
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
    String expected = read("expected.tomspecs.yaml");
    String actual = SpecDocumentYaml.encode(doc, tree, MODEL_VERSION);
    check("yaml.encode", actual.equals(expected), byteDiff("yaml.encode", actual, expected));
  }

  private static void testYamlDecodeRoundTrip(SomMetaTree tree) throws IOException {
    String expected = read("expected.tomspecs.yaml");
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

  /**
   * {@code yaml_review_cases.json}: the {@code review:} pass — a decoded review
   * written back byte for byte, and the review paths left stale by removed
   * list items.
   */
  @SuppressWarnings("unchecked")
  private static void testYamlReviewCases(SpecModel model, SomMetaTree tree) throws IOException {
    Map<String, Object> table = readJsonObject("yaml_review_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "yamlReview[" + c.get("name") + "]";
      Object expect = c.get("expect");
      Object got = runYamlReviewCase(model, tree, c);
      if (got instanceof String && expect instanceof String) {
        check(name, got.equals(expect), byteDiff(name, (String) got, (String) expect));
      } else {
        check(name, got.equals(expect), jsonMismatch(got, expect));
      }
    }
  }

  /**
   * The typed reading of a review value in the corpus's tagged form ({@code
   * yaml_review_cases.json}, op {@code typedReview}): a map as {@code [key,
   * value]} pairs sorted by key, a list in order, an int as its decimal text, a
   * float as the review writer prints it ({@link SpecDocumentYaml#reviewScalar}),
   * a string as itself.
   */
  private static Object typedReview(Object v) {
    Map<String, Object> out = new LinkedHashMap<>();
    if (v == null) {
      out.put("type", "null");
    } else if (v instanceof Boolean) {
      out.put("type", "bool");
      out.put("value", v);
    } else if (v instanceof Integer
        || v instanceof Long
        || v instanceof Short
        || v instanceof Byte
        || v instanceof java.math.BigInteger) {
      out.put("type", "int");
      out.put("value", v.toString());
    } else if (v instanceof Number) {
      out.put("type", "float");
      out.put("value", SpecDocumentYaml.reviewScalar(v));
    } else if (v instanceof String) {
      out.put("type", "string");
      out.put("value", v);
    } else if (v instanceof List) {
      List<Object> items = new ArrayList<>();
      for (Object item : (List<?>) v) {
        items.add(typedReview(item));
      }
      out.put("type", "list");
      out.put("value", items);
    } else {
      Map<?, ?> m = (Map<?, ?>) v;
      List<String> keys = new ArrayList<>();
      for (Object k : m.keySet()) {
        keys.add((String) k);
      }
      java.util.Collections.sort(keys);
      List<Object> pairs = new ArrayList<>();
      for (String k : keys) {
        List<Object> pair = new ArrayList<>();
        pair.add(k);
        pair.add(typedReview(m.get(k)));
        pairs.add(pair);
      }
      out.put("type", "map");
      out.put("value", pairs);
    }
    return out;
  }

  /** Runs one {@code yaml_review_cases.json} case and returns what it observed. */
  @SuppressWarnings("unchecked")
  private static Object runYamlReviewCase(SpecModel model, SomMetaTree tree, Map<String, Object> c) {
    SpecYamlContents contents = SpecDocumentYaml.decode((String) c.get("yaml"), tree);
    if ("typedReview".equals(c.get("op"))) {
      return typedReview(contents.review);
    }
    if ("roundTrip".equals(c.get("op"))) {
      return SpecDocumentYaml.encode(
          contents.document, tree, contents.modelVersion, contents.review);
    }
    // op == 'stale': remove the named list items, then ask which review
    // entries no longer resolve.
    for (Object item : (List<Object>) c.get("removeItems")) {
      contents.document.removeListItem((String) item);
    }
    return new ArrayList<Object>(
        SpecDocumentYaml.staleReviewPaths(
            model,
            contents.document,
            contents.review != null ? contents.review : new LinkedHashMap<>()));
  }

  // --- markdown conformance (SOM §11) -------------------------------------

  // The layout this runtime emits: `tables` (SOM §11.4, §11.5). Its export
  // golden is expected.tables.md; expected.tomspecs.md, the `Field:`-line
  // layout, is parsed only.
  static final String EMITTED_LAYOUT = "tables";
  static final String EXPORT_GOLDEN = "expected." + EMITTED_LAYOUT + ".md";

  /**
   * The expectation of case {@code c} for this runtime's layout: {@code expectTables} when the
   * case has one (its renditions' lines differ by layout), else {@code expect}.
   */
  private static Object expectFor(Map<String, Object> c) {
    return "tables".equals(EMITTED_LAYOUT) && c.containsKey("expectTables")
        ? c.get("expectTables")
        : c.get("expect");
  }

  private static void testMarkdownExport(SpecModel model) throws IOException {
    SpecDocument doc = documentFromState(readJsonObject("state.json"));
    String expected = read(EXPORT_GOLDEN);
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
    String golden = read(EXPORT_GOLDEN);
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
   * Markdown/YAML convergence: parsing either golden ({@code expected.tables.md}, the reading
   * view's tables, and {@code expected.tomspecs.md}, the {@code Field:} lines) and applying it
   * must reproduce {@code state.json} (the YAML-route memory) exactly, proving both formats
   * converge on one in-memory document (SOM §8).
   */
  private static void testMarkdownMemoryLanding(SpecModel model) throws IOException {
    Map<String, Object> canonical = readJsonObject("state.json");
    String[][] goldens = {{"tables", "expected.tables.md"}, {"fields", "expected.tomspecs.md"}};
    for (String[] golden : goldens) {
      String label = golden[0];
      SpecMarkdownImport imported = SpecDocument.fromMarkdown(read(golden[1]), model);
      check(
          "md.land." + label + ".clean",
          imported.rejections().isEmpty(),
          rejDetail(imported.result));
      SpecDocument landed = imported.document;
      check(
          "md.land." + label + ".memory",
          landed.toJson().equals(canonical),
          jsonMismatch(landed.toJson(), canonical));
    }
  }

  /**
   * {@code markdown_apply_cases.json}: {@link SpecDocument#fromMarkdown} into a fresh document,
   * and {@link SpecDocument#applyMarkdownResult(SpecMarkdownResult, boolean)} as a full overwrite
   * of the covered roots — other roots kept, a result with rejections refused (and the document
   * left unchanged) unless the caller allows them.
   */
  @SuppressWarnings("unchecked")
  private static void testMarkdownApplyCases(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("markdown_apply_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runMarkdownApplyCase(model, c, (String) table.get("schema"));
      Object expect = c.get("expect");
      check("mdApply[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /** Runs one {@code markdown_apply_cases.json} case, in the shape of its {@code expect}. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runMarkdownApplyCase(
      SpecModel model, Map<String, Object> c, String schema) {
    String markdown = (String) c.get("markdown");
    Map<String, Object> out = new LinkedHashMap<>();
    if ("fromMarkdown".equals(c.get("op"))) {
      SpecMarkdownImport imported = SpecDocument.fromMarkdown(markdown, model);
      out.put("refused", false);
      out.put("rejectionCount", imported.rejections().size());
      out.put("document", imported.document.toJson());
      return out;
    }
    SpecDocument document = new SpecDocument();
    document.loadJson((Map<String, Object>) c.get("base"));
    SpecMarkdownResult parsed = new SpecDocumentMarkdown(model, document).parse(markdown);
    boolean refused = false;
    try {
      document.applyMarkdownResult(parsed, Boolean.TRUE.equals(c.get("allowRejections")));
    } catch (IllegalStateException e) {
      refused = true;
    }
    out.put("refused", refused);
    out.put("rejectionCount", parsed.rejections.size());
    out.put("document", document.toJson());
    // The validator reports every kept block as `rejectedBlock` (DocSpecs
    // RN-11), with the document path it stands in.
    if (Boolean.TRUE.equals(c.get("readingView"))) {
      List<Object> blocks = new ArrayList<>();
      for (DocSpecsViolation v : SpecSchemaValidation.validateSpecDocument(
          model, document, DocSpecsSchema.fromYamlText(schema), "Demo")) {
        if (DocSpecsViolation.RULE_REJECTED_BLOCK.equals(v.rule)) {
          Map<String, Object> m = new LinkedHashMap<>();
          m.put("line", Integer.valueOf(v.line));
          m.put("path", v.path);
          blocks.add(m);
        }
      }
      out.put("rejectedBlocks", blocks);
    }
    return out;
  }

  /**
   * {@code assembly_cases.json}: {@link SpecDocument#assemble} over ordered
   * fragments, each loaded with {@link SpecDocument#loadJson} into a fresh
   * document. The document split in two must assemble back into {@code whole};
   * the other cases pin the refusing rule per store.
   */
  @SuppressWarnings("unchecked")
  private static void testAssemblyCases() throws IOException {
    Map<String, Object> table = readJsonObject("assembly_cases.json");
    List<Object> cases = (List<Object>) table.get("cases");
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAssemblyCase(c);
      Object expect = c.get("expect");
      check("assembly[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
    Object first = ((Map<String, Object>) ((Map<String, Object>) cases.get(0)).get("expect")).get("document");
    Object whole = table.get("whole");
    check("assembly.whole", Objects.equals(first, whole), jsonMismatch(String.valueOf(first), String.valueOf(whole)));
  }

  /**
   * {@code annotation_cases.json}: listing and editing review annotations (SOM
   * §11.9). Every op runs in order on one document loaded from {@code state};
   * an op that throws the annotation error answers {@code {error: true}}.
   */
  @SuppressWarnings("unchecked")
  private static void testAnnotationCases(SpecModel model, SomMetaTree tree) throws IOException {
    Map<String, Object> table = readJsonObject("annotation_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAnnotationCase(model, tree, c);
      Object expect = c.get("expect");
      check("annotations[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /**
   * {@code team_annotation_cases.json}: the team-review notation (SOM §11.9.8). The scripted cases
   * run like the annotation cases with the results in their team form; the {@code
   * validationCases} run like {@code validation_cases.json} over the corpus model.
   */
  @SuppressWarnings("unchecked")
  private static void testTeamAnnotationCases(SpecModel model, SomMetaTree tree)
      throws IOException {
    Map<String, Object> table = readJsonObject("team_annotation_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "teamAnnotation[" + c.get("name") + "]";
      Object expect = c.get("expect");
      try {
        Map<String, Object> got = runAnnotationCase(model, tree, c, true);
        check(name, got.equals(expect), jsonMismatch(got, expect));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
    for (Object caseObj : (List<Object>) table.get("validationCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      SpecDocument doc = documentFromState(Json.parseObject(Json.write(c.get("state"))));
      List<String> got = new ArrayList<>();
      for (SpecValidationError e : SpecValidator.validateDocument(model, doc)) {
        got.add(e.path + "|" + e.code.value);
      }
      List<String> want = new ArrayList<>();
      for (Object eObj : (List<Object>) c.get("errors")) {
        Map<String, Object> e = (Map<String, Object>) eObj;
        want.add(e.get("path") + "|" + e.get("code"));
      }
      check("teamValidate[" + c.get("name") + "]", got.equals(want), got + " != " + want);
    }
  }

  /**
   * {@code review_merge_cases.json}: merging reviewed copies (SOM §11.9.9), SOM documents (model
   * {@code demo}: the corpus model; {@code som}: the real model) and plain Markdown.
   */
  @SuppressWarnings("unchecked")
  private static void testReviewMergeCases(SpecModel model) throws IOException {
    Map<String, SpecModel> models = new LinkedHashMap<>();
    models.put("demo", model);
    models.put(
        "som",
        SpecModel.fromJson(
            Json.parseObject(
                new String(
                    Files.readAllBytes(
                        corpus.resolve("../../tom_som_dart_v0/meta/spec_model.meta.json").normalize()),
                    StandardCharsets.UTF_8))));
    for (Object caseObj : (List<Object>) readJsonObject("review_merge_cases.json").get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "reviewMerge[" + c.get("name") + "]";
      Object expect = c.get("expect");
      try {
        Map<String, Object> got = runReviewMergeCase(models, c);
        check(name, got.equals(expect), jsonMismatch(got, expect));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
  }

  /**
   * One {@code review_merge_cases.json} case: the merged document (its state, or the Markdown
   * text) and the report; a refused merge answers {@code {error: true}}.
   */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runReviewMergeCase(
      Map<String, SpecModel> models, Map<String, Object> c) {
    Map<String, Object> o = (Map<String, Object>) c.get("options");
    List<SpecReviewMember> team = new ArrayList<>();
    for (Object m : (List<Object>) o.get("team")) {
      team.add(reviewMember((Map<String, Object>) m));
    }
    SpecReviewMergeOptions options =
        new SpecReviewMergeOptions(
            team,
            (String) o.get("date"),
            (String) o.get("author"),
            (String) o.get("questionPrefix"),
            c.get("model") == null ? null : models.get((String) c.get("model")));
    Map<String, Object> out = new LinkedHashMap<>();
    try {
      if ("markdown".equals(c.get("format"))) {
        List<SpecReviewedCopy<String>> copies = new ArrayList<>();
        for (Object x : (List<Object>) c.get("copies")) {
          Map<String, Object> m = (Map<String, Object>) x;
          copies.add(new SpecReviewedCopy<>(reviewMember(m), (String) m.get("document")));
        }
        SpecReviewMergeResult<String> r =
            SpecReviewMerge.mergeReviews((String) c.get("base"), copies, options);
        out.put("merged", r.merged);
        out.put("report", r.report.toJson());
        return out;
      }
      List<SpecReviewedCopy<SpecDocument>> copies = new ArrayList<>();
      for (Object x : (List<Object>) c.get("copies")) {
        Map<String, Object> m = (Map<String, Object>) x;
        copies.add(
            new SpecReviewedCopy<>(
                reviewMember(m), documentFromState(Json.parseObject(Json.write(m.get("document"))))));
      }
      SpecDocument base = documentFromState(Json.parseObject(Json.write(c.get("base"))));
      SpecReviewMergeResult<SpecDocument> r = SpecReviewMerge.mergeReviews(base, copies, options);
      out.put("merged", r.merged.toJson());
      out.put("report", r.report.toJson());
      return out;
    } catch (SpecReviewMergeError e) {
      out.clear();
      out.put("error", true);
      return out;
    }
  }

  private static SpecReviewMember reviewMember(Map<String, Object> m) {
    return new SpecReviewMember(
        (String) m.get("memberId"), (String) m.get("displayName"), (String) m.get("role"));
  }

  /**
   * {@code inline_mark_cases.json}: accepting and rejecting inline marks (SOM §11.9.3). The text
   * cases pin {@code applyInlineMarksText}, the change-comment text cases {@code
   * decideAllMarksText} as well; the scripted cases run like the annotation cases.
   */
  @SuppressWarnings("unchecked")
  private static void testInlineMarkCases(SpecModel model, SomMetaTree tree) throws IOException {
    Map<String, Object> table = readJsonObject("inline_mark_cases.json");
    for (Object caseObj : (List<Object>) table.get("textCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String text = (String) c.get("text");
      String accept = SpecReviewAnnotations.applyInlineMarksText(text, true);
      String reject = SpecReviewAnnotations.applyInlineMarksText(text, false);
      check(
          "marks text[" + c.get("name") + "].accept",
          accept.equals(c.get("accept")),
          "got " + Json.write(accept) + ", want " + Json.write(c.get("accept")));
      check(
          "marks text[" + c.get("name") + "].reject",
          reject.equals(c.get("reject")),
          "got " + Json.write(reject) + ", want " + Json.write(c.get("reject")));
    }
    for (Object caseObj : (List<Object>) table.get("changeCommentTextCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String text = (String) c.get("text");
      String name = "change comments text[" + c.get("name") + "]";
      Map<String, String> live = new LinkedHashMap<>();
      live.put("accept", SpecReviewAnnotations.decideAllMarksText(text, true));
      live.put("reject", SpecReviewAnnotations.decideAllMarksText(text, false));
      live.put("removed", SpecReviewAnnotations.applyInlineMarksText(text, true));
      for (Map.Entry<String, String> e : live.entrySet()) {
        check(
            name + "." + e.getKey(),
            e.getValue().equals(c.get(e.getKey())),
            "got " + Json.write(e.getValue()) + ", want " + Json.write(c.get(e.getKey())));
      }
    }
    // Typed values and headlines under review (SOM §11.9.3).
    runTypedMarkCases("typedInlineMark", model, tree, (List<Object>) table.get("typedCases"));
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAnnotationCase(model, tree, c);
      Object expect = c.get("expect");
      check("marks[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /**
   * {@code change_mark_cases.json}: writing a change as inline marks (SOM §11.9.3). The text cases
   * pin {@code markChangeText}; the scripted cases run like the annotation cases.
   */
  @SuppressWarnings("unchecked")
  private static void testChangeMarkCases(SpecModel model, SomMetaTree tree) throws IOException {
    Map<String, Object> table = readJsonObject("change_mark_cases.json");
    for (Object caseObj : (List<Object>) table.get("textCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "change text[" + c.get("name") + "]";
      SpecMarkedChange r =
          SpecReviewAnnotations.markChangeText((String) c.get("old"), (String) c.get("new"));
      check(
          name + ".marked",
          r.text.equals(c.get("marked")),
          "got " + Json.write(r.text) + ", want " + Json.write(c.get("marked")));
      check(
          name + ".exact",
          Boolean.valueOf(r.exact).equals(c.get("exact")),
          "got " + r.exact + ", want " + c.get("exact"));
      String accept = SpecReviewAnnotations.applyInlineMarksText(r.text, true);
      String reject = SpecReviewAnnotations.applyInlineMarksText(r.text, false);
      check(
          name + ".accept",
          accept.equals(c.get("accept")),
          "got " + Json.write(accept) + ", want " + Json.write(c.get("accept")));
      check(
          name + ".reject",
          reject.equals(c.get("reject")),
          "got " + Json.write(reject) + ", want " + Json.write(c.get("reject")));
      if (r.exact) {
        check(
            name + ".exactRoundTrip",
            c.get("accept").equals(c.get("new")) && c.get("reject").equals(c.get("old")),
            "accept/reject do not give new/old");
      }
    }
    // Typed values and headlines written as marks (SOM §11.9.3).
    runTypedMarkCases("typedChangeMark", model, tree, (List<Object>) table.get("typedCases"));
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAnnotationCase(model, tree, c);
      Object expect = c.get("expect");
      check("change[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /**
   * {@code answer_cases.json}: extracting answers for a step folder (SOM §11.9.7). The extracts
   * are compared structurally, the markdown byte for byte.
   */
  @SuppressWarnings("unchecked")
  private static void testAnswerCases(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("answer_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAnswerCase(model, c);
      Map<String, Object> expect = (Map<String, Object>) expectFor(c);
      String name = "answers[" + c.get("name") + "]";
      check(
          name + ".extracts",
          Json.parseObject(Json.write(got)).get("extracts").equals(expect.get("extracts")),
          jsonMismatch(got.get("extracts"), expect.get("extracts")));
      check(
          name + ".markdown",
          got.get("markdown").equals(expect.get("markdown")),
          "got " + Json.write(got.get("markdown")) + ", want " + Json.write(expect.get("markdown")));
    }
  }

  /** Runs one {@code answer_cases.json} case: {@code {extracts, markdown}}. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runAnswerCase(SpecModel model, Map<String, Object> c) {
    List<SpecAnswerExtract> extracts = new ArrayList<>();
    for (Object dObj : (List<Object>) c.get("documents")) {
      Map<String, Object> d = (Map<String, Object>) dObj;
      SpecDocument doc = documentFromState(Json.parseObject(Json.write(d.get("state"))));
      extracts.add(
          SpecAnswers.extractAnswers(model, doc, (String) d.get("label"), (String) c.get("path")));
    }
    List<Object> xs = new ArrayList<>();
    for (SpecAnswerExtract x : extracts) {
      xs.add(x.toJson());
    }
    Object title = c.get("title");
    SpecAnswerRenderOptions options =
        new SpecAnswerRenderOptions(
            Boolean.TRUE.equals(c.get("includeOpen")),
            Boolean.TRUE.equals(c.get("includeMarks")),
            title == null ? "Answers" : (String) title);
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("extracts", xs);
    out.put("markdown", SpecAnswers.renderAnswers(extracts, options));
    return out;
  }

  /** Runs one {@code annotation_cases.json} case: {@code {results, state}}. */
  private static Map<String, Object> runAnnotationCase(
      SpecModel model, SomMetaTree tree, Map<String, Object> c) {
    return runAnnotationCase(model, tree, c, false);
  }

  /**
   * The change time every annotation write records in the conformance cases (SOM §11.9.10) unless
   * a case names its own {@code now}.
   */
  private static final String CORPUS_NOW = "2026-11-07T14:05+01:00";

  /**
   * Runs one annotation-script case; {@code team} renders the results in the extended form {@code
   * team_annotation_cases.json} pins (SOM §11.9.8).
   */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runAnnotationCase(
      SpecModel model, SomMetaTree tree, Map<String, Object> c, boolean team) {
    SpecDocument doc =
        documentFromState(Json.parseObject(Json.write(c.get("state"))));
    // A fixed clock, so a write's change time (SOM §11.9.10) is the same in every runtime: the
    // case's `now`, else the corpus default.
    String now = c.get("now") != null ? (String) c.get("now") : CORPUS_NOW;
    SpecReviewAnnotations api =
        new SpecReviewAnnotations(doc, (String) c.get("qualifier"), () -> now);
    List<Object> results = new ArrayList<>();
    for (Object opObj : (List<Object>) c.get("ops")) {
      Map<String, Object> op = (Map<String, Object>) opObj;
      try {
        results.add(runAnnotationOp(model, tree, doc, api, op, team));
      } catch (SpecReviewAnnotationError e) {
        Map<String, Object> err = new LinkedHashMap<>();
        err.put("error", true);
        results.add(err);
      }
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("results", results);
    out.put("state", doc.toJson());
    return out;
  }

  @SuppressWarnings("unchecked")
  private static Object runAnnotationOp(
      SpecModel model,
      SomMetaTree tree,
      SpecDocument doc,
      SpecReviewAnnotations api,
      Map<String, Object> op,
      boolean team) {
    String kind = (String) op.get("op");
    int floor = op.get("floor") == null ? 0 : ((Number) op.get("floor")).intValue();
    switch (kind) {
      case "list":
        {
          List<Object> out = new ArrayList<>();
          for (SpecReviewAnnotation a : api.list()) {
            out.add(a.toJson(team));
          }
          return out;
        }
      case "counts":
        return api.counts().toJson(team);
      case "nextId":
        return api.nextCommentId(floor);
      case "assignIds":
        return new ArrayList<Object>(api.assignCommentIds(floor));
      case "insertComment":
        return api.insertComment(
            (String) op.get("path"),
            (String) op.get("field"),
            ((Number) op.get("afterParagraph")).intValue(),
            (String) op.get("text"),
            (String) op.get("author"),
            (String) op.get("id"),
            (String) op.get("at"));
      case "insertQuestion":
        api.insertQuestion(
            (String) op.get("path"),
            (String) op.get("field"),
            ((Number) op.get("afterParagraph")).intValue(),
            SpecQuestionDraft.fromJson((Map<String, Object>) op.get("question")),
            (String) op.get("at"));
        return null;
      case "insertQuestionAfterComment":
        api.insertQuestionAfterComment(
            (String) op.get("commentId"),
            SpecQuestionDraft.fromJson((Map<String, Object>) op.get("question")),
            (String) op.get("at"));
        return null;
      case "setAnswer":
        api.setAnswer(
            (String) op.get("id"),
            (String) op.get("answer"),
            (String) op.get("author"),
            (String) op.get("at"));
        return null;
      case "editComment":
        api.editComment((String) op.get("id"), (String) op.get("text"), (String) op.get("at"));
        return null;
      case "resolve":
        api.resolve((String) op.get("id"));
        return null;
      case "applyMark":
        api.applyMark(
            (String) op.get("path"),
            (String) op.get("field"),
            ((Number) op.get("index")).intValue(),
            !Boolean.FALSE.equals(op.get("accept")));
        return null;
      case "strip":
        return api.stripped().toJson();
      case "revision":
        return api.revision();
      case "paragraphs":
        {
          List<Object> out = new ArrayList<>();
          for (SpecParagraph para :
              api.paragraphs((String) op.get("path"), (String) op.get("field"))) {
            out.add(para.toJson());
          }
          return out;
        }
      case "listMarks":
        {
          List<Object> out = new ArrayList<>();
          for (SpecMarkEntry m : api.listMarks((String) op.get("path"))) {
            out.add(m.toJson(team));
          }
          return out;
        }
      case "decideMarks":
        {
          Map<String, SpecMarkDecision> decisions = new LinkedHashMap<>();
          for (Map.Entry<String, Object> e :
              ((Map<String, Object>) op.get("decisions")).entrySet()) {
            decisions.put(e.getKey(), SpecMarkDecision.fromValue((String) e.getValue()));
          }
          String rev = (String) op.get("revision");
          return api.decideMarks(decisions, "@current".equals(rev) ? api.revision() : rev)
              .toJson(team);
        }
      case "acceptAll":
        return api.acceptAllMarks((String) op.get("path")).toJson(team);
      case "rejectAll":
        return api.rejectAllMarks((String) op.get("path")).toJson(team);
      case "removeAll":
        return api.removeAllAnnotations().toJson(team);
      case "commentChange":
        {
          String rev = (String) op.get("revision");
          return api.commentChange(
              (String) op.get("id"),
              (String) op.get("text"),
              (String) op.get("author"),
              "@current".equals(rev) ? api.revision() : rev,
              (String) op.get("at"));
        }
      case "editMarkComment":
        {
          String rev = (String) op.get("revision");
          api.editMarkComment(
              (String) op.get("id"),
              (String) op.get("text"),
              "@current".equals(rev) ? api.revision() : rev,
              (String) op.get("at"));
          return null;
        }
      case "setMarked":
        return api.setMarked(
                (String) op.get("path"),
                (String) op.get("field"),
                (String) op.get("text"),
                (String) op.get("author"),
                (String) op.get("at"))
            .toJson();
      case "markAgainst":
        return api.markAgainst(
                (String) op.get("path"),
                (String) op.get("field"),
                (String) op.get("earlier"),
                (String) op.get("author"),
                (String) op.get("at"))
            .toJson();
      case "validate":
        // The instance tier's findings as `{path, code}`: a marked typed value is
        // read as its old value (SOM §11.9.3).
        return validationPairs(SpecValidator.validateDocument(model, doc));
      case "typedRead":
        // The typed reading of one value, as the typed accessors read it.
        return typedRead(model, doc, op);
      case "roundTrip":
        {
          String yaml = SpecDocumentYaml.encode(doc, tree, MODEL_VERSION);
          SpecDocument fromYaml = SpecDocumentYaml.decode(yaml, tree).document;
          String md = new SpecDocumentMarkdown(model, doc).exportRoot(model.roots.get(0));
          SpecMarkdownImport fromMd = SpecDocument.fromMarkdown(md, model);
          Map<String, Object> out = new LinkedHashMap<>();
          out.put("yaml", fromYaml.toJson().equals(doc.toJson()));
          out.put(
              "markdown",
              fromMd.rejections().isEmpty() && fromMd.document.toJson().equals(doc.toJson()));
          return out;
        }
      default:
        throw new IllegalStateException("unknown annotation op " + kind);
    }
  }

  /** Runs one {@code assembly_cases.json} case, in the shape of its {@code expect}. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runAssemblyCase(Map<String, Object> c) {
    List<Map.Entry<String, SpecDocument>> fragments = new ArrayList<>();
    for (Object f : (List<Object>) c.get("fragments")) {
      List<Object> pair = (List<Object>) f;
      SpecDocument doc = new SpecDocument();
      doc.loadJson((Map<String, Object>) pair.get(1));
      fragments.add(Map.entry((String) pair.get(0), doc));
    }
    SpecDocumentAssembly result = SpecDocument.assemble(fragments);
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("ok", result.ok());
    out.put("document", result.document == null ? null : result.document.toJson());
    List<Object> overlaps = new ArrayList<>();
    for (SpecAssemblyOverlap o : result.overlaps) {
      Map<String, Object> entry = new LinkedHashMap<>();
      entry.put("store", o.store);
      entry.put("path", o.path);
      entry.put("field", o.field);
      entry.put("fragments", new ArrayList<Object>(o.fragments));
      entry.put("message", o.message());
      overlaps.add(entry);
    }
    out.put("overlaps", overlaps);
    return out;
  }

  /**
   * {@code list_move_cases.json}: {@link SpecDocument#moveListItem} over a loaded state — the
   * renames, the pinned ids and the resulting document, or the refusal mapped to its error word —
   * and {@link SpecDocumentYaml#rekeyReview} over the review re-key table.
   */
  @SuppressWarnings("unchecked")
  private static void testListMoveCases(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("list_move_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runListMoveCase(model, c);
      Object expect = c.get("expect");
      check("listMove[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
    for (Object caseObj : (List<Object>) table.get("reviewCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, String> renamed = new LinkedHashMap<>();
      for (Map.Entry<String, Object> e : ((Map<String, Object>) c.get("renamed")).entrySet()) {
        renamed.put(e.getKey(), (String) e.getValue());
      }
      Map<String, Object> got =
          SpecDocumentYaml.rekeyReview((Map<String, Object>) c.get("review"), renamed);
      Object expect = c.get("expect");
      check("reviewRekey[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  private static List<SpecImpactFolder> impactFolders(Object raw) {
    if (raw == null) {
      return null;
    }
    List<SpecImpactFolder> out = new ArrayList<>();
    for (Object o : (List<?>) raw) {
      Map<?, ?> m = (Map<?, ?>) o;
      out.add(new SpecImpactFolder((String) m.get("path"), Boolean.TRUE.equals(m.get("present"))));
    }
    return out;
  }

  /**
   * {@code impact_walk_cases.json}: per case the walk ({@link SpecImpactWalk#specImpactWalk}),
   * the level, the document files and the Markdown, each compared with the case's expectation.
   */
  @SuppressWarnings("unchecked")
  private static void testImpactWalk() throws IOException {
    Map<String, Object> table = readJsonObject("impact_walk_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Object modelRaw = c.get("model");
      SpecModel model = SpecModel.fromJson(
          modelRaw instanceof String ? readJsonObject((String) modelRaw) : (Map<String, Object>) modelRaw);
      Map<String, SpecDocument> documents = new LinkedHashMap<>();
      for (Map.Entry<String, Object> e : ((Map<String, Object>) c.get("documents")).entrySet()) {
        Object state = e.getValue();
        documents.put(e.getKey(), documentFromState(
            state instanceof String ? readJsonObject((String) state) : (Map<String, Object>) state));
      }
      List<String> listing = new ArrayList<>();
      for (Object o : (List<Object>) c.get("listing")) {
        listing.add((String) o);
      }
      List<SpecImpactRootWalk> walk = SpecImpactWalk.specImpactWalk(model, documents);
      SpecImpactLevel level = SpecImpactWalk.specImpactLevel(
          model, walk, listing, impactFolders(c.get("tests")), impactFolders(c.get("code")));
      List<Object> walkJson = new ArrayList<>();
      for (SpecImpactRootWalk w : walk) {
        walkJson.add(w.toJson());
      }
      Map<String, Object> got = new LinkedHashMap<>();
      got.put("walk", walkJson);
      got.put("level", level.toJson());
      got.put("documentFiles", new ArrayList<Object>(SpecImpactWalk.specImpactDocumentFiles(listing)));
      got.put("markdown", SpecImpactWalk.specImpactWalkMarkdown(walk, level));
      Map<String, Object> expect = (Map<String, Object>) c.get("expect");
      for (String key : new String[] {"walk", "level", "documentFiles", "markdown"}) {
        Object g = got.get(key);
        Object w = expect.get(key);
        check(
            "impactWalk[" + c.get("name") + "]." + key,
            Objects.equals(g, w),
            g instanceof String && w instanceof String
                ? byteDiff(key, (String) g, (String) w)
                : jsonMismatch(g, w));
      }
    }
  }

  /**
   * {@code generation_unit_cases.json}: the standard emitters, then per case the units
   * {@link SpecGenerationUnits#specGenerationUnits} reads from the document's register, each
   * unit's {@link SpecGenerationUnit#mappingFor} per area, {@link
   * SpecGenerationUnits#specDefaultUnits} per area and the stored units override of each section.
   */
  @SuppressWarnings("unchecked")
  private static void testGenerationUnits(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("generation_unit_cases.json");
    List<Object> standard = new ArrayList<Object>(SpecGenerationUnits.SPEC_STANDARD_EMITTERS);
    check(
        "generationUnits.standardEmitters",
        standard.equals(table.get("standardEmitters")),
        jsonMismatch(standard, table.get("standardEmitters")));
    List<Object> areas = (List<Object>) table.get("areas");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      SpecDocument doc = documentFromState((Map<String, Object>) c.get("state"));
      List<SpecGenerationUnit> units = SpecGenerationUnits.specGenerationUnits(model, doc);
      List<Object> unitsJson = new ArrayList<>();
      Map<String, Object> mappingFor = new LinkedHashMap<>();
      for (SpecGenerationUnit u : units) {
        Map<String, Object> o = new LinkedHashMap<>();
        o.put("unitId", u.unitId);
        o.put("kind", u.kind);
        o.put("path", u.path);
        List<Object> mappings = new ArrayList<>();
        for (SpecGenerationUnitMapping m : u.mappings) {
          Map<String, Object> mo = new LinkedHashMap<>();
          mo.put("area", m.area);
          mo.put("mapping", m.mapping);
          mappings.add(mo);
        }
        o.put("mappings", mappings);
        o.put("emitters", new ArrayList<Object>(u.emitters));
        unitsJson.add(o);
        Map<String, Object> perArea = new LinkedHashMap<>();
        for (Object a : areas) {
          perArea.put((String) a, u.mappingFor((String) a));
        }
        mappingFor.put(u.unitId, perArea);
      }
      Map<String, Object> defaultUnits = new LinkedHashMap<>();
      for (Object a : areas) {
        defaultUnits.put(
            (String) a, new ArrayList<Object>(SpecGenerationUnits.specDefaultUnits(units, (String) a)));
      }
      Map<String, Object> sectionUnits = new LinkedHashMap<>();
      for (Object p : (List<Object>) c.get("sections")) {
        sectionUnits.put((String) p, doc.units((String) p));
      }
      Map<String, Object> got = new LinkedHashMap<>();
      got.put("units", unitsJson);
      got.put("mappingFor", mappingFor);
      got.put("defaultUnits", defaultUnits);
      got.put("sectionUnits", sectionUnits);
      Object expect = c.get("expect");
      check(
          "generationUnits[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /** Runs one {@code list_move_cases.json} case, in the shape of its {@code expect}. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> runListMoveCase(SpecModel model, Map<String, Object> c) {
    SpecDocument doc = new SpecDocument();
    doc.loadJson((Map<String, Object>) c.get("state"));
    Map<String, Object> move = (Map<String, Object>) c.get("move");
    Map<String, Object> out = new LinkedHashMap<>();
    try {
      SpecListItemMove result =
          doc.moveListItem(
              model,
              (String) move.get("itemPath"),
              ((Number) move.get("toIndex")).intValue(),
              (String) move.get("toList"));
      out.put("ok", true);
      out.put("path", result.path);
      out.put("renamed", new LinkedHashMap<String, Object>(result.renamed));
      out.put("pinnedIds", new LinkedHashMap<String, Object>(result.pinnedIds));
      out.put("document", doc.toJson());
    } catch (SpecSectionIdCollision e) {
      out.put("ok", false);
      out.put("error", "collision");
    } catch (IndexOutOfBoundsException e) {
      out.put("ok", false);
      out.put("error", "range");
    } catch (IllegalArgumentException e) {
      out.put("ok", false);
      out.put("error", "argument");
    }
    return out;
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
      // As the TS runner: only the value maps land; codeSpecs / units are
      // checked on their own below.
      Map<String, Object> loadJson = new LinkedHashMap<>(parsed.toLoadJson());
      loadJson.remove("codeSpecs");
      loadJson.remove("units");
      landed.loadJson(loadJson);
      Object wantDocument = c.get("document");
      check(
          "md.reject[" + name + "].landed",
          landed.toJson().equals(wantDocument),
          jsonMismatch(landed.toJson(), wantDocument));
      // A case naming the readable header holds it (SOM §11.1).
      if (c.containsKey("readableHeader")) {
        check(
            "md.reject[" + name + "].readableHeader",
            Objects.equals(parsed.readableHeader, c.get("readableHeader")),
            "got " + parsed.readableHeader);
      }
      // A case naming heading-comment values holds them too (read trimmed).
      for (String key : new String[] {"codeSpecs", "units"}) {
        Object want = c.get(key);
        if (want == null) continue;
        Map<String, String> gotMap = key.equals("codeSpecs") ? parsed.codeSpecs : parsed.units;
        check(
            "md.reject[" + name + "]." + key,
            gotMap.equals(want),
            jsonMismatch(gotMap, want));
      }
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
        case "setRawFormField": // raw form write (bypasses the typed boundary)
          doc.setFormField(path, field, (String) s.get("value"));
          break;
        case "valueUnreadable":
          // Stored text the declared type cannot read: the typed read refuses
          // it rather than answering null.
          check(at + path, raisesAny(() -> ed.value(path)), "");
          break;
        case "formValueUnreadable":
          check(at + path + "#" + field, raisesAny(() -> ed.formValue(path, field)), "");
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
  private static boolean raisesAny(Runnable fn) {
    try {
      fn.run();
      return false;
    } catch (RuntimeException e) {
      return true;
    }
  }

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

    // AA1 criterion 5 through the SomList facade: add / addContent with an
    // explicit section id, generated ids for a date, and a pattern-less list
    // ignoring the id.
    SpecDocument listDoc = new SpecDocument();
    Map<String, Object> listAdd = (Map<String, Object>) cases.get("listAdd");
    List<Object> steps = (List<Object>) listAdd.get("steps");
    for (int i = 0; i < steps.size(); i++) {
      Map<String, Object> s = (Map<String, Object>) steps.get(i);
      String op = (String) s.get("op");
      String listPath = (String) s.get("listPath");
      SomList<String> list =
          new SomList<>(listDoc, listPath, (d, p) -> p, (String) s.get("pattern"));
      LocalDate date =
          s.get("month") == null
              ? null
              : LocalDate.of(2026, intAt(s, "month"), intAt(s, "day"));
      String sectionId = (String) s.get("sectionId");
      Map<String, Object> got = new LinkedHashMap<>();
      try {
        String p =
            op.equals("add")
                ? list.add(sectionId, date)
                : list.addContent((String) s.get("content"), sectionId, date);
        got.put("path", p);
        got.put("content", listDoc.content(p + "/content"));
      } catch (SpecSectionIdCollision e) {
        got.put("error", "collision");
      } catch (RuntimeException e) {
        got.put("error", String.valueOf(e));
      }
      got.put("sectionIds", new ArrayList<Object>(listDoc.listItemSectionIds(listPath)));
      got.put("items", new ArrayList<Object>(listDoc.listItems(listPath)));
      Object want = s.get("expect");
      check(
          "sectionId.listAdd[" + i + "]." + op, got.equals(want), jsonMismatch(got, want));
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

    // The reading notation's rules are exercised by notation_cases.json's
    // validator cases (testNotation), not by the nine-runtime table.
    for (Object caseObj : (List<Object>) readJsonObject("notation_cases.json").get("validatorCases")) {
      for (Object vObj : (List<Object>) ((Map<String, Object>) caseObj).get("violations")) {
        covered.add((String) ((Map<String, Object>) vObj).get("rule"));
      }
    }

    List<String> uncovered = new ArrayList<>();
    for (String rule : DocSpecsViolation.ALL_RULES) {
      if (!covered.contains(rule)) {
        uncovered.add(rule);
      }
    }
    check("docspecs.ruleCoverage", uncovered.isEmpty(), "uncovered: " + uncovered);
  }

  /**
   * The reading notation ({@code notation_cases.json}, DocSpecs specification,
   * Reading Notation RN-1 … RN-13): each text value of {@code cases} scanned
   * with {@link SpecNotation#scanNotation} — its elements (UTF-16 {@code
   * start}/{@code end}, {@code line}/{@code endLine}, {@code source}/{@code
   * content}, nesting) and findings — then {@code validatorCases}, the nine
   * notation rules of the embedded DocSpecs validator over whole documents,
   * with and without {@code tomSpecs}.
   */
  @SuppressWarnings("unchecked")
  private static void testNotation() throws IOException {
    Map<String, Object> table = readJsonObject("notation_cases.json");
    List<Object> cases = (List<Object>) table.get("cases");
    check("notation.cases", !cases.isEmpty(), "no cases");
    Set<String> codes = new HashSet<>();
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      String text = (String) c.get("text");
      NotationScan scan =
          SpecNotation.scanNotation(text, Boolean.TRUE.equals(c.get("tomSpecs")));
      List<Object> elements = new ArrayList<>();
      for (NotationElement e : scan.elements) {
        elements.add(e.toJson(text));
      }
      List<Object> findings = new ArrayList<>();
      for (NotationFinding f : scan.findings) {
        findings.add(f.toJson());
      }
      check("notation.scan[" + name + "].elements", elements.equals(c.get("elements")),
          jsonMismatch(elements, c.get("elements")));
      check("notation.scan[" + name + "].findings", findings.equals(c.get("findings")),
          jsonMismatch(findings, c.get("findings")));
      for (Object fObj : (List<Object>) c.get("findings")) {
        codes.add((String) ((Map<String, Object>) fObj).get("code"));
      }
    }
    List<String> uncoveredCodes = new ArrayList<>();
    for (NotationFindingCode code : NotationFindingCode.values()) {
      if (!codes.contains(code.value)) {
        uncoveredCodes.add(code.value);
      }
    }
    check("notation.codeCoverage", uncoveredCodes.isEmpty(), "uncovered: " + uncoveredCodes);

    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(read("docspecs_schema.yaml"));
    Set<String> seen = new HashSet<>();
    for (Object caseObj : (List<Object>) table.get("validatorCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      DocSpecsValidator validator =
          new DocSpecsValidator(schema, Boolean.TRUE.equals(c.get("tomSpecs")));
      List<String> got = new ArrayList<>();
      for (DocSpecsViolation v : validator.validateMarkdown((String) c.get("markdown"))) {
        got.add(v.rule + "|" + v.sectionId + "|" + v.line);
      }
      List<String> want = new ArrayList<>();
      for (Object vObj : (List<Object>) c.get("violations")) {
        Map<String, Object> v = (Map<String, Object>) vObj;
        String rule = (String) v.get("rule");
        seen.add(rule);
        want.add(rule + "|" + v.get("sectionId") + "|" + ((Number) v.get("line")).intValue());
      }
      check("notation.validate[" + c.get("name") + "]", got.equals(want), got + " != " + want);
    }
    List<String> missing = new ArrayList<>();
    for (NotationFindingCode code : NotationFindingCode.values()) {
      if (!seen.contains(code.value)) {
        missing.add(code.value);
      }
    }
    check("notation.validatorCases report every notation rule", missing.isEmpty(),
        String.valueOf(missing));
  }

  // --- strip_cases.json: stripped renditions (SOM §11.10) --------------------

  /**
   * A case's strip options, from its name lists and flags; throws {@link
   * SpecStripUsageError} for a usage error.
   */
  private static SpecStripOptions stripOptions(Map<String, Object> c) {
    return SpecStripOptions.fromNames(
        c.get("drop") == null ? null : stringList(c.get("drop")),
        c.get("unmark") == null ? null : stringList(c.get("unmark")),
        c.get("appendix") == null ? null : stringList(c.get("appendix")),
        Boolean.TRUE.equals(c.get("appendixReferences")),
        Boolean.TRUE.equals(c.get("headingDivs")));
  }

  /** {@code stripped} with every piece put back at its anchor: the original. */
  private static String unstrip(String stripped, List<SpecStripPiece> pieces) {
    StringBuilder out = new StringBuilder();
    int at = 0;
    for (SpecStripPiece p : pieces) {
      out.append(stripped, at, p.anchor).append(p.removed);
      at = p.anchor + p.inserted.length();
    }
    return out.append(stripped.substring(at)).toString();
  }

  /**
   * {@code strip_cases.json}: {@code cases} — {@link SpecDocumentStrip#stripNotationText} of one
   * value, its pieces restoring the original, and a strip of only {@code comments} equal to
   * {@code stripAnnotationsText}; {@code usageCases} — {@link SpecStripOptions#fromNames}, the
   * expanded lists or the usage error's message; {@code headerCases} — {@link
   * SpecReadableHeader#parse} and {@code format}, inverse; {@code documentCases} — {@link
   * SpecDocumentStrip#strip} of a whole document: the copy, what was kept and removed, the
   * appendix, the counts, the readable header, the rendition and the kinds of its findings.
   */
  @SuppressWarnings("unchecked")
  private static void testStripCases(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("strip_cases.json");
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(read("docspecs_schema.yaml"));
    List<Object> cases = (List<Object>) table.get("cases");
    check("strip.cases", !cases.isEmpty(), "no cases");
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "strip[" + c.get("name") + "]";
      String text = (String) c.get("text");
      try {
        SpecStripTextResult r = SpecDocumentStrip.stripNotationText(text, stripOptions(c));
        Map<String, Object> got = r.toJson();
        check(name, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
        check(name + ".pieces", unstrip(r.text, r.pieces).equals(text), "pieces do not restore");
        if (List.of("comments").equals(c.get("drop"))) {
          check(
              name + ".stripAnnotationsText",
              r.text.equals(SpecReviewAnnotations.stripAnnotationsText(text)),
              r.text);
        }
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
    List<Object> usage = (List<Object>) table.get("usageCases");
    check("strip.usageCases", !usage.isEmpty(), "no usage cases");
    for (Object caseObj : usage) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Object got;
      try {
        got = stripOptions(c).toJson();
      } catch (SpecStripUsageError e) {
        Map<String, Object> error = new LinkedHashMap<>();
        error.put("error", e.getMessage());
        got = error;
      } catch (RuntimeException e) {
        got = "threw " + e;
      }
      check(
          "strip.usage[" + c.get("name") + "]",
          got.equals(c.get("expect")),
          jsonMismatch(got, c.get("expect")));
    }
    List<Object> headers = (List<Object>) table.get("headerCases");
    check("strip.headerCases", !headers.isEmpty(), "no header cases");
    for (Object caseObj : headers) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "strip.header[" + c.get("name") + "]";
      SpecReadableHeader h = SpecReadableHeader.parse((String) c.get("line"));
      Map<String, Object> got = null;
      if (h != null) {
        got = h.options.toJson();
        if (h.source != null) {
          Map<String, Object> source = new LinkedHashMap<>();
          source.put("file", h.source.file);
          source.put("revision", h.source.revision);
          source.put("commit", h.source.commit);
          source.put("dirty", h.source.dirty);
          got.put("source", source);
        }
        got.put("format", h.format());
        SpecReadableHeader again = SpecReadableHeader.parse(h.format());
        check(
            name + ".inverse",
            again != null && again.format().equals(h.format()),
            "format does not parse back");
      }
      boolean same = Objects.equals(got, c.get("expect"));
      check(name, same, same ? "" : "got " + got + ", want " + c.get("expect"));
    }
    List<Object> documents = (List<Object>) table.get("documentCases");
    check("strip.documentCases", !documents.isEmpty(), "no document cases");
    for (Object caseObj : documents) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "strip.document[" + c.get("name") + "]";
      try {
        SpecDocument doc = new SpecDocument();
        doc.loadJson((Map<String, Object>) c.get("state"));
        boolean withModel = !Boolean.FALSE.equals(c.get("model"));
        Map<String, Object> src = (Map<String, Object>) c.get("source");
        SpecStripResult r =
            SpecDocumentStrip.strip(
                doc,
                stripOptions(c),
                withModel ? model : null,
                withModel ? schema : null,
                (String) c.get("rootType"),
                null,
                null,
                src == null
                    ? null
                    : new SpecReadableSource(
                        (String) src.get("file"),
                        (String) src.get("revision"),
                        (String) src.get("commit"),
                        Boolean.TRUE.equals(src.get("dirty"))));
        Map<String, Object> got = new LinkedHashMap<>();
        got.put("document", r.document.toJson());
        List<Object> kept = new ArrayList<>();
        for (SpecStripKept k : r.kept) {
          kept.add(k.ref.toJson());
        }
        got.put("kept", kept);
        got.put("removedItems", new ArrayList<Object>(r.removedItems));
        List<Object> appendix = new ArrayList<>();
        for (SpecAppendixEntry e : r.appendix) {
          appendix.add(e.toJson());
        }
        got.put("appendix", appendix);
        got.put("dropped", new LinkedHashMap<String, Object>(r.dropped));
        got.put("unmarked", new LinkedHashMap<String, Object>(r.unmarked));
        got.put("appended", new LinkedHashMap<String, Object>(r.appended));
        got.put("marksDropped", r.marksDropped);
        got.put("readableHeader", r.readableHeader);
        got.put("readable", r.readable);
        List<Object> kinds = new ArrayList<>();
        for (SpecStripFinding f : r.findings) {
          kinds.add(f.kind);
        }
        got.put("findings", kinds);
        check(name, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
  }

  // --- strip_merge_cases.json: the merge back (SOM §11.10) --------------------

  /** {@code text} with each {@code [find, replace]} applied to its one occurrence. */
  @SuppressWarnings("unchecked")
  private static String applyCaseEdits(String text, Object edits) {
    String out = text;
    if (edits == null) {
      return out;
    }
    for (Object edit : (List<Object>) edits) {
      List<Object> pair = (List<Object>) edit;
      String find = (String) pair.get(0);
      String replace = (String) pair.get(1);
      if (find.isEmpty()) {
        if (!out.isEmpty()) {
          throw new IllegalStateException("an empty find needs an empty text");
        }
        out = replace;
        continue;
      }
      int at = out.indexOf(find);
      if (at < 0 || out.indexOf(find, at + 1) >= 0) {
        throw new IllegalStateException("the edit \"" + find + "\" does not occur exactly once");
      }
      out = out.substring(0, at) + replace + out.substring(at + find.length());
    }
    return out;
  }

  @SuppressWarnings("unchecked")
  private static SpecDocument stateDocument(Object json) {
    SpecDocument d = new SpecDocument();
    d.loadJson((Map<String, Object>) json);
    return d;
  }

  /**
   * {@code strip_merge_cases.json}: {@code valueCases} — a value stripped, its stripped text
   * edited, and {@link SpecStripMerge#mergeStrippedValue} of the edit onto the original;
   * {@code documentCases} — a document stripped into its readable rendition, the rendition
   * edited, and {@link SpecStripMerge#merge} of it onto the document (or onto {@code current},
   * the original moved since, three ways from {@code base} or the header's commit in
   * {@code commits}): the exit code, staleness, the merged document and the report, or the
   * usage error.
   */
  @SuppressWarnings("unchecked")
  private static void testStripMergeCases(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("strip_merge_cases.json");
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText(read("docspecs_schema.yaml"));
    List<Object> values = (List<Object>) table.get("valueCases");
    check("stripMerge.valueCases", !values.isEmpty(), "no value cases");
    for (Object caseObj : values) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "stripMerge.value[" + c.get("name") + "]";
      try {
        String original = (String) c.get("original");
        SpecStripTextResult s = SpecDocumentStrip.stripNotationText(original, stripOptions(c));
        String e = applyCaseEdits(s.text, c.get("edits"));
        Map<String, Object> got =
            SpecStripMerge.mergeStrippedValue(original, s.text, e, s.pieces).toJson();
        check(name, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
    List<Object> documents = (List<Object>) table.get("documentCases");
    check("stripMerge.documentCases", !documents.isEmpty(), "no document cases");
    for (Object caseObj : documents) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "stripMerge.document[" + c.get("name") + "]";
      try {
        SpecDocument state = stateDocument(c.get("state"));
        Map<String, Object> src = (Map<String, Object>) c.get("source");
        String readable =
            SpecDocumentStrip.strip(
                    state,
                    stripOptions(c),
                    model,
                    schema,
                    null,
                    null,
                    null,
                    src == null
                        ? null
                        : new SpecReadableSource(
                            (String) src.get("file"),
                            (String) src.get("revision"),
                            (String) src.get("commit"),
                            Boolean.TRUE.equals(src.get("dirty"))))
                .readable;
        String edited = applyCaseEdits(readable, c.get("edits"));
        Map<String, Object> commits =
            c.get("commits") == null
                ? new LinkedHashMap<>()
                : (Map<String, Object>) c.get("commits");
        Map<String, Object> got = new LinkedHashMap<>();
        try {
          SpecStripMergeResult r =
              SpecStripMerge.merge(
                  c.get("current") == null ? state : stateDocument(c.get("current")),
                  edited,
                  new SpecStripMergeOptions(model)
                      .schema(schema)
                      .options(
                          c.get("options") == null
                              ? null
                              : stripOptions((Map<String, Object>) c.get("options")))
                      .currentRevision((String) c.get("currentRevision"))
                      .base(c.get("base") == null ? null : stateDocument(c.get("base")))
                      .loadBase(
                          source ->
                              source.commit != null && commits.get(source.commit) != null
                                  ? stateDocument(commits.get(source.commit))
                                  : null));
          got.put("exitCode", r.exitCode());
          got.put("stale", r.stale);
          got.put("document", r.document == null ? null : r.document.toJson());
          got.put("report", new ArrayList<Object>(r.report()));
        } catch (SpecStripUsageError e) {
          got.put("error", e.getMessage());
        }
        check(name, got.equals(c.get("expect")), jsonMismatch(got, c.get("expect")));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
  }

  /**
   * {@code docspecs_replace_cases.json}: {@link DocSpecsDocument#replaceSectionBody}
   * either rejects the case (the error flag must match) or returns exactly the
   * expected text.
   */
  @SuppressWarnings("unchecked")
  private static void testDocSpecsReplace() throws IOException {
    Map<String, Object> table = readJsonObject("docspecs_replace_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      Map<String, Object> expect = (Map<String, Object>) c.get("expect");
      boolean wantError = Boolean.TRUE.equals(expect.get("error"));
      String got;
      boolean gotError;
      try {
        got =
            DocSpecsDocument.replaceSectionBody(
                (String) c.get("markdown"), (String) c.get("sectionId"), (String) c.get("body"));
        gotError = false;
      } catch (IllegalArgumentException e) {
        got = e.getMessage();
        gotError = true;
      }
      boolean ok = gotError == wantError && (wantError || got.equals(expect.get("text")));
      check("docspecsReplace[" + name + "]", ok, "error=" + gotError + ": " + got);
    }
  }

  /**
   * {@code docspecs_path_cases.json}: the renderer's heading map (1-based
   * heading line → document path) and the findings of
   * {@link SpecSchemaValidation#validateSpecDocument}, each carrying the
   * document path of the section its line belongs to.
   */
  @SuppressWarnings("unchecked")
  private static void testDocSpecsPaths(SpecModel model) throws IOException {
    Map<String, Object> table = readJsonObject("docspecs_path_cases.json");
    DocSpecsSchema schema = DocSpecsSchema.fromYamlText((String) table.get("schema"));
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "docspecsPaths[" + c.get("name") + "]";
      String rootType = (String) c.get("rootType");
      try {
        SpecDocument doc = documentFromState((Map<String, Object>) c.get("state"));
        SpecMarkdownRendition rendition = doc.toMarkdownWithMap(model, rootType);
        Map<String, Object> map = new LinkedHashMap<>();
        for (Map.Entry<Integer, String> e : rendition.headingPaths.entrySet()) {
          map.put(String.valueOf(e.getKey()), e.getValue());
        }
        Object wantMap = c.get("headingPaths");
        check(name + ".headingPaths", map.equals(wantMap), jsonMismatch(map, wantMap));
        check(name + ".markdown", rendition.markdown.equals(doc.toMarkdown(model, rootType)),
            "rendition differs from toMarkdown");
        List<Object> got = new ArrayList<>();
        for (DocSpecsViolation v
            : SpecSchemaValidation.validateSpecDocument(model, doc, schema, rootType)) {
          Map<String, Object> m = new LinkedHashMap<>();
          m.put("rule", v.rule);
          m.put("line", v.line);
          m.put("sectionId", v.sectionId);
          m.put("path", v.path);
          got.add(m);
        }
        Object want = c.get("violations");
        check(name + ".violations", got.equals(want), jsonMismatch(got, want));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
    }
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
    // SOM §11.4 rule 8: rendered as an inline code span, so the
    // `](` stays literal instead of becoming a markdown link.
    d.setFormField("DEMO/DET", "pattern", "^[a-z0-9](-?[a-z0-9]){1,62}$");
    // A multi-line value ending in a markdown list (SOM §11.4 rule 2).
    d.setFormField(
        "DEMO/DET", "contact", "bob@example.com\n- on call: weekdays\n- backup: alice@example.com");
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
    // An item of a pattern list stores its id even when it equals the
    // positional default (`REF-2`, `CARD-2` below): the Markdown heading
    // carries that id and import stores it (SOM §11.6), so the YAML and the
    // Markdown route can only land in the same memory if the fixture does too.
    // Positional items stay covered by the pattern-less `items` and `tags`.
    d.setItemSectionId("DEMO/REF-LST-2", "REF-2");
    d.setHeadline("DEMO/SUM", "Executive Summary");
    d.setHeadline("DEMO/DET", "Details & Contacts");
    d.setHeadline("DEMO/items", "Work Items");
    d.setItemSectionId("DEMO/REF-LST-1", "REF-SPEC");
    d.setHeadline("DEMO/REF-LST-1", "Reference to the Spec");
    String c1 = d.addListItem("DEMO/CARD-LST");
    d.setItemSectionId(c1, "CARD-ALPHA");
    d.setHeadline(c1, "Alpha Card");
    d.setFormField(c1 + "/content", "note", "first card");
    // Card 2 stores the default id `CARD-2` and keeps the derived item title.
    String c2 = d.addListItem("DEMO/CARD-LST", "CARD-2");
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
    d.setContent("DEMO/notes/remarks", "Wrapper-section text");
    // `Mixed` (SOM §11.6 slot markers): a body region holding the owner's
    // preamble form, a content slot, a second content slot and a second form
    // sharing a label — every unit needs its marker to land where it was
    // written. The headline carries a line break (written as `<br>`) and the
    // narrative keeps its two blank lines (no collapse).
    d.setHeadline("DEMO/MIX", "Mixed\nslots");
    d.setContent("DEMO/MIX/content", "_Extrapolated._");
    d.setFormField("DEMO/MIX/content", "lead", "Ada");
    d.setFormField("DEMO/MIX/content", "risk", "low");
    d.setContent(
        "DEMO/MIX/narrative",
        "First narrative.\n\n\nAfter two blank lines.\nLead: label-shaped prose");
    d.setContent("DEMO/MIX/tail", "Tail text.");
    d.setFormField("DEMO/MIX/alt", "lead", "Bob");
    // SOM §11.2 `units`: a section carrying codeSpec AND units (`TTL`, both keys
    // in one heading comment, the scalar-promotion mapping in yaml) and a
    // section carrying units alone (`notes`), which the extract hands down to
    // every entry beneath it. Both ids are declared by the register.
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "demo_server");
    d.setUnits("DEMO/notes", "demo_client,demo_server");
    // Pattern-list items store their positional ids, as `REF-2` does above.
    String u1 = d.addListItem("DEMO/DLV-LST", "DLV-1");
    d.setFormField(u1 + "/content", "unitId", "demo_client");
    d.setFormField(u1 + "/content", "kind", "client");
    d.setFormField(u1 + "/content", "component", "ARCM-COMP-UI");
    // Both units map CE-NV, so an entry routed there with no stored units goes
    // to both by default, in register order (the extract's `units`).
    String n1 = d.addListItem(u1 + "/DLR-LST", "DLR-1");
    d.setFormField(n1 + "/content", "area", "CE-NV");
    d.setFormField(n1 + "/content", "mapping", "dart-tom");
    String u2 = d.addListItem("DEMO/DLV-LST", "DLV-2");
    d.setFormField(u2 + "/content", "unitId", "demo_server");
    d.setFormField(u2 + "/content", "kind", "server");
    d.setFormField(u2 + "/content", "deploymentTarget", "DEPTAR-DEPL-API");
    String r1 = d.addListItem(u2 + "/DLR-LST", "DLR-1");
    d.setFormField(r1 + "/content", "area", "CE-DB");
    d.setFormField(r1 + "/content", "mapping", "dart-tom");
    String r2 = d.addListItem(u2 + "/DLR-LST", "DLR-2");
    d.setFormField(r2 + "/content", "area", "CE-NV");
    d.setFormField(r2 + "/content", "mapping", "dart-tom");
    // The server ships the OpenAPI document of its contract (irspecs_ir.md §10).
    String e1 = d.addListItem(u2 + "/DLE-LST", "DLE-1");
    d.setFormField(e1 + "/content", "emitter", "openapi");
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
   * The catalogue's authoring-step table as a runtime reads it back: every
   * step's fields, {@code stepsFor} per area, and a catalogue written before the
   * table was transcribed, which must still load with no steps.
   */
  private static Map<String, Object> codeSpecsStepCases(Map<String, Object> catalogJson) {
    CodeSpecsAreaCatalog catalog = CodeSpecsAreaCatalog.fromJson(catalogJson);
    Map<String, Object> legacyJson = new LinkedHashMap<>(catalogJson);
    legacyJson.remove("steps");
    CodeSpecsAreaCatalog legacy = CodeSpecsAreaCatalog.fromJson(legacyJson);

    List<Object> steps = new ArrayList<>();
    for (CodeSpecsStep s : catalog.steps) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("number", s.number);
      o.put("title", s.title);
      o.put("slice", s.slice);
      o.put("placedBy", s.placedBy);
      o.put("areaCodes", new ArrayList<Object>(s.areaCodes));
      steps.add(o);
    }
    Map<String, Object> legacyOut = new LinkedHashMap<>();
    legacyOut.put("steps", legacy.steps.size());
    legacyOut.put("areas", legacy.areas.size());
    legacyOut.put("stepsByArea", stepsByArea(legacy));

    Map<String, Object> out = new LinkedHashMap<>();
    out.put("steps", steps);
    out.put("stepsByArea", stepsByArea(catalog));
    out.put("legacy", legacyOut);
    return out;
  }

  private static Map<String, Object> stepsByArea(CodeSpecsAreaCatalog catalog) {
    Map<String, Object> out = new LinkedHashMap<>();
    for (CodeSpecsArea a : catalog.areas) {
      List<Object> numbers = new ArrayList<>();
      for (CodeSpecsStep s : catalog.stepsFor(a)) {
        numbers.add(s.number);
      }
      out.put(a.code, numbers);
    }
    return out;
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

    // 0. The catalogue's §4.4.6 authoring steps read back as committed — and a
    // catalogue written before the step table was transcribed still loads.
    Map<String, Object> catalogJson = (Map<String, Object>) table.get("catalog");
    Object gotStepCases = codeSpecsStepCases(catalogJson);
    Object wantStepCases = table.get("stepCases");
    check(
        "codeSpecs.stepCases",
        gotStepCases.equals(wantStepCases),
        jsonMismatch(gotStepCases, wantStepCases));

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
        o.put("instanceId", e.instanceId);
        o.put("path", e.path);
        o.put("className", e.className);
        o.put("fieldName", e.fieldName);
        o.put("formField", e.formField);
        o.put("routedBy", e.routedBy);
        o.put("routedAt", e.routedAt);
        o.put("routingNote", e.routingNote);
        o.put("units", new ArrayList<Object>(e.units));
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

    // 5b. A malformed catalogue row fails at load, and the error names the row.
    for (Object caseObj : (List<Object>) table.get("catalogErrorCases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = (String) c.get("name");
      String want = (String) ((Map<String, Object>) c.get("expect")).get("messageContains");
      String at = "codeSpecs.catalogError[" + name + "]";
      IllegalArgumentException err = null;
      try {
        CodeSpecsAreaCatalog.fromJson((Map<String, Object>) c.get("catalog"));
      } catch (IllegalArgumentException e) {
        err = e;
      }
      check(at + ".throws", err != null, "fromJson() succeeded");
      if (err != null) {
        check(at + ".message", err.getMessage().contains(want), err.getMessage());
      }
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

  /**
   * The canonical typed-value reading ({@code typed_value_cases.json}): each
   * input read as int / double / num and written back by the formatter, and
   * whether the text is readable for each type. A case without a {@code num}
   * key is not checked for num.
   */
  @SuppressWarnings("unchecked")
  private static void testTypedValues() throws IOException {
    Map<String, Object> table = readJsonObject("typed_value_cases.json");
    for (Object caseObj : (List<Object>) table.get("cases")) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String input = (String) c.get("input");
      Integer asInt = SpecTypedValues.somParseInt(input);
      Double asDouble = SpecTypedValues.somParseDouble(input);
      Map<String, Object> readable = new LinkedHashMap<>();
      readable.put("int", SpecTypedValues.somTypedTextReadable("int", input));
      readable.put("double", SpecTypedValues.somTypedTextReadable("double", input));
      readable.put("num", SpecTypedValues.somTypedTextReadable("num?", input));
      Map<String, Object> got = new LinkedHashMap<>();
      got.put("input", input);
      got.put("int", asInt == null ? null : SpecTypedValues.somFormatInt(asInt));
      got.put("double", asDouble == null ? null : SpecTypedValues.somFormatDouble(asDouble));
      got.put("readable", readable);
      if (c.containsKey("num")) {
        Number asNum = SpecTypedValues.somParseNum(input);
        got.put("num", asNum == null ? null : SpecTypedValues.somFormatNum(asNum));
      }
      check("typedValues[" + Json.write(input) + "]", got.equals(c), jsonMismatch(got, c));
    }
  }

  // --- the section links (tom_specs_model_rules.md §9.7) --------------------

  /**
   * Replays the {@code typedCases} of {@code inline_mark_cases.json} /
   * {@code change_mark_cases.json} like the scripted annotation cases: typed values
   * and headlines under review (SOM §11.9.3).
   */
  @SuppressWarnings("unchecked")
  private static void runTypedMarkCases(
      String label, SpecModel model, SomMetaTree tree, List<Object> cases) {
    check(label + ".cases", cases != null && !cases.isEmpty(), "no typedCases");
    if (cases == null) {
      return;
    }
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      Map<String, Object> got = runAnnotationCase(model, tree, c);
      Object expect = c.get("expect");
      check(label + "[" + c.get("name") + "]", got.equals(expect), jsonMismatch(got, expect));
    }
  }

  /** The findings as {@code {path, code}}. */
  private static List<Object> validationPairs(List<SpecValidationError> errors) {
    List<Object> out = new ArrayList<>();
    for (SpecValidationError e : errors) {
      Map<String, Object> m = new LinkedHashMap<>();
      m.put("path", e.path);
      m.put("code", e.code.value);
      out.add(m);
    }
    return out;
  }

  /**
   * The typed reading of the value at {@code path} / {@code field}: an enum by its
   * name, {@code int}, {@code double}, {@code num} and {@code bool} as numbers and
   * booleans, null when the text reads as nothing — with any inline mark rejected
   * (its old value).
   */
  private static Object typedRead(SpecModel model, SpecDocument doc, Map<String, Object> op) {
    String path = (String) op.get("path");
    String field = (String) op.get("field");
    SpecResolution res = new SpecReflection(model).resolve(path);
    FormFieldSpec spec = null;
    if (field != null && res != null && res.field != null) {
      for (FormFieldSpec ff : res.field.formFields) {
        if (ff.name.equals(field)) {
          spec = ff;
          break;
        }
      }
    }
    String raw = field != null ? doc.formField(path, field) : doc.content(path);
    String typeName = null;
    List<String> values = null;
    if (spec != null) {
      typeName = spec.type;
      values = spec.enumValues;
    } else if (res != null && res.field != null) {
      typeName = res.field.type;
      values = res.field.enumValues;
    }
    if (values != null && !values.isEmpty()) {
      return SpecTypedValues.somParseEnumName(raw, values);
    }
    String base = SpecTypedValues.somScalarBase(typeName);
    if ("int".equals(base)) {
      return SpecTypedValues.somParseInt(raw);
    }
    if ("double".equals(base)) {
      return SpecTypedValues.somParseDouble(raw);
    }
    if ("num".equals(base)) {
      return SpecTypedValues.somParseNum(raw);
    }
    if ("bool".equals(base)) {
      return SpecTypedValues.somParseBool(raw);
    }
    return raw == null ? null : SpecTypedValues.somTypedReading(raw);
  }

  /**
   * What the link readers return for {@code model}, in canonical JSON: every class
   * sync, every member link, every form-field qualifier, and the {@code @SameAs}
   * bindings per root. Classes by name, fields and form fields in declaration
   * order (the Dart test's {@code linkReadBack}).
   */
  private static Map<String, Object> linkReadBack(SpecModel model) {
    List<String> names = new ArrayList<>(new java.util.TreeSet<>(model.classes.keySet()));
    SpecReflection refl = new SpecReflection(model);
    List<Object> classes = new ArrayList<>();
    List<Object> fields = new ArrayList<>();
    List<Object> formFields = new ArrayList<>();
    for (String n : names) {
      SpecSync sync = model.classes.get(n).syncedWith();
      if (sync != null) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("class", n);
        row.put("syncedWith", sync.toJson());
        classes.add(row);
      }
    }
    for (String n : names) {
      for (SpecField f : model.classes.get(n).fields) {
        SpecSync sync = f.syncedWith();
        SpecSummaryOf summary = f.summaryOf();
        SpecDerivation derived = f.derivedFrom();
        List<SpecExtractsLinks> extracts = f.extractsLinks();
        SpecSameAs sameAs = f.sameAs();
        if (sync == null && summary == null && derived == null && extracts.isEmpty()
            && sameAs == null) {
          continue;
        }
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("class", n);
        row.put("field", f.name);
        if (sync != null) {
          row.put("syncedWith", sync.toJson());
        }
        if (summary != null) {
          row.put("summaryOf", summary.toJson());
        }
        if (derived != null) {
          row.put("derivedFrom", derived.toJson());
        }
        if (!extracts.isEmpty()) {
          List<Object> list = new ArrayList<>();
          for (SpecExtractsLinks e : extracts) {
            list.add(e.toJson());
          }
          row.put("extractsLinks", list);
        }
        if (sameAs != null) {
          row.put("sameAs", sameAs.toJson());
        }
        fields.add(row);
      }
    }
    for (String n : names) {
      for (SpecField f : model.classes.get(n).fields) {
        for (FormFieldSpec ff : f.formFields) {
          if (ff.derivedFrom == null && ff.inverseOf == null && ff.summaryOf == null) {
            continue;
          }
          Map<String, Object> row = new LinkedHashMap<>();
          row.put("class", n);
          row.put("field", f.name);
          row.put("formField", ff.name);
          if (ff.derivedFrom != null) {
            row.put("derivedFrom", ff.derivedFrom.toJson());
          }
          if (ff.inverseOf != null) {
            row.put("inverseOf", ff.inverseOf.toJson());
          }
          if (ff.summaryOf != null) {
            row.put("summaryOf", ff.summaryOf.toJson());
          }
          formFields.add(row);
        }
      }
    }
    List<Object> bindings = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      for (SpecSameAsBinding b : SpecPlace.sameAsBindings(refl, r.type)) {
        bindings.add(b.toJson());
      }
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("classes", classes);
    out.put("fields", fields);
    out.put("formFields", formFields);
    out.put("sameAsBindings", bindings);
    out.put("classCount", model.classes.size());
    return out;
  }

  /** One place case: the text parsed, then resolved under {@code anchor} when given. */
  private static Map<String, Object> placeCase(SpecReflection refl, Map<String, Object> c) {
    Map<String, Object> out = new LinkedHashMap<>();
    SpecPlace place = SpecPlace.tryParse((String) c.get("text"));
    if (place == null) {
      out.put("problem", SpecPlaceProblem.MALFORMED.value);
      return out;
    }
    out.put("parsed", place.toJson());
    String anchor = (String) c.get("anchor");
    if (anchor == null) {
      return out;
    }
    try {
      out.put("resolved", place.resolve(refl, anchor).toJson());
    } catch (SpecPlaceException e) {
      out.put("problem", e.problem.value);
    }
    return out;
  }

  /**
   * One filter case: the text parsed, resolved under {@code anchor} when given,
   * and matched against {@code stored} when given.
   */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> filterCase(SpecReflection refl, Map<String, Object> c) {
    Map<String, Object> out = new LinkedHashMap<>();
    SpecPlaceFilter f = SpecPlaceFilter.tryParse((String) c.get("text"));
    if (f == null) {
      out.put("problem", SpecPlaceProblem.MALFORMED.value);
      return out;
    }
    out.put("parsed", f.toJson());
    if (c.get("stored") != null) {
      List<String> stored = new ArrayList<>();
      for (Object v : (List<Object>) c.get("stored")) {
        stored.add(v instanceof String ? (String) v : Json.write(v));
      }
      out.put("matches", f.matches(stored));
    }
    String anchor = (String) c.get("anchor");
    if (anchor != null) {
      try {
        out.put("resolved", f.resolve(refl, anchor).toJson());
      } catch (SpecPlaceException e) {
        out.put("problem", e.problem.value);
      }
    }
    return out;
  }

  /** The rows of list {@code key} of an expectation. */
  @SuppressWarnings("unchecked")
  private static List<Map<String, Object>> expectRows(Map<String, Object> e, String key) {
    List<Map<String, Object>> out = new ArrayList<>();
    Object raw = e.get(key);
    if (raw instanceof List) {
      for (Object r : (List<Object>) raw) {
        if (r instanceof Map) {
          out.add((Map<String, Object>) r);
        }
      }
    }
    return out;
  }

  private static boolean anyRowHas(Map<String, Object> e, String key, String member) {
    for (Map<String, Object> r : expectRows(e, key)) {
      if (r.containsKey(member)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Whether the reader-case intent token holds in the expectation {@code e} (the
   * Dart test's {@code _readerIntentHolds}); {@code null} for an unknown token.
   */
  @SuppressWarnings("unchecked")
  private static Boolean readerIntentHolds(String token, Map<String, Object> e) {
    switch (token) {
      case "syncedWith":
        return !expectRows(e, "classes").isEmpty();
      case "syncRelationWhere":
        for (Map<String, Object> m : expectRows(e, "classes")) {
          Object sync = m.get("syncedWith");
          if (sync instanceof Map) {
            for (Map<String, Object> rel :
                expectRows((Map<String, Object>) sync, "relations")) {
              if (rel.containsKey("where")) {
                return true;
              }
            }
          }
        }
        return false;
      case "summaryOf":
        return anyRowHas(e, "fields", "summaryOf");
      case "summaryOfDocument":
        for (Map<String, Object> m : expectRows(e, "fields")) {
          Object s = m.get("summaryOf");
          if (s instanceof Map && ((Map<String, Object>) s).containsKey("document")) {
            return true;
          }
        }
        return false;
      case "derivedFrom":
        return anyRowHas(e, "fields", "derivedFrom");
      case "extractsLinksRepeated":
        for (Map<String, Object> m : expectRows(e, "fields")) {
          Object l = m.get("extractsLinks");
          if (l instanceof List && ((List<Object>) l).size() > 1) {
            return true;
          }
        }
        return false;
      case "sameAs":
        return anyRowHas(e, "fields", "sameAs");
      case "formDerivedFrom":
        return anyRowHas(e, "formFields", "derivedFrom");
      case "formInverseOf":
        return anyRowHas(e, "formFields", "inverseOf");
      case "formSymmetric":
        for (Map<String, Object> m : expectRows(e, "formFields")) {
          Object inv = m.get("inverseOf");
          if (inv instanceof Map) {
            Object fs = ((Map<String, Object>) inv).get("fields");
            if (fs instanceof List && ((List<Object>) fs).contains("@self")) {
              return true;
            }
          }
        }
        return false;
      case "formSummaryOf":
        return anyRowHas(e, "formFields", "summaryOf");
      case "sameAsHolder":
        return anyRowHas(e, "sameAsBindings", "holder");
      case "loadsUnchanged":
        {
          Object count = e.get("classCount");
          return count instanceof Number
              && ((Number) count).intValue() > 0
              && expectRows(e, "classes").isEmpty()
              && expectRows(e, "fields").isEmpty()
              && expectRows(e, "formFields").isEmpty()
              && expectRows(e, "sameAsBindings").isEmpty();
        }
      default:
        return null;
    }
  }

  /**
   * Every string a text case's expectation shows: kinds, problems, and
   * {@code matches} / {@code noMatch} (the Dart test's {@code _tokens}).
   */
  @SuppressWarnings("unchecked")
  private static void linkTokens(Object v, String key, Set<String> out) {
    if (v instanceof List) {
      for (Object x : (List<Object>) v) {
        linkTokens(x, "", out);
      }
    } else if (v instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) v).entrySet()) {
        linkTokens(e.getValue(), e.getKey(), out);
      }
    } else if (v instanceof Boolean) {
      if (key.equals("matches")) {
        out.add((Boolean) v ? "matches" : "noMatch");
      }
    } else if (v instanceof String) {
      if (key.equals("kind") || key.equals("problem")) {
        out.add((String) v);
      }
    }
  }

  /**
   * {@code link_reader_cases.json}: the typed readers of the link annotations
   * over {@code links.meta.json}, the place / filter grammar, and the LR / CO
   * spot checks.
   */
  @SuppressWarnings("unchecked")
  private static void testLinkReaders() throws IOException {
    Map<String, Object> metaJson = readJsonObject("links.meta.json");
    Map<String, Object> table = readJsonObject("link_reader_cases.json");
    List<Object> cases = (List<Object>) table.get("cases");
    check("links.reader.cases", !cases.isEmpty(), "no cases in link_reader_cases.json");
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "links.reader[" + c.get("name") + "]";
      Object meta = "links.meta.json".equals(c.get("model")) ? metaJson : c.get("meta");
      if (meta instanceof String) {
        meta = Json.parse((String) meta);
      }
      Object want = c.get("expect");
      try {
        Map<String, Object> got =
            Json.parseObject(Json.write(linkReadBack(SpecModel.fromJson((Map<String, Object>) meta))));
        check(name, got.equals(want), jsonMismatch(got, want));
      } catch (RuntimeException e) {
        check(name, false, "threw " + e);
      }
      for (Object tokenObj : (List<Object>) c.get("intent")) {
        String token = (String) tokenObj;
        Boolean holds = readerIntentHolds(token, (Map<String, Object>) want);
        check(
            "links.reader.intent[" + c.get("name") + ": " + token + "]",
            Boolean.TRUE.equals(holds),
            holds == null ? "unknown intent token" : "does not hold");
      }
    }
    SpecModel model = SpecModel.fromJson(metaJson);
    SpecReflection refl = new SpecReflection(model);
    Map<String, Object> textCases = (Map<String, Object>) table.get("textCases");
    for (String kind : List.of("place", "filter")) {
      List<Object> list = (List<Object>) textCases.get(kind.equals("place") ? "places" : "filters");
      check("links." + kind + ".cases", list != null && !list.isEmpty(), "no " + kind + " cases");
      for (Object caseObj : list) {
        Map<String, Object> c = (Map<String, Object>) caseObj;
        String name = "links." + kind + "[" + c.get("name") + "]";
        Object want = c.get("expect");
        try {
          Map<String, Object> got =
              Json.parseObject(
                  Json.write(kind.equals("place") ? placeCase(refl, c) : filterCase(refl, c)));
          check(name, got.equals(want), jsonMismatch(got, want));
        } catch (RuntimeException e) {
          check(name, false, "threw " + e);
        }
        Set<String> shown = new HashSet<>();
        linkTokens(want, "", shown);
        for (Object token : (List<Object>) c.get("intent")) {
          check(
              "links." + kind + ".intent[" + c.get("name") + ": " + token + "]",
              shown.contains(token),
              "");
        }
      }
    }

    // LR1: the class sync is read with its relations.
    SpecSync reqs = model.classes.get("Requirements").syncedWith();
    check(
        "links.LR1.sync",
        reqs != null
            && reqs.document.equals("Detail")
            && reqs.detailOnly.equals(List.of("REQX"))
            && reqs.heldHere.equals(List.of("REQ.owner"))
            && reqs.relations.size() == 1
            && reqs.relations.get(0).relation.equals("subset"),
        "");
    SpecSync crit = model.classes.get("Criteria").syncedWith();
    check(
        "links.LR1.where",
        crit != null
            && crit.relations.size() == 1
            && "CRITE.kind=functional|quality".equals(crit.relations.get(0).where),
        "");
    check("links.LR1.none", model.classes.get("Blueprint").syncedWith() == null, "");

    // LR2: member links and the repeated @ExtractsLinks.
    SpecClass req = model.classes.get("Requirement");
    List<SpecExtractsLinks> links = req.fieldNamed("links").extractsLinks();
    List<String> modes = new ArrayList<>();
    for (SpecExtractsLinks x : links) {
      modes.add(x.mode);
    }
    check("links.LR2.modes", modes.equals(List.of("generate", "warn")), String.join(",", modes));
    check(
        "links.LR2.set",
        !links.isEmpty() && links.get(0).set.equals(Map.of("LNK.linkType", "namedInText")),
        "");
    SpecDerivation abstractD = req.fieldNamed("abstract").derivedFrom();
    check("links.LR2.copy", abstractD != null && abstractD.kind.equals("copy"), "");
    SpecDerivation pre = req.fieldNamed("prerequisites").derivedFrom();
    check("links.LR2.map", pre != null && pre.map.equals(Map.of("PRE.ref", "LNK-REF.ref")), "");
    check("links.LR2.noSummary", req.fieldNamed("links").summaryOf() == null, "");

    // LR3: the form-field qualifiers.
    SpecDerivation conflicts = formField(model, "Requirement", "constraints", "conflictsWith").derivedFrom;
    check(
        "links.LR3.where",
        conflicts != null && "LNK.linkType=conflict".equals(conflicts.where),
        "");
    SpecInverseOf sym = formField(model, "Link", "ref", "ref").inverseOf;
    check("links.LR3.symmetric", sym != null && sym.symmetric(), "");
    SpecInverseOf nsym = formField(model, "Requirement", "trace", "relatedScreens").inverseOf;
    check("links.LR3.notSymmetric", nsym != null && !nsym.symmetric(), "");
    SpecSummaryOf focus = formField(model, "Blueprint", "focus", "focusScreens").summaryOf;
    check("links.LR3.summaryDocument", focus != null && "Screens".equals(focus.document), "");

    // LR4: the real model — S1 has one holder in each document.
    SpecModel somModel =
        SpecModel.fromJson(
            Json.parseObject(
                new String(
                    Files.readAllBytes(
                        corpus.resolve("../../tom_som_dart_v0/meta/spec_model.meta.json").normalize()),
                    StandardCharsets.UTF_8)));
    SpecReflection realRefl = new SpecReflection(somModel);
    for (String root : List.of("D00SolutionBlueprint", "D10QualityAcceptancePlan")) {
      List<SpecSameAsBinding> bindings = SpecPlace.sameAsBindings(realRefl, root);
      List<Object> shown = new ArrayList<>();
      for (SpecSameAsBinding b : bindings) {
        shown.add(b.toJson());
      }
      check(
          "links.LR4[" + root + "]",
          bindings.size() == 1
              && bindings.get(0).className.equals("AcceptanceCriteriaList")
              && bindings.get(0).problem == null
              && bindings.get(0).copyPath.endsWith("/detailedCriteria"),
          Json.write(shown));
    }

    // CO1–CO2: countOf reads the filter, `|` included.
    check("links.CO1", countFindings(model, "2", "3").isEmpty(), "");
    String base = "BLU/requirements";
    check("links.CO2.settled", countFindings(model, "3", "3").equals(List.of(base + "/REQS-SUM")), "");
    check("links.CO2.total", countFindings(model, "2", "2").equals(List.of(base + "/REQS-SUM")), "");
  }

  private static FormFieldSpec formField(SpecModel model, String cls, String field, String name) {
    for (FormFieldSpec f : model.classes.get(cls).fieldNamed(field).formFields) {
      if (f.name.equals(name)) {
        return f;
      }
    }
    throw new IllegalStateException("no form field " + cls + "." + field + "." + name);
  }

  /** The countMismatch paths of a requirements list stating {@code settled} / {@code total}. */
  private static List<String> countFindings(SpecModel model, String settled, String total) {
    String base = "BLU/requirements";
    SpecDocument d = new SpecDocument();
    for (String status : List.of("approved", "done", "draft")) {
      String item = d.addListItem(base + "/REQ-ITEM-LST");
      d.setFormField(item + "/content", "status", status);
    }
    d.setFormField(base + "/REQS-SUM", "total", total);
    d.setFormField(base + "/REQS-SUM", "settled", settled);
    List<String> out = new ArrayList<>();
    for (SpecValidationError e : SpecValidator.validateDocument(model, d)) {
      if (e.code == SpecValidationCode.COUNT_MISMATCH) {
        out.add(e.path);
      }
    }
    return out;
  }

  /** {@code {path, code}} rows of an expectation list (null: none). */
  @SuppressWarnings("unchecked")
  private static List<Object> expectedFindings(Object raw) {
    return raw == null ? new ArrayList<>() : (List<Object>) raw;
  }

  /** {@code link_validation_cases.json}: the link checks of one document. */
  @SuppressWarnings("unchecked")
  private static void testLinkValidation() throws IOException {
    Map<String, Object> table = readJsonObject("link_validation_cases.json");
    Object metaName = table.get("model");
    SpecModel model =
        SpecModel.fromJson(readJsonObject(metaName == null ? "links.meta.json" : (String) metaName));
    List<Object> cases = (List<Object>) table.get("cases");
    check("links.validate.cases", !cases.isEmpty(), "no cases in link_validation_cases.json");
    Set<String> provoked = new HashSet<>();
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String name = "links.validate[" + c.get("name") + "]";
      List<Object> want = expectedFindings(c.get("errors"));
      List<Object> wantInstance = expectedFindings(c.get("instanceErrors"));
      Set<String> codes = new HashSet<>();
      for (Object e : want) {
        String code = (String) ((Map<String, Object>) e).get("code");
        provoked.add(code);
        codes.add(code);
      }
      for (Object e : wantInstance) {
        codes.add((String) ((Map<String, Object>) e).get("code"));
      }
      SpecDocument d =
          documentFromState(Json.parseObject(Json.write(c.get("state"))));
      List<Object> got = validationPairs(SpecValidator.validateLinks(model, d));
      check(name + ".errors", got.equals(want), jsonMismatch(got, want));
      List<Object> instance = validationPairs(SpecValidator.validateDocument(model, d));
      check(name + ".instanceErrors", instance.equals(wantInstance), jsonMismatch(instance, wantInstance));
      for (Object tokenObj : (List<Object>) c.get("intent")) {
        String token = (String) tokenObj;
        boolean holds = token.equals("clean") ? codes.isEmpty() : codes.contains(token);
        check("links.validate.intent[" + c.get("name") + ": " + token + "]", holds, "");
      }
    }
    for (SpecValidationCode code :
        List.of(
            SpecValidationCode.DERIVED_VALUE_MISMATCH,
            SpecValidationCode.DERIVED_LOOKUP_MISS,
            SpecValidationCode.DUPLICATE_LINK_ROW,
            SpecValidationCode.INVERSE_MISSING,
            SpecValidationCode.EXTRACTED_LINK_MISSING,
            SpecValidationCode.EXTRACTED_LINK_STALE,
            SpecValidationCode.SUMMARY_NOT_IN_DETAIL,
            SpecValidationCode.DETAIL_NOT_IN_SUMMARY,
            SpecValidationCode.SUMMARY_DUPLICATE,
            SpecValidationCode.SAME_AS_MISMATCH,
            SpecValidationCode.LINK_VALUE_PENDING)) {
      check("links.validate.provoked[" + code.value + "]", provoked.contains(code.value), "");
    }
  }

  // --- the document set (tom_specs_model_rules.md §9.7) ---------------------

  private static SpecModel realModel;

  /** The real SOM model (11 MB), loaded once across the tables. */
  private static SpecModel realModel() throws IOException {
    if (realModel == null) {
      realModel =
          SpecModel.fromJson(
              Json.parseObject(
                  new String(
                      Files.readAllBytes(
                          corpus.resolve("../../tom_som_dart_v0/meta/spec_model.meta.json").normalize()),
                      StandardCharsets.UTF_8)));
    }
    return realModel;
  }

  @SuppressWarnings("unchecked")
  private static List<Map<String, Object>> setCases(Map<String, Object> table, String group) {
    List<Map<String, Object>> out = new ArrayList<>();
    Object raw = table.get(group);
    if (raw instanceof List) {
      for (Object x : (List<Object>) raw) {
        out.add((Map<String, Object>) x);
      }
    }
    return out;
  }

  /** The documents of a case, {@code [[name, state], …]}. */
  @SuppressWarnings("unchecked")
  private static List<Map.Entry<String, SpecDocument>> setDocuments(Object entries) {
    List<Map.Entry<String, SpecDocument>> out = new ArrayList<>();
    if (entries instanceof List) {
      for (Object e : (List<Object>) entries) {
        List<Object> pair = (List<Object>) e;
        out.add(Map.entry((String) pair.get(0), stateDocument(pair.get(1))));
      }
    }
    return out;
  }

  /** The case's {@code pairs} list, {@code null} when it has none. */
  @SuppressWarnings("unchecked")
  private static List<String> casePairs(Map<String, Object> c) {
    Object raw = c.get("pairs");
    if (!(raw instanceof List)) {
      return null;
    }
    List<String> out = new ArrayList<>();
    for (Object x : (List<Object>) raw) {
      out.add(String.valueOf(x));
    }
    return out;
  }

  @SuppressWarnings("unchecked")
  private static List<String> caseIntent(Map<String, Object> c) {
    List<String> out = new ArrayList<>();
    Object raw = c.get("intent");
    if (raw instanceof List) {
      for (Object x : (List<Object>) raw) {
        out.add(String.valueOf(x));
      }
    }
    return out;
  }

  private static boolean caseFlag(Map<String, Object> c, String key) {
    return Boolean.TRUE.equals(c.get(key));
  }

  private static SpecModel corpusModel(Object name) throws IOException {
    return SpecModel.fromJson(readJsonObject(name == null ? "links.meta.json" : (String) name));
  }

  /** The model a case runs against: an inline one, the real one, or the fixture. */
  @SuppressWarnings("unchecked")
  private static SpecModel caseModel(SpecModel fixture, Map<String, Object> c) throws IOException {
    if (c.get("inline") instanceof Map) {
      return SpecModel.fromJson((Map<String, Object>) c.get("inline"));
    }
    if ("som".equals(c.get("model"))) {
      return realModel();
    }
    return fixture;
  }

  private interface CaseRun {
    Object run() throws IOException;
  }

  /** Compares one case's output (as JSON) with its expectation. */
  private static void checkCase(String name, CaseRun run, Object expect) {
    Object got;
    try {
      got = Json.parse(Json.write(run.run()));
    } catch (IOException | RuntimeException e) {
      check(name, false, "threw " + e);
      return;
    }
    check(name, Objects.equals(got, expect), "got " + Json.write(got) + " want " + Json.write(expect));
  }

  private static List<Object> stringsJson(List<String> ss) {
    return new ArrayList<Object>(ss);
  }

  private static Object setConstructionCase(SpecModel model, Map<String, Object> c) {
    List<Map.Entry<String, SpecDocument>> docs = setDocuments(c.get("documents"));
    SpecDocumentSet s;
    try {
      s = caseFlag(c, "fragments")
          ? SpecDocumentSet.fromFragments(model, docs)
          : new SpecDocumentSet(model, docs);
    } catch (SpecDocumentSetError e) {
      Map<String, Object> out = new LinkedHashMap<>();
      out.put("refused", e.toJson());
      return out;
    }
    List<Object> pairs = new ArrayList<>();
    for (SpecSyncPair p : s.pairs()) {
      pairs.add(p.toJson());
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("blueprintRoot", s.blueprintRoot);
    out.put("names", stringsJson(s.names()));
    out.put("roots", stringsJson(s.roots()));
    out.put("missingRoots", stringsJson(s.missingRoots()));
    out.put("pairs", pairs);
    return out;
  }

  private static Object setRenameCase(SpecModel model, Map<String, Object> c) {
    SpecDocumentSet s = new SpecDocumentSet(model, setDocuments(c.get("documents")));
    List<SpecRenameChange> changes;
    try {
      changes = SpecDocumentSet.renameId(s, (String) c.get("from"), (String) c.get("to"));
    } catch (SpecRenameError e) {
      Map<String, Object> out = new LinkedHashMap<>();
      out.put("refused", stringsJson(e.documents));
      return out;
    }
    SpecSyncReport after = SpecDocumentSet.syncReport(s);
    List<Object> list = new ArrayList<>();
    for (SpecRenameChange x : changes) {
      list.add(x.toJson());
    }
    int n = 0;
    for (SpecSyncFinding f : after.findings) {
      if (!f.isInfo()) {
        n++;
      }
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("changes", list);
    out.put("cleanAfter", after.clean());
    out.put("findingsAfter", n);
    return out;
  }

  private static int listLen(Object v) {
    return v instanceof List ? ((List<?>) v).size() : 0;
  }

  /** Every token a document-set expectation shows (the Dart test's {@code _setTokens}). */
  @SuppressWarnings("unchecked")
  private static Set<String> setTokens(Object expect) {
    Set<String> out = new HashSet<>();
    Map<String, Object> e = (Map<String, Object>) expect;
    Object refused = e.get("refused");
    if (refused instanceof Map) {
      out.add(String.valueOf(((Map<String, Object>) refused).get("refusal")));
    }
    if (refused instanceof List) {
      out.add("refused");
    }
    if (e.get("pairs") != null && refused == null) {
      out.add("built");
      if (listLen(e.get("missingRoots")) > 0) {
        out.add("missingRoots");
      }
    }
    if (e.get("findings") != null) {
      if (Boolean.TRUE.equals(e.get("clean"))) {
        out.add("clean");
      }
      if (listLen(e.get("notStarted")) > 0) {
        out.add("notStarted");
      }
      if (listLen(e.get("notStartedPairs")) > 0) {
        out.add("notStartedPairs");
      }
      for (Object f : (List<Object>) e.get("findings")) {
        Map<String, Object> fm = (Map<String, Object>) f;
        out.add(String.valueOf(fm.get("code")));
        out.add(String.valueOf(fm.get("resolution")));
      }
      for (Object d : (List<Object>) e.get("documentFindings")) {
        for (Object x : (List<Object>) ((List<Object>) d).get(1)) {
          out.add(String.valueOf(((Map<String, Object>) x).get("code")));
        }
      }
    }
    if (listLen(e.get("changes")) > 0) {
      out.add("renamed");
    }
    return out;
  }

  private interface SetCaseFn {
    Object run(Map<String, Object> c) throws IOException;
  }

  /** {@code document_set_cases.json}: the set, its report and the global rename. */
  @SuppressWarnings("unchecked")
  private static void testDocumentSet() throws IOException {
    Map<String, Object> table = readJsonObject("document_set_cases.json");
    SpecModel fixture = corpusModel(table.get("model"));
    Map<String, SetCaseFn> groups = new LinkedHashMap<>();
    groups.put(
        "construction",
        c ->
            setConstructionCase(
                c.get("meta") instanceof Map
                    ? SpecModel.fromJson((Map<String, Object>) c.get("meta"))
                    : fixture,
                c));
    groups.put(
        "reports",
        c ->
            SpecDocumentSet.syncReport(
                    new SpecDocumentSet(caseModel(fixture, c), setDocuments(c.get("documents"))),
                    casePairs(c))
                .toJson());
    groups.put("renames", c -> setRenameCase(fixture, c));
    for (Map.Entry<String, SetCaseFn> g : groups.entrySet()) {
      String group = g.getKey();
      List<Map<String, Object>> cases = setCases(table, group);
      for (Map<String, Object> c : cases) {
        String name = "set." + group + "[" + c.get("name") + "]";
        checkCase(name, () -> g.getValue().run(c), c.get("expect"));
        Set<String> shown = setTokens(c.get("expect"));
        for (String token : caseIntent(c)) {
          check("set." + group + ".intent[" + c.get("name") + ": " + token + "]", shown.contains(token), "");
        }
      }
    }
    // DSC4: the real model pairs every synced class.
    try {
      SpecDocumentSet real = new SpecDocumentSet(realModel());
      check("set.DSC4.blueprintRoot", "D00SolutionBlueprint".equals(real.blueprintRoot),
          String.valueOf(real.blueprintRoot));
      check("set.DSC4.pairs", real.pairs().size() == 132, String.valueOf(real.pairs().size()));
    } catch (SpecDocumentSetError e) {
      check("set.DSC4.blueprintRoot", false, e.toString());
      check("set.DSC4.pairs", false, e.toString());
    }
  }

  // --- deriveFields ----------------------------------------------------------

  private static Object deriveCase(SpecModel model, Map<String, Object> c) {
    SpecDocument doc = stateDocument(c.get("state"));
    SpecDeriveOptions options = new SpecDeriveOptions();
    if (c.get("marked") instanceof Boolean) {
      options.marked = (Boolean) c.get("marked");
    }
    options.author = (String) c.get("author");
    options.at = (String) c.get("at");
    options.dryRun = caseFlag(c, "dryRun");
    SpecDeriveResult first = SpecDeriveFields.deriveFields(model, doc, options);
    SpecDeriveResult second = SpecDeriveFields.deriveFields(model, doc, options);
    // The first run's result is read after the second, as the reference
    // runners read it (the same document unless it is a dry run).
    Map<String, Object> firstJson = first.toJson();
    List<SpecValidationError> after = new ArrayList<>(SpecValidator.validateLinks(model, second.document));
    after.addAll(SpecValidator.validateDocument(model, second.document));
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("first", firstJson);
    out.put("second", second.toJson());
    out.put("findingsAfter", validationPairs(after));
    out.put("given", doc.toJson());
    return out;
  }

  /** Whether a derive intent token holds of the expectation; {@code null}: unknown token. */
  @SuppressWarnings("unchecked")
  private static Boolean deriveIntentHolds(String token, Map<String, Object> c) {
    Map<String, Object> e = (Map<String, Object>) c.get("expect");
    Map<String, Object> first = (Map<String, Object>) e.get("first");
    List<Object> changes = (List<Object>) first.get("changes");
    switch (token) {
      case "nothing":
        return changes.isEmpty();
      case "step1":
      case "step2":
      case "step3":
        return anyEntry(changes, "step", Integer.valueOf(token.charAt(4) - '0'));
      case "rowAdded":
      case "rowRemoved":
        return anyEntry(changes, "kind", token);
      case "marked":
        for (Object x : changes) {
          if (String.valueOf(((Map<String, Object>) x).get("new")).contains("{")) {
            return true;
          }
        }
        return false;
      case "clean":
        return listLen(e.get("findingsAfter")) == 0;
      case "idempotent":
        {
          Map<String, Object> second = (Map<String, Object>) e.get("second");
          return listLen(second.get("changes")) == 0
              && Objects.equals(second.get("document"), first.get("document"));
        }
      case "unchanged":
        return Objects.equals(e.get("given"), c.get("state"));
      case "unmarkable":
      case "derivedLookupMiss":
        return anyEntry((List<Object>) first.get("unresolved"), "code", token);
      default:
        return null;
    }
  }

  @SuppressWarnings("unchecked")
  private static boolean anyEntry(List<Object> rows, String key, Object want) {
    if (rows == null) {
      return false;
    }
    for (Object x : rows) {
      if (Objects.equals(((Map<String, Object>) x).get(key), want)) {
        return true;
      }
    }
    return false;
  }

  private static void checkIntent(String label, Map<String, Object> c, String token, Boolean holds) {
    check(label + ".intent[" + c.get("name") + ": " + token + "]", Boolean.TRUE.equals(holds),
        holds == null ? "unknown intent token" : "does not hold");
  }

  /** {@code derive_cases.json}: deriveFields, plain and marked, run twice. */
  private static void testDeriveFields() throws IOException {
    Map<String, Object> table = readJsonObject("derive_cases.json");
    SpecModel model = corpusModel(table.get("model"));
    List<Map<String, Object>> cases = setCases(table, "cases");
    for (Map<String, Object> c : cases) {
      checkCase("derive[" + c.get("name") + "]", () -> deriveCase(model, c), c.get("expect"));
      for (String token : caseIntent(c)) {
        checkIntent("derive", c, token, deriveIntentHolds(token, c));
      }
    }
  }

  // --- prefill and backfill --------------------------------------------------

  private static Object prefillCase(SpecModel model, Map<String, Object> c) {
    SpecDocumentSet s = new SpecDocumentSet(model, setDocuments(c.get("documents")));
    SpecPrefillOptions options = new SpecPrefillOptions();
    options.name = (String) c.get("name_");
    options.pairs = casePairs(c);
    Object[] runs = new Object[2];
    for (int i = 0; i < 2; i++) {
      try {
        runs[i] = SpecPrefill.prefill(s, (String) c.get("root"), options).toJson();
      } catch (SpecPrefillError e) {
        Map<String, Object> refused = new LinkedHashMap<>();
        refused.put("refused", e.code);
        runs[i] = refused;
      }
    }
    SpecSyncReport after = SpecDocumentSet.syncReport(s);
    Map<String, Object> report = new LinkedHashMap<>();
    report.put("countsByCode", after.countsByCodeJson());
    report.put("notStartedPairs", stringsJson(after.notStartedPairs));
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("first", runs[0]);
    out.put("second", runs[1]);
    out.put("reportAfter", report);
    return out;
  }

  @SuppressWarnings("unchecked")
  private static Boolean prefillIntentHolds(String token, Map<String, Object> c) {
    Map<String, Object> e = (Map<String, Object>) c.get("expect");
    Map<String, Object> first = (Map<String, Object>) e.get("first");
    Map<String, Object> second = (Map<String, Object>) e.get("second");
    switch (token) {
      case "created":
        return Boolean.TRUE.equals(first.get("created"));
      case "filled":
        return listLen(first.get("filledPairs")) > 0;
      case "skipped":
        return listLen(first.get("skippedPairs")) > 0;
      case "derived":
        {
          Object d = first.get("derived");
          return d instanceof Map && listLen(((Map<String, Object>) d).get("changes")) > 0;
        }
      case "idempotent":
        {
          Object d = second.get("derived");
          return listLen(second.get("filledPairs")) == 0
              && (!(d instanceof Map) || listLen(((Map<String, Object>) d).get("changes")) == 0)
              && Objects.equals(second.get("document"), first.get("document"));
        }
      case "agrees":
        {
          Map<String, Object> report = (Map<String, Object>) e.get("reportAfter");
          for (Object x : (List<Object>) report.get("countsByCode")) {
            if (String.valueOf(((List<Object>) x).get(0)).startsWith("shared")) {
              return false;
            }
          }
          return true;
        }
      case "noBlueprint":
      case "unknownRoot":
        return token.equals(first.get("refused"));
      default:
        return null;
    }
  }

  private static Object backfillCase(SpecModel fixture, Map<String, Object> c) throws IOException {
    SpecDocumentSet s = new SpecDocumentSet(caseModel(fixture, c), setDocuments(c.get("documents")));
    SpecBackfillOptions options = new SpecBackfillOptions();
    options.pairs = casePairs(c);
    options.path = (String) c.get("path");
    options.dryRun = caseFlag(c, "dryRun");
    options.author = (String) c.get("author");
    options.date = (String) c.get("date");
    Object[] runs = new Object[2];
    for (int i = 0; i < 2; i++) {
      try {
        runs[i] = SpecBackfill.backfill(s, options).toJson();
      } catch (SpecBackfillError e) {
        Map<String, Object> refused = new LinkedHashMap<>();
        refused.put("refused", e.toJson());
        runs[i] = refused;
      }
    }
    SpecSyncReport after = SpecDocumentSet.syncReport(s);
    List<Object> given = new ArrayList<>();
    for (String n : s.names()) {
      given.add(List.of(n, s.get(n).toJson()));
    }
    Map<String, Object> report = new LinkedHashMap<>();
    report.put("countsByCode", after.countsByCodeJson());
    report.put("clean", after.clean());
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("first", runs[0]);
    out.put("second", runs[1]);
    out.put("reportAfter", report);
    out.put("given", given);
    return out;
  }

  @SuppressWarnings("unchecked")
  private static Boolean backfillIntentHolds(String token, Map<String, Object> c) {
    Map<String, Object> e = (Map<String, Object>) c.get("expect");
    Map<String, Object> first = (Map<String, Object>) e.get("first");
    Map<String, Object> second = (Map<String, Object>) e.get("second");
    List<Object> changes = (List<Object>) first.get("changes");
    List<Object> left = (List<Object>) first.get("left");
    switch (token) {
      case "nothing":
        return first.get("refused") == null && listLen(changes) == 0;
      case "value":
      case "elementAdded":
      case "elementRemoved":
      case "revision":
      case "derived":
        return anyEntry(changes, "kind", token);
      case "heldHere":
      case "mayBeAdded":
      case "agent":
        return anyEntry(left, "reason", token);
      case "setHasMarks":
        {
          Object refused = first.get("refused");
          return refused instanceof Map
              && "setHasMarks".equals(((Map<String, Object>) refused).get("code"))
              && listLen(((Map<String, Object>) refused).get("places")) > 0;
        }
      case "idempotent":
        return listLen(second.get("changes")) == 0;
      case "unchanged":
        return Objects.equals(e.get("given"), c.get("documents"));
      case "cleanAfter":
        return Boolean.TRUE.equals(((Map<String, Object>) e.get("reportAfter")).get("clean"));
      default:
        return null;
    }
  }

  /** {@code prefill_cases.json} and {@code backfill_cases.json}, each run twice. */
  private static void testPrefillBackfill() throws IOException {
    Map<String, Object> prefillTable = readJsonObject("prefill_cases.json");
    SpecModel prefillModel = corpusModel(prefillTable.get("model"));
    List<Map<String, Object>> prefillCases = setCases(prefillTable, "cases");
    for (Map<String, Object> c : prefillCases) {
      checkCase("prefill[" + c.get("name") + "]", () -> prefillCase(prefillModel, c), c.get("expect"));
      for (String token : caseIntent(c)) {
        checkIntent("prefill", c, token, prefillIntentHolds(token, c));
      }
    }
    Map<String, Object> backfillTable = readJsonObject("backfill_cases.json");
    SpecModel backfillModel = corpusModel(backfillTable.get("model"));
    List<Map<String, Object>> backfillCases = setCases(backfillTable, "cases");
    for (Map<String, Object> c : backfillCases) {
      checkCase("backfill[" + c.get("name") + "]", () -> backfillCase(backfillModel, c), c.get("expect"));
      for (String token : caseIntent(c)) {
        checkIntent("backfill", c, token, backfillIntentHolds(token, c));
      }
    }
  }

  // --- the rendition's navigation and generated parts (SOM §11.11, §11.12) ---

  /** {@code doc} rendered as the rendition of the first root of {@code model} it holds a value under. */
  private static String renditionOf(
      SpecModel model, SpecDocument doc, String fileStem, boolean markers, boolean generated) {
    SpecRoot root = null;
    for (SpecRoot r : model.roots) {
      String seg = r.sectionId == null || r.sectionId.isEmpty() ? r.type : r.sectionId;
      if (doc.hasValuesUnder(seg)) {
        root = r;
        break;
      }
    }
    if (root == null) {
      throw new IllegalStateException("no root holds a value");
    }
    return new SpecDocumentMarkdown(model, doc, fileStem, null, false, null, markers, generated)
        .exportRoot(root);
  }

  private static final java.util.regex.Pattern RENDITION_MARKER_LINE =
      java.util.regex.Pattern.compile("^\\[.*\\]\\{\\.linked\\}$");

  /** {@code markdown} with its {@code linked} marker paragraphs removed. */
  private static String withoutMarkers(String markdown) {
    String[] lines = markdown.split("\n", -1);
    List<String> out = new ArrayList<>();
    for (int i = 0; i < lines.length; i++) {
      if (RENDITION_MARKER_LINE.matcher(lines[i]).matches()) {
        if (i + 1 < lines.length && lines[i + 1].isEmpty()) {
          i++;
        }
        continue;
      }
      out.add(lines[i]);
    }
    return String.join("\n", out);
  }

  /** One rendition case, as the Dart test's {@code renditionCase} computes it. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> renditionCase(SpecModel fixture, Map<String, Object> c)
      throws IOException {
    SpecModel model = caseModel(fixture, c);
    SpecDocument doc = stateDocument(c.get("state"));
    boolean markers = !Boolean.FALSE.equals(c.get("linkedMarkers"));
    boolean generated = !Boolean.FALSE.equals(c.get("generatedParts"));
    String markdown = renditionOf(model, doc, "links", markers, generated);
    String given = markdown;
    if (caseFlag(c, "dropMarkers")) {
      given = withoutMarkers(given);
    }
    if (c.get("edits") instanceof List) {
      for (Object e : (List<Object>) c.get("edits")) {
        List<Object> pair = (List<Object>) e;
        String from = String.valueOf(pair.get(0));
        String to = String.valueOf(pair.get(1));
        int at = given.indexOf(from);
        if (at < 0) {
          throw new IllegalStateException(c.get("name") + ": the rendition has no \"" + from + "\"");
        }
        given = given.substring(0, at) + to + given.substring(at + from.length());
      }
    }
    SpecMarkdownImport parsed = SpecDocument.fromMarkdown(given, model);
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("markdown", markdown);
    if (!given.equals(markdown)) {
      out.put("given", given);
    }
    List<Object> rejections = new ArrayList<>();
    for (SpecMarkdownRejection r : parsed.rejections()) {
      rejections.add(r.reason.value);
    }
    out.put("rejections", rejections);
    out.put(
        "parseMatches",
        Objects.equals(
            Json.parse(Json.write(parsed.document.toJson())), Json.parse(Json.write(doc.toJson()))));
    String reemit = renditionOf(model, parsed.document, "links", markers, generated);
    out.put("reemitMatches", reemit.equals(markdown));
    return out;
  }

  private static boolean finds(String regex, String text) {
    return java.util.regex.Pattern.compile(regex, java.util.regex.Pattern.MULTILINE)
        .matcher(text)
        .find();
  }

  /**
   * Whether the rendition-case intent {@code token} holds in case {@code c}
   * (the Dart test's {@code _renditionIntentHolds}); {@code null} for an
   * unknown token.
   */
  @SuppressWarnings("unchecked")
  private static Boolean renditionIntentHolds(String token, Map<String, Object> c) {
    Map<String, Object> e = (Map<String, Object>) c.get("expect");
    String md = e.get("markdown") instanceof String ? (String) e.get("markdown") : "";
    boolean parsed = Boolean.TRUE.equals(e.get("parseMatches"));
    boolean reemit = Boolean.TRUE.equals(e.get("reemitMatches"));
    boolean edited = e.get("given") instanceof String;
    String given = edited ? (String) e.get("given") : "";
    switch (token) {
      case "alsoInHeldThere":
        return finds("\\[Also in \\[[^\\]]+\\]\\([^)]+\\), held there", md);
      case "alsoInHeldHere":
        return finds("\\[Also in \\[[^\\]]+\\]\\([^)]+\\), held here", md);
      case "heldException":
        return md.contains(" except REQ.owner");
      case "summaryOf":
        return md.contains(
            "held there except REQ.owner; Summary of [REQ-EXPORT](#REQ-EXPORT)]{.linked}");
      case "summarisedIn":
        return md.contains("Summarised in [KEY-1](#KEY-1)");
      case "derivedTwoFields":
        return finds("Derived from (\\[[^\\]]+\\]\\([^)]+\\)(,)?)+: \\w+, \\w+", md);
      case "extractedFrom":
        return md.contains("[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}");
      case "copyOf":
        return md.contains("[Copy of [CRIT](#CRIT), edit it there]{.linked}");
      case "copiedTo":
        return md.contains("Copied to [CRIT](#CSUM/CRIT)");
      case "copyAnchors":
        return md.contains("<a id=\"CSUM/CRIT/CRIT-SPEED\"></a>");
      case "qualifiedThree":
        return finds("^#+ <!--\\[LNK-REF\\]--> <a id=\"REQ-EXPORT/LNK-1/LNK-REF\"></a> ", md);
      case "markerRestored":
        return edited && !given.contains("{.linked}") && parsed && reemit;
      case "handEditDiscarded":
        return edited && given.contains("Copy of [X]") && parsed && reemit;
      case "emptyMarker":
        return md.contains("[]{.linked}\n\n[To be chosen") && parsed;
      case "spanKept":
        return Json.write(c.get("state")).contains("{.linked}") && parsed;
      case "dangling":
        return md.contains(
            "[Also in [BLU REQ-PRESETS](links.blu.tomspecs.md#REQ-PRESETS), held here");
      case "generatedTrace":
        return md.contains(
            "::: {.derived label=\"Generated from each requirement's traceability; "
                + "edit it there\"}\n| Requirement | Use cases | Screens | Data entities | Tests |");
      case "generatedCoverage":
        return finds(
            "\\| Requirement \\| Covered \\| By \\|\n\\| --- \\| --- \\| --- \\|\n"
                + "\\| \\[FRE-REQU-TENANT-LIFECYCLE\\]\\(#FRE-REQU-TENANT-LIFECYCLE\\) \\| (yes|no) \\|",
            md);
      case "generatedRelationships":
        return md.contains("| Requirement | Dependency | Related requirement |");
      case "generatedFirst":
        return finds(
            "^## <!--\\[REQCOV\\]--> <a id=\"REQCOV\"></a> [^\n]*\n\n"
                + "(\\[[^\n]*\\]\\{\\.linked\\}\n\n)?::: \\{\\.derived ",
            md);
      case "generatedOverview":
        return md.contains("<!--[RO-TRAC]-->") && md.contains("| Requirement | Use cases | Screens |");
      case "generatedUseCases":
        return md.contains("| [INEN-INTE-UC-02](#INEN-INTE-UC-02) |  | [FRE-REQU-TENANT-FEATURES](");
      case "generatedEditDiscarded":
        return edited && given.contains("| Requirement | Covered |\n") && parsed && reemit;
      case "noGenerated":
        return !md.contains("{.derived");
      case "emptyGenerated":
        return md.contains("::: {.derived}\n:::\n\n::: {.derived}\nTraced by hand.\n:::");
      case "summaryRowLink":
        return md.contains("| <a id=\"TOP-BETA\"></a>[TOP-BETA](#TOP-BETA) |")
            && md.contains("| <a id=\"TOP-BETA\"></a>TOP-BETA |");
      case "noMarkers":
        return !md.contains("{.linked}") && md.contains("<a id=\"REQ-EXPORT/REQD\"></a>");
      case "roundTrip":
        return !edited && parsed && reemit;
      case "clean":
        return listLen(e.get("rejections")) == 0;
      default:
        return null;
    }
  }

  /**
   * {@code link_rendition_cases.json}: each case's rendition, what the parser
   * makes of it and the rendition of that, against the expectation, and its
   * intent.
   */
  @SuppressWarnings("unchecked")
  private static void testLinkRendition() throws IOException {
    Map<String, Object> table = readJsonObject("link_rendition_cases.json");
    SpecModel fixture = corpusModel(table.get("model"));
    for (Map<String, Object> c : setCases(table, "cases")) {
      String name = "links.rendition[" + c.get("name") + "]";
      Map<String, Object> got = null;
      try {
        got = (Map<String, Object>) Json.parse(Json.write(renditionCase(fixture, c)));
      } catch (IOException | RuntimeException ex) {
        check(name, false, "threw " + ex);
      }
      if (got != null) {
        Map<String, Object> expect = (Map<String, Object>) c.get("expect");
        for (String k :
            List.of("markdown", "given", "rejections", "parseMatches", "reemitMatches")) {
          boolean ok = Objects.equals(got.get(k), expect.get(k));
          String detail = "";
          if (!ok) {
            detail = got.get(k) instanceof String && expect.get(k) instanceof String
                ? byteDiff(k, (String) got.get(k), (String) expect.get(k))
                : "got " + Json.write(got.get(k)) + " want " + Json.write(expect.get(k));
          }
          check(name + "." + k, ok, detail);
        }
        List<String> gk = new ArrayList<>(got.keySet());
        List<String> ek = new ArrayList<>(expect.keySet());
        java.util.Collections.sort(gk);
        java.util.Collections.sort(ek);
        check(name + ".keys", gk.equals(ek), gk + " vs " + ek);
      }
      for (String token : caseIntent(c)) {
        checkIntent("links.rendition", c, token, renditionIntentHolds(token, c));
      }
    }
  }

  /**
   * The schema tier finds nothing in the markers and generated parts (the
   * Dart test's RNC5, real model): each document's findings with navigation
   * equal its findings without.
   */
  private static void testRenditionSchemaTier() throws IOException {
    Map<String, Object> table = readJsonObject("uam_requirements_cut.json");
    SpecDocument rsp = stateDocument(table.get("rsp"));
    SpecDocument sbp = stateDocument(table.get("blueprint"));
    SpecDocument isc = new SpecDocument();
    String item = isc.addListItem("ISC/interactionCatalog/INEN-INTE-LST", "INEN-INTE-UC-01");
    isc.setFormField(item + "/INTR", "relatedRequirements", "FRE-REQU-TENANT-LIFECYCLE");
    SpecModel model = realModel();
    Object[][] docs = {
      {rsp, "requirements-specification"},
      {sbp, "solution-blueprint"},
      {isc, "interaction-scenarios"},
    };
    for (Object[] dc : docs) {
      SpecDocument doc = (SpecDocument) dc[0];
      String schemaName = (String) dc[1];
      String name = "links.rendition.schemaTier[" + schemaName + "]";
      try {
        Path file = corpus.resolve("../../tom_som_dart_v0/schemas/" + schemaName + "/"
            + schemaName + ".1.0.docspecs-schema.yaml").normalize();
        DocSpecsSchema schema = DocSpecsSchema.fromYamlText(
            new String(Files.readAllBytes(file), StandardCharsets.UTF_8));
        String md = renditionOf(model, doc, null, true, true);
        List<String> with = schemaFindings(schema, md);
        List<String> without = schemaFindings(schema, renditionOf(model, doc, null, false, false));
        check(name + ".derived", md.contains("{.derived"), "");
        check(name, with.equals(without), "got " + with + " want " + without);
      } catch (IOException | RuntimeException ex) {
        check(name, false, "threw " + ex);
      }
    }
  }

  private static List<String> schemaFindings(DocSpecsSchema schema, String md) {
    List<String> out = new ArrayList<>();
    for (DocSpecsViolation v : new DocSpecsValidator(schema, true).validateMarkdown(md)) {
      out.add(v.rule + " " + v.sectionId);
    }
    java.util.Collections.sort(out);
    return out;
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
    testYamlReviewCases(model, tree);
    testMarkdownExport(model);
    testMarkdownRoundTrip(model);
    testMarkdownMemoryLanding(model);
    testMarkdownImportRejections(model);
    testMarkdownApplyCases(model);
    testAssemblyCases();
    testAnnotationCases(model, tree);
    testTeamAnnotationCases(model, tree);
    testReviewMergeCases(model);
    testInlineMarkCases(model, tree);
    testChangeMarkCases(model, tree);
    testAnswerCases(model);
    testListMoveCases(model);
    testReflection(model);
    testValidation(model);
    testOperations();
    testEditor(model);
    testSectionId();
    testSerializationOrder();
    testDocSpecs();
    testNotation();
    testStripCases(model);
    testStripMergeCases(model);
    testDocSpecsReplace();
    testDocSpecsPaths(model);
    testFixtureDocument();
    testPatterns();
    testQueries(model);
    testProjection(model);
    testCodeSpecsExtract(model);
    testCodeSpecsRecords();
    testCodeSpecsGate();
    testCursorScript(model);
    testNodeCreationCases(model);
    testNodeCreationCoverage();
    testNodeCreationScript(model);
    testGenerationUnits(model);
    testTypedValues();
    testImpactWalk();
    testLinkReaders();
    testLinkValidation();
    testDocumentSet();
    testDeriveFields();
    testPrefillBackfill();
    testLinkRendition();
    testRenditionSchemaTier();

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
