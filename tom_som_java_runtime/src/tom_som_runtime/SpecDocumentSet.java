package tom_som_runtime;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Pattern;

/**
 * A project's specification documents read side by side, one per root, and the
 * validation of the set ({@code tom_specs_model_rules.md} §9.7): the places a
 * Phase 3 document shares with the Solution Blueprint agree, element by element
 * and value by value, and the links that cross two documents hold.
 *
 * <p>The documents are never assembled into one: each keeps its own registry,
 * and every finding names the document a place is in. {@link #syncReport}
 * writes nothing; {@link #renameId} renames an id in every document at once.
 * The comparison internals ({@link SpecSetCheck}, {@link SpecSetSide}) are what
 * {@link SpecBackfill#backfill} and {@link SpecPrefill#prefill} read.
 *
 * <p>A port of {@code tom_som_dart_runtime/lib/src/spec_document_set.dart} (and
 * the TypeScript, JavaScript, Python and Go {@code spec_document_set} modules).
 */
public final class SpecDocumentSet {
  /** The model the set is read with. */
  public final SpecModel model;
  /** The model's reflection. */
  public final SpecReflection refl;
  /**
   * The Blueprint's root class name: the root the others are {@code basedOn};
   * {@code null} when the model names none.
   */
  public final String blueprintRoot;

  private final Map<String, SpecDocument> documents = new HashMap<>();
  private final Map<String, String> rootOf = new HashMap<>();
  private final List<String> order = new ArrayList<>();
  private final List<SpecSyncPair> pairs;

  /**
   * A set of {@code documents}, each named by the file name the tools use. Each
   * document populates exactly one root; two documents of one root, a document
   * with no populated root or with two, and the CodeSpecs projection are refused
   * with a {@link SpecDocumentSetError} naming the documents, as is a model whose
   * synced positions cannot be paired.
   */
  public SpecDocumentSet(
      SpecModel model, List<? extends Map.Entry<String, SpecDocument>> documents) {
    this.model = model;
    this.refl = new SpecReflection(model);
    this.blueprintRoot = computeBlueprintRoot();
    this.pairs = Collections.unmodifiableList(computePairs());
    if (documents != null) {
      for (Map.Entry<String, SpecDocument> d : documents) {
        put(d.getKey(), d.getValue());
      }
    }
  }

  /** A set without documents yet: its pairs, and every Phase 3 root missing. */
  public SpecDocumentSet(SpecModel model) {
    this(model, null);
  }

  /**
   * Loads YAML or SOM Markdown files; files of one root are fragments and are
   * assembled first (refusing overlaps). Each document is named by its first
   * file's name.
   */
  public static SpecDocumentSet load(SpecModel model, List<String> files) throws IOException {
    Map<String, SomMetaTree> trees = new HashMap<>();
    List<Map.Entry<String, SpecDocument>> fragments = new ArrayList<>();
    for (String file : files) {
      String text = new String(Files.readAllBytes(Path.of(file)), StandardCharsets.UTF_8);
      String normalized = file.replace('\\', '/');
      String name = normalized.substring(normalized.lastIndexOf('/') + 1);
      SpecDocument doc;
      if (file.endsWith(".md")) {
        doc = SpecDocument.fromMarkdown(text, model).document;
      } else {
        // The root key `<SECTIONID> <Type>:` names the tree to decode with.
        SpecRoot root = null;
        for (SpecRoot r : model.roots) {
          Pattern p =
              Pattern.compile(
                  "(?m)^\\s*" + Pattern.quote(r.sectionId + " " + r.type) + ":");
          if (p.matcher(text).find()) {
            root = r;
            break;
          }
        }
        if (root == null) {
          throw new SpecDocumentSetError(
              SpecDocumentSetRefusal.NO_ROOT, List.of(name), name + " names no root of the model");
        }
        SomMetaTree tree = trees.get(root.type);
        if (tree == null) {
          tree = SomMetaBridge.buildSomMetaTree(model, root.type);
          trees.put(root.type, tree);
        }
        doc = SpecDocument.fromYaml(text, tree);
      }
      fragments.add(new AbstractMap.SimpleImmutableEntry<>(name, doc));
    }
    return fromFragments(model, fragments);
  }

