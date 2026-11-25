package tom_som_runtime;

/** A strip asked for something it cannot do (SOM §11.10); the message says which. */
public final class SpecStripUsageError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public SpecStripUsageError(String message) {
    super(message);
  }
}
