package tom_som_runtime;

import java.util.List;

/** One value a document merge changed (SOM §11.10). */
public final class SpecStripMergedValue {
  public final SpecStripValueRef ref;
  /** The merged value written into the document of record. */
  public final String text;
  /** How many pieces were put back. */
  public final int restored;
  /** The pieces put back after an edited run, for an author to check. */
  public final List<SpecStripMergePlaced> placed;

  public SpecStripMergedValue(
      SpecStripValueRef ref, String text, int restored, List<SpecStripMergePlaced> placed) {
    this.ref = ref;
    this.text = text;
    this.restored = restored;
    this.placed = placed;
  }
}
