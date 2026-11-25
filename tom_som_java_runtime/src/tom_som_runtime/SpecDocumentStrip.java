package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.function.IntUnaryOperator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Stripped renditions (SOM §11.10; the reading view's part <em>Stripped
 * renditions and the merge back</em>): a copy of a value, or of a whole
 * document, with the secondary prose of named kinds dropped, unmarked or
 * moved to an appendix.
 *
 * <p>The kinds are the four the reading notation registers as secondary
 * ({@code provenance}, {@code trace}, {@code editorial}, {@code aside},
 * DocSpecs RN-5), {@code linked}, the navigation marker (SOM §11.11), and
 * {@code derived}, the generated parts (SOM §11.12) — both removed by {@code
 * drop} and {@code unmark} alike —, and {@code comments}, the review
 * annotations (SOM §11.9). A citation shape counts as a span of its kind.
 * {@code refs}, {@code records} and {@code rejected} are never secondary: no
 * name drops or unmarks them (RN-11).
 *
 * <p>The Java port of {@code tom_som_typescript_runtime}'s
 * {@code spec_document_strip.ts} (itself the port of {@code
 * spec_document_strip.dart}); offsets count UTF-16 code units, which a Java
 * {@code String} index is. {@code strip_cases.json} holds all ports to the
 * same results.
 */
public final class SpecDocumentStrip {
  private SpecDocumentStrip() {}

  /** The kind names a strip takes, in report and header order. */
  public static final List<String> specStripKindNames =
      Collections.unmodifiableList(
          Arrays.asList(
              "provenance", "trace", "editorial", "aside", "linked", "derived", "comments"));

  /** The notation kinds a strip can drop, unmark or move to the appendix. */
  public static final List<String> specStripNotationKinds =
      Collections.unmodifiableList(Arrays.asList("provenance", "trace", "editorial", "aside"));

  /**
   * Strips one value with {@code options} (SOM §11.10): comments first, then
   * the notation from the outside in, then the whitespace the removals leave.
   * Appendix entries are numbered from 1. A value whose notation has an error
   * finding (other than {@code rejectedBlock}) is refused and returned
   * unchanged.
   */
  public static SpecStripTextResult stripNotationText(String value, SpecStripOptions options) {
    return new Plan(value, options).finish(i -> i + 1);
  }

  // ---------------------------------------------------------------------------
  // A whole document's strip.

  /** The strip without a model: every value stripped into a copy, nothing rendered or checked. */
  public static SpecStripResult strip(SpecDocument document, SpecStripOptions options) {
    return strip(document, options, null, null, null, null, null, null);
  }

  /** The strip with a model and, when given, its DocSpecs schema and the root to export. */
  public static SpecStripResult strip(
      SpecDocument document,
      SpecStripOptions options,
      SpecModel model,
      DocSpecsSchema schema,
      String rootType) {
    return strip(document, options, model, schema, rootType, null, null, null);
  }

