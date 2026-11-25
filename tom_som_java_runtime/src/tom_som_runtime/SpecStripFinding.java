package tom_som_runtime;

/** A reason a stripped document is not valid (SOM §11.10). */
public final class SpecStripFinding {
  /** {@code notation}, {@code instance}, {@code schema} or {@code parse}. */
  public final String kind;
  public final String message;
  /** The value the finding is about, or {@code null}. */
  public final SpecStripValueRef ref;

  public SpecStripFinding(String kind, String message) {
    this(kind, message, null);
  }

  public SpecStripFinding(String kind, String message, SpecStripValueRef ref) {
    this.kind = kind;
    this.message = message;
    this.ref = ref;
  }

  @Override
  public String toString() {
    return kind + ": " + (ref != null ? ref + ": " : "") + message;
  }
}
