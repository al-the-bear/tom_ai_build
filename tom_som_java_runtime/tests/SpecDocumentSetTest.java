import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import tom_som_runtime.FormFieldSpec;
import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentFindings;
import tom_som_runtime.SpecDocumentSet;
import tom_som_runtime.SpecDocumentSetError;
import tom_som_runtime.SpecDocumentSetRefusal;
import tom_som_runtime.SpecLinkValidator;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecRenameChange;
import tom_som_runtime.SpecRenameError;
import tom_som_runtime.SpecSetCheck;
import tom_som_runtime.SpecSyncCode;
import tom_som_runtime.SpecSyncFinding;
import tom_som_runtime.SpecSyncHolder;
import tom_som_runtime.SpecSyncPair;
import tom_som_runtime.SpecSyncReport;
import tom_som_runtime.SpecSyncResolution;

/**
 * The document set ({@code SpecDocumentSet}, {@code tom_specs_model_rules.md}
 * §9.7): the set, {@code syncReport} and {@code renameId}.
 *
 * <p>The shared corpus ({@code document_set_cases.json}) pins the canonical JSON
 * of the construction, the report and the rename; this test holds the Java
 * surface it does not: the accessors of the set (by type name and by section
 * id, {@code get}, {@code put} replacing a document), the typed report
 * ({@code countsByCode}, {@code countsByResolution}, {@code isInfo}), the
 * refusals as exceptions with their fields, a refused rename changing nothing,
 * and the comparison helpers (typed sameness, ids, value keys). Mirrors the Go
 * runtime's spec_document_set_test.go. A plain {@code main()} that exits 0 on
 * success and 1 on failure.
 */