  /**
   * Strips every value of {@code document} — content, form-field values,
   * scalar list items and stored headlines — into a copy. Given a {@code
   * model} it also applies the emptying rule, removes list items left empty,
   * numbers the appendix through the rendition, renders the {@code
   * .readable.md} and checks it. Every argument after {@code options} may be
   * {@code null}: {@code schema} adds the schema tier to the checks, {@code
   * rootType} names the root to export (else the single populated one),
   * {@code fileStem} and {@code documentFiles} name the files references to
   * other roots link to, {@code source} is named in the readable header.
   */
  public static SpecStripResult strip(
      SpecDocument document,
      SpecStripOptions options,
      SpecModel model,
      DocSpecsSchema schema,
      String rootType,
      String fileStem,
      Map<String, String> documentFiles,
      SpecReadableSource source) {
    List<SpecStripValueRef> refs = valueRefs(document);
    List<SpecStripFinding> findings = new ArrayList<>();
    TreeMap<Integer, Plan> plans = new TreeMap<>();
    for (int index = 0; index < refs.size(); index++) {
      SpecStripValueRef ref = refs.get(index);
      String text = ref.read(document);
      if (text.isEmpty()) {
        continue;
      }
      Plan plan = new Plan(text, options);
      if (!plan.findings.isEmpty()) {
        for (NotationFinding f : plan.findings) {
          findings.add(new SpecStripFinding("notation", findingText(f), ref));
        }
        continue;
      }
      if (plan.changes()) {
        plans.put(index, plan);
      }
    }

    SpecDocument copy = copyOf(document);
    Map<Long, Integer> provisional = new HashMap<>();
    int next = 1;
    for (Map.Entry<Integer, Plan> e : plans.entrySet()) {
      for (int i = 0; i < e.getValue().entries.size(); i++) {
        provisional.put(entryKey(e.getKey(), i), next++);
      }
    }
    apply(copy, refs, plans, provisional);
    List<SpecStripKept> kept = new ArrayList<>();
    Map<String, String> base =
        model == null ? new LinkedHashMap<>() : tierFindings(model, schema, rootType, document);
    List<String> removedItems =
        model == null
            ? new ArrayList<>()
            : emptyingRule(model, schema, rootType, base, document, copy, refs, plans, kept,
                options);

    // The appendix, numbered through the rendition.
    List<int[]> entries = new ArrayList<>();
    for (Map.Entry<Integer, Plan> e : plans.entrySet()) {
      for (int i = 0; i < e.getValue().entries.size(); i++) {
        entries.add(new int[] {e.getKey(), i});
      }
    }
    SpecRoot root = null;
    if (model != null) {
      try {
        root = copy.rootToExport(model, rootType);
      } catch (RuntimeException e) {
        findings.add(new SpecStripFinding("parse", String.valueOf(e.getMessage())));
      }
    }
    Map<String, String> titles = new LinkedHashMap<>();
    if (!entries.isEmpty() && model != null && root != null) {
      SpecMarkdownRendition map =
          new SpecDocumentMarkdown(model, copy, fileStem, documentFiles).exportRootWithMap(root);
      String[] lines = map.markdown.split("\n", -1);
      Map<String, Integer> order = new LinkedHashMap<>();
      for (Map.Entry<Integer, String> e : map.headingPaths.entrySet()) {
        order.put(e.getValue(), e.getKey());
        titles.put(e.getValue(), headingTitle(lines[e.getKey() - 1]));
      }
      Map<Integer, Integer> sectionLine = new HashMap<>();
      for (int[] entry : entries) {
        sectionLine.computeIfAbsent(
            entry[0],
            index -> {
              String path = refs.get(index).path;
              int best = 0;
              int bestLength = -1;
              for (Map.Entry<String, Integer> e : order.entrySet()) {
                String p = e.getKey();
                if ((path.equals(p) || path.startsWith(p + "/")) && p.length() > bestLength) {
                  best = e.getValue();
                  bestLength = p.length();
                }
              }
              return best;
            });
      }
      entries.sort(
          (a, b) -> {
            int c = Integer.compare(sectionLine.get(a[0]), sectionLine.get(b[0]));
            if (c != 0) {
              return c;
            }
            int d = Integer.compare(a[0], b[0]);
            return d != 0 ? d : Integer.compare(a[1], b[1]);
          });
    }
    Map<Long, Integer> numbers = new HashMap<>();
    for (int k = 0; k < entries.size(); k++) {
      numbers.put(entryKey(entries.get(k)[0], entries.get(k)[1]), k + 1);
    }
    apply(copy, refs, plans, numbers);

    List<SpecStrippedValue> values = new ArrayList<>();
    List<SpecAppendixEntry> appendix = new ArrayList<>();
    Map<String, Integer> dropped = new LinkedHashMap<>();
    Map<String, Integer> unmarked = new LinkedHashMap<>();
    Map<String, Integer> appended = new LinkedHashMap<>();
    int marksDropped = 0;
    for (Map.Entry<Integer, Plan> e : plans.entrySet()) {
      int index = e.getKey();
      Plan plan = e.getValue();
      SpecStripTextResult r = plan.finish(i -> numbers.getOrDefault(entryKey(index, i), 0));
      values.add(new SpecStrippedValue(refs.get(index), plan.o, r.text, r.pieces));
      r.dropped.forEach((k, v) -> dropped.merge(k, v, Integer::sum));
      r.unmarked.forEach((k, v) -> unmarked.merge(k, v, Integer::sum));
      r.appended.forEach((k, v) -> appended.merge(k, v, Integer::sum));
      marksDropped += r.marksDropped;
      for (SpecAppendixEntry a : r.appendix) {
        appendix.add(new SpecAppendixEntry(a.number, a.kind, a.text, refs.get(index)));
      }
    }
    appendix.sort((a, b) -> Integer.compare(a.number, b.number));

    String header = new SpecReadableHeader(options, source).format();
    String readable = null;
    if (model != null && root != null) {
      // The Java rendition writes neither linked markers (SOM §11.11) nor
      // generated parts (SOM §11.12), so `linked` and `derived` need no
      // switch here.
      SpecMarkdownRendition rendition =
          new SpecDocumentMarkdown(
                  model, copy, fileStem, documentFiles, options.headingDivs, header)
              .exportRootWithMap(root);
      if (titles.isEmpty() && !appendix.isEmpty()) {
        String[] lines = rendition.markdown.split("\n", -1);
        for (Map.Entry<Integer, String> e : rendition.headingPaths.entrySet()) {
          titles.put(e.getValue(), headingTitle(lines[e.getKey() - 1]));
        }
      }
      readable =
          appendix.isEmpty()
              ? rendition.markdown
              : withAppendix(rendition.markdown, appendix, titles, options.appendixReferences);
      checkOutput(
          model, schema, root, rootType, base, document, copy, readable, fileStem, documentFiles,
          findings);
    }
    return new SpecStripResult(
        copy,
        values,
        kept,
        removedItems,
        appendix,
        dropped,
        unmarked,
        appended,
        marksDropped,
        header,
        readable,
        findings);
  }

  private static long entryKey(int index, int entry) {
    return ((long) index << 32) | entry;
  }

  private static SpecDocument copyOf(SpecDocument document) {
    SpecDocument copy = new SpecDocument();
    copy.loadJson(document.toJson());
    return copy;
  }

  private static void apply(
      SpecDocument copy,
      List<SpecStripValueRef> refs,
      Map<Integer, Plan> plans,
      Map<Long, Integer> numbers) {
    for (Map.Entry<Integer, Plan> e : plans.entrySet()) {
      int index = e.getKey();
      refs.get(index)
          .write(
              copy,
              e.getValue().finish(i -> numbers.getOrDefault(entryKey(index, i), 0)).text);
    }
  }

  private static List<SpecStripValueRef> valueRefs(SpecDocument doc) {
    List<SpecStripValueRef> out = new ArrayList<>();
    for (String p : new TreeSet<>(doc.headlinePaths())) {
      out.add(new SpecStripValueRef(p, null, true));
    }
    for (String p : new TreeSet<>(doc.contentPaths())) {
      out.add(new SpecStripValueRef(p));
    }
    for (String p : new TreeSet<>(doc.formPaths())) {
      for (String f : new TreeSet<>(doc.formFieldNames(p))) {
        out.add(new SpecStripValueRef(p, f));
      }
    }
    return out;
  }

  private static boolean concerns(String findingPath, String path) {
    return findingPath.isEmpty()
        || path.equals(findingPath)
        || path.startsWith(findingPath + "/")
        || path.startsWith(findingPath + "-")
        || findingPath.startsWith(path + "/");
  }

