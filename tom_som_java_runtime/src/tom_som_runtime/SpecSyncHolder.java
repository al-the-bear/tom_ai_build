package tom_som_runtime;

/** Which document holds a shared place's value; the corpus compares {@link #value}. */
public enum SpecSyncHolder {
  /** The Phase 3 document (the default). */
  DETAIL("detail"),
  /** The Blueprint ({@code @SyncedWith(heldHere:)}). */
  BLUEPRINT("blueprint");

  public final String value;

  SpecSyncHolder(String value) {
    this.value = value;
  }
}
