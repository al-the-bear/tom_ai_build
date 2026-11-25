import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import tom_som_runtime.DocSpecsSchema;
import tom_som_runtime.DocSpecsViolation;
import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentMarkdown;
import tom_som_runtime.SpecMarkdownRejection;
import tom_som_runtime.SpecMarkdownResult;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecSchemaValidation;

/**
 * Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
 * accepting rejections keeps each rejected block as a {@code rejected} div in
 * the text of the section it stood in (else its parent), at its place. The
 * kept document re-exports and re-imports without a rejection and to the same
 * document, and the validator reports each div as {@code rejectedBlock}. A
 * port of
 * {@code tom_som_typescript_runtime/tests/spec_document_markdown_rejected_kept_test.ts};
 * the single cases are pinned in the conformance corpus
 * ({@code markdown_apply_cases.json}).
 *
 * <p>A plain {@code main()} that exits 0 on success and 1 on failure, run from
 * the project directory (the corpus is addressed as a sibling).
 */
public final class SpecDocumentMarkdownRejectedKeptTest {
  private static final String CORPUS = "../tom_som_conformance/corpus";

  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

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

  private static String read(String name) throws IOException {
    return new String(Files.readAllBytes(Paths.get(CORPUS, name)), StandardCharsets.UTF_8);
  }

  private static SpecModel model;
  private static String golden;
  private static final Map<String, String> variants = new LinkedHashMap<>();

  private static String sub(String from, String to) {
    int at = golden.indexOf(from);
    if (at < 0) {
      throw new IllegalStateException("the golden has no \"" + from + "\"");
    }
    return golden.substring(0, at) + to + golden.substring(at + from.length());
  }

  private static SpecMarkdownResult parse(String markdown) {
    return new SpecDocumentMarkdown(model, new SpecDocument()).parse(markdown);
  }

  private static SpecDocument kept(String markdown) {
    SpecDocument doc = new SpecDocument();
    doc.applyMarkdownResult(parse(markdown), true);
    return doc;
  }

  private static String or(String s) {
    return s == null ? "" : s;
  }

  private static void fillVariants() {
    variants.put("unknown section",
        golden + "\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n");
    variants.put("near-miss row", sub("| Owner | Bob |", "| Owner | Bob |\n| Ownr | Carol |"));
    variants.put("row given twice",
        sub("| Estimate | 8 |", "| Estimate | 8 |\n| Owner | Carol |"));
    variants.put("paragraph given twice", sub(
        "- backup: alice@example.com\n",
        "- backup: alice@example.com\nContact: carol@example.com\n- line\n"));
    variants.put("table without delimiter", sub(
        "| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |",
        "| TomSpecField | Value |\n| Owner | Bob |"));
    variants.put("records column", sub("| Id | Title | Note |", "| Id | Title | Nte |"));
    variants.put("records row", sub(
        "| <a id=\"CARD-2\"></a>CARD-2 |  | second card |",
        "| <a id=\"CARD-2\"></a>CARD-2 | second card |"));
    variants.put("unclosed records fence", sub("| second card |\n:::\n", "| second card |\n"));
    variants.put("section-table row", sub(
        "| <a id=\"DLV-1/DLR-1\"></a>DLR-LST / DLR-1 | Area | CE-NV |\n"
            + "|  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
        "| <a id=\"DLV-1/DLR-1\"></a>DLR-LS / DLR-1 | Area | CE-NV |\n"
            + "|  | Mapping | dart-tom |\n\n### <!--[DLV-2]"));
    variants.put("orphan text", "Stray text.\n\n" + golden);
    variants.put("child under a value leaf", sub(
        "high\n\n## <!--[CNT]-->",
        "high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->"));
    variants.put("nested unknown sections",
        golden + "\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n");
  }

  private static final Pattern REJECTED_DIV = Pattern.compile(
      "^:{3,} \\{\\.rejected reason=\"(\\w+)\" line=\"(\\d+)\"", Pattern.MULTILINE);