  private static List<String> emptiedItems(
      List<String> candidates, Set<String> keepItems, SpecDocument document, SpecDocument copy) {
    List<String> out = new ArrayList<>();
    for (String item : candidates) {
      if (!keepItems.contains(item)
          && document.hasValuesUnder(item)
          && !copy.hasValuesUnder(item)) {
        out.add(item);
      }
    }
    return out;
  }

  private static List<String> emptyingRule(
      SpecModel model,
      DocSpecsSchema schema,
      String rootType,
      Map<String, String> base,
      SpecDocument document,
      SpecDocument copy,
      List<SpecStripValueRef> refs,
      TreeMap<Integer, Plan> plans,
      List<SpecStripKept> kept,
      SpecStripOptions options) {
    Set<Integer> keptRefs = new HashSet<>();
    Set<String> keepItems = new HashSet<>();
    List<SpecStripValueRef> planned = new ArrayList<>();
    for (int index : plans.keySet()) {
      planned.add(refs.get(index));
    }
    List<String> candidates = itemsAbove(copy, planned);
    for (int round = 0; round < 8; round++) {
      List<String> items = emptiedItems(candidates, keepItems, document, copy);
      SpecDocument scratch = copy;
      if (!items.isEmpty()) {
        scratch = copyOf(copy);
      }
      for (String item : items) {
        scratch.removeListItem(item);
      }
      Map<String, String> now = tierFindings(model, schema, rootType, scratch);
      Map<String, String> added = new LinkedHashMap<>();
      for (Map.Entry<String, String> e : now.entrySet()) {
        if (!base.containsKey(e.getKey())) {
          added.put(e.getKey(), e.getValue());
        }
      }
      if (added.isEmpty()) {
        break;
      }
      List<Integer> emptied = new ArrayList<>();
      for (int index = 0; index < refs.size(); index++) {
        if (plans.containsKey(index)
            && !keptRefs.contains(index)
            && SpecNotation.jsTrim(refs.get(index).read(copy)).isEmpty()) {
          emptied.add(index);
        }
      }
      boolean changed = false;
      for (Map.Entry<String, String> finding : added.entrySet()) {
        String findingPath = finding.getValue();
        for (String item : items) {
          if (concerns(findingPath, item) && keepItems.add(item)) {
            changed = true;
          }
        }
        for (int index : emptied) {
          SpecStripValueRef ref = refs.get(index);
          if (keptRefs.contains(index) || !concerns(findingPath, ref.path)) {
            continue;
          }
          keptRefs.add(index);
          kept.add(new SpecStripKept(ref, finding.getKey()));
          Plan keeping = new Plan(plans.get(index).o, options.keeping());
          String text = keeping.finish(i -> 0).text;
          if (SpecNotation.jsTrim(text).isEmpty()) {
            plans.remove(index);
            ref.write(copy, ref.read(document));
          } else {
            plans.put(index, keeping);
            ref.write(copy, text);
          }
          changed = true;
        }
      }
      if (!changed) {
        break;
      }
    }
    List<String> items = emptiedItems(candidates, keepItems, document, copy);
    for (String item : items) {
      copy.removeListItem(item);
    }
    return items;
  }

  private static List<String> itemsAbove(SpecDocument doc, List<SpecStripValueRef> refs) {
    Set<String> items = new HashSet<>();
    for (String list : doc.listPaths()) {
      items.addAll(doc.listItems(list));
    }
    TreeSet<String> out = new TreeSet<>();
    for (SpecStripValueRef ref : refs) {
      String p = ref.path;
      if (items.contains(p)) {
        out.add(p);
      }
      for (int i = 0; i < p.length(); i++) {
        if (p.charAt(i) == '/' && items.contains(p.substring(0, i))) {
          out.add(p.substring(0, i));
        }
      }
    }
    return new ArrayList<>(out);
  }

  /** The instance and schema findings of {@code doc}: key → the path each concerns. */
  private static Map<String, String> tierFindings(
      SpecModel model, DocSpecsSchema schema, String rootType, SpecDocument doc) {
    Map<String, String> out = new LinkedHashMap<>();
    for (SpecValidationError e : SpecValidator.validateDocument(model, doc)) {
      out.put("instance " + e.code.value + " " + e.path + ": " + e.message, e.path);
    }
    if (schema != null) {
      try {
        for (DocSpecsViolation v :
            SpecSchemaValidation.validateSpecDocument(model, doc, schema, rootType)) {
          out.put(
              "schema " + v.rule + " " + (v.sectionId != null ? v.sectionId : "") + ": "
                  + v.message,
              v.path != null ? v.path : "");
        }
      } catch (RuntimeException e) {
        // No single root to render: the schema tier cannot judge it.
      }
    }
    return out;
  }

  private static String violationKey(DocSpecsViolation v) {
    return v.rule + " " + (v.sectionId != null ? v.sectionId : "") + ": " + v.message;
  }

  private static void compare(
      String what,
      String prefix,
      Map<String, String> want,
      Map<String, String> got,
      List<SpecStripFinding> findings) {
    TreeSet<String> keys = new TreeSet<>(want.keySet());
    keys.addAll(got.keySet());
    for (String k : keys) {
      String w = want.get(k);
      String g = got.get(k);
      if (!(k.equals(prefix) || k.startsWith(prefix + "/")) || Objects.equals(w, g)) {
        continue;
      }
      // A wrapped paragraph written in a table cell reads back on one line
      // (SOM §11.4).
      if (w != null) {
        String joined = SpecDocumentMarkdown.wrappedParagraphJoined(w);
        if (joined != null && joined.equals(g)) {
          continue;
        }
      }
      findings.add(
          new SpecStripFinding(
              "parse",
              what + " at " + k + " reads back as " + (g == null ? "nothing" : "\"" + g + "\"")
                  + " instead of " + (w == null ? "nothing" : "\"" + w + "\"")));
    }
  }

