package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * SpecDocumentMarkdownLinked — navigation between linked places of a
 * rendition (SOM §11.2 qualified anchors, SOM §11.11 the {@code linked}
 * marker), a port of the Go runtime's {@code spec_document_markdown_linked.go}
 * (itself a port of the Python, JavaScript, TypeScript and Dart runtimes'
 * {@code spec_document_markdown_linked}).
 *
 * <p>One instance is one root's navigation: the anchor of the heading a path
 * names, the markable places, the marker's entries in the order of SOM §11.11
 * (Also in, Summary of, Summarised in, Derived from, Extracted from, Copy of,
 * Copied to) and the summary rows' {@code Id} link cells. Both anchors and
 * marker are written from the model and the document's own values, and
 * nothing of either is stored: the parser removes the anchors and the marker.
 *
 * <p>Internal to {@link SpecDocumentMarkdown}.
 */
final class SpecDocumentMarkdownLinked {
  /**
   * Written by the emitter where a markable place has no entry: replaced by
   * {@code []{.linked}} when the value written after it begins with a
   * {@code linked} span, else removed with its blank line (SOM §11.11).
   */
  static final String LINKED_PLACEHOLDER = "\u0000linked\u0000";

  /**
   * A path walked through a tree: the anchor and id of the heading it ends
   * at, that heading's path, the path as a pattern (items {@code <list>-*}),
   * the items' ids on the way and the node reached ({@code null}: not reached).
   */
  static final class Walk {
    final String anchor;
    final String headingId;
    final String headingPath;
    final String pattern;
    final List<String> itemIds;
    final SomMetaNode node;

    Walk(String anchor, String headingId, String headingPath, String pattern,
        List<String> itemIds, SomMetaNode node) {
      this.anchor = anchor;
      this.headingId = headingId;
      this.headingPath = headingPath;
      this.pattern = pattern;
      this.itemIds = itemIds;
      this.node = node;
    }
  }

  /**
   * One side of a {@code @SyncedWith} pair: its anchor here, the other root,
   * the anchor there, whether this side holds the values, the sync.
   */
  private static final class Side {
    final String mine;
    final SpecRoot other;
    final String theirs;
    final boolean holder;
    final SpecSync sync;

    Side(String mine, SpecRoot other, String theirs, boolean holder, SpecSync sync) {
      this.mine = mine;
      this.other = other;
      this.theirs = theirs;
      this.holder = holder;
      this.sync = sync;
    }
  }

  /**
   * One derived value at a heading: a link to a source ({@code null}: none)
   * and the derived field's name ({@code null}: a derived section).
   */
  private static final class DerivedSource {
    final String link;
    final String field;

    DerivedSource(String link, String field) {
      this.link = link;
      this.field = field;
    }
  }

  /**
   * A detail element a summary element names: its id, its anchor and the
   * other root it is in ({@code null}: this document).
   */
  private static final class SummaryTarget {
    final String id;
    final String anchor;
    final SpecRoot other;

    SummaryTarget(String id, String anchor, SpecRoot other) {
      this.id = id;
      this.anchor = anchor;
      this.other = other;
    }
  }

  /** An item path's list path and segment. */
  static final class ItemParts {
    final String listPath;
    final String segment;

    ItemParts(String listPath, String segment) {
      this.listPath = listPath;
      this.segment = segment;
    }
  }

  final SpecDocumentMarkdown codec;
  final SpecRoot root;
  final SpecReflection refl;
  final SomMetaTree tree;

  private final Map<String, Walk> walks = new HashMap<>();
  private List<Side> sides;
  private List<SpecSameAsBinding> sameAs;
  private Map<String, List<String>> detailLists;
  private final Map<String, Boolean> markables = new HashMap<>();
  private Map<String, List<String>> summaryMap;

  SpecDocumentMarkdownLinked(SpecDocumentMarkdown codec, SpecRoot root, SomMetaTree tree) {
    this.codec = codec;
    this.root = root;
    this.refl = new SpecReflection(codec.model);
    this.tree = tree;
  }

  SpecDocument doc() {
    return codec.document;
  }

  String rootSeg() {
    return refl.rootSegment(root);
  }

