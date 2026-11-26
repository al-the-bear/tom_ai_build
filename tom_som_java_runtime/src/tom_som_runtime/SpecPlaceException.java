package tom_som_runtime;

/** A place or filter that does not parse or resolve, with the reason. */
public final class SpecPlaceException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  /** What went wrong; the corpus compares this, never the message. */
  public final SpecPlaceProblem problem;
  /** The place or filter as written. */
  public final String text;
  /** The prose for the reader. */
  public final String detail;

  public SpecPlaceException(SpecPlaceProblem problem, String text, String detail) {
    super("SpecPlaceException(" + problem.value + "): \"" + text + "\" " + detail);
    this.problem = problem;
    this.text = text;
    this.detail = detail;
  }
}
