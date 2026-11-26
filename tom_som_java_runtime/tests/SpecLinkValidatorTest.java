import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDerivedNumber;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecLinkFix;
import tom_som_runtime.SpecLinkValidator;
import tom_som_runtime.SpecMarkEntry;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecReviewAnnotationError;
import tom_som_runtime.SpecReviewAnnotations;
import tom_som_runtime.SpecTypedValues;
import tom_som_runtime.SpecValidationCode;
import tom_som_runtime.SpecValidationError;
import tom_som_runtime.SpecValidator;

/**
 * The link checks of one document ({@code SpecLinkValidator},
 * {@code tom_specs_model_rules.md} §9.7), the derived numbers of the instance
 * tier ({@code SpecValidator.derivedNumbers}) and the typed reading of a value
 * under review ({@code SpecTypedValues.somTypedReading}, the headline field of
 * the review operations).
 *
 * <p>The shared corpus ({@code link_validation_cases.json}) pins the findings as
 * {@code {path, code}}; this test holds what it does not: the fixes
 * {@code deriveFields} reads beside each finding (with the order an
 * {@code addRow} writes its values in), the finding order and messages, reading
 * the proposal, the derived numbers, and a headline refusing a comment block.
 * Mirrors the Go runtime's spec_links_validator_test.go. A plain {@code main()}
 * that exits 0 on success and 1 on failure.
 */
public final class SpecLinkValidatorTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean ok, String detail) {
    if (ok) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static List<Object> cases;

  /** The state of the link-validation case whose name starts with {@code prefix}. */
  @SuppressWarnings("unchecked")
  private static SpecDocument caseDoc(String prefix) {
    for (Object raw : cases) {
      Map<String, Object> c = (Map<String, Object>) raw;
      if (((String) c.get("name")).startsWith(prefix)) {
        SpecDocument d = new SpecDocument();
        d.loadJson(Json.parseObject(Json.write(c.get("state"))));
        return d;
      }
    }
    throw new IllegalStateException("no link-validation case " + prefix);
  }

  private static List<SpecLinkFix> fixes(SpecModel model, SpecDocument d, boolean proposed) {
    return new SpecLinkValidator(model, d, proposed).run().fixes;
  }

  private static void linkFixes(SpecModel model) {
    String req1 = "BLU/requirements/REQ-ITEM-LST-1";

    // A derived value not written yet: no finding, but deriveFields writes it.
    SpecDocument d = caseDoc("a derived value not written yet");
    check("fixes.notYet.errors", SpecValidator.validateLinks(model, d).isEmpty(), "");
    List<SpecLinkFix> want =
        List.of(
            SpecLinkFix.ofSet(
                2,
                req1 + "/REQAB",
                null,
                "Exports use the formats of REQ-IMPORT and never run with REQ-PURGE."));
    List<SpecLinkFix> got = fixes(model, d, false);
    check("fixes.notYet", got.equals(want), got.toString());

    // A one-way link not named back: the other end gets the id appended.
    want =
        List.of(
            SpecLinkFix.ofAppend(
                "BLU/acceptance/criteria/CRIT-ITEM-LST-1/content",
                "relatedRequirements",
                "REQ-EXPORT"));
    got = fixes(model, caseDoc("a one-way link not named back"), false);
    check("fixes.inverse", got.equals(want), got.toString());

    // A symmetric row without its counterpart: a row is added there, its values
    // in the order they are written.
    Map<String, String> values = new LinkedHashMap<>();
    values.put("LNK-REF#ref", "REQ-EXPORT");
    values.put("content#linkType", "conflict");
    want = List.of(SpecLinkFix.ofAddRow(1, "BLU/requirements/REQ-ITEM-LST-3/LNK-ITEM-LST", values));
    got = fixes(model, caseDoc("a symmetric row without its counterpart"), false);
    check("fixes.symmetric", got.equals(want), got.toString());
    check(
        "fixes.symmetric.order",
        got.size() == 1
            && got.get(0).orderedValueKeys().equals(List.of("LNK-REF#ref", "content#linkType")),
        "");

    // A generated row the text no longer names: removed.
    want = List.of(SpecLinkFix.ofRemoveRow(req1 + "/LNK-ITEM-LST-1", false));
    got = fixes(model, caseDoc("a generated row the text no longer names"), false);
    check("fixes.stale", got.equals(want), got.toString());

    // A copy edited apart from its holder: copied back whole.
    got = fixes(model, caseDoc("a copy edited apart from its holder"), false);
    check(
        "fixes.sameAs",
        got.size() == 1
            && got.get(0).kind.equals(SpecLinkFix.COPY)
            && got.get(0).path.equals("BLU/criteriaSummary/criteria"),
        got.toString());
  }