  // --- small helpers ---------------------------------------------------------

  /** {@code path} cut before its first {@code <list>-*} segment: that list's path. */
  static String cutPattern(String path) {
    int i = path.indexOf("-*");
    return i >= 0 ? path.substring(0, i) : path;
  }

  /** An item pattern's list pattern ({@code a/L-*} → {@code a/L}). */
  static String listPatternOf(String itemPattern) {
    return itemPattern.endsWith("-*")
        ? itemPattern.substring(0, itemPattern.length() - 2)
        : itemPattern;
  }

  private static void addUnique(List<String> out, String v) {
    if (!out.contains(v)) {
      out.add(v);
    }
  }

  private static String ownerOf(String path) {
    return path.substring(0, path.lastIndexOf('/'));
  }

  private static boolean isEmpty(String s) {
    return s == null || s.isEmpty();
  }

  // --- anchors ---------------------------------------------------------------

  /**
   * The heading id of the item at {@code itemPath} of {@code listNode} in
   * {@code d} ({@code null}: no document), as the emitter writes it.
   */
  String itemId(SpecDocument d, SomMetaNode listNode, String itemPath) {
    int slash = itemPath.lastIndexOf('/');
    SpecPaths.ListItemSegment split =
        SpecPaths.splitListItemSegment(itemPath.substring(slash + 1));
    int seq = split == null ? 0 : split.seq;
    String base = split == null ? itemPath.substring(slash + 1) : split.base;
    String listPath = itemPath.substring(0, slash + 1) + base;
    int pos = 0;
    String stored = null;
    if (d != null) {
      pos = d.listItems(listPath).indexOf(itemPath) + 1;
      stored = d.itemSectionId(itemPath);
    }
    if (pos == 0) {
      pos = seq;
    }
    return SpecSectionId.effectiveListItemSectionId(
        stored,
        SpecDocumentMarkdown.itemPatternOf(listNode),
        pos,
        SpecDocumentMarkdown.memberStemOf(listNode));
  }

  /**
   * Walks {@code path} (concrete, or a pattern whose {@code <list>-*}
   * segments take {@code ids} in order) through {@code inTree} ({@code null}:
   * this root's), the items' ids read from {@code d}.
   */
  Walk walk(String path, SomMetaTree inTree, SpecDocument d, List<String> ids) {
    SomMetaTree t = inTree == null ? tree : inTree;
    boolean cacheable = inTree == null && (ids == null || ids.isEmpty()) && d == doc();
    if (cacheable) {
      Walk hit = walks.get(path);
      if (hit != null) {
        return hit;
      }
    }
    List<String> queue = ids == null ? new ArrayList<>() : new ArrayList<>(ids);
    String[] segs = path.split("/", -1);
    SomMetaNode node = t.root;
    String cur = segs[0];
    StringBuilder pattern = new StringBuilder(segs[0]);
    String anchor = node.segment();
    String headingId = node.segment();
    String headingPath = cur;
    List<String> scope = null;
    String section = node.segment();
    List<String> itemIds = new ArrayList<>();
    SomMetaNode reached = node;
    for (int i = 1; i < segs.length; i++) {
      String seg = segs[i];
      SomMetaNode child = node.childBySegment(seg);
      if (child != null) {
        cur = cur + "/" + seg;
        pattern.append('/').append(seg);
        node = child;
        reached = child;
        if (codec.isTransparentSection(child) || SpecDocumentMarkdown.isTransparentValue(child)) {
          continue;
        }
        String id = codec.headingIdOf(child);
        boolean container = SomMetaKind.LIST.equals(child.kind);
        SpecDocumentMarkdown.AnchorRole role = container
            ? SpecDocumentMarkdown.AnchorRole.CONTAINER
            : (codec.isCopyNode(child)
                ? SpecDocumentMarkdown.AnchorRole.COPY
                : SpecDocumentMarkdown.AnchorRole.PLAIN);
        SpecDocumentMarkdown.QualifiedAnchor q =
            SpecDocumentMarkdown.qualifyAnchor(scope, section, id, role);
        anchor = q.anchor;
        scope = q.scope;
        headingId = id;
        headingPath = cur;
        if (!container) {
          section = id;
        }
        continue;
      }
      boolean star = seg.endsWith("-*");
      String base;
      boolean ok = true;
      if (star) {
        base = seg.substring(0, seg.length() - 2);
      } else {
        SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
        base = split == null ? "" : split.base;
        ok = split != null;
      }
      SomMetaNode listNode = ok ? node.childBySegment(base) : null;
      if (listNode == null || !SomMetaKind.LIST.equals(listNode.kind)) {
        reached = null;
        break;
      }
      String itemPath = cur + "/" + seg;
      String id = "";
      if (star) {
        if (!queue.isEmpty()) {
          id = queue.remove(0);
        }
      } else {
        id = itemId(d, listNode, itemPath);
      }
      itemIds.add(id);
      SpecDocumentMarkdown.QualifiedAnchor q =
          SpecDocumentMarkdown.qualifyAnchor(
              scope, section, id, SpecDocumentMarkdown.AnchorRole.ITEM);
      anchor = q.anchor;
      scope = q.scope;
      headingId = id;
      section = id;
      cur = itemPath;
      headingPath = itemPath;
      pattern.append('/').append(base).append("-*");
      SomMetaNode element = listNode.elementNode;
      node = element != null ? element : listNode;
      reached = node;
      if (element == null && i < segs.length - 1) {
        reached = null;
        break;
      }
    }
    Walk w = new Walk(anchor, headingId, headingPath, pattern.toString(), itemIds, reached);
    if (cacheable) {
      walks.put(path, w);
    }
    return w;
  }

