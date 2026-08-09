package tom_som_runtime;

/** Why an attempted node creation is illegal against the model. */
public enum SpecCreationCode {
  /**
   * The parent path does not resolve to a node that can own named children (it is
   * dangling, a leaf, or a list — lists grow through their own field, not by
   * adding children to the list node).
   */
  NOT_A_CONTAINER("notAContainer"),

  /** The requested child segment names no field on the parent's class. */
  UNKNOWN_CHILD("unknownChild"),

  /**
   * A caller-proposed list-item id does not keep the prefix mandated by the
   * list's {@code @SectionIdPattern} (AA1 criterion 3/5: an override replaces the
   * suffix, the pattern prefix stays).
   */
  PATTERN_MISMATCH("patternMismatch"),

  /**
   * A caller-proposed list-item id collides with another item's section id in the
   * same list (AA1 criterion 5: section ids within a list must be unique).
   */
  DUPLICATE_SECTION_ID("duplicateSectionId"),

  /**
   * A single-valued (non-list) child already holds a value — only one is allowed.
   */
  CARDINALITY_EXCEEDED("cardinalityExceeded");

  public final String value;

  SpecCreationCode(String value) {
    this.value = value;
  }
}