  private static void checkOutput(
      SpecModel model,
      DocSpecsSchema schema,
      SpecRoot root,
      String rootType,
      Map<String, String> before,
      SpecDocument document,
      SpecDocument copy,
      String readable,
      String fileStem,
      Map<String, String> documentFiles,
      List<SpecStripFinding> findings) {
    SpecMarkdownResult parsed =
        new SpecDocumentMarkdown(model, new SpecDocument(), fileStem, documentFiles)
            .parse(readable);
    for (SpecMarkdownRejection r : parsed.rejections) {
      findings.add(new SpecStripFinding("parse", "the rendition rejects: " + r));
    }
    String prefix = root.sectionId != null ? root.sectionId : root.type;
    Map<String, String> wantContent = new LinkedHashMap<>();
    for (String p : copy.contentPaths()) {
      wantContent.put(p, copy.content(p));
    }
    compare("content", prefix, wantContent, parsed.content, findings);
    Map<String, String> wantForms = new LinkedHashMap<>();
    for (String p : copy.formPaths()) {
      for (String f : copy.formFieldNames(p)) {
        wantForms.put(p + "/" + f, copy.formField(p, f));
      }
    }
    Map<String, String> gotForms = new LinkedHashMap<>();
    for (Map.Entry<String, Map<String, String>> e : parsed.forms.entrySet()) {
      for (Map.Entry<String, String> f : e.getValue().entrySet()) {
        gotForms.put(e.getKey() + "/" + f.getKey(), f.getValue());
      }
    }
    compare("the form field", prefix, wantForms, gotForms, findings);
    for (String key : tierFindings(model, schema, rootType, copy).keySet()) {
      if (!before.containsKey(key)) {
        findings.add(new SpecStripFinding(key.startsWith("schema") ? "schema" : "instance", key));
      }
    }
    if (schema != null) {
      String original =
          new SpecDocumentMarkdown(model, document, fileStem, documentFiles).exportRoot(root);
      DocSpecsValidator validator = new DocSpecsValidator(schema, true);
      Set<String> had = new HashSet<>();
      for (DocSpecsViolation v : validator.validateMarkdown(original)) {
        had.add(violationKey(v));
      }
      for (DocSpecsViolation v : validator.validateMarkdown(readable)) {
        if (!had.contains(violationKey(v))) {
          findings.add(
              new SpecStripFinding(
                  "schema", "the rendition: line " + v.line + ": " + violationKey(v)));
        }
      }
    }
  }

  /** The title of a heading line ({@code #} or styled div) without the section's own anchor. */
  private static String headingTitle(String line) {
    SpecDocumentMarkdown.HeadingDiv div = SpecDocumentMarkdown.headingDiv(line);
    String rest;
    if (div != null) {
      rest = div.inner;
    } else {
      Matcher h = SpecDocumentMarkdown.HEADING_LINE.matcher(line);
      rest = h.matches() ? h.group(2) : line;
    }
    rest = SpecNotation.jsTrim(rest);
    Matcher c = SpecDocumentMarkdown.HEADLINE_COMMENT.matcher(rest);
    boolean comment = c.matches();
    String title = comment ? SpecNotation.jsTrim(c.group(3)) : rest;
    return DocSpecsDocument.stripOwnAnchor(title, comment ? c.group(1) : "");
  }

  private static String withAppendix(
      String markdown,
      List<SpecAppendixEntry> entries,
      Map<String, String> titles,
      boolean references) {
    StringBuilder b =
        new StringBuilder(TRAILING_NEWLINES.matcher(markdown).replaceFirst(""))
            .append("\n\n")
            .append(SpecDocumentMarkdown.APPENDIX_MARKER)
            .append("\n\n## Notes\n");
    String section = null;
    for (SpecAppendixEntry e : entries) {
      String path = "";
      String title = "";
      if (e.value != null) {
        String best = "";
        title = e.value.path;
        for (Map.Entry<String, String> t : titles.entrySet()) {
          String p = t.getKey();
          if ((e.value.path.equals(p) || e.value.path.startsWith(p + "/"))
              && p.length() > best.length()) {
            best = p;
            title = t.getValue();
          }
        }
        path = best.isEmpty() ? e.value.path : best;
      }
      if (!path.equals(section)) {
        b.append("\n### ").append(title).append("\n");
        section = path;
      }
      StringBuilder text = new StringBuilder();
      String[] lines = e.text.split("\n", -1);
      for (int i = 0; i < lines.length; i++) {
        if (i > 0) {
          text.append('\n');
        }
        text.append(lines[i].startsWith("#") ? "\\" + lines[i] : lines[i]);
      }
      if (references) {
        b.append("\n<a id=\"note-")
            .append(e.number)
            .append("\"></a>**[")
            .append(e.number)
            .append("]** ")
            .append(text)
            .append(" [↩](#note-")
            .append(e.number)
            .append("-ref)\n");
      } else {
        b.append("\n**[").append(e.number).append("]** ").append(text).append("\n");
      }
    }
    return b.toString();
  }

  private static String findingText(NotationFinding f) {
    return f.code.value + " (line " + f.line + "): " + f.message;
  }

  // ---------------------------------------------------------------------------
  // One value's strip.

  static final int KEEP = 0;
  static final int DEL = 1;
  static final int INS = 2;

  /** One character of an edit script. */
  static final class Op {
    final int type;
    final char ch;
    final String label;

    Op(int type, char ch, String label) {
      this.type = type;
      this.ch = ch;
      this.label = label;
    }
  }

  /** A token of a Myers script: {@link #KEEP}, {@link #DEL} or {@link #INS} with its text. */
  static final class Edit {
    final int type;
    final String text;

    Edit(int type, String text) {
      this.type = type;
      this.text = text;
    }
  }

