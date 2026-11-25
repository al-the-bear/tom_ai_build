package tom_som_runtime;

/** A value the emptying rule kept (SOM §11.10): what would go is unmarked instead. */
public final class SpecStripKept {
  public final SpecStripValueRef ref;
  /** The finding the emptied value would have added. */
  public final String finding;

  public SpecStripKept(SpecStripValueRef ref, String finding) {
    this.ref = ref;
    this.finding = finding;
  }

  @Override
  public String toString() {
    return "KEPT (would empty a required value): " + ref + " — " + finding;
  }
}
