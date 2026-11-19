package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;
import java.util.regex.Pattern;

/**
 * The impact walk — the starting table of a change's impact evaluation (the
 * change mode of the {@code tom_specs} process, Phase 0 step {@code impact}); a
 * port of {@code spec_impact_walk.ts}.
 *
 * <p>For a specification it lists <b>every</b> section of <b>every</b> document
 * root of the model, filled or not, and roots the project never created as
 * well: each row with its section-id chain, its model class, whether it holds
 * values, and its CodeSpecs routing. Beside it, {@link #specImpactLevel} records
 * how far the project has come (documents, extracts, IR, tests, code).
 *
 * <p>Rows: one per class node (the root, each {@code complex} / {@code section}
 * field, each list item) and one per list (with its item count). An empty list
 * of a class element gets one <b>template</b> row {@code <list>/*} with the
 * element's subtree below it. Value leaves (content, form fields) are counted in
 * their row, not rows of their own. A class already on the branch is not
 * entered again. Below a {@code @FollowUpKind} section every row carries that
 * routing, as the CodeSpecs extractor treats it.
 *
 * <p>Pure: it reads a model and documents and writes nothing. Pinned by
 * {@code tom_som_conformance/corpus/impact_walk_cases.json}.
 */
public final class SpecImpactWalk {
  private SpecImpactWalk() {}

  /**
   * Walks every document root of {@code model}, in model order: a root present in
   * {@code documents} (keyed by root type) over its document, any other over an
   * empty one. A document keyed by a type the model has no root for is refused
   * with an {@link IllegalArgumentException}.
   */
  public static List<SpecImpactRootWalk> specImpactWalk(
      SpecModel model, Map<String, SpecDocument> documents) {
    for (String type : documents.keySet()) {
      boolean known = false;
      for (SpecRoot r : model.roots) {
        if (r.type.equals(type)) {
          known = true;
          break;
        }
      }
      if (!known) {
        throw new IllegalArgumentException(
            "spec_impact_walk: the model has no document root " + type);
      }
    }
    SpecReflection reflection = new SpecReflection(model);
    List<SpecImpactRootWalk> out = new ArrayList<>();
    for (SpecRoot root : model.roots) {
      SpecDocument doc = documents.get(root.type);
      Walker walker = new Walker(model, reflection, doc != null ? doc : new SpecDocument());
      out.add(new SpecImpactRootWalk(
          root.type, reflection.rootSegment(root), doc != null, walker.walkRoot(root)));
    }
    return out;
  }

  private static final class Walker {
    final List<SpecImpactRow> rows = new ArrayList<>();
    /** Stored values per path prefix (a value counts at its own path and every ancestor). */
    private final Map<String, Integer> counts = new HashMap<>();
    private final SpecModel model;
    private final SpecReflection reflection;
    private final SpecDocument doc;

    Walker(SpecModel model, SpecReflection reflection, SpecDocument doc) {
      this.model = model;
      this.reflection = reflection;
      this.doc = doc;
      for (String path : doc.contentPaths()) {
        if (doc.content(path) != null) {
          count(path);
        }
      }
      for (String path : doc.formPaths()) {
        for (String field : doc.formFieldNames(path)) {
          if (doc.formField(path, field) != null) {
            count(path);
          }
        }
      }
    }

    /** Adds one value at {@code path} to the path and each of its prefixes ending before {@code /} or {@code -}. */
    private void count(String path) {
      counts.merge(path, 1, Integer::sum);
      for (int i = path.length() - 1; i > 0; i--) {
        char c = path.charAt(i);
        if (c == '/' || c == '-') {
          counts.merge(path.substring(0, i), 1, Integer::sum);
        }
      }
    }

    private int valuesAt(String path) {
      Integer n = counts.get(path);
      return n == null ? 0 : n.intValue();
    }

    List<SpecImpactRow> walkRoot(SpecRoot root) {
      SpecClass cls = model.classNamed(root.type);
      if (cls == null) {
        return rows;
      }
      String segment = reflection.rootSegment(root);
      Set<String> ancestors = new HashSet<>();
      ancestors.add(cls.name);
      classNode(SpecImpactRowKind.ROOT, segment, segment, cls, 0, ancestors, null);
      return rows;
    }

