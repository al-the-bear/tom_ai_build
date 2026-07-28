package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

/**
 * The metadata tree of one document root: parent/path wiring plus the two
 * dynamic lookups ({@link #byId}, {@link #byPath}) SOM §10 requires every
 * runtime to keep — a faithful port of {@code spec_meta.dart} /
 * {@code spec_meta.ts}.
 */
public final class SomMetaTree {
  /** The document root node (carries {@link SomMetaNode#document}). */
  public final SomMetaNode root;

  private final Map<String, List<SomMetaNode>> byIdIndex = new LinkedHashMap<>();
  private final List<SomMetaNode> allNodes = new ArrayList<>();

  /**
   * Wires {@code root}'s subtree: sets parent links, computes static paths,
   * and indexes section ids.
   *
   * @throws IllegalStateException when {@code root} carries no
   *     {@code @Document} metadata, and when any node is already attached to
   *     another tree (nodes belong to exactly one tree).
   */
  public SomMetaTree(SomMetaNode root) {
    if (root.document == null) {
      throw new IllegalStateException(
          "the tree root must carry @Document metadata "
              + "(SomMetaNode.document): " + root.debugName());
    }
    this.root = root;
    wire(root, null, root.segment());
  }

  private void wire(SomMetaNode node, SomMetaNode parent, String path) {
    if (node.wiredTree != null) {
      throw new IllegalStateException(
          "SomMetaNode(" + node.debugName() + ") is already attached to a "
              + "SomMetaTree; nodes belong to exactly one tree");
    }
    node.wiredTree = this;
    node.wiredParent = parent;
    node.wiredPath = path;
    allNodes.add(node);
    String id = node.sectionId;
    if (id != null && !id.isEmpty()) {
      byIdIndex.computeIfAbsent(id, k -> new ArrayList<>()).add(node);
    }
    for (SomMetaNode child : node.children) {
      String childPath = path == null ? null : SpecPaths.join(path, child.segment());
      wire(child, node, childPath);
    }
    if (node.elementNode != null) {
      // Item positions are dynamic (`<listPath>-<seq>`), so the element
      // subtree carries no static paths.
      wire(node.elementNode, node, null);
    }
  }

  /**
   * Every node of the tree (document order; element subtrees follow their list
   * node).
   */
  public List<SomMetaNode> allNodes() {
    return allNodes;
  }

  // --- lookup by section id -----------------------------------------------

  /**
   * All nodes whose effective section id equals {@code sectionId}, in document
   * order. A shared class instantiated at several positions yields several
   * nodes (ids resolve within their parent chain, SOM §11.2).
   */
  public List<SomMetaNode> allById(String sectionId) {
    List<SomMetaNode> nodes = byIdIndex.get(sectionId);
    return nodes == null ? Collections.emptyList() : nodes;
  }

  /**
   * The first node whose effective section id equals {@code sectionId}.
   *
   * <p>A <i>resolved list-item id</i> (a list's {@code @SectionIdPattern} with
   * the {@code "xxx"} placeholder replaced by digits, e.g.
   * {@code "GOAL-ITEM-3"}) resolves to that list's element subtree. Returns
   * {@code null} when nothing matches.
   */
  public SomMetaNode byId(String sectionId) {
    List<SomMetaNode> exact = byIdIndex.get(sectionId);
    if (exact != null && !exact.isEmpty()) {
      return exact.get(0);
    }
    for (SomMetaNode node : allNodes) {
      if (node.sectionIdPattern != null
          && !node.sectionIdPattern.isEmpty()
          && matchesSectionIdPattern(node.sectionIdPattern, sectionId)) {
        return node.elementNode != null ? node.elementNode : node;
      }
    }
    return null;
  }

  /**
   * Whether {@code id} matches {@code pattern} with every {@code "xxx"}
   * placeholder standing for one-or-more digits.
   */
  private static boolean matchesSectionIdPattern(String pattern, String id) {
    String[] parts = pattern.split("xxx", -1);
    StringBuilder regex = new StringBuilder("^");
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        regex.append("[0-9]+");
      }
      regex.append(Pattern.quote(parts[i]));
    }
    regex.append("$");
    return Pattern.matches(regex.toString(), id);
  }

  // --- lookup by path -------------------------------------------------------

  /**
   * Resolves a document path (the SOM §8 grammar: segments joined by {@code "/"},
   * list items as {@code "-<seq>"} suffixes) to the metadata node it
   * addresses, or {@code null} when the path does not describe a reachable
   * position.
   *
   * <p>A list-item segment ({@code <listSegment>-<seq>}) resolves to the
   * list's element subtree; segments below it match the element class's
   * fields. A list <i>container</i> path is only valid as the final segment
   * (descending past a list requires an item suffix).
   */
  public SomMetaNode byPath(String path) {
    String[] segs = SpecPaths.segments(path);
    if (segs.length == 0 || !segs[0].equals(root.segment())) {
      return null;
    }

    SomMetaNode node = root;
    for (int i = 1; i < segs.length; i++) {
      String seg = segs[i];
      boolean last = i == segs.length - 1;

      // Prefer an exact segment match; only then try a list-item suffix, so a
      // hyphenated @SectionId is never mis-read as an item.
      SomMetaNode child = node.childBySegment(seg);
      if (child != null) {
        if (SomMetaKind.LIST.equals(child.kind) && !last) {
          return null; // a list path needs a `-<seq>` item suffix
        }
        if (child.recursive && !last) {
          return null; // chains terminate at recursive re-entries
        }
        node = child;
        continue;
      }

      SpecPaths.ListItemSegment split = SpecPaths.splitListItemSegment(seg);
      if (split == null) {
        return null;
      }
      SomMetaNode listNode = node.childBySegment(split.base);
      if (listNode == null || !SomMetaKind.LIST.equals(listNode.kind)) {
        return null;
      }
      SomMetaNode element = listNode.elementNode;
      if (element == null) {
        // Scalar list without an element subtree: the item is a value leaf.
        return last ? listNode : null;
      }
      node = element;
    }
    return node;
  }
}