  /** Text a strip writes: a converted mark's delimiter, or the reference to an appendix entry. */
  private static final class Insert {
    final String label;
    final String text;
    final int entry;

    Insert(String label, String text, int entry) {
      this.label = label;
      this.text = text;
      this.entry = entry;
    }
  }

  /** An appendix entry before its number is known. */
  static final class Entry {
    final String kind;
    final String text;

    Entry(String kind, String text) {
      this.kind = kind;
      this.text = text;
    }
  }

  private static boolean space(char c) {
    return c == ' ' || c == '\t';
  }

  private static boolean solid(char c) {
    return !SpecNotation.isJsWhitespace(c);
  }

  private static final Pattern TRAILING_NEWLINES = Pattern.compile("\\n+$");
  private static final Pattern PARAGRAPH_END = Pattern.compile("\\n[ \\t]*\\n");

  /** The strip of one value, planned once and finished for any numbering. */
  static final class Plan {
    final String o;
    final SpecStripOptions options;
    String t;
    List<Op> script1;
    String[] del;
    boolean[] blockDel = new boolean[0];
    final Map<Integer, List<Insert>> ins = new HashMap<>();
    final Map<String, Integer> dropped = new LinkedHashMap<>();
    final Map<String, Integer> unmarked = new LinkedHashMap<>();
    final Map<String, Integer> appended = new LinkedHashMap<>();
    int marksDropped;
    final List<Entry> entries = new ArrayList<>();
    final List<NotationFinding> findings = new ArrayList<>();

    Plan(String o, SpecStripOptions options) {
      this.o = o;
      this.options = options;
      for (NotationFinding f : SpecNotation.scanNotation(o, true).findings) {
        if (f.severity().equals("error") && f.code != NotationFindingCode.REJECTED_BLOCK) {
          findings.add(f);
        }
      }
      if (!findings.isEmpty()) {
        t = o;
        del = new String[o.length()];
        return;
      }
      if (options.drop.contains("comments")) {
        t = SpecReviewAnnotations.stripAnnotationsText(o);
        if (!t.equals(o)) {
          dropped.put("comments", SpecReviewAnnotations.countAnnotationsText(o));
          script1 = diff(o, t, "comments");
        }
      } else {
        t = o;
      }
      del = new String[t.length()];
      blockDel = new boolean[t.length()];
      process(SpecNotation.scanNotation(t, true).elements);
      if (!options.drop.contains("comments")) {
        marks();
      }
      if (anyDeleted()) {
        normalise();
      }
    }

    private boolean anyDeleted() {
      for (String d : del) {
        if (d != null) {
          return true;
        }
      }
      return false;
    }

    /** Whether the strip changes the value. */
    boolean changes() {
      return findings.isEmpty() && (script1 != null || anyDeleted() || !ins.isEmpty());
    }

    private void mark(int s, int e, String label) {
      mark(s, e, label, false);
    }

    private void mark(int s, int e, String label, boolean block) {
      for (int i = s; i < e && i < t.length(); i++) {
        if (del[i] == null) {
          del[i] = label;
        }
        if (block) {
          blockDel[i] = true;
        }
      }
    }

    private void insert(int at, Insert i) {
      ins.computeIfAbsent(at, k -> new ArrayList<>()).add(i);
    }

    private static void count(Map<String, Integer> m, String k) {
      m.merge(k, 1, Integer::sum);
    }

    private void process(List<NotationElement> list) {
      for (NotationElement e : list) {
        String k = e.kind;
        // A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12) is
        // removed by `-drop:` and `-unmark:` alike: its text without its
        // markers would read back as content.
        if (e.isRegistered()
            && (k.equals("linked") || k.equals("derived"))
            && (options.drop.contains(k) || options.unmark.contains(k))) {
          remove(e, k + ":drop", -1);
          count(dropped, k);
          continue;
        }
        boolean secondary = e.isRegistered() && specStripNotationKinds.contains(k);
        if (!secondary) {
          process(e.children);
          continue;
        }
        if (options.drop.contains(k)) {
          remove(e, k + ":drop", -1);
          count(dropped, k);
          continue;
        }
        if (options.appendix.contains(k)) {
          String content =
              e.type.equals("citation")
                  ? t.substring(e.start, e.end)
                  : TRAILING_NEWLINES
                      .matcher(t.substring(e.contentStart, e.contentEnd))
                      .replaceFirst("");
          entries.add(new Entry(k, stripNotationText(content, options.inEntry()).text));
          remove(e, k + ":appendix", entries.size() - 1);
          count(appended, k);
          continue;
        }
        if (options.unmark.contains(k)) {
          unmark(e, k + ":unmark");
          count(unmarked, k);
        }
        process(e.children);
      }
    }

    /** Removes {@code e}; {@code entry} is its appendix entry's index, or -1. */
    private void remove(NotationElement e, String label, int entry) {
      boolean reference = entry >= 0 && options.appendixReferences;
      if (e.type.equals("div")) {
        mark(e.start, e.end, label, true);
        if (reference) {
          insert(e.start, new Insert(label, null, entry));
        }
        return;
      }
      int s = e.start;
      if (s > 0 && space(t.charAt(s - 1)) && del[s - 1] == null) {
        del[s - 1] = label;
      } else if (!reference
          && (s == 0 || t.charAt(s - 1) == '\n')
          && e.end < t.length()
          && space(t.charAt(e.end))) {
        del[e.end] = label;
      }
      mark(e.start, e.end, label);
      if (reference) {
        insert(e.start, new Insert(label, null, entry));
      }
    }

    private void unmark(NotationElement e, String label) {
      if (e.type.equals("div")) {
        if (e.contentStart >= e.contentEnd) {
          mark(e.start, e.end, label, true);
        } else {
          mark(e.start, e.contentStart, label, true);
          mark(e.contentEnd - 1, e.end, label, true);
        }
      } else if (e.type.equals("span")) {
        mark(e.start, e.start + 1, label);
        mark(e.contentEnd, e.end, label);
      } else {
        mark(e.start + 1, e.contentStart, label);
      }
    }