    private static Set<String> with(Set<String> ancestors, String name) {
      Set<String> next = new HashSet<>(ancestors);
      next.add(name);
      return next;
    }

    private void classNode(
        SpecImpactRowKind kind,
        String path,
        String chain,
        SpecClass cls,
        int depth,
        Set<String> ancestors,
        CodeSpecsRouting process) {
      boolean template = path.contains("*");
      CodeSpecsRouting routing =
          process != null ? process : CodeSpecsRouting.codeSpecsClassRouting(cls, path);
      CodeSpecsRouting below =
          routing.verdict == CodeSpecsRoutingVerdict.FEEDS_PROCESS ? routing : null;
      rows.add(new SpecImpactRow(
          path,
          chain,
          kind,
          cls.name,
          depth,
          !template && doc.hasValuesUnder(path),
          template ? 0 : valuesAt(path),
          null,
          routing));
      for (SpecField field : cls.fields) {
        String segment = reflection.fieldSegment(field);
        String fieldPath = SpecPaths.join(path, segment);
        String fieldChain = chain + " > " + segment;
        switch (field.kind) {
          case COMPLEX:
          case SECTION: {
            SpecClass child = enter(field.type, ancestors);
            if (child != null) {
              SpecImpactRowKind childKind = field.kind == SpecFieldKind.COMPLEX
                  ? SpecImpactRowKind.COMPLEX
                  : SpecImpactRowKind.SECTION;
              classNode(childKind, fieldPath, fieldChain, child, depth + 1,
                  with(ancestors, child.name), below);
            }
            break;
          }
          case LIST:
            list(cls, field, fieldPath, fieldChain, depth + 1, ancestors, below);
            break;
          default:
            break; // a value leaf: counted in this row
        }
      }
    }

    private void list(
        SpecClass owner,
        SpecField field,
        String path,
        String chain,
        int depth,
        Set<String> ancestors,
        CodeSpecsRouting process) {
      boolean template = path.contains("*");
      List<String> items = template ? Collections.<String>emptyList() : doc.listItems(path);
      SpecClass element = field.elementIsComplex ? model.classNamed(field.elementType) : null;
      CodeSpecsRouting routing;
      if (process != null) {
        routing = process;
      } else if (element != null) {
        routing = CodeSpecsRouting.codeSpecsClassRouting(element, path);
      } else {
        CodeSpecsRouting declared = CodeSpecsRouting.codeSpecsFieldRouting(owner, field);
        routing = declared != null ? declared : CodeSpecsRouting.codeSpecsClassRouting(owner, path);
      }
      rows.add(new SpecImpactRow(
          path,
          chain,
          SpecImpactRowKind.LIST,
          element != null ? element.name : "",
          depth,
          !template && doc.hasValuesUnder(path),
          template ? 0 : valuesAt(path),
          Integer.valueOf(items.size()),
          routing));
      if (element == null || ancestors.contains(element.name)) {
        return;
      }
      Set<String> next = with(ancestors, element.name);
      if (items.isEmpty()) {
        classNode(SpecImpactRowKind.TEMPLATE, path + "/*", chain + " > *", element, depth + 1,
            next, process);
        return;
      }
      for (String itemPath : items) {
        String stored = doc.itemSectionId(itemPath);
        String id = stored != null ? stored : itemPath.substring(itemPath.lastIndexOf('/') + 1);
        classNode(SpecImpactRowKind.ITEM, itemPath, chain + " > " + id, element, depth + 1,
            next, process);
      }
    }

    private SpecClass enter(String type, Set<String> ancestors) {
      if (type == null || ancestors.contains(type)) {
        return null;
      }
      return model.classNamed(type);
    }
  }

  // --- the project's level -------------------------------------------------

