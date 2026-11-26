import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.TreeSet;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDeriveChange;
import tom_som_runtime.SpecDeriveFields;
import tom_som_runtime.SpecDeriveOptions;
import tom_som_runtime.SpecDeriveResult;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecValidationCode;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;

/**
 * {@code deriveFields} ({@code SpecDeriveFields}, {@code tom_specs_model_rules.md}
 * §9.7): the derived places of one document, written plain or as marks.
 *
 * <p>The shared corpus ({@code derive_cases.json}) pins the canonical JSON of
 * each run; this test holds the Java surface it does not: the typed changes
 * ({@code SpecDeriveChange} with its step, kind, field and values), the dry run
 * answering a copy and leaving the given document alone, the unresolved entries
 * as {@code SpecValidationError} with their code, and the canonical JSON of a
 * change without a field. Mirrors the Go runtime's spec_derive_fields_test.go. A
 * plain {@code main()} that exits 0 on success and 1 on failure.
 */
public final class SpecDeriveFieldsTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, Object got, Object want) {
    if (Objects.equals(got, want)) {
      passed++;
    } else {
      failed.add(name + ": got " + got + " want " + want);
    }
  }

  private static Map<String, Object> table;

  private static SpecDocument doc(String prefix) {
    return SpecDocumentSetTest.stateDocument(
        SpecDocumentSetTest.caseNamed(table, "cases", prefix).get("state"));
  }

  private static void plainSteps(SpecModel model) {
    SpecDocument doc = doc("step 1: a missing symmetric row");
    SpecDeriveResult r = SpecDeriveFields.deriveFields(model, doc, SpecDeriveOptions.plain());
    eq("plain.same", r.document == doc, true);
    SpecDeriveChange first = r.changes.get(0);
    eq("plain.rowAdded", List.of(first.step, first.kind, String.valueOf(first.field)),
        List.of(1, SpecDeriveChange.ROW_ADDED, "null"));
    TreeSet<Integer> steps = new TreeSet<>();
    for (SpecDeriveChange c : r.changes) {
      steps.add(c.step);
    }
    eq("plain.steps", new ArrayList<>(steps), List.of(1, 2));
    SpecDeriveChange last = r.changes.get(r.changes.size() - 1);
    eq("plain.value", List.of(last.kind, last.field, last.oldValue, last.newValue),
        List.of(SpecDeriveChange.VALUE, "conflictsWith", "", "REQ-EXPORT"));
    eq("plain.unresolved", r.unresolved.size(), 0);
    eq("plain.clean", SpecValidator.validateLinks(model, doc).size(), 0);
    eq("plain.again",
        SpecDeriveFields.deriveFields(model, doc, SpecDeriveOptions.plain()).changes.size(), 0);
  }

  private static void dryRun(SpecModel model) {
    SpecDocument doc = doc("a dry run writes nothing");
    String before = Json.write(doc.toJson());
    SpecDeriveOptions options = SpecDeriveOptions.plain();
    options.dryRun = true;
    SpecDeriveResult r = SpecDeriveFields.deriveFields(model, doc, options);
    eq("dry.copy", r.document != doc, true);
    eq("dry.unchanged", Json.write(doc.toJson()), before);
    eq("dry.changes", !r.changes.isEmpty(), true);
    eq("dry.written", !Json.write(r.document.toJson()).equals(before), true);
  }

  private static void marked(SpecModel model) {
    SpecDocument doc = doc("under review: every derived value");
    String at = "2026-11-24T10:00+01:00";
    SpecDeriveOptions options = new SpecDeriveOptions();
    options.author = "agent_spec_author";
    options.at = at;
    SpecDeriveResult r = SpecDeriveFields.deriveFields(model, doc, options);
    int values = 0;
    for (SpecDeriveChange c : r.changes) {
      if (!c.kind.equals(SpecDeriveChange.VALUE)) {
        continue;
      }
      values++;
      eq("marked.marks[" + c.path + "]",
          c.newValue.contains("{") && c.newValue.contains("@agent_spec_author " + at), true);
    }
    eq("marked.values", values > 0, true);
    eq("marked.again", SpecDeriveFields.deriveFields(model, doc, options).changes.size(), 0);
  }

  @SuppressWarnings("unchecked")
  private static void unresolved(SpecModel model) {
    SpecDeriveResult miss =
        SpecDeriveFields.deriveFields(model, doc("a lookup without its row"), SpecDeriveOptions.plain());
    boolean found = false;
    for (SpecValidationError e : miss.unresolved) {
      found = found || e.code == SpecValidationCode.DERIVED_LOOKUP_MISS;
    }
    eq("lookupMiss", found, true);
    SpecDeriveOptions options = new SpecDeriveOptions();
    options.at = "2026-11-24T10:00+01:00";
    SpecDeriveResult fenced =
        SpecDeriveFields.deriveFields(model, doc("under review: a change inside fenced code"), options);
    List<SpecValidationCode> codes = new ArrayList<>();
    for (SpecValidationError e : fenced.unresolved) {
      codes.add(e.code);
    }
    eq("unmarkable", codes, List.of(SpecValidationCode.UNMARKABLE));
    List<Object> json = (List<Object>) fenced.toJson().get("unresolved");
    eq("unmarkable.json", ((Map<String, Object>) json.get(0)).get("code"), "unmarkable");
  }

  private static void changeJson() {
    eq("json.noField",
        SpecDocumentSetTest.json(new SpecDeriveChange(1, "rowRemoved", "A/b-1", null, "", "").toJson()),
        Json.parse("{\"step\":1,\"kind\":\"rowRemoved\",\"path\":\"A/b-1\",\"old\":\"\",\"new\":\"\"}"));
    eq("json.field",
        SpecDocumentSetTest.json(new SpecDeriveChange(3, "value", "A/c", "n", "1", "2").toJson()),
        Json.parse(
            "{\"step\":3,\"kind\":\"value\",\"path\":\"A/c\",\"field\":\"n\",\"old\":\"1\",\"new\":\"2\"}"));
  }

  public static void main(String[] args) throws IOException {
    table = SpecDocumentSetTest.table("derive_cases.json");
    SpecModel model = SpecDocumentSetTest.tableModel(table);
    plainSteps(model);
    dryRun(model);
    marked(model);
    unresolved(model);
    changeJson();
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
