package tom_som_runtime;

/** What to do with one inline mark (SOM §11.9.3). */
public enum SpecMarkDecision {
  /** Take the change: an insertion's text, nothing for a deletion, a substitution's new text. */
  ACCEPT("accept"),
  /** Undo the change: nothing for an insertion, a deletion's text, a substitution's old text. */
  REJECT("reject"),
  /** Keep the mark as written. */
  LEAVE("leave");

  /** The wire name. */
  public final String value;

  SpecMarkDecision(String value) {
    this.value = value;
  }

  /** The decision with wire name {@code value}. */
  public static SpecMarkDecision fromValue(String value) {
    for (SpecMarkDecision d : values()) {
      if (d.value.equals(value)) {
        return d;
      }
    }
    throw new IllegalArgumentException("unknown mark decision " + value);
  }
}
