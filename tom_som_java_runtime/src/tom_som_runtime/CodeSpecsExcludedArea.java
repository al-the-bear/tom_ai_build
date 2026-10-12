package tom_som_runtime;

/**
 * One area the gate record left out of scope.
 *
 * <p>Kept visible rather than dropped, so a consumer can say so: a scoped-out
 * area must never read as a covered one.
 */
public final class CodeSpecsExcludedArea {
  /** The {@code CE-*} code. */
  public final String area;

  /** {@code NOT_APPLICABLE}, or {@code INSUFFICIENT} with a recorded descope. */
  public final CodeSpecsGateVerdict verdict;

  /** Whether an insufficient verdict was resolved by descoping. */
  public final boolean descoped;

  /** How many routed entries the excluded extract carried (0 with no file). */
  public final int entryCount;

  /** The file the excluded extract was read from, or '' when there was none. */
  public final String source;

  public CodeSpecsExcludedArea(
      String area,
      CodeSpecsGateVerdict verdict,
      boolean descoped,
      int entryCount,
      String source) {
    this.area = area;
    this.verdict = verdict;
    this.descoped = descoped;
    this.entryCount = entryCount;
    this.source = source;
  }

  @Override
  public String toString() {
    return "CodeSpecsExcludedArea(" + area + ", " + verdict.word + ")";
  }
}
