package tom_som_runtime;

import java.util.List;

/** One value a strip changed, with what went (SOM §11.10). */
public final class SpecStrippedValue {
  public final SpecStripValueRef ref;
  /** The value before the strip. */
  public final String original;
  /** The value after it. */
  public final String stripped;
  /** What went, in order; applying every piece at its anchor gives the original back. */
  public final List<SpecStripPiece> pieces;

  public SpecStrippedValue(
      SpecStripValueRef ref, String original, String stripped, List<SpecStripPiece> pieces) {
    this.ref = ref;
    this.original = original;
    this.stripped = stripped;
    this.pieces = pieces;
  }
}
