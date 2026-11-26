package tom_som_runtime;

/** How a finding of a {@link SpecDocumentSet} is resolved; the corpus compares {@link #value}. */
public enum SpecSyncResolution {
  /** {@code backfill} resolves it, writing the Blueprint. */
  BACKFILL("backfill"),
  /** {@code deriveFields} resolves it. */
  DERIVE_FIELDS("deriveFields"),
  /** The agent decides (or asks the user). */
  AGENT("agent"),
  /** Reported, not a finding: it does not hold up a gate. */
  INFO("info");

  public final String value;

  SpecSyncResolution(String value) {
    this.value = value;
  }
}