  /** The anchor of the heading {@code path} names in this document. */
  String anchorOf(String path) {
    return walk(path, null, doc(), null).anchor;
  }

  // --- the model's links, per root -------------------------------------------

  /** The model's root of type {@code t}, or {@code null}. */
  private SpecRoot rootOfType(String t) {
    for (SpecRoot r : codec.model.roots) {
      if (r.type.equals(t)) {
        return r;
      }
    }
    return null;
  }

  /** Every {@code @SyncedWith} pair this root is a side of. */
  private List<Side> allSides() {
    if (sides != null) {
      return sides;
    }
    sides = new ArrayList<>();
    String bp = codec.syncBlueprint();
    if (bp == null || bp.isEmpty()) {
      return sides;
    }
    for (SpecSyncPair p : codec.syncPairList()) {
      if (p.sync == null) {
        continue;
      }
      if (root.type.equals(bp)) {
        SpecRoot other = rootOfType(p.detailRoot);
        if (other != null) {
          sides.add(new Side(p.blueprintAnchor, other, p.detailAnchor, false, p.sync));
        }
      } else if (root.type.equals(p.detailRoot)) {
        SpecRoot other = rootOfType(bp);
        if (other != null) {
          sides.add(new Side(p.detailAnchor, other, p.blueprintAnchor, true, p.sync));
        }
      }
    }
    return sides;
  }

  /** The {@code @SameAs} copies of this root with their holders. */
  private List<SpecSameAsBinding> sameAsBindings() {
    if (sameAs == null) {
      sameAs = SpecPlace.sameAsBindings(refl, root.type);
    }
    return sameAs;
  }

  private boolean underCopy(String pattern) {
    for (SpecSameAsBinding b : sameAsBindings()) {
      if (pattern.equals(b.copyPath) || pattern.startsWith(b.copyPath + "/")) {
        return true;
      }
    }
    return false;
  }

  /**
   * The side whose shared list {@code listPattern} is: the innermost pair
   * anchor holding it, when the list lies directly beneath it (not below an
   * item of it), outside a copy and outside the pair's {@code detailOnly}
   * places.
   */
  private Side sharedListSide(String listPattern, String concreteList) {
    if (underCopy(listPattern)) {
      return null;
    }
    Side best = null;
    for (Side s : allSides()) {
      if (!listPattern.startsWith(s.mine + "/")) {
        continue;
      }
      if (best == null || s.mine.length() > best.mine.length()) {
        best = s;
      }
    }
    if (best == null) {
      return null;
    }
    String rel = listPattern.substring(best.mine.length() + 1);
    if (rel.contains("-*")) {
      return null;
    }
    // The anchor's concrete path: the list's as long as the anchor is.
    int depth = best.mine.split("/", -1).length;
    String[] parts = concreteList.split("/", -1);
    if (depth < parts.length) {
      parts = Arrays.copyOf(parts, depth);
    }
    String anchor = String.join("/", parts);
    if (best.sync.detailOnly != null) {
      for (String place : best.sync.detailOnly) {
        SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(refl, place, anchor);
        if (r == null) {
          continue;
        }
        String p = walk(r.path, null, doc(), null).pattern;
        if (listPattern.equals(p) || listPattern.startsWith(p + "/")) {
          return null;
        }
      }
    }
    return best;
  }