  private static void findings(SpecModel model) {
    List<SpecValidationError> errs =
        SpecValidator.validateLinks(model, caseDoc("a copy differing from its source"));
    check(
        "findings.copy",
        errs.size() == 1 && errs.get(0).code == SpecValidationCode.DERIVED_VALUE_MISMATCH,
        errs.toString());
    check(
        "findings.copyMessage",
        !errs.isEmpty() && errs.get(0).message.contains("is derived (copy of"),
        errs.toString());
    // Sorted by path, then by code in declaration order.
    errs = SpecValidator.validateLinks(model, caseDoc("an id named in a generate-mode text"));
    boolean sorted = true;
    for (int i = 1; i < errs.size(); i++) {
      SpecValidationError a = errs.get(i - 1);
      SpecValidationError b = errs.get(i);
      int c = a.path.compareTo(b.path);
      if (c > 0 || (c == 0 && a.code.ordinal() > b.code.ordinal())) {
        sorted = false;
      }
    }
    check("findings.sorted", sorted, errs.toString());
    // A value holding a pending change is read with the mark rejected and listed
    // once; reading the proposal lists nothing.
    SpecDocument d = caseDoc("a source holding a pending change");
    int pending = 0;
    for (SpecValidationError e : SpecValidator.validateLinks(model, d)) {
      if (e.code == SpecValidationCode.LINK_VALUE_PENDING) {
        pending++;
      }
    }
    check("findings.pending", pending == 1, String.valueOf(pending));
    boolean proposalPending = false;
    for (SpecValidationError e : new SpecLinkValidator(model, d, true).run().errors) {
      if (e.code == SpecValidationCode.LINK_VALUE_PENDING) {
        proposalPending = true;
      }
    }
    check("findings.proposal", !proposalPending, "");
  }

  private static void expandAndIds() {
    SpecDocument d = caseDoc("a clean Blueprint");
    check(
        "expand",
        SpecLinkValidator.expandPattern(d, "BLU/requirements/REQ-ITEM-LST-*/REQD")
            .equals(
                List.of(
                    "BLU/requirements/REQ-ITEM-LST-1/REQD",
                    "BLU/requirements/REQ-ITEM-LST-2/REQD",
                    "BLU/requirements/REQ-ITEM-LST-3/REQD")),
        "");
    check(
        "expand.plain",
        SpecLinkValidator.expandPattern(d, "BLU/requirements").equals(List.of("BLU/requirements")),
        "");
    check("ids", SpecLinkValidator.linkIds(" A, ,B ,").equals(List.of("A", "B")), "");
    SpecValidationCode[] all = SpecValidationCode.values();
    check(
        "codes.unmarkableLast",
        all[all.length - 1] == SpecValidationCode.UNMARKABLE,
        "");
    check(
        "fix.toJson",
        Json.parseObject(Json.write(SpecLinkFix.ofSet(2, "P", null, "v").toJson()))
            .equals(
                Json.parseObject(
                    "{\"step\":2,\"kind\":\"set\",\"path\":\"P\",\"field\":null,\"value\":\"v\"}")),
        "");
  }

