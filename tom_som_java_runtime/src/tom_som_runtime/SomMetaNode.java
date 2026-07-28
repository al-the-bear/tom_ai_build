package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * One node of the SOM metadata tree (SOM §7.1 MetaNode) — a faithful port of
 * {@code spec_meta.dart} / {@code spec_meta.ts}.
 *
 * <p>A node describes one navigable position of a document root's structure:
 * the document root itself, a field, or a list's element subtree. Class-level
 * annotations attach to the node where the class is <i>instantiated</i>;
 * field-level annotations attach to the node directly (field-level
 * {@code @SectionId} wins over the target class's).
 *
 * <p>Java has no named constructor arguments, so the node exposes public
 * mutable metadata fields (defaulted like the TS initializer): construct with
 * the required {@code (className, kind, typeName)} triple, assign the rest,
 * then hand the root to {@link SomMetaTree}, which wires the parent links and
 * absolute paths. A node instance belongs to at most one tree.
 */
public final class SomMetaNode {
  /**
   * The exact model class name this node is (for root/complex/section nodes:
   * the instantiated class; for leaves: the declaring class of the field).
   */
  public String className;

  /**
   * The exact field name in the parent class, {@code null} on the document
   * root and on list element subtrees.
   */
  public String memberName;

  /**
   * The effective {@code @SectionId} (field-level wins over class-level),
   * {@code null} when none.
   */
  public String sectionId;

  /**
   * The target class's own {@code @SectionId} (SOM §12.2 fallback): the id its
   * generated schema type is keyed by, used only to build the mapping key of a
   * section/complex node whose field carries no id. Never enters
   * {@link #segment} — the path stays field-level. {@code null} when none.
   */
  public String classSectionId;

  /** The {@code @SectionIdPattern} on a list field (item ids), {@code null} when none. */
  public String sectionIdPattern;

  /** The structural kind of the node (a {@link SomMetaKind} constant). */
  public String kind;

  /** The Dart type name of the field/class ({@code "String"}, {@code "GoalEntry"}, …). */
  public String typeName;

  /** {@code @SerializationOrder(order)}, {@code null} when unannotated. */
  public Integer serializationOrder;

  /** {@code @Min(count)}, {@code null} when unannotated. */
  public Integer min;

  /** Whether {@code @Unused} is present on the node. */
  public boolean unused;

  /** {@code @ContentType}, {@code null} when unannotated. */
  public SomContentTypeMeta contentType;

  /** {@code @ContentHelp(guidance)}, {@code null} when unannotated. */
  public String contentHelp;

  /**
   * The {@code @Headline(text)} predefined DEFAULT headline (YRD4; field-level
   * wins over the target class's), {@code null} when unannotated.
   *
   * <p>Render precedence: {@code stored headline > this default > name
   * derivation}. Editors prefill a new section's headline from this; a stored
   * headline always wins and stays editable.
   */
  public String headline;

  /** {@code @Comment(text)}, {@code null} when unannotated. */
  public String comment;

  /** The cleaned {@code ///} doc comment (member wins over class), {@code null} when none. */
  public String docComment;

  /** The instantiated class's own doc comment, when it differs from {@link #docComment}. */
  public String classDocComment;

  /** The form metadata, for {@link SomMetaKind#FORM} nodes. */
  public SomFormMeta form;

  /** {@code @Document} metadata; non-null only on the document root. */
  public SomDocMeta document;

  /** The {@code @MapsTo} target class name, {@code null} when unannotated. */
  public String mapsTo;

  /** The {@code @DetailedIn} target class name, {@code null} when unannotated. */
  public String detailedIn;

  /** Annotations without a dedicated slot, captured losslessly. */
  public List<SomMetaExtra> extra = new ArrayList<>();

  /**
   * Whether this node is a recursive re-entry reference (a class already on
   * the descent stack): {@link #kind} == {@link SomMetaKind#COMPLEX}, no
   * children.
   */
  public boolean recursive;

  /**
   * The child nodes, in {@code @SerializationOrder} order. For complex/section
   * nodes these are the target class's fields (the class collapses onto the
   * node); empty for leaves and recursive references.
   */
  public List<SomMetaNode> children = new ArrayList<>();

  /**
   * For {@link SomMetaKind#LIST} nodes, the element class subtree. Its children
   * describe each item's structure; item positions have no static path (see
   * {@link #path}).
   */
  public SomMetaNode elementNode;

  // --- tree wiring (set once by SomMetaTree) ------------------------------
  SomMetaTree wiredTree;
  SomMetaNode wiredParent;
  String wiredPath;

  public SomMetaNode(String className, String kind, String typeName) {
    this.className = className;
    this.kind = kind;
    this.typeName = typeName;
  }

  /**
   * The tree this node belongs to.
   *
   * @throws IllegalStateException when the node has not been attached to a
   *     {@link SomMetaTree} yet.
   */
  public SomMetaTree tree() {
    if (wiredTree == null) {
      throw new IllegalStateException(
          "SomMetaNode(" + debugName() + ") is not attached to a SomMetaTree");
    }
    return wiredTree;
  }

  /**
   * The parent node, or {@code null} on the document root. The parent of a
   * list's {@link #elementNode} is the list node itself.
   *
   * @throws IllegalStateException when the node is unattached.
   */
  public SomMetaNode parent() {
    tree(); // attachment guard
    return wiredParent;
  }

  /**
   * The node's absolute document path per the SOM §8 path grammar
   * ({@code <rootSegment>/<segment>/…}), or {@code null} for nodes inside a
   * list element subtree — their concrete paths depend on the item sequence
   * (see {@link #itemPath} on the list node and {@link SomMetaTree#byPath}).
   *
   * @throws IllegalStateException when the node is unattached.
   */
  public String path() {
    tree(); // attachment guard
    return wiredPath;
  }

  /**
   * The path segment this node contributes: the effective {@link #sectionId}
   * when present, else the {@link #memberName}, else the {@link #className}
   * (document root).
   */
  public String segment() {
    if (sectionId != null && !sectionId.isEmpty()) {
      return sectionId;
    }
    if (memberName != null && !memberName.isEmpty()) {
      return memberName;
    }
    return className;
  }

  /**
   * The path of the {@code seq}-th item of this list node ({@code <path>-<seq>}).
   *
   * @throws IllegalStateException when the node is not a list or has no static
   *     path.
   */
  public String itemPath(int seq) {
    if (!SomMetaKind.LIST.equals(kind)) {
      throw new IllegalStateException(
          "itemPath() requires a list node, " + debugName() + " is " + kind);
    }
    String p = path();
    if (p == null) {
      throw new IllegalStateException(
          "list " + debugName() + " sits inside a list element subtree and "
              + "has no static path");
    }
    return SpecPaths.listItemPath(p, seq);
  }

  /** The direct child whose {@link #memberName} equals {@code name}, or {@code null}. */
  public SomMetaNode childByMember(String name) {
    for (SomMetaNode c : children) {
      if (name.equals(c.memberName)) {
        return c;
      }
    }
    return null;
  }

  /** The direct child whose {@link #segment} equals {@code seg}, or {@code null}. */
  public SomMetaNode childBySegment(String seg) {
    for (SomMetaNode c : children) {
      if (c.segment().equals(seg)) {
        return c;
      }
    }
    return null;
  }

  /** A short identification for error messages. */
  public String debugName() {
    if (memberName == null || memberName.isEmpty()) {
      return className;
    }
    return className + "." + memberName;
  }
}
