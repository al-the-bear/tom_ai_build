package tom_som_runtime;

/** Why {@link SpecPrefill#prefill} refuses. */
public final class SpecPrefillError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** {@link #code}: the set holds no Blueprint. */
  public static final String NO_BLUEPRINT = "noBlueprint";
  /** {@link #code}: the root names no root of the model, or the Blueprint's own. */
  public static final String UNKNOWN_ROOT = "unknownRoot";

  /** {@link #NO_BLUEPRINT} or {@link #UNKNOWN_ROOT}. */
  public final String code;

  public SpecPrefillError(String code, String message) {
    super(message);
    this.code = code;
  }

  @Override
  public String toString() {
    return "SpecPrefillError(" + code + "): " + getMessage();
  }
}