    private void marks() {
      for (MarkAt m : findMarks(t)) {
        if (allDeleted(m.start, m.end)) {
          marksDropped++;
          continue;
        }
        if (m.sep < 0) {
          if (hadText(m.bodyStart, m.bodyEnd) && !survives(m.bodyStart, m.bodyEnd)) {
            removeMark(m);
          }
          continue;
        }
        boolean oldHad = hadText(m.bodyStart, m.sep);
        boolean newHad = hadText(m.sep + 2, m.bodyEnd);
        boolean oldLeft = survives(m.bodyStart, m.sep);
        boolean newLeft = survives(m.sep + 2, m.bodyEnd);
        if (!oldLeft && !newLeft && (oldHad || newHad)) {
          removeMark(m);
        } else if (oldHad && !oldLeft) {
          convert(m, "++", m.bodyStart, m.sep + 2);
        } else if (newHad && !newLeft) {
          convert(m, "--", m.sep, m.bodyEnd);
        }
      }
    }

    private void removeMark(MarkAt m) {
      int s = m.start;
      if (s > 0 && space(t.charAt(s - 1)) && del[s - 1] == null) {
        del[s - 1] = "mark";
      } else if ((s == 0 || t.charAt(s - 1) == '\n')
          && m.end < t.length()
          && space(t.charAt(m.end))) {
        del[m.end] = "mark";
      }
      mark(m.start, m.end, "mark");
    }

    private void convert(MarkAt m, String delimiter, int s, int e) {
      mark(m.start + 1, m.start + 3, "mark");
      insert(m.start + 3, new Insert("mark", delimiter, -1));
      mark(s, e, "mark");
      mark(m.end - 3, m.end - 1, "mark");
      insert(m.end - 1, new Insert("mark", delimiter, -1));
    }

    private boolean allDeleted(int s, int e) {
      for (int i = s; i < e; i++) {
        if (del[i] == null) {
          return false;
        }
      }
      return true;
    }

    private boolean hadText(int s, int e) {
      return !SpecNotation.isBlank(t.substring(s, e));
    }

    private boolean survives(int s, int e) {
      for (int i = s; i < e; i++) {
        if (del[i] == null && solid(t.charAt(i))) {
          return true;
        }
      }
      return false;
    }

    private void whitespace(int i) {
      if (i >= 0 && del[i] == null) {
        del[i] = "whitespace";
      }
    }

    private void normalise() {
      List<Integer> starts = new ArrayList<>();
      starts.add(0);
      for (int i = 0; i < t.length(); i++) {
        if (t.charAt(i) == '\n') {
          starts.add(i + 1);
        }
      }
      for (int l = 0; l < starts.size(); l++) {
        int s = starts.get(l);
        int e = l + 1 < starts.size() ? starts.get(l + 1) - 1 : t.length();
        if (SpecNotation.isBlank(t.substring(s, e))) {
          continue;
        }
        boolean touched = false;
        boolean survives = false;
        boolean allBlock = true;
        for (int i = s; i < e; i++) {
          if (del[i] != null) {
            touched = true;
          } else if (solid(t.charAt(i))) {
            survives = true;
          }
          if (!blockDel[i]) {
            allBlock = false;
          }
        }
        for (int i = s; i <= e; i++) {
          if (ins.containsKey(i)) {
            survives = true;
          }
        }
        if (!touched || survives || allBlock) {
          continue;
        }
        mark(s, e, "whitespace");
        if (e < t.length()) {
          whitespace(e);
        } else if (s > 0) {
          whitespace(s - 1);
        }
      }
      // Blank-line runs, read on the text as it now stands.
      List<Integer> keptList = new ArrayList<>();
      StringBuilder sb = new StringBuilder();
      for (int i = 0; i <= t.length(); i++) {
        List<Insert> at = ins.get(i);
        if (at != null) {
          for (Insert x : at) {
            String s = x.text != null ? x.text : "x"; // a reference is never blank
            for (int k = 0; k < s.length(); k++) {
              keptList.add(-1);
            }
            sb.append(s);
          }
        }
        if (i < t.length() && del[i] == null) {
          keptList.add(i);
          sb.append(t.charAt(i));
        }
      }
      String b = sb.toString();
      int[] kept = new int[keptList.size()];
      for (int i = 0; i < kept.length; i++) {
        kept[i] = keptList.get(i);
      }
      int firstSolid = 0;
      while (firstSolid < b.length() && !solid(b.charAt(firstSolid))) {
        firstSolid++;
      }
      if (firstSolid == b.length()) {
        for (int i : kept) {
          whitespace(i);
        }
        return;
      }
      int lastSolid = b.length() - 1;
      while (!solid(b.charAt(lastSolid))) {
        lastSolid--;
      }
      int lead = b.lastIndexOf('\n', firstSolid);
      for (int k = 0; k <= lead; k++) {
        whitespace(kept[k]);
      }
      int trail = b.indexOf('\n', lastSolid);
      if (trail >= 0) {
        for (int k = trail; k < b.length(); k++) {
          whitespace(kept[k]);
        }
      }
      int k = firstSolid;
      while (k < lastSolid) {
        if (solid(b.charAt(k))) {
          k++;
          continue;
        }
        int runStart = k;
        while (!solid(b.charAt(k))) {
          k++;
        }
        int runEnd = k;
        List<Integer> breaks = new ArrayList<>();
        for (int j = runStart; j < runEnd; j++) {
          if (b.charAt(j) == '\n') {
            breaks.add(j);
          }
        }
        if (breaks.size() <= 2) {
          continue;
        }
        int from = kept[runStart - 1];
        int to = kept[runEnd];
        boolean atRemoval = false;
        if (from >= 0 && to >= 0) {
          for (int i = from + 1; i < to; i++) {
            if (del[i] != null && !del[i].equals("whitespace")) {
              atRemoval = true;
            }
          }
        } else {
          atRemoval = true;
        }
        if (!atRemoval) {
          continue;
        }
        for (int j = breaks.get(0) + 1; j <= breaks.get(breaks.size() - 1) - 1; j++) {
          whitespace(kept[j]);
        }
      }
    }

