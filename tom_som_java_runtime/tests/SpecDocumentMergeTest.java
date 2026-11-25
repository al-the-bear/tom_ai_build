import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import tom_som_runtime.Json;
import tom_som_runtime.SpecDocumentStrip;
import tom_som_runtime.SpecStripMerge;
import tom_som_runtime.SpecStripOptions;
import tom_som_runtime.SpecStripTextResult;
import tom_som_runtime.SpecStripValueMerge;
import tom_som_runtime.SpecStripValueRef;

/**
 * The merge back (SOM §11.10): properties over the strip corpus, the report
 * lines of a conflict, text beyond ASCII and the base read from git — what
 * {@code strip_merge_cases.json} (run by {@code ConformanceRunner}) does not
 * reach. The Java port of {@code
 * tom_som_typescript_runtime/tests/spec_document_merge_test.ts}, with the
 * non-ASCII cases of {@code tom_som_cpp_runtime/tests/spec_document_merge_test.cpp},
 * whose expectations were computed with the TypeScript runtime (offsets and
 * excerpts in UTF-16 code units).
 *
 * <p>A plain {@code main()} that exits 0 on success and 1 on failure. The git
 * checks build their own scratch repository in the system temp directory and
 * are skipped when no {@code git} can be run.
 */
public final class SpecDocumentMergeTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail == null || detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void check(String name, boolean condition) {
    check(name, condition, "");
  }

  private static final String SIBLINGS = "..";

  @SuppressWarnings("unchecked")
  private static List<String> names(Map<String, Object> c, String key) {
    return c.get(key) == null ? null : (List<String>) c.get(key);
  }

  private static SpecStripOptions options(Map<String, Object> c) {
    return SpecStripOptions.fromNames(
        names(c, "drop"),
        names(c, "unmark"),
        names(c, "appendix"),
        Boolean.TRUE.equals(c.get("appendixReferences")),
        Boolean.TRUE.equals(c.get("headingDivs")));
  }

  /** Every value case of the strip corpus merges back unchanged, and with a paragraph added. */
  @SuppressWarnings("unchecked")
  private static void testOverStripCases() throws IOException {
    String text =
        new String(
            Files.readAllBytes(
                Paths.get(SIBLINGS + "/tom_som_conformance/corpus/strip_cases.json")),
            StandardCharsets.UTF_8);
    Map<String, Object> table = (Map<String, Object>) Json.parse(text);
    List<Object> cases = (List<Object>) table.get("cases");
    check("strip cases read", !cases.isEmpty());
    for (Object caseObj : cases) {
      Map<String, Object> c = (Map<String, Object>) caseObj;
      String o = (String) c.get("text");
      SpecStripOptions opts = options(c);
      SpecStripTextResult s = SpecDocumentStrip.stripNotationText(o, opts);
      if (s.refused()) {
        continue;
      }
      SpecStripValueMerge same = SpecStripMerge.mergeStrippedValue(o, s.text, s.text, s.pieces);
      check(
          "unchanged[" + c.get("name") + "]",
          o.equals(same.text) && same.restored == s.pieces.size() && same.placed.isEmpty());
      String e = s.text.isEmpty() ? "An added paragraph." : s.text + "\n\nAn added paragraph.";
      SpecStripValueMerge r = SpecStripMerge.mergeStrippedValue(o, s.text, e, s.pieces);
      check(
          "addedParagraph[" + c.get("name") + "]",
          r.ok() && SpecDocumentStrip.stripNotationText(r.text, opts).text.equals(e),
          Json.write(r.toJson()));
    }
  }

  private static void testValues() {
    SpecStripOptions trace = SpecStripOptions.fromNames(Arrays.asList("trace"), null, null, false, false);
    String o = "Keep this. Gone here (-> C1). Tail.";
    SpecStripTextResult s = SpecDocumentStrip.stripNotationText(o, trace);
    SpecStripValueMerge r = SpecStripMerge.mergeStrippedValue(o, s.text, "Keep this. Tail.", s.pieces);
    check("conflict.ok", !r.ok() && r.text == null);
    check(
        "conflict.code",
        r.conflicts.size() == 1 && r.conflicts.get(0).code.equals("sentenceRemoved"));
    if (!r.conflicts.isEmpty()) {
      List<String> lines = r.conflicts.get(0).about(new SpecStripValueRef("DEMO/SUM")).reportLines();
      List<String> want =
          Arrays.asList(
              "CONFLICT DEMO/SUM \u2014 the edit removed the whole sentence holding the piece",
              "  O: \u00abKeep this. Gone here (-> C1). Tail.\u00bb",
              "  B: \u00abKeep this. Gone here. Tail.\u00bb",
              "  E: \u00abKeep this. Tail.\u00bb",
              "  piece: \u00ab (-> C1)\u00bb");
      check("conflict.reportLines", lines.equals(want), lines.toString());
    }

    String o2 = "Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2).";
    SpecStripOptions opts =
        SpecStripOptions.fromNames(Arrays.asList("trace", "aside"), null, null, false, false);
    SpecStripTextResult s2 = SpecDocumentStrip.stripNotationText(o2, opts);
    String e2 = s2.text.replace("Alpha", "First");
    SpecStripValueMerge r2 = SpecStripMerge.mergeStrippedValue(o2, s2.text, e2, s2.pieces);
    check(
        "several pieces",
        "First (-> A1). Beta [aside]{.aside} gamma (-> B2).".equals(r2.text)
            && r2.restored == 3
            && SpecDocumentStrip.stripNotationText(r2.text, opts).text.equals(e2),
        Json.write(r2.toJson()));
  }

  /** A value beyond ASCII, one edit, and what the merge gives. */
  private static final class Case {
    final String original;
    final String list; // "drop" or "unmark"
    final String names;
    final String find;
    final String replace;
    final String text; // null: conflicts
    final int restored;
    final int placedAt; // -1: nothing placed
    final String placedRemoved;
    final String conflict; // the one conflict's code, null: none
    final String[] lines; // the conflict's report lines

    Case(
        String original,
        String list,
        String names,
        String find,
        String replace,
        String text,
        int restored,
        int placedAt,
        String placedRemoved,
        String conflict,
        String[] lines) {
      this.original = original;
      this.list = list;
      this.names = names;
      this.find = find;
      this.replace = replace;
      this.text = text;
      this.restored = restored;
      this.placedAt = placedAt;
      this.placedRemoved = placedRemoved;
      this.conflict = conflict;
      this.lines = lines;
    }
  }

  private static final Case[] NON_ASCII = {
    new Case(
        "Die Gr\u00f6\u00dfe ist hoch (-> C2.1).",
        "drop", "trace", "hoch",
        "stark gestiegen \ud83d\ude00",
        "Die Gr\u00f6\u00dfe ist stark gestiegen \ud83d\ude00 (-> C2.1).",
        1, 32, " (-> C2.1)", null,
        new String[] {}),
    new Case(
        "Ein \ud83d\ude00 [schnelles braunes]{.aside} Tier l\u00e4uft.",
        "unmark", "aside", "braunes Tier",
        "Wesen",
        null,
        0, -1, null, "crossesBoundary",
        new String[] {
            "CONFLICT (document) \u2014 an edit crosses the boundary of an unmarked element",
            "  O: \u00abEin \ud83d\ude00 [schnelles braunes]{.aside} Tier l\u00e4uft.\u00bb",
            "  B: \u00abEin \ud83d\ude00 schnelles braunes Tier l\u00e4uft.\u00bb",
            "  E: \u00abEin \ud83d\ude00 schnelles Wesen l\u00e4uft.\u00bb",
            "  piece: \u00ab]{.aside}\u00bb"}),
    new Case(
        "\u00c4 Wort{>>Bemerkung \u00fcber \u00d6l<<} hier.",
        "drop", "comments", "Wort",
        "Begriff",
        "\u00c4 Begriff{>>Bemerkung \u00fcber \u00d6l<<} hier.",
        2, -1, null, null,
        new String[] {}),
    new Case(
        "Gr\u00f6\u00dfe [weil \ud83d\ude00 so]{.aside} gilt.\n\nZweiter Absatz.",
        "drop", "aside", "gilt",
        "bleibt",
        "Gr\u00f6\u00dfe [weil \ud83d\ude00 so]{.aside} bleibt.\n\nZweiter Absatz.",
        1, -1, null, null,
        new String[] {}),
    new Case(
        "Ein \u00e4\u00f6\u00fc\u00e4\u00f6\u00fc\u00e4\u00f6\u00fc\u00e4\u00f6\u00fc\u00e4\u00f6\u00fc\u00e4\u00f6\u00fc langer Satz mit [schnelles braunes]{.aside} Tier und noch viel mehr Text danach \u00e4\u00f6\u00fc.",
        "unmark", "aside", "braunes Tier",
        "Wesen",
        null,
        0, -1, null, "crossesBoundary",
        new String[] {
            "CONFLICT (document) \u2014 an edit crosses the boundary of an unmarked element",
            "  O: \u00aber Satz mit [schnelles braunes]{.aside} Tier und noch viel m\u00bb",
            "  B: \u00abger Satz mit schnelles braunes Tier und noch viel mehr Text \u00bb",
            "  E: \u00ab\u00e4\u00f6\u00fc langer Satz mit schnelles Wesen und noch viel mehr Text \u00bb",
            "  piece: \u00ab]{.aside}\u00bb"}),
  };

  private static void testNonAscii() {
    for (int i = 0; i < NON_ASCII.length; i++) {
      Case c = NON_ASCII[i];
      String tag = "nonAscii " + i + ": ";
      boolean drop = c.list.equals("drop");
      List<String> names = Collections.singletonList(c.names);
      SpecStripOptions o =
          SpecStripOptions.fromNames(drop ? names : null, drop ? null : names, null, false, false);
      SpecStripTextResult st = SpecDocumentStrip.stripNotationText(c.original, o);
      int at = st.text.indexOf(c.find);
      check(tag + "the edit applies", at >= 0);
      if (at < 0) {
        continue;
      }
      String edited = st.text.substring(0, at) + c.replace + st.text.substring(at + c.find.length());
      SpecStripValueMerge m = SpecStripMerge.mergeStrippedValue(c.original, st.text, edited, st.pieces);
      check(tag + "text", c.text == null ? m.text == null : c.text.equals(m.text), m.text);
      check(tag + "restored", m.restored == c.restored, String.valueOf(m.restored));
      if (c.placedAt < 0) {
        check(tag + "placed", m.placed.isEmpty());
      } else {
        check(
            tag + "placed",
            m.placed.size() == 1
                && m.placed.get(0).at == c.placedAt
                && m.placed.get(0).piece.removed.equals(c.placedRemoved),
            m.placed.isEmpty() ? "none" : String.valueOf(m.placed.get(0).at));
      }
      if (c.conflict == null) {
        check(tag + "conflicts", m.conflicts.isEmpty());
      } else {
        check(
            tag + "conflicts",
            m.conflicts.size() == 1 && m.conflicts.get(0).code.equals(c.conflict));
        if (m.conflicts.size() == 1) {
          List<String> lines = m.conflicts.get(0).reportLines();
          check(tag + "report lines", lines.equals(Arrays.asList(c.lines)), lines.toString());
        }
      }
    }
  }

  private static void testLabels() {
    check("label", SpecStripMerge.specStripMergeLabel(new SpecStripValueRef("A/B")).equals("A/B"));
    check(
        "label.field",
        SpecStripMerge.specStripMergeLabel(new SpecStripValueRef("A/B", "f")).equals("A/B / f"));
    check(
        "label.headline",
        SpecStripMerge.specStripMergeLabel(new SpecStripValueRef("A/B", null, true))
            .equals("A/B (headline)"));
  }

  /** Runs git in {@code folder}; false when it fails or cannot be run. */
  private static boolean git(File folder, String... args) {
    List<String> command = new ArrayList<>(Arrays.asList("git"));
    command.addAll(Arrays.asList(args));
    try {
      Process p =
          new ProcessBuilder(command)
              .directory(folder)
              .redirectErrorStream(true)
              .redirectOutput(ProcessBuilder.Redirect.DISCARD)
              .start();
      p.getOutputStream().close();
      return p.waitFor() == 0;
    } catch (IOException e) {
      return false;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      return false;
    }
  }

  /** The base read from git, in a scratch repository of the test's own. */
  private static void testGitShowFile() throws IOException {
    Path repo = Files.createTempDirectory("tom_som_java_merge_test");
    try {
      File folder = repo.toFile();
      Path doc = repo.resolve("doc.md");
      Path inner = repo.resolve("sub").resolve("inner.md");
      Files.createDirectories(inner.getParent());
      Files.write(doc, "first ä\n".getBytes(StandardCharsets.UTF_8));
      Files.write(inner, "inner\n".getBytes(StandardCharsets.UTF_8));
      boolean made =
          git(folder, "init", "-q")
              && git(folder, "add", "doc.md", "sub/inner.md")
              && git(
                  folder,
                  "-c", "user.name=test",
                  "-c", "user.email=test@example.invalid",
                  "-c", "commit.gpgsign=false",
                  "-c", "core.hooksPath=/dev/null",
                  "commit", "-q", "-m", "first");
      if (!made) {
        System.out.println("SKIP: gitShowFile (no git, or the scratch repository could not be made)");
        return;
      }
      Files.write(doc, "second\n".getBytes(StandardCharsets.UTF_8));
      check(
          "gitShowFile: the committed text, not the working tree's",
          "first ä\n".equals(SpecStripMerge.gitShowFile("HEAD", doc.toString())),
          String.valueOf(SpecStripMerge.gitShowFile("HEAD", doc.toString())));
      check(
          "gitShowFile: a file in a folder is read from its folder",
          "inner\n".equals(SpecStripMerge.gitShowFile("HEAD", inner.toString())));
      check(
          "gitShowFile: an unknown commit gives none",
          SpecStripMerge.gitShowFile("0000000000000000000000000000000000000000", doc.toString())
              == null);
      check(
          "gitShowFile: an unknown file gives none",
          SpecStripMerge.gitShowFile("HEAD", doc + "x") == null);
      check(
          "gitShowFile: a missing folder gives none",
          SpecStripMerge.gitShowFile("HEAD", repo.resolve("none").resolve("doc.md").toString())
              == null);
      check(
          "gitShowFile: a commit that reads as an option gives none",
          SpecStripMerge.gitShowFile("--stat", doc.toString()) == null);
    } finally {
      try (Stream<Path> walk = Files.walk(repo)) {
        walk.sorted(Comparator.reverseOrder()).forEach(p -> p.toFile().delete());
      }
    }
  }

  public static void main(String[] args) throws IOException {
    testOverStripCases();
    testValues();
    testNonAscii();
    testLabels();
    testGitShowFile();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + (passed + failed.size()) + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
    }
    System.out.println("OK: " + passed + " checks passed");
  }
}