  private static final Pattern PROJECT_IDEA = Pattern.compile("^phase1_[^/]*/[^/]+\\.md$");
  private static final Pattern EXTRACT =
      Pattern.compile("^generated-doc/codespecs_extracts/CE-[^/]+\\.extract\\.yaml$");
  private static final Pattern IR = Pattern.compile("^irspecs/[^/]+\\.ir\\.yaml$");
  private static final Pattern GATE_CHECKLIST = Pattern.compile("^gates/G[^/]*\\.checklist\\.yaml$");
  private static final Pattern GATE_REPORT = Pattern.compile("^quality/evidence/gates/[^/]+\\.md$");
  private static final Pattern DOCUMENT_FILE = Pattern.compile("^phase[^/]*/[^/]+\\.docspecs\\.yaml$");

  private static List<String> normalized(List<String> listing) {
    List<String> out = new ArrayList<>();
    for (String p : listing) {
      String f = p.replace('\\', '/');
      if (f.startsWith("./")) {
        f = f.substring(2);
      }
      out.add(f);
    }
    return out;
  }

  /**
   * The project's level from the walk and a listing of the spec root (paths
   * relative to it, {@code /}-separated). Phase 2 is reached when the root with
   * section id {@code SBP} is present, Phase 3 when any other root is that is
   * not a generation input, Phase 4 when extracts or IR exist, Phases 5 and 6
   * when a test or code folder the caller passed exists. Phases 7–8 are not
   * visible on disk and are not reported. {@code tests} / {@code code} are
   * {@code null} when none were given.
   */
  public static SpecImpactLevel specImpactLevel(
      SpecModel model,
      List<SpecImpactRootWalk> walk,
      List<String> listing,
      List<SpecImpactFolder> tests,
      List<SpecImpactFolder> code) {
    List<String> files = normalized(listing);
    List<SpecImpactLevelDocument> documents = new ArrayList<>();
    for (SpecImpactRootWalk r : walk) {
      documents.add(new SpecImpactLevelDocument(r.type, r.sectionId, r.present));
    }
    boolean projectIdea = false;
    int extracts = 0;
    int ir = 0;
    List<String> gates = new ArrayList<>();
    for (String f : files) {
      if (PROJECT_IDEA.matcher(f).find()) {
        projectIdea = true;
      }
      if (EXTRACT.matcher(f).find()) {
        extracts++;
      }
      if (IR.matcher(f).find()) {
        ir++;
      }
      if (GATE_CHECKLIST.matcher(f).find() || GATE_REPORT.matcher(f).find()) {
        gates.add(f);
      }
    }
    Collections.sort(gates);
    boolean gateRecord = files.contains("generated-doc/codespecs_extracts/gate.verdicts.yaml");
    List<Integer> reached = new ArrayList<>();
    if (projectIdea) {
      reached.add(1);
    }
    if (present(model, walk, r -> "SBP".equals(r.sectionId))) {
      reached.add(2);
    }
    if (present(model, walk, r -> !"SBP".equals(r.sectionId) && !model.isGenerationInput(r))) {
      reached.add(3);
    }
    if (extracts > 0 || ir > 0) {
      reached.add(4);
    }
    if (anyPresent(tests)) {
      reached.add(5);
    }
    if (anyPresent(code)) {
      reached.add(6);
    }
    List<Integer> leftOut = new ArrayList<>();
    for (int p = 1; p <= 6; p++) {
      if (!reached.contains(p)) {
        leftOut.add(p);
      }
    }
    return new SpecImpactLevel(
        documents, projectIdea, extracts, gateRecord, ir, gates, tests, code, reached, leftOut);
  }

  private static boolean present(
      SpecModel model, List<SpecImpactRootWalk> walk, Predicate<SpecRoot> test) {
    for (SpecImpactRootWalk w : walk) {
      if (!w.present) {
        continue;
      }
      for (SpecRoot r : model.roots) {
        if (r.type.equals(w.type)) {
          if (test.test(r)) {
            return true;
          }
          break;
        }
      }
    }
    return false;
  }

  private static boolean anyPresent(List<SpecImpactFolder> folders) {
    if (folders == null) {
      return false;
    }
    for (SpecImpactFolder f : folders) {
      if (f.present) {
        return true;
      }
    }
    return false;
  }

