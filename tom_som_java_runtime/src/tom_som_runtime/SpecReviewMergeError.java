package tom_som_runtime;

/** Thrown by {@link SpecReviewMerge#mergeReviews} when a copy's structure does not fit the base. */
public final class SpecReviewMergeError extends RuntimeException {
  private static final long serialVersionUID = 1L;

  public SpecReviewMergeError(String message) {
    super(message);
  }
}
