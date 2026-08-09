package tom_som_runtime;

/**
 * A rejected node-creation attempt. Thrown by {@link SpecNodeCreator#add} and
 * returned (rather than thrown) by {@link SpecNodeCreator#checkAddNode}.
 *
 * <p>Unchecked, like every other caller-error signal in this runtime: the nine
 * ports agree on the {@link #code}, and Java is the only one of them with a
 * checked-exception concept that could add a compile-time obligation the others
 * do not have.
 *
 * <p>{@link #getMessage()} carries the human-readable explanation. The
 * <b>code</b> is the contract the shared corpus pins; the message is prose, kept
 * deliberately unpinned so rewording it is not a nine-package change.
 */
public final class SpecCreationError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** The parent path the add was attempted under. */
  public final String parentPath;

  /** The child section segment that was requested. */
  public final String childSegment;

  /** Why the add is illegal. */
  public final SpecCreationCode code;

  public SpecCreationError(
      String parentPath, String childSegment, SpecCreationCode code, String message) {
    super(message);
    this.parentPath = parentPath;
    this.childSegment = childSegment;
    this.code = code;
  }

  @Override
  public String toString() {
    return "SpecCreationError("
        + code.value
        + ") under \""
        + parentPath
        + "\" → \""
        + childSegment
        + "\": "
        + getMessage();
  }
}
