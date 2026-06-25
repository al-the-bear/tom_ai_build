package tom_som_runtime;

/** One problem found while validating a document. */
public final class SpecValidationError {
  public final String path;
  public final SpecValidationCode code;
  public final String message;

  public SpecValidationError(String path, SpecValidationCode code, String message) {
    this.path = path;
    this.code = code;
    this.message = message;
  }

  @Override
  public String toString() {
    return "[" + code.value + "] " + path + ": " + message;
  }
}
