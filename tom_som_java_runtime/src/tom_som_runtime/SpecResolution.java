package tom_som_runtime;

/** The outcome of resolving a document path against a {@link SpecModel}. */
public final class SpecResolution {
  public final String path;
  public final SpecNodeKind kind;
  public final SpecRoot root;
  public final SpecField field;
  public final SpecClass targetClass;

  public SpecResolution(
      String path,
      SpecNodeKind kind,
      SpecRoot root,
      SpecField field,
      SpecClass targetClass) {
    this.path = path;
    this.kind = kind;
    this.root = root;
    this.field = field;
    this.targetClass = targetClass;
  }

  /**
   * Whether a single string value is stored directly at this path (a content,
   * enum, scalar leaf, or a scalar list item).
   */
  public boolean isValueLeaf() {
    return kind == SpecNodeKind.CONTENT
        || kind == SpecNodeKind.ENUM_VALUE
        || kind == SpecNodeKind.SCALAR
        || kind == SpecNodeKind.LIST_ITEM_SCALAR;
  }
}