    /** The result, its appendix entries numbered by {@code number} (entry index → number). */
    SpecStripTextResult finish(IntUnaryOperator number) {
      if (!findings.isEmpty()) {
        return new SpecStripTextResult(
            o,
            new ArrayList<>(),
            new LinkedHashMap<>(),
            new LinkedHashMap<>(),
            new LinkedHashMap<>(),
            0,
            new ArrayList<>(),
            findings);
      }
      List<Op> script2 = new ArrayList<>();
      for (int i = 0; i <= t.length(); i++) {
        List<Insert> at = ins.get(i);
        if (at != null) {
          for (Insert x : at) {
            String s;
            if (x.text != null) {
              s = x.text;
            } else {
              int n = number.applyAsInt(x.entry);
              s = "<a id=\"note-" + n + "-ref\"></a>[\\[" + n + "\\]](#note-" + n + ")";
            }
            for (int k = 0; k < s.length(); k++) {
              script2.add(new Op(INS, s.charAt(k), x.label));
            }
          }
        }
        if (i < t.length()) {
          script2.add(
              del[i] == null ? new Op(KEEP, t.charAt(i), null) : new Op(DEL, t.charAt(i), del[i]));
        }
      }
      List<Op> ops = script1 == null ? script2 : compose(script1, script2);
      StringBuilder out = new StringBuilder();
      List<SpecStripPiece> pieces = new ArrayList<>();
      int oPos = 0;
      int bPos = 0;
      int i = 0;
      while (i < ops.size()) {
        if (ops.get(i).type == KEEP) {
          out.append(ops.get(i).ch);
          oPos++;
          bPos++;
          i++;
          continue;
        }
        int anchor = bPos;
        int origin = oPos;
        StringBuilder removed = new StringBuilder();
        StringBuilder inserted = new StringBuilder();
        TreeSet<String> labels = new TreeSet<>();
        while (i < ops.size() && ops.get(i).type != KEEP) {
          Op op = ops.get(i);
          if (op.label != null) {
            labels.add(op.label);
          }
          if (op.type == DEL) {
            removed.append(op.ch);
            oPos++;
          } else {
            inserted.append(op.ch);
            out.append(op.ch);
            bPos++;
          }
          i++;
        }
        pieces.add(
            new SpecStripPiece(
                anchor, origin, removed.toString(), inserted.toString(), new ArrayList<>(labels)));
      }
      List<SpecAppendixEntry> appendix = new ArrayList<>();
      for (int k = 0; k < entries.size(); k++) {
        appendix.add(
            new SpecAppendixEntry(number.applyAsInt(k), entries.get(k).kind, entries.get(k).text));
      }
      return new SpecStripTextResult(
          out.toString(),
          pieces,
          new LinkedHashMap<>(dropped),
          new LinkedHashMap<>(unmarked),
          new LinkedHashMap<>(appended),
          marksDropped,
          appendix,
          new ArrayList<>());
    }
  }

  /** Composes the scripts original → middle ({@code s1}) and middle → result ({@code s2}). */
  static List<Op> compose(List<Op> s1, List<Op> s2) {
    List<Op> out = new ArrayList<>();
    int j = 0;
    for (Op a : s1) {
      if (a.type == DEL) {
        out.add(a);
        continue;
      }
      while (j < s2.size() && s2.get(j).type == INS) {
        out.add(s2.get(j++));
      }
      Op b = s2.get(j++);
      if (a.type == KEEP) {
        out.add(b.type == KEEP ? a : new Op(DEL, a.ch, b.label));
      } else if (b.type == KEEP) {
        out.add(a);
      }
    }
    while (j < s2.size() && s2.get(j).type == INS) {
      out.add(s2.get(j++));
    }
    return out;
  }

  private static void chars(List<Op> out, int type, String s, String label) {
    for (int k = 0; k < s.length(); k++) {
      out.add(new Op(type, s.charAt(k), type == KEEP ? null : label));
    }
  }

  /** An edit script from {@code a} to {@code b}: Myers by line, then by word token. */
  static List<Op> diff(String a, String b, String label) {
    List<Op> out = new ArrayList<>();
    StringBuilder deleted = new StringBuilder();
    StringBuilder inserted = new StringBuilder();
    List<Edit> lineEdits = new ArrayList<>(myers(lines(a), lines(b)));
    lineEdits.add(new Edit(KEEP, "")); // flushes the last run
    for (Edit e : lineEdits) {
      if (e.type == KEEP) {
        if (deleted.length() > 0 || inserted.length() > 0) {
          for (Edit x : myers(tokens(deleted.toString()), tokens(inserted.toString()))) {
            chars(out, x.type, x.text, label);
          }
          deleted.setLength(0);
          inserted.setLength(0);
        }
        chars(out, KEEP, e.text, label);
      } else if (e.type == DEL) {
        deleted.append(e.text);
      } else {
        inserted.append(e.text);
      }
    }
    return out;
  }

  /** {@code s} as its lines, each with its line break. */
  static List<String> lines(String s) {
    List<String> out = new ArrayList<>();
    int i = 0;
    while (i < s.length()) {
      int n = s.indexOf('\n', i);
      int e = n < 0 ? s.length() : n + 1;
      out.add(s.substring(i, e));
      i = e;
    }
    return out;
  }

