package tom_som_runtime;

/**
 * A malformed or unreadable CodeSpecs extract file or gate record.
 *
 * <p>Unchecked, like every other failure signal in this runtime. The message
 * names the file it was read from.
 */
public final class CodeSpecsRecordError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** What is wrong, naming the file it was read from. */
  public final String message;

  public CodeSpecsRecordError(String message) {
    super(message);
    this.message = message;
  }

  @Override
  public String toString() {
    return "CodeSpecsRecordError: " + message;
  }
}
