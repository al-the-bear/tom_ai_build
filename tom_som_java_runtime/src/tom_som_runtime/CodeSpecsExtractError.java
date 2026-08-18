package tom_som_runtime;

/**
 * Thrown when the document cannot be extracted from at all.
 *
 * <p>Two causes: a section routed nowhere — {@code ROUTE-TOTAL}
 * ({@code tom_specs_model_rules.md} §10.2) failing — and a walk root that cannot
 * be resolved to exactly one ({@code codespecs_prompt.md} §5). Both are errors
 * rather than skips: a section routed nowhere is a section the agent writing that
 * area never sees, and a walk over the wrong root is every area empty. A silent
 * omission at this boundary is indistinguishable from a specification that
 * genuinely said nothing.
 *
 * <p>Unchecked, like every other failure signal in this runtime: the nine ports
 * agree on the failure, and Java is the only one of them with a
 * checked-exception concept that could add a compile-time obligation the others
 * do not have.
 */
public final class CodeSpecsExtractError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** The document path of the offending node. */
  public final String path;

  /** The model class at {@link #path}. */
  public final String className;

  public CodeSpecsExtractError(String message, String path, String className) {
    super(message);
    this.path = path;
    this.className = className;
  }

  @Override
  public String toString() {
    return "CodeSpecsExtractError: " + getMessage() + " (" + path + ", " + className + ")";
  }
}
