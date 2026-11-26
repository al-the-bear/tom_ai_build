import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import tom_som_runtime.Json;
import tom_som_runtime.SpecBackfill;
import tom_som_runtime.SpecBackfillChange;
import tom_som_runtime.SpecBackfillError;
import tom_som_runtime.SpecBackfillLeft;
import tom_som_runtime.SpecBackfillOptions;
import tom_som_runtime.SpecBackfillResult;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentSet;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecPrefill;
import tom_som_runtime.SpecPrefillError;
import tom_som_runtime.SpecPrefillOptions;
import tom_som_runtime.SpecPrefillResult;
import tom_som_runtime.SpecSyncCode;

/**
 * {@code prefill} and {@code backfill} ({@code SpecPrefill},
 * {@code SpecBackfill}): the Blueprint into a new Phase 3 document (BP-8), and
 * the accepted Phase 3 end state back into the Blueprint (DP-part-operations-2).
 *
 * <p>The shared corpus ({@code prefill_cases.json}, {@code backfill_cases.json})
 * pins the canonical JSON of each run; this test holds the Java surface it does
 * not: the created document joining the set under its default name, the typed
 * results ({@code filledPairs}, {@code skippedPairs}, {@code derived},
 * {@code findings}; {@code changes}, {@code left}), the refusals as exceptions
 * with their codes and places, the revision entry's version bump and default
 * author, and the dry run leaving the set's Blueprint alone. Mirrors the Go
 * runtime's spec_prefill_backfill_test.go. A plain {@code main()} that exits 0
 * on success and 1 on failure.
 */