  private static int tokenKind(char c) {
    if (c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d) {
      return 2;
    }
    if ((c >= 0x30 && c <= 0x39)
        || (c >= 0x41 && c <= 0x5a)
        || (c >= 0x61 && c <= 0x7a)
        || c == 0x5f
        || c >= 0x80) {
      return 1;
    }
    return 0;
  }

  private static List<String> tokens(String s) {
    List<String> out = new ArrayList<>();
    int i = 0;
    while (i < s.length()) {
      int k = tokenKind(s.charAt(i));
      int j = i + 1;
      if (k != 0) {
        while (j < s.length() && tokenKind(s.charAt(j)) == k) {
          j++;
        }
      }
      out.add(s.substring(i, j));
      i = j;
    }
    return out;
  }

  /** The Myers edit script from {@code a} to {@code b}; past 2000 differences, all of each. */
  static List<Edit> myers(List<String> a, List<String> b) {
    int n = a.size();
    int m = b.size();
    int max = n + m;
    List<Edit> out = new ArrayList<>();
    if (max == 0) {
      return out;
    }
    int cap = 2000;
    int off = max + 1;
    int[] v = new int[2 * max + 3];
    List<int[]> trace = new ArrayList<>();
    int found = -1;
    for (int d = 0; d <= max && d <= cap; d++) {
      if (d > 0) {
        int[] snap = new int[2 * d - 1];
        for (int k = -(d - 1); k <= d - 1; k++) {
          snap[k + d - 1] = v[k + off];
        }
        trace.add(snap);
      }
      for (int k = -d; k <= d; k += 2) {
        int x =
            k == -d || (k != d && v[k - 1 + off] < v[k + 1 + off])
                ? v[k + 1 + off]
                : v[k - 1 + off] + 1;
        int y = x - k;
        while (x < n && y < m && a.get(x).equals(b.get(y))) {
          x++;
          y++;
        }
        v[k + off] = x;
        if (x >= n && y >= m) {
          found = d;
          break;
        }
      }
      if (found >= 0) {
        break;
      }
    }
    if (found < 0) {
      for (String t : a) {
        out.add(new Edit(DEL, t));
      }
      for (String t : b) {
        out.add(new Edit(INS, t));
      }
      return out;
    }
    int x = n;
    int y = m;
    for (int d = found; d > 0; d--) {
      int[] snap = trace.get(d - 1);
      int k = x - y;
      int prevK =
          k == -d || (k != d && snap[k - 1 + d - 1] < snap[k + 1 + d - 1]) ? k + 1 : k - 1;
      int prevX = snap[prevK + d - 1];
      int prevY = prevX - prevK;
      while (x > prevX && y > prevY) {
        out.add(new Edit(KEEP, a.get(x - 1)));
        x--;
        y--;
      }
      if (x == prevX) {
        out.add(new Edit(INS, b.get(y - 1)));
      } else {
        out.add(new Edit(DEL, a.get(x - 1)));
      }
      x = prevX;
      y = prevY;
    }
    while (x > 0 && y > 0) {
      out.add(new Edit(KEEP, a.get(x - 1)));
      x--;
      y--;
    }
    Collections.reverse(out);
    return out;
  }

  /** An inline review mark of a value: its range, its body and its {@code ~>} (or -1). */
  static final class MarkAt {
    final int start;
    final int end;
    final int bodyStart;
    final int bodyEnd;
    final int sep;

    MarkAt(int start, int end, int bodyStart, int bodyEnd, int sep) {
      this.start = start;
      this.end = end;
      this.bodyStart = bodyStart;
      this.bodyEnd = bodyEnd;
      this.sep = sep;
    }
  }

  private static String markCloser(String opener) {
    switch (opener) {
      case "{++":
        return "++}";
      case "{--":
        return "--}";
      case "{~~":
        return "~~}";
      case "{==":
        return "==}";
      case "{>>":
        return "<<}";
      default:
        return null;
    }
  }

  /** The inline review marks of {@code t} outside code, each closing on its paragraph. */
  static List<MarkAt> findMarks(String t) {
    boolean[] code = new boolean[t.length()];
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    int s = 0;
    for (String line : t.split("\n", -1)) {
      boolean inFence = fence.inFence();
      fence.feed(line);
      if (inFence || fence.inFence()) {
        for (int i = s; i < s + line.length(); i++) {
          code[i] = true;
        }
      } else {
        int i = 0;
        while (i < line.length()) {
          if (line.charAt(i) != '`') {
            i++;
            continue;
          }
          int j = i;
          while (j < line.length() && line.charAt(j) == '`') {
            j++;
          }
          String ticks = line.substring(i, j);
          int close = line.indexOf(ticks, j);
          if (close < 0) {
            i = j;
            continue;
          }
          for (int k = s + i; k < s + close + ticks.length(); k++) {
            code[k] = true;
          }
          i = close + ticks.length();
        }
      }
      s += line.length() + 1;
    }
    List<MarkAt> out = new ArrayList<>();
    Matcher paragraphEnd = PARAGRAPH_END.matcher(t);
    int i = 0;
    while (i + 3 <= t.length()) {
      String opener = t.substring(i, i + 3);
      String closer = markCloser(opener);
      if (closer == null || code[i]) {
        i++;
        continue;
      }
      int limit = paragraphEnd.find(i) ? paragraphEnd.start() : t.length();
      int close = t.indexOf(closer, i + 3);
      if (close < 0 || close + 3 > limit) {
        i++;
        continue;
      }
      int sep = -1;
      if (opener.equals("{~~")) {
        sep = t.indexOf("~>", i + 3);
        if (sep < 0 || sep >= close) {
          i++;
          continue;
        }
      }
      out.add(new MarkAt(i, close + 3, i + 3, close, sep));
      i = close + 3;
    }
    return out;
  }
}
