package tom_som_runtime;

/**
 * Thrown when a review-annotation operation ({@link SpecReviewAnnotations})
 * names a comment, question, paragraph or inline mark that does not exist.
 * Thrown before anything is changed. Unchecked, like every other caller-error
 * signal in this runtime.
 */
public final class SpecReviewAnnotationError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public SpecReviewAnnotationError(String message) {
    super(message);
  }

  @Override
  public String toString() {
    return "SpecReviewAnnotationError: " + getMessage();
  }
}
