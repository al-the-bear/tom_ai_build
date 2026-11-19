package tom_som_runtime;

/** What a row of the impact walk stands for ({@link SpecImpactWalk}). */
public enum SpecImpactRowKind {
  /** The document root. */
  ROOT("root"),
  /** A {@code complex} field's class node. */
  COMPLEX("complex"),
  /** A {@code section} field's class node. */
  SECTION("section"),
  /** A list field (its items are rows of their own). */
  LIST("list"),
  /** One item of a list of class elements. */
  ITEM("item"),
  /** The element class of an empty list, at {@code <list>/*}: what a new item holds. */
  TEMPLATE("template");

  public final String value;

  SpecImpactRowKind(String value) {
    this.value = value;
  }
}