public final class SpecPrefillBackfillTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, Object got, Object want) {
    if (Objects.equals(got, want)) {
      passed++;
    } else {
      failed.add(name + ": got " + got + " want " + want);
    }
  }

  private static SpecDocumentSet caseSet(SpecModel model, Map<String, Object> table, String prefix) {
    return new SpecDocumentSet(
        model, SpecDocumentSetTest.documents(SpecDocumentSetTest.caseNamed(table, "cases", prefix)));
  }

  private static String formField(SpecDocument doc, String path, String field) {
    String v = doc.formField(path, field);
    return v == null ? "" : v;
  }

  private static void prefill(SpecModel model) throws IOException {
    Map<String, Object> table = SpecDocumentSetTest.table("prefill_cases.json");
    SpecDocumentSet s = caseSet(model, table, "a new Screens document");
    eq("prefill.missing", s.missingRoots(), List.of("Screens"));
    SpecPrefillResult r = SpecPrefill.prefill(s, "SCR");
    eq("prefill.name", r.name, "Screens");
    eq("prefill.created", r.created, true);
    eq("prefill.joined", s.get("Screens") == r.document, true);
    eq("prefill.filled", r.filledPairs, List.of("ACC"));
    eq("prefill.skipped", r.skippedPairs, List.of());
    eq("prefill.missingAfter", s.missingRoots(), List.of());
    SpecPrefillResult again = SpecPrefill.prefill(s, "Screens");
    eq("prefill.again.notCreated", again.created, false);
    eq("prefill.again.filled", again.filledPairs, List.of());
    eq("prefill.again.skipped", again.skippedPairs, List.of("ACC"));
    eq("prefill.again.derived", again.derived.changes.size(), 0);

    SpecDocumentSet named = caseSet(model, table, "a new Detail document");
    SpecPrefillOptions options = new SpecPrefillOptions();
    options.name = "detail.tomspecs.yaml";
    r = SpecPrefill.prefill(named, "Detail", options);
    eq("prefill.named", named.names(), List.of("blueprint", "detail.tomspecs.yaml", "screens"));
    eq("prefill.derived", !r.derived.changes.isEmpty(), true);
    for (SpecSyncCode code : SpecDocumentSet.syncReport(named).countsByCode().keySet()) {
      eq("prefill.agrees[" + code.value + "]", code.value.startsWith("shared"), false);
    }

    String[][] refusals = {
      {"a set without the Blueprint", "DET", SpecPrefillError.NO_BLUEPRINT},
      {"the Blueprint's own root", "BLU", SpecPrefillError.UNKNOWN_ROOT},
      {"the Blueprint's own root", "Nope", SpecPrefillError.UNKNOWN_ROOT},
    };
    for (String[] x : refusals) {
      try {
        SpecPrefill.prefill(caseSet(model, table, x[0]), x[1]);
        eq("prefill." + x[2] + "[" + x[1] + "].thrown", false, true);
      } catch (SpecPrefillError e) {
        eq("prefill." + x[2] + "[" + x[1] + "]", e.code, x[2]);
        eq("prefill.string[" + x[1] + "]", e.toString().startsWith("SpecPrefillError(" + x[2] + "): "), true);
      }
    }
  }

  private static void backfill(SpecModel model) throws IOException {
    Map<String, Object> table = SpecDocumentSetTest.table("backfill_cases.json");

    SpecDocumentSet s = caseSet(model, table, "a differing enum value");
    SpecBackfillOptions options = new SpecBackfillOptions();
    options.author = "agent_spec_author";
    options.date = "2026-11-24";
    SpecBackfillResult r = SpecBackfill.backfill(s, options);
    eq("backfill.same", r.blueprint == s.blueprint(), true);
    List<String> kinds = new ArrayList<>();
    for (SpecBackfillChange c : r.changes) {
      kinds.add(c.kind);
    }
    eq("backfill.kinds", kinds, List.of(SpecBackfillChange.VALUE, SpecBackfillChange.REVISION));
    SpecBackfillChange value = r.changes.get(0);
    eq("backfill.value", List.of(value.pair, value.oldValue, value.newValue),
        List.of("REQS", "approved", "done"));
    String rev = r.changes.get(1).path;
    eq("backfill.revision.version", r.changes.get(1).newValue, "1.1");
    SpecDocument bp = s.blueprint();
    eq("backfill.revision.author", formField(bp, rev + "/content", "author"), "agent_spec_author");
    eq("backfill.revision.summary", formField(bp, rev + "/content", "summary"),
        "Backfilled from detail, screens: REQS");
    eq("backfill.clean", SpecDocumentSet.syncReport(s).clean(), true);
    eq("backfill.again", SpecBackfill.backfill(s).changes.size(), 0);

    // Default author and date.
    SpecDocumentSet d = caseSet(model, table, "a value the Blueprint leaves empty");
    r = SpecBackfill.backfill(d);
    rev = "";
    for (SpecBackfillChange c : r.changes) {
      if (c.kind.equals(SpecBackfillChange.REVISION)) {
        rev = c.path;
      }
    }
    eq("backfill.default.author", formField(d.blueprint(), rev + "/content", "author"), "backfill");
    eq("backfill.default.date", formField(d.blueprint(), rev + "/content", "date"),
        LocalDate.now().toString());

    SpecDocumentSet dry = caseSet(model, table, "a dry run writes a copy");
    String before = Json.write(dry.blueprint().toJson());
    SpecBackfillOptions dryOptions = new SpecBackfillOptions();
    dryOptions.dryRun = true;
    r = SpecBackfill.backfill(dry, dryOptions);
    eq("backfill.dry.copy", r.blueprint != dry.blueprint(), true);
    eq("backfill.dry.unchanged", Json.write(dry.blueprint().toJson()), before);
    eq("backfill.dry.changes", !r.changes.isEmpty(), true);

    SpecBackfillResult held = SpecBackfill.backfill(caseSet(model, table, "a heldHere value"));
    eq("backfill.held.changes", held.changes.size(), 0);
    List<String> reasons = new ArrayList<>();
    for (SpecBackfillLeft l : held.left) {
      reasons.add(l.reason);
    }
    eq("backfill.held.reason", reasons, List.of(SpecBackfillLeft.HELD_HERE));
    eq("backfill.held.code", held.left.get(0).finding.code, SpecSyncCode.SHARED_VALUE_DIFFERS);

    try {
      SpecBackfill.backfill(caseSet(model, table, "a set holding an inline mark"));
      eq("backfill.marks.thrown", false, true);
    } catch (SpecBackfillError e) {
      eq("backfill.marks", e.code, SpecBackfillError.SET_HAS_MARKS);
      eq("backfill.marks.places", !e.places.isEmpty() && e.places.get(0).document != null, true);
      eq("backfill.marks.string", e.toString().startsWith("SpecBackfillError(setHasMarks): "), true);
    }
    try {
      SpecBackfill.backfill(new SpecDocumentSet(model));
      eq("backfill.noBlueprint.thrown", false, true);
    } catch (SpecBackfillError e) {
      eq("backfill.noBlueprint", e.code, SpecBackfillError.NO_BLUEPRINT);
    }
  }

  private static void bumpAndJson() {
    eq("bump.empty", SpecBackfill.bump(""), "1");
    eq("bump.minor", SpecBackfill.bump("1.2"), "1.3");
    eq("bump.carry", SpecBackfill.bump("v1.9-rc"), "v1.10-rc");
    eq("bump.none", SpecBackfill.bump("draft"), "draft.1");
    eq("change.json",
        SpecDocumentSetTest.json(
            new SpecBackfillChange("", SpecBackfillChange.REVISION, "B/R-1", null, "", "2").toJson()),
        Json.parse("{\"pair\":\"\",\"kind\":\"revision\",\"path\":\"B/R-1\",\"old\":\"\",\"new\":\"2\"}"));
  }

  public static void main(String[] args) throws IOException {
    SpecModel model = SpecDocumentSetTest.tableModel(SpecDocumentSetTest.table("prefill_cases.json"));
    prefill(model);
    backfill(model);
    bumpAndJson();
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