  /** The {@code @SummaryOf} of the list member at {@code listPath}, or {@code null}. */
  private SpecSummaryOf summaryOfList(String listPath) {
    SpecResolution r = refl.resolve(listPath);
    if (r == null || r.field == null) {
      return null;
    }
    return r.field.summaryOf();
  }

  /** Whether a summary names its detail elements in this document. */
  private boolean sameDocument(SpecSummaryOf s) {
    return isEmpty(s.document) || s.document.equals(root.type);
  }

  /**
   * Detail-list pattern → the summary lists (patterns) of this document naming
   * its elements, in insertion order.
   */
  private Map<String, List<String>> detailListsMap() {
    if (detailLists != null) {
      return detailLists;
    }
    Map<String, List<String>> out = new LinkedHashMap<>();
    for (SomMetaNode node : tree.allNodes()) {
      String np = node.path();
      if (!SomMetaKind.LIST.equals(node.kind) || isEmpty(np)) {
        continue;
      }
      SpecSummaryOf s = summaryOfList(np);
      if (s == null || !sameDocument(s)) {
        continue;
      }
      SpecPlaceResolution r =
          SpecLinkValidator.resolveLinkPlace(refl, null, s.detail, rootSeg(), ownerOf(np));
      if (r == null) {
        continue;
      }
      String key = walk(cutPattern(r.path), null, doc(), null).pattern;
      out.computeIfAbsent(key, k -> new ArrayList<>()).add(np);
    }
    detailLists = out;
    return out;
  }

  // --- markable places (structural: the parser and the emitter agree) -------

  /**
   * Whether the heading at {@code path} carries one of the links of SOM
   * §11.11: a {@code @SyncedWith} anchor or an element of one of its shared
   * lists, an element of a summary list or of a detail list a summary of this
   * document names, a heading holding a derived value, a list of link rows
   * extracted from text, a {@code @SameAs} copy or its holder.
   */
  boolean markable(String path) {
    Boolean v = markables.get(path);
    if (v == null) {
      v = computeMarkable(path);
      markables.put(path, v);
    }
    return v;
  }

  private boolean computeMarkable(String path) {
    Walk w = walk(path, null, doc(), null);
    SomMetaNode node = w.node;
    if (node == null || !w.headingPath.equals(path)) {
      return false;
    }
    String pattern = w.pattern;
    for (Side s : allSides()) {
      if (s.mine.equals(pattern)) {
        return true;
      }
    }
    ItemParts item = itemParts(path);
    if (item != null) {
      String listPattern = listPatternOf(pattern);
      if (sharedListSide(listPattern, item.listPath) != null) {
        return true;
      }
      if (summaryOfList(item.listPath) != null) {
        return true;
      }
      if (detailListsMap().get(listPattern) != null) {
        return true;
      }
    }
    if (!derivedSources(path, node, true, false).isEmpty()) {
      return true;
    }
    if (SomMetaKind.LIST.equals(node.kind) && !extractFrom(path).isEmpty()) {
      return true;
    }
    for (SpecSameAsBinding b : sameAsBindings()) {
      if (pattern.equals(b.copyPath) || pattern.equals(b.holderPath)) {
        return true;
      }
    }
    return false;
  }