  /**
   * The specification's current documents in a listing of the spec root: the
   * {@code *.docspecs.yaml} files directly in a {@code phase*} folder, sorted.
   * The numbered step folders below hold round copies and are not the
   * specification.
   */
  public static List<String> specImpactDocumentFiles(List<String> listing) {
    List<String> out = new ArrayList<>();
    for (String f : normalized(listing)) {
      if (DOCUMENT_FILE.matcher(f).find()) {
        out.add(f);
      }
    }
    Collections.sort(out);
    return out;
  }

  // --- the Markdown table --------------------------------------------------

  private static String cell(String text) {
    return text.replace("|", "\\|");
  }

  private static String orNone(String joined) {
    return joined.isEmpty() ? "none" : joined;
  }

  private static String joinInts(List<Integer> values) {
    List<String> parts = new ArrayList<>();
    for (Integer v : values) {
      parts.add(String.valueOf(v));
    }
    return String.join(", ", parts);
  }

  private static String folders(List<SpecImpactFolder> f) {
    if (f == null) {
      return "not given";
    }
    if (f.isEmpty()) {
      return "none";
    }
    List<String> parts = new ArrayList<>();
    for (SpecImpactFolder x : f) {
      parts.add("`" + x.path + "` (" + (x.present ? "present" : "absent") + ")");
    }
    return String.join(", ", parts);
  }

  /**
   * The walk as Markdown, for a round folder's {@code walk/} (one table per
   * root, then § Level when {@code level} is not {@code null}): the table the
   * change analyst gives verdicts to.
   */
  public static String specImpactWalkMarkdown(List<SpecImpactRootWalk> walk, SpecImpactLevel level) {
    List<String> out = new ArrayList<>();
    out.add("# Impact walk");
    out.add("");
    out.add("Every section of every document root, filled or not: the section-id chain, the model class, "
        + "whether it holds values, and its CodeSpecs routing. "
        + "A list counts its items; an empty list of sections shows what a new item holds at `<list>/*`.");
    out.add("");
    for (SpecImpactRootWalk root : walk) {
      int filled = 0;
      for (SpecImpactRow r : root.rows) {
        if (r.filled) {
          filled++;
        }
      }
      out.add("## " + root.sectionId + " — " + root.type + (root.present ? "" : " (absent)"));
      out.add("");
      out.add(root.rows.size() + " rows, " + filled + " holding values.");
      out.add("");
      out.add("| Section-id chain | Path | Kind | Class | Values | Items | Routing |");
      out.add("| --- | --- | --- | --- | --- | --- | --- |");
      for (SpecImpactRow r : root.rows) {
        String routing = r.routingValues.isEmpty()
            ? r.routing
            : r.routing + ": " + String.join(", ", r.routingValues);
        out.add("| " + cell(r.chain) + " | `" + cell(r.path) + "` | " + r.kind.value + " | "
            + cell(r.className) + " | " + (r.filled ? String.valueOf(r.values) : "—") + " | "
            + (r.items != null ? String.valueOf(r.items) : "") + " | " + cell(routing) + " |");
      }
      out.add("");
    }
    if (level != null) {
      List<String> present = new ArrayList<>();
      List<String> absent = new ArrayList<>();
      for (SpecImpactLevelDocument d : level.documents) {
        (d.present ? present : absent).add(d.sectionId);
      }
      List<String> gates = new ArrayList<>();
      for (String g : level.gates) {
        gates.add("`" + g + "`");
      }
      out.add("## Level");
      out.add("");
      out.add("- Documents present: " + orNone(String.join(", ", present)));
      out.add("- Documents absent: " + orNone(String.join(", ", absent)));
      out.add("- Project Idea: " + (level.projectIdea ? "yes" : "no"));
      out.add("- CodeSpecs extracts: " + level.extracts + "; gate record: "
          + (level.gateRecord ? "yes" : "no"));
      out.add("- IR Specs: " + level.ir);
      out.add("- Gates: " + orNone(String.join(", ", gates)));
      out.add("- Tests: " + folders(level.tests));
      out.add("- Code: " + folders(level.code));
      out.add("- Phases reached: " + orNone(joinInts(level.phasesReached))
          + "; left out by a change: " + orNone(joinInts(level.phasesLeftOut))
          + " (Phases 7–8 are not visible on disk)");
      out.add("");
    }
    return String.join("\n", out);
  }
}