  private static void derivedNumbers(SpecModel model) {
    String base = "BLU/requirements";
    SpecDocument d = new SpecDocument();
    for (String status : List.of("approved", "done", "draft")) {
      String item = d.addListItem(base + "/REQ-ITEM-LST");
      d.setFormField(item + "/content", "status", status);
    }
    d.setFormField(base + "/REQS-SUM", "total", "1");
    Map<String, String> got = numbers(model, d, false);
    check(
        "numbers.counts",
        "3".equals(got.get(base + "/REQS-SUM#total"))
            && "2".equals(got.get(base + "/REQS-SUM#settled")),
        got.toString());
    // A count reading a pending mark: rejected by default, accepted when reading
    // the proposal.
    d.setFormField(base + "/REQ-ITEM-LST-3/content", "status", "{~~draft~>done~~}");
    check(
        "numbers.rejected",
        "2".equals(numbers(model, d, false).get(base + "/REQS-SUM#settled")),
        "");
    check(
        "numbers.proposed",
        "3".equals(numbers(model, d, true).get(base + "/REQS-SUM#settled")),
        "");
  }

  private static Map<String, String> numbers(SpecModel model, SpecDocument d, boolean proposed) {
    Map<String, String> out = new HashMap<>();
    for (SpecDerivedNumber n : SpecValidator.derivedNumbers(model, d, proposed)) {
      out.put(n.path + "#" + n.field, n.value);
    }
    return out;
  }

  private static void typedReading() {
    check("typed.plain", "30".equals(SpecTypedValues.somTypedReading("30")), "");
    check("typed.none", "".equals(SpecTypedValues.somTypedReading("")), "");
    check("typed.null", SpecTypedValues.somTypedReading(null) == null, "");
    check("typed.change", "30".equals(SpecTypedValues.somTypedReading("{~~ 30 ~> 15 ~~}")), "");
    check("typed.insertion", "".equals(SpecTypedValues.somTypedReading("{++15++}")), "");
    check(
        "typed.int",
        Integer.valueOf(30).equals(SpecTypedValues.somParseInt("{~~30~>15~~}")),
        "");
    check(
        "typed.bool",
        Boolean.TRUE.equals(SpecTypedValues.somParseBool("{~~true~>false~~}")),
        "");
    check(
        "typed.enum",
        "high".equals(SpecTypedValues.somParseEnumName("{~~high~>low~~}", List.of("low", "high"))),
        "");
    check(
        "typed.readable",
        SpecTypedValues.somTypedTextReadable("int", "{~~30~>lots~~}"),
        "a marked int is read by its new value");
    check(
        "typed.isTyped",
        SpecTypedValues.somIsTypedField("String", List.of("a"))
            && SpecTypedValues.somIsTypedField("int?", null)
            && !SpecTypedValues.somIsTypedField("String", null),
        "");
  }

  private static void headlineField() {
    SpecDocument d = new SpecDocument();
    d.setHeadline("BLU/requirements", "Requirements {++and links++}");
    SpecReviewAnnotations api =
        new SpecReviewAnnotations(d, null, () -> "2026-11-07T14:05+01:00");
    List<SpecMarkEntry> marks = api.listMarks(null);
    check(
        "headline.marks",
        marks.size() == 1
            && marks.get(0).path.equals("BLU/requirements")
            && SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD.equals(marks.get(0).field),
        String.valueOf(marks.size()));
    boolean refused = false;
    try {
      api.insertComment(
          "BLU/requirements", SpecReviewAnnotations.K_SPEC_HEADLINE_FIELD, 0, "x", null, null);
    } catch (SpecReviewAnnotationError e) {
      refused = true;
    }
    check("headline.noComment", refused, "a headline takes a comment block");
    api.acceptAllMarks(null);
    check(
        "headline.accepted",
        "Requirements and links".equals(d.headline("BLU/requirements")),
        String.valueOf(d.headline("BLU/requirements")));
  }

  @SuppressWarnings("unchecked")
  public static void main(String[] args) throws IOException {
    SpecModel model = SpecPlaceTest.linksModel();
    String text =
        new String(
            Files.readAllBytes(
                Paths.get("../tom_som_conformance/corpus/link_validation_cases.json")),
            StandardCharsets.UTF_8);
    cases = (List<Object>) Json.parseObject(text).get("cases");
    linkFixes(model);
    findings(model);
    expandAndIds();
    derivedNumbers(model);
    typedReading();
    headlineField();
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