  /** For an item path, its list's path and its segment; {@code null} otherwise. */
  ItemParts itemParts(String path) {
    int slash = path.lastIndexOf('/');
    if (slash < 0) {
      return null;
    }
    String seg = path.substring(slash + 1);
    SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
    if (split == null) {
      return null;
    }
    String parent = path.substring(0, slash);
    SomMetaNode parentNode = tree.byPath(parent);
    if (parentNode != null && parentNode.childBySegment(seg) != null) {
      return null;
    }
    String listPath = parent + "/" + split.base;
    SomMetaNode listNode = tree.byPath(listPath);
    if (listNode == null || !SomMetaKind.LIST.equals(listNode.kind)) {
      return null;
    }
    return new ItemParts(listPath, seg);
  }

  // --- the marker ------------------------------------------------------------

  /**
   * A link to {@code anchor} in {@code other} ({@code null}: this document),
   * its text {@code id} prefixed by the other root's id.
   */
  private String link(String id, String anchor, SpecRoot other) {
    if (other == null) {
      return "[" + id + "](#" + anchor + ")";
    }
    String name = isEmpty(other.sectionId) ? other.type : other.sectionId;
    return "[" + name + " " + id + "](" + codec.fileOfRoot(other) + "#" + anchor + ")";
  }

  private static String note(Side s) {
    String held = s.holder ? "held here" : "held there";
    if (s.sync.heldHere == null || s.sync.heldHere.isEmpty()) {
      return held;
    }
    return held + " except " + String.join(", ", s.sync.heldHere);
  }

  /**
   * The marker's entries at the heading {@code path}, in the order of SOM
   * §11.11; empty when {@code path} is not markable or carries no link this
   * time. {@code sectionTable}: the heading's children are written as a
   * section table.
   */
  List<String> entries(String path, boolean sectionTable) {
    List<String> out = new ArrayList<>();
    if (!markable(path)) {
      return out;
    }
    Walk w = walk(path, null, doc(), null);
    SomMetaNode node = w.node;
    String pattern = w.pattern;

    // Also in (@SyncedWith).
    for (Side s : allSides()) {
      if (!s.mine.equals(pattern)) {
        continue;
      }
      SomMetaTree otherTree = codec.treeFor(s.other.type);
      Walk there = walk(s.theirs, otherTree, null, w.itemIds);
      out.add("Also in " + link(w.headingId, there.anchor, s.other) + ", " + note(s));
    }
    ItemParts item = itemParts(path);
    if (item != null) {
      String listPattern = listPatternOf(pattern);
      Side side = sharedListSide(listPattern, item.listPath);
      if (side != null) {
        SomMetaTree otherTree = codec.treeFor(side.other.type);
        String rel = listPattern.substring(side.mine.length());
        Walk there = walk(side.theirs + rel + "-*", otherTree, null, w.itemIds);
        out.add("Also in " + link(w.headingId, there.anchor, side.other) + ", " + note(side));
      }

      // Summary of (@SummaryOf on the list).
      SpecSummaryOf summary = summaryOfList(item.listPath);
      if (summary != null) {
        List<String> links = new ArrayList<>();
        for (SummaryTarget t : summaryTargets(path, item.listPath, w.headingId, summary)) {
          links.add(link(t.id, t.anchor, t.other));
        }
        if (!links.isEmpty()) {
          out.add("Summary of " + String.join(", ", links));
        }
      }

      // Summarised in: the summary elements of this document naming it.
      List<String> named = summaryLinks().get(item.listPath + "#" + w.headingId);
      if (named != null) {
        out.add("Summarised in " + String.join(", ", named));
      }
    }

    // Derived from.
    List<DerivedSource> derived = derivedSources(path, node, false, sectionTable);
    if (!derived.isEmpty()) {
      List<String> dlinks = new ArrayList<>();
      List<String> fields = new ArrayList<>();
      for (DerivedSource d : derived) {
        if (!isEmpty(d.link)) {
          addUnique(dlinks, d.link);
        }
        if (!isEmpty(d.field)) {
          addUnique(fields, d.field);
        }
      }
      if (!dlinks.isEmpty()) {
        String entry = "Derived from " + String.join(", ", dlinks);
        if (!fields.isEmpty()) {
          entry += ": " + String.join(", ", fields);
        }
        out.add(entry);
      }
    }

    // Extracted from (@ExtractsLinks, generate).
    if (SomMetaKind.LIST.equals(node.kind)) {
      List<String> from = extractFrom(path);
      if (!from.isEmpty()) {
        out.add("Extracted from " + String.join(", ", from));
      }
    }

    // Copy of / Copied to (@SameAs).
    for (SpecSameAsBinding b : sameAsBindings()) {
      if (!pattern.equals(b.copyPath) || isEmpty(b.holderPath)) {
        continue;
      }
      Walk h = walk(b.holderPath, null, doc(), w.itemIds);
      out.add("Copy of " + link(h.headingId, h.anchor, null) + ", edit it there");
    }
    List<String> copies = new ArrayList<>();
    for (SpecSameAsBinding b : sameAsBindings()) {
      if (!pattern.equals(b.holderPath)) {
        continue;
      }
      Walk c = walk(b.copyPath, null, doc(), w.itemIds);
      copies.add(link(c.headingId, c.anchor, null));
    }
    if (!copies.isEmpty()) {
      out.add("Copied to " + String.join(", ", copies));
    }
    return out;
  }

