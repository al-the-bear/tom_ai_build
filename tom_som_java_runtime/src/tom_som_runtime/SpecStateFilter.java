package tom_som_runtime;

/** Whether a node currently holds a value, used by the {@code state} dimension. */
public enum SpecStateFilter {
  /** The node (and everything beneath it) holds no value. */
  EMPTY("empty"),

  /** The node holds at least one value at or beneath its path. */
  NON_EMPTY("nonEmpty");

  public final String value;

  SpecStateFilter(String value) {
    this.value = value;
  }

  /** Parses the corpus wire name ({@code "empty"} / {@code "nonEmpty"}). */
  public static SpecStateFilter parse(String raw) {
    for (SpecStateFilter f : values()) {
      if (f.value.equals(raw)) {
        return f;
      }
    }
    throw new IllegalArgumentException("\"" + raw + "\" is not a state filter");
  }
}
