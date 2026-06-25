package tom_som_runtime;

/**
 * Raised when a generated object model is instantiated against a document whose
 * authoring model version it must not edit (§2.2).
 */
public final class SomVersionError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public SomVersionError(String message) {
    super(message);
  }

  @Override
  public String toString() {
    return "SomVersionError: " + getMessage();
  }
}