  /**
   * A set from documents and fragments: those of one root are fragments of one
   * document, assembled in the order given (overlaps refused), the document
   * named by its first fragment's name.
   */
  public static SpecDocumentSet fromFragments(
      SpecModel model, List<? extends Map.Entry<String, SpecDocument>> fragments) {
    SpecReflection refl = new SpecReflection(model);
    Map<String, List<Map.Entry<String, SpecDocument>>> byRoot = new LinkedHashMap<>();
    for (Map.Entry<String, SpecDocument> f : fragments) {
      List<String> roots = populatedRoots(refl, f.getValue());
      if (roots.size() != 1) {
        boolean none = roots.isEmpty();
        throw new SpecDocumentSetError(
            none ? SpecDocumentSetRefusal.NO_ROOT : SpecDocumentSetRefusal.TWO_ROOTS,
            List.of(f.getKey()),
            f.getKey() + " populates " + (none ? "no root" : String.join(" and ", roots)));
      }
      byRoot.computeIfAbsent(roots.get(0), k -> new ArrayList<>()).add(f);
    }
    List<Map.Entry<String, SpecDocument>> documents = new ArrayList<>();
    for (List<Map.Entry<String, SpecDocument>> group : byRoot.values()) {
      if (group.size() == 1) {
        documents.add(group.get(0));
        continue;
      }
      List<String> names = new ArrayList<>();
      for (Map.Entry<String, SpecDocument> g : group) {
        names.add(g.getKey());
      }
      SpecDocumentAssembly assembly = SpecDocumentAssembly.assemble(group);
      if (!assembly.ok()) {
        throw new SpecDocumentSetError(
            SpecDocumentSetRefusal.OVERLAP,
            names,
            "the fragments " + String.join(", ", names) + " overlap");
      }
      documents.add(new AbstractMap.SimpleImmutableEntry<>(names.get(0), assembly.document));
    }
    return new SpecDocumentSet(model, documents);
  }

