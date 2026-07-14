package tom_som_runtime;

/**
 * Occurrence bounds for one subsection type — a faithful port of the Go
 * {@code DocSpecsSubsectionRule}. {@code maxCount == null} means infinite.
 */
public final class DocSpecsSubsectionRule {
  public final int minCount;
  /** The maximum occurrence count, {@code null} for infinite. */
  public final Integer maxCount;

  public DocSpecsSubsectionRule(int minCount, Integer maxCount) {
    this.minCount = minCount;
    this.maxCount = maxCount;
  }
}
