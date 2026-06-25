package tom_som_runtime;

/** The render kind of a field, mirroring the exporter's classification. */
public enum SpecFieldKind {
  LIST("list"),
  FORM("form"),
  SECTION("section"),
  CONTENT("content"),
  ENUM("enum"),
  COMPLEX("complex"),
  SCALAR("scalar");

  public final String raw;

  SpecFieldKind(String raw) {
    this.raw = raw;
  }

  /** Parses {@code raw}; an unknown value falls back to {@link #SCALAR}. */
  public static SpecFieldKind parse(String raw) {
    for (SpecFieldKind kind : values()) {
      if (kind.raw.equals(raw)) {
        return kind;
      }
    }
    return SCALAR;
  }
}