  /**
   * {@code <detail list path>#<element id>} → the links to the summary
   * elements of this document naming that element, in document order.
   */
  private Map<String, List<String>> summaryLinks() {
    if (summaryMap != null) {
      return summaryMap;
    }
    Map<String, List<String>> out = new HashMap<>();
    List<String> summaries = new ArrayList<>();
    for (List<String> lists : detailListsMap().values()) {
      for (String l : lists) {
        addUnique(summaries, l);
      }
    }
    SpecDocument doc = doc();
    for (String summaryList : summaries) {
      for (String concrete : SpecLinkValidator.expandPattern(doc, summaryList)) {
        SpecSummaryOf s = summaryOfList(concrete);
        if (s == null) {
          continue;
        }
        SpecPlaceResolution r =
            SpecLinkValidator.resolveLinkPlace(refl, doc, s.detail, rootSeg(), ownerOf(concrete));
        if (r == null) {
          continue;
        }
        String detail = cutPattern(r.path);
        for (String e : doc.listItems(concrete)) {
          Walk ew = walk(e, null, doc, null);
          for (String id : summaryIds(e, s, ew.headingId)) {
            addUnique(
                out.computeIfAbsent(detail + "#" + id, k -> new ArrayList<>()),
                link(ew.headingId, ew.anchor, null));
          }
        }
      }
    }
    summaryMap = out;
    return out;
  }

  /** The ids summary element {@code element} names: its {@code match} field's ids, else its own. */
  private List<String> summaryIds(String element, SpecSummaryOf s, String ownId) {
    List<String> out = new ArrayList<>();
    if (isEmpty(s.match)) {
      out.add(ownId);
      return out;
    }
    SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(refl, s.match, element);
    if (r == null || isEmpty(r.field())) {
      return out;
    }
    String raw = doc().formField(r.path, r.field());
    if (raw == null) {
      return out;
    }
    for (String x : raw.split(",", -1)) {
      String id = x.trim();
      if (!id.isEmpty()) {
        out.add(id);
      }
    }
    return out;
  }

  /** The detail elements summary element {@code element} of {@code listPath} names. */
  private List<SummaryTarget> summaryTargets(
      String element, String listPath, String ownId, SpecSummaryOf s) {
    List<SummaryTarget> out = new ArrayList<>();
    List<String> ids = summaryIds(element, s, ownId);
    if (ids.isEmpty()) {
      return out;
    }
    String owner = ownerOf(listPath);
    if (sameDocument(s)) {
      SpecPlaceResolution r =
          SpecLinkValidator.resolveLinkPlace(refl, doc(), s.detail, rootSeg(), owner);
      if (r == null) {
        return out;
      }
      String list = cutPattern(r.path);
      for (String id : ids) {
        out.add(new SummaryTarget(id, walk(list + "-*", null, doc(), List.of(id)).anchor, null));
      }
      return out;
    }
    SpecRoot other = rootOfType(s.document);
    if (other == null) {
      return out;
    }
    String otherSeg = refl.rootSegment(other);
    SpecPlaceResolution r =
        SpecLinkValidator.resolveLinkPlace(refl, null, s.detail, otherSeg, otherSeg);
    for (String id : ids) {
      String anchor = id;
      if (r != null && !r.path.contains("-*")) {
        SomMetaTree otherTree = codec.treeFor(other.type);
        anchor = walk(r.path + "-*", otherTree, null, List.of(id)).anchor;
      }
      out.add(new SummaryTarget(id, anchor, other));
    }
    return out;
  }

