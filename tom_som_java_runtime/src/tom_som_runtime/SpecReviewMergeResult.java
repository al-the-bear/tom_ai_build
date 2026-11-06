package tom_som_runtime;

/**
 * The merged document of a team review and its report (SOM §11.9.9).
 *
 * @param <D> the document type, the base's
 */
public final class SpecReviewMergeResult<D> {
  /** The merged document. */
  public final D merged;

  /** What the merge did. */
  public final SpecReviewMergeReport report;

  public SpecReviewMergeResult(D merged, SpecReviewMergeReport report) {
    this.merged = merged;
    this.report = report;
  }
}