  private String computeBlueprintRoot() {
    List<String> targets = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      SpecClass cls = refl.classNamed(r.type);
      if (cls == null) {
        continue;
      }
      SpecAnnotation doc = cls.annotation("Document");
      if (doc == null) {
        continue;
      }
      Object based = doc.argument("basedOn");
      if (based instanceof List) {
        for (Object e : (List<?>) based) {
          String t = LinkArguments.jsonText(e);
          if (!targets.contains(t)) {
            targets.add(t);
          }
        }
      }
    }
    return targets.size() == 1 ? targets.get(0) : null;
  }

  /** The Blueprint document, or {@code null}. */
  public SpecDocument blueprint() {
    return blueprintRoot == null ? null : document(blueprintRoot);
  }

  /** The document of {@code rootType} (a type name or a section id), or {@code null}. */
  public SpecDocument document(String rootType) {
    String name = nameOf(rootType);
    return name == null ? null : documents.get(name);
  }

  /** The name of the document of {@code rootType} (a type name or a section id), {@code null} when the set has none. */
  public String nameOf(String rootType) {
    String t = typeOf(rootType);
    if (t == null) {
      return null;
    }
    for (String name : order) {
      if (rootOf.get(name).equals(t)) {
        return name;
      }
    }
    return null;
  }

  private String typeOf(String rootType) {
    if (rootType == null || rootType.isEmpty()) {
      return null;
    }
    for (SpecRoot r : model.roots) {
      if (r.type.equals(rootType) || rootType.equals(r.sectionId)) {
        return r.type;
      }
    }
    return null;
  }

  private boolean hasRoot(String type) {
    return rootOf.containsValue(type);
  }

  /** The populated roots, in model order. */
  public List<String> roots() {
    List<String> out = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      if (hasRoot(r.type)) {
        out.add(r.type);
      }
    }
    return out;
  }

  /** The document names, in model order of their roots. */
  public List<String> names() {
    List<String> out = new ArrayList<>();
    for (String r : roots()) {
      String name = nameOf(r);
      if (name != null) {
        out.add(name);
      }
    }
    return out;
  }

  /**
   * Every Phase 3 root a pair names with no document yet: its pairs are "not
   * started", reported as such and never as findings.
   */
  public List<String> missingRoots() {
    List<String> out = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      boolean named = false;
      for (SpecSyncPair p : pairs) {
        if (p.detailRoot.equals(r.type)) {
          named = true;
          break;
        }
      }
      if (named && !hasRoot(r.type)) {
        out.add(r.type);
      }
    }
    return out;
  }

  /** The anchor pairs, in the Blueprint's walk order. */
  public List<SpecSyncPair> pairs() {
    return pairs;
  }

  /** Adds or replaces a document (what {@code prefill} creates); refused like the documents the constructor takes. */
  public void put(String name, SpecDocument document) {
    List<String> roots = populatedRoots(refl, document);
    if (roots.isEmpty()) {
      throw new SpecDocumentSetError(
          SpecDocumentSetRefusal.NO_ROOT, List.of(name), name + " populates no root");
    }
    if (roots.size() > 1) {
      throw new SpecDocumentSetError(
          SpecDocumentSetRefusal.TWO_ROOTS,
          List.of(name),
          name + " populates " + String.join(" and ", roots));
    }
    String root = roots.get(0);
    SpecClass cls = refl.classNamed(root);
    if (cls != null && cls.isCodeSpecsProjection()) {
      throw new SpecDocumentSetError(
          SpecDocumentSetRefusal.PROJECTION,
          List.of(name),
          name + " is the CodeSpecs projection, which is no specification");
    }
    for (String other : order) {
      if (rootOf.get(other).equals(root) && !other.equals(name)) {
        throw new SpecDocumentSetError(
            SpecDocumentSetRefusal.SAME_ROOT,
            List.of(other, name),
            other + " and " + name + " both populate " + root);
      }
    }
    if (!documents.containsKey(name)) {
      order.add(name);
    }
    documents.put(name, document);
    rootOf.put(name, root);
  }

  /** The document named {@code name}, or {@code null}. */
  public SpecDocument get(String name) {
    return documents.get(name);
  }

  /** The root class name of the document named {@code name}, {@code null} when the set has none of that name. */
  public String rootOf(String name) {
    return rootOf.get(name);
  }

  /** The roots {@code doc} holds a value under, in model order. */
  static List<String> populatedRoots(SpecReflection refl, SpecDocument doc) {
    Set<String> segs = new HashSet<>();
    List<Set<String>> stores =
        List.of(doc.contentPaths(), doc.formPaths(), doc.listPaths(), doc.headlinePaths());
    for (Set<String> paths : stores) {
      for (String p : paths) {
        int slash = p.indexOf('/');
        segs.add(slash >= 0 ? p.substring(0, slash) : p);
      }
    }
    List<String> out = new ArrayList<>();
    for (SpecRoot r : refl.model.roots) {
      if (segs.contains(refl.rootSegment(r))) {
        out.add(r.type);
      }
    }
    return out;
  }

  // --- the anchor pairs -------------------------------------------------------

  private final Map<String, List<SpecSectionPosition>> positionCache = new HashMap<>();

  /** The class positions of {@code root}, {@code @SameAs} copies left out (a copy is kept equal to its holder, never paired). */
  private List<SpecSectionPosition> positionsOf(String root) {
    List<SpecSectionPosition> hit = positionCache.get(root);
    if (hit != null) {
      return hit;
    }
    List<SpecSectionPosition> every = SpecPlace.sectionPositions(refl, root);
    List<String> copies = new ArrayList<>();
    for (SpecSectionPosition p : every) {
      if (!p.isMember && p.member != null && p.member.sameAs() != null) {
        copies.add(p.path);
      }
    }
    hit = new ArrayList<>();
    for (SpecSectionPosition p : every) {
      if (p.isMember) {
        continue;
      }
      boolean inCopy = false;
      for (String c : copies) {
        if (p.path.equals(c) || p.path.startsWith(c + "/")) {
          inCopy = true;
          break;
        }
      }
      if (!inCopy) {
        hit.add(p);
      }
    }
    positionCache.put(root, hit);
    return hit;
  }

  private static SpecDocumentSetError unpairable(String className) {
    return new SpecDocumentSetError(
        SpecDocumentSetRefusal.UNPAIRABLE,
        List.of(),
        "the positions of " + className + " in the Blueprint and its document "
            + "cannot be paired (SHARED-ANCHOR)",
        className);
  }

  /** The key a position is paired by: the path below the nearest enclosing anchor. */
  private String pairKey(SpecSectionPosition p, String root, Map<String, String> candidates) {
    SpecSectionPosition outer = null;
    for (SpecSectionPosition q : positionsOf(root)) {
      if (q.path.equals(p.path) || !p.path.startsWith(q.path + "/")) {
        continue;
      }
      if (!candidates.containsKey(q.className)) {
        continue;
      }
      if (outer == null || q.path.length() > outer.path.length()) {
        outer = q;
      }
    }
    List<String> ids = p.sectionIds;
    String outerName = "";
    if (outer != null) {
      ids = p.sectionIds.subList(outer.sectionIds.size(), p.sectionIds.size());
      outerName = outer.className;
    }
    return outerName + "/" + String.join("/", ids);
  }

  private List<SpecSyncPair> computePairs() {
    List<SpecSyncPair> out = new ArrayList<>();
    String bp = blueprintRoot;
    if (bp == null) {
      return out;
    }
    Map<String, String> candidates = new LinkedHashMap<>(); // class -> target root
    for (SpecSectionPosition p : positionsOf(bp)) {
      SpecClass cls = refl.classNamed(p.className);
      if (cls == null) {
        continue;
      }
      String target = cls.detailedIn;
      SpecSync sync = cls.syncedWith();
      if (sync != null) {
        target = sync.document;
      }
      if (target == null || target.isEmpty() || target.equals(bp) || refl.classNamed(target) == null) {
        continue;
      }
      candidates.putIfAbsent(p.className, target);
    }

    for (Map.Entry<String, String> cand : candidates.entrySet()) {
      String className = cand.getKey();
      String target = cand.getValue();
      List<SpecSectionPosition> mine = new ArrayList<>();
      List<SpecSectionPosition> theirs = new ArrayList<>();
      for (SpecSectionPosition p : positionsOf(bp)) {
        if (p.className.equals(className)) {
          mine.add(p);
        }
      }
      for (SpecSectionPosition p : positionsOf(target)) {
        if (p.className.equals(className)) {
          theirs.add(p);
        }
      }
      if (theirs.isEmpty()) {
        continue;
      }
      List<SpecSectionPosition[]> matched = new ArrayList<>();
      if (mine.size() == 1 && theirs.size() == 1) {
        matched.add(new SpecSectionPosition[] {mine.get(0), theirs.get(0)});
      } else {
        Map<String, SpecSectionPosition> byKey = new HashMap<>();
        for (SpecSectionPosition p : theirs) {
          String k = pairKey(p, target, candidates);
          if (byKey.containsKey(k)) {
            throw unpairable(className);
          }
          byKey.put(k, p);
        }
        for (SpecSectionPosition p : mine) {
          String k = pairKey(p, bp, candidates);
          SpecSectionPosition q = byKey.remove(k);
          if (q == null) {
            throw unpairable(className);
          }
          matched.add(new SpecSectionPosition[] {p, q});
        }
        if (!byKey.isEmpty()) {
          throw unpairable(className);
        }
      }
      SpecClass cls = refl.classNamed(className);
      String sectionId =
          cls.sectionId == null || cls.sectionId.isEmpty() ? className : cls.sectionId;
      for (SpecSectionPosition[] m : matched) {
        out.add(new SpecSyncPair(className, sectionId, m[0].path, m[1].path, target, cls.syncedWith()));
      }
    }
    return out;
  }

  // --- the report -------------------------------------------------------------

  /** The validation of {@code set}, with counts, every pair. Writes nothing. */
  public static SpecSyncReport syncReport(SpecDocumentSet set) {
    return syncReport(set, null);
  }

  /**
   * The validation of {@code set}, with counts; {@code pairs} (non-null) keeps
   * the findings of those pairs (by section id) only. Writes nothing.
   */
  public static SpecSyncReport syncReport(SpecDocumentSet set, List<String> pairs) {
    Set<String> scope = pairScope(pairs);
    SpecSetCheck c = new SpecSetCheck(set);
    int index = 0;
    for (SpecSyncPair p : set.pairs()) {
      if (scope == null || scope.contains(p.sectionId)) {
        c.comparePair(p, index);
      }
      index++;
    }
    c.crossChecks(scope, index);
    if (scope == null) {
      c.pendingScan(index + 1);
      c.unmarkableScan(index + 2);
    }
    c.sortOut();
    List<SpecDocumentFindings> documentFindings = new ArrayList<>();
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      List<SpecValidationError> errors = new ArrayList<>(SpecValidator.validateDocument(set.model, doc));
      errors.addAll(SpecValidator.validateLinks(set.model, doc));
      documentFindings.add(new SpecDocumentFindings(name, errors));
    }
    List<SpecSyncFinding> findings = new ArrayList<>();
    for (SpecSetFound o : c.out) {
      findings.add(o.finding);
    }
    return new SpecSyncReport(findings, documentFindings, set.missingRoots(), c.notStartedPairs);
  }

  /** A set of pair section ids, {@code null} for every pair. */
  static Set<String> pairScope(List<String> pairs) {
    return pairs == null ? null : new HashSet<>(pairs);
  }

  // --- the global rename ------------------------------------------------------

  static List<String> allItems(SpecDocument doc) {
    List<String> out = new ArrayList<>();
    for (String lst : new TreeSet<>(doc.listPaths())) {
      out.addAll(doc.listItems(lst));
    }
    return out;
  }

  private static boolean idChar(char ch) {
    return ch == '-' || (ch >= '0' && ch <= '9') || (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
  }

  /**
   * {@code v} with every whole-token occurrence of {@code from} (no letter,
   * digit or hyphen on either side) replaced by {@code to}; {@code null} when
   * there is none.
   */
  static String replaceToken(String v, String from, String to) {
    if (from.isEmpty()) {
      return null;
    }
    StringBuilder out = new StringBuilder();
    boolean found = false;
    int i = 0;
    while (i < v.length()) {
      if (v.startsWith(from, i)
          && (i == 0 || !idChar(v.charAt(i - 1)))
          && (i + from.length() >= v.length() || !idChar(v.charAt(i + from.length())))) {
        out.append(to);
        i += from.length();
        found = true;
        continue;
      }
      out.append(v.charAt(i));
      i++;
    }
    return found ? out.toString() : null;
  }

  /**
   * Renames the section id {@code from} to {@code to} in every document of
   * {@code set} at once (DP-part-cleanup-2): the list element carrying it, and
   * every value naming it as a whole token (references, comma-separated lists,
   * the texts link rows are extracted from). Refused with a
   * {@link SpecRenameError}, nothing changed, when an element of any document
   * already carries {@code to}. Returns the changes, in document and path order.
   */
  public static List<SpecRenameChange> renameId(SpecDocumentSet set, String from, String to) {
    SpecSetCheck c = new SpecSetCheck(set);
    List<String> holders = new ArrayList<>();
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      for (String i : allItems(doc)) {
        if (c.itemId(doc, i).equals(to)) {
          holders.add(name);
          break;
        }
      }
    }
    if (!holders.isEmpty()) {
      throw new SpecRenameError(
          holders, to + " is already an id in " + String.join(", ", holders));
    }
    List<SpecRenameChange> changes = new ArrayList<>();
    for (String name : set.names()) {
      SpecDocument doc = set.get(name);
      for (String item : allItems(doc)) {
        if (!c.itemId(doc, item).equals(from)) {
          continue;
        }
        doc.setItemSectionId(item, to);
        changes.add(new SpecRenameChange(name, item, SpecRenameChange.SECTION_ID, from, to, null));
      }
      for (String p : new TreeSet<>(doc.contentPaths())) {
        String v = doc.content(p);
        String n = replaceToken(v, from, to);
        if (n == null) {
          continue;
        }
        doc.setContent(p, n);
        changes.add(new SpecRenameChange(name, p, SpecRenameChange.VALUE, v, n, null));
      }
      for (String p : new TreeSet<>(doc.formPaths())) {
        for (String f : new TreeSet<>(doc.formFieldNames(p))) {
          String v = doc.formField(p, f);
          String n = replaceToken(v, from, to);
          if (n == null) {
            continue;
          }
          doc.setFormField(p, f, n);
          changes.add(new SpecRenameChange(name, p, SpecRenameChange.VALUE, v, n, f));
        }
      }
    }
    return changes;
  }
}