  @SuppressWarnings("unchecked")
  private static void testEveryVariant() {
    check("a clean parse keeps nothing", parse(golden).keptContent.isEmpty());
    DocSpecsSchema schema =
        DocSpecsSchema.fromYamlText("title-format: \"# <!--[DEMO]--> Demo\"\n");
    for (Map.Entry<String, String> variant : variants.entrySet()) {
      String name = variant.getKey();
      String markdown = variant.getValue();
      SpecMarkdownResult result = parse(markdown);
      check(name + ": rejected", !result.rejections.isEmpty());
      SpecDocument doc = kept(markdown);
      List<String> values = new ArrayList<>();
      for (Object v : ((Map<String, Object>) doc.toJson().get("content")).values()) {
        values.add(String.valueOf(v));
      }
      List<String> divs = new ArrayList<>();
      Matcher m = REJECTED_DIV.matcher(String.join("\n", values));
      while (m.find()) {
        divs.add(m.group(1) + "@" + m.group(2));
      }
      List<String> want = new ArrayList<>();
      for (SpecMarkdownRejection r : result.rejections) {
        want.add(r.reason.value + "@" + r.line);
      }
      check(name + ": every rejection kept", divs.equals(want), divs + " != " + want);

      String rendition = doc.toMarkdown(model, "Demo");
      SpecMarkdownResult again = parse(rendition);
      List<String> messages = new ArrayList<>();
      for (SpecMarkdownRejection r : again.rejections) {
        messages.add(r.message);
      }
      check(name + ": re-imports clean", again.rejections.isEmpty(),
          String.join("; ", messages));
      SpecDocument reloaded = new SpecDocument();
      reloaded.applyMarkdownResult(again, true);
      check(name + ": re-imports the same document",
          Json.write(reloaded.toJson()).equals(Json.write(doc.toJson())));

      int reported = 0;
      for (DocSpecsViolation v
          : SpecSchemaValidation.validateSpecDocument(model, doc, schema, "Demo")) {
        if (DocSpecsViolation.RULE_REJECTED_BLOCK.equals(v.rule)) {
          reported++;
        }
      }
      check(name + ": reported", reported == result.rejections.size(),
          reported + " != " + result.rejections.size());
    }
  }

  private static void testRefused() {
    SpecDocument doc = new SpecDocument();
    Map<String, Object> content = new LinkedHashMap<>();
    content.put("DEMO/TTL", "base");
    Map<String, Object> state = new LinkedHashMap<>();
    state.put("content", content);
    doc.loadJson(state);
    boolean threw = false;
    try {
      doc.applyMarkdownResult(parse(variants.get("unknown section")));
    } catch (IllegalStateException e) {
      threw = true;
    }
    check("a refused import throws", threw);
    check("a refused import never reads the kept blocks",
        content.equals(doc.toJson().get("content")),
        String.valueOf(doc.toJson().get("content")));
  }

  private static void testAttributes() {
    String row = or(kept(variants.get("near-miss row")).content("DEMO/DET"));
    check("near-miss row names the field",
        row.contains("reason=\"unknownField\" line=\"31\" field=\"owner\" "), row);
    String twice = or(kept(variants.get("row given twice")).content("DEMO/DET"));
    check("a field given twice names the kept form",
        twice.contains("field=\"owner\" kept=\"DEMO/DET\" "), twice);
    String cell =
        or(kept(variants.get("section-table row")).content("DEMO/DLV-LST-1/content"));
    check("a near-miss cell names the section",
        cell.contains("section=\"DLR-LST / DLR-1\" "), cell);
    check("the skipped continuation row is in the block",
        cell.contains("|  | Mapping | dart-tom |"));
  }

  private static void testParents() {
    SpecDocument doc = kept(variants.get("unclosed records fence"));
    check("the list container keeps no text", doc.content("DEMO/CARD-LST") == null,
        String.valueOf(doc.content("DEMO/CARD-LST")));
    String root = or(doc.content("DEMO"));
    check("the unclosed fence is escaped", root.contains("\n\\::: {.records}\n"), root);
    check("the div closes", root.stripTrailing().endsWith("\n:::"), root);
    String records = or(kept(variants.get("records column")).content("DEMO"));
    check("a records div is kept in the parent",
        records.startsWith(":::: {.rejected reason=\"unknownField\""), records);
    check("its own div stays inside", records.contains("\n::: {.records}\n"), records);
  }

  private static void testPlace() {
    SpecDocument doc = kept(variants.get("paragraph given twice"));
    check("the first value is kept",
        or(doc.formField("DEMO/DET", "contact")).startsWith("bob@example.com"));
    String want =
        "Captured during the November review.\n"
            + "Owner: this line is prose, not the field.\n\n"
            + "::: {.rejected reason=\"malformedBlock\" line=\"35\" field=\"contact\" "
            + "kept=\"DEMO/DET\" label=\"field 'contact' given twice\"}\n"
            + "Contact: carol@example.com\n- line\n:::";
    String got = or(doc.content("DEMO/DET"));
    check("a paragraph given twice is kept at its place", got.equals(want),
        "\n--- got\n" + got + "\n--- want\n" + want);
    String orphan = or(kept(variants.get("orphan text")).content("DEMO"));
    check("orphan text starts the root",
        orphan.startsWith("::: {.rejected reason=\"orphanContent\" line=\"1\""), orphan);
  }

  public static void main(String[] args) throws IOException {
    model = SpecModel.fromJson(Json.parseObject(read("model.meta.json")));
    golden = read("expected.tables.md");
    fillVariants();
    testEveryVariant();
    testRefused();
    testAttributes();
    testParents();
    testPlace();

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

  private SpecDocumentMarkdownRejectedKeptTest() {}
}
