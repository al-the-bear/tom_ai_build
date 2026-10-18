import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecModel;

/**
 * {@link SpecDocument#hasValuesUnder} answers from a prefix index rather than a
 * scan of every stored key. The markdown emitter, the validator and the query
 * engine ask it once per model node, so a scan made rendering a large
 * specification quadratic.
 *
 * <p>VI-1 holds the index to the scan it replaces, across every mutator, so a
 * mutation that forgets to drop the index fails here. VI-2 guards the
 * complexity itself. Mirrors the Dart reference cases as a dependency-free
 * {@code main()} that exits 0 on success and 1 on failure.
 */
public final class SpecDocumentValueIndexTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  /**
   * The predicate the index must reproduce: a stored key equal to {@code query},
   * or continuing it after a {@code /} or a {@code -}.
   */
  @SuppressWarnings("unchecked")
  private static boolean scan(SpecDocument d, String query) {
    Map<String, Object> json = d.toJson();
    for (String store : new String[] {"content", "forms", "lists", "headlines", "codeSpecs"}) {
      Object m = json.get(store);
      if (!(m instanceof Map)) {
        continue;
      }
      for (Object key : ((Map<Object, Object>) m).keySet()) {
        String k = String.valueOf(key);
        if (k.equals(query) || k.startsWith(query + "/") || k.startsWith(query + "-")) {
          return true;
        }
      }
    }
    return false;
  }

  private static final String[] PROBES = {
    "DEMO",
    "DEMO/TTL",
    "DEMO/TT",
    "DEMO/SUM",
    "DEMO/DET",
    "DEMO/items",
    "DEMO/items-1",
    "DEMO/items-1/label",
    "DEMO/items-2",
    "DEMO/items-3",
    "DEMO/REF-LST",
    "DEMO/REF",
    "DEMO/CARD-LST-1",
    "DEMO/CARD",
    "DEMO/META/tags",
    "OTHER",
    "",
  };

  private static void expectAgrees(SpecDocument d, String when) {
    for (String p : PROBES) {
      boolean got = d.hasValuesUnder(p);
      boolean want = scan(d, p);
      check("VI-1 " + when + ": \"" + p + "\"", got == want, "index " + got + ", scan " + want);
    }
  }

  @SuppressWarnings("unchecked")
  private static Map<String, Object> readCorpus(String name) throws IOException {
    Path p = Path.of("..", "tom_som_conformance", "corpus", name);
    return (Map<String, Object>) Json.parse(Files.readString(p, StandardCharsets.UTF_8));
  }

  @SuppressWarnings("unchecked")
  private static void vi1() throws IOException {
    SpecDocument d = new SpecDocument();
    expectAgrees(d, "empty");
    d.setContent("DEMO/TTL", "Hello");
    expectAgrees(d, "setContent");
    d.setHeadline("DEMO/SUM", "Summary");
    expectAgrees(d, "setHeadline");
    d.setCodeSpec("DEMO/DET", "a.b");
    expectAgrees(d, "setCodeSpec");
    d.setFormField("DEMO/CARD-LST-1/content", "note", "x");
    expectAgrees(d, "setFormField");
    String item = d.addListItem("DEMO/items");
    d.setContent(item + "/label", "First");
    d.addListItem("DEMO/items");
    expectAgrees(d, "addListItem");
    d.setItemSectionId(item, "ITEM-A");
    expectAgrees(d, "setItemSectionId");
    d.setContent("DEMO/TTL", "");
    expectAgrees(d, "setContent to empty");
    d.setHeadline("DEMO/SUM", "");
    expectAgrees(d, "setHeadline to empty");
    d.setCodeSpec("DEMO/DET", "");
    expectAgrees(d, "setCodeSpec to empty");
    d.setFormField("DEMO/CARD-LST-1/content", "note", "");
    expectAgrees(d, "setFormField to empty");
    d.removeListItem(item);
    expectAgrees(d, "removeListItem");
    d.setContent("DEMO/SUM/X", "y");
    expectAgrees(d, "before removeValuesUnder");
    d.removeValuesUnder("DEMO/SUM");
    expectAgrees(d, "removeValuesUnder");

    Map<String, Object> lists = new LinkedHashMap<>();
    Map<String, Object> refList = new LinkedHashMap<>();
    refList.put("seq", 1);
    refList.put("items", List.of("DEMO/REF-LST-1"));
    lists.put("DEMO/REF-LST", refList);
    Map<String, Object> json = new LinkedHashMap<>();
    json.put("content", Map.of("DEMO/REF-LST-1", "spec"));
    json.put("lists", lists);
    d.loadJson(json);
    expectAgrees(d, "loadJson");

    // moveListItem over the corpus model and every successful move case. The
    // probes are every key (and bounded prefix) of the state before and the
    // document after, so a key the move renames away or into is covered.
    SpecModel model = SpecModel.fromJson(readCorpus("model.meta.json"));
    int moves = 0;
    for (Object o : (List<Object>) readCorpus("list_move_cases.json").get("cases")) {
      Map<String, Object> c = (Map<String, Object>) o;
      Map<String, Object> expect = (Map<String, Object>) c.get("expect");
      if (!Boolean.TRUE.equals(expect.get("ok"))) {
        continue;
      }
      moves++;
      List<String> keys = new ArrayList<>();
      collectKeys((Map<String, Object>) c.get("state"), keys);
      collectKeys((Map<String, Object>) expect.get("document"), keys);
      SpecDocument m = new SpecDocument();
      m.loadJson((Map<String, Object>) c.get("state"));
      String when = "moveListItem [" + c.get("name") + "]";
      for (String key : keys) {
        expectAgreesOn(m, key, "before " + when);
      }
      Map<String, Object> move = (Map<String, Object>) c.get("move");
      m.moveListItem(
          model,
          (String) move.get("itemPath"),
          ((Number) move.get("toIndex")).intValue(),
          (String) move.get("toList"));
      for (String key : keys) {
        expectAgreesOn(m, key, when);
      }
    }
    check("VI-1 move cases found", moves > 0, "");
  }

  @SuppressWarnings("unchecked")
  private static void collectKeys(Map<String, Object> json, List<String> out) {
    for (String store : new String[] {"content", "forms", "lists", "headlines", "codeSpecs"}) {
      Object m = json.get(store);
      if (m instanceof Map) {
        for (Object k : ((Map<Object, Object>) m).keySet()) {
          out.add(String.valueOf(k));
        }
      }
    }
  }

  /** Checks {@code key} and each of its {@code /}- and {@code -}-bounded prefixes. */
  private static void expectAgreesOn(SpecDocument d, String key, String when) {
    for (int i = 0; i <= key.length(); i++) {
      if (i == key.length() || key.charAt(i) == '/' || key.charAt(i) == '-') {
        String p = key.substring(0, i);
        boolean got = d.hasValuesUnder(p);
        boolean want = scan(d, p);
        check("VI-1 " + when + ": \"" + p + "\"", got == want, "index " + got + ", scan " + want);
        String q = p + "x";
        check("VI-1 " + when + ": \"" + q + "\"",
            d.hasValuesUnder(q) == scan(d, q), "index/scan disagree");
      }
    }
  }

  private static void vi2() {
    // 20,000 stored values and 20,000 queries. A per-query scan costs 4 * 10^8
    // key comparisons; the index answers in milliseconds. The bound is
    // generous, so only the complexity class can fail it.
    final int n = 20000;
    SpecDocument d = new SpecDocument();
    for (int i = 0; i < n; i++) {
      d.setContent("ROOT/S" + (i / 100) + "/F" + i, "v" + i);
    }
    long start = System.nanoTime();
    int hits = 0;
    for (int i = 0; i < n; i++) {
      if (d.hasValuesUnder("ROOT/S" + (i / 100) + "/F" + i)) {
        hits++;
      }
      if (d.hasValuesUnder("ROOT/S" + (i / 100) + "/G" + i)) {
        hits--;
      }
    }
    long ms = (System.nanoTime() - start) / 1_000_000;
    check("VI-2 hits", hits == n, hits + " != " + n);
    check("VI-2 under 2 s", ms < 2000, ms + " ms");
  }

  public static void main(String[] args) throws IOException {
    vi1();
    vi2();
    for (String f : failed) {
      System.out.println("FAIL " + f);
    }
    System.out.println(failed.isEmpty() ? "OK: " + passed + " checks passed" : passed + "/" + (passed + failed.size()) + " passed");
    System.exit(failed.isEmpty() ? 0 : 1);
  }
}
