package tom_som_runtime;

/** A {@link SpecSyncFinding} with its sort keys (and, for a pair's finding, its two sides). */
public final class SpecSetFound {
  public final int order;
  public final String key;
  public final SpecSyncFinding finding;
  /** The Blueprint side, {@code null} for a finding outside a pair. */
  public final SpecSetSide b;
  /** The Phase 3 side, {@code null} for a finding outside a pair. */
  public final SpecSetSide d;

  public SpecSetFound(int order, String key, SpecSyncFinding finding, SpecSetSide b, SpecSetSide d) {
    this.order = order;
    this.key = key;
    this.finding = finding;
    this.b = b;
    this.d = d;
  }
}