public final class SpecDocumentSetTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, Object got, Object want) {
    if (Objects.equals(got, want)) {
      passed++;
    } else {
      failed.add(name + ": got " + got + " want " + want);
    }
  }

  /** A case table of the corpus. */
  static Map<String, Object> table(String name) throws IOException {
    return Json.parseObject(
        new String(
            Files.readAllBytes(Paths.get("../tom_som_conformance/corpus/" + name)),
            StandardCharsets.UTF_8));
  }

  /** The table's model (the corpus file it names, else {@code links.meta.json}). */
  static SpecModel tableModel(Map<String, Object> table) throws IOException {
    Object name = table.get("model");
    return SpecModel.fromJson(table(name == null ? "links.meta.json" : (String) name));
  }

  /** The case of {@code group} whose name starts with {@code prefix}. */
  @SuppressWarnings("unchecked")
  static Map<String, Object> caseNamed(Map<String, Object> table, String group, String prefix) {
    for (Object raw : (List<Object>) table.get(group)) {
      Map<String, Object> c = (Map<String, Object>) raw;
      if (((String) c.get("name")).startsWith(prefix)) {
        return c;
      }
    }
    throw new IllegalStateException("no " + group + " case " + prefix);
  }

  @SuppressWarnings("unchecked")
  static SpecDocument stateDocument(Object state) {
    SpecDocument d = new SpecDocument();
    d.loadJson((Map<String, Object>) Json.parse(Json.write(state)));
    return d;
  }

  /** The documents of a case, {@code [[name, state], …]}. */
  @SuppressWarnings("unchecked")
  static List<Map.Entry<String, SpecDocument>> documents(Map<String, Object> c) {
    List<Map.Entry<String, SpecDocument>> out = new ArrayList<>();
    for (Object e : (List<Object>) c.get("documents")) {
      List<Object> pair = (List<Object>) e;
      out.add(Map.entry((String) pair.get(0), stateDocument(pair.get(1))));
    }
    return out;
  }

  /** {@code value} as parsed JSON (for comparing with an expectation). */
  static Object json(Object value) {
    return Json.parse(Json.write(value));
  }

  private static void accessors(Map<String, Object> table, SpecModel model) {
    List<Map.Entry<String, SpecDocument>> docs =
        documents(caseNamed(table, "construction", "the base set"));
    SpecDocumentSet s = new SpecDocumentSet(model, docs);
    eq("blueprintRoot", s.blueprintRoot, "Blueprint");
    eq("blueprint", s.blueprint() == docs.get(0).getValue(), true);
    eq("document.byType", s.document("Detail") == docs.get(1).getValue(), true);
    eq("document.bySectionId", s.document("DET") == docs.get(1).getValue(), true);
    eq("nameOf", s.nameOf("SCR"), "screens");
    eq("nameOf.unknown", s.nameOf("Nope"), null);
    eq("get", s.get("detail") == docs.get(1).getValue(), true);
    eq("get.unknown", s.get("nope"), null);
    eq("rootOf", s.rootOf("screens"), "Screens");
    List<String> ids = new ArrayList<>();
    for (SpecSyncPair p : s.pairs()) {
      ids.add(p.sectionId);
    }
    eq("pairs", ids, List.of("REQS", "ACC", "CRIT"));
    eq("pair.anchors",
        List.of(s.pairs().get(0).blueprintAnchor, s.pairs().get(0).detailAnchor),
        List.of("BLU/requirements", "DET/requirements"));
    eq("pair.sync", s.pairs().get(0).sync != null, true);
    // put replaces the document of the same name.
    SpecDocument other = new SpecDocument();
    other.loadJson(docs.get(1).getValue().toJson());
    s.put("detail", other);
    eq("put.replaces", s.get("detail") == other, true);
    eq("put.names", s.names(), List.of("blueprint", "detail", "screens"));
    // An empty set knows its pairs and every Phase 3 root as missing.
    SpecDocumentSet empty = new SpecDocumentSet(model);
    eq("empty.names", empty.names(), List.of());
    eq("empty.missing", empty.missingRoots(), List.of("Detail", "Screens"));
    eq("empty.pairs", empty.pairs().size(), 3);
  }

  @SuppressWarnings("unchecked")
  private static void refusals(Map<String, Object> table, SpecModel model) {
    Map<String, Object> same = caseNamed(table, "construction", "two documents of one root");
    try {
      new SpecDocumentSet(model, documents(same));
      eq("sameRoot.thrown", false, true);
    } catch (SpecDocumentSetError e) {
      eq("sameRoot.refusal", e.refusal, SpecDocumentSetRefusal.SAME_ROOT);
      eq("sameRoot.json", json(e.toJson()), ((Map<String, Object>) same.get("expect")).get("refused"));
      eq("sameRoot.string", e.toString().startsWith("SpecDocumentSetError(sameRoot): "), true);
    }
    Map<String, Object> unp = caseNamed(table, "construction", "a synced class whose positions");
    try {
      new SpecDocumentSet(SpecModel.fromJson((Map<String, Object>) unp.get("meta")), documents(unp));
      eq("unpairable.thrown", false, true);
    } catch (SpecDocumentSetError e) {
      eq("unpairable.refusal", e.refusal, SpecDocumentSetRefusal.UNPAIRABLE);
      eq("unpairable.className", e.className != null, true);
    }
    // put refuses an empty document.
    SpecDocumentSet s = new SpecDocumentSet(model);
    try {
      s.put("x", new SpecDocument());
      eq("put.noRoot.thrown", false, true);
    } catch (SpecDocumentSetError e) {
      eq("put.noRoot", e.refusal, SpecDocumentSetRefusal.NO_ROOT);
    }
  }

  private static void report(Map<String, Object> table, SpecModel model) {
    Map<String, Object> c = caseNamed(table, "reports", "an enum value differs");
    SpecSyncReport r = SpecDocumentSet.syncReport(new SpecDocumentSet(model, documents(c)));
    eq("clean", r.clean(), false);
    eq("countsByCode", r.countsByCode(), Map.of(SpecSyncCode.SHARED_VALUE_DIFFERS, 1));
    eq("countsByResolution", r.countsByResolution(), Map.of(SpecSyncResolution.BACKFILL, 1));
    SpecSyncFinding f = r.findings.get(0);
    eq("finding.pair", f.pair, "REQS");
    eq("finding.holder", f.holder, SpecSyncHolder.DETAIL);
    eq("finding.isInfo", f.isInfo(), false);
    eq("finding.values", List.of(f.blueprint.value, f.detail.value), List.of("approved", "done"));
    eq("finding.field", f.blueprint.field, "status");
    List<String> names = new ArrayList<>();
    for (SpecDocumentFindings d : r.documentFindings) {
      names.add(d.name);
    }
    eq("report.documents", names, List.of("blueprint", "detail", "screens"));
    eq("report.json", json(r.toJson()), c.get("expect"));
    // Scoped to another pair, the finding is left out.
    SpecSyncReport scoped =
        SpecDocumentSet.syncReport(new SpecDocumentSet(model, documents(c)), List.of("ACC"));
    eq("report.scoped", scoped.findings.size(), 0);
    SpecSyncReport pending =
        SpecDocumentSet.syncReport(
            new SpecDocumentSet(
                model, documents(caseNamed(table, "reports", "a value holding a pending change"))));
    eq("pending.clean", pending.clean(), true);
    boolean allInfo = !pending.findings.isEmpty();
    for (SpecSyncFinding x : pending.findings) {
      allInfo = allInfo && x.isInfo();
    }
    eq("pending.info", allInfo, true);
  }

  @SuppressWarnings("unchecked")
  private static void rename(Map<String, Object> table, SpecModel model) {
    Map<String, Object> ok = caseNamed(table, "renames", "an id renamed");
    SpecDocumentSet s = new SpecDocumentSet(model, documents(ok));
    String from = (String) ok.get("from");
    List<SpecRenameChange> changes = SpecDocumentSet.renameId(s, from, (String) ok.get("to"));
    SpecRenameChange first = changes.get(0);
    eq("rename.first", List.of(first.kind, first.oldValue, first.newValue),
        List.of(SpecRenameChange.SECTION_ID, from, ok.get("to")));
    eq("rename.again", SpecDocumentSet.renameId(s, from, "REQ-OTHER").size(), 0);

    Map<String, Object> refused = caseNamed(table, "renames", "a rename onto an id");
    s = new SpecDocumentSet(model, documents(refused));
    List<Object> before = new ArrayList<>();
    for (String n : s.names()) {
      before.add(json(s.get(n).toJson()));
    }
    try {
      SpecDocumentSet.renameId(s, (String) refused.get("from"), (String) refused.get("to"));
      eq("rename.refused.thrown", false, true);
    } catch (SpecRenameError e) {
      eq("rename.documents", json(e.documents), ((Map<String, Object>) refused.get("expect")).get("refused"));
      eq("rename.string", e.toString().startsWith("SpecRenameError: "), true);
    }
    List<Object> after = new ArrayList<>();
    for (String n : s.names()) {
      after.add(json(s.get(n).toJson()));
    }
    eq("rename.unchanged", after, before);
  }

  private static void helpers() {
    FormFieldSpec dbl = new FormFieldSpec("n", "n", "double", null, false);
    FormFieldSpec bool = new FormFieldSpec("b", "b", "bool", null, false);
    eq("sameTyped.double", SpecSetCheck.sameTyped("2", "2.0", dbl), true);
    eq("sameTyped.hex", SpecSetCheck.sameTyped("0x10", "16", dbl), true);
    eq("sameTyped.nan", SpecSetCheck.sameTyped("NaN", "NaN", dbl), false);
    eq("sameTyped.text", SpecSetCheck.sameTyped("2", "2.0", null), false);
    eq("sameTyped.bool", SpecSetCheck.sameTyped("True", "true", bool), true);
    eq("ids", SpecLinkValidator.linkIds(" A, ,B ,C"), List.of("A", "B", "C"));
    eq("stripKind.form", SpecSetCheck.stripKind("f:LIST[X]/content#status"), "LIST[X]/content");
    eq("stripKind.item", SpecSetCheck.stripKind("i:LIST[X]"), "LIST[X]");
    eq("reviewed", SpecSetCheck.reviewed(" a {++b ++}"), "a");
    eq("isPending", SpecSetCheck.isPending("a {++b++}"), true);
    eq("isPending.plain", SpecSetCheck.isPending("a b"), false);
    eq("codeIndex.first", SpecSyncCode.indexOf("sharedValueDiffers"), 0);
    eq("codeIndex.last", SpecSyncCode.indexOf("unmarkable"), 9);
    eq("codeIndex.unknown", SpecSyncCode.indexOf("nope"), -1);
  }

  public static void main(String[] args) throws IOException {
    Map<String, Object> table = table("document_set_cases.json");
    SpecModel model = tableModel(table);
    accessors(table, model);
    refusals(table, model);
    report(table, model);
    rename(table, model);
    helpers();
    if (failed.isEmpty()) {
      System.out.println("OK: " + passed + " checks passed");
      System.exit(0);
    }
    System.out.println("FAIL: " + failed.size() + "/" + (passed + failed.size()) + " checks failed");
    for (String f : failed) {
      System.out.println("  - " + f);
    }
    System.exit(1);
  }
}