  /**
   * The {@code Id} cell of a records row standing for summary element
   * {@code item} of {@code listPath} whose {@code @SummaryOf} has no
   * {@code match} (SOM §11.5, §11.11): its anchor, then its id as a link to the
   * detail element it names. {@code null} when the list is no such summary.
   */
  String summaryIdCell(String item, String listPath, String id) {
    SpecSummaryOf s = summaryOfList(listPath);
    if (s == null || !isEmpty(s.match)) {
      return null;
    }
    List<SummaryTarget> targets = summaryTargets(item, listPath, id, s);
    if (targets.isEmpty()) {
      return null;
    }
    // Without `match` a summary element names exactly one detail element.
    SummaryTarget t = targets.get(0);
    String href = t.other == null ? "#" + t.anchor : codec.fileOfRoot(t.other) + "#" + t.anchor;
    return "<a id=\"" + anchorOf(item) + "\"></a>[" + id + "](" + href + ")";
  }

  /**
   * The derived values at the heading {@code path}: a link to a source and the
   * derived field's name per source. {@code probe}: answer whether there is
   * any, structurally (no links built).
   */
  private List<DerivedSource> derivedSources(
      String path, SomMetaNode node, boolean probe, boolean sectionTable) {
    SpecDocument doc = doc();
    List<DerivedSource> out = new ArrayList<>();
    boolean isItem = itemParts(path) != null;
    if (SomMetaKind.FORM.equals(node.kind)) {
      form(out, path, null, probe);
    }
    if (!isItem && path.contains("/")) {
      member(out, path, null, probe);
    }
    if (SomMetaKind.SECTION.equals(node.kind) || SomMetaKind.COMPLEX.equals(node.kind) || isItem) {
      for (SpecDocumentMarkdown.NodeRel slot : codec.bodySlots(node)) {
        String slotPath = path + "/" + slot.rel;
        if (SomMetaKind.FORM.equals(slot.node.kind)) {
          form(out, slotPath, null, probe);
        } else {
          String name = isEmpty(slot.node.memberName) ? slot.node.segment() : slot.node.memberName;
          member(out, slotPath, name, probe);
        }
      }
      if (sectionTable || probe) {
        for (SpecDocumentMarkdown.NodeRel child : codec.effectiveChildren(node)) {
          if (!SomMetaKind.FORM.equals(child.node.kind)) {
            continue;
          }
          if (probe || doc.hasValuesUnder(path + "/" + child.rel)) {
            form(out, path + "/" + child.rel, codec.headingIdOf(child.node), probe);
          }
        }
      }
    }
    return out;
  }

  /** A link to the heading {@code target} names. */
  private String linkTo(String target) {
    Walk t = walk(cutPattern(target), null, doc(), null);
    return link(t.headingId, t.anchor, null);
  }

  /** A link to the source {@code place} of a link annotated at {@code owner}. */
  private String source(String place, String owner, boolean probe) {
    if (probe) {
      return null;
    }
    SpecPlaceResolution r = SpecLinkValidator.resolveLinkPlace(refl, doc(), place, rootSeg(), owner);
    return r == null ? null : linkTo(r.path);
  }

  /** The derived form fields of the form at {@code formPath}. */
  private void form(List<DerivedSource> out, String formPath, String prefix, boolean probe) {
    String owner = ownerOf(formPath);
    SpecResolution res = refl.resolve(formPath);
    if (res == null || res.field == null || res.field.formFields == null) {
      return;
    }
    for (FormFieldSpec ff : res.field.formFields) {
      String name = prefix == null ? ff.name : prefix + "." + ff.name;
      if (ff.derivedFrom != null) {
        out.add(new DerivedSource(source(ff.derivedFrom.source, owner, probe), name));
      }
      if (ff.countOf != null) {
        for (String t : ff.countOf) {
          SpecPlaceFilter f = SpecPlaceFilter.tryParse(t);
          if (f == null) {
            continue;
          }
          String place = f.scoped ? "./" + f.sectionId : f.sectionId;
          out.add(new DerivedSource(source(place, owner, probe), name));
        }
      }
      if (ff.productOf != null) {
        for (String operand : ff.productOf) {
          String l = null;
          if (!probe) {
            int dot = operand.indexOf('.');
            l = dot < 0 ? linkTo(formPath) : linkTo(owner + "/" + operand.substring(0, dot));
          }
          out.add(new DerivedSource(l, name));
        }
      }
      if (!isEmpty(ff.rankOf)) {
        String l = null;
        if (!probe) {
          ItemParts item = itemParts(owner);
          l = item != null ? linkTo(item.listPath) : linkTo(formPath);
        }
        out.add(new DerivedSource(l, name));
      }
    }
  }

  /**
   * A member carrying {@code @DerivedFrom}: {@code name} for one written in
   * its owner's body (no heading of its own), {@code null} for the heading
   * itself.
   */
  private void member(List<DerivedSource> out, String memberPath, String name, boolean probe) {
    SpecResolution res = refl.resolve(memberPath);
    if (res == null || res.field == null) {
      return;
    }
    SpecDerivation d = res.field.derivedFrom();
    if (d == null) {
      return;
    }
    out.add(new DerivedSource(source(d.source, ownerOf(memberPath), probe), name));
  }

  /**
   * The {@code Extracted from} links of the link-row list at {@code path}: the
   * text places of its {@code @ExtractsLinks} in {@code generate} mode.
   */
  private List<String> extractFrom(String path) {
    List<String> out = new ArrayList<>();
    SpecResolution res = refl.resolve(path);
    if (res == null || res.field == null) {
      return out;
    }
    String owner = ownerOf(path);
    for (SpecExtractsLinks e : res.field.extractsLinks()) {
      if (!"generate".equals(e.mode) || e.from == null) {
        continue;
      }
      for (String place : e.from) {
        SpecPlaceResolution r = SpecLinkValidator.resolveLinkPlace(refl, doc(), place, rootSeg(), owner);
        if (r == null) {
          continue;
        }
        Walk t = walk(cutPattern(r.path), null, doc(), null);
        addUnique(out, link(t.headingId, t.anchor, null));
      }
    }
    return out;
  }

  // --- the marker as text ----------------------------------------------------

  /** Whether {@code paragraph} is exactly one span of kind {@code linked}. */
  static boolean isLinkedParagraph(String paragraph) {
    String text = paragraph.trim();
    if (!text.startsWith("[") || !text.endsWith("{.linked}")) {
      return false;
    }
    NotationScan scan = SpecNotation.scanNotation(text, false);
    if (scan.elements.size() != 1) {
      return false;
    }
    NotationElement e = scan.elements.get(0);
    return "span".equals(e.type) && "linked".equals(e.kind) && e.start == 0 && e.end == text.length();
  }

  private static boolean isBlank(String line) {
    return line.trim().isEmpty();
  }

  /**
   * {@code markdown} with every placeholder resolved: {@code []{.linked}}
   * where the paragraph after it is a {@code linked} span, else removed with
   * its blank line.
   */
  static String resolveLinkedPlaceholders(String markdown) {
    if (!markdown.contains(LINKED_PLACEHOLDER)) {
      return markdown;
    }
    String[] lines = markdown.split("\n", -1);
    List<String> out = new ArrayList<>(lines.length);
    for (int i = 0; i < lines.length; ) {
      if (!lines[i].equals(LINKED_PLACEHOLDER)) {
        out.add(lines[i]);
        i++;
        continue;
      }
      // The placeholder, its blank line, then the paragraph that follows.
      int k = i + 1;
      while (k < lines.length && isBlank(lines[k])) {
        k++;
      }
      int j = k;
      while (j < lines.length && !isBlank(lines[j])) {
        j++;
      }
      if (j > k && isLinkedParagraph(String.join("\n", Arrays.asList(lines).subList(k, j)))) {
        out.add("[]{.linked}");
        i++;
      } else {
        i += 2; // the blank line after the placeholder goes with it
      }
    }
    return String.join("\n", out);
  }
}
